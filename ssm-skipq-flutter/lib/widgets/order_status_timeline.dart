import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/order.dart';

class OrderStatusTimeline extends StatelessWidget {
  const OrderStatusTimeline({super.key, required this.status});

  final OrderStatus status;

  static const _steps = [
    (OrderStatus.pending, 'Order Placed', Icons.receipt_long_outlined),
    (OrderStatus.preparing, 'Preparing', Icons.kitchen_outlined),
    (OrderStatus.ready, 'Ready for Pickup', Icons.restaurant_menu_outlined),
    (OrderStatus.pickedUp, 'Collected', Icons.check_circle_outline),
  ];

  int _rank(OrderStatus s) {
    switch (s) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
        return 0;
      case OrderStatus.preparing:
        return 1;
      case OrderStatus.ready:
        return 2;
      case OrderStatus.pickedUp:
        return 3;
      case OrderStatus.cancelled:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _rank(status);

    return SizedBox(
      height: 86,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          children: [
            Positioned(
              top: 19,
              left: constraints.maxWidth / 8,
              right: constraints.maxWidth / 8,
              child: Container(
                height: 3,
                color: status == OrderStatus.cancelled || current < 1
                    ? AppTheme.border
                    : AppTheme.primary,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(_steps.length, (index) {
              final step = _steps[index];
              final isDone = status != OrderStatus.cancelled && current > index;
              final isCurrent = status != OrderStatus.cancelled && current == index;
              final isFuture = status != OrderStatus.cancelled && current < index;
              final contentColor = isDone || isCurrent
                  ? AppTheme.primary
                  : AppTheme.textMuted;
              final fillColor = index == _steps.length - 1 &&
                      status == OrderStatus.pickedUp
                  ? AppTheme.primary
                  : isDone || isCurrent
                  ? Colors.white
                      : AppTheme.gray100;
              final borderColor = isDone || isCurrent
                  ? AppTheme.primary
                  : AppTheme.border;

              return Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: fillColor,
                        border: Border.all(color: borderColor, width: 2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(step.$3, color: contentColor, size: 19),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      step.$2,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w600,
                        color: isFuture ? AppTheme.textMuted : AppTheme.text,
                      ),
                    ),
                  ],
                ),
              );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
