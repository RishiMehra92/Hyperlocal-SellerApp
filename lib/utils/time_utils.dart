import 'package:hyper_local_seller/extensions/translation_extension.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum TimeFormatType {
  store,
  product,
  order,
  attribute,
  attributeValues,
  wallet,
  transactions,
  earnings,
}

class TimeUtils {
  static String formatTimeAgo(
    String? dateStr,
    BuildContext context, {
    TimeFormatType type = TimeFormatType.product,
  }) {
    if (dateStr == null || dateStr.isEmpty) return "";

    try {
      final DateTime? dateTime = parseDate(dateStr);
      if (dateTime == null) return dateStr;

      final DateTime now = DateTime.now();
      final Duration difference = now.difference(dateTime);
      final l10n = context;

      // Handle "time ago" logic
      if (type == TimeFormatType.store) {
        // For store, if more than 7 days, show actual date
        if (difference.inDays > 7) {
          return DateFormat('d MMM, yyyy').format(dateTime);
        }
      }

      if (type == TimeFormatType.earnings) {
        return DateFormat('dd-MM-yyyy').format(dateTime);
      }

      // Default relative time logic
      if (difference.inSeconds < 60) {
        return l10n.tr('justNow');
      } else if (difference.inMinutes < 60) {
        return l10n.tr('minutesAgo', positionalArgs: [difference.inMinutes]);
      } else if (difference.inHours < 24) {
        return l10n.tr('hoursAgo', positionalArgs: [difference.inHours]);
      } else if (difference.inDays < 30) {
        return l10n.tr('daysAgo', positionalArgs: [difference.inDays]);
      } else {
        // Fallback for very old dates
        return DateFormat('d MMM, yyyy').format(dateTime);
      }
    } catch (e) {
      debugPrint("Error formatting date: $e");
      return dateStr;
    }
  }

  static String formatScheduledDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      final DateTime? dateTime = parseDate(dateStr);
      if (dateTime != null) {
        return DateFormat('MMM dd, yyyy').format(dateTime);
      }
      return dateStr;
    } catch (_) {
      return dateStr;
    }
  }

  static DateTime? parseDate(String dateStr) {
    // 1. Try ISO 8601
    try {
      return DateTime.parse(dateStr);
    } catch (_) {}

    // 2. Try "MMM d, yyyy hh:mm:ss a" (e.g., "Sep 19, 2026 01:46:45 PM")
    try {
      return DateFormat('MMM d, yyyy hh:mm:ss a').parse(dateStr);
    } catch (_) {}

    // 2.1. Try "MMM d, yyyy hh:mm a" (e.g., "Sep 18, 2026 04:00 PM")
    try {
      return DateFormat('MMM d, yyyy hh:mm a').parse(dateStr);
    } catch (_) {}

    // 3. Try "d MMM, yyyy" (e.g., "26 Jan, 2026")
    try {
      return DateFormat('d MMM, yyyy').parse(dateStr);
    } catch (_) {}

    // 3. Try "MMM d, yyyy" (e.g., "Jul 14, 2026")
    try {
      return DateFormat('MMM d, yyyy').parse(dateStr);
    } catch (_) {}

    // 4. Try "EEEE, d MMM" (e.g., "Monday, 26 Jan") - assuming current year
    try {
      DateTime parsed = DateFormat('EEEE, d MMM').parse(dateStr);
      return DateTime(DateTime.now().year, parsed.month, parsed.day);
    } catch (_) {}

    // 5. Try "d MMM" (e.g., "26 Jan") - assuming current year
    try {
      DateTime parsed = DateFormat('d MMM').parse(dateStr);
      return DateTime(DateTime.now().year, parsed.month, parsed.day);
    } catch (_) {}

    return null;
  }
}
