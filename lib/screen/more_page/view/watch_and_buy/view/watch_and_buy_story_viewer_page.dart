import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:hyper_local_seller/widgets/custom/custom_network_image.dart';
import '../model/watch_and_buy_story_model.dart';
import 'widgets/watch_and_buy_product_card.dart';

class WatchAndBuyStoryViewerPage extends StatefulWidget {
  final List<WatchAndBuyStoryModel> stories;
  final int initialIndex;

  const WatchAndBuyStoryViewerPage({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<WatchAndBuyStoryViewerPage> createState() =>
      _WatchAndBuyStoryViewerPageState();
}

class _WatchAndBuyStoryViewerPageState extends State<WatchAndBuyStoryViewerPage>
    with SingleTickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _animController;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _animController = AnimationController(vsync: this);

    _animController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStory();
      }
    });

    _loadStory(_currentIndex);
  }

  @override
  void dispose() {
    _animController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  void _loadStory(int index) {
    _animController.stop();
    _animController.reset();
    _videoController?.dispose();
    _videoController = null;
    _isVideoInitialized = false;

    final story = widget.stories[index];

    if (story.isVideo) {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(story.mediaUrl))
            ..initialize()
                .then((_) {
                  if (!mounted) return;
                  setState(() {
                    _isVideoInitialized = true;
                  });
                  final duration = _videoController!.value.duration;
                  _animController.duration = duration > Duration.zero
                      ? duration
                      : const Duration(seconds: 10);
                  _videoController!.play();
                  _animController.forward();
                })
                .catchError((e) {
                  if (!mounted) return;
                  _animController.duration = const Duration(seconds: 5);
                  _animController.forward();
                });
    } else {
      _animController.duration = const Duration(seconds: 5);
      _animController.forward();
    }
  }

  void _nextStory() {
    if (_currentIndex < widget.stories.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _loadStory(_currentIndex);
    } else {
      Navigator.of(context).pop();
    }
  }

  void _previousStory() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _loadStory(_currentIndex);
    } else {
      _loadStory(_currentIndex);
    }
  }

  void _pause() {
    _animController.stop();
    _videoController?.pause();
  }

  void _resume() {
    _animController.forward();
    _videoController?.play();
  }

  String _formatTime(BuildContext context, String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final diff = DateTime.now().difference(date);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context;

    if (widget.stories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            l10n?.tr('noStoriesFound') ?? 'No stories',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final story = widget.stories[_currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (_) => _pause(),
        onTapUp: (_) => _resume(),
        onTapCancel: () => _resume(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Media Content
            Center(
              child: story.isVideo
                  ? (_isVideoInitialized && _videoController != null
                        ? AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          )
                        : const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          ))
                  : CustomNetworkImage(
                      imageUrl: story.mediaUrl,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
            ),

            // 2. Left / Right tap zones for navigation
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _previousStory,
                    child: Container(),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _nextStory,
                    child: Container(),
                  ),
                ),
              ],
            ),

            // 3. Top Gradient with Progress Bars and Profile Header
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 12,
                  right: 12,
                  bottom: 24,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Segmented Progress Bar
                    Row(
                      children: List.generate(widget.stories.length, (index) {
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2.0,
                            ),
                            child: AnimatedBuilder(
                              animation: _animController,
                              builder: (context, _) {
                                double progress = 0.0;
                                if (index < _currentIndex) {
                                  progress = 1.0;
                                } else if (index == _currentIndex) {
                                  progress = _animController.value;
                                }
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 2.5,
                                    backgroundColor: Colors.white24,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),

                    // User Info & Close Button
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey.shade800,
                          backgroundImage:
                              story.profile?.photoUrl != null &&
                                  story.profile!.photoUrl!.isNotEmpty
                              ? NetworkImage(story.profile!.photoUrl!)
                              : null,
                          child:
                              story.profile?.photoUrl == null ||
                                  story.profile!.photoUrl!.isEmpty
                              ? const Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                story.profile != null
                                    ? '@${story.profile!.username}'
                                    : (l10n?.tr('storiesTab') ?? 'Story'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (story.createdAt != null)
                                Text(
                                  _formatTime(context, story.createdAt),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 4. Bottom Overlay (Story Text & Tagged Products)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 24,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text Overlay
                    if (story.text != null && story.text!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Text(
                          story.text!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Tagged Products List
                    if (story.products.isNotEmpty) ...[
                      SizedBox(
                        height: 72,
                        child: PageView.builder(
                          controller: PageController(viewportFraction: 0.85),
                          padEnds: true,
                          itemCount: story.products.length,
                          itemBuilder: (context, pIdx) {
                            final product = story.products[pIdx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: WatchAndBuyProductCard(
                                imageUrl: product.imageUrl,
                                title:
                                    product.title ??
                                    (context.tr('productHash', positionalArgs: [(product.productId ?? pIdx + 1)
                                              .toString(),]) ??
                                        'Product #${product.productId ?? pIdx + 1}'),
                                subtitle: product.price != null
                                    ? '\$${product.price}'
                                    : (context.tr('variantHash', positionalArgs: [(product.productVariantId ?? 0)
                                                .toString(),]) ??
                                          'Variant #${product.productVariantId ?? 0}'),
                                isDark:
                                    Theme.of(context).brightness ==
                                    Brightness.dark,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
