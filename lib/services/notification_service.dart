import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
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

  /// Whether the user has granted exact-alarm permission.
  /// When false, we fall back to inexact scheduling.
  bool _canScheduleExact = true;

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

    // Detect the device's local timezone so tz.local resolves correctly.
    // Without this, tz.local defaults to UTC.
    try {
      final timezoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneName.toString()));
      debugPrint('[Notifications] Device timezone: $timezoneName');
    } catch (e) {
      debugPrint(
        '[Notifications] Plugin timezone lookup failed: $e — trying offset fallback',
      );
      _setTimezoneFromOffset();
    }

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

    try {
      await _plugin.initialize(settings: initSettings);
    } catch (e, st) {
      debugPrint('[Notifications] init() failed: $e\n$st');
    }
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Android 13+ runtime permission
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      try {
        await android.requestNotificationsPermission();
      } catch (e) {
        debugPrint('[Notifications] requestNotificationsPermission failed: $e');
      }

      try {
        final exactGranted = await android.requestExactAlarmsPermission();
        _canScheduleExact = exactGranted ?? false;
        if (!_canScheduleExact) {
          debugPrint(
            '[Notifications] Exact alarm permission denied — '
            'falling back to inexact scheduling',
          );
        }
      } catch (e) {
        debugPrint('[Notifications] requestExactAlarmsPermission failed: $e');
        _canScheduleExact = false;
      }
    }

    // iOS permission
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      try {
        await ios.requestPermissions(alert: true, badge: true, sound: true);
      } catch (e) {
        debugPrint('[Notifications] iOS requestPermissions failed: $e');
      }
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

    // Compute wind-down time once (same for every day in the 7-day window).
    final avgBedtimeMin = _averageBedtimeMinutes(sleepLogs, now);
    final windDownMin = avgBedtimeMin - 60;
    final windDownHour = (windDownMin ~/ 60) % 24;
    final windDownMinute = windDownMin % 60;

    for (int i = 0; i < 7; i++) {
      final targetDate = now.add(Duration(days: i));
      final dateOnly = DateTime(
        targetDate.year,
        targetDate.month,
        targetDate.day,
      );
      final dayOfYear = dateOnly
          .difference(DateTime(dateOnly.year, 1, 1))
          .inDays;

      final sleepId = _sleepBaseId + dayOfYear;
      final activityId = _activityBaseId + dayOfYear;
      final windDownId = _windDownBaseId + dayOfYear;

      // Cancel only the IDs for the dates we're about to re-evaluate.
      // Already-fired notifications are no-ops; notifications for other
      // dates that were scheduled on previous app launches are untouched.
      await _cancelSafe(sleepId);
      await _cancelSafe(activityId);
      await _cancelSafe(windDownId);

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

      // ── 3. Wind-Down Reminder – 1 h before avg bedtime (default 10 PM) ──

      var windDownTime = tz.TZDateTime(
        tz.local,
        dateOnly.year,
        dateOnly.month,
        dateOnly.day,
        windDownHour,
        windDownMinute,
      );
      // If the computed time is before noon, it likely wrapped past midnight;
      // push it to the next calendar day.
      if (windDownHour < 12) {
        windDownTime = windDownTime.add(const Duration(days: 1));
      }
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
    await _cancelSafe(_weeklyCheckInId);
    await _scheduleWeeklyCheckIn(now);

    // ── 5. Inactivity Nudge – 3 days from now if no recent data ──
    await _cancelSafe(_inactivityId);
    await _scheduleInactivityNudge(now, sleepLogs, dayLogs);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Private helpers
  // ──────────────────────────────────────────────────────────────────────────

  /// Fallback: resolve the IANA timezone from [DateTime.now().timeZoneOffset].
  /// No permissions required — the device already knows its own offset.
  void _setTimezoneFromOffset() {
    final deviceOffset = DateTime.now().timeZoneOffset;
    final offsetMs = deviceOffset.inMilliseconds;
    debugPrint(
      '[Notifications] Device UTC offset: '
      '${deviceOffset.inHours}h ${(deviceOffset.inMinutes % 60).abs()}m',
    );

    // Lookup table for half / quarter-hour offsets that are common but
    // harder to find by scanning (scan returns the first alphabetical match).
    const offsetToIana = {
      19800000: 'Asia/Kolkata',       // +05:30  IST
      20700000: 'Asia/Kathmandu',     // +05:45
      12600000: 'Asia/Tehran',        // +03:30
      16200000: 'Asia/Kabul',         // +04:30
      34200000: 'Australia/Adelaide', // +09:30
      23400000: 'Asia/Yangon',        // +06:30
      -12600000: 'America/St_Johns',  // −03:30
    };

    final knownIana = offsetToIana[offsetMs];
    if (knownIana != null) {
      try {
        tz.setLocalLocation(tz.getLocation(knownIana));
        debugPrint('[Notifications] Timezone set via offset table: $knownIana');
        return;
      } catch (_) {}
    }

    // Full database scan — find any location whose current offset matches.
    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      for (final name in tz.timeZoneDatabase.locations.keys) {
        final loc = tz.getLocation(name);
        if (loc.timeZone(nowMs).offset.inMilliseconds == offsetMs) {
          tz.setLocalLocation(loc);
          debugPrint('[Notifications] Timezone set via DB scan: $name');
          return;
        }
      }
    } catch (e) {
      debugPrint('[Notifications] DB scan failed: $e');
    }

    debugPrint(
      '[Notifications] WARNING: Could not resolve timezone — '
      'tz.local remains UTC. Notifications will fire at UTC times!',
    );
  }

  /// Cancel a notification by ID, swallowing any platform errors.
  Future<void> _cancelSafe(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('[Notifications] cancel($id) failed: $e');
    }
  }

  /// Returns the average bedtime as minutes since midnight (can be >1440 for
  /// past-midnight bedtimes, e.g. 1:30 AM → 25*60+30 = 1530).
  /// Falls back to 22*60 (10 PM) if fewer than 2 logs in the past 7 days.
  int _averageBedtimeMinutes(List<SleepLog> sleepLogs, tz.TZDateTime now) {
    const defaultMinutes = 22 * 60; // 10 PM

    final sevenDaysAgo = now.subtract(const Duration(days: 7));
    final recentLogs = sleepLogs
        .where((log) => log.bedtime.isAfter(sevenDaysAgo))
        .toList();

    if (recentLogs.length < 2) return defaultMinutes;

    // Normalise each bedtime to minutes-since-noon so that both 11 PM and
    // 1 AM cluster together (instead of wrapping around midnight).
    int totalMinutes = 0;
    for (final log in recentLogs) {
      int mins = log.bedtime.hour * 60 + log.bedtime.minute;
      // Treat times before 6 AM as "previous evening" (add 24 h)
      if (mins < 6 * 60) mins += 24 * 60;
      totalMinutes += mins;
    }

    final avg = totalMinutes ~/ recentLogs.length;
    debugPrint(
      '[Notifications] Average bedtime from ${recentLogs.length} logs: '
      '${avg ~/ 60}:${(avg % 60).toString().padLeft(2, '0')}',
    );
    return avg;
  }

  Future<void> _scheduleWeeklyCheckIn(tz.TZDateTime now) async {
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
      await _scheduleNotification(
        id: _weeklyCheckInId,
        title: '📊 Weekly Review',
        body: 'Check your progress on your weekly goals!',
        scheduledDate: nextSunday,
      );
      debugPrint('[Notifications] Scheduled weekly check-in for $nextSunday');
    }
  }

  Future<void> _scheduleInactivityNudge(
    tz.TZDateTime now,
    List<SleepLog> sleepLogs,
    List<DayLog> dayLogs,
  ) async {
    // Check if user has logged anything in the last 2 days
    final twoDaysAgo = now.subtract(const Duration(days: 2));

    final hasRecentSleep = sleepLogs.any((log) => log.date.isAfter(twoDaysAgo));
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
        await _scheduleNotification(
          id: _inactivityId,
          title: '👋 We miss you!',
          body:
              "You haven't logged anything recently. Come track your progress!",
          scheduledDate: nudgeTime,
        );
        debugPrint('[Notifications] Scheduled inactivity nudge for $nudgeTime');
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

    // Choose schedule mode based on whether exact alarms are permitted.
    final scheduleMode = _canScheduleExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: scheduleMode,
        matchDateTimeComponents: null, // one-shot, not repeating
      );
    } catch (e, st) {
      debugPrint('[Notifications] zonedSchedule($id) failed: $e\n$st');
    }
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

    try {
      await _plugin.show(
        id: _achievementIdCounter++,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
      );
    } catch (e, st) {
      debugPrint('[Notifications] show() achievement failed: $e\n$st');
    }
  }
}
