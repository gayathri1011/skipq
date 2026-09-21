import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/menu.dart';
import '../../models/order.dart';
import '../../services/menu_service.dart';
import '../../services/orders_service.dart';
import '../../services/feedback_service.dart';
import '../../services/super_admin_service.dart';
import '../../widgets/menu_item_image.dart';
import 'super_admin_feedback_analytics_screen.dart';
import 'super_admin_revenue_analytics_screen.dart';
import 'super_admin_cancellation_analytics_screen.dart';
import 'super_admin_date_filter.dart';

class SuperAdminAnalyticsDetailScreen extends StatelessWidget {
  const SuperAdminAnalyticsDetailScreen({
    super.key,
    required this.title,
    required this.filter,
    required this.ordersService,
    required this.menuService,
    required this.feedbackService,
    required this.superAdminService,
  });

  final String title;
  final SuperAdminDateFilterSelection filter;
  final OrdersService ordersService;
  final MenuService menuService;
  final FeedbackService feedbackService;
  final SuperAdminService superAdminService;

  @override
  Widget build(BuildContext context) {
    if (title == 'Order Analytics') {
      return OrderAnalyticsScreen(
        ordersService: ordersService,
        menuService: menuService,
        superAdminService: superAdminService,
        initialSelection: filter,
      );
    }
    if (title == 'Feedback Analytics') {
      return FeedbackAnalyticsScreen(
        feedbackService: feedbackService,
        superAdminService: superAdminService,
        initialSelection: filter,
      );
    }
    if (title == 'Revenue Analytics') {
      return RevenueAnalyticsScreen(
        superAdminService: superAdminService,
        initialSelection: filter,
      );
    }
    if (title == 'Cancellation Analytics') {
      return CancellationAnalyticsScreen(
        superAdminService: superAdminService,
        initialSelection: filter,
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
          child: Text('$title will be available soon.\n${filter.label}')),
    );
  }
}

class OrderAnalyticsScreen extends StatefulWidget {
  const OrderAnalyticsScreen({
    super.key,
    required this.ordersService,
    required this.menuService,
    required this.superAdminService,
    this.initialSelection,
  });

  final OrdersService ordersService;
  final MenuService menuService;
  final SuperAdminService superAdminService;
  final SuperAdminDateFilterSelection? initialSelection;

  @override
  State<OrderAnalyticsScreen> createState() => _OrderAnalyticsScreenState();
}

class _OrderAnalyticsScreenState extends State<OrderAnalyticsScreen> {
  List<Order> _orders = [];
  List<MenuItem> _menuItems = [];
  List<Category> _categories = [];
  late SuperAdminDateFilterSelection _selection;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selection = widget.initialSelection ??
        SuperAdminDateFilterSelection(
          period: SuperAdminAnalyticsPeriod.day,
          label: DateFormat('d MMM yyyy').format(now),
          range: DateTimeRange(
            start: DateTime(now.year, now.month, now.day),
            end: DateTime(now.year, now.month, now.day + 1),
          ),
        );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.superAdminService.fetchOrders(),
        widget.superAdminService.fetchMenuItems(),
        widget.superAdminService.fetchCategories(),
      ]);
      _orders = results[0] as List<Order>;
      _menuItems = results[1] as List<MenuItem>;
      _categories = results[2] as List<Category>;
    } catch (_) {
      _error = 'Unable to load order analytics data.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Order> get _filteredOrders => _orders.where((order) {
        return !order.createdAt.isBefore(_selection.range.start) &&
            order.createdAt.isBefore(_selection.range.end);
      }).toList();

  @override
  Widget build(BuildContext context) {
    final orders = _filteredOrders;
    final completed =
        orders.where((order) => order.status == OrderStatus.pickedUp).length;
    final cancelled =
        orders.where((order) => order.status == OrderStatus.cancelled).length;
    final completionRate =
        orders.isEmpty ? 0 : (completed * 100 / orders.length).round();
    final ranked = _rankedItems(orders);

    return Scaffold(
      appBar: AppBar(title: const Text('Order Analytics')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SuperAdminDateFilter(
              initialSelection: _selection,
              onChanged: (selection) => setState(() => _selection = selection),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: AppTheme.error))
            else ...[
              _statCards(orders.length, completed, cancelled),
              const SizedBox(height: 16),
              _metricRow(completionRate, orders.length),
              const SizedBox(height: 16),
              _categorySection(orders),
              const SizedBox(height: 16),
              _highlight(ranked),
              const SizedBox(height: 16),
              _topFive(ranked),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCards(int total, int completed, int cancelled) {
    return Row(
      children: [
        Expanded(
            child: _statCard(
                'Total Orders', '$total', Icons.receipt_long_outlined)),
        const SizedBox(width: 8),
        Expanded(
            child: _statCard(
                'Completed Orders', '$completed', Icons.check_circle_outline)),
        const SizedBox(width: 8),
        Expanded(
            child: _statCard(
                'Cancelled Orders', '$cancelled', Icons.cancel_outlined)),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primary, size: 20),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(int completionRate, int total) {
    final average = _averageLabel(total);
    return Row(
      children: [
        Expanded(
            child:
                _metricCard('$completionRate% completed', 'Completion rate')),
        if (average != null) ...[
          const SizedBox(width: 10),
          Expanded(child: _metricCard(average.$1, average.$2)),
        ],
      ],
    );
  }

  (String, String)? _averageLabel(int total) {
    switch (_selection.period) {
      case SuperAdminAnalyticsPeriod.day:
        return null;
      case SuperAdminAnalyticsPeriod.month:
        final days =
            _selection.range.end.difference(_selection.range.start).inDays;
        return ((total / days).toStringAsFixed(1), 'Average orders per day');
      case SuperAdminAnalyticsPeriod.year:
        return ((total / 12).toStringAsFixed(1), 'Average orders per month');
      case SuperAdminAnalyticsPeriod.custom:
        final days =
            _selection.range.end.difference(_selection.range.start).inDays;
        return (
          (total / math.max(days, 1)).toStringAsFixed(1),
          'Average orders per day'
        );
    }
  }

  Widget _metricCard(String value, String label) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _categorySection(List<Order> orders) {
    final buckets = _categoryBuckets(orders);
    final chartMax = _chartScaleMax(buckets.map((bucket) => bucket.value));
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Orders by Category',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(_selection.label,
                style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 14),
            SizedBox(
              height: 220,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: buckets.map((bucket) {
                    final height =
                        bucket.value == 0 ? 2.0 : 150 * bucket.value / chartMax;
                    return Tooltip(
                      message: '${bucket.value} orders',
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SizedBox(
                          width: buckets.length > 8 ? 52 : 68,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(height: 150 - height),
                              Container(
                                height: height,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(bucket.label,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Text('Scale: 0 - $chartMax orders',
                style:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  List<_CategoryBucket> _categoryBuckets(List<Order> orders) {
    final counts = <String, int>{
      for (final category in _categories) category.id: 0,
    };
    final menuItemsById = {
      for (final menuItem in _menuItems) menuItem.id: menuItem,
    };
    for (final order in orders) {
      for (final category in _categories) {
        final hasCategory = order.items.any((item) {
          final menuItem = menuItemsById[item.menuItemId];
          return menuItem?.categoryId == category.id ||
              menuItem?.categoryName == category.name;
        });
        if (hasCategory) counts[category.id] = (counts[category.id] ?? 0) + 1;
      }
    }
    final categoryBuckets = _categories
        .map((category) =>
            _CategoryBucket(category.name, counts[category.id] ?? 0))
        .toList();
    categoryBuckets.sort((a, b) => b.value.compareTo(a.value));
    return categoryBuckets;
  }

  Widget _highlight(List<_RankedItem> ranked) {
    final top = ranked.isEmpty ? null : ranked.first;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: top == null
            ? const Text(
                'Most Ordered Item\nNo order data available for this period')
            : Row(
                children: [
                  MenuItemImage(item: top.item, width: 82, height: 82),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Most Ordered Item',
                            style: TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(height: 5),
                        Text(top.item.name,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text('${top.quantity} ordered',
                            style:
                                const TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _topFive(List<_RankedItem> ranked) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top 5 Most Ordered Items',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            if (ranked.isEmpty)
              const Text('No order data available for this period')
            else
              ...ranked.take(5).toList().asMap().entries.map((entry) {
                final rankedItem = entry.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: MenuItemImage(
                    item: rankedItem.item,
                    width: 46,
                    height: 46,
                  ),
                  title: Text(rankedItem.item.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: const Text('Quantity Ordered'),
                  trailing: Text('${rankedItem.quantity}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                );
              }),
          ],
        ),
      ),
    );
  }

  List<_RankedItem> _rankedItems(List<Order> orders) {
    final quantities = <String, int>{};
    final names = <String, String>{};
    for (final order in orders) {
      for (final item in order.items) {
        quantities[item.menuItemId] =
            (quantities[item.menuItemId] ?? 0) + item.quantity;
        names[item.menuItemId] = item.name;
      }
    }
    final ranked = quantities.entries.map((entry) {
      final menuItem =
          _menuItems.where((item) => item.id == entry.key).firstOrNull;
      return _RankedItem(
        menuItem ??
            MenuItem(
              id: entry.key,
              name: names[entry.key] ?? 'Unknown item',
              description: '',
              price: 0,
              categoryId: '',
              categoryName: '',
              imageUrl: '',
              isVeg: true,
              available: true,
              createdAt: DateTime.now(),
            ),
        entry.value,
      );
    }).toList();
    ranked.sort((a, b) => b.quantity.compareTo(a.quantity));
    return ranked;
  }
}

class _CategoryBucket {
  const _CategoryBucket(this.label, this.value);

  final String label;
  final int value;
}

class _RankedItem {
  const _RankedItem(this.item, this.quantity);

  final MenuItem item;
  final int quantity;
}

int _chartScaleMax(Iterable<int> values) {
  final maximum = values.fold<int>(0, math.max);
  for (final step in [100, 1000, 5000, 10000]) {
    if (maximum <= step) return step;
  }
  var scale = 20000;
  while (scale < maximum) {
    scale *= 2;
  }
  return scale;
}
