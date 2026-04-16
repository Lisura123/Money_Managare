import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/external_account.dart';
import '../../providers/cash_transaction_provider.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/date_range_picker.dart';

/// Dropdown item type for the To Account selector.
/// Either a [String] ('main','mano'), an [ExternalAccount], or the sentinel 'others'.
typedef _ToItem = Object;

class CashTransactionFormScreen extends StatefulWidget {
  const CashTransactionFormScreen({super.key});

  @override
  State<CashTransactionFormScreen> createState() =>
      _CashTransactionFormScreenState();
}

class _CashTransactionFormScreenState extends State<CashTransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  String _fromAccountType = 'main'; // 'main' | 'mano'

  /// Null = not yet chosen.
  /// String 'main' | 'mano' = internal cash account.
  /// ExternalAccount = named external account.
  /// String 'others' = anonymous external.
  _ToItem? _toSelection;

  bool _isLoading = false;

  bool get _isSpecialTo =>
      _toSelection is ExternalAccount || _toSelection == 'others';

  String get _toLabel {
    if (_toSelection == null) return '';
    if (_toSelection is ExternalAccount) {
      return (_toSelection as ExternalAccount).name;
    }
    if (_toSelection == 'others') return 'Others (External)';
    return _toSelection == 'mano' ? "Mano's account" : 'Main Account';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<CashTransactionProvider>();
      p.fetchExternalAccounts();
      p.fetchSummary();
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

    if (_toSelection == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a To account'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    // Same account check (internal → internal same type)
    if (_toSelection is String &&
        _toSelection != 'others' &&
        _toSelection == _fromAccountType) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('From and To accounts must be different'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    final fromLabel =
        _fromAccountType == 'mano' ? "Mano's account" : 'Main Account';

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
            Text(fromLabel,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('To:'),
            const SizedBox(height: 4),
            Text(_toLabel, style: const TextStyle(fontWeight: FontWeight.w600)),
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
      String? toAccountType;
      int? toExternalAccountId;

      if (_toSelection is ExternalAccount) {
        toExternalAccountId = (_toSelection as ExternalAccount).id;
      } else if (_toSelection is String && _toSelection != 'others') {
        toAccountType = _toSelection as String;
      }
      // 'others' → both null

      await context.read<CashTransactionProvider>().createTransaction(
            fromAccountType: _fromAccountType,
            toAccountType: toAccountType,
            toExternalAccountId: toExternalAccountId,
            amount: amount,
            transactionDate: Formatters.dateToApi(_selectedDate),
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
    final provider = context.watch<CashTransactionProvider>();
    // Only show externals that are NOT linked to an internal cash account type
    final externalAccounts = provider.externalAccounts
        .where((e) => e.cashAccountType == null)
        .toList();
    final mainBalance = provider.mainBalance;
    final manoBalance = provider.manoBalance;
    final amount =
        double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0;
    final showSummary = _toSelection != null && amount > 0;

    // Available internal "to" options: exclude same type as from
    final internalOptions =
        ['main', 'mano'].where((t) => t != _fromAccountType).toList();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('New Cash Transaction')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date
                  _DateRow(selectedDate: _selectedDate, onTap: _pickDate),
                  const SizedBox(height: 16),

                  // From Account
                  DropdownButtonFormField<String>(
                    value: _fromAccountType,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'From Account',
                      prefixIcon:
                          const Icon(Icons.account_balance_wallet_outlined),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'main', child: Text('Main Account')),
                      DropdownMenuItem(
                          value: 'mano', child: Text("Mano's account")),
                    ],
                    onChanged: (v) => setState(() {
                      _fromAccountType = v!;
                      // Reset to if it's same as the new from
                      if (_toSelection is String &&
                          _toSelection != 'others' &&
                          _toSelection == v) {
                        _toSelection = null;
                      }
                    }),
                    validator: (v) => v == null ? 'Select from account' : null,
                  ),
                  const SizedBox(height: 4),
                  const Center(
                      child: Icon(Icons.arrow_downward, color: Colors.grey)),
                  const SizedBox(height: 4),

                  // To Account
                  DropdownButtonFormField<Object?>(
                    value: _toSelection,
                    isExpanded: true,
                    hint: const Text('To Account'),
                    decoration: InputDecoration(
                      labelText: 'To Account',
                      prefixIcon:
                          const Icon(Icons.account_balance_wallet_rounded),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                    ),
                    items: [
                      // Internal cash accounts (excluding from)
                      ...internalOptions.map((t) => DropdownMenuItem<Object?>(
                          value: t,
                          child: Row(
                            children: [
                              Icon(Icons.attach_money,
                                  size: 16,
                                  color: t == 'mano'
                                      ? const Color(0xFF7C3AED)
                                      : AppColors.success),
                              const SizedBox(width: 8),
                              Text(
                                t == 'mano'
                                    ? "Mano's account \u2014 ${Formatters.currency(manoBalance)}"
                                    : 'Main Account \u2014 ${Formatters.currency(mainBalance)}',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ))),
                      // Named external accounts
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
                      // Others
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
                    onChanged: (v) => setState(() => _toSelection = v),
                    validator: (_) =>
                        _toSelection == null ? 'Select to account' : null,
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  AmountTextField(
                    label: 'Amount (Rs.)',
                    controller: _amountController,
                    validator: Validators.positiveAmount,
                    onChanged: (_) => setState(() {}),
                  ),

                  // Summary
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
                                'From: ${_fromAccountType == 'mano' ? "Mano's Cash" : 'Main Cash'}',
                                style: const TextStyle(fontSize: 12),
                              )),
                              Expanded(
                                  child: Text(
                                'To: $_toLabel',
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
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),
                  // Notes
                  AppTextField(
                    label:
                        _isSpecialTo ? 'Notes (required)' : 'Notes (optional)',
                    controller: _notesController,
                    prefixIcon: Icons.notes_outlined,
                    maxLines: 2,
                    maxLength: 500,
                    validator: _isSpecialTo
                        ? (v) => (v == null || v.trim().isEmpty)
                            ? 'Notes are required for external transfers'
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 18, color: Colors.grey),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Date',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                Text(Formatters.date(selectedDate),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
