import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/self_transaction_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/admin/self_transaction_tile.dart';

class SelfTransactionListScreen extends StatefulWidget {
  const SelfTransactionListScreen({super.key});

  @override
  State<SelfTransactionListScreen> createState() =>
      _SelfTransactionListScreenState();
}

class _SelfTransactionListScreenState extends State<SelfTransactionListScreen> {
  final _scrollController = ScrollController();
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<SelfTransactionProvider>().fetchTransactions());
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final provider = context.read<SelfTransactionProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        provider.hasMore &&
        !provider.isLoading) {
      provider.fetchTransactions();
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
    final txns = context.read<SelfTransactionProvider>().transactions;
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
          .read<SelfTransactionProvider>()
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

  Future<void> _confirmDelete(dynamic transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Self Transaction'),
        content: Text(
            'Are you sure you want to delete this transaction of ${Formatters.currency(transaction.amount)}? Balance changes will be reversed.'),
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
          .read<SelfTransactionProvider>()
          .deleteTransaction(transaction.id);
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SelfTransactionProvider>();
    final total = provider.transactions.fold(0.0, (s, t) => s + t.amount);

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
              title: const Text('Self Transactions'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    final result = await Navigator.of(context)
                        .pushNamed(AppRoutes.selfTransactionForm);
                    if (result == true && mounted) {
                      context
                          .read<SelfTransactionProvider>()
                          .fetchTransactions();
                    }
                  },
                ),
              ],
            ),
      body: Column(
        children: [
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
                        .read<SelfTransactionProvider>()
                        .fetchTransactions());
              }
              if (provider.transactions.isEmpty) {
                return EmptyState(
                    icon: Icons.swap_horiz_rounded,
                    title: 'No transactions',
                    actionLabel: 'Add Transaction',
                    onAction: () => Navigator.of(context)
                        .pushNamed(AppRoutes.selfTransactionForm));
              }
              return RefreshIndicator(
                onRefresh: () =>
                    context.read<SelfTransactionProvider>().fetchTransactions(),
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
                    final t = provider.transactions[i];
                    final isSelected = _selectedIds.contains(t.id);
                    return GestureDetector(
                      onLongPress: () {
                        if (!_isSelectionMode) {
                          setState(() {
                            _isSelectionMode = true;
                            _selectedIds.add(t.id);
                          });
                        } else {
                          _confirmDelete(t);
                        }
                      },
                      onTap: _isSelectionMode
                          ? () => _toggleSelection(t.id)
                          : null,
                      child: Row(
                        children: [
                          if (_isSelectionMode)
                            Checkbox(
                              value: isSelected,
                              onChanged: (_) => _toggleSelection(t.id),
                              activeColor: AppColors.primary,
                            ),
                          Expanded(
                            child: SelfTransactionTile(transaction: t),
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
