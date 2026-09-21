import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _registerNumberController = TextEditingController();
  final _departmentController = TextEditingController();
  final _courseController = TextEditingController();
  Map<String, String>? _originalValues;
  bool _editing = false;
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _registerNumberController.dispose();
    _departmentController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  void _initialize(StudentUser? user) {
    if (_initialized || user == null) return;
    _nameController.text = user.name;
    _registerNumberController.text = user.registerNumber;
    _departmentController.text = user.department;
    _courseController.text = user.academicStream;
    _initialized = true;
  }

  Map<String, String> _currentValues() => {
        'name': _nameController.text.trim(),
        'registerNumber': _registerNumberController.text.trim(),
        'department': _departmentController.text.trim(),
        'academicStream': _courseController.text.trim(),
      };

  bool _hasChanges(Map<String, String> current, Map<String, String> original) {
    return current['name'] != original['name'] ||
        current['registerNumber'] != original['registerNumber'] ||
        current['department'] != original['department'] ||
        current['academicStream'] != original['academicStream'];
  }

  void _enterEdit(StudentUser user) {
    setState(() {
      _originalValues = {
        'name': user.name,
        'registerNumber': user.registerNumber,
        'department': user.department,
        'academicStream': user.academicStream,
      };
      _nameController.text = user.name;
      _registerNumberController.text = user.registerNumber;
      _departmentController.text = user.department;
      _courseController.text = user.academicStream;
      _editing = true;
    });
  }

  void _cancelEdit() {
    final original = _originalValues;
    if (original == null) return;
    setState(() {
      _nameController.text = original['name']!;
      _registerNumberController.text = original['registerNumber']!;
      _departmentController.text = original['department']!;
      _courseController.text = original['academicStream']!;
      _editing = false;
      _originalValues = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final original = _originalValues;
    final current = _currentValues();
    if (original != null && !_hasChanges(current, original)) {
      _cancelEdit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No changes made')),
        );
      }
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updateStudentProfile(
            name: current['name']!,
            registerNumber: current['registerNumber']!,
            department: current['department']!,
            academicStream: current['academicStream']!,
          );
      if (mounted) {
        setState(() {
          _editing = false;
          _originalValues = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      }
    } catch (error) {
      if (mounted) {
        final auth = context.read<AuthProvider>();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(auth.messageFromError(error,
                  fallback: 'Unable to update profile'))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user as StudentUser?;
    _initialize(user);

    return AppScaffold(
      title: 'Profile',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: AppTheme.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Student profile',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.w700)),
                        ),
                        if (_editing)
                          IconButton(
                            onPressed: _saving ? null : _cancelEdit,
                            tooltip: 'Discard changes',
                            icon: const Icon(Icons.arrow_back),
                          )
                        else
                          IconButton(
                            onPressed:
                                user == null ? null : () => _enterEdit(user),
                            tooltip: 'Edit profile',
                            icon: const Icon(Icons.edit_outlined),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(user?.mobile ?? '',
                        style: const TextStyle(color: AppTheme.textSecondary)),
                    const SizedBox(height: 20),
                    if (_editing) ...[
                      _editField(_nameController, 'Name'),
                      const SizedBox(height: 14),
                      _editField(_registerNumberController, 'Register Number'),
                      const SizedBox(height: 14),
                      _editField(_departmentController, 'Department'),
                      const SizedBox(height: 14),
                      _editField(_courseController, 'Course of Study'),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          child: Text(_saving ? 'SAVING...' : 'Save Profile'),
                        ),
                      ),
                    ] else ...[
                      _readOnlyField('Name', user?.name ?? ''),
                      _readOnlyField(
                          'Register Number', user?.registerNumber ?? ''),
                      _readOnlyField('Department', user?.department ?? ''),
                      _readOnlyField(
                          'Course of Study', user?.academicStream ?? ''),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.go('/student/order-history'),
              icon: const Icon(Icons.history),
              label: const Text('Order History'),
            ),
            const SizedBox(height: 16),
            const Card(
              margin: EdgeInsets.zero,
              elevation: 0,
              color: AppTheme.bgSubtle,
              surfaceTintColor: Colors.transparent,
              child: ListTile(
                leading: Icon(Icons.account_circle_outlined,
                    color: AppTheme.textMuted),
                title: Text('Google sign-in coming soon'),
                subtitle: Text('Your mobile login remains active for now.'),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) context.go('/');
              },
              child: const Text('LOG OUT'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      validator: (value) =>
          value == null || value.trim().isEmpty ? '$label is required' : null,
    );
  }

  Widget _readOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value.isEmpty ? 'Not provided' : value,
              style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
