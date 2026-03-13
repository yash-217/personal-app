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

  // ── Notification ID ranges ──
  // Sleep reminders:      100-106  (one per day for 7 days)
  // Activity reminders:   200-206
  // Wind-down reminders:  300-306
  // Weekly check-in:      400
  // Inactivity nudge:     500
  static const int _sleepBaseId = 100;
  static const int _activityBaseId = 200;
  static const int _windDownBaseId = 300;
  static const int _weeklyCheckInId = 400;
  static const int _inactivityId = 500;

  /// Android notification channels
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

  // ──────────────────────────────────────────────────────────────────────────
  // Public API – called on app launch and after any data change.
  // ──────────────────────────────────────────────────────────────────────────

  /// Reschedule all notifications based on current data.
  Future<void> rescheduleNotifications({
    required List<SleepLog> sleepLogs,
    required List<DayLog> dayLogs,
  }) async {
    // Cancel everything first so we always have a clean slate
    await _plugin.cancelAll();

    final now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < 7; i++) {
      final targetDate = now.add(Duration(days: i));
      final dateOnly = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );

      // ── 1. Morning Sleep Reminder @ 9 AM ──
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

      // ── 2. Evening Activity Reminder @ 8 PM ──
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

      // ── 3. Wind-Down Reminder @ 10 PM ──
      final windDownTime = tz.TZDateTime(
        tz.local,
        dateOnly.year,
        dateOnly.month,
        dateOnly.day,
        22, // 10 PM
      );
      if (windDownTime.isAfter(now)) {
        await _scheduleNotification(
          id: _windDownBaseId + i,
          title: '🌙 Time to wind down',
          body: 'Put your screens away for better sleep tonight.',
          scheduledDate: windDownTime,
        );
        debugPrint(
          '[Notifications] Scheduled wind-down reminder for $windDownTime',
        );
      }
    }

    // ── 4. Weekly Check-in – Next Sunday @ 10 AM ──
    _scheduleWeeklyCheckIn(now);

    // ── 5. Inactivity Nudge – 3 days from now if no recent data ──
    _scheduleInactivityNudge(now, sleepLogs, dayLogs);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  void _scheduleWeeklyCheckIn(tz.TZDateTime now) {
    // Find the next Sunday
    int daysUntilSunday = DateTime.sunday - now.weekday;
    if (daysUntilSunday <= 0) daysUntilSunday += 7;

    final nextSunday = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysUntilSunday,
      10, // 10 AM
    );

    if (nextSunday.isAfter(now)) {
      _scheduleNotification(
        id: _weeklyCheckInId,
        title: '📊 Weekly Review',
        body: 'Check your progress on your weekly goals!',
        scheduledDate: nextSunday,
      );
      debugPrint(
        '[Notifications] Scheduled weekly check-in for $nextSunday',
      );
    }
  }

  void _scheduleInactivityNudge(
    tz.TZDateTime now,
    List<SleepLog> sleepLogs,
    List<DayLog> dayLogs,
  ) {
    // Check if user has logged anything in the last 2 days
    final twoDaysAgo = now.subtract(const Duration(days: 2));

    final hasRecentSleep = sleepLogs.any(
      (log) => log.date.isAfter(twoDaysAgo),
    );
    final hasRecentActivity = dayLogs.any(
      (log) => log.date.isAfter(twoDaysAgo),
    );

    // If they have recent data, no need for a nudge. If they don't, schedule
    // one 3 days from now (so effectively it fires ~3 days after last activity).
    if (!hasRecentSleep && !hasRecentActivity) {
      final nudgeTime = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day + 1, // tomorrow
        11, // 11 AM
      );

      if (nudgeTime.isAfter(now)) {
        _scheduleNotification(
          id: _inactivityId,
          title: '👋 We miss you!',
          body: "You haven't logged anything recently. Come track your progress!",
          scheduledDate: nudgeTime,
        );
        debugPrint(
          '[Notifications] Scheduled inactivity nudge for $nudgeTime',
        );
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

  // ──────────────────────────────────────────────────────────────────────────
  // Achievement Notification (instant, not scheduled)
  // ──────────────────────────────────────────────────────────────────────────
  static int _achievementIdCounter = 600;

  Future<void> showAchievementNotification({
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'achievement_channel',
      'Achievements',
      channelDescription: 'Notifications for unlocked achievements',
      importance: Importance.high,
      priority: Priority.high,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: _achievementIdCounter++,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }
}
