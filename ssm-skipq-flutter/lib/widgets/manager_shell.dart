import 'package:flutter/material.dart';

import '../services/feedback_service.dart';
import '../services/menu_service.dart';
import '../services/orders_service.dart';
import '../services/socket_service.dart';
import '../services/super_admin_service.dart';
import '../screens/manager/manager_dashboard_screen.dart';
import '../screens/manager/manager_feedback_screen.dart';
import '../screens/manager/manager_menu_screen.dart';
import '../screens/manager/manager_orders_screen.dart';
import '../screens/manager/manager_profile_screen.dart';

class ManagerShell extends StatefulWidget {
  const ManagerShell({
    super.key,
    required this.ordersService,
    required this.menuService,
    required this.feedbackService,
    required this.socketService,
    required this.superAdminService,
    this.initialTab = 0,
  });

  final OrdersService ordersService;
  final MenuService menuService;
  final FeedbackService feedbackService;
  final SocketService socketService;
  final SuperAdminService superAdminService;
  final int initialTab;

  @override
  State<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends State<ManagerShell> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialTab.clamp(0, 3);
  }

  @override
  void didUpdateWidget(covariant ManagerShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      setState(() => _index = widget.initialTab.clamp(0, 3));
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ManagerDashboardScreen(
        ordersService: widget.ordersService,
        socketService: widget.socketService,
        onViewOrders: () => setState(() => _index = 1),
      ),
      ManagerOrdersScreen(
        ordersService: widget.ordersService,
        socketService: widget.socketService,
      ),
      ManagerMenuScreen(menuService: widget.menuService),
      ManagerFeedbackScreen(feedbackService: widget.feedbackService),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manager Portal'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => ManagerProfileScreen(
                          superAdminService: widget.superAdminService,
                          ordersService: widget.ordersService,
                          feedbackService: widget.feedbackService,
                          menuService: widget.menuService,
                        )),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt),
              label: 'Orders'),
          NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu),
              label: 'Master'),
          NavigationDestination(
              icon: Icon(Icons.message_outlined),
              selectedIcon: Icon(Icons.message),
              label: 'Feedback'),
        ],
      ),
    );
  }
}
