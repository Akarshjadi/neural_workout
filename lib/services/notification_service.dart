import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

import '../models/note.dart';

/// Phase 6 — Local notifications. User sets rules (times + conditions), app fires them.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  // Notification IDs
  static const int nightReview = 101;
  static const int cardsDue = 9999;

  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final localTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTz.identifier));
    } catch (e) {
      debugPrint('NotificationService timezone fallback: $e');
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    try {
      await _plugin.initialize(settings);

      // Request POST_NOTIFICATIONS on Android 13+
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      if (granted == false) {
        _ready = false;
        return;
      }
      _ready = true;
    } catch (e, stackTrace) {
      _ready = false;
      debugPrint('NotificationService: init failed: $e\n$stackTrace');
    }
  }

  /// Schedule a daily notification at [hour]:[minute] local time.
  /// Returns true if the notification was scheduled successfully, false otherwise.
  Future<bool> scheduleDaily({
    required int hour,
    required int minute,
    required String title,
    required String body,
    required int id,
  }) async {
    if (!_ready) return false;
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'neural_workout_reminders',
            'Reminders',
            channelDescription: 'Neural Workout study reminders',
            importance: Importance.defaultImportance,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      return true;
    } catch (e, stackTrace) {
      debugPrint('NotificationService: scheduleDaily failed: $e\n$stackTrace');
      return false;
    }
  }

  /// Schedule a notification at the earliest due time from due cards.
  /// Returns true if the notification was scheduled successfully, false otherwise.
  Future<bool> scheduleForDueCards(List<Note> dueNotes) async {
    if (!_ready || dueNotes.isEmpty) return false;
    try {
      final earliest = dueNotes
          .map((n) => n.card.due)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      final now = tz.TZDateTime.now(tz.local);
      final scheduled = earliest.isBefore(now)
          ? now.add(const Duration(minutes: 1))
          : tz.TZDateTime.from(earliest, tz.local);
      await _plugin.zonedSchedule(
        cardsDue,
        'Cards due',
        '${dueNotes.length} notes ready for review',
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'neural_workout_due',
            'Due Cards',
            channelDescription: 'Spaced repetition due cards',
            importance: Importance.defaultImportance,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      return true;
    } catch (e, stackTrace) {
      debugPrint('NotificationService: scheduleForDueCards failed: $e\n$stackTrace');
      return false;
    }
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    try {
      await _plugin.cancelAll();
    } catch (e, stackTrace) {
      debugPrint('NotificationService: cancelAll failed: $e\n$stackTrace');
    }
  }

  /// Schedule break reminders.
  Future<bool> scheduleBreakReminders() async {
    if (!_ready) return false;
    try {
      // Just a simple midday reminder for micro breaks. (ponytail style)
      return await scheduleDaily(
        hour: 14,
        minute: 0,
        title: 'Micro Break Reminder',
        body: 'Time for a 5m break to lock in memory synthesis.',
        id: 103, // break reminder ID
      );
    } catch (e) {
      return false;
    }
  }
}

