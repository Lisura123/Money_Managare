import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/showroom.dart';
import '../../providers/showroom_provider.dart';
import '../../services/api_service.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class ShowroomFormScreen extends StatefulWidget {
  const ShowroomFormScreen({super.key});

  @override
  State<ShowroomFormScreen> createState() => _ShowroomFormScreenState();
}

class _ShowroomFormScreenState extends State<ShowroomFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  bool _isLoading = false;
  Showroom? _showroom;

  bool get _isEdit => _showroom != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Showroom && _showroom == null) {
      _showroom = args;
      _nameController.text = args.name;
      _locationController.text = args.location ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    try {
      final provider = context.read<ShowroomProvider>();
      if (_isEdit) {
        await provider.updateShowroom(
          _showroom!.id,
          name: _nameController.text.trim(),
          location: _locationController.text.trim().isEmpty
              ? ''
              : _locationController.text.trim(),
        );
      } else {
        await provider.createShowroom(
          name: _nameController.text.trim(),
          location: _locationController.text.trim().isEmpty
              ? ''
              : _locationController.text.trim(),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit
            ? 'Showroom updated successfully'
            : 'Showroom created successfully'),
        backgroundColor: AppColors.success,
      ));
      Navigator.of(context).pop(true);
    } on ValidationException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.firstError),
        backgroundColor: AppColors.error,
      ));
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Showroom' : 'New Showroom'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppTextField(
                  label: 'Showroom Name',
                  controller: _nameController,
                  prefixIcon: Icons.storefront_outlined,
                  validator: Validators.required,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Location (optional)',
                  controller: _locationController,
                  prefixIcon: Icons.location_on_outlined,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 28),
                AppButton(
                  label: _isEdit ? 'Update Showroom' : 'Create Showroom',
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
