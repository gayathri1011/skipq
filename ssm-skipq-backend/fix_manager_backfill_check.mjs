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
const now = new Date();
const result = await Order.updateMany(
  { _id: { $in: ids } },
  { $set: { createdAt: now } },
);
console.log('UPDATE_RESULT', result);
const after = await Order.find({ _id: { $in: ids } }).lean();
console.log(JSON.stringify(after, null, 2));
await mongoose.disconnect();
