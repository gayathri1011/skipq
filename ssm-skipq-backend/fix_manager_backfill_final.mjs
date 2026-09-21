import dotenv from 'dotenv';
dotenv.config();
import mongoose from 'mongoose';

const uri = process.env.MONGODB_URI;
if (!uri) throw new Error('MONGODB_URI missing');

const ids = ['6aaeda71b9ad4ec267709794', '6aaedab3b9ad4ec2677097b5'];
const now = new Date();

await mongoose.connect(uri);
const collection = mongoose.connection.collection('orders');

for (const id of ids) {
  const res = await collection.updateOne(
    { _id: new mongoose.Types.ObjectId(id) },
    { $set: { createdAt: now } },
  );
  console.log('UPDATE', id, res);
}

const docs = await collection
  .find({ _id: { $in: ids.map((id) => new mongoose.Types.ObjectId(id)) } })
  .sort({ createdAt: 1 })
  .toArray();

console.log('UPDATED_DOCS');
for (const d of docs) {
  const createdAt = new Date(d.createdAt);
  const visible =
    createdAt.getFullYear() === now.getFullYear() &&
    createdAt.getMonth() === now.getMonth() &&
    createdAt.getDate() === now.getDate();

  console.log(
    JSON.stringify(
      {
        id: String(d._id),
        tokenNumber: d.tokenNumber,
        status: d.status,
        createdAt: d.createdAt,
        managerVisibleToday: visible,
      },
      null,
      2,
    ),
  );
}

await mongoose.disconnect();
