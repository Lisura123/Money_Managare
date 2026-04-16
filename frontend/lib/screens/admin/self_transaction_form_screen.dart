import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/card_account.dart';
import '../../models/external_account.dart';
import '../../providers/self_transaction_provider.dart';
import '../../providers/card_account_provider.dart';
import '../../providers/showroom_provider.dart';
import '../../services/api_service.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/date_range_picker.dart';

class SelfTransactionFormScreen extends StatefulWidget {
  const SelfTransactionFormScreen({super.key});

  @override
  State<SelfTransactionFormScreen> createState() =>
      _SelfTransactionFormScreenState();
}

class _SelfTransactionFormScreenState extends State<SelfTransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  CardAccount? _fromAccount;
  CardAccount? _toAccount;

  /// Non-null when a special destination is selected.
  /// Type: ExternalAccount (e.g. Mano's account) or String 'others'.
  Object? _specialSelection;
  bool _isLoading = false;

  bool get _isSpecialSelected => _specialSelection != null;

  String get _specialLabel => _specialSelection is ExternalAccount
      ? (_specialSelection as ExternalAccount).name
      : 'Others (External)';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final showrooms = context.read<ShowroomProvider>().showrooms;
      if (showrooms.isEmpty) {
        await context.read<ShowroomProvider>().fetchShowrooms();
      }
      final updatedShowrooms = context.read<ShowroomProvider>().showrooms;
      await Future.wait([
        context
            .read<CardAccountProvider>()
            .fetchAllAccounts(updatedShowrooms.map((s) => s.id).toList()),
        context.read<SelfTransactionProvider>().fetchExternalAccounts(),
      ]);
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await pickDate(context,
        initial: _selectedDate, lastDate: DateTime.now());
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    if (_fromAccount == null ||
        (_specialSelection == null && _toAccount == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select both from and to accounts'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    if (_specialSelection == null && _fromAccount!.id == _toAccount!.id) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('From and To accounts must be different'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    if (amount > _fromAccount!.currentBalance) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Insufficient balance. Available: ${Formatters.currency(_fromAccount!.currentBalance)}'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Transfer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Transfer ${Formatters.currency(amount)} from:'),
            const SizedBox(height: 4),
            Text(
                '${_fromAccount!.showroomName ?? ''} — ${Formatters.maskedCard(_fromAccount!.lastFour)}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('To:'),
            const SizedBox(height: 4),
            Text(
                _specialSelection != null
                    ? _specialLabel
                    : '${_toAccount!.showroomName ?? ''} \u2014 ${Formatters.maskedCard(_toAccount!.lastFour)}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isLoading = true);
    try {
      await context.read<SelfTransactionProvider>().createTransaction(
            fromCardAccountId: _fromAccount!.id,
            toCardAccountId: _specialSelection == null ? _toAccount!.id : null,
            toExternalAccountId: _specialSelection is ExternalAccount
                ? (_specialSelection as ExternalAccount).id
                : null,
            amount: amount,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Transaction created'),
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
    final accountProvider = context.watch<CardAccountProvider>();
    final stProvider = context.watch<SelfTransactionProvider>();
    final allAccounts = accountProvider.allAccounts;
    final externalAccounts = stProvider.externalAccounts;
    final toAccounts = _fromAccount == null
        ? allAccounts
        : allAccounts.where((a) => a.id != _fromAccount!.id).toList();
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    final showSummary = _fromAccount != null &&
        (_specialSelection != null || _toAccount != null) &&
        amount > 0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('New Self Transaction')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DateRow(selectedDate: _selectedDate, onTap: _pickDate),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CardAccount>(
                    value: _fromAccount,
                    isExpanded: true,
                    hint: const Text('From Account'),
                    decoration: InputDecoration(
                      labelText: 'From Account',
                      prefixIcon: const Icon(Icons.credit_card_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                    ),
                    items: allAccounts
                        .map((a) => DropdownMenuItem(
                            value: a,
                            child: Text(
                              '${a.showroomName ?? ''} — ${Formatters.cardDropdownLabel(a.bankName, a.lastFour, a.currentBalance)}',
                              style: const TextStyle(fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            )))
                        .toList(),
                    onChanged: (v) => setState(() {
                      _fromAccount = v;
                      if (_toAccount?.id == v?.id) _toAccount = null;
                    }),
                    validator: (v) => v == null ? 'Select from account' : null,
                  ),
                  const SizedBox(height: 4),
                  const Center(
                      child: Icon(Icons.arrow_downward, color: Colors.grey)),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<Object?>(
                    value: _specialSelection ?? _toAccount,
                    isExpanded: true,
                    hint: const Text('To Account'),
                    decoration: InputDecoration(
                      labelText: 'To Account',
                      prefixIcon: const Icon(Icons.credit_card_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                    ),
                    items: [
                      ...toAccounts.map((a) => DropdownMenuItem<Object?>(
                          value: a,
                          child: Text(
                            '${a.showroomName ?? ''} \u2014 ${Formatters.cardDropdownLabel(a.bankName, a.lastFour, a.currentBalance)}',
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ))),
                      ...externalAccounts.map((e) => DropdownMenuItem<Object?>(
                          value: e,
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${e.name} \u2014 ${Formatters.currency(e.balance)}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ))),
                      const DropdownMenuItem<Object?>(
                        value: 'others',
                        child: Row(
                          children: [
                            Icon(Icons.swap_horiz_outlined,
                                size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Text('Others',
                                style: TextStyle(
                                    fontSize: 13, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() {
                      if (v is CardAccount) {
                        _specialSelection = null;
                        _toAccount = v;
                      } else {
                        _specialSelection = v; // ExternalAccount or 'others'
                        _toAccount = null;
                      }
                    }),
                    validator: (_) =>
                        (_specialSelection == null && _toAccount == null)
                            ? 'Select to account'
                            : null,
                  ),
                  const SizedBox(height: 16),
                  AmountTextField(
                    label: 'Amount (Rs.)',
                    controller: _amountController,
                    validator: Validators.positiveAmount,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (showSummary) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Transfer Summary',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                  child: Text(
                                'From: ${Formatters.maskedCard(_fromAccount!.lastFour)}',
                                style: const TextStyle(fontSize: 12),
                              )),
                              Expanded(
                                  child: Text(
                                _specialSelection != null
                                    ? 'To: $_specialLabel'
                                    : 'To: ${Formatters.maskedCard(_toAccount!.lastFour)}',
                                style: const TextStyle(fontSize: 12),
                              )),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Amount: ${Formatters.currency(amount)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: AppColors.accent),
                          ),
                          if (_fromAccount!.currentBalance < amount)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Warning: Insufficient balance',
                                style: TextStyle(
                                    color: AppColors.error, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  AppTextField(
                    label: _isSpecialSelected
                        ? 'Notes (required)'
                        : 'Notes (optional)',
                    controller: _notesController,
                    prefixIcon: Icons.notes_outlined,
                    maxLines: 2,
                    maxLength: 500,
                    validator: _isSpecialSelected
                        ? (v) => (v == null || v.trim().isEmpty)
                            ? 'Notes are required for this destination'
                            : null
                        : null,
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: 'Create Transaction',
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

class _DateRow extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTap;
  const _DateRow({required this.selectedDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Transaction Date',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 18, color: AppColors.accent),
                const SizedBox(width: 10),
                Text(
                  Formatters.date(selectedDate),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
