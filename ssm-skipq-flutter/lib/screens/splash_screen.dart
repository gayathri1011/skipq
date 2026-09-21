import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/assets.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../screens/student/student_auth_form.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _showAuth = false;
  late final AnimationController _heroController;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      if (auth.isStudent) {
        if (mounted) context.go('/student');
        return;
      }
      if (auth.isManager) {
        if (mounted) context.go('/manager');
      }
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    const displayFont = TextStyle();
    const bodyFont = TextStyle();
    final heroWidth =
        (MediaQuery.sizeOf(context).width * 0.72).clamp(220.0, 280.0);

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: StudentAuthForm(
              onManagerTap: () => context.go('/manager/login'),
            ),
          ),
          AnimatedSlide(
            duration: const Duration(milliseconds: 550),
            curve: const Cubic(0.32, 0.72, 0, 1),
            offset: _showAuth ? const Offset(0, -1) : Offset.zero,
            child: GestureDetector(
              onTap: () => setState(() => _showAuth = true),
              child: Material(
                color: AppTheme.primary,
                child: SafeArea(
                  child: Stack(
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedBuilder(
                                animation: _heroController,
                                builder: (context, child) {
                                  final y = Tween<double>(begin: 0, end: -10)
                                      .animate(CurvedAnimation(
                                        parent: _heroController,
                                        curve: Curves.easeInOut,
                                      ))
                                      .value;
                                  return Transform.translate(
                                    offset: Offset(0, y),
                                    child: child,
                                  );
                                },
                                child: SizedBox(
                                  width: heroWidth,
                                  child: ColorFiltered(
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.screen,
                                    ),
                                    child: Image.asset(
                                      AppAssets.splashHero,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'SkipQ@SSM',
                                style: displayFont.copyWith(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.02,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Skip the Queue. Grab Your Meal.',
                                textAlign: TextAlign.center,
                                style: bodyFont.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.92),
                                  height: 1.75,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 32,
                        child: Text(
                          'TAP TO CONTINUE',
                          textAlign: TextAlign.center,
                          style: displayFont.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.75),
                            letterSpacing: 0.06 * 16,
                          ),
                        ),
                      ),
                    ],
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
