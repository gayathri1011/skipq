import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/order.dart';
import '../../services/orders_service.dart';
import '../../services/socket_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/order_status_timeline.dart';

class StudentOrderConfirmationScreen extends StatefulWidget {
  const StudentOrderConfirmationScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
    required this.ordersService,
    required this.socketService,
  });

  final String orderId;
  final Order? initialOrder;
  final OrdersService ordersService;
  final SocketService socketService;

  @override
  State<StudentOrderConfirmationScreen> createState() =>
      _StudentOrderConfirmationScreenState();
}

class _StudentOrderConfirmationScreenState
    extends State<StudentOrderConfirmationScreen> {
  Order? _order;
  bool _loading = true;
  String? _error;

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
      final latest = orders.where((o) => o.id == widget.orderId).firstOrNull;
      if (!mounted) return;
      if (latest != null) {
        setState(() {
          _order = latest;
          _loading = false;
          _error = null;
        });
      } else if (_order == null) {
        setState(() {
          _loading = false;
          _error = 'Order not found.';
        });
      }
    } catch (_) {
      if (!mounted) return;
      if (_order == null) {
        setState(() {
          _loading = false;
          _error = 'Unable to load order details.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppScaffold(
        title: 'My Order',
        showBack: true,
        backTo: '/student',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _order == null) {
      return AppScaffold(
        title: 'My Order',
        showBack: true,
        backTo: '/student',
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error ?? 'Order not found.'),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.go('/student'),
                child: const Text('BACK TO HOME'),
              ),
            ],
          ),
        ),
      );
    }

    final order = _order!;

    return AppScaffold(
      title: 'My Order',
      showBack: true,
      backTo: '/student',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryMuted,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('Token Number', style: TextStyle(color: AppTheme.textSecondary)),
                Text(
                  order.tokenNumber,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Order Placed'),
                        Text(formatIstTime(order.createdAt)),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Payment'),
                        Text(order.paymentMethod.label),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (order.status == OrderStatus.ready) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Order ${order.tokenNumber} is ready for pickup.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text('Order Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 12),
          OrderStatusTimeline(status: order.status),
          const SizedBox(height: 24),
          const Text('Order Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ...order.items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${item.name} × ${item.quantity}'),
              trailing: Text('₹${item.price * item.quantity}'),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('₹${order.total}', style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: () => context.go('/student'),
            child: const Text('BACK TO HOME'),
          ),
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
