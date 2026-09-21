import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ordering_window_provider.dart';
import '../services/menu_service.dart';
import '../services/orders_service.dart';
import '../services/payment_service.dart';
import '../services/socket_service.dart';
import '../services/feedback_service.dart';
import '../screens/student/student_cart_screen.dart';
import '../screens/student/student_home_screen.dart';
import '../screens/student/student_track_order_list_screen.dart';
import '../screens/student/student_profile_screen.dart';
import 'student_bottom_navigation_bar.dart';

class StudentShell extends StatefulWidget {
  const StudentShell({
    super.key,
    required this.menuService,
    required this.ordersService,
    required this.socketService,
    required this.feedbackService,
    required this.paymentService,
    this.initialTab = 0,
  });

  final MenuService menuService;
  final OrdersService ordersService;
  final SocketService socketService;
  final FeedbackService feedbackService;
  final PaymentService paymentService;
  final int initialTab;

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  late int _index;
  final int _homeRefreshToken = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialTab.clamp(0, 3);
    context.read<OrderingWindowProvider>().initialize();
  }

  @override
  void didUpdateWidget(covariant StudentShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _index = widget.initialTab.clamp(0, 3);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      StudentHomeScreen(
        menuService: widget.menuService,
        ordersService: widget.ordersService,
        refreshToken: _homeRefreshToken,
      ),
      StudentCartScreen(
        menuService: widget.menuService,
        ordersService: widget.ordersService,
        paymentService: widget.paymentService,
      ),
      StudentTrackOrderListScreen(
        ordersService: widget.ordersService,
        socketService: widget.socketService,
        feedbackService: widget.feedbackService,
      ),
      const StudentProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SkipQ · Pre-Order · Pick Up'),
        centerTitle: true,
      ),
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: StudentBottomNavigationBar(selectedIndex: _index),
    );
  }
}
