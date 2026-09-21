import 'package:flutter_test/flutter_test.dart';
import 'package:ssm_skipq/models/dashboard_analytics.dart';
import 'package:ssm_skipq/models/order.dart';

void main() {
  test('dashboard analytics totals completed orders and best sellers', () {
    final orders = [
      Order(
        id: '1',
        studentId: 'student-1',
        items: [
          const OrderItem(
            menuItemId: 'rice',
            name: 'Rice',
            price: 40,
            quantity: 2,
          ),
          const OrderItem(
            menuItemId: 'tea',
            name: 'Tea',
            price: 20,
            quantity: 1,
          ),
        ],
        total: 100,
        paymentMethod: PaymentMethod.googlePay,
        paymentStatus: PaymentStatus.paid,
        status: OrderStatus.ready,
        tokenNumber: 'A001',
        createdAt: DateTime(2026, 9, 17),
      ),
      Order(
        id: '2',
        studentId: 'student-2',
        items: [
          const OrderItem(
            menuItemId: 'rice',
            name: 'Rice',
            price: 40,
            quantity: 1,
          ),
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
          const OrderItem(
            menuItemId: 'sambar',
            name: 'Sambar',
            price: 30,
            quantity: 2,
          ),
        ],
        total: 60,
        paymentMethod: PaymentMethod.googlePay,
        paymentStatus: PaymentStatus.paid,
        status: OrderStatus.pending,
        tokenNumber: 'A003',
        createdAt: DateTime(2026, 9, 19),
      ),
    ];

    final analytics = DashboardAnalytics.fromOrders(orders);

    expect(analytics.totalOrders, 3);
    expect(analytics.totalRevenue, 200);
    expect(analytics.completedOrders, 1);
    expect(analytics.topItems.first.name, 'Rice');
    expect(analytics.topItems.first.quantity, 3);
    expect(analytics.topItems.first.revenue, 120);
  });
}
