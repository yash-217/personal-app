import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/day_log.dart';
import '../models/workout_session.dart';
import '../models/workout_routine.dart';
import '../models/run_log.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import 'exercise_provider.dart';
import 'sleep_provider.dart';
import 'achievement_provider.dart';
import '../models/exercise.dart';

class WorkoutProvider extends ChangeNotifier {
  static const _uuid = Uuid();
  final StorageService _storage;

  List<DayLog> _dayLogs = [];
  List<WorkoutSession> _sessions = [];
  List<RunLog> _runLogs = [];
  List<WorkoutRoutine> _routines = [];

  SleepProvider? _sleepProvider;
  AchievementProvider? _achievementProvider;

  WorkoutProvider(this._storage) {
    _loadData();
  }

  /// Set a reference to the SleepProvider for coordinated notification scheduling.
  void setSleepProvider(SleepProvider provider) {
    _sleepProvider = provider;
  }

  /// Set a reference to the AchievementProvider for badge evaluation.
  void setAchievementProvider(AchievementProvider provider) {
    _achievementProvider = provider;
  }

  Future<void> _rescheduleNotifications() async {
    try {
      await NotificationService().rescheduleNotifications(
        sleepLogs: _sleepProvider?.logs ?? [],
        dayLogs: _dayLogs,
      );
    } catch (e) {
      debugPrint('[WorkoutProvider] rescheduleNotifications failed: $e');
    }
    _achievementProvider?.evaluate(
      dayLogs: _dayLogs,
      sleepLogs: _sleepProvider?.logs ?? [],
      runLogs: _runLogs,
    );
  }

  // --- Getters ---
  List<DayLog> get dayLogs => _dayLogs;
  List<WorkoutSession> get sessions => _sessions;
  List<RunLog> get runLogs => _runLogs;
  List<WorkoutRoutine> get routines => _routines;

  void _loadData() {
    _dayLogs = _storage.getAllDayLogs();
    _sessions = _storage.getAllSessions();
    _runLogs = _storage.getAllRunLogs();
    _routines = _storage.getAllRoutines();
    notifyListeners();
  }

  // --- Day Log Operations ---
  DayLog? getDayLogForDate(DateTime date) {
    try {
      return _dayLogs.firstWhere((d) => _dateKey(d.date) == _dateKey(date));
    } catch (_) {
      return null;
    }
  }

  WorkoutSession? getSessionById(String id) {
    try {
      return _sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Map<DateTime, List<ActivityType>> getCalendarEvents() {
    final map = <DateTime, List<ActivityType>>{};
    for (final log in _dayLogs) {
      final normalized = DateTime(log.date.year, log.date.month, log.date.day);
      map[normalized] = log.activities;
    }
    return map;
  }

  /// Toggle an activity for a given date. If the activity exists, remove it.
  /// If it doesn't exist, add it. Creates a new DayLog if none exists.
  Future<void> toggleActivity(DateTime date, ActivityType type) async {
    final existing = getDayLogForDate(date);
    if (existing != null) {
      final activities = List<ActivityType>.from(existing.activities);
      if (activities.contains(type)) {
        activities.remove(type);
      } else {
        activities.add(type);
      }

      if (activities.isEmpty) {
        await _storage.deleteDayLog(existing.id);
        _dayLogs.removeWhere((d) => d.id == existing.id);
      } else {
        final updated = existing.copyWith(activities: activities);
        await _storage.saveDayLog(updated);
        final index = _dayLogs.indexWhere((d) => d.id == existing.id);
        if (index >= 0) _dayLogs[index] = updated;
      }
    } else {
      final log = DayLog(
        id: _uuid.v4(),
        date: DateTime(date.year, date.month, date.day),
        activities: [type],
      );
      await _storage.saveDayLog(log);
      _dayLogs.add(log);
    }
    notifyListeners();
    _rescheduleNotifications();
  }

  /// Remove a specific activity type from a day
  Future<void> removeActivity(DateTime date, ActivityType type) async {
    final existing = getDayLogForDate(date);
    if (existing == null) return;

    final activities = List<ActivityType>.from(existing.activities);
    activities.remove(type);

    // Clean up associated data
    if (type == ActivityType.gym && existing.sessionId != null) {
      await deleteSession(existing.sessionId!);
    }
    if (type == ActivityType.run && existing.runLogId != null) {
      await deleteRunLog(existing.runLogId!);
    }

    if (activities.isEmpty) {
      await _storage.deleteDayLog(existing.id);
      _dayLogs.removeWhere((d) => d.id == existing.id);
    } else {
      final updated = existing.copyWith(activities: activities);
      await _storage.saveDayLog(updated);
      final index = _dayLogs.indexWhere((d) => d.id == existing.id);
      if (index >= 0) _dayLogs[index] = updated;
    }
    notifyListeners();
  }

  /// Delete a run log
  Future<void> deleteRunLog(String id) async {
    await _storage.deleteRunLog(id);
    _runLogs.removeWhere((r) => r.id == id);
  }

  /// Delete a workout session
  Future<void> deleteSession(String id) async {
    await _storage.deleteSession(id);
    _sessions.removeWhere((s) => s.id == id);
  }

  /// Add a gym session to a day
  Future<void> addGymSession(
    DateTime date,
    WorkoutSession session,
    ExerciseProvider exerciseProvider,
  ) async {
    await _storage.saveSession(session);
    _sessions.add(session);

    // Update exercise history
    for (var exerciseId in session.performance.keys) {
      final sets = session.performance[exerciseId]!;
      final entries = sets.map((s) {
        return ExerciseHistoryEntry(
          date: session.date,
          weightLbs: s.weightLbs,
          weightKg: s.weightKg,
          reps: s.reps,
          sessionId: session.id,
        );
      }).toList();
      await exerciseProvider.addHistoryEntries(exerciseId, entries);
    }

    final existing = getDayLogForDate(date);
    if (existing != null) {
      final activities = List<ActivityType>.from(existing.activities);
      if (!activities.contains(ActivityType.gym)) {
        activities.add(ActivityType.gym);
      }
      final updated = existing.copyWith(
        activities: activities,
        sessionId: session.id,
      );
      await _storage.saveDayLog(updated);
      final index = _dayLogs.indexWhere((d) => d.id == existing.id);
      if (index >= 0) _dayLogs[index] = updated;
    } else {
      final log = DayLog(
        id: _uuid.v4(),
        date: DateTime(date.year, date.month, date.day),
        activities: [ActivityType.gym],
        sessionId: session.id,
      );
      await _storage.saveDayLog(log);
      _dayLogs.add(log);
    }
    notifyListeners();
    _rescheduleNotifications();
  }

  Future<void> updateGymSession(
    WorkoutSession session,
    ExerciseProvider exerciseProvider,
  ) async {
    await _storage.saveSession(session);
    final index = _sessions.indexWhere((s) => s.id == session.id);
    if (index >= 0) _sessions[index] = session;

    // Update exercise history
    for (var exerciseId in session.performance.keys) {
      final sets = session.performance[exerciseId]!;
      final entries = sets.map((s) {
        return ExerciseHistoryEntry(
          date: session.date,
          weightLbs: s.weightLbs,
          weightKg: s.weightKg,
          reps: s.reps,
          sessionId: session.id,
        );
      }).toList();
      await exerciseProvider.updateHistory(exerciseId, session.id, entries);
    }

    notifyListeners();
    _rescheduleNotifications();
  }

  /// Add a run log to a day
  Future<void> addRunLog(RunLog runLog) async {
    await _storage.saveRunLog(runLog);
    _runLogs.add(runLog);

    final date = runLog.date;
    final existing = getDayLogForDate(date);
    if (existing != null) {
      final activities = List<ActivityType>.from(existing.activities);
      if (!activities.contains(ActivityType.run)) {
        activities.add(ActivityType.run);
      }
      final updated = existing.copyWith(
        activities: activities,
        runLogId: runLog.id,
      );
      await _storage.saveDayLog(updated);
      final index = _dayLogs.indexWhere((d) => d.id == existing.id);
      if (index >= 0) _dayLogs[index] = updated;
    } else {
      final log = DayLog(
        id: _uuid.v4(),
        date: DateTime(date.year, date.month, date.day),
        activities: [ActivityType.run],
        runLogId: runLog.id,
      );
      await _storage.saveDayLog(log);
      _dayLogs.add(log);
    }
    notifyListeners();
    _rescheduleNotifications();
  }

  // --- Stats ---
  int get totalGymDays => _dayLogs.where((d) => d.hasGym).length;

  int get totalRunDays => _dayLogs.where((d) => d.hasRun).length;

  int get totalSwimDays => _dayLogs.where((d) => d.hasSwim).length;

  /// Gym days in current week (Mon-Sun)
  int gymDaysThisWeek() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeek = DateTime(monday.year, monday.month, monday.day);
    return _dayLogs
        .where(
          (d) =>
              d.hasGym &&
              d.date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              d.date.isBefore(startOfWeek.add(const Duration(days: 7))),
        )
        .length;
  }

  /// Current streak of consecutive days with any gym activity
  int get currentStreak {
    if (_dayLogs.isEmpty) return 0;

    final gymDays =
        _dayLogs
            .where((d) => d.hasGym)
            .map((d) => DateTime(d.date.year, d.date.month, d.date.day))
            .toList()
          ..sort((a, b) => b.compareTo(a)); // newest first

    if (gymDays.isEmpty) return 0;

    int streak = 0;
    var checkDate = DateTime.now();
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    // If today isn't a gym day, start from yesterday
    if (!gymDays.contains(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (gymDays.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Best streak ever
  int get bestStreak {
    if (_dayLogs.isEmpty) return 0;

    final gymDays =
        _dayLogs
            .where((d) => d.hasGym)
            .map((d) => DateTime(d.date.year, d.date.month, d.date.day))
            .toSet()
            .toList()
          ..sort();

    if (gymDays.isEmpty) return 0;

    int best = 1;
    int current = 1;

    for (int i = 1; i < gymDays.length; i++) {
      if (gymDays[i].difference(gymDays[i - 1]).inDays == 1) {
        current++;
        if (current > best) best = current;
      } else {
        current = 1;
      }
    }

    return best;
  }

  /// Runs this month count
  int get runsThisMonth {
    final now = DateTime.now();
    return _dayLogs
        .where(
          (d) =>
              d.hasRun && d.date.year == now.year && d.date.month == now.month,
        )
        .length;
  }

  /// Total run distance this month
  double get totalRunDistanceThisMonth {
    final now = DateTime.now();
    return _runLogs
        .where((r) => r.date.year == now.year && r.date.month == now.month)
        .fold(0.0, (sum, r) => sum + r.distanceKm);
  }

  /// Average run pace this month (min/km)
  double get avgRunPaceThisMonth {
    final now = DateTime.now();
    final monthRuns = _runLogs
        .where(
          (r) =>
              r.date.year == now.year &&
              r.date.month == now.month &&
              r.distanceKm > 0,
        )
        .toList();
    if (monthRuns.isEmpty) return 0;
    return monthRuns.fold(0.0, (sum, r) => sum + r.paceMinPerKm) /
        monthRuns.length;
  }

  /// Swims this month
  int get swimsThisMonth {
    final now = DateTime.now();
    return _dayLogs
        .where(
          (d) =>
              d.hasSwim && d.date.year == now.year && d.date.month == now.month,
        )
        .length;
  }

  /// Weekly adherence for last 4 weeks (returns list of gym days per week)
  List<int> weeklyAdherenceLastFourWeeks() {
    final now = DateTime.now();
    final result = <int>[];
    for (int week = 3; week >= 0; week--) {
      final startOfWeek = now.subtract(
        Duration(days: now.weekday - 1 + (week * 7)),
      );
      final start = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );
      final end = start.add(const Duration(days: 7));
      final count = _dayLogs
          .where(
            (d) =>
                d.hasGym &&
                d.date.isAfter(start.subtract(const Duration(days: 1))) &&
                d.date.isBefore(end),
          )
          .length;
      result.add(count);
    }
    return result;
  }

  // --- Helpers ---
  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  WorkoutSession? getSessionForDate(DateTime date) {
    final dayLog = getDayLogForDate(date);
    if (dayLog?.sessionId == null) return null;
    return _storage.getSession(dayLog!.sessionId!);
  }

  RunLog? getRunLogForDate(DateTime date) {
    final dayLog = getDayLogForDate(date);
    if (dayLog?.runLogId == null) return null;
    return _storage.getRunLog(dayLog!.runLogId!);
  }

  // --- Routines ---
  Future<void> createRoutine(WorkoutRoutine routine) async {
    await _storage.saveRoutine(routine);
    _routines.add(routine);
    notifyListeners();
  }

  Future<void> deleteRoutine(String id) async {
    await _storage.deleteRoutine(id);
    _routines.removeWhere((r) => r.id == id);
    notifyListeners();
  }
}
