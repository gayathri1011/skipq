import mongoose from 'mongoose';

const orderItemSchema = new mongoose.Schema(
  {
    menuItemId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'MenuItem',
      required: [true, 'Menu item reference is required'],
    },
    name: {
      type: String,
      required: [true, 'Item name is required'],
      trim: true,
    },
    price: {
      type: Number,
      required: [true, 'Item price is required'],
      min: [0, 'Price cannot be negative'],
    },
    quantity: {
      type: Number,
      required: [true, 'Quantity is required'],
      min: [1, 'Quantity must be at least 1'],
    },
  },
  { _id: false },
);

const orderSchema = new mongoose.Schema(
  {
    studentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Student',
      required: [true, 'Student reference is required'],
    },
    items: {
      type: [orderItemSchema],
      validate: {
        validator: (items) => Array.isArray(items) && items.length > 0,
        message: 'Order must contain at least one item',
      },
    },
    total: {
      type: Number,
      required: [true, 'Order total is required'],
      min: [0, 'Total cannot be negative'],
    },
    paymentMethod: {
      type: String,
      enum: ['GOOGLE_PAY', 'PHONEPE', 'PAY_AT_COUNTER', 'RAZORPAY'],
      required: [true, 'Payment method is required'],
    },
    paymentStatus: {
      type: String,
      enum: ['PENDING', 'PAID'],
      default: 'PENDING',
    },
    status: {
      type: String,
      enum: [
        'PENDING',
        'CONFIRMED',
        'PREPARING',
        'READY',
        'PICKED_UP',
        'CANCELLED',
      ],
      default: 'PENDING',
    },
    cancelledBy: {
      type: String,
      enum: ['STUDENT'],
    },
    cancelledAt: {
      type: Date,
    },
    tokenNumber: {
      type: String,
      required: [true, 'Token number is required'],
      trim: true,
    },
    note: {
      type: String,
      trim: true,
      default: '',
    },
    razorpayOrderId: {
      type: String,
      trim: true,
    },
    razorpayPaymentId: {
      type: String,
      trim: true,
    },
  },
  {
    timestamps: { createdAt: true, updatedAt: false },
  },
);

orderSchema.index({ studentId: 1, createdAt: -1 });
orderSchema.index({ status: 1, createdAt: -1 });
orderSchema.index({ tokenNumber: 1, createdAt: -1 });

const Order = mongoose.model('Order', orderSchema);

export default Order;
