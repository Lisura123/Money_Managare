import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/edit_request.dart';
import '../../providers/edit_request_provider.dart';
import '../../providers/showroom_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import 'review_edit_request_screen.dart';

class AdminEditRequestsScreen extends StatefulWidget {
  const AdminEditRequestsScreen({super.key});

  @override
  State<AdminEditRequestsScreen> createState() =>
      _AdminEditRequestsScreenState();
}

class _AdminEditRequestsScreenState extends State<AdminEditRequestsScreen> {
  final _scrollController = ScrollController();
  String _statusFilter = 'pending';
  int? _showroomFilter;
  String? _typeFilter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ShowroomProvider>().fetchShowrooms();
      _reload();
    });
    _scrollController.addListener(_onScroll);
  }

  void _reload() {
    context.read<EditRequestProvider>().fetchAllRequests(
          refresh: true,
          status: _statusFilter.isEmpty ? null : _statusFilter,
          showroomId: _showroomFilter,
          entryType: _typeFilter,
        );
  }

  void _onScroll() {
    final p = context.read<EditRequestProvider>();
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        p.allHasMore &&
        !p.allLoading) {
      p.fetchAllRequests(
        status: _statusFilter.isEmpty ? null : _statusFilter,
        showroomId: _showroomFilter,
        entryType: _typeFilter,
      );
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
      appBar: AppBar(
        title: const Text('Edit Requests'),
        actions: [
          if (provider.pendingCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Chip(
                label: Text('${provider.pendingCount} pending',
                    style:
                        GoogleFonts.inter(fontSize: 11, color: Colors.white)),
                backgroundColor: const Color(0xFFFFC107),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _FilterBar(
            statusFilter: _statusFilter,
            showroomFilter: _showroomFilter,
            typeFilter: _typeFilter,
            onStatusChanged: (v) {
              setState(() => _statusFilter = v);
              _reload();
            },
            onShowroomChanged: (v) {
              setState(() => _showroomFilter = v);
              _reload();
            },
            onTypeChanged: (v) {
              setState(() => _typeFilter = v);
              _reload();
            },
          ),
          Expanded(
            child: Builder(builder: (ctx) {
              if (provider.allLoading && provider.allRequests.isEmpty) {
                return const ShimmerLoading(itemCount: 5);
              }
              if (provider.allError != null && provider.allRequests.isEmpty) {
                return ErrorState(
                    message: provider.allError!, onRetry: _reload);
              }
              if (provider.allRequests.isEmpty) {
                return const EmptyState(
                    icon: Icons.edit_note_outlined,
                    title: 'No edit requests found');
              }
              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.allRequests.length +
                      (provider.allHasMore ? 1 : 0),
                  itemBuilder: (ctx, i) {
                    if (i == provider.allRequests.length) {
                      return const Center(
                          child: Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator()));
                    }
                    final req = provider.allRequests[i];
                    return _AdminRequestCard(
                      request: req,
                      onReviewed: _reload,
                    );
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------
// Filter bar
// -------------------------------------------------------
class _FilterBar extends StatelessWidget {
  final String statusFilter;
  final int? showroomFilter;
  final String? typeFilter;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<int?> onShowroomChanged;
  final ValueChanged<String?> onTypeChanged;

  const _FilterBar({
    required this.statusFilter,
    required this.showroomFilter,
    required this.typeFilter,
    required this.onStatusChanged,
    required this.onShowroomChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
                label: 'Pending',
                selected: statusFilter == 'pending',
                color: const Color(0xFFFFC107),
                onTap: () => onStatusChanged('pending')),
            const SizedBox(width: 6),
            _FilterChip(
                label: 'Approved',
                selected: statusFilter == 'approved',
                color: AppColors.success,
                onTap: () => onStatusChanged('approved')),
            const SizedBox(width: 6),
            _FilterChip(
                label: 'Rejected',
                selected: statusFilter == 'rejected',
                color: AppColors.error,
                onTap: () => onStatusChanged('rejected')),
            const SizedBox(width: 6),
            _FilterChip(
                label: 'All',
                selected: statusFilter.isEmpty,
                color: Colors.grey,
                onTap: () => onStatusChanged('')),
            const SizedBox(width: 12),
            _FilterChip(
                label: 'Cash',
                selected: typeFilter == 'cash',
                color: AppColors.success,
                onTap: () =>
                    onTypeChanged(typeFilter == 'cash' ? null : 'cash')),
            const SizedBox(width: 6),
            _FilterChip(
                label: 'Card',
                selected: typeFilter == 'card',
                color: AppColors.accent,
                onTap: () =>
                    onTypeChanged(typeFilter == 'card' ? null : 'card')),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : color,
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------
// Admin request card
// -------------------------------------------------------
class _AdminRequestCard extends StatelessWidget {
  final EditRequest request;
  final VoidCallback onReviewed;
  const _AdminRequestCard({required this.request, required this.onReviewed});

  String _fmt(dynamic v) {
    if (v == null) return '—';
    final d = double.tryParse(v.toString());
    if (d != null) return Formatters.currency(d);
    return v.toString();
  }

  String _amountKey() => request.entryType == 'cash' ? 'cash_amount' : 'amount';

  @override
  Widget build(BuildContext context) {
    final origAmount = request.originalValues[_amountKey()];
    final reqAmount = request.requestedChanges[_amountKey()];
    final hasAmountChange = origAmount != null && reqAmount != null;
    double diff = 0;
    if (hasAmountChange) {
      diff = (double.tryParse(reqAmount.toString()) ?? 0) -
          (double.tryParse(origAmount.toString()) ?? 0);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: request.status == 'pending'
            ? () async {
                final result = await Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) =>
                            ReviewEditRequestScreen(request: request)));
                if (result == true) onReviewed();
              }
            : () => _showReadOnly(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Staff + showroom
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.staffName ?? '—',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          request.showroomName ?? '—',
                          style: GoogleFonts.inter(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  _AdminStatusBadge(status: request.status),
                ],
              ),
              const SizedBox(height: 10),
              // Type badge + amount diff
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: request.entryType == 'cash'
                          ? AppColors.success.withValues(alpha: 0.12)
                          : AppColors.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      request.entryType == 'cash' ? 'Cash' : 'Card',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: request.entryType == 'cash'
                              ? AppColors.success
                              : AppColors.accent),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (hasAmountChange) ...[
                    Text(
                      _fmt(origAmount),
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          decoration: TextDecoration.lineThrough),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 13, color: Colors.grey),
                    ),
                    Text(
                      _fmt(reqAmount),
                      style: GoogleFonts.poppins(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      diff >= 0
                          ? '+${Formatters.currency(diff)}'
                          : Formatters.currency(diff),
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color:
                              diff >= 0 ? AppColors.success : AppColors.error),
                    ),
                  ] else
                    Text('Notes update',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                request.reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
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

  void _showReadOnly(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ReadOnlyDetailSheet(request: request),
    );
  }
}

// -------------------------------------------------------
// Read-only detail for reviewed requests
// -------------------------------------------------------
class _ReadOnlyDetailSheet extends StatelessWidget {
  final EditRequest request;
  const _ReadOnlyDetailSheet({required this.request});

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
      initialChildSize: 0.7,
      maxChildSize: 0.92,
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
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Expanded(
                    child: Text('Edit Request',
                        style: GoogleFonts.poppins(
                            fontSize: 16, fontWeight: FontWeight.w700))),
                _AdminStatusBadge(status: request.status),
              ],
            ),
            const SizedBox(height: 4),
            Text('${request.staffName ?? ''} · ${request.showroomName ?? ''}',
                style: GoogleFonts.inter(
                    fontSize: 12, color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            _DetailSection(
                title: 'Original', entries: request.originalValues, fmt: _fmt),
            const SizedBox(height: 10),
            _DetailSection(
                title: 'Requested Changes',
                entries: request.requestedChanges,
                fmt: _fmt,
                highlight: true),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reason',
                      style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600)),
                  const SizedBox(height: 6),
                  Text(request.reason,
                      style: GoogleFonts.inter(fontSize: 13, height: 1.5)),
                ],
              ),
            ),
            if (request.adminRemarks != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: request.status == 'approved'
                        ? AppColors.success.withValues(alpha: 0.08)
                        : AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: request.status == 'approved'
                            ? AppColors.success.withValues(alpha: 0.3)
                            : AppColors.error.withValues(alpha: 0.3))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Admin Remarks',
                        style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600)),
                    const SizedBox(height: 6),
                    Text(request.adminRemarks!,
                        style: GoogleFonts.inter(fontSize: 13, height: 1.5)),
                    if (request.reviewerName != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('— ${request.reviewerName!}',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: Colors.grey.shade600)),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String title;
  final Map<String, dynamic> entries;
  final String Function(dynamic) fmt;
  final bool highlight;
  const _DetailSection(
      {required this.title,
      required this.entries,
      required this.fmt,
      this.highlight = false});

  String _friendly(String k) {
    switch (k) {
      case 'cash_amount':
      case 'amount':
        return 'Amount';
      case 'notes':
        return 'Notes';
      default:
        return k;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.primary.withValues(alpha: 0.05)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: highlight
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.grey.shade300),
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
          ...entries.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                        width: 70,
                        child: Text(_friendly(e.key),
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.grey.shade500))),
                    Expanded(
                        child: Text(fmt(e.value),
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: highlight
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: highlight ? AppColors.primary : null))),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _AdminStatusBadge extends StatelessWidget {
  final String status;
  const _AdminStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg, fg;
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
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          style: GoogleFonts.inter(
              fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
