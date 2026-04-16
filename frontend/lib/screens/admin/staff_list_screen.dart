import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/staff_provider.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import 'package:google_fonts/google_fonts.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<StaffProvider>().fetchStaff());
  }

  Future<void> _sendResetEmail(
      int staffId, String staffEmail, String staffName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Reset Email'),
        content: Text('Send a password reset email to $staffName?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Send')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<StaffProvider>().sendResetEmail(staffId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Reset email sent to $staffEmail.'),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Failed to send email. Try again later.'),
            backgroundColor: AppColors.error));
      }
    }
  }

  Future<void> _delete(int staffId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Staff'),
        content: const Text('Are you sure? This cannot be undone.'),
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
      await context.read<StaffProvider>().deleteStaff(staffId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Staff deleted'),
            backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StaffProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            onPressed: () async {
              final result =
                  await Navigator.of(context).pushNamed(AppRoutes.staffForm);
              if (result == true && mounted) {
                context.read<StaffProvider>().fetchStaff();
              }
            },
          ),
        ],
      ),
      body: () {
        if (provider.isLoading && provider.staff.isEmpty) {
          return const ShimmerLoading(itemCount: 6);
        }
        if (provider.error != null && provider.staff.isEmpty) {
          return ErrorState(
              message: provider.error!,
              onRetry: () => context.read<StaffProvider>().fetchStaff());
        }
        if (provider.staff.isEmpty) {
          return EmptyState(
              icon: Icons.people_outline,
              title: 'No staff yet',
              actionLabel: 'Add Staff',
              onAction: () =>
                  Navigator.of(context).pushNamed(AppRoutes.staffForm));
        }
        return RefreshIndicator(
          onRefresh: () => context.read<StaffProvider>().fetchStaff(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.staff.length,
            itemBuilder: (ctx, i) {
              final staff = provider.staff[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(staff.initials,
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            fontSize: 14)),
                  ),
                  title: Text(staff.name,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(staff.email, style: GoogleFonts.inter(fontSize: 12)),
                      if (staff.showroomName != null)
                        Text(staff.showroomName!,
                            style: GoogleFonts.inter(
                                fontSize: 11, color: Colors.grey.shade600)),
                    ],
                  ),
                  isThreeLine: staff.showroomName != null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.lock_reset_outlined,
                            size: 18, color: AppColors.accent),
                        tooltip: 'Send Reset Email',
                        onPressed: () =>
                            _sendResetEmail(staff.id, staff.email, staff.name),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: () async {
                          final result = await Navigator.of(context)
                              .pushNamed(AppRoutes.staffForm, arguments: staff);
                          if (result == true && mounted) {
                            context.read<StaffProvider>().fetchStaff();
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.error, size: 18),
                        onPressed: () => _delete(staff.id),
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
