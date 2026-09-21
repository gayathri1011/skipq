import mongoose from 'mongoose';

const categorySchema = new mongoose.Schema({
  name: {
    type: String,
    required: [true, 'Category name is required'],
    unique: true,
    trim: true,
    maxlength: 100,
  },
  icon: {
    type: String,
    trim: true,
    default: 'restaurant',
    maxlength: 50,
  },
  sortOrder: {
    type: Number,
    default: 0,
    min: 0,
  },
});

const Category = mongoose.model('Category', categorySchema);

export default Category;
