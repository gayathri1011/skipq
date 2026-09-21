import dotenv from 'dotenv';
dotenv.config();
import mongoose from 'mongoose';
import Order from './models/Order.js';

const uri = process.env.MONGODB_URI;
if (!uri) throw new Error('MONGODB_URI missing');

await mongoose.connect(uri);

const now = new Date();
const start = new Date(now);
start.setHours(0, 0, 0, 0);
const end = new Date(now);
end.setHours(23, 59, 59, 999);

const orders = await Order.find({ createdAt: { $gte: start, $lte: end } }).sort({ createdAt: 1 }).lean();
console.log('TODAY_COUNT', orders.length);
for (const o of orders) {
  console.log(JSON.stringify({
    id: String(o._id),
    total: o.total,
    status: o.status,
    paymentStatus: o.paymentStatus,
    createdAt: o.createdAt,
    tokenNumber: o.tokenNumber,
    studentId: String(o.studentId),
    itemsCount: Array.isArray(o.items) ? o.items.length : 0,
  }, null, 2));
}

await mongoose.disconnect();
