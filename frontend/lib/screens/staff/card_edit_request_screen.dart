import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/daily_card_entry.dart';
import '../../providers/edit_request_provider.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';

class CardEditRequestScreen extends StatefulWidget {
  final DailyCardEntry entry;
  const CardEditRequestScreen({super.key, required this.entry});

  @override
  State<CardEditRequestScreen> createState() => _CardEditRequestScreenState();
}

class _CardEditRequestScreenState extends State<CardEditRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.entry.amount.toStringAsFixed(2);
    _notesController.text = widget.entry.notes ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();

    final newAmount =
        double.tryParse(_amountController.text.replaceAll(',', ''));
    final newNotes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    final requestedChanges = <String, dynamic>{};
    if (newAmount != null && (newAmount - widget.entry.amount).abs() > 0.001) {
      requestedChanges['amount'] = newAmount;
    }
    final currentNotes = widget.entry.notes ?? '';
    final updatedNotes = newNotes ?? '';
    if (updatedNotes != currentNotes) {
      requestedChanges['notes'] = newNotes;
    }

    if (requestedChanges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('No changes detected. Please modify the amount or notes.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await context.read<EditRequestProvider>().submitEditRequest(
            entryType: 'card',
            entryId: widget.entry.id,
            requestedChanges: requestedChanges,
            reason: _reasonController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Edit request submitted. Waiting for admin approval.'),
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
    final bankInfo = widget.entry.bankName != null
        ? '${widget.entry.bankName} ****${widget.entry.lastFour ?? ''}'
        : 'Card entry';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Request Edit — Card Entry')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Original entry card
                  _OriginalEntryCard(
                    date: Formatters.date(widget.entry.entryDate),
                    amount: Formatters.currency(widget.entry.amount),
                    bankInfo: bankInfo,
                    notes: widget.entry.notes,
                  ),
                  const SizedBox(height: 20),
                  Text('New Values',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    'Modify the fields you want to change. Date and card account cannot be changed.',
                    style: GoogleFonts.inter(
                        fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  AmountTextField(
                    controller: _amountController,
                    label: 'Amount (Rs.)',
                    validator: Validators.positiveAmount,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _notesController,
                    label: 'Notes (optional)',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 20),
                  Text('Reason for Edit',
                      style: GoogleFonts.poppins(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  AppTextField(
                    controller: _reasonController,
                    label: 'Explain why this entry needs to be changed',
                    maxLines: 4,
                    validator: (v) {
                      if (v == null || v.trim().length < 10) {
                        return 'Please provide at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  AppButton(
                    label: 'Submit Edit Request',
                    onPressed: _isLoading ? null : _submit,
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

class _OriginalEntryCard extends StatelessWidget {
  final String date;
  final String amount;
  final String bankInfo;
  final String? notes;

  const _OriginalEntryCard({
    required this.date,
    required this.amount,
    required this.bankInfo,
    this.notes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.credit_card_rounded,
                  size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text('Current Entry',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 10),
          _Row(label: 'Date', value: date),
          const SizedBox(height: 4),
          _Row(label: 'Account', value: bankInfo),
          const SizedBox(height: 4),
          _Row(label: 'Amount', value: amount),
          if (notes != null && notes!.isNotEmpty) ...[
            const SizedBox(height: 4),
            _Row(label: 'Notes', value: notes!),
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 58,
          child: Text(label,
              style:
                  GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
        ),
        Expanded(
            child: Text(value,
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w500))),
      ],
    );
  }
}
