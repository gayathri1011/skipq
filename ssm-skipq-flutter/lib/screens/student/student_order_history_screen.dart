import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../models/order.dart';
import '../../services/orders_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/order_status_badge.dart';

class StudentOrderHistoryScreen extends StatefulWidget {
  const StudentOrderHistoryScreen({
    super.key,
    required this.ordersService,
  });

  final OrdersService ordersService;

  @override
  State<StudentOrderHistoryScreen> createState() =>
      _StudentOrderHistoryScreenState();
}

class _StudentOrderHistoryScreenState extends State<StudentOrderHistoryScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;

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
      final orders = await widget.ordersService.fetchMyOrders();
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (!mounted) return;
      setState(() => _orders = orders);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Unable to load order history.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Order History',
      showBack: true,
      backTo: '/student?tab=profile',
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
                        itemBuilder: (context, index) =>
                            _OrderHistoryCard(order: _orders[index]),
                      ),
                    ),
    );
  }
}

class _OrderHistoryCard extends StatelessWidget {
  const _OrderHistoryCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final feedback = order.feedback;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.tokenNumber,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text(formatIstDateTime(order.createdAt),
                          style:
                              const TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                OrderStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: 12),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('${item.name} x ${item.quantity}'),
              ),
            ),
            const Divider(height: 20),
            Text('Amount paid: Rs ${order.total}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            const Text('Feedback',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            if (feedback == null || !order.hasFeedback)
              const Text('No feedback given',
                  style: TextStyle(color: AppTheme.textSecondary))
            else ...[
              Row(
                children: [
                  ...List.generate(
                    5,
                    (index) => Icon(
                      index < feedback.rating ? Icons.star : Icons.star_border,
                      size: 18,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${feedback.rating}/5'),
                ],
              ),
              if (feedback.review.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(feedback.review),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
