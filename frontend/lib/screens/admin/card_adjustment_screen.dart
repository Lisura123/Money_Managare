import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/card_entry_provider.dart';
import '../../providers/card_account_provider.dart';
import '../../providers/showroom_provider.dart';
import '../../models/showroom.dart';
import '../../models/card_account.dart';
import '../../services/api_service.dart';
import '../../utils/validators.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/app_button.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/admin/adjustment_tile.dart';

class CardAdjustmentScreen extends StatefulWidget {
  const CardAdjustmentScreen({super.key});

  @override
  State<CardAdjustmentScreen> createState() => _CardAdjustmentScreenState();
}

class _CardAdjustmentScreenState extends State<CardAdjustmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  Showroom? _selectedShowroom;
  CardAccount? _selectedAccount;
  bool _isLoading = false;
  bool _isAddition = true;
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  double get _parsedAmount =>
      double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CardEntryProvider>().fetchAdjustments();
      if (context.read<ShowroomProvider>().showrooms.isEmpty) {
        context.read<ShowroomProvider>().fetchShowrooms();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteAdjustment(dynamic adjustment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Card Adjustment'),
        content: Text(
            'Are you sure you want to delete this adjustment of ${Formatters.currency(adjustment.adjustedAmount)}? The balance change will be reversed.'),
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
      await context.read<CardEntryProvider>().deleteAdjustment(adjustment.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Adjustment deleted'),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    }
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
    final adjustments = context.read<CardEntryProvider>().adjustments;
    setState(() {
      if (_selectedIds.length == adjustments.length) {
        _selectedIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedIds.clear();
        _selectedIds.addAll(adjustments.map((a) => a.id));
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
        title: const Text('Delete Selected Adjustments'),
        content: Text(
            'Are you sure you want to delete $count ${count == 1 ? 'adjustment' : 'adjustments'}? Balance changes will be reversed.'),
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
          .bulkDeleteAdjustments(_selectedIds.toList());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '$count ${count == 1 ? 'adjustment' : 'adjustments'} deleted'),
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

  Widget _signBtn(String label, bool isAdd) {
    final selected = _isAddition == isAdd;
    final color = isAdd ? AppColors.success : AppColors.error;
    return GestureDetector(
      onTap: () => setState(() => _isAddition = isAdd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          border: Border.all(color: selected ? color : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _loadAccounts(Showroom showroom) async {
    await context.read<CardAccountProvider>().fetchForShowroom(showroom.id);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);
    try {
      final raw = double.parse(_amountController.text.replaceAll(',', ''));
      final amount = _isAddition ? raw : -raw;
      await context.read<CardEntryProvider>().addAdjustment(
            cardAccountId: _selectedAccount?.id,
            amount: amount,
            reason: _reasonController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Card adjustment added'),
        backgroundColor: AppColors.success,
      ));
      _amountController.clear();
      _reasonController.clear();
      setState(() {
        _selectedShowroom = null;
        _selectedAccount = null;
      });
      context.read<CardEntryProvider>().fetchAdjustments();
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
    final provider = context.watch<CardEntryProvider>();
    final showrooms = context.watch<ShowroomProvider>().showrooms;
    final accounts = context.watch<CardAccountProvider>().accounts;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
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
                      _selectedIds.length == provider.adjustments.length
                          ? Icons.deselect
                          : Icons.select_all,
                    ),
                    tooltip: _selectedIds.length == provider.adjustments.length
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
            : AppBar(title: const Text('Card Adjustments')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('New Adjustment',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, fontSize: 15)),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<Showroom>(
                          initialValue: _selectedShowroom,
                          isExpanded: true,
                          hint: const Text('Filter by showroom'),
                          decoration: InputDecoration(
                            labelText: 'Showroom',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                          items: showrooms
                              .map((s) => DropdownMenuItem(
                                  value: s, child: Text(s.name)))
                              .toList(),
                          onChanged: (v) {
                            setState(() {
                              _selectedShowroom = v;
                              _selectedAccount = null;
                            });
                            if (v != null) _loadAccounts(v);
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<CardAccount>(
                          initialValue: _selectedAccount,
                          isExpanded: true,
                          hint: const Text('Card Account (optional)'),
                          decoration: InputDecoration(
                            labelText: 'Card Account',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                          ),
                          items: [
                            const DropdownMenuItem<CardAccount>(
                                value: null, child: Text('All Accounts')),
                            ...accounts.map((a) => DropdownMenuItem(
                                value: a, child: Text(a.dropdownLabel(null)))),
                          ],
                          onChanged: (v) =>
                              setState(() => _selectedAccount = v),
                        ),
                        if (_selectedAccount != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.account_balance_wallet,
                                      size: 16, color: AppColors.accent),
                                  const SizedBox(width: 8),
                                  Text('Current Balance:',
                                      style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.grey.shade700)),
                                  const SizedBox(width: 6),
                                  Text(
                                    Formatters.currency(
                                        _selectedAccount!.currentBalance),
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _signBtn('+ Add', true)),
                            const SizedBox(width: 8),
                            Expanded(child: _signBtn('− Subtract', false)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AmountTextField(
                          label: 'Amount (Rs.)',
                          controller: _amountController,
                          validator: Validators.positiveAmount,
                        ),
                        if (_parsedAmount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 4),
                            child: Center(
                              child: Text(
                                _isAddition
                                    ? '+${Formatters.currency(_parsedAmount)}'
                                    : '−${Formatters.currency(_parsedAmount)}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: _isAddition
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        AppTextField(
                          label: 'Reason',
                          controller: _reasonController,
                          prefixIcon: Icons.notes_outlined,
                          maxLines: 2,
                          validator: Validators.required,
                        ),
                        const SizedBox(height: 16),
                        AppButton(
                          label: 'Apply Adjustment',
                          onPressed: _submit,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Adjustment History',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              const SizedBox(height: 8),
              if (provider.isLoading && provider.adjustments.isEmpty)
                const ShimmerLoading(itemCount: 4)
              else if (provider.adjustments.isEmpty)
                const EmptyState(
                    icon: Icons.tune_outlined, title: 'No adjustments yet')
              else
                ...provider.adjustments.map((a) => GestureDetector(
                      onLongPress: () {
                        if (!_isSelectionMode) {
                          setState(() {
                            _isSelectionMode = true;
                            _selectedIds.add(a.id);
                          });
                        }
                      },
                      child: Row(
                        children: [
                          if (_isSelectionMode)
                            Checkbox(
                              value: _selectedIds.contains(a.id),
                              onChanged: (_) => _toggleSelection(a.id),
                              activeColor: AppColors.primary,
                            ),
                          Expanded(
                            child: GestureDetector(
                              onTap: _isSelectionMode
                                  ? () => _toggleSelection(a.id)
                                  : null,
                              child: AdjustmentTile(
                                date: Formatters.date(a.createdAt),
                                adminName: a.adminName ?? '',
                                amount: a.adjustedAmount,
                                reason: a.reason ?? '',
                                isCard: true,
                                onDelete: _isSelectionMode
                                    ? null
                                    : () => _confirmDeleteAdjustment(a),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
