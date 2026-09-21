import 'package:dio/dio.dart';

import '../models/super_admin.dart';
import '../models/feedback.dart';
import '../models/menu.dart';
import '../models/order.dart';
import '../models/settings.dart';
import 'api_client.dart';

class SuperAdminService {
  SuperAdminService(this._api);

  final ApiClient _api;

  Options get _options => Options(headers: {
        'X-Super-Admin-Id': 'superadmin',
        'X-Super-Admin-Password': '1234admin',
      });

        Future<List<Order>> fetchOrders() async {
        final response = await _api.dio
          .get<Map<String, dynamic>>('/super-admin/orders', options: _options);
        final data = response.data?['data'] as Map<String, dynamic>?;
        return (data?['orders'] as List<dynamic>? ?? [])
          .map((item) => Order.fromJson(item as Map<String, dynamic>))
          .toList();
        }

        Future<List<OrderFeedback>> fetchFeedback() async {
        final response = await _api.dio
          .get<Map<String, dynamic>>('/super-admin/feedback', options: _options);
        final data = response.data?['data'] as Map<String, dynamic>?;
        return (data?['feedback'] as List<dynamic>? ?? [])
          .map((item) => OrderFeedback.fromJson(item as Map<String, dynamic>))
          .toList();
        }

        Future<List<MenuItem>> fetchMenuItems() async {
        final response = await _api.dio
          .get<Map<String, dynamic>>('/super-admin/menu-items', options: _options);
        final data = response.data?['data'] as Map<String, dynamic>?;
        return (data?['items'] as List<dynamic>? ?? [])
          .map((item) => MenuItem.fromJson(item as Map<String, dynamic>))
          .toList();
        }

  Future<List<ManagedManager>> fetchManagers() async {
    final response = await _api.dio
        .get<Map<String, dynamic>>('/super-admin/managers', options: _options);
    final data = response.data?['data'] as Map<String, dynamic>?;
    return (data?['managers'] as List<dynamic>? ?? [])
        .map((item) => ManagedManager.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Category>> fetchCategories() async {
    final response = await _api.dio
        .get<Map<String, dynamic>>('/super-admin/categories', options: _options);
    final data = response.data?['data'] as Map<String, dynamic>?;
    return (data?['categories'] as List<dynamic>? ?? [])
        .map((item) => Category.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<OrderingWindow> fetchOrderingWindow() async {
    final response = await _api.dio.get<Map<String, dynamic>>(
      '/super-admin/ordering-window',
      options: _options,
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    return OrderingWindow.fromJson(data ?? {});
  }

  Future<ManagedManager> createManager(
      {required String name,
      required String managerId,
      required String password}) async {
    final response = await _api.dio.post<Map<String, dynamic>>(
      '/super-admin/managers',
      data: {'name': name, 'managerId': managerId, 'password': password},
      options: _options,
    );
    final data = response.data?['data'] as Map<String, dynamic>?;
    return ManagedManager.fromJson(data?['manager'] as Map<String, dynamic>);
  }

  Future<void> deleteManager(String id) async {
    await _api.dio.delete<void>('/super-admin/managers/$id', options: _options);
  }
}
