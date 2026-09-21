import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/order.dart';
import '../../services/super_admin_service.dart';
import '../../utils/helpers.dart';
import 'super_admin_date_filter.dart';

class CancellationAnalyticsScreen extends StatefulWidget {
  const CancellationAnalyticsScreen({
    super.key,
    required this.superAdminService,
    this.initialSelection,
  });

  final SuperAdminService superAdminService;
  final SuperAdminDateFilterSelection? initialSelection;

  @override
  State<CancellationAnalyticsScreen> createState() =>
      _CancellationAnalyticsScreenState();
}

class _CancellationAnalyticsScreenState
    extends State<CancellationAnalyticsScreen> {
  List<Order> _orders = [];
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
      _orders = await widget.superAdminService.fetchOrders();
    } catch (_) {
      _error = 'Unable to load cancellation analytics data.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Order> get _periodOrders => _orders.where((order) =>
      !order.createdAt.isBefore(_selection.range.start) &&
      order.createdAt.isBefore(_selection.range.end)).toList();

  List<Order> get _cancelledOrders =>
      _periodOrders.where((order) => order.status == OrderStatus.cancelled).toList()
        ..sort((a, b) => (b.cancelledAt ?? b.createdAt)
            .compareTo(a.cancelledAt ?? a.createdAt));

  @override
  Widget build(BuildContext context) {
    final periodOrders = _periodOrders;
    final cancelled = _cancelledOrders;
    final rate = periodOrders.isEmpty ? 0.0 : cancelled.length * 100 / periodOrders.length;
    return Scaffold(
      appBar: AppBar(title: const Text('Cancellation Analytics')),
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
              Row(children: [
                Expanded(child: _statCard('Total Cancellations', '${cancelled.length}', Icons.cancel_outlined)),
                const SizedBox(width: 10),
                Expanded(child: _statCard('Cancellation Rate', '${rate.toStringAsFixed(1)}%', Icons.percent)),
              ]),
              const SizedBox(height: 16),
              _trend(cancelled),
              const SizedBox(height: 16),
              _recentList(cancelled),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: AppTheme.primary),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
      ]),
    ),
  );

  Widget _trend(List<Order> cancelled) {
    final points = _trendPoints(cancelled);
    final width = math.max(MediaQuery.sizeOf(context).width - 60, points.length * 42.0).toDouble();
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Cancellation Trend', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      Text(_selection.label, style: const TextStyle(color: AppTheme.textSecondary)),
      const SizedBox(height: 12),
      SizedBox(height: 210, child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: CustomPaint(size: Size(width, 190), painter: _CancellationTrendPainter(points)))),
    ])));
  }

  List<_CancellationPoint> _trendPoints(List<Order> cancelled) {
    final start = _selection.range.start;
    final end = _selection.range.end;
    final points = <_CancellationPoint>[];
    void add(String label, DateTime from, DateTime to) {
      final value = cancelled.where((order) {
        final date = order.cancelledAt ?? order.createdAt;
        return !date.isBefore(from) && date.isBefore(to);
      }).length;
      points.add(_CancellationPoint(label, value));
    }
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
          while (month.isBefore(end)) {
            add(DateFormat('MMM').format(month), month, DateTime(month.year, month.month + 1));
            month = DateTime(month.year, month.month + 1);
          }
        }
    }
    return points;
  }

  Widget _recentList(List<Order> cancelled) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Recent Cancellations', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (cancelled.isEmpty)
          Text('No cancellations found for ${_selection.label.toLowerCase()}.')
        else
          ...cancelled.map((order) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.receipt_long_outlined, color: AppTheme.primary),
            title: Text(order.tokenNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(order.items.map((item) => '${item.name} x${item.quantity}').join(', ')),
            trailing: Text(formatIstDateTime(order.cancelledAt ?? order.createdAt), textAlign: TextAlign.right),
          )),
      ]),
    ),
  );
}

class _CancellationPoint {
  const _CancellationPoint(this.label, this.value);
  final String label;
  final int value;
}

class _CancellationTrendPainter extends CustomPainter {
  const _CancellationTrendPainter(this.points);
  final List<_CancellationPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 28.0, top = 8.0, bottom = 28.0;
    final maxValue = points.fold<int>(0, (max, point) => math.max(max, point.value));
    final chartHeight = size.height - top - bottom;
    final step = points.length <= 1 ? size.width - left : (size.width - left) / (points.length - 1);
    final line = Paint()..color = AppTheme.primary..strokeWidth = 2.5..style = PaintingStyle.stroke;
    final path = Path();
    Offset? previous;
    for (var i = 0; i < points.length; i++) {
      final x = left + i * step;
      final y = top + chartHeight * (maxValue == 0 ? 1 : 1 - points[i].value / maxValue);
      final current = Offset(x, y);
      if (previous == null) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(current, 3.5, Paint()..color = AppTheme.primary);
      previous = current;
      final labelStep = math.max(1, (points.length / 8).ceil());
      if (i % labelStep == 0 || i == points.length - 1) {
        _text(canvas, points[i].label, Offset(x - 14, size.height - 20));
      }
    }
    for (var i = 0; i < 4; i++) {
      final y = top + chartHeight * i / 3;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), Paint()..color = AppTheme.border);
    }
    canvas.drawPath(path, line);
  }

  void _text(Canvas canvas, String value, Offset offset) {
    final painter = TextPainter(text: TextSpan(text: value, style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary)), textDirection: ui.TextDirection.ltr)..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _CancellationTrendPainter oldDelegate) => oldDelegate.points != points;
}
