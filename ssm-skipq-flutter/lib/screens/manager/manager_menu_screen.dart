import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/theme.dart';
import '../../models/menu.dart';
import '../../services/menu_service.dart';

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

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  String? _categoryId;
  bool _isVeg = true;
  XFile? _pickedImage;
  bool _formLoading = false;

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

  Future<void> _createItem() async {
    if (_categoryId == null) return;
    setState(() => _formLoading = true);
    try {
      final form = FormData.fromMap({
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price': _priceController.text.trim(),
        'categoryId': _categoryId,
        'isVeg': _isVeg.toString(),
        if (_pickedImage != null)
          'image': await MultipartFile.fromFile(_pickedImage!.path),
      });
      final item = await widget.menuService.createMenuItem(form);
      setState(() {
        _items = [..._items, item]..sort((a, b) => a.name.compareTo(b.name));
        _nameController.clear();
        _descController.clear();
        _priceController.clear();
        _pickedImage = null;
      });
    } catch (_) {
      setState(() => _error = 'Unable to create menu item.');
    } finally {
      setState(() => _formLoading = false);
    }
  }

  Future<void> _toggleAvailability(MenuItem item) async {
    try {
      final updated = await widget.menuService.toggleAvailability(item.id);
      setState(() {
        final idx = _items.indexWhere((e) => e.id == item.id);
        if (idx >= 0) _items[idx] = updated;
      });
    } catch (_) {
      setState(() => _error = 'Unable to toggle availability.');
    }
  }

  Future<void> _deleteItem(MenuItem item) async {
    try {
      await widget.menuService.deleteMenuItem(item.id);
      setState(() => _items.removeWhere((e) => e.id == item.id));
    } catch (_) {
      setState(() => _error = 'Unable to delete item.');
    }
  }

  Future<void> _updatePrice(MenuItem item, String value) async {
    final price = num.tryParse(value);
    if (price == null || price < 0) return;
    try {
      final updated = await widget.menuService.updatePrice(item.id, price);
      setState(() {
        final idx = _items.indexWhere((e) => e.id == item.id);
        if (idx >= 0) _items[idx] = updated;
      });
    } catch (_) {
      setState(() => _error = 'Unable to update price.');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) setState(() => _pickedImage = file);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Add Menu Item', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
          TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description')),
          TextField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: 'Price'),
            keyboardType: TextInputType.number,
          ),
          DropdownButtonFormField<String>(
            initialValue: _categoryId,
            decoration: const InputDecoration(labelText: 'Category'),
            items: _categories
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setState(() => _categoryId = v),
          ),
          SwitchListTile(
            title: const Text('Vegetarian'),
            value: _isVeg,
            onChanged: (v) => setState(() => _isVeg = v),
          ),
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.image),
            label: Text(_pickedImage == null ? 'Pick image' : 'Image selected'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _formLoading ? null : _createItem,
            child: Text(_formLoading ? 'Saving…' : 'Add Item'),
          ),
          const Divider(height: 32),
          const Text('Menu Items', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: AppTheme.error))
          else
            ..._items.map((item) {
              final priceController = TextEditingController(text: '${item.price}');
              return Card(
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
                              child: Image.network(item.imageUrl, width: 56, height: 56, fit: BoxFit.cover),
                            )
                          else
                            const Icon(Icons.restaurant, size: 56),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(item.categoryName),
                                Text(item.isVeg ? 'Veg' : 'Non-Veg'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: priceController,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: TextInputType.number,
                        onSubmitted: (v) => _updatePrice(item, v),
                      ),
                      Row(
                        children: [
                          Text(item.available ? 'Available' : 'Sold out'),
                          const Spacer(),
                          Switch(
                            value: item.available,
                            onChanged: (_) => _toggleAvailability(item),
                          ),
                          IconButton(
                            onPressed: () => _deleteItem(item),
                            icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
