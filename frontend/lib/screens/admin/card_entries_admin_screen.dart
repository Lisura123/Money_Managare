import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/daily_card_entry.dart';
import '../../providers/card_account_provider.dart';
import '../../providers/card_entry_provider.dart';
import '../../providers/showroom_provider.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/admin/entry_list_tile.dart';
import '../../widgets/admin/filter_bottom_sheet.dart';

class CardEntriesAdminScreen extends StatefulWidget {
  const CardEntriesAdminScreen({super.key});

  @override
  State<CardEntriesAdminScreen> createState() => _CardEntriesAdminScreenState();
}

class _CardEntriesAdminScreenState extends State<CardEntriesAdminScreen> {
  final _scrollController = ScrollController();
  DateTime? _startDate, _endDate;
  int? _showroomId;
  int? _cardAccountId;
  Timer? _refreshTimer;
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args['showroom'] != null) {
        _showroomId = args['showroom'].id;
      }
      _loadCardAccounts();
      _load();
    });
    _scrollController.addListener(_onScroll);
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _silentRefresh(),
    );
  }

  Future<void> _silentRefresh() async {
    if (!mounted) return;
    await context.read<CardEntryProvider>().fetchEntries(
          from: _fmt(_startDate),
          to: _fmt(_endDate),
          showroomId: _showroomId,
          cardAccountId: _cardAccountId,
          refresh: true,
          silent: true,
        );
  }

  Future<void> _loadCardAccounts() async {
    final showrooms = context.read<ShowroomProvider>().showrooms;
    if (showrooms.isNotEmpty) {
      await context
          .read<CardAccountProvider>()
          .fetchAllAccounts(showrooms.map((s) => s.id).toList());
    }
  }

  String? _fmt(DateTime? d) => d == null
      ? null
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    await context.read<CardEntryProvider>().fetchEntries(
          from: _fmt(_startDate),
          to: _fmt(_endDate),
          showroomId: _showroomId,
          cardAccountId: _cardAccountId,
          refresh: true,
        );
  }

  void _onScroll() {
    final provider = context.read<CardEntryProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        provider.hasMore &&
        !provider.isLoading) {
      context.read<CardEntryProvider>().fetchEntries(
            from: _fmt(_startDate),
            to: _fmt(_endDate),
            showroomId: _showroomId,
            cardAccountId: _cardAccountId,
          );
    }
  }

  void _showEntryOptions(DailyCardEntry entry) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${Formatters.date(entry.entryDate)} — ${Formatters.currency(entry.amount)}',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 15),
            ),
            Text(
                '${entry.userName ?? ''} · ${entry.showroomName ?? ''} · ${entry.bankName ?? ''} •••• ${entry.lastFour ?? ''}',
                style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.grey.shade600)),
            const Divider(height: 20),
            if (!entry.isLocked) ...[
              ListTile(
                leading:
                    const Icon(Icons.edit_outlined, color: AppColors.accent),
                title: const Text('Edit Entry'),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditDialog(entry);
                },
              ),
            ],
            ListTile(
              leading:
                  const Icon(Icons.tune_outlined, color: AppColors.primary),
              title: const Text('Add Adjustment'),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(ctx);
                _showAdjustmentDialog(entry);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete Entry'),
              contentPadding: EdgeInsets.zero,
              onTap: () {
                Navigator.pop(ctx);
                _confirmDeleteEntry(entry);
              },
            ),
            if (entry.isLocked)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.lock, size: 14, color: AppColors.error),
                    const SizedBox(width: 6),
                    Text('This entry is locked',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.error)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll() {
    final entries = context.read<CardEntryProvider>().entries;
    setState(() {
      if (_selectedIds.length == entries.length) {
        _selectedIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedIds.clear();
        _selectedIds.addAll(entries.map((e) => e.id));
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  Future<void> _bulkDelete() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Selected Entries'),
        content: Text(
            'Are you sure you want to delete $count ${count == 1 ? 'entry' : 'entries'}? This will reverse balance changes and cannot be undone.'),
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
      await context
          .read<CardEntryProvider>()
          .bulkDeleteEntries(_selectedIds.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('$count ${count == 1 ? 'entry' : 'entries'} deleted'),
            backgroundColor: AppColors.success));
        _cancelSelection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _confirmDeleteEntry(DailyCardEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Card Entry'),
        content: Text(
            'Are you sure you want to delete this entry of ${Formatters.currency(entry.amount)}? This will reverse the balance change and cannot be undone.'),
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
      await context.read<CardEntryProvider>().deleteEntry(entry.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Card entry deleted'),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    }
  }

  void _showEditDialog(DailyCardEntry entry) {
    final amountCtrl =
        TextEditingController(text: entry.amount.toStringAsFixed(2));
    final notesCtrl = TextEditingController(text: entry.notes ?? '');
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Card Entry'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Amount (Rs.)',
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: Validators.positiveAmount,
                prefixText: 'Rs. ',
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Notes (optional)',
                controller: notesCtrl,
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              try {
                await context.read<CardEntryProvider>().updateEntry(
                      entry.id,
                      amount: double.parse(amountCtrl.text),
                      notes: notesCtrl.text.trim().isEmpty
                          ? null
                          : notesCtrl.text.trim(),
                    );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Entry updated'),
                      backgroundColor: AppColors.success));
                  _load();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppColors.error));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAdjustmentDialog(DailyCardEntry entry) {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isAdditionNotifier = ValueNotifier<bool>(true);

    Widget signBtn(bool isAdd, bool isAddition) {
      final sel = isAddition == isAdd;
      final c = isAdd ? AppColors.success : AppColors.error;
      return GestureDetector(
        onTap: () => isAdditionNotifier.value = isAdd,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: sel ? c : Colors.transparent,
            border: Border.all(color: sel ? c : Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            isAdd ? '+ Add' : '− Subtract',
            style: TextStyle(
              color: sel ? Colors.white : Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => ValueListenableBuilder<bool>(
        valueListenable: isAdditionNotifier,
        builder: (_, isAddition, __) =>
            ValueListenableBuilder<TextEditingValue>(
          valueListenable: amountCtrl,
          builder: (_, __, ___) {
            final raw =
                double.tryParse(amountCtrl.text.replaceAll(',', '')) ?? 0.0;
            final color = isAddition ? AppColors.success : AppColors.error;
            return AlertDialog(
              title: const Text('Add Adjustment'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Expanded(child: signBtn(true, isAddition)),
                      const SizedBox(width: 8),
                      Expanded(child: signBtn(false, isAddition)),
                    ]),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Amount (Rs.)',
                      controller: amountCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                      validator: Validators.positiveAmount,
                      prefixText: 'Rs. ',
                    ),
                    if (raw > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 2),
                        child: Center(
                          child: Text(
                            isAddition
                                ? '+${Formatters.currency(raw)}'
                                : '−${Formatters.currency(raw)}',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: color),
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    AppTextField(
                      label: 'Reason',
                      controller: reasonCtrl,
                      maxLines: 2,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(ctx);
                    final amount =
                        double.parse(amountCtrl.text.replaceAll(',', '')) *
                            (isAddition ? 1 : -1);
                    try {
                      await context
                          .read<CardEntryProvider>()
                          .addEntryAdjustment(
                            entry.id,
                            amount: amount,
                            reason: reasonCtrl.text.trim(),
                          );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Adjustment added'),
                                backgroundColor: AppColors.success));
                        _load();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: AppColors.error));
                      }
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardEntryProvider>();
    final showrooms = context
        .watch<ShowroomProvider>()
        .showrooms
        .map((s) => {'id': s.id, 'name': s.name})
        .toList();
    final cardAccounts = context
        .watch<CardAccountProvider>()
        .allAccounts
        .map((a) => {
              'id': a.id,
              'label': '${a.bankName} •••• ${a.lastFour}',
            })
        .toList();
    final total = provider.totalAmount;

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _cancelSelection,
              ),
              title: Text('${_selectedIds.length} selected'),
              actions: [
                IconButton(
                  icon: Icon(
                    _selectedIds.length == provider.entries.length
                        ? Icons.deselect
                        : Icons.select_all,
                  ),
                  tooltip: _selectedIds.length == provider.entries.length
                      ? 'Deselect All'
                      : 'Select All',
                  onPressed: _selectAll,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  tooltip: 'Delete Selected',
                  onPressed: _bulkDelete,
                ),
              ],
            )
          : AppBar(
              title: const Text('Card Entries'),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.filter_list,
                    color: (_startDate != null ||
                            _endDate != null ||
                            _showroomId != null ||
                            _cardAccountId != null)
                        ? AppColors.accent
                        : null,
                  ),
                  onPressed: () => FilterBottomSheet.show(
                    context,
                    initialStartDate: _startDate,
                    initialEndDate: _endDate,
                    initialShowroomId: _showroomId,
                    initialCardAccountId: _cardAccountId,
                    showrooms: showrooms,
                    cardAccounts: cardAccounts,
                    onApply: (s, e, sid, caid, _) {
                      setState(() {
                        _startDate = s;
                        _endDate = e;
                        _showroomId = sid;
                        _cardAccountId = caid;
                      });
                      _load();
                    },
                  ),
                ),
              ],
            ),
      body: Column(
        children: [
          if (provider.entries.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.accent.withValues(alpha: 0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${provider.totalEntries} entries',
                      style: GoogleFonts.inter(fontSize: 13)),
                  Text('Total: ${Formatters.currency(total)}',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent)),
                ],
              ),
            ),
          Expanded(
            child: () {
              if (provider.isLoading && provider.entries.isEmpty) {
                return const ShimmerLoading(itemCount: 6);
              }
              if (provider.error != null && provider.entries.isEmpty) {
                return ErrorState(message: provider.error!, onRetry: _load);
              }
              if (provider.entries.isEmpty) {
                return const EmptyState(
                    icon: Icons.credit_card_rounded,
                    title: 'No card entries found');
              }
              return RefreshIndicator(
                onRefresh: _load,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      provider.entries.length + (provider.hasMore ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == provider.entries.length) {
                      return const Center(
                          child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator()));
                    }
                    final e = provider.entries[i];
                    final isSelected = _selectedIds.contains(e.id);
                    return GestureDetector(
                      onLongPress: () {
                        if (!_isSelectionMode) {
                          setState(() {
                            _isSelectionMode = true;
                            _selectedIds.add(e.id);
                          });
                        }
                      },
                      child: Row(
                        children: [
                          if (_isSelectionMode)
                            Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggleSelection(e.id),
                              activeColor: AppColors.primary,
                            ),
                          Expanded(
                            child: EntryListTile(
                              date:
                                  Formatters.date(DateTime.parse(e.entryDate)),
                              staffName: e.userName ?? '',
                              amount: e.amount,
                              isLocked: e.isLocked,
                              isCard: true,
                              showroomName: e.showroomName,
                              notes: e.notes,
                              cardLabel: '${e.bankName} •••• ${e.lastFour}',
                              onTap: _isSelectionMode
                                  ? () => _toggleSelection(e.id)
                                  : () => _showEntryOptions(e),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            }(),
          ),
        ],
      ),
    );
  }
}
