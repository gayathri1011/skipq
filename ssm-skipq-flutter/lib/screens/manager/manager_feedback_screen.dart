import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/feedback.dart';
import '../../services/feedback_service.dart';
import '../../utils/helpers.dart';

class ManagerFeedbackScreen extends StatefulWidget {
  const ManagerFeedbackScreen({super.key, required this.feedbackService});

  final FeedbackService feedbackService;

  @override
  State<ManagerFeedbackScreen> createState() => _ManagerFeedbackScreenState();
}

class _ManagerFeedbackScreenState extends State<ManagerFeedbackScreen> {
  List<OrderFeedback> _feedback = [];
  bool _loading = true;
  String? _error;
  String _sortMode = 'All';

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
      _feedback = await widget.feedbackService.fetchManagerFeedback();
    } catch (_) {
      _error = 'Unable to load feedback.';
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayFeedback = _feedback.where((entry) => isTodayIst(entry.createdAt)).toList();
    final visibleFeedback = List<OrderFeedback>.of(todayFeedback)
      ..sort(_compareFeedback);

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Feedback', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          _ratingSummary(todayFeedback),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PopupMenuButton<String>(
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
                  children: [
                    Text(_sortMode, style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, color: AppTheme.primary),
                  ],
                ),
              ),
            ],
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: AppTheme.error))
          else if (visibleFeedback.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No reviews yet today - check back later.'),
            )
          else
            ...visibleFeedback.map(
              (entry) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.order?.tokenNumber ?? 'Order',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < entry.rating ? Icons.star : Icons.star_border,
                            color: AppTheme.primary,
                            size: 18,
                          ),
                        ),
                      ),
                      if (entry.review.isNotEmpty) Text(entry.review),
                      if (entry.student != null)
                        Text('${entry.student!.name} · ${entry.student!.mobile}'),
                      Text(formatIstDateTime(entry.createdAt),
                          style: const TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ratingSummary(List<OrderFeedback> todayFeedback) {
    final total = todayFeedback.length;
    final average = total == 0
        ? 0.0
        : todayFeedback.fold<int>(0, (sum, entry) => sum + entry.rating) / total;

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
                    Text('${average.toStringAsFixed(1)}/5', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppTheme.text)),
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
                    final count = todayFeedback.where((entry) => entry.rating == rating).length;
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

  int _compareFeedback(OrderFeedback left, OrderFeedback right) {
    switch (_sortMode) {
      case 'All':
        return 0;
      case 'Positive First':
        return right.rating.compareTo(left.rating);
      case 'Negative First':
        return left.rating.compareTo(right.rating);
      case 'Most Helpful':
      case 'Most Recent':
      default:
        return right.createdAt.compareTo(left.createdAt);
    }
  }

}
