import 'package:flutter/material.dart';

import '../config/assets.dart';
import '../config/theme.dart';
import 'food_collage.dart';

enum WelcomeLoginVariant { student, manager }

class WelcomeLoginLayout extends StatelessWidget {
  const WelcomeLoginLayout({
    super.key,
    required this.headline,
    required this.child,
    this.variant = WelcomeLoginVariant.manager,
    this.subtitle,
    this.footer,
  });

  final String headline;
  final String? subtitle;
  final WelcomeLoginVariant variant;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final isStudent = variant == WelcomeLoginVariant.student;
    const displayFont = TextStyle();
    const bodyFont = TextStyle();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppTheme.primaryMuted, Colors.white],
          stops: [0.0, 0.38],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isStudent)
                  const FoodCollage()
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 32, 16, 8),
                    child: Center(
                      child: Image.asset(
                        AppAssets.logoAppIcon,
                        width: (MediaQuery.sizeOf(context).width * 0.42)
                            .clamp(120.0, 144.0),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isStudent)
                        Text(
                          'SkipQ@SSM',
                          textAlign: TextAlign.center,
                          style: displayFont.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                            letterSpacing: -0.02,
                          ),
                        ),
                      if (isStudent) const SizedBox(height: 8),
                      Text(
                        headline,
                        textAlign: TextAlign.center,
                        style: displayFont.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.text,
                          height: 1.25,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          subtitle!,
                          textAlign: TextAlign.center,
                          style: bodyFont.copyWith(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                            height: 1.75,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      child,
                      if (footer != null) ...[
                        const SizedBox(height: 32),
                        DefaultTextStyle(
                          style: bodyFont.copyWith(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                          child: footer!,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
