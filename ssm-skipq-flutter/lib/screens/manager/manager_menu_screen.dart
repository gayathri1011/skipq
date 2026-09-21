import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/theme.dart';
import '../../models/menu.dart';
import '../../services/menu_service.dart';
import '../../utils/category_icons.dart';

class ManagerMenuScreen extends StatefulWidget {
  const ManagerMenuScreen({super.key, required this.menuService});

  final MenuService menuService;

  @override
  State<ManagerMenuScreen> createState() => _ManagerMenuScreenState();
}

class _ManagerMenuScreenState extends State<ManagerMenuScreen> {
  List<Category> _categories = [];
  List<MenuItem> _items = [];
  bool _loading = true;
  String? _error;

  String? _categoryId;
  static const _categoryIcons = CategoryIcons.byKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await widget.menuService.fetchManagerMenu();
      _categories = data.categories;
      _items = data.items;
      _categoryId ??= _categories.isNotEmpty ? _categories.first.id : null;
    } catch (_) {
      _error = 'Unable to load menu.';
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _showCategoryDialog({Category? category}) async {
    final screenContext = context;
    final nameController = TextEditingController(text: category?.name ?? '');
    final orderController = TextEditingController(
      text: '${category?.sortOrder ?? _categories.length}',
    );
    var icon = category?.icon ?? 'restaurant';
    var isSubmitting = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(category == null ? 'Add Category' : 'Edit Category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: orderController,
                decoration: const InputDecoration(labelText: 'Display order'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: icon,
                decoration: const InputDecoration(labelText: 'Icon'),
                items: _categoryIcons.entries
                    .map((entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Row(
                            children: [
                              Icon(entry.value),
                              const SizedBox(width: 8),
                              Text(entry.key),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => icon = value);
                },
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(screenContext).showSnackBar(
                          const SnackBar(
                            content: Text('Category name is required.'),
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isSubmitting = true);

                      final name = nameController.text.trim();
                      final sortOrder = int.tryParse(orderController.text) ?? 0;
                      try {
                        final updated = category == null
                            ? await widget.menuService.createCategory(
                                name: name,
                                icon: icon,
                                sortOrder: sortOrder,
                              )
                            : await widget.menuService.updateCategory(
                                category.id,
                                name: name,
                                icon: icon,
                                sortOrder: sortOrder,
                              );
                        if (!context.mounted) return;

                        setState(() {
                          _categories = category == null
                              ? [..._categories, updated]
                              : _categories
                                  .map((item) => item.id == updated.id ? updated : item)
                                  .toList();
                          _categories.sort((a, b) => a.sortOrder == b.sortOrder
                              ? a.name.compareTo(b.name)
                              : a.sortOrder.compareTo(b.sortOrder));
                          _categoryId ??= updated.id;
                        });
                        Navigator.pop(context, true);
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(screenContext).showSnackBar(
                            const SnackBar(
                              content: Text('Unable to save category. Please try again.'),
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setDialogState(() => isSubmitting = false);
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 250));
    nameController.dispose();
    orderController.dispose();
    if (result == true && mounted) {
      ScaffoldMessenger.of(screenContext).showSnackBar(
        SnackBar(
          content: Text(
            category == null ? 'Category added successfully' : 'Category updated successfully',
          ),
        ),
      );
    }
  }

  Future<bool> _deleteCategory(Category category) async {
    try {
      await widget.menuService.deleteCategory(category.id);
      setState(() {
        _categories.removeWhere((item) => item.id == category.id);
        if (_categoryId == category.id) {
          _categoryId = _categories.isNotEmpty ? _categories.first.id : null;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category deleted')),
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  IconData _categoryIcon(String key) => CategoryIcons.resolve(key);

  Future<void> _openCategoryItems(Category category) async {
    setState(() => _categoryId = category.id);
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => _CategoryItemsPage(
          category: category,
          items: _items.where((item) => item.categoryId == category.id).toList(),
          onAddItem: () => _showAddItemDialog(category),
          onEditItem: _showEditItemDialog,
          onDeleteItem: (item) async {
            var deleted = false;
            await showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Delete this item?'),
                content: const Text('This cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final success = await _deleteItem(item);
                      if (!dialogContext.mounted) return;
                      if (success) {
                        deleted = true;
                        Navigator.pop(dialogContext);
                      } else {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Unable to delete item.')),
                        );
                      }
                    },
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            return deleted;
          },
          onUpdatePrice: (item, price) => _updatePrice(item, price),
          onToggleAvailability: _toggleAvailability,
          onEditCategory: () => _showCategoryDialog(category: category),
          onDeleteCategory: () async {
            final categoryItems = _items.where((item) => item.categoryId == category.id).toList();
            if (categoryItems.isNotEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Can't delete — this category still has items in it. Remove or move the items first.",
                    ),
                  ),
                );
              }
              return;
            }

            var deleted = false;
            await showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Delete this category?'),
                content: const Text('This cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final success = await _deleteCategory(category);
                      if (!dialogContext.mounted) return;
                      if (success) {
                        deleted = true;
                        Navigator.pop(dialogContext);
                      } else {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(content: Text('Unable to delete category. Move or delete its items first.')),
                        );
                      }
                    },
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (deleted) {
              if (mounted) Navigator.pop(context);
            }
          },
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<MenuItem?> _showAddItemDialog(Category category) {
    return showDialog<MenuItem>(
      context: context,
      builder: (_) => _MenuItemFormDialog(
        menuService: widget.menuService,
        category: category,
      ),
    );
  }

  Future<MenuItem?> _showEditItemDialog(MenuItem item) {
    return showDialog<MenuItem>(
      context: context,
      builder: (_) => _MenuItemFormDialog(
        menuService: widget.menuService,
        item: item,
      ),
    );
  }

  Future<MenuItem?> _toggleAvailability(MenuItem item) async {
    try {
      final updated = await widget.menuService.toggleAvailability(item.id);
      setState(() {
        final idx = _items.indexWhere((e) => e.id == item.id);
        if (idx >= 0) _items[idx] = updated;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Availability updated')),
        );
      }
      return updated;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update availability.')),
        );
      }
      return null;
    }
  }

  Future<bool> _deleteItem(MenuItem item) async {
    try {
      await widget.menuService.deleteMenuItem(item.id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _updatePrice(MenuItem item, String value) async {
    final price = num.tryParse(value);
    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid price.')),
      );
      return;
    }
    try {
      final updated = await widget.menuService.updatePrice(item.id, price);
      setState(() {
        final idx = _items.indexWhere((e) => e.id == item.id);
        if (idx >= 0) _items[idx] = updated;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item price updated')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update item price.')),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Category Master',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: AppTheme.error))
          else if (_categories.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Create a category to begin.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: _categories.length + 1,
              itemBuilder: (context, index) {
                if (index == _categories.length) {
                  return Card(
                    margin: EdgeInsets.zero,
                    elevation: 0,
                    color: AppTheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: AppTheme.border),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showCategoryDialog(),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_circle_outline, color: AppTheme.primary, size: 26),
                            SizedBox(height: 10),
                            Text(
                              '+ New Category',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final category = _categories[index];
                final selected = _categoryId == category.id;
                return Card(
                  margin: EdgeInsets.zero,
                  elevation: 0,
                  color: AppTheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: selected ? AppTheme.primary : AppTheme.border,
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openCategoryItems(category),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_categoryIcon(category.icon), color: AppTheme.primary, size: 28),
                          const SizedBox(height: 10),
                          Text(
                            category.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _MenuItemFormDialog extends StatefulWidget {
  const _MenuItemFormDialog({
    required this.menuService,
    this.category,
    this.item,
  });

  final MenuService menuService;
  final Category? category;
  final MenuItem? item;

  @override
  State<_MenuItemFormDialog> createState() => _MenuItemFormDialogState();
}

class _MenuItemFormDialogState extends State<_MenuItemFormDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late bool _isVeg;
  XFile? _pickedImage;
  bool _isSubmitting = false;

  bool get _isEditing => widget.item != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item?.name ?? '');
    _descriptionController = TextEditingController(text: widget.item?.description ?? '');
    _priceController = TextEditingController(text: widget.item == null ? '' : '${widget.item!.price}');
    _isVeg = widget.item?.isVeg ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final price = num.tryParse(_priceController.text.trim());
    if (name.isEmpty || price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item name and valid price are required.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final form = FormData.fromMap({
        'name': name,
        'description': _descriptionController.text.trim(),
        'price': price,
        'categoryId': widget.item?.categoryId ?? widget.category!.id,
        'isVeg': _isVeg.toString(),
        if (_pickedImage != null)
          'image': await MultipartFile.fromFile(_pickedImage!.path),
      });
      final result = _isEditing
          ? await widget.menuService.updateMenuItem(widget.item!.id, form)
          : await widget.menuService.createMenuItem(form);
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Unable to update menu item. Please try again.'
                : 'Unable to create menu item. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'Edit Item' : 'Add Menu Item to ${widget.category!.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final file = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (!mounted || file == null) return;
                setState(() => _pickedImage = file);
              },
              icon: const Icon(Icons.image_outlined),
              label: Text(_pickedImage == null
                  ? (_isEditing ? 'Change Image' : 'Add Image')
                  : 'Image Selected'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Vegetarian'),
              value: _isVeg,
              activeTrackColor: Colors.green,
              activeThumbColor: Colors.white,
              inactiveTrackColor: Colors.white,
              inactiveThumbColor: AppTheme.textMuted,
              trackOutlineColor: const WidgetStatePropertyAll(AppTheme.border),
              onChanged: (value) => setState(() => _isVeg = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_isEditing ? 'Save' : 'Add Item'),
        ),
      ],
    );
  }
}

class _CategoryItemsPage extends StatefulWidget {
  const _CategoryItemsPage({
    required this.category,
    required this.items,
    required this.onAddItem,
    required this.onEditItem,
    required this.onDeleteItem,
    required this.onUpdatePrice,
    required this.onToggleAvailability,
    required this.onEditCategory,
    required this.onDeleteCategory,
  });

  final Category category;
  final List<MenuItem> items;
  final Future<MenuItem?> Function() onAddItem;
  final Future<MenuItem?> Function(MenuItem item) onEditItem;
  final Future<bool> Function(MenuItem item) onDeleteItem;
  final Future<void> Function(MenuItem item, String price) onUpdatePrice;
  final Future<MenuItem?> Function(MenuItem item) onToggleAvailability;
  final VoidCallback onEditCategory;
  final Future<void> Function() onDeleteCategory;

  @override
  State<_CategoryItemsPage> createState() => _CategoryItemsPageState();
}

class _CategoryItemsPageState extends State<_CategoryItemsPage> {
  late List<MenuItem> _items;
  final Set<String> _updatingAvailability = <String>{};

  @override
  void initState() {
    super.initState();
    _items = [...widget.items];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        actions: [
          IconButton(
            tooltip: 'Edit category',
            onPressed: widget.onEditCategory,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete category',
            onPressed: widget.onDeleteCategory,
            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final item = await widget.onAddItem();
                    if (item != null && mounted) {
                      setState(() => _items = [..._items, item]);
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Item added successfully')),
                      );
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('+ Add Item'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No items in this category yet.'),
            )
          else
            ..._items.map(
              (item) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (item.imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.imageUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.restaurant,
                                  size: 56,
                                ),
                              ),
                            )
                          else
                            const Icon(Icons.restaurant, size: 56),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 8,
                                      color: item.available
                                          ? const Color(0xFFFE4101)
                                          : AppTheme.textMuted,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      item.available ? 'Available' : 'Unavailable',
                                      style: TextStyle(
                                        color: item.available
                                            ? const Color(0xFFFE4101)
                                            : AppTheme.textMuted,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (item.isVeg) ...[
                                      const Icon(
                                        Icons.eco,
                                        color: Colors.green,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text('Veg'),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\u20b9${item.price}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Price',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1),
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Edit item',
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final updated = await widget.onEditItem(item);
                              if (updated == null || !mounted) return;
                              setState(() {
                                _items = _items
                                    .map((entry) => entry.id == updated.id ? updated : entry)
                                    .toList();
                              });
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Item updated')),
                              );
                            },
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Delete item',
                            onPressed: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final deleted = await widget.onDeleteItem(item);
                              if (!deleted || !mounted) return;
                              setState(() {
                                _items = _items.where((entry) => entry.id != item.id).toList();
                              });
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Item deleted')),
                              );
                            },
                            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                          ),
                          const Spacer(),
                          Semantics(
                            button: true,
                            label: item.available
                                ? 'Set unavailable'
                                : 'Set available',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _updatingAvailability.contains(item.id)
                                  ? null
                                  : () async {
                                      final previous = item;
                                      setState(() {
                                        _updatingAvailability.add(item.id);
                                        _items = _items
                                            .map((entry) => entry.id == item.id
                                                ? entry.copyWith(available: !entry.available)
                                                : entry)
                                            .toList();
                                      });

                                      final updated = await widget.onToggleAvailability(item);
                                      if (!mounted) return;
                                      setState(() {
                                        _updatingAvailability.remove(item.id);
                                        _items = _items
                                            .map((entry) => entry.id == item.id
                                                ? updated ?? previous
                                                : entry)
                                            .toList();
                                      });
                                    },
                              child: Container(
                                width: 54,
                                height: 30,
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: item.available
                                      ? const Color(0xFFFE4101)
                                      : AppTheme.border,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Align(
                                  alignment: item.available
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
