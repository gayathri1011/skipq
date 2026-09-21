import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/order.dart';
import '../../models/payment.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/orders_service.dart';
import '../../services/payment_service.dart';
import '../../widgets/app_scaffold.dart';

class StudentCheckoutScreen extends StatefulWidget {
  const StudentCheckoutScreen({
    super.key,
    required this.ordersService,
    required this.paymentService,
  });

  final OrdersService ordersService;
  final PaymentService paymentService;

  @override
  State<StudentCheckoutScreen> createState() => _StudentCheckoutScreenState();
}

class _StudentCheckoutScreenState extends State<StudentCheckoutScreen> {
  PaymentMethod _method = PaymentMethod.razorpay;
  bool _processing = false;
  bool _orderPlaced = false;
  bool _loadingConfig = true;
  String? _error;
  PaymentConfig? _paymentConfig;

  @override
  void initState() {
    super.initState();
    _loadPaymentConfig();
  }

  @override
  void dispose() {
    widget.paymentService.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentConfig() async {
    try {
      final config = await widget.paymentService.fetchConfig();
      if (!mounted) return;
      setState(() {
        _paymentConfig = config;
        _method = config.enabled ? PaymentMethod.razorpay : PaymentMethod.payAtCounter;
        _loadingConfig = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _paymentConfig = const PaymentConfig(enabled: false, keyId: '', testMode: false);
        _method = PaymentMethod.payAtCounter;
        _loadingConfig = false;
      });
    }
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) return;

    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user is! StudentUser) {
      setState(() => _error = 'Please log in as a student to place an order.');
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      final result = await widget.ordersService.createOrder(
        items: cart.items
            .map(
              (item) => OrderItem(
                menuItemId: item.menuItemId,
                name: item.name,
                price: item.price,
                quantity: item.quantity,
              ),
            )
            .toList(),
        total: cart.totalAmount,
        paymentMethod: _method,
        note: cart.note,
      );

      Order finalOrder = result.order;

      if (_method == PaymentMethod.razorpay) {
        final checkout = result.razorpay;
        if (checkout == null) {
          throw Exception('Razorpay checkout was not returned by the server');
        }

        final payment = await widget.paymentService.openRazorpayCheckout(
          checkout: checkout,
          skipqOrderId: result.order.id,
          customerName: user.name,
          customerMobile: user.mobile,
          description: 'SkipQ order ${result.order.tokenNumber}',
        );

        finalOrder = await widget.paymentService.verifyRazorpayPayment(
          orderId: result.order.id,
          payment: payment,
        );
      }

      if (mounted) {
        setState(() => _orderPlaced = true);
        cart.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed successfully')),
        );
        context.go(
          '/student/track-order/${finalOrder.id}',
          extra: finalOrder,
        );
      }
    } catch (e) {
      setState(() {
        _error = e is String
            ? e
            : context.read<AuthProvider>().messageFromError(
                  e,
                  fallback: 'Unable to place order. Please try again.',
                );
      });
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    if (cart.items.isEmpty && !_processing && !_orderPlaced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/student');
      });
    }

    final razorpayEnabled = _paymentConfig?.enabled ?? false;

    return AppScaffold(
      title: 'Checkout',
      showBack: true,
      backTo: '/student?tab=cart',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Your Order', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          ...cart.items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.name),
              subtitle: Text('× ${item.quantity}'),
              trailing: Text('₹${item.price * item.quantity}'),
            ),
          ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              Text(
                '₹${cart.totalAmount}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          if (_loadingConfig)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            if (razorpayEnabled)
              RadioMenuButton<PaymentMethod>(
                value: PaymentMethod.razorpay,
                groupValue: _method,
                onChanged: _processing ? null : (v) => setState(() => _method = v!),
                child: const Text('Pay Online'),
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  'Online payment is not configured on the server yet. Use Pay at Counter, or add Razorpay test keys to the backend.',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ),
            RadioMenuButton<PaymentMethod>(
              value: PaymentMethod.payAtCounter,
              groupValue: _method,
              onChanged: _processing ? null : (v) => setState(() => _method = v!),
              child: const Text('Pay at Counter'),
            ),
          ],
          if (_processing)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_error!, style: const TextStyle(color: AppTheme.error)),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _processing || _loadingConfig ? null : _placeOrder,
            child: Text(_processing ? 'Please wait…' : 'PLACE ORDER'),
          ),
        ],
      ),
    );
  }
}
