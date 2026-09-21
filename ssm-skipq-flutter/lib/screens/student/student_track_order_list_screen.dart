import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/order.dart';
import '../../services/feedback_service.dart';
import '../../services/orders_service.dart';
import '../../services/socket_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../screens/student/student_track_order_screen.dart';

class StudentTrackOrderListScreen extends StatefulWidget {
  const StudentTrackOrderListScreen({
    super.key,
    required this.ordersService,
    required this.socketService,
    required this.feedbackService,
  });

  final OrdersService ordersService;
  final SocketService socketService;
  final FeedbackService feedbackService;

  @override
  State<StudentTrackOrderListScreen> createState() =>
      _StudentTrackOrderListScreenState();
}

class _StudentTrackOrderListScreenState
    extends State<StudentTrackOrderListScreen> {
  bool _loading = true;
  String? _error;
  Order? _activeOrder;

  @override
  void initState() {
    super.initState();
    _load();
    widget.socketService.joinStudentRoom();
    widget.socketService.onOrderUpdated((order) {
      if (mounted && _activeOrder != null && order.id == _activeOrder!.id) {
        setState(() {
          _activeOrder = order.status == OrderStatus.cancelled ? null : order;
        });
      }
    });
  }

  @override
  void dispose() {
    widget.socketService.off('order:updated');
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final allOrders = await widget.ordersService.fetchMyOrders();
      final activeOrder = getCurrentActiveOrderForStudent(allOrders);

      if (mounted) {
        setState(() {
          _activeOrder = activeOrder;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Unable to load orders.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const AppScaffold(
        title: 'Track Order',
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return AppScaffold(
          title: 'Track Order', body: Center(child: Text(_error!)));
    }
    if (_activeOrder == null) {
      return AppScaffold(
        title: 'Track Order',
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shopping_bag_outlined,
                    size: 64, color: AppTheme.textMuted),
                const SizedBox(height: 16),
                const Text('No active order',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Browse the menu to place an order.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.go('/student'),
                  child: const Text('BROWSE MENU'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return StudentTrackOrderScreen(
      orderId: _activeOrder!.id,
      initialOrder: _activeOrder,
      ordersService: widget.ordersService,
      socketService: widget.socketService,
      feedbackService: widget.feedbackService,
    );
  }
}
