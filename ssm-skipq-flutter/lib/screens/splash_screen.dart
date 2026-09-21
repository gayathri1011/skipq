import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
  with TickerProviderStateMixin {
  bool _showAuth = false;
  late final AnimationController _heroController;
  late final AnimationController _entranceController;
  late final Animation<double> _entranceOpacity;
  late final Animation<double> _entranceScale;

  @override
  void initState() {
    super.initState();
    _showAuth = false;
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    )..repeat(reverse: true);
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _entranceOpacity = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );
    _entranceScale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );
    _entranceController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (!mounted) return;
      if (auth.isStudent) {
        context.go('/student');
      } else if (auth.isManager) {
        context.go('/manager');
      }
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _openAuth() {
    if (context.read<AuthProvider>().isLoading) return;
    setState(() => _showAuth = true);
  }

  Widget _buildSplashLayer({
    required bool interactive,
    required bool showTapHint,
  }) {
    final displayFont = GoogleFonts.sora();
    final bodyFont = GoogleFonts.inter();
    final heroWidth =
        (MediaQuery.sizeOf(context).width * 0.72).clamp(220.0, 280.0);

    final content = Material(
      color: AppTheme.primary,
      child: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.sizeOf(context).height - 64,
                    maxWidth: 320,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
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
                        child: FadeTransition(
                          opacity: _entranceOpacity,
                          child: ScaleTransition(
                            scale: _entranceScale,
                            child: SizedBox(
                              width: heroWidth,
                              child: Image.asset(
                                AppAssets.splashHero,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.restaurant_menu,
                                  size: heroWidth * 0.5,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
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
            ),
            if (showTapHint)
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
    );

    if (!interactive) return content;

    return GestureDetector(
      onTap: _openAuth,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return Scaffold(
        body: _buildSplashLayer(interactive: false, showTapHint: false),
      );
    }

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
            child: _buildSplashLayer(interactive: !_showAuth, showTapHint: true),
          ),
        ],
      ),
    );
  }
}
