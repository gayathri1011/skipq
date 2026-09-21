import 'package:dio/dio.dart';

import '../models/menu.dart';
import 'api_client.dart';

class MenuService {
  MenuService(this._api);

  final ApiClient _api;

  Future<List<Category>> fetchCategories() async {
    final response =
        await _api.dio.get<Map<String, dynamic>>('/menu/categories');
    final data = response.data?['data'] as Map<String, dynamic>?;
    return (data?['categories'] as List<dynamic>? ?? [])
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<MenuItem>> fetchMenuItems() async {
    final response = await _api.dio.get<Map<String, dynamic>>('/menu/items');
    final data = response.data?['data'] as Map<String, dynamic>?;
    return (data?['items'] as List<dynamic>? ?? [])
        .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Category> createCategory({
    required String name,
    required String icon,
    required int sortOrder,
  }) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/menu/categories',
      data: {'name': name, 'icon': icon, 'sortOrder': sortOrder},
    );
    final category =
        (response.data?['data'] as Map<String, dynamic>)['category'];
    return Category.fromJson(category as Map<String, dynamic>);
  }

  Future<Category> updateCategory(
    String id, {
    required String name,
    required String icon,
    required int sortOrder,
  }) async {
    final response = await _api.dio.patch<Map<String, dynamic>>(
      '/menu/categories/$id',
      data: {'name': name, 'icon': icon, 'sortOrder': sortOrder},
    );
    final category =
        (response.data?['data'] as Map<String, dynamic>)['category'];
    return Category.fromJson(category as Map<String, dynamic>);
  }

  Future<void> deleteCategory(String id) async {
    await _api.dio.delete<void>('/menu/categories/$id');
  }

  Future<({List<Category> categories, List<MenuItem> items})>
      fetchManagerMenu() async {
    final response =
        await _api.dio.get<Map<String, dynamic>>('/menu/manager/items');
    final data = response.data?['data'] as Map<String, dynamic>?;
    final categories = (data?['categories'] as List<dynamic>? ?? [])
        .map((e) => Category.fromJson(e as Map<String, dynamic>))
        .toList();
    final items = (data?['items'] as List<dynamic>? ?? [])
        .map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .toList();
    return (categories: categories, items: items);
  }

  Future<MenuItem> createMenuItem(FormData formData) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/menu/items',
      data: formData,
    );
    final item = (response.data?['data'] as Map<String, dynamic>)['item'];
    return MenuItem.fromJson(item as Map<String, dynamic>);
  }

  Future<MenuItem> updateMenuItem(String id, FormData formData) async {
    final response = await _api.dio.patch<Map<String, dynamic>>(
      '/menu/items/$id',
      data: formData,
    );
    final item = (response.data?['data'] as Map<String, dynamic>)['item'];
    return MenuItem.fromJson(item as Map<String, dynamic>);
  }

  Future<MenuItem> updatePrice(String id, num price) async {
    final response = await _api.dio.patch<Map<String, dynamic>>(
      '/menu/items/$id/price',
      data: {'price': price},
    );
    final item = (response.data?['data'] as Map<String, dynamic>)['item'];
    return MenuItem.fromJson(item as Map<String, dynamic>);
  }

  Future<MenuItem> toggleAvailability(String id) async {
    final response = await _api.dio
        .patch<Map<String, dynamic>>('/menu/items/$id/availability');
    final item = (response.data?['data'] as Map<String, dynamic>)['item'];
    return MenuItem.fromJson(item as Map<String, dynamic>);
  }

  Future<void> deleteMenuItem(String id) async {
    await _api.dio.delete<void>('/menu/items/$id');
  }
}
