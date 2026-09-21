import { Router } from 'express';
import {
  getCategories,
  createCategory,
  updateCategory,
  deleteCategory,
  getMenuItems,
  getManagerMenuItems,
  createMenuItem,
  updateMenuItem,
  updateMenuItemPrice,
  toggleMenuItemAvailability,
  deleteMenuItem,
} from '../controllers/menuController.js';
import { authenticate, authorize } from '../middleware/auth.js';
import { uploadMenuImage } from '../middleware/upload.js';

const router = Router();

router.get('/categories', authenticate, authorize('student'), getCategories);
router.get('/items', authenticate, authorize('student'), getMenuItems);
router.post('/categories', authenticate, authorize('manager'), createCategory);
router.patch('/categories/:id', authenticate, authorize('manager'), updateCategory);
router.delete('/categories/:id', authenticate, authorize('manager'), deleteCategory);

router.get(
  '/manager/items',
  authenticate,
  authorize('manager'),
  getManagerMenuItems,
);
router.post(
  '/items',
  authenticate,
  authorize('manager'),
  uploadMenuImage,
  createMenuItem,
);
router.patch(
  '/items/:id',
  authenticate,
  authorize('manager'),
  uploadMenuImage,
  updateMenuItem,
);
router.patch(
  '/items/:id/price',
  authenticate,
  authorize('manager'),
  updateMenuItemPrice,
);
router.patch(
  '/items/:id/availability',
  authenticate,
  authorize('manager'),
  toggleMenuItemAvailability,
);
router.delete(
  '/items/:id',
  authenticate,
  authorize('manager'),
  deleteMenuItem,
);

export default router;
