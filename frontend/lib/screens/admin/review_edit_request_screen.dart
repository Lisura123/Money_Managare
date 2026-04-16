import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/edit_request.dart';
import '../../providers/edit_request_provider.dart';
import '../../services/api_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/app_text_field.dart';

class ReviewEditRequestScreen extends StatefulWidget {
  final EditRequest request;
  const ReviewEditRequestScreen({super.key, required this.request});

  @override
  State<ReviewEditRequestScreen> createState() =>
      _ReviewEditRequestScreenState();
}

class _ReviewEditRequestScreenState extends State<ReviewEditRequestScreen> {
  final _remarksController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  String _amountKey() =>
      widget.request.entryType == 'cash' ? 'cash_amount' : 'amount';

  String _fmt(dynamic v) {
    if (v == null) return '—';
    final d = double.tryParse(v.toString());
    if (d != null) return Formatters.currency(d);
    return v.toString();
  }

  String _friendly(String k) {
    switch (k) {
      case 'cash_amount':
      case 'amount':
        return 'Amount';
      case 'notes':
        return 'Notes';
      default:
        return k;
    }
  }

  Future<void> _approve() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Edit Request'),
        content: const Text(
            'Approve this edit request? The entry will be updated with the new values.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve',
                style: TextStyle(color: AppColors.success)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await context.read<EditRequestProvider>().approveRequest(
            widget.request.id,
            adminRemarks: _remarksController.text.trim().isEmpty
                ? null
                : _remarksController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Request approved. Entry has been updated.'),
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

  Future<void> _reject() async {
    if (_remarksController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content:
            Text('Please provide a reason in Admin Remarks before rejecting.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Edit Request'),
        content: const Text(
            'Reject this edit request? The entry will remain unchanged.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Reject', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await context.read<EditRequestProvider>().rejectRequest(
            widget.request.id,
            adminRemarks: _remarksController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Request rejected.'),
        backgroundColor: AppColors.error,
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
    final req = widget.request;
    final amountKey = _amountKey();
    final origAmount = req.originalValues[amountKey];
    final reqAmount = req.requestedChanges[amountKey];
    final hasAmountChange = origAmount != null && reqAmount != null;
    double diff = 0;
    if (hasAmountChange) {
      diff = (double.tryParse(reqAmount.toString()) ?? 0) -
          (double.tryParse(origAmount.toString()) ?? 0);
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Review Edit Request'),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Staff meta
                _MetaCard(request: req),
                const SizedBox(height: 16),

                // Before/After comparison
                Text('Changes Requested',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _CompareCard(
                        title: 'Original',
                        icon: Icons.history_rounded,
                        color: Colors.grey.shade600,
                        bgColor: Colors.grey.shade100,
                        borderColor: Colors.grey.shade300,
                        entries: req.originalValues,
                        fmt: _fmt,
                        friendly: _friendly,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _CompareCard(
                        title: 'New Values',
                        icon: Icons.edit_rounded,
                        color: AppColors.primary,
                        bgColor: AppColors.primary.withValues(alpha: 0.05),
                        borderColor: AppColors.primary.withValues(alpha: 0.2),
                        entries: req.requestedChanges,
                        fmt: _fmt,
                        friendly: _friendly,
                        highlight: true,
                      ),
                    ),
                  ],
                ),

                // Amount diff indicator
                if (hasAmountChange) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: diff >= 0
                          ? AppColors.success.withValues(alpha: 0.08)
                          : AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: diff >= 0
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          diff >= 0
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          color:
                              diff >= 0 ? AppColors.success : AppColors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${diff >= 0 ? '+' : ''}${Formatters.currency(diff)} difference',
                          style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: diff >= 0
                                  ? AppColors.success
                                  : AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Reason
                _ReasonCard(reason: req.reason),
                const SizedBox(height: 20),

                // Admin remarks
                Text('Admin Remarks',
                    style: GoogleFonts.poppins(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(
                  'Optional for approval · Required for rejection',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: _remarksController,
                  label: 'Add a note for the staff member',
                  maxLines: 3,
                ),
                const SizedBox(height: 28),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppColors.error))
                            : const Icon(Icons.close_rounded),
                        label: Text('Reject',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600)),
                        onPressed: _isLoading ? null : _reject,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_rounded),
                        label: Text('Approve',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600)),
                        onPressed: _isLoading ? null : _approve,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------
// Sub-widgets
// -------------------------------------------------------
class _MetaCard extends StatelessWidget {
  final EditRequest request;
  const _MetaCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              (request.staffName ?? '?')[0].toUpperCase(),
              style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.staffName ?? '—',
                    style: GoogleFonts.poppins(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Text(
                  '${request.staffEmail ?? ''}  ·  ${request.showroomName ?? ''}',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: Colors.grey.shade600),
                ),
                Text(
                  'Submitted ${Formatters.dateTime(request.createdAt)}',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: request.entryType == 'cash'
                  ? AppColors.success.withValues(alpha: 0.12)
                  : AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              request.entryType == 'cash' ? 'Cash' : 'Card',
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: request.entryType == 'cash'
                      ? AppColors.success
                      : AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompareCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final Map<String, dynamic> entries;
  final String Function(dynamic) fmt;
  final String Function(String) friendly;
  final bool highlight;

  const _CompareCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.entries,
    required this.fmt,
    required this.friendly,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...entries.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(friendly(e.key),
                        style: GoogleFonts.inter(
                            fontSize: 10, color: Colors.grey.shade500)),
                    Text(
                      fmt(e.value),
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight:
                              highlight ? FontWeight.w700 : FontWeight.w500,
                          color: highlight ? color : null),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _ReasonCard extends StatelessWidget {
  final String reason;
  const _ReasonCard({required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 14, color: Color(0xFF996600)),
              const SizedBox(width: 5),
              Text('Reason for Edit',
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF996600))),
            ],
          ),
          const SizedBox(height: 8),
          Text(reason, style: GoogleFonts.inter(fontSize: 13, height: 1.6)),
        ],
      ),
    );
  }
}
