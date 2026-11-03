import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class WatchAndBuyVideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;

  const WatchAndBuyVideoThumbnailWidget({super.key, required this.videoUrl});

  @override
  State<WatchAndBuyVideoThumbnailWidget> createState() =>
      _WatchAndBuyVideoThumbnailWidgetState();
}

class _WatchAndBuyVideoThumbnailWidgetState
    extends State<WatchAndBuyVideoThumbnailWidget> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  void _initVideo() {
    if (widget.videoUrl.isEmpty) return;
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize()
          .then((_) {
            if (mounted) {
              setState(() {
                _isInitialized = true;
              });
            }
          })
          .catchError((_) {
            // Ignore initialization error for preview thumbnail
          });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized && _controller != null) {
      final size = _controller!.value.size;
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.width > 0 ? size.width : 300,
            height: size.height > 0 ? size.height : 500,
            child: VideoPlayer(_controller!),
          ),
        ),
      );
    }

    return Container(
      color: Colors.black12,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white54,
          ),
        ),
      ),
    );
  }
}
