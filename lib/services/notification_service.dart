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
  // IDs are date-stable: baseId + dayOfYear (0-365).
  // This prevents a cancelAll()-style wipe from destroying a pending
  // notification that was scheduled on a previous app launch.
  //
  // Sleep reminders:      1000 + dayOfYear
  // Activity reminders:   2000 + dayOfYear
  // Wind-down reminders:  3000 + dayOfYear
  // Weekly check-in:      4000
  // Inactivity nudge:     5000
  // Achievements:         6000+
  static const int _sleepBaseId = 1000;
  static const int _activityBaseId = 2000;
  static const int _windDownBaseId = 3000;
  static const int _weeklyCheckInId = 4000;
  static const int _inactivityId = 5000;

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
  ///
  /// Uses targeted cancellation instead of cancelAll() so that
  /// already-pending notifications for other dates are preserved.
  Future<void> rescheduleNotifications({
    required List<SleepLog> sleepLogs,
    required List<DayLog> dayLogs,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    for (int i = 0; i < 7; i++) {
      final targetDate = now.add(Duration(days: i));
      final dateOnly = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );
      final dayOfYear =
          dateOnly.difference(DateTime(dateOnly.year, 1, 1)).inDays;

      final sleepId = _sleepBaseId + dayOfYear;
      final activityId = _activityBaseId + dayOfYear;
      final windDownId = _windDownBaseId + dayOfYear;

      // Cancel only the IDs for the dates we're about to re-evaluate.
      // Already-fired notifications are no-ops; notifications for other
      // dates that were scheduled on previous app launches are untouched.
      await _plugin.cancel(id: sleepId);
      await _plugin.cancel(id: activityId);
      await _plugin.cancel(id: windDownId);

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
            id: sleepId,
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
            id: activityId,
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
          id: windDownId,
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
    await _plugin.cancel(id: _weeklyCheckInId);
    _scheduleWeeklyCheckIn(now);

    // ── 5. Inactivity Nudge – 3 days from now if no recent data ──
    await _plugin.cancel(id: _inactivityId);
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
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null, // one-shot, not repeating
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Achievement Notification (instant, not scheduled)
  // ──────────────────────────────────────────────────────────────────────────
  static int _achievementIdCounter = 6000;

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
