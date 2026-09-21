const isSuperAdmin = (req) =>
  req.headers['x-super-admin-id'] === 'superadmin' &&
  req.headers['x-super-admin-password'] === '1234admin';

export const requireSuperAdmin = (req, res, next) => {
  if (isSuperAdmin(req)) {
    next();
    return;
  }

  res.status(403).json({
    success: false,
    message: 'Super Admin access required',
  });
};