import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/card_account.dart';
import '../../providers/card_account_provider.dart';
import '../../providers/card_entry_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/admin/adjustment_tile.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/shimmer_loading.dart';

class CardAccountDetailScreen extends StatefulWidget {
  const CardAccountDetailScreen({super.key});

  @override
  State<CardAccountDetailScreen> createState() =>
      _CardAccountDetailScreenState();
}

class _CardAccountDetailScreenState extends State<CardAccountDetailScreen>
    with SingleTickerProviderStateMixin {
  CardAccount? _account;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is CardAccount && _account == null) {
      _account = args;
      _load();
    }
  }

  Future<void> _load() async {
    if (_account == null) return;
    await Future.wait([
      context
          .read<CardEntryProvider>()
          .fetchEntries(cardAccountId: _account!.id, refresh: true),
      context
          .read<CardEntryProvider>()
          .fetchAdjustments(cardAccountId: _account!.id),
    ]);
  }

  Future<void> _refreshAccount() async {
    if (_account == null) return;
    final cardAccountProvider = context.read<CardAccountProvider>();
    await cardAccountProvider.fetchForShowroom(_account!.showroomId);
    final updated = cardAccountProvider.accounts
        .where((a) => a.id == _account!.id)
        .firstOrNull;
    if (updated != null && mounted) {
      setState(() => _account = updated);
    }
    await _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_account == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final entryProvider = context.watch<CardEntryProvider>();
    final a = _account!;

    return Scaffold(
      appBar: AppBar(
        title: Text(a.displayLabel),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit',
            onPressed: () async {
              final result = await Navigator.of(context).pushNamed(
                AppRoutes.cardAccountForm,
                arguments: {'account': a},
              );
              if (result == true && mounted) _refreshAccount();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAccount,
        child: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverToBoxAdapter(child: _buildHeader(a)),
            SliverToBoxAdapter(child: _buildInfoCard(a)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: 'Entries'),
                    Tab(text: 'Adjustments'),
                  ],
                ),
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _EntriesTab(provider: entryProvider),
              _AdjustmentsTab(provider: entryProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(CardAccount a) {
    final isActive = a.isActive;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.75)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.credit_card_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.bankName,
                      style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      a.maskedNumber,
                      style: GoogleFonts.inter(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withValues(alpha: 0.25)
                      : Colors.red.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: GoogleFonts.inter(
                    color: isActive ? Colors.greenAccent : Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Current Balance',
            style: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.currency(a.currentBalance),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(CardAccount a) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            children: [
              _infoRow('Showroom', a.showroomName ?? '—'),
              const Divider(height: 20),
              _infoRow('Card Number', a.maskedNumber),
              const Divider(height: 20),
              _infoRow('Status', a.isActive ? 'Active' : 'Inactive',
                  valueColor: a.isActive ? AppColors.success : AppColors.error),
              if (a.createdAt != null) ...[
                const Divider(height: 20),
                _infoRow('Created', Formatters.date(a.createdAt!)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _EntriesTab extends StatelessWidget {
  final CardEntryProvider provider;
  const _EntriesTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.entries.isEmpty) {
      return const ShimmerLoading(itemCount: 5);
    }
    if (provider.entries.isEmpty) {
      return const EmptyState(
          icon: Icons.receipt_long_outlined, title: 'No entries yet');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.entries.length,
      itemBuilder: (_, i) {
        final e = provider.entries[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 1,
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.credit_card_outlined,
                  color: AppColors.accent, size: 18),
            ),
            title: Text(
              Formatters.currency(e.amount),
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              '${Formatters.date(DateTime.parse(e.entryDate))}  ·  ${e.userName ?? ''}',
              style:
                  GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: e.isLocked
                ? const Icon(Icons.lock, size: 14, color: AppColors.error)
                : null,
          ),
        );
      },
    );
  }
}

class _AdjustmentsTab extends StatelessWidget {
  final CardEntryProvider provider;
  const _AdjustmentsTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.adjustments.isEmpty) {
      return const ShimmerLoading(itemCount: 4);
    }
    if (provider.adjustments.isEmpty) {
      return const EmptyState(
          icon: Icons.tune_outlined, title: 'No adjustments yet');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.adjustments.length,
      itemBuilder: (_, i) {
        final adj = provider.adjustments[i];
        return AdjustmentTile(
          date: adj.createdAt != null ? Formatters.date(adj.createdAt!) : '—',
          adminName: adj.adminName ?? '',
          amount: adj.adjustedAmount,
          reason: adj.reason ?? '',
          isCard: true,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Pinned tab bar delegate
// ---------------------------------------------------------------------------

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  const _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate old) => tabBar != old.tabBar;
}
