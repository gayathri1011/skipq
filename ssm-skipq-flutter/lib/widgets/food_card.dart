import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/menu.dart';
import '../providers/cart_provider.dart';
import 'veg_status_badge.dart';

class FoodCard extends StatelessWidget {
  const FoodCard({
    super.key,
    required this.item,
    required this.orderingOpen,
    this.isHighlyOrdered = false,
  });

  final MenuItem item;
  final bool orderingOpen;
  final bool isHighlyOrdered;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final vegBadge = VegStatusBadge(isVeg: item.isVeg);

    return SizedBox(
      width: 170,
      height: 240,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFCEEE6),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 132,
                    width: double.infinity,
                    child: AspectRatio(
                      aspectRatio: 1 / 0.85,
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFFF7E1D2),
                            child: const Icon(
                              Icons.image_not_supported_outlined,
                              size: 36,
                              color: Color(0xFFB86A3D),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (isHighlyOrdered)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: const Color(0xFFF59E0B).withOpacity(0.35),
                        ),
                      ),
                      child: const Text(
                        'Highly Ordered',
                        style: TextStyle(
                          color: Color(0xFFB45309),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                vegBadge,
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '₹${item.price}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: Color(0xFF111827),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFE4101),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 26),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => cart.addItem(
                    menuItemId: item.id,
                    name: item.name,
                    price: item.price,
                    imageUrl: item.imageUrl,
                    isVeg: item.isVeg,
                    available: item.available,
                  ),
                  child: const Text(
                    'ADD',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
