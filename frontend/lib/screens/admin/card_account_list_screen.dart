import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../models/showroom.dart';
import '../../models/card_account.dart';
import '../../providers/card_account_provider.dart';
import '../../providers/showroom_provider.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/common/app_card.dart';

class CardAccountListScreen extends StatefulWidget {
  const CardAccountListScreen({super.key});

  @override
  State<CardAccountListScreen> createState() => _CardAccountListScreenState();
}

class _CardAccountListScreenState extends State<CardAccountListScreen> {
  Showroom? _showroom;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Showroom && _showroom == null) {
      _showroom = args;
    }
    _load();
  }

  Future<void> _load() async {
    if (_showroom != null) {
      await context.read<CardAccountProvider>().fetchForShowroom(_showroom!.id);
    } else {
      await context.read<CardAccountProvider>().fetchAllAccounts(
          context.read<ShowroomProvider>().showrooms.map((s) => s.id).toList());
    }
  }

  Future<void> _delete(CardAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Card Account'),
        content:
            Text('Delete "${account.displayLabel}"? This cannot be undone.'),
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
          .read<CardAccountProvider>()
          .deleteAccount(account.showroomId, account.id);
      if (mounted) _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardAccountProvider>();
    final accounts =
        _showroom != null ? provider.accounts : provider.allAccounts;

    return Scaffold(
      appBar: AppBar(
        title: Text(_showroom != null
            ? '${_showroom!.name} Cards'
            : 'All Card Accounts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.of(context).pushNamed(
                  AppRoutes.cardAccountForm,
                  arguments: {'showroom': _showroom});
              if (result == true && mounted) _load();
            },
          ),
        ],
      ),
      body: () {
        if (provider.isLoading && accounts.isEmpty) {
          return const ShimmerLoading(itemCount: 5);
        }
        if (provider.error != null && accounts.isEmpty) {
          return ErrorState(message: provider.error!, onRetry: _load);
        }
        if (accounts.isEmpty) {
          return EmptyState(
              icon: Icons.credit_card_outlined,
              title: 'No card accounts',
              actionLabel: 'Add Account',
              onAction: () => Navigator.of(context).pushNamed(
                  AppRoutes.cardAccountForm,
                  arguments: {'showroom': _showroom}));
        }
        return RefreshIndicator(
          onRefresh: _load,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            itemBuilder: (ctx, i) {
              final a = accounts[i];
              return AppCard(
                child: ListTile(
                  onTap: () => Navigator.of(context)
                      .pushNamed(AppRoutes.cardAccountDetail, arguments: a),
                  leading: const Icon(Icons.credit_card_rounded,
                      color: AppColors.accent),
                  title: Text(a.displayLabel),
                  subtitle: Text(a.maskedNumber),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () async {
                          final result = await Navigator.of(context).pushNamed(
                              AppRoutes.cardAccountForm,
                              arguments: {'account': a, 'showroom': _showroom});
                          if (result == true && mounted) _load();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error, size: 18),
                        onPressed: () => _delete(a),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      }(),
    );
  }
}
