import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/menu.dart';
import '../../models/order.dart';
import '../../models/payment.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/menu_service.dart';
import '../../services/orders_service.dart';
import '../../services/payment_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/menu_item_image.dart';
import '../../widgets/veg_status_badge.dart';

class StudentCartScreen extends StatefulWidget {
  const StudentCartScreen({
    super.key,
    required this.menuService,
    required this.ordersService,
    required this.paymentService,
  });

  final MenuService menuService;
  final OrdersService ordersService;
  final PaymentService paymentService;

  @override
  State<StudentCartScreen> createState() => _StudentCartScreenState();
}

class _StudentCartScreenState extends State<StudentCartScreen> {
  static const List<String> _crossSellHeaders = [
    'Pair it with...',
    'Goes great with this',
    'You might also like',
    "Don't forget these!",
    'A little something extra?',
    'Take it up a notch',
    'Perfect with your order',
    'One more thing?',
    'Level up your meal',
    'Tastes even better with',
    'Why stop here?',
    'Add a little more joy',
    'Fan favorites to add',
    'Make it a full meal',
    'Others also grabbed...',
  ];

  List<MenuItem> _catalog = [];
  late String _crossSellHeader;
  bool _checkoutOpen = false;
  PaymentMethod _paymentMethod = PaymentMethod.razorpay;
  bool _loadingConfig = true;
  bool _processing = false;
  String? _checkoutError;
  PaymentConfig? _paymentConfig;

  @override
  void initState() {
    super.initState();
    _crossSellHeader =
        _crossSellHeaders[Random().nextInt(_crossSellHeaders.length)];
    _loadCatalog();
    _loadPaymentConfig();
  }

  Future<void> _loadCatalog() async {
    try {
      final items = await widget.menuService.fetchMenuItems();
      if (!mounted) return;
      setState(() => _catalog = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _catalog = const []);
    }
  }

  Future<void> _loadPaymentConfig() async {
    try {
      final config = await widget.paymentService.fetchConfig();
      if (!mounted) return;
      setState(() {
        _paymentConfig = config;
        _paymentMethod = config.enabled
            ? PaymentMethod.razorpay
            : PaymentMethod.payAtCounter;
        _loadingConfig = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _paymentConfig =
            const PaymentConfig(enabled: false, keyId: '', testMode: false);
        _paymentMethod = PaymentMethod.payAtCounter;
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
      setState(() =>
          _checkoutError = 'Please log in as a student to place an order.');
      return;
    }

    setState(() {
      _processing = true;
      _checkoutError = null;
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
        paymentMethod: _paymentMethod,
        note: cart.note,
      );

      Order finalOrder = result.order;

      if (_paymentMethod == PaymentMethod.razorpay) {
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

      if (!mounted) return;
      setState(() => _checkoutOpen = false);
      cart.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully')),
      );
      context.go('/student/track-order/${finalOrder.id}', extra: finalOrder);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _checkoutError = e is String
            ? e
            : context.read<AuthProvider>().messageFromError(
                  e,
                  fallback: 'Unable to place order. Please try again.',
                );
      });
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  List<MenuItem> get _suggestions {
    final cart = context.read<CartProvider>();
    final inCartIds = cart.items.map((item) => item.menuItemId).toSet();
    final categoryIds = cart.items
        .where((item) => item.categoryId.isNotEmpty)
        .map((item) => item.categoryId)
        .toSet();

    final sameCategory = _catalog
        .where((item) => item.available)
        .where((item) => !inCartIds.contains(item.id))
        .where((item) =>
            categoryIds.isEmpty || categoryIds.contains(item.categoryId))
        .toList();

    final fallback = _catalog
        .where((item) => item.available)
        .where((item) => !inCartIds.contains(item.id))
        .toList();

    final base = sameCategory.isNotEmpty ? sameCategory : fallback;
    base.sort((a, b) => b.price.compareTo(a.price));
    return base.take(6).toList();
  }

  void _showNoteSheet(BuildContext context, CartProvider cart) {
    final controller = TextEditingController(text: cart.note);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add a note for the canteen',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Less spicy please',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () {
                    cart.setNote(controller.text);
                    context.pop();
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    if (cart.items.isEmpty) {
      return AppScaffold(
        title: 'Your Cart',
        showBack: true,
        backTo: '/student',
        body: EmptyState(
          icon: Icons.shopping_bag_outlined,
          title: 'Your cart is empty',
          message: 'Add something tasty from the menu to get started.',
          actionLabel: 'Browse Menu',
          onAction: () => context.go('/student'),
        ),
      );
    }

    final subtotal = cart.totalAmount;
    final taxes = 0;
    final total = subtotal + taxes;
    final suggestions = _suggestions;
    final razorpayEnabled = _paymentConfig?.enabled ?? false;

    return AppScaffold(
      title: 'Your Cart',
      showBack: true,
      backTo: '/student',
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...cart.items.map((item) {
                  final totalForItem = item.price * item.quantity;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              VegStatusBadge(isVeg: item.isVeg),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () =>
                                        cart.decrement(item.menuItemId),
                                    child: const Icon(Icons.remove, size: 16),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10),
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () =>
                                        cart.increment(item.menuItemId),
                                    child: const Icon(Icons.add, size: 16),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '₹$totalForItem',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                InkWell(
                  onTap: () => _showNoteSheet(context, cart),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSubtle,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryMuted,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.edit_note_outlined,
                            size: 18,
                            color: AppTheme.text,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Add a note for the canteen',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.text,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                if (cart.note.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      cart.note,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  _crossSellHeader,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 106,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: suggestions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final item = suggestions[index];
                      return Container(
                        width: 152,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: MenuItemImage(
                                item: item,
                                width: 48,
                                height: 48,
                                borderRadius: 10,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${item.price}',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const Spacer(),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: SizedBox(
                                      height: 24,
                                      child: FilledButton(
                                        onPressed: () => context
                                            .read<CartProvider>()
                                            .addItem(
                                              menuItemId: item.id,
                                              name: item.name,
                                              price: item.price,
                                              imageUrl: item.imageUrl,
                                              isVeg: item.isVeg,
                                              available: item.available,
                                              categoryId: item.categoryId,
                                              categoryName: item.categoryName,
                                            ),
                                        style: FilledButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 10),
                                          minimumSize: const Size(0, 24),
                                        ),
                                        child: const Text(
                                          '+',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSubtle,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal'),
                          Text('₹${subtotal.toStringAsFixed(0)}'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Taxes / Fees'),
                          Text('₹${taxes.toStringAsFixed(0)}'),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(fontWeight: FontWeight.w800)),
                          Text(
                            '₹${total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_checkoutOpen) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Payment Method',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        if (_loadingConfig)
                          const Center(child: CircularProgressIndicator())
                        else ...[
                          if (razorpayEnabled)
                            RadioListTile<PaymentMethod>(
                              contentPadding: EdgeInsets.zero,
                              value: PaymentMethod.razorpay,
                              groupValue: _paymentMethod,
                              onChanged: _processing
                                  ? null
                                  : (value) =>
                                      setState(() => _paymentMethod = value!),
                              title: const Text('Pay Online'),
                            )
                          else
                            Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 4),
                              child: Text(
                                'Online payment is not configured on the server yet. Use Pay at Counter, or add Razorpay test keys to the backend.',
                                style: TextStyle(
                                    color: Colors.grey.shade700, fontSize: 13),
                              ),
                            ),
                          RadioListTile<PaymentMethod>(
                            contentPadding: EdgeInsets.zero,
                            value: PaymentMethod.payAtCounter,
                            groupValue: _paymentMethod,
                            onChanged: _processing
                                ? null
                                : (value) =>
                                    setState(() => _paymentMethod = value!),
                            title: const Text('Pay at Counter'),
                          ),
                        ],
                        if (_checkoutError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _checkoutError!,
                            style: const TextStyle(color: AppTheme.error),
                          ),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _processing || _loadingConfig
                                ? null
                                : _placeOrder,
                            child: Text(
                                _processing ? 'Please wait…' : 'PLACE ORDER'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => setState(() => _checkoutOpen = true),
                      child: const Text('PROCEED TO CHECKOUT'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
