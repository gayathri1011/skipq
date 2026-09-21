import dotenv from 'dotenv';
dotenv.config();
import mongoose from 'mongoose';

const uri = process.env.MONGODB_URI;
if (!uri) throw new Error('MONGODB_URI missing');

const targetId = '6aaeda71b9ad4ec267709794';

await mongoose.connect(uri);
const collection = mongoose.connection.collection('orders');
const before = await collection.findOne({ _id: new mongoose.Types.ObjectId(targetId) });
console.log('BEFORE', { _id: String(before._id), tokenNumber: before.tokenNumber, createdAt: before.createdAt, status: before.status });

const res = await collection.updateOne(
  { _id: new mongoose.Types.ObjectId(targetId) },
  { $set: { createdAt: new Date('2026-09-20T12:00:00.000Z') } },
);
console.log('UPDATE_RESULT', res);

const after = await collection.findOne({ _id: new mongoose.Types.ObjectId(targetId) });
console.log('AFTER', { _id: String(after._id), tokenNumber: after.tokenNumber, createdAt: after.createdAt, status: after.status });

await mongoose.disconnect();
