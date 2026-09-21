import 'package:flutter/foundation.dart';

import '../models/order.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  String _note = '';

  List<CartItem> get items => List.unmodifiable(_items);
  String get note => _note;

  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  num get totalAmount =>
      _items.fold<num>(0, (sum, item) => sum + item.price * item.quantity);

  void setNote(String value) {
    final next = value.trim();
    if (_note == next) return;
    _note = next;
    notifyListeners();
  }

  int getQuantity(String menuItemId) {
    return _items
            .firstWhere(
              (item) => item.menuItemId == menuItemId,
              orElse: () => const CartItem(
                menuItemId: '',
                name: '',
                price: 0,
                quantity: 0,
                imageUrl: '',
                isVeg: true,
                available: true,
              ),
            )
            .quantity;
  }

  void addItem({
    required String menuItemId,
    required String name,
    required num price,
    required String imageUrl,
    required bool isVeg,
    required bool available,
    String categoryId = '',
    String categoryName = '',
  }) {
    final index = _items.indexWhere((e) => e.menuItemId == menuItemId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: _items[index].quantity + 1);
    } else {
      _items.add(
        CartItem(
          menuItemId: menuItemId,
          name: name,
          price: price,
          quantity: 1,
          imageUrl: imageUrl,
          isVeg: isVeg,
          available: available,
          categoryId: categoryId,
          categoryName: categoryName,
        ),
      );
    }
    notifyListeners();
  }

  void addItemWithQuantity({
    required String menuItemId,
    required String name,
    required num price,
    required String imageUrl,
    required bool isVeg,
    required bool available,
    required int quantity,
    String categoryId = '',
    String categoryName = '',
  }) {
    if (quantity < 1) return;
    final index = _items.indexWhere((e) => e.menuItemId == menuItemId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity + quantity,
      );
    } else {
      _items.add(
        CartItem(
          menuItemId: menuItemId,
          name: name,
          price: price,
          quantity: quantity,
          imageUrl: imageUrl,
          isVeg: isVeg,
          available: available,
          categoryId: categoryId,
          categoryName: categoryName,
        ),
      );
    }
    notifyListeners();
  }

  void increment(String menuItemId) {
    final index = _items.indexWhere((e) => e.menuItemId == menuItemId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: _items[index].quantity + 1);
      notifyListeners();
    }
  }

  void decrement(String menuItemId) {
    final index = _items.indexWhere((e) => e.menuItemId == menuItemId);
    if (index < 0) return;
    final next = _items[index].quantity - 1;
    if (next <= 0) {
      _items.removeAt(index);
    } else {
      _items[index] = _items[index].copyWith(quantity: next);
    }
    notifyListeners();
  }

  void removeItem(String menuItemId) {
    _items.removeWhere((e) => e.menuItemId == menuItemId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _note = '';
    notifyListeners();
  }
}
