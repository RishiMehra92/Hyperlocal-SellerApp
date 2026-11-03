import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';

import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_network_image.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';

import '../bloc/watch_and_buy_bloc.dart';
import '../bloc/watch_and_buy_event.dart';
import '../bloc/watch_and_buy_state.dart';
import '../model/watch_and_buy_reel_model.dart';
import 'watch_and_buy_reels_viewer_page.dart';
import 'widgets/watch_and_buy_video_thumbnail.dart';
import 'widgets/create_reel_bottom_sheet.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';

class WatchAndBuyReelsPage extends StatefulWidget {
  const WatchAndBuyReelsPage({super.key});

  @override
  State<WatchAndBuyReelsPage> createState() => _WatchAndBuyReelsPageState();
}

class _WatchAndBuyReelsPageState extends State<WatchAndBuyReelsPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<WatchAndBuyBloc>().add(FetchWatchAndBuyReelsEvent());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      context.read<WatchAndBuyBloc>().add(LoadMoreWatchAndBuyReelsEvent());
    }
  }

  void _openReelViewer(BuildContext context, List<WatchAndBuyReelModel> reels, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WatchAndBuyReelsViewerPage(reels: reels, initialIndex: initialIndex),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenType = context.screenType;

    return CustomScaffold(
      title: l10n?.tr('reelsTab') ?? 'Reels',
      showAppbar: true,
      centerTitle: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!DemoGuard.shouldProceed(context)) return;
          if (!PermissionChecker.hasPermission(AppPermissions.watchBuyReelCreate)) {
            showCustomSnackbar(
              context: context,
              message: l10n?.tr('noPermissionError') ?? 'You do not have permission to perform this action',
              isError: true,
            );
            return;
          }
          showCreateReelBottomSheet(context);
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<WatchAndBuyBloc, WatchAndBuyState>(
            listenWhen: (previous, current) => previous.deleteReelStatus != current.deleteReelStatus,
            listener: (context, state) {
              if (state.deleteReelStatus == ApiStatus.success) {
                showCustomSnackbar(context: context, message: state.deleteReelMessage ?? 'Reel deleted successfully');
              } else if (state.deleteReelStatus == ApiStatus.failure) {
                showCustomSnackbar(
                  context: context,
                  message: state.deleteReelMessage ?? 'Failed to delete reel',
                  isError: true,
                );
              }
            },
          ),
          BlocListener<WatchAndBuyBloc, WatchAndBuyState>(
            listenWhen: (previous, current) => previous.publishReelStatus != current.publishReelStatus,
            listener: (context, state) {
              if (state.publishReelStatus == ApiStatus.success) {
                showCustomSnackbar(context: context, message: state.publishReelMessage ?? 'Reel updated successfully');
              } else if (state.publishReelStatus == ApiStatus.failure) {
                showCustomSnackbar(
                  context: context,
                  message: state.publishReelMessage ?? 'Failed to update reel',
                  isError: true,
                );
              }
            },
          ),
        ],
        child: BlocBuilder<WatchAndBuyBloc, WatchAndBuyState>(
          builder: (context, state) {
            if (state.reelsStatus == ApiStatus.loading) {
              return const Center(child: CustomLoadingIndicator());
            }

            if (state.reelsStatus == ApiStatus.failure && state.reels.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        state.reelsErrorMessage ?? 'Failed to load reels',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        text: l10n?.tr('retry') ?? 'Retry',
                        width: 140,
                        onPressed: () {
                          context.read<WatchAndBuyBloc>().add(FetchWatchAndBuyReelsEvent());
                        },
                      ),
                    ],
                  ),
                ),
              );
            }

            if (state.reels.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.video_library_rounded, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      l10n?.tr('noReelsFound') ?? 'No reels available yet',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: () async {
                context.read<WatchAndBuyBloc>().add(FetchWatchAndBuyReelsEvent());
              },
              child: GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                controller: _scrollController,
                padding: UIUtils.pagePadding(screenType).copyWith(bottom: 100),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.55,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                ),
                itemCount: state.reels.length + (state.isReelsLoadingMore ? 2 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.reels.length) {
                    return const Center(
                      child: Padding(padding: EdgeInsets.all(8.0), child: CustomLoadingIndicator()),
                    );
                  }

                  final reel = state.reels[index];
                  return _buildReelCard(context, reel, index, state.reels, isDark);
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildReelCard(
    BuildContext context,
    WatchAndBuyReelModel reel,
    int index,
    List<WatchAndBuyReelModel> reels,
    bool isDark,
  ) {
    final l10n = context;
    return GestureDetector(
      onTap: () => _openReelViewer(context, reels, index),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.mainDarkContainerBgColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Cover Image or First Frame of Video
              (reel.coverUrl != null && reel.coverUrl!.isNotEmpty)
                  ? CustomNetworkImage(
                      imageUrl: reel.coverUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : WatchAndBuyVideoThumbnailWidget(videoUrl: reel.videoUrl),

              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),

              // Top Badges
              Positioned(
                top: 10,
                left: 10,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.play_arrow_rounded, size: 13, color: Colors.white),
                          if (reel.products.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text(
                              '${reel.products.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.shopping_bag_outlined, size: 12, color: Colors.white),
                          ],
                        ],
                      ),
                    ),
                    if (reel.status == 'unpublished') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600.withValues(alpha: 0.95),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.visibility_off_rounded, size: 11, color: Colors.white),
                            const SizedBox(width: 3),
                            Text(
                              l10n?.tr('unpublish') ?? 'Unpublished',
                              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Action Menu
              Positioned(
                top: 0,
                right: 0,
                child: PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black87, blurRadius: 4)],
                  ),
                  color: isDark ? AppColors.mainDarkContainerBgColor : Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (!DemoGuard.shouldProceed(context)) return;

                    final bloc = context.read<WatchAndBuyBloc>();
                    if (value == 'edit') {
                      if (!PermissionChecker.hasPermission(AppPermissions.watchBuyReelEdit)) {
                        showCustomSnackbar(
                          context: context,
                          message: l10n?.tr('noPermissionError') ?? 'You do not have permission to perform this action',
                          isError: true,
                        );
                        return;
                      }
                      showCreateReelBottomSheet(context, existingReel: reel);
                    } else if (value == 'publish') {
                      if (!PermissionChecker.hasPermission(AppPermissions.watchBuyReelPublish)) {
                        showCustomSnackbar(
                          context: context,
                          message: l10n?.tr('noPermissionError') ?? 'You do not have permission to perform this action',
                          isError: true,
                        );
                        return;
                      }
                      bloc.add(PublishWatchAndBuyReelEvent(id: reel.id, published: true));
                    } else if (value == 'unpublish') {
                      if (!PermissionChecker.hasPermission(AppPermissions.watchBuyReelPublish)) {
                        showCustomSnackbar(
                          context: context,
                          message: l10n?.tr('noPermissionError') ?? 'You do not have permission to perform this action',
                          isError: true,
                        );
                        return;
                      }
                      bloc.add(PublishWatchAndBuyReelEvent(id: reel.id, published: false));
                    } else if (value == 'delete') {
                      if (!PermissionChecker.hasPermission(AppPermissions.watchBuyReelDelete)) {
                        showCustomSnackbar(
                          context: context,
                          message: l10n?.tr('noPermissionError') ?? 'You do not have permission to perform this action',
                          isError: true,
                        );
                        return;
                      }
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: Text(l10n?.tr('deleteReel') ?? 'Delete Reel'),
                          content: Text(l10n?.tr('deleteReelConfirmation') ?? 'Are you sure you want to delete this reel?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n?.tr('cancel') ?? 'Cancel')),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                bloc.add(DeleteWatchAndBuyReelEvent(id: reel.id));
                              },
                              child: Text(l10n?.tr('delete') ?? 'Delete', style: const TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) {
                    final isPublished = reel.status.toLowerCase() == 'published';
                    final localL10n = context;
                    return [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 20),
                            const SizedBox(width: 12),
                            Text(localL10n?.tr('edit') ?? 'Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: isPublished ? 'unpublish' : 'publish',
                        child: Row(
                          children: [
                            Icon(isPublished ? Icons.visibility_off : Icons.visibility, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              isPublished ? (localL10n?.tr('unpublish') ?? 'Unpublish') : (localL10n?.tr('publish') ?? 'Publish'),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 12),
                            Text(localL10n?.tr('delete') ?? 'Delete', style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ),

              // Bottom Reel Text
              if (reel.caption != null && reel.caption!.isNotEmpty)
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: Text(
                    reel.caption!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(blurRadius: 4, color: Colors.black87)],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
