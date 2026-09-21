import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/order.dart';
import '../../services/feedback_service.dart';
import '../../services/orders_service.dart';
import '../../services/socket_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/order_feedback_form.dart';
import '../../widgets/order_status_timeline.dart';
import '../../widgets/student_bottom_navigation_bar.dart';

class StudentTrackOrderScreen extends StatefulWidget {
  const StudentTrackOrderScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
    required this.ordersService,
    required this.socketService,
    required this.feedbackService,
    this.showBottomNavigation = false,
  });

  final String orderId;
  final Order? initialOrder;
  final OrdersService ordersService;
  final SocketService socketService;
  final FeedbackService feedbackService;
  final bool showBottomNavigation;

  @override
  State<StudentTrackOrderScreen> createState() =>
      _StudentTrackOrderScreenState();
}

class _StudentTrackOrderScreenState extends State<StudentTrackOrderScreen> {
  Order? _order;
  bool _loading = true;
  bool _cancelling = false;
  String? _error;
  final Set<String> _submittedFeedback = {};

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _loading = _order == null;
    _refresh();
    widget.socketService.joinStudentRoom();
    widget.socketService.onOrderUpdated(_handleOrderUpdated);
  }

  @override
  void dispose() {
    widget.socketService.off('order:updated');
    super.dispose();
  }

  void _handleOrderUpdated(Order updated) {
    if (updated.id == widget.orderId && mounted) {
      setState(() {
        _order = updated;
        _loading = false;
        _error = null;
      });
    }
  }

  Future<void> _refresh() async {
    try {
      final orders = await widget.ordersService.fetchMyOrders();
      final matches =
          orders.where((order) => order.id == widget.orderId).toList();
      final latest = matches.isEmpty ? widget.initialOrder : matches.first;
      if (!mounted) return;
      setState(() {
        _order = latest ?? _order;
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _order = widget.initialOrder ?? _order;
        _loading = false;
        _error = 'Unable to load order details.';
      });
    }
  }

  String _getStatusMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        return 'Your order has been received!';
      case OrderStatus.preparing:
        return 'The canteen is preparing your food.';
      case OrderStatus.ready:
        return 'Your order is ready! Please collect it from the counter using your token number.';
      case OrderStatus.pickedUp:
        return 'Order completed. Enjoy your meal!';
      case OrderStatus.cancelled:
        return 'This order has been cancelled.';
    }
  }

  Future<void> _cancelOrder() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cancel this order?'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Keep Order'),
            ),
            ElevatedButton(
              onPressed: () async {
                setDialogState(() => _cancelling = true);
                try {
                  final updated =
                      await widget.ordersService.cancelOrder(widget.orderId);
                  if (!mounted) return;
                  setState(() {
                    _order = updated;
                    _cancelling = false;
                  });
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Order cancelled')),
                  );
                } catch (_) {
                  if (dialogContext.mounted) {
                    setDialogState(() => _cancelling = false);
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Unable to cancel order. It may already be accepted.')),
                    );
                  }
                }
              },
              child: _cancelling
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Cancel Order'),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowFeedback(Order order) =>
      order.status == OrderStatus.pickedUp &&
      !order.hasFeedback &&
      !_submittedFeedback.contains(order.id);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppScaffold(
        title: 'Track Order',
        showBack: true,
        backTo: '/student',
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: widget.showBottomNavigation
            ? const StudentBottomNavigationBar(selectedIndex: 2)
            : null,
      );
    }

    if (_error != null && _order == null) {
      return AppScaffold(
        title: 'Track Order',
        showBack: true,
        backTo: '/student',
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 56, color: AppTheme.textMuted),
              const SizedBox(height: 16),
              const Text(
                'No order in progress right now',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Place an order from the menu to start tracking it here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil('/student', (route) => false),
                child: const Text('BROWSE MENU'),
              ),
            ],
          ),
        ),
        bottomNavigationBar: widget.showBottomNavigation
            ? const StudentBottomNavigationBar(selectedIndex: 2)
            : null,
      );
    }

    if (_order == null) {
      return AppScaffold(
        title: 'Track Order',
        showBack: true,
        backTo: '/student',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.receipt_long_outlined,
                    size: 56, color: AppTheme.textMuted),
                SizedBox(height: 16),
                Text(
                  'No order in progress right now',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  'Place an order from the menu to start tracking it here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: widget.showBottomNavigation
            ? const StudentBottomNavigationBar(selectedIndex: 2)
            : null,
      );
    }

    final order = _order!;

    return AppScaffold(
      title: 'Track Order',
      showBack: true,
      backTo: '/student',
      bottomNavigationBar: widget.showBottomNavigation
          ? const StudentBottomNavigationBar(selectedIndex: 2)
          : null,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              margin: EdgeInsets.zero,
              color: AppTheme.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('Your Token Number',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 12)),
                    Text(
                      order.tokenNumber,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _getStatusMessage(order.status),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (order.status == OrderStatus.pending) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _cancelling ? null : _cancelOrder,
                icon: const Icon(Icons.cancel_outlined),
                label: Text(_cancelling ? 'Cancelling…' : 'Cancel Order'),
              ),
            ],
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              color: AppTheme.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Status',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 16),
                    OrderStatusTimeline(status: order.status),
                  ],
                ),
              ),
            ),
            if (_shouldShowFeedback(order)) ...[
              const SizedBox(height: 16),
              OrderFeedbackForm(
                orderId: order.id,
                tokenNumber: order.tokenNumber,
                feedbackService: widget.feedbackService,
                onSubmitted: (feedback) {
                  setState(() {
                    _submittedFeedback.add(order.id);
                    _order = order.copyWith(
                      hasFeedback: true,
                      feedback: SubmittedFeedback(
                        rating: feedback.rating,
                        review: feedback.review,
                      ),
                    );
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Feedback submitted')),
                  );
                },
              ),
            ] else if (order.status == OrderStatus.pickedUp &&
                (order.hasFeedback ||
                    order.feedback != null ||
                    _submittedFeedback.contains(order.id))) ...[
              const SizedBox(height: 16),
              _FeedbackConfirmation(feedback: order.feedback),
            ],
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              color: AppTheme.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Order Details',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 12),
                    ...order.items.map(
                      (item) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('${item.name} × ${item.quantity}',
                            style: const TextStyle(fontSize: 14)),
                        trailing: Text('₹${item.price * item.quantity}',
                            style: const TextStyle(fontSize: 14)),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                        Text('₹${order.total}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _FeedbackConfirmation extends StatelessWidget {
  const _FeedbackConfirmation({required this.feedback});

  final SubmittedFeedback? feedback;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgSubtle,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thanks for your feedback!',
              style: TextStyle(fontWeight: FontWeight.w700)),
          if (feedback != null) ...[
            const SizedBox(height: 8),
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < feedback!.rating ? Icons.star : Icons.star_border,
                  color: AppTheme.primary,
                  size: 18,
                ),
              ),
            ),
            if (feedback!.review.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(feedback!.review),
            ],
          ],
        ],
      ),
    );
  }
}
