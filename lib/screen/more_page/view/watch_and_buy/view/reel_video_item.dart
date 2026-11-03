import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../model/watch_and_buy_reel_model.dart';
import 'widgets/watch_and_buy_product_card.dart';

class ReelVideoItem extends StatefulWidget {
  final VideoPlayerController? controller;
  final WatchAndBuyReelModel item;
  final bool isActive;
  final int index;
  final VoidCallback onLikeToggle;
  final bool isMuted;
  final VoidCallback onVideoComplete;

  const ReelVideoItem({
    super.key,
    required this.controller,
    required this.item,
    required this.isActive,
    required this.index,
    required this.onLikeToggle,
    required this.isMuted,
    required this.onVideoComplete,
  });

  @override
  State<ReelVideoItem> createState() => _ReelVideoItemState();
}

class _ReelVideoItemState extends State<ReelVideoItem>
    with SingleTickerProviderStateMixin {
  VideoPlayerController? get _controller => widget.controller;
  bool get _isInitialized =>
      _controller != null && _controller!.value.isInitialized;
  bool get _hasError => _controller != null && _controller!.value.hasError;
  String get _errorMsg => _controller?.value.errorDescription ?? '';

  @override
  void initState() {
    super.initState();
    log(
      'Reel[${widget.index}]: initState, isActive=${widget.isActive}, controllerInitialized=$_isInitialized',
    );
    widget.controller?.addListener(_videoListener);
    if (widget.controller != null && widget.controller!.value.isInitialized) {
      widget.controller!.setVolume(widget.isMuted ? 0.0 : 1.0);
      if (widget.isActive) {
        log('Reel[${widget.index}]: Playing video in initState');
        widget.controller!.play();
      }
    }
  }

  void _videoListener() {
    if (!mounted ||
        widget.controller == null ||
        !widget.controller!.value.isInitialized) {
      return;
    }

    final bool isFinished =
        widget.controller!.value.position >= widget.controller!.value.duration;
    if (isFinished) {
      widget.controller!.removeListener(_videoListener);
      widget.onVideoComplete();
      return;
    }

    setState(() {});
  }

  @override
  void didUpdateWidget(covariant ReelVideoItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool controllerChanged = widget.controller != oldWidget.controller;

    if (controllerChanged) {
      oldWidget.controller?.removeListener(_videoListener);
      widget.controller?.addListener(_videoListener);
    }

    if (widget.controller != null && widget.controller!.value.isInitialized) {
      widget.controller!.setVolume(widget.isMuted ? 0.0 : 1.0);
      if (widget.isActive) {
        if (!oldWidget.isActive || controllerChanged) {
          log(
            'Reel[${widget.index}]: Playing video in didUpdateWidget (isActive changed to true or controller changed)',
          );
          widget.controller!.play();
        }
      } else {
        if (oldWidget.isActive || controllerChanged) {
          log(
            'Reel[${widget.index}]: Pausing video in didUpdateWidget (isActive changed to false or controller changed)',
          );
          widget.controller!.pause();
          widget.controller!.seekTo(Duration.zero);
        }
      }
    }
  }

  void _initializePlayer() {
    widget.controller?.initialize().then((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_videoListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('reel_${widget.index}'),
      onVisibilityChanged: (info) {
        log(
          'Reel[${widget.index}]: onVisibilityChanged -> fraction=${info.visibleFraction}',
        );
        if (!mounted || _controller == null || !_isInitialized) return;

        if (info.visibleFraction == 0.0) {
          if (_controller!.value.isPlaying) {
            log(
              'Reel[${widget.index}]: Pausing video because visibleFraction == 0.0',
            );
            _controller!.pause();
            setState(() {});
          }
        } else if (info.visibleFraction == 1.0 && widget.isActive) {
          if (!_controller!.value.isPlaying) {
            log(
              'Reel[${widget.index}]: Playing video because visibleFraction == 1.0 and isActive == true',
            );
            _controller!.play();
            setState(() {});
          }
        }
      },
      child: Stack(
        children: [
          // Video display or loading/error states
          Positioned.fill(
            child: Hero(
              tag: 'reel_${widget.index}',
              child: Container(
                color: Colors.black,
                child: _hasError
                    ? _buildErrorScreen()
                    : !_isInitialized
                    ? _buildLoadingScreen()
                    : GestureDetector(
                        onTap: () {
                          if (_controller != null) {
                            if (_controller!.value.isPlaying) {
                              _controller!.pause();
                            } else {
                              _controller!.play();
                            }
                            setState(() {});
                          }
                        },
                        onDoubleTap: () {},
                        child: SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _controller!.value.size.width,
                              height: _controller!.value.size.height,
                              child: VideoPlayer(_controller!),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),

          // Black gradient overlay to read overlays clearly
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.3),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.1),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // Video pause icon overlay (indicates pause status)
          if (_isInitialized &&
              _controller != null &&
              !_controller!.value.isPlaying)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),

          // Frosted glass bar at the bottom with details and interactive likes
          Positioned(
            key: const ValueKey('bottom_ui'),
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 10,
            child: Column(
              children: [
                // Reel Info & Actions Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Left side: User info and caption
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundImage:
                                      widget.item.profile?.photoUrl != null
                                      ? CachedNetworkImageProvider(
                                          widget.item.profile!.photoUrl!,
                                        )
                                      : null,
                                  child: widget.item.profile?.photoUrl == null
                                      ? const Icon(
                                          Icons.person,
                                          size: 18,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  widget.item.profile?.username ?? 'User',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            if (widget.item.caption != null &&
                                widget.item.caption!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                widget.item.caption!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right side: Static Like Count
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatLikes(widget.item.likeCount),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Products Row
                if (widget.item.products.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildProductsList(widget.item.products),
                ],

                // Progress Bar
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _isInitialized && _controller != null
                      ? ValueListenableBuilder<VideoPlayerValue>(
                          valueListenable: _controller!,
                          builder: (context, value, child) {
                            final duration = value.duration;
                            final position = value.position;
                            final targetValue = duration.inMilliseconds > 0
                                ? position.inMilliseconds /
                                      duration.inMilliseconds
                                : 0.0;

                            return ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(
                                  begin: 0.0,
                                  end: targetValue,
                                ),
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.linear,
                                builder: (context, val, _) {
                                  return LinearProgressIndicator(
                                    value: val,
                                    minHeight: 3,
                                    backgroundColor: Colors.white24,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).primaryColor,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: const LinearProgressIndicator(
                            minHeight: 3,
                            backgroundColor: Colors.white24,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.grey,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(List<WatchAndBuyReelProduct> products) {
    return SizedBox(
      height: 72,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.85),
        padEnds: true,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: WatchAndBuyProductCard(
              imageUrl: product.imageUrl,
              title:
                  product.name ??
                  context.tr('unknownProduct') ??
                  'Unknown Product',
              subtitle:
                  context.tr('variantHash', positionalArgs: [product.productVariantId?.toString() ?? '0']) ??
                  'Variant #${product.productVariantId ?? 0}',
              isDark: Theme.of(context).brightness == Brightness.dark,
              onTap: () {
                // Action when seller taps product on their reel (e.g. edit product, view product)
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Stack(
      children: [
        if (widget.item.coverUrl != null && widget.item.coverUrl!.isNotEmpty)
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: widget.item.coverUrl!,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => const SizedBox.shrink(),
            ),
          ),
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.4)),
        ),
        const Center(
          child: CircularProgressIndicator(
            color: Colors.white70,
            strokeWidth: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.white54,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('unableToLoadVideo') ??
                'Unable to load video',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          if (_errorMsg.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _errorMsg,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _initializePlayer,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: Text(context.tr('retry') ?? 'Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white24,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLikes(int likes) {
    if (likes >= 1000) {
      return "${(likes / 1000).toStringAsFixed(1)}k";
    }
    return likes.toString();
  }
}
