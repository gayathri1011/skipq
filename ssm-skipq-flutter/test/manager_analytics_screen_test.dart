import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssm_skipq/config/theme.dart';
import 'package:ssm_skipq/models/menu.dart';
import 'package:ssm_skipq/models/order.dart';
import 'package:ssm_skipq/screens/manager/manager_analytics_screen.dart';
import 'package:ssm_skipq/services/api_client.dart';
import 'package:ssm_skipq/services/menu_service.dart';
import 'package:ssm_skipq/services/orders_service.dart';

class FakeOrdersService extends OrdersService {
  FakeOrdersService(this._orders) : super(ApiClient());

  final List<Order> _orders;

  @override
  Future<List<Order>> fetchManagerOrders() async => _orders;
}

class FakeMenuService extends MenuService {
  FakeMenuService(this._items) : super(ApiClient());

  final List<MenuItem> _items;

  @override
  Future<List<MenuItem>> fetchMenuItems() async => _items;
}

void main() {
  testWidgets('analytics summary uses the specified item card layout and labels', (tester) async {
    final orders = [
      Order(
        id: '1',
        studentId: 'student-1',
        items: [
          const OrderItem(menuItemId: 'rice', name: 'Chicken Biryani', price: 40, quantity: 24),
          const OrderItem(menuItemId: 'tea', name: 'Tea', price: 20, quantity: 6),
        ],
        total: 100,
        paymentMethod: PaymentMethod.googlePay,
        paymentStatus: PaymentStatus.paid,
        status: OrderStatus.pickedUp,
        tokenNumber: 'A001',
        createdAt: DateTime(2026, 9, 18),
      ),
      Order(
        id: '2',
        studentId: 'student-2',
        items: [
          const OrderItem(menuItemId: 'rice', name: 'Chicken Biryani', price: 40, quantity: 4),
        ],
        total: 40,
        paymentMethod: PaymentMethod.payAtCounter,
        paymentStatus: PaymentStatus.pending,
        status: OrderStatus.pickedUp,
        tokenNumber: 'A002',
        createdAt: DateTime(2026, 9, 18),
      ),
      Order(
        id: '3',
        studentId: 'student-3',
        items: [
          const OrderItem(menuItemId: 'tea', name: 'Tea', price: 20, quantity: 8),
        ],
        total: 60,
        paymentMethod: PaymentMethod.googlePay,
        paymentStatus: PaymentStatus.paid,
        status: OrderStatus.pickedUp,
        tokenNumber: 'A003',
        createdAt: DateTime(2026, 9, 18),
      ),
    ];

    final menuItems = [
      const MenuItem(
        id: 'rice',
        name: 'Chicken Biryani',
        description: 'Spicy biryani',
        price: 40,
        categoryId: 'main',
        categoryName: 'Main Course',
        imageUrl: 'https://example.com/chicken-biryani.jpg',
        isVeg: false,
        available: true,
      ),
      const MenuItem(
        id: 'tea',
        name: 'Tea',
        description: 'Hot tea',
        price: 20,
        categoryId: 'beverages',
        categoryName: 'Beverages',
        imageUrl: 'https://example.com/tea.jpg',
        isVeg: true,
        available: true,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ManagerAnalyticsScreen(
            ordersService: FakeOrdersService(orders),
            menuService: FakeMenuService(menuItems),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final textLabels = tester.widgetList<Text>(find.byType(Text)).map((w) => w.data).whereType<String>().toList();
    print('TEXT_LABELS=$textLabels');
    print('HAS_TITLE=${textLabels.any((label) => label.contains('Most Ordered Item'))}');
    print('TITLE_FINDER_COUNT=${find.byWidgetPredicate((w) => w is Text && w.data == 'Most Ordered Item').evaluate().length}');

    expect(textLabels.any((label) => label.contains('Most Ordered Item')), isTrue,
        reason: 'Expected the most-ordered summary header to be present in the rendered text tree.');
    expect(textLabels.any((label) => label == 'View All'), isTrue,
        reason: 'Expected the action button to be rendered in the summary card.');
    expect(textLabels.any((label) => label.contains('Top 5 Most Ordered Items')), isTrue,
        reason: 'Expected the top-five section title to be rendered.');
    expect(textLabels.any((label) => label == 'Quantity Ordered'), isTrue,
        reason: 'Expected the quantity label to be rendered in the ranking UI.');
    expect(textLabels.any((label) => label == 'Chicken Biryani'), isTrue,
        reason: 'Expected the top item to be visible in the analytics widget tree.');
  });
}
