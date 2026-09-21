import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../services/super_admin_service.dart';
import '../../services/orders_service.dart';
import '../../services/feedback_service.dart';
import '../../services/menu_service.dart';
import '../../screens/super_admin/super_admin_login_screen.dart';

class ManagerProfileScreen extends StatelessWidget {
  const ManagerProfileScreen({
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
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user as ManagerUser?;

    return Scaffold(
      backgroundColor: AppTheme.bgSubtle,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Profile',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryMuted,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_outline,
                            color: AppTheme.primary, size: 38),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _infoField('Name', user?.name ?? ''),
                    const SizedBox(height: 18),
                    _infoField('Manager ID', user?.managerId ?? ''),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => SuperAdminLoginScreen(
                              superAdminService: superAdminService,
                              ordersService: ordersService,
                              feedbackService: feedbackService,
                              menuService: menuService,
                            )),
                  ),
                  child: const Text('Login as Super Admin?'),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await auth.logout();
                    if (context.mounted) context.go('/');
                  },
                  child: const Text('Logout'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        const SizedBox(height: 5),
        Text(value,
            style: const TextStyle(
                color: AppTheme.text,
                fontSize: 18,
                fontWeight: FontWeight.w700)),
      ],
    );
  }
}
