import { Router } from 'express';
import {
  createOrder,
  getMyOrders,
  getMyOrderById,
  getManagerOrders,
  getOrderAnalytics,
  advanceOrderStatus,
  cancelOrder,
  updateOrderPayment,
} from '../controllers/orderController.js';
import {
  submitOrderFeedback,
  getManagerFeedback,
} from '../controllers/feedbackController.js';
import { authenticate, authorize } from '../middleware/auth.js';

const router = Router();

router.post('/', authenticate, authorize('student'), createOrder);
router.get('/', authenticate, authorize('student'), getMyOrders);

router.get(
  '/feedback/manager',
  authenticate,
  authorize('manager'),
  getManagerFeedback,
);
router.post(
  '/:id/feedback',
  authenticate,
  authorize('student'),
  submitOrderFeedback,
);

router.get('/analytics', authenticate, authorize('manager'), getOrderAnalytics);
router.get('/manager', authenticate, authorize('manager'), getManagerOrders);
router.patch(
  '/:id/status',
  authenticate,
  authorize('manager'),
  advanceOrderStatus,
);
router.patch(
  '/:id/cancel',
  authenticate,
  authorize('student'),
  cancelOrder,
);
router.patch(
  '/:id/payment',
  authenticate,
  authorize('manager'),
  updateOrderPayment,
);
router.get('/:id', authenticate, authorize('student'), getMyOrderById);

export default router;
