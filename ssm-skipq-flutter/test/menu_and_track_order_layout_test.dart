import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ssm_skipq/config/theme.dart';
import 'package:ssm_skipq/models/feedback.dart';
import 'package:ssm_skipq/models/menu.dart';
import 'package:ssm_skipq/models/order.dart';
import 'package:ssm_skipq/providers/cart_provider.dart';
import 'package:ssm_skipq/screens/student/student_track_order_screen.dart';
import 'package:ssm_skipq/services/api_client.dart';
import 'package:ssm_skipq/services/feedback_service.dart';
import 'package:ssm_skipq/services/orders_service.dart';
import 'package:ssm_skipq/services/socket_service.dart';
import 'package:ssm_skipq/widgets/food_card.dart';
import 'package:ssm_skipq/widgets/student_bottom_navigation_bar.dart';

class FakeOrdersService extends OrdersService {
  FakeOrdersService() : super(ApiClient());

  @override
  Future<List<Order>> fetchMyOrders() async => const [];
}

class FakeSocketService extends SocketService {
  FakeSocketService() : super(ApiClient());

  @override
  void joinStudentRoom() {}

  @override
  void onOrderUpdated(void Function(Order order) handler) {}

  @override
  void off(String event) {}
}

class FakeFeedbackService extends FeedbackService {
  FakeFeedbackService() : super(ApiClient());

  @override
  Future<OrderFeedback> submitFeedback({
    required String orderId,
    required int rating,
    String? review,
  }) async {
    return OrderFeedback(
      id: 'fb-1',
      orderId: orderId,
      rating: rating,
      review: review ?? '',
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  testWidgets('Cart tab stays inside the student shell route', (tester) async {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: StudentBottomNavigationBar(selectedIndex: 0),
          ),
        ),
        GoRoute(
          path: '/student',
          builder: (_, __) => const Scaffold(body: Text('student shell')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();

    expect(router.routerDelegate.currentConfiguration.uri.toString(),
        '/student?tab=cart');
  });

  testWidgets('FoodCard shows Highly Ordered badge without changing layout',
      (tester) async {
    final item = MenuItem(
      id: 'menu-1',
      name: 'Samosa',
      description: 'Tasty item',
      price: 199,
      categoryId: 'main',
      categoryName: 'Main',
      imageUrl: 'https://example.com/item.jpg',
      isVeg: true,
      available: true,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CartProvider(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: Center(
            child: SizedBox(
              width: 170,
              child: FoodCard(
                item: item,
                orderingOpen: true,
                isHighlyOrdered: true,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Highly Ordered'), findsOneWidget);
    expect(find.text('ADD'), findsOneWidget);
    expect(find.text('Samosa'), findsOneWidget);
    expect(find.text('₹199'), findsOneWidget);
  });

  testWidgets(
      'FoodCard keeps the image in a square aspect ratio and name text compact',
      (tester) async {
    final item = MenuItem(
      id: 'menu-1',
      name:
          'Another really long menu item name that should ellipsize before overflow',
      description: 'Tasty item',
      price: 199,
      categoryId: 'main',
      categoryName: 'Main',
      imageUrl: 'https://example.com/item.jpg',
      isVeg: true,
      available: true,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CartProvider(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: Center(
            child: SizedBox(
              width: 170,
              child: FoodCard(item: item, orderingOpen: true),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AspectRatio), findsWidgets);
    expect(find.text('ADD'), findsOneWidget);
  });

  testWidgets('Current grid ratio stays within the card height',
      (tester) async {
    final item = MenuItem(
      id: 'menu-2',
      name: 'Another really long menu item name that should ellipsize',
      description: 'Tasty item',
      price: 199,
      categoryId: 'main',
      categoryName: 'Main',
      imageUrl: 'https://example.com/item.jpg',
      isVeg: true,
      available: true,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CartProvider(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: Scaffold(
              body: SizedBox(
                height: 220,
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.68,
                  children: [FoodCard(item: item, orderingOpen: true)],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('Menu grid keeps every card at a uniform fixed height',
      (tester) async {
    final items = List.generate(
      4,
      (index) => MenuItem(
        id: 'menu-$index',
        name: index.isEven ? 'Bajji' : 'Chicken Fried Rice Very Long Name',
        description: 'Tasty item',
        price: 199,
        categoryId: 'main',
        categoryName: 'Main',
        imageUrl: 'https://example.com/item.jpg',
        isVeg: index.isEven,
        available: true,
        createdAt: DateTime.now(),
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CartProvider(),
        child: MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(390, 844)),
            child: Scaffold(
              body: LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 12) / 2;
                  const targetHeight = 290.0;

                  return GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: cardWidth / targetHeight,
                    children: items
                        .map((item) => FoodCard(item: item, orderingOpen: true))
                        .toList(),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    final cardFinder = find.byType(FoodCard);
    final cardHeights = List.generate(
      cardFinder.evaluate().length,
      (index) => tester.getRect(cardFinder.at(index)).height,
    );

    expect(cardHeights.length, 4);
    expect(cardHeights.toSet().length, 1);
    expect(find.text('ADD'), findsNWidgets(4));
  });

  testWidgets('Track order shows the feedback form once the order is picked up',
      (tester) async {
    final order = Order(
      id: 'order-1',
      studentId: 'student-1',
      items: const [
        OrderItem(
            menuItemId: 'item-1', name: 'Sandwich', price: 120, quantity: 1),
      ],
      total: 120,
      paymentMethod: PaymentMethod.googlePay,
      paymentStatus: PaymentStatus.paid,
      status: OrderStatus.pickedUp,
      tokenNumber: 'A001',
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: StudentTrackOrderScreen(
          orderId: order.id,
          initialOrder: order,
          ordersService: FakeOrdersService(),
          socketService: FakeSocketService(),
          feedbackService: FakeFeedbackService(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('How was your order A001?'), findsOneWidget);
    expect(find.text('Submit Feedback'), findsOneWidget);
  });

  test('picked-up order remains a tracked order for feedback flow', () {
    final order = Order(
      id: 'order-2',
      studentId: 'student-2',
      items: const [
        OrderItem(menuItemId: 'item-2', name: 'Burger', price: 150, quantity: 1),
      ],
      total: 150,
      paymentMethod: PaymentMethod.googlePay,
      paymentStatus: PaymentStatus.paid,
      status: OrderStatus.pickedUp,
      tokenNumber: 'A002',
      createdAt: DateTime.now(),
    );

    expect(getCurrentActiveOrderForStudent([order], orderId: order.id), isNotNull);
  });
}
