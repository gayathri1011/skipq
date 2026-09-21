import 'package:flutter/material.dart';

import '../config/menu_assets.dart';
import '../config/theme.dart';
import '../models/menu.dart';

class MenuItemImage extends StatelessWidget {
  const MenuItemImage({
    super.key,
    required this.item,
    this.width = 88,
    this.height = 88,
    this.borderRadius = 12,
  });

  final MenuItem item;
  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final localAsset = MenuAssets.localAssetFor(item);
    final networkUrl = item.imageUrl.trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final resolvedWidth = width.isFinite ? width : constraints.maxWidth;
        final resolvedHeight = height.isFinite ? height : constraints.maxHeight;

        return Semantics(
          image: true,
          label: '${item.name} image',
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              width: resolvedWidth,
              height: resolvedHeight,
              color: AppTheme.bgSubtle,
              child: networkUrl.isNotEmpty && localAsset != null
                  ? FadeInImage(
                      placeholder: AssetImage(localAsset),
                      image: NetworkImage(networkUrl),
                      width: resolvedWidth,
                      height: resolvedHeight,
                      fit: BoxFit.cover,
                      imageErrorBuilder: (_, __, ___) =>
                          _buildFallback(localAsset, resolvedWidth, resolvedHeight),
                    )
                  : networkUrl.isNotEmpty
                      ? Image.network(
                          networkUrl,
                          width: resolvedWidth,
                          height: resolvedHeight,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return _placeholder(
                              showProgress: true,
                              width: resolvedWidth,
                              height: resolvedHeight,
                            );
                          },
                          errorBuilder: (_, __, ___) =>
                              _buildFallback(localAsset, resolvedWidth, resolvedHeight),
                        )
                      : _buildFallback(localAsset, resolvedWidth, resolvedHeight),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFallback(
    String? localAsset,
    double resolvedWidth,
    double resolvedHeight,
  ) {
    if (localAsset != null) {
      return Image.asset(
        localAsset,
        width: resolvedWidth,
        height: resolvedHeight,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(
          width: resolvedWidth,
          height: resolvedHeight,
        ),
      );
    }
    return _placeholder(width: resolvedWidth, height: resolvedHeight);
  }

  Widget _placeholder({
    required double width,
    required double height,
    bool showProgress = false,
  }) {
    return Center(
      child: showProgress
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(
              Icons.restaurant_menu,
              color: AppTheme.textMuted,
              size: (width.isFinite ? width : height) * 0.34,
            ),
    );
  }
}
