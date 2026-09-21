import mongoose from 'mongoose';
import Order from '../models/Order.js';
import Counter from '../models/Counter.js';
import MenuItem from '../models/MenuItem.js';
import Feedback from '../models/Feedback.js';
import { getTodayDateKey, formatTokenNumber, getTodayStartIst } from '../utils/token.js';
import { assertOrderingOpen } from '../controllers/settingsController.js';
import {
  createRazorpayOrder,
  getRazorpayKeyId,
  isRazorpayConfigured,
  isRazorpayTestMode,
} from '../config/razorpay.js';

const STATUS_FLOW = {
  PENDING: 'CONFIRMED',
  CONFIRMED: 'READY',
  PREPARING: 'READY',
  READY: 'PICKED_UP',
};

const STATUS_ACTION_LABELS = {
  PENDING: 'Accept',
  CONFIRMED: 'Ready',
  PREPARING: 'Ready',
  READY: 'Collected',
};

const getDateRange = (range, customStart, customEnd) => {
  const now = new Date();
  const startOfToday = new Date(now);
  startOfToday.setHours(0, 0, 0, 0);

  let start = new Date(startOfToday);
  let end = new Date(now);

  switch (range) {
    case 'week':
      start.setDate(start.getDate() - 6);
      break;
    case 'month':
      start.setMonth(start.getMonth() - 1);
      break;
    case 'year':
      start.setFullYear(start.getFullYear() - 1);
      break;
    case 'custom':
      if (customStart) {
        start = new Date(customStart);
      }
      if (customEnd) {
        end = new Date(customEnd);
        end.setHours(23, 59, 59, 999);
      }
      break;
    case 'day':
    default:
      start = new Date(startOfToday);
      break;
  }

  return { start, end };
};

export const formatOrder = (order) => ({
  id: order._id?.toString?.() ?? order.id,
  studentId: order.studentId?._id?.toString?.() ?? order.studentId?.toString?.() ?? order.studentId,
  student: order.studentId?.name
    ? {
        name: order.studentId.name,
        mobile: order.studentId.mobile,
      }
    : order.student ?? undefined,
  items: order.items,
  total: order.total,
  paymentMethod: order.paymentMethod,
  paymentStatus: order.paymentStatus,
  status: order.status,
  cancelledBy: order.cancelledBy,
  cancelledAt: order.cancelledAt,
  tokenNumber: order.tokenNumber,
  createdAt: order.createdAt,
  note: order.note ?? '',
});

const emitOrderUpdate = (req, order) => {
  const formatted = formatOrder(order);
  const io = req.app.get('io');
  io.to('manager').emit('order:updated', formatted);
  io.to(`student:${formatted.studentId}`).emit('order:updated', formatted);
};

export const createOrder = async (req, res) => {
  const session = await mongoose.startSession();

  try {
    const { isOpen } = await assertOrderingOpen();
    if (!isOpen) {
      return res.status(403).json({
        success: false,
        message:
          'Ordering is closed. Please visit the canteen directly.',
      });
    }

    const { items, paymentMethod, note } = req.body;
    const studentId = req.user.id;
    const trimmedNote = typeof note === 'string' ? note.trim() : '';

    if (!Array.isArray(items) || items.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Order must contain at least one item',
      });
    }

    const validMethods = ['GOOGLE_PAY', 'PHONEPE', 'PAY_AT_COUNTER', 'RAZORPAY'];
    if (!validMethods.includes(paymentMethod)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid payment method',
      });
    }

    if (paymentMethod === 'RAZORPAY' && !isRazorpayConfigured()) {
      return res.status(503).json({
        success: false,
        message:
          'Online payment is not configured yet. Use Pay at Counter or add Razorpay test keys.',
      });
    }

    const paymentStatus =
      paymentMethod === 'PAY_AT_COUNTER' || paymentMethod === 'RAZORPAY'
        ? 'PENDING'
        : 'PAID';

    for (const item of items) {
      if (!item.menuItemId || !item.quantity) {
        return res.status(400).json({
          success: false,
          message: 'Each item must include menuItemId and quantity',
        });
      }

      if (!Number.isInteger(item.quantity) || item.quantity < 1) {
        return res.status(400).json({
          success: false,
          message: 'Each item quantity must be a positive integer',
        });
      }
    }

    const menuItemIds = items.map((item) => item.menuItemId);
    const menuItems = await MenuItem.find({ _id: { $in: menuItemIds } });

    if (menuItems.length !== items.length) {
      return res.status(400).json({
        success: false,
        message: 'One or more menu items are invalid',
      });
    }

    const menuById = new Map(
      menuItems.map((menuItem) => [menuItem._id.toString(), menuItem]),
    );

    const unavailable = menuItems.filter((m) => !m.available);
    if (unavailable.length > 0) {
      return res.status(400).json({
        success: false,
        message: `${unavailable[0].name} is currently sold out`,
      });
    }

    const normalizedItems = items.map((item) => {
      const menuItem = menuById.get(item.menuItemId.toString());
      return {
        menuItemId: menuItem._id,
        name: menuItem.name,
        price: menuItem.price,
        quantity: item.quantity,
      };
    });

    const calculatedTotal = normalizedItems.reduce(
      (sum, item) => sum + item.price * item.quantity,
      0,
    );

    if (
      req.body.total != null &&
      Math.abs(calculatedTotal - Number(req.body.total)) > 0.01
    ) {
      return res.status(400).json({
        success: false,
        message: 'Order total does not match item prices',
      });
    }

    const dateKey = getTodayDateKey();
    let createdOrder;

    await session.withTransaction(async () => {
      const counter = await Counter.findOneAndUpdate(
        { dateKey },
        { $inc: { sequence: 1 } },
        { new: true, upsert: true, session },
      );

      const tokenNumber = formatTokenNumber(counter.sequence);

      const [order] = await Order.create(
        [
          {
            studentId,
            items: normalizedItems,
            total: calculatedTotal,
            paymentMethod,
            paymentStatus,
            status: 'PENDING',
            tokenNumber,
            note: trimmedNote,
          },
        ],
        { session },
      );

      createdOrder = order;
    });

    const populated = await Order.findById(createdOrder._id)
      .populate('studentId', 'name mobile')
      .lean();

    const formatted = formatOrder(populated);
    const io = req.app.get('io');

    io.to('manager').emit('order:created', formatted);
    io.to(`student:${studentId}`).emit('order:updated', formatted);

    let razorpay = null;

    if (paymentMethod === 'RAZORPAY') {
      const razorpayOrder = await createRazorpayOrder({
        amountInr: calculatedTotal,
        receipt: createdOrder._id.toString(),
        notes: {
          tokenNumber: createdOrder.tokenNumber,
          studentId,
        },
      });

      await Order.findByIdAndUpdate(createdOrder._id, {
        razorpayOrderId: razorpayOrder.id,
      });

      razorpay = {
        orderId: razorpayOrder.id,
        amount: razorpayOrder.amount,
        currency: razorpayOrder.currency,
        keyId: getRazorpayKeyId(),
        testMode: isRazorpayTestMode(),
      };
    }

    return res.status(201).json({
      success: true,
      data: {
        order: formatted,
        razorpay,
      },
    });
  } catch (error) {
    console.error('Create order error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to place order',
    });
  } finally {
    session.endSession();
  }
};

export const getMyOrders = async (req, res) => {
  try {
    const studentId = req.user.id;

    const [orders, feedbackRows] = await Promise.all([
      Order.find({ studentId })
        .sort({ createdAt: -1 })
        .lean(),
      Feedback.find({ studentId }).select('orderId rating review').lean(),
    ]);

    const feedbackOrderIds = new Set(
      feedbackRows.map((row) => row.orderId.toString()),
    );
    const feedbackByOrderId = new Map(
      feedbackRows.map((row) => [row.orderId.toString(), row]),
    );

    return res.json({
      success: true,
      data: {
        orders: orders.map((order) => ({
          id: order._id,
          studentId: order.studentId,
          items: order.items,
          total: order.total,
          paymentMethod: order.paymentMethod,
          paymentStatus: order.paymentStatus,
          status: order.status,
          tokenNumber: order.tokenNumber,
          createdAt: order.createdAt,
          note: order.note ?? '',
          hasFeedback: feedbackOrderIds.has(order._id.toString()),
          feedback: feedbackByOrderId.has(order._id.toString())
            ? {
                rating: feedbackByOrderId.get(order._id.toString()).rating,
                review: feedbackByOrderId.get(order._id.toString()).review ?? '',
              }
            : null,
        })),
      },
    });
  } catch (error) {
    console.error('Get orders error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch orders',
    });
  }
};

export const getMyOrderById = async (req, res) => {
  try {
    const order = await Order.findOne({
      _id: req.params.id,
      studentId: req.user.id,
    }).lean();

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found',
      });
    }

    const hasFeedback = await Feedback.exists({
      orderId: order._id,
      studentId: req.user.id,
    });
    const feedback = hasFeedback
      ? await Feedback.findOne({
          orderId: order._id,
          studentId: req.user.id,
        })
          .select('rating review')
          .lean()
      : null;

    return res.json({
      success: true,
      data: {
        order: {
          ...formatOrder(order),
          hasFeedback: Boolean(hasFeedback),
          feedback: feedback
            ? { rating: feedback.rating, review: feedback.review ?? '' }
            : null,
        },
      },
    });
  } catch (error) {
    if (error instanceof mongoose.Error.CastError) {
      return res.status(404).json({
        success: false,
        message: 'Order not found',
      });
    }

    console.error('Get student order error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch order',
    });
  }
};

export const getManagerOrders = async (_req, res) => {
  try {
    const orders = await Order.find()
      .populate('studentId', 'name mobile')
      .sort({ createdAt: -1 })
      .lean();

    return res.json({
      success: true,
      data: {
        orders: orders.map(formatOrder),
        statusFlow: STATUS_FLOW,
        statusActionLabels: STATUS_ACTION_LABELS,
      },
    });
  } catch (error) {
    console.error('Get manager orders error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch orders',
    });
  }
};

export const getOrderAnalytics = async (req, res) => {
  try {
    const range = req.query.range || 'day';
    const { start, end } = getDateRange(
      Array.isArray(range) ? range[0] : range,
      req.query.startDate,
      req.query.endDate,
    );

    const orders = await Order.find({
      createdAt: { $gte: start, $lte: end },
    }).lean();

    let totalRevenue = 0;
    let completedOrders = 0;
    const itemMap = new Map();

    for (const order of orders) {
      if (order.status === 'PICKED_UP') {
        totalRevenue += Number(order.total || 0);
        completedOrders += 1;
      }

      for (const item of order.items || []) {
        const itemName = item.name || 'Unknown';
        const current = itemMap.get(itemName) || {
          name: itemName,
          quantity: 0,
          revenue: 0,
        };

        current.quantity += Number(item.quantity || 0);
        current.revenue += Number((item.price || 0) * (item.quantity || 0));
        itemMap.set(itemName, current);
      }
    }

    const topItems = [...itemMap.values()]
      .sort((a, b) => {
        const quantityOrder = b.quantity - a.quantity;
        if (quantityOrder !== 0) return quantityOrder;
        return b.revenue - a.revenue;
      })
      .slice(0, 5)
      .map((item) => ({
        name: item.name,
        quantity: item.quantity,
        revenue: Number(item.revenue.toFixed(2)),
      }));

    return res.json({
      success: true,
      data: {
        analytics: {
          totalOrders: orders.length,
          totalRevenue: Number(totalRevenue.toFixed(2)),
          completedOrders,
          topItems,
        },
      },
    });
  } catch (error) {
    console.error('Get order analytics error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to calculate analytics',
    });
  }
};

export const advanceOrderStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const order = await Order.findById(id).populate('studentId', 'name mobile');

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found',
      });
    }

    const nextStatus = STATUS_FLOW[order.status];
    if (!nextStatus) {
      return res.status(400).json({
        success: false,
        message: `Cannot advance order from status ${order.status}`,
      });
    }

    order.status = nextStatus;
    await order.save();

    emitOrderUpdate(req, order);

    return res.json({
      success: true,
      data: { order: formatOrder(order) },
    });
  } catch (error) {
    console.error('Advance order status error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to update order status',
    });
  }
};

export const cancelOrder = async (req, res) => {
  try {
    const order = await Order.findOneAndUpdate(
      {
        _id: req.params.id,
        studentId: req.user.id,
        status: 'PENDING',
      },
      { $set: { status: 'CANCELLED', cancelledBy: 'STUDENT', cancelledAt: new Date() } },
      { new: true },
    ).populate('studentId', 'name mobile');

    if (order) {
      emitOrderUpdate(req, order);
      return res.json({
        success: true,
        data: { order: formatOrder(order) },
      });
    }

    const existing = await Order.findOne({
      _id: req.params.id,
      studentId: req.user.id,
    }).select('status');

    if (!existing) {
      return res.status(404).json({
        success: false,
        message: 'Order not found',
      });
    }

    return res.status(409).json({
      success: false,
      message: 'Only pending orders can be cancelled.',
    });
  } catch (error) {
    console.error('Cancel order error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to cancel order',
    });
  }
};

export const updateOrderPayment = async (req, res) => {
  try {
    const { id } = req.params;
    const { paymentStatus } = req.body;

    if (!['PENDING', 'PAID'].includes(paymentStatus)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid payment status',
      });
    }

    const order = await Order.findById(id).populate('studentId', 'name mobile');

    if (!order) {
      return res.status(404).json({
        success: false,
        message: 'Order not found',
      });
    }

    if (order.paymentMethod !== 'PAY_AT_COUNTER') {
      return res.status(400).json({
        success: false,
        message: 'Payment status can only be updated for counter payments',
      });
    }

    if (paymentStatus !== 'PAID') {
      return res.status(400).json({
        success: false,
        message: 'Only payment received is supported',
      });
    }

    if (order.paymentStatus === 'PAID') {
      return res.status(400).json({
        success: false,
        message: 'Payment already received',
      });
    }

    order.paymentStatus = 'PAID';
    await order.save();

    emitOrderUpdate(req, order);

    return res.json({
      success: true,
      data: { order: formatOrder(order) },
    });
  } catch (error) {
    console.error('Update order payment error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to update payment status',
    });
  }
};
