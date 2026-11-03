import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hyper_local_seller/utils/time_utils.dart'; // To reuse _parseDate logic

class OrderCountdownTimer extends StatefulWidget {
  final String createdAt;
  final int timeoutMinutes;
  final String? deadlineStr;
  final VoidCallback onTimeout;
  final TextStyle? textStyle;

  const OrderCountdownTimer({
    super.key,
    required this.createdAt,
    required this.timeoutMinutes,
    this.deadlineStr,
    required this.onTimeout,
    this.textStyle,
  });

  @override
  State<OrderCountdownTimer> createState() => _OrderCountdownTimerState();
}

class _OrderCountdownTimerState extends State<OrderCountdownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;
  bool _isTimeoutTriggered = false;

  // Track orders that have already been auto-rejected this session to prevent infinite refresh loops
  // if the backend fails to actually update the status to "rejected".
  static final Set<String> _autoRejectedKeys = {};

  String get _uniqueKey => '${widget.createdAt}_${widget.timeoutMinutes}_${widget.deadlineStr ?? ''}';

  @override
  void initState() {
    super.initState();
    _calculateRemainingTime();
    
    if (_remaining > Duration.zero) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _remaining -= const Duration(seconds: 1);
          if (_remaining <= Duration.zero) {
            _timer?.cancel();
            _triggerTimeout();
          }
        });
      });
    } else {
      // The user explicitly wants orders that are already expired when the app opens to be auto-rejected immediately.
      _triggerTimeout();
    }
  }

  void _calculateRemainingTime() {
    try {
      DateTime? expiryTime;
      
      if (widget.deadlineStr != null && widget.deadlineStr!.isNotEmpty) {
        expiryTime = TimeUtils.parseDate(widget.deadlineStr!);
      }
      
      if (expiryTime == null) {
        DateTime? parsedDate = TimeUtils.parseDate(widget.createdAt);
        if (parsedDate != null) {
          expiryTime = parsedDate.add(Duration(minutes: widget.timeoutMinutes));
        }
      }

      if (expiryTime != null) {
        final now = DateTime.now();
        final diffSeconds = expiryTime.difference(now).inSeconds;
        debugPrint('OrderCountdownTimer: expiryTime=$expiryTime, now=$now, diffSeconds=$diffSeconds');
        if (expiryTime.isAfter(now)) {
          _remaining = expiryTime.difference(now);
          debugPrint('OrderCountdownTimer: remaining $_remaining');
        } else {
          debugPrint('OrderCountdownTimer: already expired (diff is $diffSeconds seconds)');
          _remaining = Duration.zero;
        }
      } else {
        _remaining = Duration.zero;
      }
    } catch (e) {
      _remaining = Duration.zero;
    }
  }

  void _triggerTimeout() {
    if (!_isTimeoutTriggered) {
      if (_autoRejectedKeys.contains(_uniqueKey)) {
        debugPrint('OrderCountdownTimer: Already auto-rejected $_uniqueKey this session. Skipping to prevent loop.');
        return;
      }
      
      _isTimeoutTriggered = true;
      _autoRejectedKeys.add(_uniqueKey);
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTimeout();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    if (duration <= Duration.zero) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    final hours = duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : '';
    return "$hours$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining <= Duration.zero) {
      return Text(
        context.tr('expired'),
        style: widget.textStyle?.copyWith(color: Colors.red) ??
            const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
      );
    }
    return Text(
      _formatDuration(_remaining),
      style: widget.textStyle?.copyWith(
            color: _remaining.inMinutes < 1 ? Colors.red : Colors.orange,
          ) ??
          TextStyle(
            color: _remaining.inMinutes < 1 ? Colors.red : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
    );
  }
}
