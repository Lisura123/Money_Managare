import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/user.dart';
import '../../models/showroom.dart';
import '../../providers/staff_provider.dart';
import '../../providers/showroom_provider.dart';
import '../../services/api_service.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class StaffFormScreen extends StatefulWidget {
  const StaffFormScreen({super.key});

  @override
  State<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends State<StaffFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  User? _staff;
  Showroom? _selectedShowroom;
  bool _isLoading = false;
  bool _obscure = true;

  bool get _isEdit => _staff != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is User && _staff == null) {
      _staff = args;
      _nameController.text = args.name;
      _emailController.text = args.email;
      if (args.showroomId != null) {
        _selectedShowroom = context
            .read<ShowroomProvider>()
            .showrooms
            .where((s) => s.id == args.showroomId)
            .firstOrNull;
      }
    }
    if (context.read<ShowroomProvider>().showrooms.isEmpty) {
      context.read<ShowroomProvider>().fetchShowrooms();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _showCredentialsFallbackDialog(
      String email, String password) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Email Not Sent — Save Credentials'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The welcome email could not be sent. Please share these credentials manually:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  Text(email, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 10),
                  Text('Password:', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  Text(password,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          fontFamily: 'monospace')),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Password'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: password));
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                content: Text('Password copied'),
                duration: Duration(seconds: 2),
              ));
            },
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    try {
      final provider = context.read<StaffProvider>();
      if (_isEdit) {
        final passwordChanged = _passwordController.text.isNotEmpty;
        await provider.updateStaff(
          _staff!.id,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          showroomId: _selectedShowroom?.id,
          password: _passwordController.text.isEmpty
              ? null
              : _passwordController.text,
        );
        if (!mounted) return;
        final msg = passwordChanged
            ? 'Staff updated. New password sent to their email.'
            : 'Staff updated';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.success,
        ));
        Navigator.of(context).pop(true);
      } else {
        if (_selectedShowroom == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Please assign a showroom'),
              backgroundColor: AppColors.error,
            ));
          }
          return;
        }
        final result = await provider.createStaff(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
          showroomId: _selectedShowroom!.id,
        );
        if (!mounted) return;
        final emailSent = result['email_sent'] as bool? ?? true;
        if (emailSent) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Staff member created. Login credentials sent to ${_emailController.text.trim()}.'),
            backgroundColor: AppColors.success,
          ));
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Staff member created, but email could not be sent. Please share credentials manually.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ));
          await _showCredentialsFallbackDialog(
              _emailController.text.trim(), _passwordController.text);
          if (mounted) Navigator.of(context).pop(true);
        }
      }
    } on ValidationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.firstError), backgroundColor: AppColors.error));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString()), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showrooms = context.watch<ShowroomProvider>().showrooms;
    final passwordHasText = _passwordController.text.isNotEmpty;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'Edit Staff' : 'New Staff')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: 'Full Name',
                    controller: _nameController,
                    prefixIcon: Icons.person_outline,
                    validator: Validators.required,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Email',
                    controller: _emailController,
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: _isEdit
                        ? 'New Password (leave blank to keep)'
                        : 'Password',
                    controller: _passwordController,
                    prefixIcon: Icons.lock_outline,
                    obscureText: _obscure,
                    validator: _isEdit ? null : Validators.password,
                    textInputAction: TextInputAction.next,
                    onChanged: (_) => setState(() {}),
                    suffix: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  if (_isEdit && passwordHasText) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.email_outlined,
                            size: 14, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Text(
                          'The staff member will be notified of the new password via email.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.accent),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Showroom>(
                    value: _selectedShowroom,
                    isExpanded: true,
                    hint: const Text('Assign Showroom (optional)'),
                    decoration: InputDecoration(
                      labelText: 'Showroom',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                    ),
                    items: [
                      const DropdownMenuItem<Showroom>(
                          value: null, child: Text('No Showroom')),
                      ...showrooms.map((s) =>
                          DropdownMenuItem(value: s, child: Text(s.name))),
                    ],
                    onChanged: (v) => setState(() => _selectedShowroom = v),
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: _isEdit ? 'Update Staff' : 'Create Staff',
                    onPressed: _submit,
                    isLoading: _isLoading,
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
