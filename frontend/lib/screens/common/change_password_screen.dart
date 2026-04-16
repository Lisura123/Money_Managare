import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  bool _isDirty = false;

  String? _currentPasswordError;
  String? _newPasswordError;

  // Strength indicator
  String _strengthLabel = '';
  Color _strengthColor = Colors.transparent;
  double _strengthFraction = 0;

  void _onNewPasswordChanged(String value) {
    setState(() {
      _newPasswordError = null;
      _isDirty = true;
      if (value.isEmpty) {
        _strengthLabel = '';
        _strengthColor = Colors.transparent;
        _strengthFraction = 0;
      } else if (value.length < 8) {
        _strengthLabel = 'Too short';
        _strengthColor = AppColors.error;
        _strengthFraction = 0.25;
      } else if (value.length < 12 &&
          !RegExp(r'(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
        _strengthLabel = 'Weak';
        _strengthColor = AppColors.warning;
        _strengthFraction = 0.5;
      } else if (value.length >= 12 ||
          RegExp(r'(?=.*[a-zA-Z])(?=.*\d)').hasMatch(value)) {
        _strengthLabel = 'Strong';
        _strengthColor = AppColors.success;
        _strengthFraction = 1.0;
      }
    });
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
            'You have unsaved changes. Are you sure you want to go back?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Stay')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Discard',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _submit() async {
    setState(() {
      _currentPasswordError = null;
      _newPasswordError = null;
    });
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await context.read<AuthService>().changePassword(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
            newPasswordConfirmation: _confirmController.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Password changed successfully.'),
        backgroundColor: AppColors.success,
      ));
      _currentController.clear();
      _newController.clear();
      _confirmController.clear();
      setState(() {
        _isDirty = false;
        _strengthLabel = '';
        _strengthColor = Colors.transparent;
        _strengthFraction = 0;
      });
      Navigator.of(context).pop();
    } on ValidationException catch (e) {
      if (!mounted) return;
      setState(() {
        _currentPasswordError = e.errors['current_password']?.first;
        _newPasswordError = e.errors['new_password']?.first;
      });
      if (_currentPasswordError == null && _newPasswordError == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.error,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppColors.error,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Change Password')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current password
                  AppTextField(
                    label: 'Current Password',
                    controller: _currentController,
                    obscureText: _obscureCurrent,
                    autofocus: true,
                    prefixIcon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(_obscureCurrent
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                    onChanged: (_) => setState(() {
                      _currentPasswordError = null;
                      _isDirty = true;
                    }),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      return null;
                    },
                  ),
                  if (_currentPasswordError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 12),
                      child: Text(
                        _currentPasswordError!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 12),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // New password
                  AppTextField(
                    label: 'New Password',
                    controller: _newController,
                    obscureText: _obscureNew,
                    prefixIcon: Icons.lock_reset_outlined,
                    suffix: IconButton(
                      icon: Icon(_obscureNew
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    onChanged: _onNewPasswordChanged,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 8) return 'Minimum 8 characters';
                      return null;
                    },
                  ),
                  if (_newPasswordError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 12),
                      child: Text(
                        _newPasswordError!,
                        style: const TextStyle(
                            color: AppColors.error, fontSize: 12),
                      ),
                    ),
                  if (_strengthLabel.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _strengthFraction,
                        minHeight: 4,
                        backgroundColor: Colors.grey.shade200,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(_strengthColor),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _strengthLabel,
                      style: TextStyle(fontSize: 12, color: _strengthColor),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Confirm new password
                  AppTextField(
                    label: 'Confirm New Password',
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    prefixIcon: Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    onChanged: (_) => setState(() => _isDirty = true),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v != _newController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  AppButton(
                    label: 'Change Password',
                    isLoading: _isLoading,
                    onPressed: _submit,
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
