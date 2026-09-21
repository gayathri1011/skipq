import 'package:flutter/material.dart';

import '../config/assets.dart';

class FoodCollage extends StatefulWidget {
  const FoodCollage({super.key});

  @override
  State<FoodCollage> createState() => _FoodCollageState();
}

class _FoodCollageState extends State<FoodCollage>
    with TickerProviderStateMixin {
  static const _foods = [
    _FoodItem(AppAssets.collageFood1, -3, 0),
    _FoodItem(AppAssets.collageFood2, 2, 300),
    _FoodItem(AppAssets.collageFood3, -2, 600),
    _FoodItem(AppAssets.collageFood4, 3, 900),
  ];

  late final List<AnimationController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = _foods
        .map(
          (food) => AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 2400),
          ),
        )
        .toList();

    for (var i = 0; i < _foods.length; i++) {
      Future.delayed(Duration(milliseconds: _foods[i].delay), () {
        if (mounted) _controllers[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemWidth =
        (MediaQuery.sizeOf(context).width * 0.22).clamp(82.0, 112.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var i = 0; i < _foods.length; i++)
            SizedBox(
              width: i == 0 ? itemWidth : itemWidth * 0.78,
              child: AnimatedBuilder(
                animation: _controllers[i],
                builder: (context, child) {
                  final y = Tween<double>(begin: 0, end: -8)
                      .animate(CurvedAnimation(
                        parent: _controllers[i],
                        curve: Curves.easeInOut,
                      ))
                      .value;
                  return Transform.translate(
                    offset: Offset(0, y),
                    child: child,
                  );
                },
                child: Transform.rotate(
                  angle: _foods[i].rotate * 3.1415926535 / 180,
                  child: Container(
                    width: itemWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        _foods[i].asset,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FoodItem {
  const _FoodItem(this.asset, this.rotate, this.delay);

  final String asset;
  final double rotate;
  final int delay;
}
