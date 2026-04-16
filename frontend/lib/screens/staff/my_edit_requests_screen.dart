import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/edit_request.dart';
import '../../providers/edit_request_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';

class MyEditRequestsScreen extends StatefulWidget {
  const MyEditRequestsScreen({super.key});

  @override
  State<MyEditRequestsScreen> createState() => _MyEditRequestsScreenState();
}

class _MyEditRequestsScreenState extends State<MyEditRequestsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditRequestProvider>().fetchMyRequests(refresh: true);
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final p = context.read<EditRequestProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        p.myHasMore &&
        !p.myLoading) {
      p.fetchMyRequests();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EditRequestProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Edit Requests')),
      body: Builder(builder: (ctx) {
        if (provider.myLoading && provider.myRequests.isEmpty) {
          return const ShimmerLoading(itemCount: 5);
        }
        if (provider.myError != null && provider.myRequests.isEmpty) {
          return ErrorState(
            message: provider.myError!,
            onRetry: () => context
                .read<EditRequestProvider>()
                .fetchMyRequests(refresh: true),
          );
        }
        if (provider.myRequests.isEmpty) {
          return const EmptyState(
              icon: Icons.edit_note_outlined, title: 'No edit requests yet');
        }
        return RefreshIndicator(
          onRefresh: () => context
              .read<EditRequestProvider>()
              .fetchMyRequests(refresh: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount:
                provider.myRequests.length + (provider.myHasMore ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == provider.myRequests.length) {
                return const Center(
                    child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator()));
              }
              final req = provider.myRequests[i];
              return _EditRequestCard(
                request: req,
                onCancelled: () {
                  context
                      .read<EditRequestProvider>()
                      .fetchMyRequests(refresh: true);
                },
              );
            },
          ),
        );
      }),
    );
  }
}

// -------------------------------------------------------
// Edit Request Card (staff view)
// -------------------------------------------------------
class _EditRequestCard extends StatelessWidget {
  final EditRequest request;
  final VoidCallback onCancelled;
  const _EditRequestCard({required this.request, required this.onCancelled});

  String _formatAmount(dynamic v) {
    if (v == null) return '—';
    final d = double.tryParse(v.toString());
    if (d == null) return v.toString();
    return Formatters.currency(d);
  }

  String _amountKey() => request.entryType == 'cash' ? 'cash_amount' : 'amount';

  @override
  Widget build(BuildContext context) {
    final origAmount = request.originalValues[_amountKey()];
    final reqAmount = request.requestedChanges[_amountKey()];
    final hasAmountChange = origAmount != null && reqAmount != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: request.entryType == 'cash'
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          request.entryType == 'cash'
                              ? Icons.attach_money
                              : Icons.credit_card_rounded,
                          size: 13,
                          color: request.entryType == 'cash'
                              ? AppColors.success
                              : AppColors.accent,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          request.entryType == 'cash' ? 'Cash' : 'Card',
                          style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: request.entryType == 'cash'
                                  ? AppColors.success
                                  : AppColors.accent),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _StatusBadge(status: request.status),
                ],
              ),
              const SizedBox(height: 10),
              // Amount change
              if (hasAmountChange)
                Row(
                  children: [
                    Text(
                      _formatAmount(origAmount),
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          decoration: TextDecoration.lineThrough),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 14, color: Colors.grey),
                    ),
                    Text(
                      _formatAmount(reqAmount),
                      style: GoogleFonts.poppins(
                          fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                )
              else
                Text(
                  'Notes update requested',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
              const SizedBox(height: 6),
              Text(
                request.reason,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 6),
              Text(
                Formatters.dateTime(request.createdAt),
                style: GoogleFonts.inter(
                    fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _EditRequestDetailSheet(
        request: request,
        onCancelled: () {
          Navigator.pop(context);
          onCancelled();
        },
      ),
    );
  }
}

// -------------------------------------------------------
// Detail bottom sheet
// -------------------------------------------------------
class _EditRequestDetailSheet extends StatelessWidget {
  final EditRequest request;
  final VoidCallback onCancelled;
  const _EditRequestDetailSheet(
      {required this.request, required this.onCancelled});

  String _fmt(dynamic v) {
    if (v == null) return '—';
    final d = double.tryParse(v.toString());
    if (d != null) return Formatters.currency(d);
    return v.toString();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, sc) => SingleChildScrollView(
        controller: sc,
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Text('Edit Request',
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                const Spacer(),
                _StatusBadge(status: request.status),
              ],
            ),
            const SizedBox(height: 16),
            _Section(
              title: 'Original Values',
              color: Colors.grey.shade100,
              borderColor: Colors.grey.shade300,
              children: request.originalValues.entries
                  .map((e) =>
                      _KVRow(label: _friendlyKey(e.key), value: _fmt(e.value)))
                  .toList(),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Requested Changes',
              color: AppColors.primary.withValues(alpha: 0.05),
              borderColor: AppColors.primary.withValues(alpha: 0.2),
              children: request.requestedChanges.entries
                  .map((e) => _KVRow(
                      label: _friendlyKey(e.key),
                      value: _fmt(e.value),
                      highlight: true))
                  .toList(),
            ),
            const SizedBox(height: 12),
            _Section(
              title: 'Reason',
              color: Colors.amber.withValues(alpha: 0.08),
              borderColor: Colors.amber.withValues(alpha: 0.3),
              children: [
                Text(request.reason,
                    style: GoogleFonts.inter(fontSize: 13, height: 1.5))
              ],
            ),
            if (request.adminRemarks != null) ...[
              const SizedBox(height: 12),
              _Section(
                title: 'Admin Remarks',
                color: request.status == 'approved'
                    ? AppColors.success.withValues(alpha: 0.08)
                    : AppColors.error.withValues(alpha: 0.08),
                borderColor: request.status == 'approved'
                    ? AppColors.success.withValues(alpha: 0.3)
                    : AppColors.error.withValues(alpha: 0.3),
                children: [
                  Text(request.adminRemarks!,
                      style: GoogleFonts.inter(fontSize: 13, height: 1.5)),
                  if (request.reviewerName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                          '— ${request.reviewerName!}${request.reviewedAt != null ? ', ${Formatters.dateTime(request.reviewedAt!)}' : ''}',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.grey.shade600)),
                    ),
                ],
              ),
            ],
            if (request.status == 'pending') ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text('Cancel Request',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  onPressed: () => _confirmCancel(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _friendlyKey(String k) {
    switch (k) {
      case 'cash_amount':
        return 'Amount';
      case 'amount':
        return 'Amount';
      case 'notes':
        return 'Notes';
      default:
        return k;
    }
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text(
            'Are you sure you want to cancel this edit request? The original entry will remain unchanged.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Keep It')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context
                    .read<EditRequestProvider>()
                    .cancelRequest(request.id);
                onCancelled();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: AppColors.error));
                }
              }
            },
            child: const Text('Cancel Request',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Color color;
  final Color borderColor;
  final List<Widget> children;
  const _Section({
    required this.title,
    required this.color,
    required this.borderColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600)),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }
}

class _KVRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  const _KVRow(
      {required this.label, required this.value, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.grey.shade500)),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                  color: highlight ? AppColors.primary : null),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------
// Reusable status badge (exported for use in admin screen)
// -------------------------------------------------------
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'approved':
        bg = const Color(0xFF4CAF50).withValues(alpha: 0.12);
        fg = const Color(0xFF4CAF50);
        label = 'Approved';
        break;
      case 'rejected':
        bg = const Color(0xFFEF5363).withValues(alpha: 0.12);
        fg = const Color(0xFFEF5363);
        label = 'Rejected';
        break;
      default:
        bg = const Color(0xFFFFC107).withValues(alpha: 0.18);
        fg = const Color(0xFF996600);
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
