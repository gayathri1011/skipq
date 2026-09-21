import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/theme.dart';
import '../../models/order.dart';
import '../../services/orders_service.dart';
import '../../services/socket_service.dart';
import '../../utils/helpers.dart';
import '../../widgets/order_status_badge.dart';

class ManagerOrdersScreen extends StatefulWidget {
  const ManagerOrdersScreen({
    super.key,
    required this.ordersService,
    required this.socketService,
  });

  final OrdersService ordersService;
  final SocketService socketService;

  @override
  State<ManagerOrdersScreen> createState() => _ManagerOrdersScreenState();
}

class _ManagerOrdersScreenState extends State<ManagerOrdersScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  String? _error;
  String? _actionLoadingId;

  @override
  void initState() {
    super.initState();
    _load();
    widget.socketService.joinManagerRoom();
    widget.socketService.onOrderCreated(_upsertOrder);
    widget.socketService.onOrderUpdated(_upsertOrder);
  }

  void _upsertOrder(Order order) {
    setState(() {
      final idx = _orders.indexWhere((o) => o.id == order.id);
      if (idx >= 0) {
        _orders[idx] = order;
      } else {
        _orders.insert(0, order);
      }
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _orders = await widget.ordersService.fetchManagerOrders();
    } catch (_) {
      _error = 'Unable to load orders.';
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _advance(String orderId) async {
    setState(() => _actionLoadingId = orderId);
    try {
      final updated = await widget.ordersService.advanceStatus(orderId);
      _upsertOrder(updated);
    } catch (_) {
      setState(() => _error = 'Unable to update order status.');
    } finally {
      setState(() => _actionLoadingId = null);
    }
  }

  Future<void> _markPaymentReceived(Order order) async {
    if (order.paymentStatus == PaymentStatus.paid) return;
    setState(() => _actionLoadingId = order.id);
    try {
      final updated =
          await widget.ordersService.updatePayment(order.id, PaymentStatus.paid);
      _upsertOrder(updated);
    } catch (_) {
      setState(() => _error = 'Unable to update payment status.');
    } finally {
      setState(() => _actionLoadingId = null);
    }
  }

  Future<void> _call(String mobile) async {
    final uri = Uri.parse('tel:$mobile');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final todayOrders =
        _orders.where((o) => isTodayIst(o.createdAt)).toList();
    final active = todayOrders
        .where((o) =>
            o.status != OrderStatus.pickedUp && o.status != OrderStatus.cancelled)
        .length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('$active active · ${todayOrders.length} today'),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Text(_error!, style: const TextStyle(color: AppTheme.error))
          else if (todayOrders.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No orders yet today. New orders appear instantly.'),
            )
          else
            ...todayOrders.map((order) {
              final action = order.status.managerAction;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
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
                                  fontSize: 20, fontWeight: FontWeight.w800)),
                          OrderStatusBadge(status: order.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...order.items.map((item) => Text('${item.name} × ${item.quantity}')),
                      const SizedBox(height: 8),
                      Text('₹${order.total} · ${order.paymentMethod.label} · '
                          '${order.paymentStatus == PaymentStatus.paid ? 'Paid' : 'Pending'}'),
                      if (order.student != null)
                        Text('${order.student!.name} · ${order.student!.mobile}'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (action != null)
                            ElevatedButton(
                              onPressed: _actionLoadingId == order.id
                                  ? null
                                  : () => _advance(order.id),
                              child: Text(_actionLoadingId == order.id ? '…' : action),
                            ),
                          if (order.paymentMethod == PaymentMethod.payAtCounter &&
                              order.paymentStatus == PaymentStatus.pending)
                            OutlinedButton(
                              onPressed: _actionLoadingId == order.id
                                  ? null
                                  : () => _markPaymentReceived(order),
                              child: const Text('Mark Payment Received'),
                            ),
                          if (order.paymentMethod == PaymentMethod.payAtCounter &&
                              order.paymentStatus == PaymentStatus.paid)
                            const OutlinedButton(
                              onPressed: null,
                              child: Text('Payment Received ✓'),
                            ),
                          if (order.student != null)
                            OutlinedButton.icon(
                              onPressed: () => _call(order.student!.mobile),
                              icon: const Icon(Icons.phone),
                              label: const Text('Call Student'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
