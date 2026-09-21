import 'package:ssm_skipq/models/order.dart';

class DashboardTopItem {
  const DashboardTopItem({
    required this.name,
    required this.quantity,
    required this.revenue,
  });

  final String name;
  final int quantity;
  final num revenue;

  factory DashboardTopItem.fromJson(Map<String, dynamic> json) {
    return DashboardTopItem(
      name: json['name'] as String? ?? 'Unknown',
      quantity: json['quantity'] as int? ?? 0,
      revenue: json['revenue'] as num? ?? 0,
    );
  }
}

class DashboardAnalytics {
  const DashboardAnalytics({
    this.totalOrders = 0,
    this.totalRevenue = 0,
    this.completedOrders = 0,
    this.topItems = const [],
  });

  final int totalOrders;
  final num totalRevenue;
  final int completedOrders;
  final List<DashboardTopItem> topItems;

  factory DashboardAnalytics.fromJson(Map<String, dynamic> json) {
    final itemList = (json['topItems'] as List<dynamic>? ?? [])
        .map((item) => DashboardTopItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return DashboardAnalytics(
      totalOrders: json['totalOrders'] as int? ?? 0,
      totalRevenue: json['totalRevenue'] as num? ?? 0,
      completedOrders: json['completedOrders'] as int? ?? 0,
      topItems: itemList,
    );
  }

  factory DashboardAnalytics.fromOrders(List<Order> orders) {
    final aggregate = <String, Map<String, dynamic>>{};
    num totalRevenue = 0;
    var completedOrders = 0;

    for (final order in orders) {
      if (order.status == OrderStatus.pickedUp) {
        totalRevenue += order.total;
        completedOrders++;
      }

      for (final item in order.items) {
        final key = item.name;
        final entry = aggregate.putIfAbsent(
          key,
          () => {'name': item.name, 'quantity': 0, 'revenue': 0},
        );
        entry['quantity'] = (entry['quantity'] as int) + item.quantity;
        entry['revenue'] = (entry['revenue'] as num) + item.price * item.quantity;
      }
    }

    final topItems = aggregate.values
        .map((entry) => DashboardTopItem(
              name: entry['name'] as String,
              quantity: entry['quantity'] as int,
              revenue: entry['revenue'] as num,
            ))
        .toList()
      ..sort((a, b) {
        final quantityCompare = b.quantity.compareTo(a.quantity);
        if (quantityCompare != 0) return quantityCompare;
        return b.revenue.compareTo(a.revenue);
      });

    return DashboardAnalytics(
      totalOrders: orders.length,
      totalRevenue: totalRevenue,
      completedOrders: completedOrders,
      topItems: topItems.take(5).toList(),
    );
  }
}
