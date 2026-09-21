import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentBottomNavigationBar extends StatelessWidget {
  const StudentBottomNavigationBar({
    super.key,
    required this.selectedIndex,
  });

  final int selectedIndex;

  void _select(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/student');
        break;
      case 1:
        context.go('/student?tab=cart');
        break;
      case 2:
        context.go('/student?tab=track');
        break;
      case 3:
        context.go('/student?tab=profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (index) => _select(context, index),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.shopping_cart_outlined),
          selectedIcon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
        NavigationDestination(
          icon: Icon(Icons.list_alt_outlined),
          selectedIcon: Icon(Icons.list_alt),
          label: 'Track Order',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
