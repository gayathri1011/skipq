import dotenv from 'dotenv';
dotenv.config();
import mongoose from 'mongoose';
import Order from './models/Order.js';

const ids = [
  '6aaeda71b9ad4ec267709794',
  '6aaedab3b9ad4ec2677097b5',
];

const uri = process.env.MONGODB_URI;
if (!uri) throw new Error('MONGODB_URI missing');

await mongoose.connect(uri);

const before = await Order.find({ _id: { $in: ids } }).sort({ createdAt: 1 }).lean();
console.log('BEFORE');
for (const o of before) {
  console.log(JSON.stringify({ id: String(o._id), tokenNumber: o.tokenNumber, createdAt: o.createdAt, status: o.status }, null, 2));
}

await Order.updateMany(
  { _id: { $in: ids } },
  { $set: { createdAt: new Date() } },
);

const after = await Order.find({ _id: { $in: ids } }).sort({ createdAt: 1 }).lean();
console.log('AFTER');
for (const o of after) {
  console.log(JSON.stringify({ id: String(o._id), tokenNumber: o.tokenNumber, createdAt: o.createdAt, status: o.status }, null, 2));
}

await mongoose.disconnect();
