import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/welcome_login_layout.dart';

class ManagerLoginScreen extends StatefulWidget {
  const ManagerLoginScreen({super.key});

  @override
  State<ManagerLoginScreen> createState() => _ManagerLoginScreenState();
}

class _ManagerLoginScreenState extends State<ManagerLoginScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    try {
      await auth.loginManager(
        _idController.text.trim().toUpperCase(),
        _passwordController.text,
      );
      if (mounted) context.go('/manager');
    } catch (e) {
      setState(() => _error = auth.messageFromError(e,
          fallback: 'Invalid Manager ID or password.'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isManager) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/manager');
      });
    }

    final displayFont = GoogleFonts.sora();

    return Scaffold(
      body: WelcomeLoginLayout(
        variant: WelcomeLoginVariant.manager,
        headline: 'Canteen Manager Portal',
        subtitle: 'Sign in to manage orders, menu, and daily operations.',
        footer: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('Student? ',
                style: GoogleFonts.inter(color: AppTheme.textSecondary)),
            TextButton(
              onPressed: () => context.go('/'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primary,
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Student login'),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Manager ID',
                style: displayFont.copyWith(
                    fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _idController,
              decoration: const InputDecoration(hintText: 'e.g. SSM001'),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),
            Text('Password',
                style: displayFont.copyWith(
                    fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                hintText: 'Your password',
                suffixIcon: IconButton(
                  tooltip: _showPassword ? 'Hide password' : 'Show password',
                  icon: Icon(
                      _showPassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
              ),
              obscureText: !_showPassword,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.errorMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: GoogleFonts.inter(fontSize: 14, color: AppTheme.error),
                ),
              ),
            ],
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Signing in…' : 'Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}
