import dotenv from 'dotenv';
dotenv.config();
import mongoose from 'mongoose';

const ids = [
  '6aaeda71b9ad4ec267709794',
  '6aaedab3b9ad4ec2677097b5',
].map((id) => new mongoose.Types.ObjectId(id));

const uri = process.env.MONGODB_URI;
if (!uri) throw new Error('MONGODB_URI missing');

await mongoose.connect(uri);

const result = await mongoose.connection.collection('orders').updateMany(
  { _id: { $in: ids } },
  { $set: { createdAt: new Date() } },
);
console.log('RAW_UPDATE_RESULT', result);

const docs = await mongoose.connection.collection('orders').find({ _id: { $in: ids } }).toArray();
console.log(JSON.stringify(docs.map((d) => ({ id: String(d._id), tokenNumber: d.tokenNumber, createdAt: d.createdAt, status: d.status })), null, 2));

await mongoose.disconnect();
