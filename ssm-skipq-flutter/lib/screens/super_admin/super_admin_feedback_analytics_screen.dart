import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../models/feedback.dart';
import '../../services/feedback_service.dart';
import '../../services/super_admin_service.dart';
import '../../utils/helpers.dart';
import 'super_admin_date_filter.dart';

class FeedbackAnalyticsScreen extends StatefulWidget {
  const FeedbackAnalyticsScreen({
    super.key,
    required this.feedbackService,
    required this.superAdminService,
    this.initialSelection,
  });

  final FeedbackService feedbackService;
  final SuperAdminService superAdminService;
  final SuperAdminDateFilterSelection? initialSelection;

  @override
  State<FeedbackAnalyticsScreen> createState() => _FeedbackAnalyticsScreenState();
}

class _FeedbackAnalyticsScreenState extends State<FeedbackAnalyticsScreen> {
  List<OrderFeedback> _feedback = [];
  late SuperAdminDateFilterSelection _selection;
  bool _loading = true;
  String? _error;
  String _sortMode = 'All';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selection = widget.initialSelection ??
        SuperAdminDateFilterSelection(
          period: SuperAdminAnalyticsPeriod.year,
          label: '${now.year}',
          range: DateTimeRange(start: DateTime(now.year), end: DateTime(now.year + 1)),
        );
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _feedback = await widget.superAdminService.fetchFeedback();
    } catch (_) {
      _error = 'Unable to load feedback analytics data.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<OrderFeedback> get _periodFeedback => _feedback
      .where((entry) =>
          !entry.createdAt.isBefore(_selection.range.start) &&
          entry.createdAt.isBefore(_selection.range.end))
      .toList();

  List<OrderFeedback> get _visibleFeedback {
    final feedback = List<OrderFeedback>.of(_periodFeedback);
    feedback.sort(_compareFeedback);
    return feedback;
  }

  @override
  Widget build(BuildContext context) {
    final periodFeedback = _periodFeedback;
    return Scaffold(
      appBar: AppBar(title: const Text('Feedback Analytics')),
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
              _ratingSummary(periodFeedback),
              const SizedBox(height: 16),
              _ratingTrend(periodFeedback),
              const SizedBox(height: 12),
              _sortDropdown(),
              const SizedBox(height: 4),
              if (_visibleFeedback.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No reviews found for ${_selection.label.toLowerCase()}.', textAlign: TextAlign.center),
                )
              else
                ..._visibleFeedback.map(_feedbackCard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ratingSummary(List<OrderFeedback> feedback) {
    final total = feedback.length;
    final average = total == 0
        ? 0.0
        : feedback.fold<int>(0, (sum, entry) => sum + entry.rating) / total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryMuted,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 112,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${average.toStringAsFixed(1)}/5', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(99)),
                      child: Text('${average.toStringAsFixed(1)} ★', style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                    const SizedBox(height: 8),
                    Text('$total Review${total == 1 ? '' : 's'}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: List.generate(5, (index) {
                    final rating = 5 - index;
                    final count = feedback.where((entry) => entry.rating == rating).length;
                    final ratio = total == 0 ? 0.0 : count / total;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Row(
                        children: [
                          SizedBox(width: 28, child: Text('$rating ★', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: Stack(
                                children: [
                                  Container(height: 8, color: Colors.white),
                                  FractionallySizedBox(widthFactor: ratio, child: Container(height: 8, color: AppTheme.primary)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(width: 28, child: Text('$count', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ratingTrend(List<OrderFeedback> feedback) {
    final points = _trendPoints(feedback);
    final width = math.max(MediaQuery.sizeOf(context).width - 60, points.length * 42.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rating Trend', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(_selection.label, style: const TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: CustomPaint(
                  size: Size(width, 190),
                  painter: _RatingTrendPainter(points),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_TrendPoint> _trendPoints(List<OrderFeedback> feedback) {
    final start = _selection.range.start;
    final end = _selection.range.end;
    final points = <_TrendPoint>[];
    void addPoint(String label, DateTime bucketStart, DateTime bucketEnd) {
      final values = feedback
          .where((entry) => !entry.createdAt.isBefore(bucketStart) && entry.createdAt.isBefore(bucketEnd))
          .map((entry) => entry.rating)
          .toList();
        points.add(_TrendPoint(
          label, values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length));
    }

    switch (_selection.period) {
      case SuperAdminAnalyticsPeriod.day:
        for (var hour = 0; hour < 24; hour++) {
          final bucketStart = start.add(Duration(hours: hour));
          addPoint(DateFormat('ha').format(bucketStart), bucketStart, bucketStart.add(const Duration(hours: 1)));
        }
      case SuperAdminAnalyticsPeriod.month:
        for (var day = start; day.isBefore(end); day = day.add(const Duration(days: 1))) {
          addPoint('${day.day}', day, day.add(const Duration(days: 1)));
        }
      case SuperAdminAnalyticsPeriod.year:
        for (var month = 1; month <= 12; month++) {
          final bucketStart = DateTime(start.year, month);
          addPoint(DateFormat('MMM').format(bucketStart), bucketStart, DateTime(start.year, month + 1));
        }
      case SuperAdminAnalyticsPeriod.custom:
        final span = end.difference(start).inDays;
        if (span <= 92) {
          for (var day = start; day.isBefore(end); day = day.add(const Duration(days: 1))) {
            addPoint('${day.day}', day, day.add(const Duration(days: 1)));
          }
        } else {
          var month = DateTime(start.year, start.month);
          while (month.isBefore(end)) {
            addPoint(DateFormat('MMM').format(month), month, DateTime(month.year, month.month + 1));
            month = DateTime(month.year, month.month + 1);
          }
        }
    }
    return points;
  }

  Widget _sortDropdown() {
    return Align(
      alignment: Alignment.centerRight,
      child: PopupMenuButton<String>(
        initialValue: _sortMode,
        onSelected: (value) => setState(() => _sortMode = value),
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'All', child: Text('All')),
          PopupMenuItem(value: 'Most Helpful', child: Text('Most Helpful')),
          PopupMenuItem(value: 'Most Recent', child: Text('Most Recent')),
          PopupMenuItem(value: 'Positive First', child: Text('Positive First')),
          PopupMenuItem(value: 'Negative First', child: Text('Negative First')),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_sortMode, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w700)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _feedbackCard(OrderFeedback entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.order?.tokenNumber ?? 'Order', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Row(
              children: List.generate(5, (i) => Icon(
                    i < entry.rating ? Icons.star : Icons.star_border,
                    color: AppTheme.primary,
                    size: 18,
                  )),
            ),
            if (entry.review.isNotEmpty) Text(entry.review),
            if (entry.student != null) Text('${entry.student!.name} · ${entry.student!.mobile}'),
            Text(formatIstDateTime(entry.createdAt), style: const TextStyle(color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  int _compareFeedback(OrderFeedback left, OrderFeedback right) {
    switch (_sortMode) {
      case 'Positive First':
        return right.rating.compareTo(left.rating);
      case 'Negative First':
        return left.rating.compareTo(right.rating);
      case 'Most Helpful':
      case 'Most Recent':
        return right.createdAt.compareTo(left.createdAt);
      case 'All':
      default:
        return 0;
    }
  }
}

class _TrendPoint {
  const _TrendPoint(this.label, this.value);

  final String label;
  final double? value;
}

class _RatingTrendPainter extends CustomPainter {
  const _RatingTrendPainter(this.points);

  final List<_TrendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 28.0;
    const top = 8.0;
    const bottom = 28.0;
    final chartHeight = size.height - top - bottom;
    final chartWidth = size.width - left;
    final xStep = points.length <= 1 ? chartWidth : chartWidth / (points.length - 1);
    final gridPaint = Paint()..color = AppTheme.border;
    final linePaint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = AppTheme.primary;

    for (var rating = 1; rating <= 5; rating++) {
      final y = top + chartHeight * (5 - rating) / 4;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), gridPaint);
      _drawText(canvas, '$rating', Offset(4, y - 7), const TextStyle(fontSize: 10, color: AppTheme.textSecondary));
    }

    Offset? previous;
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final x = left + xStep * index;
      final value = point.value ?? 0;
      final y = top + chartHeight * (5 - value.clamp(0, 5)) / 5;
      final current = Offset(x, y);
      if (previous != null) canvas.drawLine(previous, current, linePaint);
      canvas.drawCircle(current, 4, dotPaint);
      previous = current;
      final labelStep = math.max(1, (points.length / 8).ceil());
      if (index % labelStep == 0 || index == points.length - 1) {
        _drawText(canvas, point.label, Offset(x - 14, size.height - 20), const TextStyle(fontSize: 9, color: AppTheme.textSecondary));
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset offset, TextStyle style) {
    final painter = TextPainter(text: TextSpan(text: text, style: style), textDirection: ui.TextDirection.ltr)..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _RatingTrendPainter oldDelegate) => oldDelegate.points != points;
}
