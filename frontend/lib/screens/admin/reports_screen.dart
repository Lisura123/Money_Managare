import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/card_account.dart';
import '../../providers/card_account_provider.dart';
import '../../providers/report_provider.dart';
import '../../providers/showroom_provider.dart';
import '../../models/showroom.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/date_range_picker.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime? _startDate, _endDate;
  Showroom? _selectedShowroom;
  CardAccount? _selectedCardAccount;
  String? _activeReport;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (context.read<ShowroomProvider>().showrooms.isEmpty) {
        await context.read<ShowroomProvider>().fetchShowrooms();
      }
      final showrooms = context.read<ShowroomProvider>().showrooms;
      if (showrooms.isNotEmpty) {
        await context
            .read<CardAccountProvider>()
            .fetchAllAccounts(showrooms.map((s) => s.id).toList());
      }
    });
  }

  Future<void> _pickStart() async {
    final d = await pickDate(context, initial: _startDate ?? DateTime.now());
    if (d != null) setState(() => _startDate = d);
  }

  Future<void> _pickEnd() async {
    final d = await pickDate(context,
        initial: _endDate ?? DateTime.now(), lastDate: DateTime.now());
    if (d != null) setState(() => _endDate = d);
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'Select';
    return Formatters.date(d);
  }

  String? _apiDate(DateTime? d) {
    if (d == null) return null;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _generate(String key, Future<String?> Function() fn) async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select both From and To dates'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('To date must be on or after From date'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    setState(() => _activeReport = key);
    await fn();
    if (mounted) setState(() => _activeReport = null);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final showrooms = context.watch<ShowroomProvider>().showrooms;
    final allCardAccounts = context.watch<CardAccountProvider>().allAccounts;
    final from = _apiDate(_startDate) ?? '';
    final to = _apiDate(_endDate) ?? '';
    final hasDates = _startDate != null && _endDate != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date Range',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: _DateBtn(
                        label: 'From',
                        value: _fmt(_startDate),
                        onTap: _pickStart)),
                const SizedBox(width: 12),
                Expanded(
                    child: _DateBtn(
                        label: 'To', value: _fmt(_endDate), onTap: _pickEnd)),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Showroom>(
              value: _selectedShowroom,
              isExpanded: true,
              hint: const Text('All Showrooms'),
              decoration: InputDecoration(
                labelText: 'Showroom',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: [
                const DropdownMenuItem<Showroom>(
                    value: null, child: Text('All Showrooms')),
                ...showrooms.map(
                    (s) => DropdownMenuItem(value: s, child: Text(s.name))),
              ],
              onChanged: (v) => setState(() => _selectedShowroom = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<CardAccount>(
              value: _selectedCardAccount,
              isExpanded: true,
              hint: const Text('Select Card Account (for Card Statement)'),
              decoration: InputDecoration(
                labelText: 'Card Account',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              items: [
                const DropdownMenuItem<CardAccount>(
                    value: null, child: Text('None')),
                ...allCardAccounts.map((a) => DropdownMenuItem(
                    value: a,
                    child: Text(
                        Formatters.cardDropdownLabel(
                            a.bankName, a.lastFour, a.currentBalance),
                        overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (v) => setState(() => _selectedCardAccount = v),
            ),
            const SizedBox(height: 20),
            Text('Available Reports',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 10),
            _ReportCard(
              title: 'Daily Summary',
              description: _selectedShowroom != null
                  ? 'Cash & card totals for ${_selectedShowroom!.name}'
                  : 'Cash & card totals for all showrooms',
              icon: Icons.summarize_outlined,
              color: AppColors.primary,
              isLoading: _activeReport == 'daily_summary',
              hint: !hasDates ? 'Select date range first' : null,
              onTap: () => _generate(
                  'daily_summary',
                  () => provider.generateDailySummary(
                        from: from,
                        to: to,
                        showroomId: _selectedShowroom?.id,
                      )),
            ),
            _ReportCard(
              title: 'Showroom Report',
              description: _selectedShowroom != null
                  ? 'Breakdown for ${_selectedShowroom!.name}'
                  : 'Breakdown per showroom for the date range',
              icon: Icons.storefront_outlined,
              color: Colors.deepPurple,
              isLoading: _activeReport == 'showroom',
              hint: _selectedShowroom == null
                  ? 'Select a showroom first'
                  : !hasDates
                      ? 'Select date range first'
                      : null,
              onTap: _selectedShowroom == null
                  ? null
                  : () => _generate(
                      'showroom',
                      () => provider.generateShowroomReport(
                            showroomId: _selectedShowroom!.id,
                            from: from,
                            to: to,
                          )),
            ),
            _ReportCard(
              title: 'Card Statement',
              description: _selectedCardAccount != null
                  ? '${_selectedCardAccount!.bankName} •••• ${_selectedCardAccount!.lastFour}'
                  : 'Card account transaction history',
              icon: Icons.credit_card_rounded,
              color: AppColors.accent,
              isLoading: _activeReport == 'card_statement',
              hint: _selectedCardAccount == null
                  ? 'Select a card account first'
                  : !hasDates
                      ? 'Select date range first'
                      : null,
              onTap: _selectedCardAccount == null
                  ? null
                  : () => _generate(
                      'card_statement',
                      () => provider.generateCardStatement(
                          cardAccountId: _selectedCardAccount!.id,
                          from: from,
                          to: to)),
            ),
            _ReportCard(
              title: 'Self Transactions',
              description: 'Record of inter-account transfers',
              icon: Icons.swap_horiz_rounded,
              color: AppColors.success,
              isLoading: _activeReport == 'self_transactions',
              hint: !hasDates ? 'Select date range first' : null,
              onTap: () => _generate('self_transactions',
                  () => provider.generateSelfTransactions(from: from, to: to)),
            ),
            _ReportCard(
              title: 'Adjustments',
              description: 'Cash & card adjustments log',
              icon: Icons.tune_outlined,
              color: Colors.orange,
              isLoading: _activeReport == 'adjustments',
              hint: !hasDates ? 'Select date range first' : null,
              onTap: () => _generate('adjustments',
                  () => provider.generateAdjustments(from: from, to: to)),
            ),
            if (provider.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(provider.error!,
                            style: const TextStyle(color: AppColors.error))),
                    IconButton(
                      icon: const Icon(Icons.close,
                          color: AppColors.error, size: 18),
                      onPressed: provider.clearError,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DateBtn extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;
  const _DateBtn(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(value, style: GoogleFonts.inter(fontSize: 13)),
                const Icon(Icons.calendar_today_outlined,
                    size: 15, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title, description;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback? onTap;
  final String? hint;
  const _ReportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onTap,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(description,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.grey.shade600)),
                    if (hint != null && !isLoading)
                      Text(hint!,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.orange.shade700)),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                Icon(Icons.download_outlined,
                    color: onTap != null ? Colors.grey : Colors.grey.shade300),
            ],
          ),
        ),
      ),
    );
  }
}
