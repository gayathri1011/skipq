import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/feedback.dart';
import '../services/feedback_service.dart';

class OrderFeedbackForm extends StatefulWidget {
  const OrderFeedbackForm({
    super.key,
    required this.orderId,
    required this.tokenNumber,
    required this.feedbackService,
    required this.onSubmitted,
  });

  final String orderId;
  final String tokenNumber;
  final FeedbackService feedbackService;
  final ValueChanged<OrderFeedback> onSubmitted;

  @override
  State<OrderFeedbackForm> createState() => _OrderFeedbackFormState();
}

class _OrderFeedbackFormState extends State<OrderFeedbackForm> {
  int _rating = 0;
  final _reviewController = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating < 1) {
      setState(() => _error = 'Please select a star rating.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final feedback = await widget.feedbackService.submitFeedback(
        orderId: widget.orderId,
        rating: _rating,
        review: _reviewController.text,
      );
      widget.onSubmitted(feedback);
    } catch (_) {
      setState(() => _error = 'Unable to submit feedback. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How was your order ${widget.tokenNumber}?',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              final value = index + 1;
              return IconButton(
                onPressed: () => setState(() => _rating = value),
                icon: Icon(
                  value <= _rating ? Icons.star : Icons.star_border,
                  color: AppTheme.primary,
                ),
              );
            }),
          ),
          TextField(
            controller: _reviewController,
            maxLines: 3,
            maxLength: 500,
            decoration: const InputDecoration(
              hintText: 'Optional short review…',
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          if (_error != null)
            Text(_error!, style: const TextStyle(color: AppTheme.error)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Submitting…' : 'Submit Feedback'),
            ),
          ),
        ],
      ),
    );
  }
}
