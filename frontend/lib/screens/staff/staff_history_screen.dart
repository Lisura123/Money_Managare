import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/cash_entry_provider.dart';
import '../../providers/card_entry_provider.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/staff/cash_entry_card.dart';
import '../../widgets/staff/card_entry_card.dart';
import 'cash_edit_request_screen.dart';
import 'card_edit_request_screen.dart';

class StaffHistoryScreen extends StatefulWidget {
  const StaffHistoryScreen({super.key});

  @override
  State<StaffHistoryScreen> createState() => _StaffHistoryScreenState();
}

class _StaffHistoryScreenState extends State<StaffHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _cashScrollController = ScrollController();
  final _cardScrollController = ScrollController();
  String? _cashAccountTypeFilter; // null = All, 'main', 'mano'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
    _cashScrollController.addListener(_onCashScroll);
    _cardScrollController.addListener(_onCardScroll);
  }

  Future<void> _loadAll() async {
    await Future.wait([
      context
          .read<CashEntryProvider>()
          .fetchMyHistory(cashAccountType: _cashAccountTypeFilter),
      context.read<CardEntryProvider>().fetchMyHistory(),
    ]);
  }

  void _onCashScroll() {
    final provider = context.read<CashEntryProvider>();
    if (_cashScrollController.position.pixels >=
            _cashScrollController.position.maxScrollExtent - 100 &&
        provider.historyHasMore &&
        !provider.isLoading) {
      provider.fetchMyHistory(cashAccountType: _cashAccountTypeFilter);
    }
  }

  void _onCardScroll() {
    final provider = context.read<CardEntryProvider>();
    if (_cardScrollController.position.pixels >=
            _cardScrollController.position.maxScrollExtent - 100 &&
        provider.historyHasMore &&
        !provider.isLoading) {
      provider.fetchMyHistory();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cashScrollController.dispose();
    _cardScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My History'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          labelStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Cash Entries'),
            Tab(text: 'Card Entries'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CashTab(
            scrollController: _cashScrollController,
            cashAccountTypeFilter: _cashAccountTypeFilter,
            onFilterChanged: (type) {
              setState(() => _cashAccountTypeFilter = type);
              context
                  .read<CashEntryProvider>()
                  .fetchMyHistory(cashAccountType: type, refresh: true);
            },
          ),
          _CardTab(scrollController: _cardScrollController)
        ],
      ),
    );
  }
}

class _CashTab extends StatelessWidget {
  final ScrollController scrollController;
  final String? cashAccountTypeFilter;
  final ValueChanged<String?> onFilterChanged;

  const _CashTab({
    required this.scrollController,
    required this.cashAccountTypeFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CashEntryProvider>();
    if (provider.isLoading && provider.myHistory.isEmpty) {
      return const ShimmerLoading(itemCount: 6);
    }
    if (provider.error != null && provider.myHistory.isEmpty) {
      return ErrorState(
          message: provider.error!,
          onRetry: () => context
              .read<CashEntryProvider>()
              .fetchMyHistory(cashAccountType: cashAccountTypeFilter));
    }
    return Column(
      children: [
        // Segmented filter
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: cashAccountTypeFilter == null,
                onTap: () => onFilterChanged(null),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Main',
                color: AppColors.success,
                selected: cashAccountTypeFilter == 'main',
                onTap: () => onFilterChanged('main'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: "Mano's",
                color: const Color(0xFF7C3AED),
                selected: cashAccountTypeFilter == 'mano',
                onTap: () => onFilterChanged('mano'),
              ),
            ],
          ),
        ),
        Expanded(
          child: () {
            if (provider.myHistory.isEmpty) {
              return const EmptyState(
                  icon: Icons.attach_money, title: 'No cash entries found');
            }
            return RefreshIndicator(
              onRefresh: () => context.read<CashEntryProvider>().fetchMyHistory(
                  cashAccountType: cashAccountTypeFilter, refresh: true),
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: provider.myHistory.length +
                    (provider.historyHasMore ? 1 : 0),
                itemBuilder: (ctx, i) {
                  if (i == provider.myHistory.length) {
                    return const Center(
                        child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator()));
                  }
                  final entry = provider.myHistory[i];
                  return GestureDetector(
                    onTap: entry.isLocked
                        ? null
                        : () async {
                            final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        CashEditRequestScreen(entry: entry)));
                            if (result == true) {
                              context.read<CashEntryProvider>().fetchMyHistory(
                                  cashAccountType: cashAccountTypeFilter,
                                  refresh: true);
                            }
                          },
                    child: CashEntryCard(entry: entry),
                  );
                },
              ),
            );
          }(),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey.shade600),
        ),
      ),
    );
  }
}

class _CardTab extends StatelessWidget {
  final ScrollController scrollController;
  const _CardTab({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardEntryProvider>();
    if (provider.isLoading && provider.myHistory.isEmpty) {
      return const ShimmerLoading(itemCount: 6);
    }
    if (provider.error != null && provider.myHistory.isEmpty) {
      return ErrorState(
          message: provider.error!,
          onRetry: () => context.read<CardEntryProvider>().fetchMyHistory());
    }
    if (provider.myHistory.isEmpty) {
      return const EmptyState(
          icon: Icons.credit_card_rounded, title: 'No card entries found');
    }
    return RefreshIndicator(
      onRefresh: () =>
          context.read<CardEntryProvider>().fetchMyHistory(refresh: true),
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.all(16),
        itemCount:
            provider.myHistory.length + (provider.historyHasMore ? 1 : 0),
        itemBuilder: (ctx, i) {
          if (i == provider.myHistory.length) {
            return const Center(
                child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator()));
          }
          final entry = provider.myHistory[i];
          return GestureDetector(
            onTap: entry.isLocked
                ? null
                : () async {
                    final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) =>
                                CardEditRequestScreen(entry: entry)));
                    if (result == true) {
                      context
                          .read<CardEntryProvider>()
                          .fetchMyHistory(refresh: true);
                    }
                  },
            child: CardEntryCard(entry: entry),
          );
        },
      ),
    );
  }
}
