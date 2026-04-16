import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/card_account.dart';
import '../../models/showroom.dart';
import '../../providers/card_account_provider.dart';
import '../../providers/showroom_provider.dart';
import '../../services/api_service.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class CardAccountFormScreen extends StatefulWidget {
  const CardAccountFormScreen({super.key});

  @override
  State<CardAccountFormScreen> createState() => _CardAccountFormScreenState();
}

class _CardAccountFormScreenState extends State<CardAccountFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _lastFourController = TextEditingController();
  final _balanceController = TextEditingController();
  CardAccount? _account;
  Showroom? _selectedShowroom;
  bool _isLoading = false;

  bool get _isEdit => _account != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && _account == null) {
      _account = args['account'] as CardAccount?;
      final showroomArg = args['showroom'] as Showroom?;
      if (_account != null) {
        _labelController.text = _account!.bankName;
        _lastFourController.text = _account!.lastFour;
        _selectedShowroom = context
            .read<ShowroomProvider>()
            .showrooms
            .where((s) => s.id == _account!.showroomId)
            .firstOrNull;
      } else {
        _selectedShowroom = showroomArg;
      }
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _lastFourController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedShowroom == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a showroom'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final provider = context.read<CardAccountProvider>();
      if (_isEdit) {
        await provider.update(
          _selectedShowroom!.id,
          _account!.id,
          bankName: _labelController.text.trim(),
          lastFour: _lastFourController.text.trim(),
          balance: _account!.currentBalance,
        );
      } else {
        final initialBalance =
            double.tryParse(_balanceController.text.replaceAll(',', '')) ?? 0.0;
        await provider.create(
          _selectedShowroom!.id,
          bankName: _labelController.text.trim(),
          lastFour: _lastFourController.text.trim(),
          balance: initialBalance,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(_isEdit ? 'Card account updated' : 'Card account created'),
        backgroundColor: AppColors.success,
      ));
      Navigator.of(context).pop(true);
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

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
            title: Text(_isEdit ? 'Edit Card Account' : 'New Card Account')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  DropdownButtonFormField<Showroom>(
                    initialValue: _selectedShowroom,
                    isExpanded: true,
                    hint: const Text('Select Showroom'),
                    decoration: InputDecoration(
                      labelText: 'Showroom',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                    ),
                    items: showrooms
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedShowroom = v),
                    validator: (v) =>
                        v == null ? 'Please select a showroom' : null,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Last 4 Digits',
                    controller: _lastFourController,
                    prefixIcon: Icons.credit_card_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: Validators.exactFourDigits,
                    textInputAction: TextInputAction.next,
                    readOnly: _isEdit,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Label (optional)',
                    controller: _labelController,
                    prefixIcon: Icons.label_outline,
                    textInputAction:
                        _isEdit ? TextInputAction.done : TextInputAction.next,
                    onFieldSubmitted: _isEdit ? (_) => _submit() : null,
                  ),
                  if (!_isEdit) ...[
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Initial Balance (Rs.)',
                      controller: _balanceController,
                      prefixIcon: Icons.account_balance_wallet_outlined,
                      prefixText: 'Rs. ',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = double.tryParse(v.replaceAll(',', ''));
                        if (n == null || n < 0) return 'Enter a valid amount';
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 28),
                  AppButton(
                    label: _isEdit ? 'Update Account' : 'Create Account',
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
