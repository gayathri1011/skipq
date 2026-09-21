import 'package:flutter/material.dart';

import '../../config/theme.dart';
import '../../services/super_admin_service.dart';
import '../../services/orders_service.dart';
import '../../services/feedback_service.dart';
import '../../services/menu_service.dart';
import 'super_admin_shell.dart';
import 'super_admin_session.dart';

class SuperAdminLoginScreen extends StatefulWidget {
  const SuperAdminLoginScreen({
    super.key,
    required this.superAdminService,
    required this.ordersService,
    required this.feedbackService,
    required this.menuService,
  });

  final SuperAdminService superAdminService;
  final OrdersService ordersService;
  final FeedbackService feedbackService;
  final MenuService menuService;

  @override
  State<SuperAdminLoginScreen> createState() => _SuperAdminLoginScreenState();
}

class _SuperAdminLoginScreenState extends State<SuperAdminLoginScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _idController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    final valid = _idController.text.trim() == 'superadmin' &&
        _passwordController.text == '1234admin';
    if (!valid) {
      setState(() => _error = 'Invalid Super Admin ID or password.');
      return;
    }

    SuperAdminSession.start();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          builder: (_) => SuperAdminShell(
                superAdminService: widget.superAdminService,
                ordersService: widget.ordersService,
                feedbackService: widget.feedbackService,
                menuService: widget.menuService,
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgSubtle,
      appBar: AppBar(title: const Text('Super Admin Access')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 34,
                      backgroundColor: AppTheme.primaryMuted,
                      child: Icon(Icons.admin_panel_settings_outlined,
                          color: AppTheme.primary, size: 36),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Super Admin Login',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  const Text('Access platform administration tools.',
                      style: TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _idController,
                    textInputAction: TextInputAction.next,
                    decoration:
                        const InputDecoration(labelText: 'Super Admin ID'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: !_showPassword,
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      suffixIcon: IconButton(
                        tooltip:
                            _showPassword ? 'Hide password' : 'Show password',
                        icon: Icon(_showPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(color: AppTheme.error)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _login,
                      child: const Text('Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
