import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/cash_entry_provider.dart';
import '../../services/api_service.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/date_range_picker.dart';

class CashEntryScreen extends StatefulWidget {
  final dynamic existingEntry;
  final String cashAccountType;
  const CashEntryScreen({
    super.key,
    this.existingEntry,
    this.cashAccountType = 'main',
  });

  @override
  State<CashEntryScreen> createState() => _CashEntryScreenState();
}

class _CashEntryScreenState extends State<CashEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  bool get _isEdit => widget.existingEntry != null;

  String get _accountType => _isEdit
      ? (widget.existingEntry.cashAccountType ?? 'main')
      : widget.cashAccountType;

  String get _accountLabel =>
      _accountType == 'mano' ? "Mano's Account" : 'Main Account';

  Color get _accountColor =>
      _accountType == 'mano' ? const Color(0xFF7C3AED) : AppColors.success;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _amountController.text =
          widget.existingEntry.cashAmount.toStringAsFixed(2);
      _notesController.text = widget.existingEntry.notes ?? '';
      final parsedDate = DateTime.tryParse(widget.existingEntry.entryDate);
      if (parsedDate != null) {
        _selectedDate =
            DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      }
    }
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
    setState(() => _isLoading = true);
    try {
      final provider = context.read<CashEntryProvider>();
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      final notes = _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim();

      if (_isEdit) {
        await provider.updateEntry(
          widget.existingEntry.id as int,
          cashAmount: amount,
          notes: notes,
        );
      } else {
        final dateStr =
            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
        await provider.submitEntry(
          entryDate: dateStr,
          cashAmount: amount,
          notes: notes,
          cashAccountType: _accountType,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEdit
            ? 'Entry updated successfully'
            : 'Cash entry submitted successfully'),
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
          title: Text(_isEdit ? 'Edit Cash Entry' : 'New Cash Entry'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account type badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _accountColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _accountColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_balance_wallet_outlined,
                            size: 16, color: _accountColor),
                        const SizedBox(width: 8),
                        Text(
                          _accountLabel,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _accountColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
