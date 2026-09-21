import bcrypt from 'bcryptjs';
import Manager from '../models/Manager.js';

const isSuperAdmin = (req) =>
  req.headers['x-super-admin-id'] === 'superadmin' &&
  req.headers['x-super-admin-password'] === '1234admin';

const guard = (req, res) => {
  if (isSuperAdmin(req)) return true;
  res.status(403).json({ success: false, message: 'Super Admin access required' });
  return false;
};

export const listManagers = async (req, res) => {
  if (!guard(req, res)) return;
  const managers = await Manager.find()
    .select('managerId name passwordPlain')
    .sort({ name: 1 });
  return res.json({
    success: true,
    data: {
      managers: managers.map((manager) => ({
        id: manager._id,
        managerId: manager.managerId,
        name: manager.name,
        passwordMasked: '********',
        passwordPlain: manager.passwordPlain ?? null,
      })),
    },
  });
};

export const createManager = async (req, res) => {
  if (!guard(req, res)) return;
  const { managerId, name, password } = req.body;
  if (!managerId?.trim() || !name?.trim() || !password) {
    return res.status(400).json({ success: false, message: 'Name, Manager ID, and password are required.' });
  }

  const normalizedId = managerId.trim().toUpperCase();
  const exists = await Manager.findOne({ managerId: normalizedId });
  if (exists) {
    return res.status(409).json({ success: false, message: 'Manager ID already exists.' });
  }

  const manager = await Manager.create({
    managerId: normalizedId,
    name: name.trim(),
    passwordHash: await bcrypt.hash(password, 12),
    passwordPlain: password,
  });
  return res.status(201).json({
    success: true,
    data: {
      manager: {
        id: manager._id,
        managerId: manager.managerId,
        name: manager.name,
        passwordMasked: '********',
        passwordPlain: manager.passwordPlain,
      },
    },
  });
};

export const deleteManager = async (req, res) => {
  if (!guard(req, res)) return;
  const manager = await Manager.findByIdAndDelete(req.params.id);
  if (!manager) {
    return res.status(404).json({ success: false, message: 'Manager not found' });
  }
  return res.json({ success: true, message: 'Manager deleted' });
};
