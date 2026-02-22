import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/sleep_log.dart';
import '../models/day_log.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Notification ID ranges: Sleep 100-106, Activity 200-206
  static const int _sleepBaseId = 100;
  static const int _activityBaseId = 200;

  /// Android notification channel details
  static const _channelId = 'daily_reminders';
  static const _channelName = 'Daily Reminders';
  static const _channelDescription =
      'Reminders to log your sleep and activities';

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings: initSettings);
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Android 13+ runtime permission
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }

    // iOS permission
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      await ios.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  /// Reschedule all notifications based on current data.
  /// Call this on app launch and after any sleep/activity data change.
  Future<void> rescheduleNotifications({
    required List<SleepLog> sleepLogs,
    required List<DayLog> dayLogs,
  }) async {
    // Cancel everything first
    await _plugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < 7; i++) {
      final targetDate = now.add(Duration(days: i));
      final dateOnly = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );

      // --- Sleep reminder at 9 AM ---
      final hasSleepLog = sleepLogs.any(
        (log) =>
            log.date.year == dateOnly.year &&
            log.date.month == dateOnly.month &&
            log.date.day == dateOnly.day,
      );

      if (!hasSleepLog) {
        final sleepTime = tz.TZDateTime(
          tz.local,
          dateOnly.year,
          dateOnly.month,
          dateOnly.day,
          9, // 9 AM
        );
        if (sleepTime.isAfter(now)) {
          await _scheduleNotification(
            id: _sleepBaseId + i,
            title: '😴 Log your sleep',
            body: 'How did you sleep last night? Tap to log it.',
            scheduledDate: sleepTime,
          );
          debugPrint('[Notifications] Scheduled sleep reminder for $sleepTime');
        }
      }

      // --- Activity reminder at 8 PM ---
      final dayLog = dayLogs
          .where(
            (d) =>
                d.date.year == dateOnly.year &&
                d.date.month == dateOnly.month &&
                d.date.day == dateOnly.day,
          )
          .toList();
      final hasActivity =
          dayLog.isNotEmpty && dayLog.first.activities.isNotEmpty;

      if (!hasActivity) {
        final activityTime = tz.TZDateTime(
          tz.local,
          dateOnly.year,
          dateOnly.month,
          dateOnly.day,
          20, // 8 PM
        );
        if (activityTime.isAfter(now)) {
          await _scheduleNotification(
            id: _activityBaseId + i,
            title: '💪 Log your activity',
            body: "Did you work out today? Don't forget to track it!",
            scheduledDate: activityTime,
          );
          debugPrint(
            '[Notifications] Scheduled activity reminder for $activityTime',
          );
        }
      }
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: null, // one-shot, not repeating
    );
  }
}
