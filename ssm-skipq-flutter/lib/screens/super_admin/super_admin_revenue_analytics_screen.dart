import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/menu.dart';
import '../../models/order.dart';
import '../../models/settings.dart';
import '../../services/super_admin_service.dart';
import '../../widgets/menu_item_image.dart';
import 'super_admin_date_filter.dart';

class RevenueAnalyticsScreen extends StatefulWidget {
  const RevenueAnalyticsScreen({
    super.key,
    required this.superAdminService,
    this.initialSelection,
  });

  final SuperAdminService superAdminService;
  final SuperAdminDateFilterSelection? initialSelection;

  @override
  State<RevenueAnalyticsScreen> createState() => _RevenueAnalyticsScreenState();
}

class _RevenueAnalyticsScreenState extends State<RevenueAnalyticsScreen> {
  List<Order> _orders = [];
  List<MenuItem> _menuItems = [];
  OrderingWindow _window = const OrderingWindow(
    orderingOpenTime: '09:30', orderingCloseTime: '11:30', isOpen: true);
  late SuperAdminDateFilterSelection _selection;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selection = widget.initialSelection ?? SuperAdminDateFilterSelection(
      period: SuperAdminAnalyticsPeriod.year,
      label: '${now.year}',
      range: DateTimeRange(start: DateTime(now.year), end: DateTime(now.year + 1)),
    );
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await Future.wait([
        widget.superAdminService.fetchOrders(),
        widget.superAdminService.fetchMenuItems(),
        widget.superAdminService.fetchOrderingWindow(),
      ]);
      _orders = result[0] as List<Order>;
      _menuItems = result[1] as List<MenuItem>;
      _window = result[2] as OrderingWindow;
    } catch (_) {
      _error = 'Unable to load revenue analytics data.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Order> get _completedOrders => _orders.where((order) => order.status == OrderStatus.pickedUp).toList();

  List<Order> get _periodOrders => _completedOrders.where((order) =>
      !order.createdAt.isBefore(_selection.range.start) &&
      order.createdAt.isBefore(_selection.range.end)).toList();

  num _revenue(Iterable<Order> orders) => orders.fold<num>(0, (sum, order) => sum + order.total);

  @override
  Widget build(BuildContext context) {
    final periodOrders = _periodOrders;
    return Scaffold(
      appBar: AppBar(title: const Text('Revenue Analytics')),
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
              const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: AppTheme.error))
            else ...[
              _revenueCard(_revenue(periodOrders)),
              const SizedBox(height: 16),
              _milestones(),
              const SizedBox(height: 16),
              _trend(periodOrders),
              const SizedBox(height: 16),
              _topItems(periodOrders),
              const SizedBox(height: 16),
              _heatmap(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _revenueCard(num revenue) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Total Revenue', style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        Text('₹${revenue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(_selection.label, style: const TextStyle(color: AppTheme.textMuted)),
      ]),
    ),
  );

  Widget _milestones() {
    final year = DateTime.now().year;
    final yearOrders = _completedOrders.where((order) => order.createdAt.year == year).toList();
    final byDay = <DateTime, num>{};
    final byMonth = <int, num>{};
    for (final order in yearOrders) {
      final day = DateTime(order.createdAt.year, order.createdAt.month, order.createdAt.day);
      byDay[day] = (byDay[day] ?? 0) + order.total;
      byMonth[order.createdAt.month] = (byMonth[order.createdAt.month] ?? 0) + order.total;
    }
    final bestDay = byDay.entries.isEmpty ? null : (byDay.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;
    final bestMonth = byMonth.entries.isEmpty ? null : (byMonth.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first;
    return Card(
      color: AppTheme.primaryMuted,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.emoji_events_outlined, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(bestDay == null ? 'Highest single-day revenue this year: ₹0' : 'Highest single-day revenue this year: ₹${bestDay.value.toStringAsFixed(0)} on ${DateFormat('d MMM').format(bestDay.key)}'),
            const SizedBox(height: 6),
            Text(bestMonth == null ? 'Best month so far: No completed revenue' : 'Best month so far: ${DateFormat('MMMM').format(DateTime(year, bestMonth.key))} (₹${bestMonth.value.toStringAsFixed(0)})'),
          ])),
        ]),
      ),
    );
  }

  Widget _trend(List<Order> orders) {
    final points = _trendPoints(orders);
    final width = math.max(MediaQuery.sizeOf(context).width - 60, points.length * 42.0).toDouble();
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Revenue Trend', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(_selection.label, style: const TextStyle(color: AppTheme.textSecondary)),
      const SizedBox(height: 12),
      SizedBox(height: 210, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: CustomPaint(size: Size(width, 190), painter: _RevenueTrendPainter(points)))),
    ])));
  }

  List<_RevenuePoint> _trendPoints(List<Order> orders) {
    final start = _selection.range.start;
    final end = _selection.range.end;
    final points = <_RevenuePoint>[];
    void add(String label, DateTime from, DateTime to) => points.add(_RevenuePoint(label, _revenue(orders.where((o) => !o.createdAt.isBefore(from) && o.createdAt.isBefore(to)).toList()).toDouble()));
    switch (_selection.period) {
      case SuperAdminAnalyticsPeriod.day:
        for (var hour = 0; hour < 24; hour++) {
          final from = start.add(Duration(hours: hour));
          add(DateFormat('ha').format(from), from, from.add(const Duration(hours: 1)));
        }
      case SuperAdminAnalyticsPeriod.month:
        for (var day = start; day.isBefore(end); day = day.add(const Duration(days: 1))) {
          add('${day.day}', day, day.add(const Duration(days: 1)));
        }
      case SuperAdminAnalyticsPeriod.year:
        for (var month = 1; month <= 12; month++) {
          final from = DateTime(start.year, month);
          add(DateFormat('MMM').format(from), from, DateTime(start.year, month + 1));
        }
      case SuperAdminAnalyticsPeriod.custom:
        if (end.difference(start).inDays <= 92) {
          for (var day = start; day.isBefore(end); day = day.add(const Duration(days: 1))) {
            add('${day.day}', day, day.add(const Duration(days: 1)));
          }
        } else {
          var month = DateTime(start.year, start.month);
          while (month.isBefore(end)) { add(DateFormat('MMM').format(month), month, DateTime(month.year, month.month + 1)); month = DateTime(month.year, month.month + 1); }
        }
    }
    return points;
  }

  Widget _topItems(List<Order> orders) {
    final totals = <String, _RevenueItem>{};
    for (final order in orders) {
      for (final item in order.items) {
        final entry = totals.putIfAbsent(item.menuItemId, () => _RevenueItem(item.name, item.quantity, item.price * item.quantity));
        entry.units += item.quantity;
        entry.revenue += item.price * item.quantity;
      }
    }
    final ranked = totals.values.toList()..sort((a, b) => b.revenue.compareTo(a.revenue));
    final total = _revenue(orders);
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Top Revenue Generating Items', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8),
      if (ranked.isEmpty) const Text('No completed order revenue for this period.'),
      ...ranked.take(5).map((entry) {
        final menuItem = _menuItems.where((item) => item.name == entry.name).firstOrNull;
        return ListTile(contentPadding: EdgeInsets.zero, leading: menuItem == null ? const Icon(Icons.restaurant_menu) : MenuItemImage(item: menuItem, width: 46, height: 46), title: Text(entry.name, style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${entry.units} units sold'), trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [Text('₹${entry.revenue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800)), Text('${total == 0 ? 0 : entry.revenue * 100 / total ~/ 1}%')]),);
      }),
    ])));
  }

  Widget _heatmap() {
    final open = _timeToHour(_window.orderingOpenTime);
    final close = _timeToHour(_window.orderingCloseTime).ceil();
    final rows = math.max(1, close - open).toInt();
    final values = List.generate(rows, (_) => List<num>.filled(7, 0));
    final cutoff = DateTime.now().subtract(const Duration(days: 90));
    for (final order in _completedOrders.where((o) => o.createdAt.isAfter(cutoff))) {
      final hour = order.createdAt.hour + order.createdAt.minute / 60;
      final row = hour.floor() - open.toInt();
      if (row >= 0 && row < rows) values[row][order.createdAt.weekday - 1] += order.total;
    }
    final maximum = values.expand((row) => row).fold<num>(0, math.max);
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Revenue Heatmap', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      const Text('Last 90 days · operating hours', style: TextStyle(color: AppTheme.textSecondary)),
      const SizedBox(height: 10),
      Row(children: [const SizedBox(width: 38), ...['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((day) => Expanded(child: Text(day, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10))))]),
      for (var row = 0; row < rows; row++) Row(children: [SizedBox(width: 38, child: Text('${open + row}:00', style: const TextStyle(fontSize: 10))), ...List.generate(7, (day) { final value = values[row][day]; return Expanded(child: Tooltip(message: '₹${value.toStringAsFixed(0)}', child: Container(height: 30, margin: const EdgeInsets.all(2), color: Color.lerp(AppTheme.primaryMuted, AppTheme.primary, maximum == 0 ? 0 : value / maximum)))); })]),
    ])));
  }

  double _timeToHour(String value) {
    final parts = value.split(':');
    return (double.tryParse(parts.first) ?? 9) + (double.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0) / 60;
  }
}

class _RevenueItem {
  _RevenueItem(this.name, this.units, this.revenue);
  final String name;
  int units;
  num revenue;
}

class _RevenuePoint {
  const _RevenuePoint(this.label, this.value);
  final String label;
  final double value;
}

class _RevenueTrendPainter extends CustomPainter {
  const _RevenueTrendPainter(this.points);
  final List<_RevenuePoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 34.0, top = 8.0, bottom = 28.0;
    final maxValue = points.fold<double>(0, (max, point) => math.max(max, point.value));
    final chartHeight = size.height - top - bottom;
    final step = points.length <= 1 ? size.width - left : (size.width - left) / (points.length - 1);
    final line = Paint()..color = AppTheme.primary..strokeWidth = 2.5..style = PaintingStyle.stroke;
    final fill = Paint()..color = AppTheme.primary.withValues(alpha: .14)..style = PaintingStyle.fill;
    final grid = Paint()..color = AppTheme.border;
    final path = Path(), area = Path();
    for (var i = 0; i < points.length; i++) {
      final x = left + i * step;
      final y = top + chartHeight * (maxValue == 0 ? 1 : 1 - points[i].value / maxValue);
      if (i == 0) { path.moveTo(x, y); area.moveTo(x, size.height - bottom); area.lineTo(x, y); } else { path.lineTo(x, y); area.lineTo(x, y); }
      canvas.drawCircle(Offset(x, y), 3.5, Paint()..color = AppTheme.primary);
      if (i % math.max(1, (points.length / 8).ceil()) == 0 || i == points.length - 1) {
        _text(canvas, points[i].label, Offset(x - 14, size.height - 20));
      }
    }
    area.lineTo(left + (points.length - 1) * step, size.height - bottom); area.close();
    for (var i = 0; i < 4; i++) {
      canvas.drawLine(Offset(left, top + chartHeight * i / 3), Offset(size.width, top + chartHeight * i / 3), grid);
    }
    canvas.drawPath(area, fill); canvas.drawPath(path, line);
  }

  void _text(Canvas canvas, String value, Offset offset) {
    final painter = TextPainter(text: TextSpan(text: value, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)), textDirection: ui.TextDirection.ltr)..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _RevenueTrendPainter oldDelegate) => oldDelegate.points != points;
}
