import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../memory/database.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

/// Detects intent from user messages and executes phone-level actions.
/// Returns a response string if action was handled, null if AI should handle it.
class ActionDetector {
  static final ActionDetector instance = ActionDetector._internal();
  ActionDetector._internal();

  final _uuid = const Uuid();

  Future<String?> detect(String input) async {
    final lower = input.toLowerCase();

    // ─── Alarm detection ─────────────────────────────────────────────────
    if (_containsAny(lower, ['set alarm', 'wake me', 'alarm for', 'remind me at'])) {
      return await _handleAlarm(input);
    }

    // ─── Note saving ──────────────────────────────────────────────────────
    if (_containsAny(lower, ['save note', 'note this', 'write down', 'remember this', 'save this'])) {
      return await _handleNote(input);
    }

    // ─── Call intent ─────────────────────────────────────────────────────
    if (_containsAny(lower, ['call ', 'dial '])) {
      return await _handleCall(input);
    }

    // ─── Open URL ────────────────────────────────────────────────────────
    if (_containsAny(lower, ['open https://', 'open http://', 'open website', 'go to '])) {
      return await _handleUrl(input);
    }

    return null; // Let AI handle it
  }

  // ─── Alarm Handler ───────────────────────────────────────────────────────

  Future<String> _handleAlarm(String input) async {
    final timeResult = _extractTime(input);

    if (timeResult == null) {
      return '⚠️ I couldn\'t detect a time in your message. Try saying "Set alarm for 7:30 AM" or "Wake me at 8am".';
    }

    final (hour, minute, label) = timeResult;

    try {
      // Request exact alarm permission on Android 12+
      final status = await Permission.scheduleExactAlarm.request();
      if (status.isDenied) {
        return '⚠️ Alarm permission denied. Please enable "Alarms & Reminders" permission for ORB in system settings.';
      }

      final now = DateTime.now();
      var alarmTime = DateTime(now.year, now.month, now.day, hour, minute);

      // If time has passed today, schedule for tomorrow
      if (alarmTime.isBefore(now)) {
        alarmTime = alarmTime.add(const Duration(days: 1));
      }

      final alarmId = DateTime.now().millisecondsSinceEpoch % 100000;

      await AndroidAlarmManager.oneShotAt(
        alarmTime,
        alarmId,
        alarmCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );

      final formatted = DateFormat('h:mm a').format(alarmTime);
      final day = alarmTime.day == now.day ? 'today' : 'tomorrow';
      return '✅ Alarm set for **$formatted** $day${label != null ? ' — "$label"' : ''}.';
    } catch (e) {
      return '⚠️ Could not set alarm: ${e.toString()}. Make sure ORB has alarm permissions.';
    }
  }

  /// Extracts hour, minute, optional label from natural language
  (int, int, String?)? _extractTime(String input) {
    // Patterns: "7am", "7:30 am", "07:30", "7 am", "19:30"
    final patterns = [
      RegExp(r'(\d{1,2}):(\d{2})\s*(am|pm)?', caseSensitive: false),
      RegExp(r'(\d{1,2})\s*(am|pm)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(input.toLowerCase());
      if (match != null) {
        int hour = int.parse(match.group(1)!);
        int minute = 0;

        if (match.groupCount >= 2 && match.group(2) != null) {
          final g2 = match.group(2)!;
          if (g2 == 'am' || g2 == 'pm') {
            if (g2 == 'pm' && hour != 12) hour += 12;
            if (g2 == 'am' && hour == 12) hour = 0;
          } else {
            minute = int.tryParse(g2) ?? 0;
            final ampm = match.group(3);
            if (ampm != null) {
              if (ampm == 'pm' && hour != 12) hour += 12;
              if (ampm == 'am' && hour == 12) hour = 0;
            }
          }
        }

        if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
          // Try to extract a label
          final labelMatch = RegExp(r'for (.+?)(?:at|$)').firstMatch(input);
          final label = labelMatch?.group(1)?.trim();
          return (hour, minute, label);
        }
      }
    }
    return null;
  }

  // ─── Note Handler ────────────────────────────────────────────────────────

  Future<String> _handleNote(String input) async {
    // Extract content after action words
    String content = input;
    for (final trigger in ['save note:', 'note this:', 'write down:', 'remember this:', 'save this:']) {
      if (input.toLowerCase().contains(trigger)) {
        content = input.substring(input.toLowerCase().indexOf(trigger) + trigger.length).trim();
        break;
      }
    }

    if (content.isEmpty || content.toLowerCase() == input.toLowerCase()) {
      return '⚠️ What should I save? Try "Save note: Your content here"';
    }

    await OrbDatabase.instance.insertMessage({
      'id': _uuid.v4(),
      'role': 'note',
      'content': content,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'session_id': 'notes',
      'provider': null,
      'model': null,
    });

    return '✅ Note saved: *"$content"*';
  }

  // ─── Call Handler ────────────────────────────────────────────────────────

  Future<String> _handleCall(String input) async {
    // Extract phone number
    final phoneMatch = RegExp(r'[\+]?[0-9\s\-\(\)]{7,15}').firstMatch(input);
    if (phoneMatch == null) {
      return '⚠️ No phone number found. Try "Call 9876543210".';
    }

    final number = phoneMatch.group(0)!.replaceAll(RegExp(r'\s'), '');
    final uri = Uri.parse('tel:$number');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return '📞 Opening dialer for $number...';
    }
    return '⚠️ Could not open the dialer.';
  }

  // ─── URL Handler ─────────────────────────────────────────────────────────

  Future<String> _handleUrl(String input) async {
    final urlMatch = RegExp(r'https?://[^\s]+').firstMatch(input);
    if (urlMatch == null) return '⚠️ No URL found in your message.';

    final url = Uri.parse(urlMatch.group(0)!);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
      return '🌐 Opening ${url.host}...';
    }
    return '⚠️ Could not open the URL.';
  }

  bool _containsAny(String input, List<String> keywords) {
    return keywords.any((k) => input.contains(k));
  }
}

/// Top-level callback required by android_alarm_manager_plus
@pragma('vm:entry-point')
void alarmCallback() {
  // In a real app, you'd show a notification here
  // This runs in a separate isolate
}
