import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local_seller/config/colors.dart';
import 'package:hyper_local_seller/config/hive_storage.dart';
import 'package:hyper_local_seller/service/api_base_helper.dart';
import 'package:hyper_local_seller/service/demo_guard.dart';
import 'package:hyper_local_seller/utils/image_picker_utils.dart';
import 'package:hyper_local_seller/utils/ui_utils.dart';
import 'package:hyper_local_seller/widgets/custom/custom_alert_dialog.dart';
import 'package:hyper_local_seller/widgets/custom/custom_buttons.dart';
import 'package:hyper_local_seller/widgets/custom/custom_loading_indicator.dart';
import 'package:hyper_local_seller/widgets/custom/custom_network_image.dart';
import 'package:hyper_local_seller/widgets/custom/custom_scaffold.dart';
import 'package:hyper_local_seller/widgets/custom/custom_snackbar.dart';
import 'widgets/watch_and_buy_video_thumbnail.dart';
import 'package:hyper_local_seller/widgets/custom/custom_textfield.dart';
import 'package:hyper_local_seller/screen/products_page/product_addons/create_product_addons/models/lookup_models.dart';
import 'widgets/watch_and_buy_product_selection_field.dart';
import '../bloc/watch_and_buy_bloc.dart';
import '../bloc/watch_and_buy_event.dart';
import '../bloc/watch_and_buy_state.dart';
import '../model/watch_and_buy_story_model.dart';
import 'watch_and_buy_story_viewer_page.dart';
import 'package:hyper_local_seller/utils/permission_checker.dart';
import 'package:hyper_local_seller/config/app_permissions.dart';

class WatchAndBuyStoriesPage extends StatefulWidget {
  const WatchAndBuyStoriesPage({super.key});

  @override
  State<WatchAndBuyStoriesPage> createState() => _WatchAndBuyStoriesPageState();
}

class _WatchAndBuyStoriesPageState extends State<WatchAndBuyStoriesPage> {
  @override
  void initState() {
    super.initState();
    context.read<WatchAndBuyBloc>().add(FetchWatchAndBuyStoriesEvent());
  }

  void _confirmDeleteStory(BuildContext context, int storyId) {
    if (!DemoGuard.shouldProceed(context)) return;

    final l10n = context;

    if (!PermissionChecker.hasPermission(AppPermissions.watchBuyStatusDelete)) {
      showCustomSnackbar(
        context: context,
        message:
            l10n?.tr('noPermissionError') ??
            'You do not have permission to perform this action',
        isError: true,
      );
      return;
    }

    showAppAlertDialog(
      context: context,
      title: l10n?.tr('deleteStory') ?? 'Delete Story',
      message:
          l10n?.tr('deleteStoryConfirmation') ??
          'Are you sure you want to delete this story? This action cannot be undone.',
      icon: Icons.delete_outline_rounded,
      iconColor: Colors.red,
      confirmText: l10n?.tr('delete') ?? 'Delete',
      cancelText: l10n?.tr('cancel') ?? 'Cancel',
      isDestructive: true,
      onConfirm: () {
        context.read<WatchAndBuyBloc>().add(
          DeleteWatchAndBuyStoryEvent(id: storyId),
        );
      },
    );
  }

  void _openStoryViewer(
    BuildContext context,
    List<WatchAndBuyStoryModel> stories,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WatchAndBuyStoryViewerPage(
          stories: stories,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  String _formatExpiryTime(BuildContext context, WatchAndBuyStoryModel story) {
    final l10n = context;
    DateTime? expireTime;

    if (story.expiresAt != null && story.expiresAt!.isNotEmpty) {
      try {
        expireTime = DateTime.parse(story.expiresAt!);
      } catch (_) {}
    }

    if (expireTime == null &&
        story.createdAt != null &&
        story.createdAt!.isNotEmpty) {
      try {
        expireTime = DateTime.parse(
          story.createdAt!,
        ).add(const Duration(hours: 24));
      } catch (_) {}
    }

    if (expireTime == null) return '';

    final diff = expireTime.difference(DateTime.now());
    if (diff.isNegative || diff.inSeconds <= 0) {
      return l10n?.tr('expired') ?? 'Expired';
    } else if (diff.inHours >= 1) {
      return l10n?.tr('hoursLeft', positionalArgs: [diff.inHours]) ?? '${diff.inHours}h left';
    } else if (diff.inMinutes >= 1) {
      return l10n?.tr('minutesLeft', positionalArgs: [diff.inMinutes]) ?? '${diff.inMinutes}m left';
    } else {
      return l10n?.tr('secondsLeft', positionalArgs: [diff.inSeconds]) ?? '${diff.inSeconds}s left';
    }
  }

  bool _isStoryExpired(WatchAndBuyStoryModel story) {
    DateTime? expireTime;
    if (story.expiresAt != null && story.expiresAt!.isNotEmpty) {
      try {
        expireTime = DateTime.parse(story.expiresAt!);
      } catch (_) {}
    }
    if (expireTime == null &&
        story.createdAt != null &&
        story.createdAt!.isNotEmpty) {
      try {
        expireTime = DateTime.parse(
          story.createdAt!,
        ).add(const Duration(hours: 24));
      } catch (_) {}
    }
    if (expireTime == null) return false;
    return expireTime.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenType = context.screenType;

    return CustomScaffold(
      title: l10n?.tr('storiesTab') ?? 'Stories',
      showAppbar: true,
      centerTitle: true,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (!DemoGuard.shouldProceed(context)) return;
          if (!PermissionChecker.hasPermission(
            AppPermissions.watchBuyStatusCreate,
          )) {
            showCustomSnackbar(
              context: context,
              message:
                  l10n?.tr('noPermissionError') ??
                  'You do not have permission to perform this action',
              isError: true,
            );
            return;
          }
          _showCreateStoryBottomSheet(context);
        },
        backgroundColor: AppColors.primaryColor,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: BlocConsumer<WatchAndBuyBloc, WatchAndBuyState>(
        listenWhen: (previous, current) =>
            previous.deleteStoryStatus != current.deleteStoryStatus,
        listener: (context, state) {
          if (state.deleteStoryStatus == ApiStatus.success) {
            showCustomSnackbar(
              context: context,
              message:
                  state.deleteStoryMessage ??
                  (l10n?.tr('storyDeletedSuccessfully') ??
                      'Story deleted successfully'),
            );
          } else if (state.deleteStoryStatus == ApiStatus.failure) {
            showCustomSnackbar(
              context: context,
              message:
                  state.deleteStoryMessage ??
                  (l10n?.tr('failedToDeleteStory') ?? 'Failed to delete story'),
              isError: true,
            );
          }
        },
        builder: (context, state) {
          if (state.storiesStatus == ApiStatus.loading) {
            return const Center(child: CustomLoadingIndicator());
          }

          if (state.storiesStatus == ApiStatus.failure) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      state.storiesErrorMessage ??
                          (l10n?.tr('failedToLoadStories') ??
                              'Failed to load stories'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: l10n?.tr('retry') ?? 'Retry',
                      width: 140,
                      onPressed: () {
                        context.read<WatchAndBuyBloc>().add(
                          FetchWatchAndBuyStoriesEvent(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          }

          if (state.stories.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.amp_stories_rounded,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n?.tr('noStoriesFound') ?? 'No stories available yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primaryColor,
            onRefresh: () async {
              context.read<WatchAndBuyBloc>().add(
                FetchWatchAndBuyStoriesEvent(),
              );
            },
            child: GridView.builder(
              padding: UIUtils.pagePadding(screenType),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: state.stories.length,
              itemBuilder: (context, index) {
                final story = state.stories[index];
                return _buildStoryCard(
                  context,
                  story,
                  index,
                  state.stories,
                  isDark,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStoryCard(
    BuildContext context,
    WatchAndBuyStoryModel story,
    int index,
    List<WatchAndBuyStoryModel> stories,
    bool isDark,
  ) {
    final expiryText = _formatExpiryTime(context, story);
    final isExpired = _isStoryExpired(story);

    return GestureDetector(
      onTap: () => _openStoryViewer(context, stories, index),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.mainDarkContainerBgColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Media Preview
              story.isVideo
                  ? WatchAndBuyVideoThumbnailWidget(videoUrl: story.mediaUrl)
                  : CustomNetworkImage(
                      imageUrl: story.mediaUrl,
                      fit: BoxFit.cover,
                    ),

              // Gradient Overlay for Text readability
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

              // Top Badges (Content Type / Products Count & Expiry Countdown)
              Positioned(
                top: 10,
                left: 10,
                right: 44,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                story.isVideo ? Icons.videocam : Icons.image,
                                size: 13,
                                color: Colors.white,
                              ),
                              if (story.products.isNotEmpty) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '${story.products.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 12,
                                  color: Colors.white,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (expiryText.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? Colors.red.withValues(alpha: 0.8)
                              : Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              expiryText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Top Right Delete Button
              Positioned(
                top: 8,
                right: 8,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _confirmDeleteStory(context, story.id),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Story Text
              if (story.text != null && story.text!.isNotEmpty)
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: Text(
                    story.text!,
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

void _showCreateStoryBottomSheet(BuildContext context) {
  final bloc = context.read<WatchAndBuyBloc>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        BlocProvider.value(value: bloc, child: const _CreateStoryBottomSheet()),
  );
}

class _CreateStoryBottomSheet extends StatefulWidget {
  const _CreateStoryBottomSheet();

  @override
  State<_CreateStoryBottomSheet> createState() =>
      _CreateStoryBottomSheetState();
}

class _CreateStoryBottomSheetState extends State<_CreateStoryBottomSheet> {
  String? _mediaPath;
  MediaType? _mediaType;
  final TextEditingController _textController = TextEditingController();
  List<ProductLookup> _selectedProducts = [];

  Future<void> _pickImage() async {
    final maxUploadMb = HiveStorage.watchAndBuyMaxUploadMb;
    final path = await ImagePickerUtils.pickMedia(
      context,
      mediaType: MediaType.image,
      maxSizeMb: maxUploadMb.toDouble(),
    );
    if (path != null) {
      setState(() {
        _mediaPath = path;
        _mediaType = MediaType.image;
      });
    }
  }

  Future<void> _pickVideo() async {
    final maxUploadMb = HiveStorage.watchAndBuyMaxUploadMb;
    final maxDuration = HiveStorage.watchAndBuyMaxDurationSeconds;
    final path = await ImagePickerUtils.pickMedia(
      context,
      mediaType: MediaType.video,
      maxSizeMb: maxUploadMb.toDouble(),
      maxVideoDuration: Duration(seconds: maxDuration),
    );
    if (path != null) {
      setState(() {
        _mediaPath = path;
        _mediaType = MediaType.video;
      });
    }
  }

  void _submit() {
    if (_mediaPath == null) return;
    context.read<WatchAndBuyBloc>().add(
      CreateWatchAndBuyStoryEvent(
        media: File(_mediaPath!),
        text: _textController.text.trim().isEmpty
            ? null
            : _textController.text.trim(),
        attachmentIds: _selectedProducts.isEmpty
            ? null
            : _selectedProducts.map((p) => p.id).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = context;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.mainDarkContainerBgColor : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n?.tr('createStory') ?? 'Create Story',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CustomTextField(
                controller: _textController,
                label: l10n?.tr('titleLabel') ?? 'Title',
                hint: l10n?.tr('enterTitleOptional') ?? 'Enter title (optional)',
                maxLength: 100,
                maxLines: 1,
              ),
              const SizedBox(height: 20),
              if (_mediaPath == null)
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.image_outlined,
                                size: 32,
                                color: AppColors.primaryColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n?.tr('uploadImage') ?? 'Upload Image',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: _pickVideo,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? Colors.white24 : Colors.black12,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.videocam_outlined,
                                size: 32,
                                color: AppColors.primaryColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                l10n?.tr('uploadVideo') ?? 'Upload Video',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black12,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_mediaType == MediaType.image)
                          Image.file(File(_mediaPath!), fit: BoxFit.cover)
                        else
                          Container(
                            color: Colors.black87,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.play_circle_outline,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    l10n?.tr('videoSelected') ?? 'Video Selected',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _mediaPath = null;
                                _mediaType = null;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              WatchAndBuyProductSelectionField(
                isRequired: false,
                maxProducts: 5,
                preloadEligibleProducts: false,
                selectedProducts: _selectedProducts,
                onChanged: (products) {
                  setState(() {
                    _selectedProducts = products;
                  });
                },
              ),
              const SizedBox(height: 24),
              BlocConsumer<WatchAndBuyBloc, WatchAndBuyState>(
                listenWhen: (prev, curr) =>
                    prev.createStoryStatus != curr.createStoryStatus,
                listener: (context, state) {
                  if (state.createStoryStatus == ApiStatus.success) {
                    Navigator.of(context).pop();
                    showCustomSnackbar(
                      context: context,
                      message:
                          state.createStoryMessage ??
                          (l10n?.tr('storyUploadedSuccessfully') ??
                              'Story uploaded successfully'),
                    );
                  } else if (state.createStoryStatus == ApiStatus.failure) {
                    showCustomSnackbar(
                      context: context,
                      message:
                          state.createStoryMessage ??
                          (l10n?.tr('failedToUploadStory') ??
                              'Failed to upload story'),
                      isError: true,
                      showAtTop: true,
                    );
                  }
                },
                builder: (context, state) {
                  final isLoading =
                      state.createStoryStatus == ApiStatus.loading;
                  return PrimaryButton(
                    text: l10n?.tr('uploadStory') ?? 'Upload Story',
                    isLoading: isLoading,
                    onPressed: _mediaPath == null || isLoading ? null : _submit,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
