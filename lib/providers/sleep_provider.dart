import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/sleep_log.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../providers/workout_provider.dart';
import '../providers/achievement_provider.dart';

class SleepProvider extends ChangeNotifier {
  static const _uuid = Uuid();
  final StorageService _storage;
  List<SleepLog> _logs = [];

  WorkoutProvider? _workoutProvider;
  AchievementProvider? _achievementProvider;

  SleepProvider(this._storage) {
    _loadData();
  }

  /// Set a reference to the WorkoutProvider for coordinated notification scheduling.
  void setWorkoutProvider(WorkoutProvider provider) {
    _workoutProvider = provider;
  }

  /// Set a reference to the AchievementProvider for badge evaluation.
  void setAchievementProvider(AchievementProvider provider) {
    _achievementProvider = provider;
  }

  void _rescheduleNotifications() {
    NotificationService().rescheduleNotifications(
      sleepLogs: _logs,
      dayLogs: _workoutProvider?.dayLogs ?? [],
    );
    _achievementProvider?.evaluate(
      dayLogs: _workoutProvider?.dayLogs ?? [],
      sleepLogs: _logs,
      runLogs: _workoutProvider?.runLogs ?? [],
    );
  }

  List<SleepLog> get logs => _logs;

  void _loadData() {
    _logs = _storage.getAllSleepLogs();
    notifyListeners();
  }

  Future<void> addLog({
    required DateTime date,
    required DateTime bedtime,
    required DateTime wakeTime,
    bool avoidedScreentime = false,
    int quality = 5,
    String? mood,
    String? notes,
    bool? morningErection,
    bool? period,
  }) async {
    final log = SleepLog(
      id: _uuid.v4(),
      date: date,
      bedtime: bedtime,
      wakeTime: wakeTime,
      avoidedScreentime: avoidedScreentime,
      quality: quality,
      mood: mood,
      notes: notes,
      morningErection: morningErection,
      period: period,
    );
    await _storage.saveSleepLog(log);
    _logs.insert(0, log);
    notifyListeners();
    _rescheduleNotifications();
  }

  Future<void> updateLog(SleepLog log) async {
    await _storage.saveSleepLog(log);
    final index = _logs.indexWhere((l) => l.id == log.id);
    if (index >= 0) {
      _logs[index] = log;
      notifyListeners();
      _rescheduleNotifications();
    }
  }

  Future<void> deleteLog(String id) async {
    await _storage.deleteSleepLog(id);
    _logs.removeWhere((l) => l.id == id);
    notifyListeners();
    _rescheduleNotifications();
  }

  // --- Stats ---

  String get avgDuration {
    if (_logs.isEmpty) return '0h 0m';
    final totalMinutes = _logs.fold(0, (sum, log) => sum + log.durationMinutes);
    final avgMinutes = totalMinutes ~/ _logs.length;
    final hours = avgMinutes ~/ 60;
    final minutes = avgMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  double get avgQuality {
    if (_logs.isEmpty) return 0;
    final totalQuality = _logs.fold(0, (sum, log) => sum + log.quality);
    return totalQuality / _logs.length;
  }

  /// Percentage of logs where screentime was avoided
  double get screentimeAvoidanceRate {
    if (_logs.isEmpty) return 0;
    final avoidedCount = _logs.where((l) => l.avoidedScreentime).length;
    return (avoidedCount / _logs.length) * 100;
  }

  /// Average bedtime in hours (18.0 - 30.0 range for the chart)
  double get avgBedtime {
    if (_logs.isEmpty) return 0;
    double totalHours = 0;
    for (final log in _logs) {
      double hour = log.bedtime.hour + log.bedtime.minute / 60.0;
      if (hour < 12) hour += 24;
      totalHours += hour;
    }
    return totalHours / _logs.length;
  }

  /// Average wake time in hours (always +24 if before noon for chart normalization)
  double get avgWakeTime {
    if (_logs.isEmpty) return 0;
    double totalHours = 0;
    for (final log in _logs) {
      double hour = log.wakeTime.hour + log.wakeTime.minute / 60.0;
      if (hour < 15) hour += 24; // Wake up before 3 PM treated as next day
      totalHours += hour;
    }
    return totalHours / _logs.length;
  }

  /// Returns sleep windows (from, to) for the last 7 days
  List<({double from, double to})> get weeklySleepWindows {
    // Return last 7 days of data
    return _logs
        .take(7)
        .map((l) {
          double start = l.bedtime.hour + l.bedtime.minute / 60.0;
          double end = l.wakeTime.hour + l.wakeTime.minute / 60.0;

          // Handle midnight crossing: if end < start, it means wake up was next day
          if (end < start) {
            end += 24;
          }
          // If bedtime is very early morning (e.g. 1 AM), also offset it for the chart
          if (start < 12) {
            start += 24;
            end += 24;
          }

          return (from: start, to: end);
        })
        .toList()
        .reversed
        .toList();
  }

  /// Returns dynamic chart bounds (minY, maxY) based on last 7 days.
  /// Snaps to the nearest even hours that encapsulate the sleep data.
  ({double minY, double maxY}) get sleepChartBounds {
    final windows = weeklySleepWindows;
    if (windows.isEmpty) return (minY: 18.0, maxY: 34.0);

    double minFrom = windows.map((w) => w.from).reduce((a, b) => a < b ? a : b);
    double maxTo = windows.map((w) => w.to).reduce((a, b) => a > b ? a : b);

    // Snap to the even hour below the earliest bedtime
    // We subtract a tiny epsilon (0.1) to ensure if someone sleeps exactly at 22:00,
    // the chart might show from 20:00 to give some breathing room.
    double minY = ((minFrom - 0.1) / 2).floorToDouble() * 2;

    // Snap to the even hour above the latest wake time
    double maxY = ((maxTo + 0.1) / 2).ceilToDouble() * 2;

    // Ensure at least a 4-hour range for visual consistency
    if (maxY - minY < 4) {
      minY -= 2;
      maxY += 2;
    }

    return (minY: minY, maxY: maxY);
  }

  /// Returns sleep duration for the last 7 days for charting
  List<double> get weeklySleepDuration {
    return _logs
        .take(7)
        .map((l) => l.durationMinutes / 60.0)
        .toList()
        .reversed
        .toList();
  }
}
