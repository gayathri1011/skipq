import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/helpers.dart';
import '../../widgets/welcome_login_layout.dart';

class StudentAuthForm extends StatefulWidget {
  const StudentAuthForm({super.key, this.onManagerTap});

  final VoidCallback? onManagerTap;

  @override
  State<StudentAuthForm> createState() => _StudentAuthFormState();
}

class _StudentAuthFormState extends State<StudentAuthForm> {
  bool _isRegister = false;
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  bool _submitting = false;
  String? _error;
  bool _showNameError = false;
  bool _showMobileError = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  bool get _isFormValid {
    if (_isRegister) {
      return StudentAuthValidation.nameError(_nameController.text) == null &&
          StudentAuthValidation.mobileError(_mobileController.text) == null;
    }
    return StudentAuthValidation.mobileError(_mobileController.text) == null;
  }

  Future<void> _submit() async {
    setState(() {
      _showMobileError = true;
      if (_isRegister) _showNameError = true;
    });

    final mobileError =
        StudentAuthValidation.mobileError(_mobileController.text);
    if (mobileError != null) {
      setState(() => _error = mobileError);
      return;
    }
    if (_isRegister) {
      final nameError = StudentAuthValidation.nameError(_nameController.text);
      if (nameError != null) {
        setState(() => _error = nameError);
        return;
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();
    try {
      if (_isRegister) {
        await auth.registerStudent(
          _nameController.text.trim(),
          _mobileController.text.trim(),
        );
      } else {
        await auth.loginStudent(_mobileController.text.trim());
      }
      if (mounted) {
        if (_isRegister) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account created')),
          );
        }
        context.go('/student');
      }
    } catch (e) {
      setState(() =>
          _error = auth.messageFromError(e, fallback: 'Unable to connect.'));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const displayFont = TextStyle();
    final nameError = StudentAuthValidation.nameError(_nameController.text);
    final mobileError =
        StudentAuthValidation.mobileError(_mobileController.text);

    return WelcomeLoginLayout(
      variant: WelcomeLoginVariant.student,
      headline: "SSM's Own Canteen Pre-Order App",
      footer: TextButton(
        onPressed: widget.onManagerTap,
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.primary,
          padding: EdgeInsets.zero,
        ),
        child: const Text('Canteen Staff Login'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthModeToggle(
            isRegister: _isRegister,
            onChanged: (value) => setState(() {
              _isRegister = value;
              _error = null;
            }),
          ),
          const SizedBox(height: 20),
          if (_isRegister) ...[
            Text('Full Name',
                style: displayFont.copyWith(
                    fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Your name',
                errorText:
                    _showNameError && nameError != null ? nameError : null,
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) {
                setState(() {
                  _showNameError = true;
                  _error = null;
                });
              },
            ),
            const SizedBox(height: 16),
          ],
          Text('Mobile Number',
              style: displayFont.copyWith(
                  fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(
            controller: _mobileController,
            decoration: InputDecoration(
              hintText: '10-digit mobile number',
              counterText: '',
              errorText:
                  _showMobileError && mobileError != null ? mobileError : null,
            ),
            keyboardType: TextInputType.phone,
            maxLength: 10,
            onChanged: (_) {
              setState(() {
                _showMobileError = true;
                _error = null;
              });
            },
          ),
          if (_error != null &&
              !(_showNameError && nameError == _error) &&
              !(_showMobileError && mobileError == _error)) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _error!,
                style: const TextStyle(fontSize: 14, color: AppTheme.error),
              ),
            ),
          ],
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _submitting || !_isFormValid ? null : _submit,
            child: Text(_submitting
                ? (_isRegister ? 'Creating account…' : 'Signing in…')
                : (_isRegister ? 'Register' : 'Login')),
          ),
        ],
      ),
    );
  }
}

class _AuthModeToggle extends StatelessWidget {
  const _AuthModeToggle({
    required this.isRegister,
    required this.onChanged,
  });

  final bool isRegister;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.gray100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: 'Register',
              selected: isRegister,
              onTap: () => onChanged(true),
              labelStyle: labelStyle,
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: 'Login',
              selected: !isRegister,
              onTap: () => onChanged(false),
              labelStyle: labelStyle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.labelStyle,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      elevation: selected ? 1 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: labelStyle.copyWith(
              color: selected ? AppTheme.text : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
