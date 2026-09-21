import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/order.dart';
import '../../providers/cart_provider.dart';
import '../../services/feedback_service.dart';
import '../../services/menu_service.dart';
import '../../services/orders_service.dart';
import '../../services/socket_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/order_feedback_form.dart';
import '../../widgets/order_status_badge.dart';

class StudentOrdersScreen extends StatefulWidget {
  const StudentOrdersScreen({
    super.key,
    required this.ordersService,
    required this.menuService,
    required this.feedbackService,
    required this.socketService,
  });

  final OrdersService ordersService;
  final MenuService menuService;
  final FeedbackService feedbackService;
  final SocketService socketService;

  @override
  State<StudentOrdersScreen> createState() => _StudentOrdersScreenState();
}

class _StudentOrdersScreenState extends State<StudentOrdersScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;
  final Set<String> _submittedFeedback = {};

  @override
  void initState() {
    super.initState();
    _load();
    widget.socketService.joinStudentRoom();
    widget.socketService.onOrderUpdated((order) {
      setState(() {
        final idx = _orders.indexWhere((o) => o.id == order.id);
        if (idx >= 0) {
          _orders[idx] = order;
        }
      });
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _orders = await widget.ordersService.fetchMyOrders();
    } catch (_) {
      _error = 'Unable to load orders.';
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _reorder(Order order) async {
    if (order.status == OrderStatus.cancelled) return;
    try {
      final menuItems = await widget.menuService.fetchMenuItems();
      if (!mounted) return;
      final cart = context.read<CartProvider>();
      var added = 0;
      var skipped = 0;
      for (final line in order.items) {
        final match = menuItems
            .where((m) => m.id == line.menuItemId && m.available)
            .firstOrNull;
        if (match == null) {
          skipped++;
          continue;
        }
        cart.addItemWithQuantity(
          menuItemId: match.id,
          name: match.name,
          price: match.price,
          imageUrl: match.imageUrl,
          isVeg: match.isVeg,
          available: match.available,
          quantity: line.quantity,
        );
        added++;
      }
      if (added == 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nothing to reorder — items unavailable.')),
        );
        return;
      }
      if (skipped > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$skipped item(s) skipped — no longer available.')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Items added to cart')),
        );
      }
      if (mounted) context.go('/student?tab=cart');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reorder failed. Please try again.')),
        );
      }
    }
  }

  bool _needsFeedback(Order order) =>
      order.status == OrderStatus.pickedUp &&
      !order.hasFeedback &&
      !_submittedFeedback.contains(order.id);

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'My Orders',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _orders.isEmpty
                  ? const Center(child: Text('No orders yet.'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => context.go('/student/track-order/${order.id}'),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(order.tokenNumber,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 18)),
                                        OrderStatusBadge(status: order.status),
                                      ],
                                    ),
                                    Text(formatIstDateTime(order.createdAt),
                                        style: const TextStyle(color: AppTheme.textSecondary)),
                                    const SizedBox(height: 8),
                                    ...order.items.map(
                                      (item) => Text('${item.name} × ${item.quantity}'),
                                    ),
                                    const SizedBox(height: 8),
                                    Text('₹${order.total} · ${order.paymentMethod.label}'),
                                    const SizedBox(height: 12),
                                    if (order.status != OrderStatus.cancelled)
                                      OutlinedButton.icon(
                                        onPressed: () => _reorder(order),
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Reorder'),
                                      ),
                                    if (_needsFeedback(order)) ...[
                                      const SizedBox(height: 12),
                                      OrderFeedbackForm(
                                        orderId: order.id,
                                        tokenNumber: order.tokenNumber,
                                        feedbackService: widget.feedbackService,
                                        onSubmitted: (feedback) {
                                          setState(() {
                                            _submittedFeedback.add(order.id);
                                            _orders[index] =
                                                order.copyWith(
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
                                        (order.hasFeedback || order.feedback != null)) ...[
                                      const SizedBox(height: 12),
                                      _FeedbackConfirmation(feedback: order.feedback),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
