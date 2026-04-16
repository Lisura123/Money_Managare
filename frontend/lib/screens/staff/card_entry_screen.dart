import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/card_entry_provider.dart';
import '../../providers/card_account_provider.dart';
import '../../models/card_account.dart';
import '../../services/api_service.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/date_range_picker.dart';

class CardEntryScreen extends StatefulWidget {
  final dynamic existingEntry;
  const CardEntryScreen({super.key, this.existingEntry});

  @override
  State<CardEntryScreen> createState() => _CardEntryScreenState();
}

class _CardEntryScreenState extends State<CardEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  CardAccount? _selectedAccount;
  bool _isLoading = false;

  bool get _isEdit => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _amountController.text = widget.existingEntry.amount.toStringAsFixed(2);
      _notesController.text = widget.existingEntry.notes ?? '';
      final parsedDate = DateTime.tryParse(widget.existingEntry.entryDate);
      if (parsedDate != null) {
        _selectedDate =
            DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<CardAccountProvider>().fetchMyAccounts();
      if (_isEdit && widget.existingEntry.cardAccountId != null && mounted) {
        final accounts = context.read<CardAccountProvider>().myAccounts;
        final match =
            accounts.where((a) => a.id == widget.existingEntry.cardAccountId);
        if (match.isNotEmpty) {
          setState(() => _selectedAccount = match.first);
        }
      }
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
    if (_selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select a card account'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    try {
      final provider = context.read<CardEntryProvider>();
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      if (_isEdit) {
        await provider.updateEntry(
          widget.existingEntry.id as int,
          amount: amount,
          notes: notes,
        );
      } else {
        final dateStr =
            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
        await provider.submitEntry(
          entryDate: dateStr,
          cardAccountId: _selectedAccount!.id,
          amount: amount,
          notes: notes,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit
            ? 'Entry updated successfully'
            : 'Card entry submitted successfully'),
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
    final cardAccountProvider = context.watch<CardAccountProvider>();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? 'Edit Card Entry' : 'New Card Entry'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Entry Date',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: Theme.of(context).inputDecorationTheme.fillColor,
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined,
                              size: 18, color: AppColors.accent),
                          const SizedBox(width: 10),
                          Text(
                            Formatters.date(_selectedDate),
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                          const Spacer(),
                          const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Card Account',
                      style: GoogleFonts.inter(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  if (cardAccountProvider.isLoading)
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(10)),
                      child: const Center(
                          child: SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2))),
                    )
                  else
                    DropdownButtonFormField<CardAccount>(
                      value: _selectedAccount,
                      isExpanded: true,
                      hint: const Text('Select card account'),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Theme.of(context).dividerColor)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                      ),
                      items: cardAccountProvider.myAccounts.isEmpty
                          ? [
                              const DropdownMenuItem<CardAccount>(
                                  value: null,
                                  child: Text('No card accounts available'))
                            ]
                          : cardAccountProvider.myAccounts
                              .map((a) => DropdownMenuItem(
                                    value: a,
                                    child: Text(
                                      Formatters.cardDropdownLabel(a.bankName,
                                          a.lastFour, a.currentBalance),
                                      style: GoogleFonts.inter(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ))
                              .toList(),
                      onChanged: (v) => setState(() => _selectedAccount = v),
                      validator: (v) =>
                          v == null ? 'Please select a card account' : null,
                    ),
                  const SizedBox(height: 16),
                  AmountTextField(
                    label: 'Amount (Rs.)',
                    controller: _amountController,
                    validator: Validators.positiveAmount,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Notes (optional)',
                    controller: _notesController,
                    prefixIcon: Icons.notes_outlined,
                    maxLines: 3,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: _isEdit ? 'Update Entry' : 'Submit Entry',
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
