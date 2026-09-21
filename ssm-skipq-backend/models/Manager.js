import mongoose from 'mongoose';

const managerSchema = new mongoose.Schema({
  managerId: {
    type: String,
    required: [true, 'Manager ID is required'],
    unique: true,
    trim: true,
    uppercase: true,
  },
  passwordHash: {
    type: String,
    required: [true, 'Password hash is required'],
  },
  passwordPlain: {
    type: String,
  },
  name: {
    type: String,
    required: [true, 'Manager name is required'],
    trim: true,
    maxlength: 100,
  },
});

const Manager = mongoose.model('Manager', managerSchema);

export default Manager;
