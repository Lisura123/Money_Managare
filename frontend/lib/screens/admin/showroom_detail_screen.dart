import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../models/showroom.dart';
import '../../providers/showroom_provider.dart';
import '../../providers/card_account_provider.dart';
import '../../providers/cash_entry_provider.dart';
import '../../providers/card_entry_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/shimmer_loading.dart';

class ShowroomDetailScreen extends StatefulWidget {
  const ShowroomDetailScreen({super.key});

  @override
  State<ShowroomDetailScreen> createState() => _ShowroomDetailScreenState();
}

class _ShowroomDetailScreenState extends State<ShowroomDetailScreen> {
  Showroom? _showroom;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Showroom && _showroom == null) {
      _showroom = args;
      _load();
    }
  }

  Future<void> _load() async {
    if (_showroom == null) return;
    await Future.wait([
      context.read<CardAccountProvider>().fetchForShowroom(_showroom!.id),
      context.read<CashEntryProvider>().fetchEntries(showroomId: _showroom!.id),
      context.read<CardEntryProvider>().fetchEntries(showroomId: _showroom!.id),
    ]);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Showroom'),
        content: Text(
            'Are you sure you want to delete "${_showroom!.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<ShowroomProvider>().deleteShowroom(_showroom!.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cashProvider = context.watch<CashEntryProvider>();
    final cardProvider = context.watch<CardEntryProvider>();
    final accountProvider = context.watch<CardAccountProvider>();

    final cashTotal =
        cashProvider.entries.fold(0.0, (s, e) => s + e.cashAmount);
    final cardTotal = cardProvider.entries.fold(0.0, (s, e) => s + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(_showroom?.name ?? 'Showroom'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.of(context)
                  .pushNamed(AppRoutes.showroomForm, arguments: _showroom);
              if (result == true && mounted) {
                final updated = await context
                    .read<ShowroomProvider>()
                    .fetchShowroom(_showroom!.id);
                setState(() => _showroom = updated);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: _delete,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_showroom?.location != null) ...[
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: AppColors.accent, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _showroom!.location!,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: _StatBox(
                      label: 'Cash Total',
                      value: Formatters.currency(cashTotal),
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBox(
                      label: 'Card Total',
                      value: Formatters.currency(cardTotal),
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionHeader(
                title: 'Card Accounts',
                action: TextButton(
                  onPressed: () => Navigator.of(context).pushNamed(
                      AppRoutes.cardAccountList,
                      arguments: _showroom),
                  child: const Text('Manage'),
                ),
              ),
              if (accountProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: ShimmerLoading(
                      itemCount: 2, itemHeight: 62, padding: EdgeInsets.zero),
                )
              else if (accountProvider.accounts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text('No card accounts yet',
                      style: GoogleFonts.inter(
                          color: Colors.grey.shade500, fontSize: 13)),
                )
              else
                ...accountProvider.accounts.map((a) => AppCard(
                      padding: EdgeInsets.zero,
                      onTap: () => Navigator.of(context)
                          .pushNamed(AppRoutes.cardAccountDetail, arguments: a),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.credit_card_rounded,
                              color: AppColors.accent, size: 18),
                        ),
                        title: Text(a.bankName,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        subtitle: Text(
                            '${a.maskedNumber}  ·  ${Formatters.currency(a.currentBalance)}',
                            style: GoogleFonts.inter(fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: a.isActive
                                    ? AppColors.success.withValues(alpha: 0.1)
                                    : AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                a.isActive ? 'Active' : 'Inactive',
                                style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: a.isActive
                                        ? AppColors.success
                                        : AppColors.error),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right,
                                color: Colors.grey, size: 18),
                          ],
                        ),
                      ),
                    )),
              const SizedBox(height: 16),
              _SectionHeader(
                title: 'Recent Cash Entries',
                action: TextButton(
                  onPressed: () => Navigator.of(context).pushNamed(
                      AppRoutes.cashEntriesAdmin,
                      arguments: {'showroom': _showroom}),
                  child: const Text('View All'),
                ),
              ),
              if (cashProvider.isLoading && cashProvider.entries.isEmpty)
                const ShimmerLoading(
                    itemCount: 2, itemHeight: 60, padding: EdgeInsets.zero)
              else if (cashProvider.entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('No cash entries yet',
                      style: GoogleFonts.inter(
                          color: Colors.grey.shade500, fontSize: 13)),
                )
              else
                ...cashProvider.entries.take(5).map((e) {
                  final isMano = e.cashAccountType == 'mano';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 1,
                    child: ListTile(
                      dense: true,
                      leading: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: (isMano
                                  ? const Color(0xFF7C3AED)
                                  : AppColors.success)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.attach_money,
                            size: 16,
                            color: isMano
                                ? const Color(0xFF7C3AED)
                                : AppColors.success),
                      ),
                      title: Text(Formatters.date(e.entryDate),
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w500, fontSize: 13)),
                      subtitle: Text(e.cashAccountLabel,
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.grey.shade500)),
                      trailing: Text(Formatters.currency(e.cashAmount),
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: AppColors.primary)),
                    ),
                  );
                }),
              const SizedBox(height: 16),
              _SectionHeader(
                title: 'Recent Card Entries',
                action: TextButton(
                  onPressed: () => Navigator.of(context).pushNamed(
                      AppRoutes.cardEntriesAdmin,
                      arguments: {'showroom': _showroom}),
                  child: const Text('View All'),
                ),
              ),
              if (cardProvider.isLoading && cardProvider.entries.isEmpty)
                const ShimmerLoading(
                    itemCount: 2, itemHeight: 60, padding: EdgeInsets.zero)
              else if (cardProvider.entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('No card entries yet',
                      style: GoogleFonts.inter(
                          color: Colors.grey.shade500, fontSize: 13)),
                )
              else
                ...cardProvider.entries.take(5).map((e) => Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 1,
                      child: ListTile(
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.credit_card_rounded,
                              color: AppColors.accent, size: 16),
                        ),
                        title: Text(Formatters.date(e.entryDate),
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500, fontSize: 13)),
                        subtitle: e.bankName != null
                            ? Text(Formatters.cardLabel(e.bankName, e.lastFour),
                                style: GoogleFonts.inter(
                                    fontSize: 11, color: Colors.grey.shade500))
                            : null,
                        trailing: Text(Formatters.currency(e.amount),
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.primary)),
                      ),
                    )),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBox(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 14, color: color)),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;
  const _SectionHeader({required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
        if (action != null) action!,
      ],
    );
  }
}
