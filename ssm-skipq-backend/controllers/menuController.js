import Category from '../models/Category.js';
import MenuItem from '../models/MenuItem.js';
import { uploadImageBuffer, deleteCloudinaryImage } from '../utils/cloudinaryUpload.js';

const sortCategories = (categories) =>
  [...categories].sort((a, b) => {
    const orderDifference = (a.sortOrder ?? 0) - (b.sortOrder ?? 0);
    return orderDifference || a.name.localeCompare(b.name);
  });

const formatMenuItem = (item) => ({
  id: item._id,
  name: item.name,
  description: item.description ?? '',
  price: item.price,
  categoryId: item.category?._id ?? item.category,
  categoryName: item.category?.name ?? '',
  imageUrl: item.imageUrl ?? '',
  isVeg: item.isVeg,
  available: item.available,
  createdAt: item.createdAt,
});

export const getCategories = async (_req, res) => {
  try {
    const categories = await Category.find().lean();
    const sorted = sortCategories(categories);

    return res.json({
      success: true,
      data: { categories: sorted },
    });
  } catch (error) {
    console.error('Get categories error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch categories',
    });
  }
};

export const createCategory = async (req, res) => {
  try {
    const name = req.body.name?.trim();
    if (!name) {
      return res.status(400).json({
        success: false,
        message: 'Category name is required',
      });
    }

    const highest = await Category.findOne().sort({ sortOrder: -1 }).lean();
    const category = await Category.create({
      name,
      icon: req.body.icon?.trim() || 'restaurant',
      sortOrder: Number.isFinite(Number(req.body.sortOrder))
        ? Number(req.body.sortOrder)
        : (highest?.sortOrder ?? -1) + 1,
    });

    return res.status(201).json({ success: true, data: { category } });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({ success: false, message: 'Category already exists' });
    }
    console.error('Create category error:', error.message);
    return res.status(500).json({ success: false, message: 'Unable to create category' });
  }
};

export const updateCategory = async (req, res) => {
  try {
    const updates = {};
    if (req.body.name !== undefined) {
      const name = req.body.name.trim();
      if (!name) return res.status(400).json({ success: false, message: 'Category name is required' });
      updates.name = name;
    }
    if (req.body.icon !== undefined) updates.icon = req.body.icon.trim() || 'restaurant';
    if (req.body.sortOrder !== undefined) updates.sortOrder = Number(req.body.sortOrder);

    const category = await Category.findByIdAndUpdate(req.params.id, updates, {
      new: true,
      runValidators: true,
    }).lean();

    if (!category) return res.status(404).json({ success: false, message: 'Category not found' });
    return res.json({ success: true, data: { category } });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({ success: false, message: 'Category already exists' });
    }
    console.error('Update category error:', error.message);
    return res.status(500).json({ success: false, message: 'Unable to update category' });
  }
};

export const deleteCategory = async (req, res) => {
  try {
    const itemCount = await MenuItem.countDocuments({ category: req.params.id });
    if (itemCount > 0) {
      return res.status(409).json({
        success: false,
        message: 'Move or delete menu items before deleting this category',
      });
    }

    const category = await Category.findByIdAndDelete(req.params.id);
    if (!category) return res.status(404).json({ success: false, message: 'Category not found' });
    return res.json({ success: true, message: 'Category deleted' });
  } catch (error) {
    console.error('Delete category error:', error.message);
    return res.status(500).json({ success: false, message: 'Unable to delete category' });
  }
};

export const getMenuItems = async (_req, res) => {
  try {
    const items = await MenuItem.find()
      .populate('category', 'name')
      .sort({ name: 1 })
      .lean();

    return res.json({
      success: true,
      data: { items: items.map(formatMenuItem) },
    });
  } catch (error) {
    console.error('Get menu items error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch menu items',
    });
  }
};

export const getManagerMenuItems = async (_req, res) => {
  try {
    const [categories, items] = await Promise.all([
      Category.find().lean(),
      MenuItem.find().populate('category', 'name').sort({ name: 1 }).lean(),
    ]);

    return res.json({
      success: true,
      data: {
        categories: sortCategories(categories),
        items: items.map(formatMenuItem),
      },
    });
  } catch (error) {
    console.error('Get manager menu error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to fetch menu',
    });
  }
};

export const createMenuItem = async (req, res) => {
  try {
    const { name, description, price, categoryId, isVeg } = req.body;

    if (!name?.trim() || price == null || !categoryId) {
      return res.status(400).json({
        success: false,
        message: 'Name, price, and category are required',
      });
    }

    const category = await Category.findById(categoryId);
    if (!category) {
      return res.status(400).json({
        success: false,
        message: 'Invalid category',
      });
    }

    let imageUrl = '';
    if (req.file) {
      const result = await uploadImageBuffer(req.file.buffer);
      imageUrl = result.secure_url;
    }

    const item = await MenuItem.create({
      name: name.trim(),
      description: description?.trim() ?? '',
      price: Number(price),
      category: categoryId,
      imageUrl,
      isVeg: isVeg === 'true' || isVeg === true,
      available: true,
    });

    const populated = await MenuItem.findById(item._id)
      .populate('category', 'name')
      .lean();

    return res.status(201).json({
      success: true,
      data: { item: formatMenuItem(populated) },
    });
  } catch (error) {
    console.error('Create menu item error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to create menu item',
    });
  }
};

export const updateMenuItem = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, price, categoryId, isVeg } = req.body;

    const item = await MenuItem.findById(id);
    if (!item) {
      return res.status(404).json({
        success: false,
        message: 'Menu item not found',
      });
    }

    if (name?.trim()) item.name = name.trim();
    if (description !== undefined) item.description = description.trim();
    if (price != null) item.price = Number(price);
    if (categoryId) {
      const category = await Category.findById(categoryId);
      if (!category) {
        return res.status(400).json({
          success: false,
          message: 'Invalid category',
        });
      }
      item.category = categoryId;
    }
    if (isVeg !== undefined) {
      item.isVeg = isVeg === 'true' || isVeg === true;
    }

    if (req.file) {
      await deleteCloudinaryImage(item.imageUrl);
      const result = await uploadImageBuffer(req.file.buffer);
      item.imageUrl = result.secure_url;
    }

    await item.save();

    const populated = await MenuItem.findById(item._id)
      .populate('category', 'name')
      .lean();

    return res.json({
      success: true,
      data: { item: formatMenuItem(populated) },
    });
  } catch (error) {
    console.error('Update menu item error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to update menu item',
    });
  }
};

export const updateMenuItemPrice = async (req, res) => {
  try {
    const { id } = req.params;
    const { price } = req.body;

    if (price == null || Number(price) < 0) {
      return res.status(400).json({
        success: false,
        message: 'Valid price is required',
      });
    }

    const item = await MenuItem.findByIdAndUpdate(
      id,
      { price: Number(price) },
      { new: true },
    )
      .populate('category', 'name')
      .lean();

    if (!item) {
      return res.status(404).json({
        success: false,
        message: 'Menu item not found',
      });
    }

    return res.json({
      success: true,
      data: { item: formatMenuItem(item) },
    });
  } catch (error) {
    console.error('Update price error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to update price',
    });
  }
};

export const toggleMenuItemAvailability = async (req, res) => {
  try {
    const { id } = req.params;
    const item = await MenuItem.findById(id);

    if (!item) {
      return res.status(404).json({
        success: false,
        message: 'Menu item not found',
      });
    }

    item.available = !item.available;
    await item.save();

    const populated = await MenuItem.findById(item._id)
      .populate('category', 'name')
      .lean();

    return res.json({
      success: true,
      data: { item: formatMenuItem(populated) },
    });
  } catch (error) {
    console.error('Toggle availability error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to toggle availability',
    });
  }
};

export const deleteMenuItem = async (req, res) => {
  try {
    const { id } = req.params;
    const item = await MenuItem.findById(id);

    if (!item) {
      return res.status(404).json({
        success: false,
        message: 'Menu item not found',
      });
    }

    await deleteCloudinaryImage(item.imageUrl);
    await item.deleteOne();

    return res.json({
      success: true,
      message: 'Menu item deleted',
    });
  } catch (error) {
    console.error('Delete menu item error:', error.message);
    return res.status(500).json({
      success: false,
      message: 'Unable to delete menu item',
    });
  }
};
