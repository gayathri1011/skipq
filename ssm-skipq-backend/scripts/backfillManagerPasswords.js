import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';
import mongoose from 'mongoose';
import connectDB from '../config/db.js';
import Manager from '../models/Manager.js';

dotenv.config();

const DEFAULT_MANAGER_ID = 'SSM001';
const DEFAULT_MANAGER_PASSWORD = 'manager123';

const backfillManagerPasswords = async () => {
  await connectDB();

  const passwordHash = await bcrypt.hash(DEFAULT_MANAGER_PASSWORD, 12);
  const manager = await Manager.findOneAndUpdate(
    { managerId: DEFAULT_MANAGER_ID },
    {
      $set: {
        passwordHash,
        passwordPlain: DEFAULT_MANAGER_PASSWORD,
      },
    },
    { new: true },
  );

  if (!manager) {
    throw new Error(`Manager ${DEFAULT_MANAGER_ID} was not found`);
  }

  const unresolved = await Manager.find({
    $or: [
      { passwordPlain: { $exists: false } },
      { passwordPlain: null },
      { passwordPlain: '' },
    ],
  })
    .select('managerId name')
    .sort({ managerId: 1 })
    .lean();

  console.log(`Backfilled ${DEFAULT_MANAGER_ID} (${manager.name}) with manager123.`);
  if (unresolved.length === 0) {
    console.log('No other managers are missing a retrievable password.');
  } else {
    console.log('Other managers still missing retrievable passwords:');
    for (const item of unresolved) {
      console.log(`- ${item.managerId}: ${item.name}`);
    }
  }

  await mongoose.disconnect();
};

backfillManagerPasswords().catch(async (error) => {
  console.error('Manager password backfill failed:', error.message);
  await mongoose.disconnect();
  process.exitCode = 1;
});
