import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/cash_transaction_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';

class CashTransactionListScreen extends StatefulWidget {
  const CashTransactionListScreen({super.key});

  @override
  State<CashTransactionListScreen> createState() =>
      _CashTransactionListScreenState();
}

class _CashTransactionListScreenState extends State<CashTransactionListScreen> {
  final _scrollController = ScrollController();
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CashTransactionProvider>().fetchTransactions(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final p = context.read<CashTransactionProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        p.hasMore &&
        !p.isLoading) {
      p.fetchTransactions();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
    final txns = context.read<CashTransactionProvider>().transactions;
    setState(() {
      if (_selectedIds.length == txns.length) {
        _selectedIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedIds.clear();
        _selectedIds.addAll(txns.map((t) => t.id));
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
        title: const Text('Delete Selected Transactions'),
        content: Text(
            'Are you sure you want to delete $count ${count == 1 ? 'transaction' : 'transactions'}? Balance changes will be reversed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context
          .read<CashTransactionProvider>()
          .bulkDeleteTransactions(_selectedIds.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '$count ${count == 1 ? 'transaction' : 'transactions'} deleted'),
            backgroundColor: Colors.green));
        _cancelSelection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _confirmDelete(dynamic tx) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Cash Transaction'),
        content: Text(
            'Are you sure you want to delete this transaction of ${Formatters.currency(tx.amount)}? Balance changes will be reversed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<CashTransactionProvider>().deleteTransaction(tx.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Transaction deleted'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  String _fmtDisplay(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _showFilterSheet() async {
    final provider = context.read<CashTransactionProvider>();

    // Local mutable copies for the sheet
    DateTime? fromDate = provider.filterDateFrom;
    DateTime? toDate = provider.filterDateTo;
    String? fromAccount = provider.filterFromAccount;
    String? txType = provider.filterType;

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          Future<void> pickDate(bool isFrom) async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: ctx,
              initialDate: (isFrom ? fromDate : toDate) ?? now,
              firstDate: DateTime(2020),
              lastDate: now,
            );
            if (picked != null) {
              setSheetState(() => isFrom ? fromDate = picked : toDate = picked);
            }
          }

          String fmtChip(DateTime? d) => d == null ? 'Select' : _fmtDisplay(d);

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Filters',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                const SizedBox(height: 16),
                // Date range
                const Text('Date Range',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _DateButton(
                          label: 'From',
                          value: fmtChip(fromDate),
                          onTap: () => pickDate(true)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateButton(
                          label: 'To',
                          value: fmtChip(toDate),
                          onTap: () => pickDate(false)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // From account
                const Text('From Account',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: fromAccount,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Accounts')),
                    DropdownMenuItem(
                        value: 'main', child: Text('Main Account')),
                    DropdownMenuItem(
                        value: 'mano', child: Text("Mano's Account")),
                  ],
                  onChanged: (v) => setSheetState(() => fromAccount = v),
                ),
                const SizedBox(height: 16),
                // Transaction type
                const Text('Transaction Type',
                    style:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: txType,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade300)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Types')),
                    DropdownMenuItem(
                        value: 'internal',
                        child: Text('Internal (between accounts)')),
                    DropdownMenuItem(
                        value: 'external',
                        child: Text('External (out of accounts)')),
                  ],
                  onChanged: (v) => setSheetState(() => txType = v),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          provider.clearFilters();
                          provider.fetchTransactions(refresh: true);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary),
                        onPressed: () {
                          provider.setFilters(
                            fromAccount: fromAccount,
                            type: txType,
                            dateFrom: fromDate,
                            dateTo: toDate,
                          );
                          provider.fetchTransactions(refresh: true);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Apply',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CashTransactionProvider>();
    final total = provider.transactions.fold(0.0, (s, t) => s + t.amount);
    final hasFilters = provider.hasActiveFilters;

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
                    _selectedIds.length == provider.transactions.length
                        ? Icons.deselect
                        : Icons.select_all,
                  ),
                  tooltip: _selectedIds.length == provider.transactions.length
                      ? 'Deselect All'
                      : 'Select All',
                  onPressed: _selectAll,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete Selected',
                  onPressed: _bulkDelete,
                ),
              ],
            )
          : AppBar(
              title: const Text('Cash Transactions'),
              actions: [
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.filter_list_outlined),
                      tooltip: 'Filter',
                      onPressed: _showFilterSheet,
                    ),
                    if (hasFilters)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                              color: AppColors.accent, shape: BoxShape.circle),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final result = await Navigator.of(context)
                        .pushNamed(AppRoutes.cashTransactionForm);
                    if (result == true && mounted) {
                      context
                          .read<CashTransactionProvider>()
                          .fetchTransactions(refresh: true);
                    }
                  },
                ),
              ],
            ),
      body: Column(
        children: [
          // Active filter chips
          if (hasFilters)
            _ActiveFilterChips(
              provider: provider,
              fmtDisplay: _fmtDisplay,
              onClearAll: () {
                provider.clearFilters();
                provider.fetchTransactions(refresh: true);
              },
              onRemoveFilter: (which) {
                switch (which) {
                  case 'fromAccount':
                    provider.setFilters(
                        type: provider.filterType,
                        dateFrom: provider.filterDateFrom,
                        dateTo: provider.filterDateTo);
                  case 'type':
                    provider.setFilters(
                        fromAccount: provider.filterFromAccount,
                        dateFrom: provider.filterDateFrom,
                        dateTo: provider.filterDateTo);
                  case 'dateFrom':
                    provider.setFilters(
                        fromAccount: provider.filterFromAccount,
                        type: provider.filterType,
                        dateTo: provider.filterDateTo);
                  case 'dateTo':
                    provider.setFilters(
                        fromAccount: provider.filterFromAccount,
                        type: provider.filterType,
                        dateFrom: provider.filterDateFrom);
                }
                provider.fetchTransactions(refresh: true);
              },
            ),
          if (provider.transactions.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.accent.withValues(alpha: 0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${provider.transactions.length} transactions'),
                  Text('Total: ${Formatters.currency(total)}'),
                ],
              ),
            ),
          ],
          Expanded(
            child: () {
              if (provider.isLoading && provider.transactions.isEmpty) {
                return const ShimmerLoading(itemCount: 6);
              }
              if (provider.error != null && provider.transactions.isEmpty) {
                return ErrorState(
                    message: provider.error!,
                    onRetry: () => context
                        .read<CashTransactionProvider>()
                        .fetchTransactions(refresh: true));
              }
              if (provider.transactions.isEmpty) {
                return EmptyState(
                    icon: Icons.currency_exchange_outlined,
                    title: 'No cash transactions',
                    actionLabel: 'Add Transaction',
                    onAction: () async {
                      final result = await Navigator.of(context)
                          .pushNamed(AppRoutes.cashTransactionForm);
                      if (result == true && mounted) {
                        context
                            .read<CashTransactionProvider>()
                            .fetchTransactions(refresh: true);
                      }
                    });
              }
              return RefreshIndicator(
                onRefresh: () => context
                    .read<CashTransactionProvider>()
                    .fetchTransactions(refresh: true),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount:
                      provider.transactions.length + (provider.hasMore ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == provider.transactions.length) {
                      return const Center(
                          child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator()));
                    }
                    final tx = provider.transactions[i];
                    final isSelected = _selectedIds.contains(tx.id);
                    return GestureDetector(
                      onLongPress: () {
                        if (!_isSelectionMode) {
                          setState(() {
                            _isSelectionMode = true;
                            _selectedIds.add(tx.id);
                          });
                        } else {
                          _confirmDelete(tx);
                        }
                      },
                      onTap: _isSelectionMode
                          ? () => _toggleSelection(tx.id)
                          : null,
                      child: Row(
                        children: [
                          if (_isSelectionMode)
                            Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggleSelection(tx.id),
                              activeColor: AppColors.primary,
                            ),
                          Expanded(
                            child: _CashTransactionTile(tx: tx),
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

// ---------------------------------------------------------------------------
// Active filter chips bar
// ---------------------------------------------------------------------------

class _ActiveFilterChips extends StatelessWidget {
  final CashTransactionProvider provider;
  final String Function(DateTime) fmtDisplay;
  final VoidCallback onClearAll;
  final void Function(String which) onRemoveFilter;

  const _ActiveFilterChips({
    required this.provider,
    required this.fmtDisplay,
    required this.onClearAll,
    required this.onRemoveFilter,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (provider.filterDateFrom != null) {
      chips.add(_chip('From: ${fmtDisplay(provider.filterDateFrom!)}',
          () => onRemoveFilter('dateFrom')));
    }
    if (provider.filterDateTo != null) {
      chips.add(_chip('To: ${fmtDisplay(provider.filterDateTo!)}',
          () => onRemoveFilter('dateTo')));
    }
    if (provider.filterFromAccount != null) {
      final label = provider.filterFromAccount == 'main' ? 'Main' : "Mano's";
      chips.add(_chip('From: $label', () => onRemoveFilter('fromAccount')));
    }
    if (provider.filterType != null) {
      final label = provider.filterType == 'internal' ? 'Internal' : 'External';
      chips.add(_chip(label, () => onRemoveFilter('type')));
    }

    return Container(
      color: Colors.grey.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: chips),
            ),
          ),
          TextButton(
            onPressed: onClearAll,
            style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: const Text('Clear all', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, VoidCallback onDelete) => Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Chip(
          label: Text(label, style: const TextStyle(fontSize: 12)),
          deleteIcon: const Icon(Icons.close, size: 14),
          onDeleted: onDelete,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          visualDensity: VisualDensity.compact,
          backgroundColor: AppColors.primary.withValues(alpha: 0.08),
          side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
        ),
      );
}

// ---------------------------------------------------------------------------
// Date picker button (reused from FilterBottomSheet pattern)
// ---------------------------------------------------------------------------

class _DateButton extends StatelessWidget {
  final String label, value;
  final VoidCallback onTap;

  const _DateButton(
      {required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            const SizedBox(height: 2),
            Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _CashTransactionTile extends StatelessWidget {
  final dynamic tx;
  const _CashTransactionTile({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isExternalTo = tx.toAccountType == null;
    final color = isExternalTo ? Colors.orange : AppColors.success;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.currency_exchange_outlined,
                  color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: tx.fromLabel,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Icon(Icons.arrow_forward,
                                size: 13, color: Colors.grey.shade500),
                          ),
                        ),
                        TextSpan(
                          text: tx.toLabel,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isExternalTo
                                  ? Colors.orange
                                  : AppColors.primary),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    Formatters.date(tx.transactionDate),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  if (tx.notes != null && tx.notes!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        tx.notes!,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              Formatters.currency(tx.amount),
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.accent),
            ),
          ],
        ),
      ),
    );
  }
}
