import { Router } from 'express';
import { createManager, deleteManager, listManagers } from '../controllers/superAdminController.js';
import { getManagerOrders } from '../controllers/orderController.js';
import { getManagerFeedback } from '../controllers/feedbackController.js';
import { getCategories, getMenuItems } from '../controllers/menuController.js';
import { requireSuperAdmin } from '../middleware/superAdminAuth.js';
import { getOrderingWindow } from '../controllers/settingsController.js';

const router = Router();

router.get('/managers', listManagers);
router.post('/managers', createManager);
router.delete('/managers/:id', requireSuperAdmin, deleteManager);
router.get('/orders', requireSuperAdmin, getManagerOrders);
router.get('/feedback', requireSuperAdmin, getManagerFeedback);
router.get('/menu-items', requireSuperAdmin, getMenuItems);
router.get('/categories', requireSuperAdmin, getCategories);
router.get('/ordering-window', requireSuperAdmin, getOrderingWindow);

export default router;
