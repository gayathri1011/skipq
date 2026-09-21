import { Router } from 'express';
import {
  studentRegister,
  studentLogin,
  managerLogin,
  getMe,
  updateStudentProfile,
} from '../controllers/authController.js';
import { authenticate, authorize } from '../middleware/auth.js';

const router = Router();

router.post('/student-register', studentRegister);
router.post('/student-login', studentLogin);
router.post('/manager-login', managerLogin);
router.get('/me', authenticate, getMe);
router.patch(
  '/student-profile',
  authenticate,
  authorize('student'),
  updateStudentProfile,
);

router.get(
  '/student-check',
  authenticate,
  authorize('student'),
  (_req, res) => {
    res.json({ success: true, message: 'Student access granted' });
  },
);

router.get(
  '/manager-check',
  authenticate,
  authorize('manager'),
  (_req, res) => {
    res.json({ success: true, message: 'Manager access granted' });
  },
);

export default router;
