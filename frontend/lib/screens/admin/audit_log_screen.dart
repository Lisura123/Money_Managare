import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/audit_log_provider.dart';
import '../../models/audit_log.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  final _scrollController = ScrollController();
  String? _tableName;
  String? _action;
  bool _isSelectionMode = false;
  final Set<int> _selectedIds = {};

  static const _tables = [
    'daily_cash_entries',
    'daily_card_entries',
    'admin_cash_adjustments',
    'admin_card_adjustments',
    'self_transactions',
    'showrooms',
    'card_accounts',
    'users',
    'settings',
  ];

  static const _actions = ['created', 'updated', 'deleted'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _scrollController.addListener(_onScroll);
  }

  Future<void> _load() async {
    await context.read<AuditLogProvider>().fetchLogs(
          tableName: _tableName,
          action: _action,
          refresh: true,
        );
  }

  void _onScroll() {
    final provider = context.read<AuditLogProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        provider.hasMore &&
        !provider.isLoading) {
      provider.fetchLogs(
          tableName: _tableName, action: _action, refresh: false);
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
    final provider = context.read<AuditLogProvider>();
    setState(() {
      if (_selectedIds.length == provider.logs.length) {
        _selectedIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedIds
          ..clear()
          ..addAll(provider.logs.map((l) => l.id));
      }
    });
  }

  void _cancelSelection() {
    setState(() {
      _selectedIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _bulkDelete() async {
    if (_selectedIds.isEmpty) return;
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Selected Logs'),
        content: Text(
            'Are you sure you want to delete $count ${count == 1 ? 'log' : 'logs'}? This cannot be undone.'),
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
      HapticFeedback.mediumImpact();
      await context
          .read<AuditLogProvider>()
          .bulkDeleteLogs(_selectedIds.toList());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Deleted $count ${count == 1 ? 'log' : 'logs'}'),
        backgroundColor: AppColors.success,
      ));
      _cancelSelection();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()),
        backgroundColor: AppColors.error,
      ));
    }
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => _FilterSheet(
        initialTable: _tableName,
        initialAction: _action,
        tables: _tables,
        actions: _actions,
        onApply: (t, a) {
          setState(() {
            _tableName = t;
            _action = a;
          });
          _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AuditLogProvider>();
    final hasFilters = _tableName != null || _action != null;

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                  icon: const Icon(Icons.close), onPressed: _cancelSelection),
              title: Text('${_selectedIds.length} selected'),
              actions: [
                IconButton(
                  icon: Icon(
                    _selectedIds.length ==
                            context.read<AuditLogProvider>().logs.length
                        ? Icons.deselect
                        : Icons.select_all,
                  ),
                  onPressed: _selectAll,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  onPressed: _bulkDelete,
                ),
              ],
            )
          : AppBar(
              title: const Text('Audit Log'),
              actions: [
                IconButton(
                  icon: Icon(Icons.filter_list,
                      color: hasFilters ? AppColors.accent : null),
                  onPressed: _showFilters,
                ),
              ],
            ),
      body: () {
        if (provider.isLoading && provider.logs.isEmpty) {
          return const ShimmerLoading(itemCount: 8);
        }
        if (provider.error != null && provider.logs.isEmpty) {
          return ErrorState(message: provider.error!, onRetry: _load);
        }
        if (provider.logs.isEmpty) {
          return const EmptyState(
              icon: Icons.history_edu_outlined, title: 'No audit logs');
        }
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: provider.logs.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == provider.logs.length) {
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator()));
              }
              final log = provider.logs[i];
              final isSelected = _selectedIds.contains(log.id);
              return GestureDetector(
                onLongPress: () {
                  if (!_isSelectionMode) {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _isSelectionMode = true;
                      _selectedIds.add(log.id);
                    });
                  }
                },
                child: Row(
                  children: [
                    if (_isSelectionMode)
                      Checkbox(
                        value: isSelected,
                        onChanged: (_) => _toggleSelection(log.id),
                        activeColor: AppColors.primary,
                      ),
                    Expanded(
                      child: _AuditTile(
                        log: log,
                        onTap: _isSelectionMode
                            ? () => _toggleSelection(log.id)
                            : null,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }(),
    );
  }
}

class _AuditTile extends StatelessWidget {
  final AuditLog log;
  final VoidCallback? onTap;
  const _AuditTile({required this.log, this.onTap});

  Color get _color {
    switch (log.action) {
      case 'created':
        return AppColors.success;
      case 'deleted':
        return AppColors.error;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(log.action.toUpperCase(),
                        style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _color)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(log.tableName,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ),
                  Text(Formatters.dateTime(log.createdAt),
                      style: GoogleFonts.inter(
                          fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
              const SizedBox(height: 4),
              if (log.userName != null)
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(log.userName!,
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              if (log.newValues != null && log.newValues!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  log.newValues!.entries
                      .take(3)
                      .map((e) => '${e.key}: ${e.value}')
                      .join(', '),
                  style: GoogleFonts.inter(
                      fontSize: 11, color: Colors.grey.shade500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final String? initialTable, initialAction;
  final List<String> tables, actions;
  final Function(String? table, String? action) onApply;
  const _FilterSheet({
    this.initialTable,
    this.initialAction,
    required this.tables,
    required this.actions,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  String? _table, _action;

  @override
  void initState() {
    super.initState();
    _table = widget.initialTable;
    _action = widget.initialAction;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filters',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _table,
            isExpanded: true,
            hint: const Text('All Tables'),
            decoration: InputDecoration(
              labelText: 'Table',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: [
              const DropdownMenuItem<String?>(
                  value: null, child: Text('All Tables')),
              ...widget.tables
                  .map((t) => DropdownMenuItem(value: t, child: Text(t))),
            ],
            onChanged: (v) => setState(() => _table = v),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _action,
            isExpanded: true,
            hint: const Text('All Actions'),
            decoration: InputDecoration(
              labelText: 'Action',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            items: [
              const DropdownMenuItem<String?>(
                  value: null, child: Text('All Actions')),
              ...widget.actions
                  .map((a) => DropdownMenuItem(value: a, child: Text(a))),
            ],
            onChanged: (v) => setState(() => _action = v),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                    onPressed: () {
                      widget.onApply(null, null);
                      Navigator.pop(context);
                    },
                    child: const Text('Clear')),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary),
                  onPressed: () {
                    widget.onApply(_table, _action);
                    Navigator.pop(context);
                  },
                  child: Text('Apply',
                      style: GoogleFonts.poppins(color: Colors.white)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
