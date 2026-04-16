import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cash_entry_provider.dart';
import '../../providers/card_entry_provider.dart';
import '../../providers/staff_status_provider.dart';
import '../../models/today_status.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../staff/cash_entry_screen.dart';
import '../staff/card_entry_screen.dart';
import '../staff/staff_history_screen.dart';
import '../staff/staff_profile_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  int _currentIndex = 0;

  static const _tabs = [
    _StaffHomeTab(),
    StaffHistoryScreen(),
    StaffProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Are you sure you want to exit?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Exit')),
            ],
          ),
        );
        if (shouldExit == true) SystemNavigator.pop();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _tabs,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          selectedItemColor: AppColors.accent,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'History'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home tab (previous StaffDashboardScreen content)
// ---------------------------------------------------------------------------

class _StaffHomeTab extends StatefulWidget {
  const _StaffHomeTab();

  @override
  State<_StaffHomeTab> createState() => _StaffHomeTabState();
}

class _StaffHomeTabState extends State<_StaffHomeTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    await Future.wait([
      context.read<CashEntryProvider>().fetchMyHistory(),
      context.read<CardEntryProvider>().fetchMyHistory(),
      context.read<StaffStatusProvider>().fetchTodayStatus(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final cashProvider = context.watch<CashEntryProvider>();
    final cardProvider = context.watch<CardEntryProvider>();
    final statusProvider = context.watch<StaffStatusProvider>();
    final todayStatus = statusProvider.status;
    final isWindowOpen = statusProvider.isEditWindowOpen;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          'Dashboard',
          style: GoogleFonts.poppins(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _GreetingCard(user: user),
              const SizedBox(height: 20),
              if (!isWindowOpen)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_clock,
                          color: Colors.orange.shade700, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Entry Submission Closed',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.orange.shade800)),
                            const SizedBox(height: 2),
                            Text(
                              'Open from ${Formatters.time12h(statusProvider.editWindowStart)} to ${Formatters.time12h(statusProvider.editWindowEnd)}',
                              style: GoogleFonts.inter(
                                  fontSize: 11, color: Colors.orange.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Text('Quick Actions',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _ActionCard(
                          icon: Icons.attach_money,
                          label: 'Main Account',
                          color: AppColors.success,
                          disabled: !isWindowOpen,
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const CashEntryScreen(
                                      cashAccountType: 'main'))),
                        ),
                        _CashStatusBadge(status: todayStatus?.mainCash),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        _ActionCard(
                          icon: Icons.attach_money,
                          label: "Mano's Account",
                          color: const Color(0xFF7C3AED),
                          disabled: !isWindowOpen,
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const CashEntryScreen(
                                      cashAccountType: 'mano'))),
                        ),
                        _CashStatusBadge(status: todayStatus?.manoCash),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _ActionCard(
                          icon: Icons.credit_card_rounded,
                          label: 'Card Entry',
                          color: AppColors.accent,
                          disabled: !isWindowOpen,
                          onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const CardEntryScreen())),
                        ),
                        _CardStatusBadge(status: todayStatus?.card),
                      ],
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 20),
              _SummaryRow(
                cashCount: cashProvider.myHistory.length,
                cardCount: cardProvider.myHistory.length,
                cashTotal: cashProvider.myHistory
                    .fold(0.0, (sum, e) => sum + e.cashAmount),
                cardTotal: cardProvider.myHistory
                    .fold(0.0, (sum, e) => sum + e.amount),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Cash Entries',
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: () => context
                        .findAncestorStateOfType<_StaffDashboardScreenState>()
                        ?.setState(() => context
                            .findAncestorStateOfType<
                                _StaffDashboardScreenState>()!
                            ._currentIndex = 1),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (cashProvider.isLoading)
                const ShimmerLoading(itemCount: 3)
              else if (cashProvider.myHistory.isEmpty)
                const _EmptyRecent(label: 'No cash entries yet.')
              else
                ...cashProvider.myHistory.take(3).map((e) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: const Icon(Icons.attach_money,
                            color: AppColors.success),
                        title: Text(Formatters.date(e.entryDate),
                            style:
                                GoogleFonts.inter(fontWeight: FontWeight.w500)),
                        trailing: Text(Formatters.currency(e.cashAmount),
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ),
                    )),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Card Entries',
                      style: GoogleFonts.poppins(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  TextButton(
                    onPressed: () => context
                        .findAncestorStateOfType<_StaffDashboardScreenState>()
                        ?.setState(() => context
                            .findAncestorStateOfType<
                                _StaffDashboardScreenState>()!
                            ._currentIndex = 1),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (cardProvider.isLoading)
                const ShimmerLoading(itemCount: 3)
              else if (cardProvider.myHistory.isEmpty)
                const _EmptyRecent(label: 'No card entries yet.')
              else
                ...cardProvider.myHistory.take(3).map((e) => Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: const Icon(Icons.credit_card_rounded,
                            color: AppColors.accent),
                        title: Text(Formatters.date(e.entryDate),
                            style:
                                GoogleFonts.inter(fontWeight: FontWeight.w500)),
                        subtitle: e.bankName != null
                            ? Text(
                                Formatters.cardLabel(
                                    e.bankName!, e.lastFour ?? ''),
                                style: GoogleFonts.inter(fontSize: 12))
                            : null,
                        trailing: Text(Formatters.currency(e.amount),
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ),
                    )),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreetingCard extends StatelessWidget {
  final dynamic user;
  const _GreetingCard({required this.user});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF2D4A7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(
              user?.initials ?? '?',
              style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting,
                  style:
                      GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
              Text(
                user?.name ?? '',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16),
              ),
              if (user?.showroomName != null)
                Text(user!.showroomName!,
                    style:
                        GoogleFonts.inter(color: Colors.white60, fontSize: 11)),
              const SizedBox(height: 2),
              Text(Formatters.date(DateTime.now()),
                  style:
                      GoogleFonts.inter(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool disabled;
  const _ActionCard(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap,
      this.disabled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: disabled
                ? Colors.grey.withValues(alpha: 0.1)
                : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: disabled
                    ? Colors.grey.withValues(alpha: 0.3)
                    : color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(disabled ? Icons.lock_outline : icon,
                  color: disabled ? Colors.grey : color, size: 32),
              const SizedBox(height: 8),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: disabled ? Colors.grey : color,
                      fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int cashCount, cardCount;
  final double cashTotal, cardTotal;
  const _SummaryRow(
      {required this.cashCount,
      required this.cardCount,
      required this.cashTotal,
      required this.cardTotal});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _SummaryItem(
                label: 'Cash Entries',
                value: '$cashCount',
                sub: Formatters.currency(cashTotal),
                color: AppColors.success)),
        const SizedBox(width: 12),
        Expanded(
            child: _SummaryItem(
                label: 'Card Entries',
                value: '$cardCount',
                sub: Formatters.currency(cardTotal),
                color: AppColors.accent)),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label, value, sub;
  final Color color;
  const _SummaryItem(
      {required this.label,
      required this.value,
      required this.sub,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style:
                GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700, fontSize: 22, color: color)),
        Text(sub,
            style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

class _EmptyRecent extends StatelessWidget {
  final String label;
  const _EmptyRecent({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(label,
          style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13)),
    );
  }
}

// ---------------------------------------------------------------------------
// Today Status Badges
// ---------------------------------------------------------------------------

class _CashStatusBadge extends StatelessWidget {
  final CashEntryStatus? status;
  const _CashStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();
    if (status!.submitted) {
      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline,
                size: 12, color: AppColors.success),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                status!.amount != null
                    ? Formatters.currency(status!.amount!)
                    : 'Submitted',
                style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(
        'Not submitted',
        style: GoogleFonts.inter(
            fontSize: 10,
            color: AppColors.warning,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CardStatusBadge extends StatelessWidget {
  final CardStatusToday? status;
  const _CardStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();
    if (status!.count > 0) {
      return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6)),
        child: Text(
          '${status!.count} entries · ${Formatters.currency(status!.total)}',
          style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.accent,
              fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6)),
      child: Text(
        'No entries today',
        style: GoogleFonts.inter(
            fontSize: 10,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500),
      ),
    );
  }
}
