import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';

class SuperAdminManagerScreen extends StatelessWidget {
  const SuperAdminManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final manager = context.read<AuthProvider>().user;
    final managerUser = manager is ManagerUser ? manager : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Manager Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        const Text('Manager accounts connected to this portal.', style: TextStyle(color: AppTheme.textSecondary)),
        const SizedBox(height: 20),
        if (managerUser == null)
          const Text('No manager account is currently available.')
        else
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: AppTheme.primaryMuted,
                    child: Icon(Icons.person_outline, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(managerUser.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 4),
                        Text(managerUser.managerId, style: const TextStyle(color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.verified_outlined, color: AppTheme.success),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
