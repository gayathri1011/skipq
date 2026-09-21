import 'package:flutter_test/flutter_test.dart';
import 'package:ssm_skipq/models/order.dart';
import 'package:ssm_skipq/screens/student/student_track_order_list_screen.dart';

void main() {
  group('getCurrentActiveOrderForStudent', () {
    test('returns null when all orders are completed or cancelled', () {
      final orders = [
        Order(
          id: 'old-1',
          studentId: 'student-1',
          items: const [],
          total: 120,
          paymentMethod: PaymentMethod.razorpay,
          paymentStatus: PaymentStatus.paid,
          status: OrderStatus.pickedUp,
          tokenNumber: 'A12',
          createdAt: DateTime.now(),
        ),
        Order(
          id: 'old-2',
          studentId: 'student-1',
          items: const [],
          total: 240,
          paymentMethod: PaymentMethod.payAtCounter,
          paymentStatus: PaymentStatus.pending,
          status: OrderStatus.cancelled,
          tokenNumber: 'A13',
          createdAt: DateTime.now(),
        ),
      ];

      expect(getCurrentActiveOrderForStudent(orders), isNull);
    });

    test('returns the newest active order when one is still in progress', () {
      final first = Order(
        id: 'new-1',
        studentId: 'student-1',
        items: const [],
        total: 180,
        paymentMethod: PaymentMethod.googlePay,
        paymentStatus: PaymentStatus.pending,
        status: OrderStatus.confirmed,
        tokenNumber: 'A14',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      final second = Order(
        id: 'new-2',
        studentId: 'student-1',
        items: const [],
        total: 220,
        paymentMethod: PaymentMethod.razorpay,
        paymentStatus: PaymentStatus.paid,
        status: OrderStatus.preparing,
        tokenNumber: 'A15',
        createdAt: DateTime.now(),
      );

      expect(getCurrentActiveOrderForStudent([first, second]), second);
    });
  });
}
