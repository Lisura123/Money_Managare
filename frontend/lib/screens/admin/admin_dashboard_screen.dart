import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../models/dashboard_summary.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/edit_request_provider.dart';
import '../../providers/showroom_provider.dart';
import '../../screens/admin/edit_requests_screen.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/shimmer_loading.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with WidgetsBindingObserver {
  int _navIndex = 0;
  DateTime? _lastBackgroundTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().initialize();
      context.read<DashboardProvider>().setActive(true);
      context.read<ShowroomProvider>().fetchShowrooms();
      context.read<EditRequestProvider>().fetchPendingCount();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<DashboardProvider>().setActive(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final provider = context.read<DashboardProvider>();
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _lastBackgroundTime = DateTime.now();
      provider.setActive(false);
    } else if (state == AppLifecycleState.resumed) {
      provider.setActive(true);
      if (_lastBackgroundTime != null) {
        final elapsed =
            DateTime.now().difference(_lastBackgroundTime!).inMinutes;
        if (elapsed >= 10) {
          provider.fetch(silent: true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Refreshing data...'),
              duration: Duration(seconds: 2),
            ));
          }
        }
      }
      _lastBackgroundTime = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final dashProvider = context.watch<DashboardProvider>();

    // Show new-day notification once
    if (dashProvider.newDayDetected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('New day — dashboard refreshed.'),
            backgroundColor: AppColors.accent,
            duration: Duration(seconds: 3),
          ));
          context.read<DashboardProvider>().clearNewDayNotification();
        }
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_navIndex != 0) {
          setState(() => _navIndex = 0);
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
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: Text(
            _navIndex == 0
                ? 'Dashboard'
                : _navIndex == 1
                    ? 'Showrooms'
                    : _navIndex == 2
                        ? 'Transactions'
                        : _navIndex == 3
                            ? 'Reports'
                            : 'Settings',
            style: GoogleFonts.poppins(
                color: Colors.white, fontWeight: FontWeight.w600),
          ),
          actions: [
            if (_navIndex == 0)
              Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none,
                        color: Colors.white),
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const AdminEditRequestsScreen())),
                  ),
                  Consumer<EditRequestProvider>(
                    builder: (_, p, __) {
                      if (p.pendingCount == 0) return const SizedBox.shrink();
                      return Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                              color: Colors.red, shape: BoxShape.circle),
                          child: Text(
                            p.pendingCount > 99 ? '99+' : '${p.pendingCount}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            IconButton(
              icon: const Icon(Icons.person_outline, color: Colors.white),
              onPressed: _showProfileMenu,
            ),
          ],
        ),
        body: IndexedStack(
          index: _navIndex,
          children: [
            _HomeTab(user: user),
            _ShowroomsTab(),
            const _TransactionsTab(),
          ],
        ),
        floatingActionButton: _navIndex == 0
            ? FloatingActionButton(
                heroTag: 'adminDashboardFab',
                backgroundColor: AppColors.accent,
                onPressed: () => _showAddMenu(context),
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _navIndex,
          onTap: (i) {
            if (i == 3) {
              Navigator.of(context).pushNamed(AppRoutes.reports);
            } else if (i == 4) {
              Navigator.of(context).pushNamed(AppRoutes.settings);
            } else {
              setState(() => _navIndex = i);
            }
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle:
              GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard'),
            BottomNavigationBarItem(
                icon: Icon(Icons.storefront_outlined),
                activeIcon: Icon(Icons.storefront),
                label: 'Showrooms'),
            BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'Transactions'),
            BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart),
                label: 'Reports'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Settings'),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu() {
    final user = context.read<AuthProvider>().user;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(user?.initials ?? '?',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: AppColors.primary)),
            ),
            const SizedBox(height: 10),
            Text(user?.name ?? '',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600, fontSize: 16)),
            Text(user?.email ?? '',
                style: GoogleFonts.inter(
                    color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change Password'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushNamed(AppRoutes.changePassword);
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Staff Management'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushNamed(AppRoutes.staffList);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: const Text('Sign Out',
                  style: TextStyle(color: AppColors.error)),
              onTap: () async {
                Navigator.pop(ctx);
                await context.read<AuthProvider>().logout();
                if (mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Quick Add',
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            _QuickAddTile(
              icon: Icons.storefront_outlined,
              label: 'New Showroom',
              color: AppColors.primary,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushNamed(AppRoutes.showroomForm);
              },
            ),
            _QuickAddTile(
              icon: Icons.credit_card_rounded,
              label: 'New Card Account',
              color: AppColors.accent,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushNamed(AppRoutes.cardAccountForm);
              },
            ),
            _QuickAddTile(
              icon: Icons.swap_horiz_rounded,
              label: 'Self Transaction',
              color: AppColors.success,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).pushNamed(AppRoutes.selfTransactionForm);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _QuickAddTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAddTile(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }
}

class _HomeTab extends StatelessWidget {
  final dynamic user;
  const _HomeTab({required this.user});

  @override
  Widget build(BuildContext context) {
    final dp = context.watch<DashboardProvider>();

    return RefreshIndicator(
      onRefresh: () => context.read<DashboardProvider>().fetch(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _WelcomeBanner(user: user),
            const SizedBox(height: 16),
            if (dp.isLoading && dp.summary == null)
              const ShimmerLoading(itemCount: 4)
            else
              _buildSummaryCards(dp),
            _LastUpdatedRow(dp: dp),
            const SizedBox(height: 20),
            _QuickNavRow(),
            const SizedBox(height: 20),
            Text('Showrooms Overview',
                style: GoogleFonts.poppins(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (dp.summary != null)
              ..._buildShowroomCards(context, dp.summary!.today.perShowroom)
            else
              ..._buildShowroomFallback(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(DashboardProvider dp) {
    final today = dp.summary?.today ?? DailySnapshot.empty();
    final yesterday = dp.summary?.yesterday ?? DailySnapshot.empty();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _AnimatedStatCard(
                label: 'Main Cash',
                value: today.cashMainAdjusted,
                rawValue: today.cashMainTotal,
                yesterdayValue: yesterday.cashMainAdjusted,
                icon: Icons.attach_money,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AnimatedStatCard(
                label: "Mano's Cash",
                value: today.cashManoAdjusted,
                rawValue: today.cashManoTotal,
                yesterdayValue: yesterday.cashManoAdjusted,
                icon: Icons.attach_money,
                color: const Color(0xFF7C3AED),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AnimatedStatCard(
                label: 'Total Card',
                value: today.cardAdjusted,
                rawValue: today.cardTotal,
                yesterdayValue: yesterday.cardAdjusted,
                icon: Icons.credit_card_rounded,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AnimatedStatCard(
                label: 'Grand Total',
                value: today.grandAdjusted,
                rawValue: today.grandTotal,
                yesterdayValue: yesterday.grandAdjusted,
                icon: Icons.account_balance_outlined,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildShowroomCards(
      BuildContext context, List<ShowroomSnapshot> perShowroom) {
    if (perShowroom.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(
            child: Text('No data for today yet.',
                style: GoogleFonts.inter(color: Colors.grey.shade500)),
          ),
        ),
      ];
    }
    return perShowroom.map((s) => _ShowroomSnapshotCard(snapshot: s)).toList();
  }

  List<Widget> _buildShowroomFallback(BuildContext context) {
    final sp = context.watch<ShowroomProvider>();
    if (sp.isLoading) return [const ShimmerLoading(itemCount: 3)];
    return sp.showrooms
        .map((s) => _SimpleShowroomCard(
              name: s.name,
              onTap: () => Navigator.of(context)
                  .pushNamed(AppRoutes.showroomDetail, arguments: s),
            ))
        .toList();
  }
}

// ---------------------------------------------------------------------------
// Last Updated Row
// ---------------------------------------------------------------------------

class _LastUpdatedRow extends StatelessWidget {
  final DashboardProvider dp;
  const _LastUpdatedRow({required this.dp});

  @override
  Widget build(BuildContext context) {
    if (dp.lastFetchedAt == null) return const SizedBox.shrink();
    final minutesAgo = DateTime.now().difference(dp.lastFetchedAt!).inMinutes;
    final timeStr = DateFormat('h:mm a').format(dp.lastFetchedAt!);
    final isStale = minutesAgo >= 5;
    final label = isStale
        ? 'Last updated: $timeStr ($minutesAgo min ago)'
        : 'Last updated: $timeStr';

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.update,
              size: 12,
              color: isStale ? AppColors.warning : Colors.grey.shade400),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 10,
                color: isStale ? AppColors.warning : Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated Stat Card
// ---------------------------------------------------------------------------

class _AnimatedStatCard extends StatefulWidget {
  final String label;
  final double value;
  final double rawValue;
  final double yesterdayValue;
  final IconData icon;
  final Color color;

  const _AnimatedStatCard({
    required this.label,
    required this.value,
    required this.rawValue,
    required this.yesterdayValue,
    required this.icon,
    required this.color,
  });

  @override
  State<_AnimatedStatCard> createState() => _AnimatedStatCardState();
}

class _AnimatedStatCardState extends State<_AnimatedStatCard> {
  double _prevValue = 0;
  bool _flash = false;
  bool _increased = false;

  @override
  void didUpdateWidget(_AnimatedStatCard old) {
    super.didUpdateWidget(old);
    if ((old.value - widget.value).abs() > 0.001) {
      setState(() {
        _prevValue = old.value;
        _increased = widget.value > old.value;
        _flash = true;
      });
      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _flash = false);
      });
    }
  }

  String _trendText() {
    final y = widget.yesterdayValue;
    final t = widget.value;
    if (y == 0) return '';
    final diff = t - y;
    final pct = (diff / y * 100).abs();
    if (diff > 0) return '+${pct.toStringAsFixed(0)}%';
    if (diff < 0) return '-${pct.toStringAsFixed(0)}%';
    return '=';
  }

  Color _trendColor() {
    if (widget.yesterdayValue == 0) return Colors.grey.shade400;
    return widget.value >= widget.yesterdayValue
        ? AppColors.success
        : AppColors.error;
  }

  IconData? _trendIcon() {
    if (widget.yesterdayValue == 0) return null;
    if ((widget.value - widget.yesterdayValue).abs() < 0.001) return null;
    return widget.value > widget.yesterdayValue
        ? Icons.arrow_upward
        : Icons.arrow_downward;
  }

  @override
  Widget build(BuildContext context) {
    final trend = _trendText();
    final trendIcon = _trendIcon();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _flash
            ? (_increased
                ? AppColors.success.withValues(alpha: 0.08)
                : AppColors.error.withValues(alpha: 0.08))
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6)),
                child: Icon(widget.icon, color: widget.color, size: 16),
              ),
              const Spacer(),
              if (trend.isNotEmpty && trendIcon != null) ...[
                Icon(trendIcon, size: 11, color: _trendColor()),
                const SizedBox(width: 2),
                Text(trend,
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: _trendColor(),
                        fontWeight: FontWeight.w600)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            key: ValueKey(widget.value),
            tween: Tween(begin: _prevValue, end: widget.value),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOut,
            builder: (_, val, __) => Text(
              Formatters.currency(val),
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: widget.color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(widget.label,
              style:
                  GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade600)),
          if ((widget.value - widget.rawValue).abs() > 0.001)
            Text(
              'Raw: ${Formatters.currency(widget.rawValue)}',
              style:
                  GoogleFonts.inter(fontSize: 9, color: Colors.grey.shade400),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Showroom snapshot card (from dashboard summary)
// ---------------------------------------------------------------------------

class _ShowroomSnapshotCard extends StatelessWidget {
  final ShowroomSnapshot snapshot;
  const _ShowroomSnapshotCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final cashTotal = snapshot.cashMainAdjusted + snapshot.cashManoAdjusted;
    final grandTotal = cashTotal + snapshot.cardAdjusted;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.storefront_outlined,
              color: AppColors.primary, size: 20),
        ),
        title: Text(snapshot.showroomName,
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text(
          'Cash: ${Formatters.currency(cashTotal)}  '
          'Card: ${Formatters.currency(snapshot.cardAdjusted)}',
          style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(Formatters.currency(grandTotal),
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.primary)),
            Text('${snapshot.entryCount} card entries',
                style: GoogleFonts.inter(
                    fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Simple Showroom Card (fallback — no snapshot)
// ---------------------------------------------------------------------------

class _SimpleShowroomCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;
  const _SimpleShowroomCard({required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.storefront_outlined,
              color: AppColors.primary, size: 20),
        ),
        title: Text(name,
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final dynamic user;
  const _WelcomeBanner({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [AppColors.primary, Color(0xFF2D4A7A)]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Text(user?.initials ?? '?',
                style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back,',
                    style:
                        GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                Text(user?.name ?? '',
                    style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                const SizedBox(height: 2),
                Text(DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                    style:
                        GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Admin',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _QuickNavRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Access',
            style:
                GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavChip(
                icon: Icons.attach_money,
                label: 'Cash',
                onTap: () => Navigator.of(context)
                    .pushNamed(AppRoutes.cashEntriesAdmin)),
            _NavChip(
                icon: Icons.credit_card_rounded,
                label: 'Cards',
                onTap: () => Navigator.of(context)
                    .pushNamed(AppRoutes.cardEntriesAdmin)),
            _NavChip(
                icon: Icons.swap_horiz_rounded,
                label: 'Transfers',
                onTap: () => Navigator.of(context)
                    .pushNamed(AppRoutes.selfTransactionList)),
            _NavChip(
                icon: Icons.history_edu_outlined,
                label: 'Audit',
                onTap: () =>
                    Navigator.of(context).pushNamed(AppRoutes.auditLog)),
          ],
        ),
      ],
    );
  }
}

class _NavChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _NavChip(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary)),
          ],
        ),
      ),
    );
  }
}

class _ShowroomsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sp = context.watch<ShowroomProvider>();
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => context.read<ShowroomProvider>().fetchShowrooms(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sp.showrooms.length,
          itemBuilder: (ctx, i) {
            final s = sp.showrooms[i];
            return _SimpleShowroomCard(
              name: s.name,
              onTap: () => Navigator.of(context)
                  .pushNamed(AppRoutes.showroomDetail, arguments: s),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addShowroomFab',
        backgroundColor: AppColors.primary,
        onPressed: () =>
            Navigator.of(context).pushNamed(AppRoutes.showroomForm),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _TransactionsTab extends StatelessWidget {
  const _TransactionsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Transactions',
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppColors.primary)),
          const SizedBox(height: 16),
          _NavCard(
            icon: Icons.attach_money_rounded,
            title: 'Cash Entries',
            subtitle: 'View and manage all cash entries',
            color: AppColors.primary,
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.cashEntriesAdmin),
          ),
          const SizedBox(height: 12),
          _NavCard(
            icon: Icons.credit_card_rounded,
            title: 'Card Entries',
            subtitle: 'View and manage all card entries',
            color: AppColors.accent,
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.cardEntriesAdmin),
          ),
          const SizedBox(height: 12),
          _NavCard(
            icon: Icons.swap_horiz_rounded,
            title: 'Self Transactions',
            subtitle: 'Inter-account transfers',
            color: AppColors.success,
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.selfTransactionList),
          ),
          const SizedBox(height: 12),
          _NavCard(
            icon: Icons.currency_exchange_outlined,
            title: 'Cash Transactions',
            subtitle: 'Transfer between cash accounts',
            color: const Color(0xFF7C3AED),
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.cashTransactionList),
          ),
          const SizedBox(height: 12),
          _NavCard(
            icon: Icons.tune_outlined,
            title: 'Cash Adjustments',
            subtitle: 'Apply adjustments to cash records',
            color: Colors.orange,
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.cashAdjustment),
          ),
          const SizedBox(height: 12),
          _NavCard(
            icon: Icons.credit_score_outlined,
            title: 'Card Adjustments',
            subtitle: 'Apply adjustments to card records',
            color: Colors.deepOrange,
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.cardAdjustment),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _NavCard(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title,
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle,
            style:
                GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
