import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../providers/showroom_provider.dart';
import '../../widgets/common/shimmer_loading.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/error_state.dart';
import '../../widgets/admin/showroom_summary_card.dart';

class ShowroomListScreen extends StatefulWidget {
  const ShowroomListScreen({super.key});

  @override
  State<ShowroomListScreen> createState() => _ShowroomListScreenState();
}

class _ShowroomListScreenState extends State<ShowroomListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => context.read<ShowroomProvider>().fetchShowrooms());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShowroomProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Showrooms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result =
                  await Navigator.of(context).pushNamed(AppRoutes.showroomForm);
              if (result == true && context.mounted) {
                context.read<ShowroomProvider>().fetchShowrooms();
              }
            },
          ),
        ],
      ),
      body: () {
        if (provider.isLoading && provider.showrooms.isEmpty) {
          return const ShimmerLoading(itemCount: 5);
        }
        if (provider.error != null && provider.showrooms.isEmpty) {
          return ErrorState(
              message: provider.error!,
              onRetry: () => context.read<ShowroomProvider>().fetchShowrooms());
        }
        if (provider.showrooms.isEmpty) {
          return EmptyState(
            icon: Icons.storefront_outlined,
            title: 'No showrooms yet',
            actionLabel: 'Add Showroom',
            onAction: () =>
                Navigator.of(context).pushNamed(AppRoutes.showroomForm),
          );
        }
        return RefreshIndicator(
          onRefresh: () => context.read<ShowroomProvider>().fetchShowrooms(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.showrooms.length,
            itemBuilder: (ctx, i) {
              final s = provider.showrooms[i];
              return ShowroomSummaryCard(
                showroom: s,
                onTap: () => Navigator.of(context)
                    .pushNamed(AppRoutes.showroomDetail, arguments: s),
              );
            },
          ),
        );
      }(),
    );
  }
}
