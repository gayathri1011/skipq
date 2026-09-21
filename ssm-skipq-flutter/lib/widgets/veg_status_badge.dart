import 'package:flutter/material.dart';

class VegStatusBadge extends StatelessWidget {
  const VegStatusBadge({
    super.key,
    required this.isVeg,
  });

  final bool isVeg;

  @override
  Widget build(BuildContext context) {
    final borderColor =
        isVeg ? const Color(0xFF16A34A) : const Color(0xFF7C2D12);
    final dotColor = isVeg ? const Color(0xFF16A34A) : const Color(0xFF7C2D12);
    final fillColor = isVeg ? const Color(0xFFE7F9EE) : const Color(0xFFF6EAE7);

    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor, width: 1.4),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
