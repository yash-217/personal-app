import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/achievement.dart';
import '../models/day_log.dart';
import '../models/sleep_log.dart';
import '../models/run_log.dart';
import '../models/activity_log.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

/// Defines a badge that can be unlocked.
class BadgeDefinition {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final String category; // 'consistency', 'volume', 'endurance', 'recovery'

  const BadgeDefinition({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.category,
  });
}

class AchievementProvider extends ChangeNotifier {
  static const _uuid = Uuid();
  final StorageService _storage;
  List<Achievement> _achievements = [];

  /// Newly unlocked badge IDs from the last evaluation (for celebration UI).
  List<String> _newlyUnlocked = [];

  AchievementProvider(this._storage) {
    _loadData();
  }

  // ---------------------------------------------------------------------------
  // Badge Registry
  // ---------------------------------------------------------------------------
  static const List<BadgeDefinition> allBadges = [
    // Consistency
    BadgeDefinition(
      id: 'first_workout',
      emoji: '💪',
      title: 'First Step',
      description: 'Log your first workout',
      category: 'consistency',
    ),
    BadgeDefinition(
      id: 'streak_3',
      emoji: '🔥',
      title: 'On Fire',
      description: '3-day workout streak',
      category: 'consistency',
    ),
    BadgeDefinition(
      id: 'streak_7',
      emoji: '⚡',
      title: 'Unstoppable',
      description: '7-day workout streak',
      category: 'consistency',
    ),
    BadgeDefinition(
      id: 'streak_30',
      emoji: '🏆',
      title: 'Iron Will',
      description: '30-day workout streak',
      category: 'consistency',
    ),

    // Volume
    BadgeDefinition(
      id: 'gym_10',
      emoji: '🎯',
      title: 'Dedicated',
      description: '10 total gym sessions',
      category: 'volume',
    ),
    BadgeDefinition(
      id: 'gym_50',
      emoji: '🥇',
      title: 'Gym Rat',
      description: '50 total gym sessions',
      category: 'volume',
    ),

    // Endurance
    BadgeDefinition(
      id: 'first_run',
      emoji: '🏃',
      title: 'First Run',
      description: 'Log your first run',
      category: 'endurance',
    ),
    BadgeDefinition(
      id: 'run_5k',
      emoji: '🏅',
      title: '5K Finisher',
      description: 'Run 5 km+ in a single session',
      category: 'endurance',
    ),

    // Recovery
    BadgeDefinition(
      id: 'first_sleep',
      emoji: '😴',
      title: 'Sleep Tracker',
      description: 'Log your first sleep entry',
      category: 'recovery',
    ),
    BadgeDefinition(
      id: 'sleep_streak_7',
      emoji: '🌙',
      title: 'Sleep Routine',
      description: 'Log sleep 7 days in a row',
      category: 'recovery',
    ),
    BadgeDefinition(
      id: 'sleep_quality_7',
      emoji: '💤',
      title: 'Sweet Dreams',
      description: 'Avg sleep quality ≥ 5 for 7 consecutive days',
      category: 'recovery',
    ),
    BadgeDefinition(
      id: 'screen_free_7',
      emoji: '📵',
      title: 'Digital Detox',
      description: 'Avoid screentime 7 days in a row',
      category: 'recovery',
    ),
    BadgeDefinition(
      id: 'sleep_8h_streak_5',
      emoji: '🛌',
      title: 'Full Rest',
      description: 'Sleep 8+ hours for 5 consecutive days',
      category: 'recovery',
    ),
    BadgeDefinition(
      id: 'early_bird',
      emoji: '🌅',
      title: 'Early Bird',
      description: '5 workouts logged before noon',
      category: 'consistency',
    ),

    // Endurance (additional)
    BadgeDefinition(
      id: 'run_10k',
      emoji: '🏅',
      title: '10K Finisher',
      description: 'Run 10 km+ in a single session',
      category: 'endurance',
    ),
    BadgeDefinition(
      id: 'run_total_50k',
      emoji: '🗺️',
      title: 'Explorer',
      description: '50 km total running distance',
      category: 'endurance',
    ),

    // Volume (additional)
    BadgeDefinition(
      id: 'gym_100',
      emoji: '💎',
      title: 'Century Club',
      description: '100 total gym sessions',
      category: 'volume',
    ),

    // Steps & Walking
    BadgeDefinition(
      id: 'steps_10k_first',
      emoji: '🚶',
      title: 'Stepper',
      description: 'Take 10,000 steps in a single day',
      category: 'consistency',
    ),
    BadgeDefinition(
      id: 'steps_streak_5',
      emoji: '🏃‍♂️',
      title: 'Stride Master',
      description: 'Reach step goal 5 days in a row',
      category: 'consistency',
    ),
    BadgeDefinition(
      id: 'walk_total_100k',
      emoji: '🗺️',
      title: 'Voyager',
      description: 'Walk 100 km total distance',
      category: 'endurance',
    ),

    // Sports
    BadgeDefinition(
      id: 'sport_first_swim',
      emoji: '🏊',
      title: 'Water Born',
      description: 'Log your first swim activity',
      category: 'volume',
    ),
    BadgeDefinition(
      id: 'sport_football_5',
      emoji: '⚽',
      title: 'Playmaker',
      description: 'Log 5 football sessions',
      category: 'volume',
    ),
    BadgeDefinition(
      id: 'sport_tt_5',
      emoji: '🏓',
      title: 'Ping Pong Master',
      description: 'Log 5 Table Tennis sessions',
      category: 'volume',
    ),
    BadgeDefinition(
      id: 'sport_badminton_5',
      emoji: '🏸',
      title: 'Smash Champion',
      description: 'Log 5 Badminton sessions',
      category: 'volume',
    ),

    // Plank
    BadgeDefinition(
      id: 'plank_first',
      emoji: '🧘',
      title: 'First Plank',
      description: 'Log your first plank hold',
      category: 'consistency',
    ),
    BadgeDefinition(
      id: 'plank_60s',
      emoji: '⏱️',
      title: 'One Minute Plank',
      description: 'Hold a plank for 60+ seconds',
      category: 'endurance',
    ),
    BadgeDefinition(
      id: 'plank_streak_7',
      emoji: '🔥',
      title: 'Plank Week',
      description: 'Log planks 7 days in a row',
      category: 'consistency',
    ),
    BadgeDefinition(
      id: 'plank_120s',
      emoji: '💎',
      title: 'Plank Master',
      description: 'Hold a plank for 120+ seconds',
      category: 'endurance',
    ),

    // Pushups
    BadgeDefinition(
      id: 'pushups_first',
      emoji: '💪',
      title: 'First Set',
      description: 'Log your first pushup set',
      category: 'consistency',
    ),
    BadgeDefinition(
      id: 'pushups_25',
      emoji: '🎯',
      title: '25 Club',
      description: 'Do 25+ pushups in a single set',
      category: 'endurance',
    ),
    BadgeDefinition(
      id: 'pushups_50',
      emoji: '🏆',
      title: 'Half Century',
      description: 'Do 50+ pushups in a single set',
      category: 'endurance',
    ),
    BadgeDefinition(
      id: 'pushups_streak_7',
      emoji: '🔥',
      title: 'Pushup Week',
      description: 'Log pushups 7 days in a row',
      category: 'consistency',
    ),
    BadgeDefinition(
      id: 'pushups_total_1000',
      emoji: '🗺️',
      title: 'Thousand Reps',
      description: '1,000 total pushups logged',
      category: 'volume',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------
  List<Achievement> get achievements => _achievements;
  List<String> get newlyUnlocked => _newlyUnlocked;

  bool isUnlocked(String badgeId) =>
      _achievements.any((a) => a.badgeId == badgeId);

  Achievement? getAchievement(String badgeId) {
    try {
      return _achievements.firstWhere((a) => a.badgeId == badgeId);
    } catch (_) {
      return null;
    }
  }

  int get unlockedCount => _achievements.length;
  int get totalCount => allBadges.length;

  List<BadgeDefinition> get unlockedBadges =>
      allBadges.where((b) => isUnlocked(b.id)).toList();

  List<BadgeDefinition> get lockedBadges =>
      allBadges.where((b) => !isUnlocked(b.id)).toList();

  /// Clear the newly-unlocked list (call after the celebration UI is shown).
  void clearNewlyUnlocked() {
    _newlyUnlocked = [];
  }

  /// Mark a specific achievement as viewed.
  Future<void> markViewed(String badgeId) async {
    final achievement = getAchievement(badgeId);
    if (achievement != null && !achievement.hasViewed) {
      achievement.hasViewed = true;
      await _storage.saveAchievement(achievement);
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Data loading
  // ---------------------------------------------------------------------------
  void _loadData() {
    _achievements = _storage.getAllAchievements();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Evaluation Engine
  // ---------------------------------------------------------------------------
  /// Evaluates all badge rules against the provided data and unlocks any
  /// newly earned badges. Call this after any workout/sleep data change.
  Future<void> evaluate({
    required List<DayLog> dayLogs,
    required List<SleepLog> sleepLogs,
    required List<RunLog> runLogs,
    List<ActivityLog>? activityLogs,
  }) async {
    _newlyUnlocked = [];

    // --- Consistency ---
    final gymDays = dayLogs.where((d) => d.hasGym).toList();

    // First workout
    if (gymDays.isNotEmpty) {
      await _tryUnlock('first_workout');
    }

    // Gym session counts
    if (gymDays.length >= 10) await _tryUnlock('gym_10');
    if (gymDays.length >= 50) await _tryUnlock('gym_50');

    // Workout streak
    final streak = _calculateStreak(gymDays);
    if (streak >= 3) await _tryUnlock('streak_3');
    if (streak >= 7) await _tryUnlock('streak_7');
    if (streak >= 30) await _tryUnlock('streak_30');

    // Early bird (workouts logged with a session date before noon)
    final earlyWorkouts = dayLogs
        .where((d) => d.hasGym && d.date.hour < 12)
        .length;
    if (earlyWorkouts >= 5) await _tryUnlock('early_bird');

    // --- Endurance ---
    final runDays = dayLogs.where((d) => d.hasRun).toList();
    if (runDays.isNotEmpty) await _tryUnlock('first_run');

    // 5K / 10K in a single run
    final has5k = runLogs.any((r) => r.distanceKm >= 5.0);
    if (has5k) await _tryUnlock('run_5k');
    final has10k = runLogs.any((r) => r.distanceKm >= 10.0);
    if (has10k) await _tryUnlock('run_10k');

    // Total 50K running distance
    final totalRunKm = runLogs.fold(0.0, (sum, r) => sum + r.distanceKm);
    if (totalRunKm >= 50.0) await _tryUnlock('run_total_50k');

    // --- Volume (additional) ---
    if (gymDays.length >= 100) await _tryUnlock('gym_100');

    // --- Recovery ---
    if (sleepLogs.isNotEmpty) await _tryUnlock('first_sleep');

    // Sleep streak
    final sleepStreak = _calculateSleepStreak(sleepLogs);
    if (sleepStreak >= 7) await _tryUnlock('sleep_streak_7');

    // Sweet Dreams: avg quality >= 5 for 7 consecutive days
    final qualityStreak = _calculateQualityStreak(sleepLogs, 5, 7);
    if (qualityStreak >= 7) await _tryUnlock('sleep_quality_7');

    // Digital Detox: avoided screentime 7 days in a row
    final screenStreak = _calculateScreenFreeStreak(sleepLogs);
    if (screenStreak >= 7) await _tryUnlock('screen_free_7');

    // Full Rest: 8+ hours for 5 consecutive days
    final fullRestStreak = _calculateDurationStreak(sleepLogs, 480, 5);
    if (fullRestStreak >= 5) await _tryUnlock('sleep_8h_streak_5');

    // --- Steps & Walking ---
    // 10k steps in a single day
    final has10kSteps = dayLogs.any((d) => (d.steps ?? 0) >= 10000);
    if (has10kSteps) await _tryUnlock('steps_10k_first');

    // Step goal streak (5 days in a row reaching the daily step goal)
    final stepGoal = StorageService.instance.profileBox.values.isNotEmpty
        ? (StorageService.instance.profileBox.values.first.dailyStepGoal ?? 10000)
        : 10000;
    final stepGoalStreak = _calculateStepGoalStreak(dayLogs, stepGoal);
    if (stepGoalStreak >= 5) await _tryUnlock('steps_streak_5');

    // Total 100km walked
    final totalWalkKm = dayLogs.fold(
      0.0, (sum, d) => sum + (d.walkDistanceKm ?? 0.0),
    );
    if (totalWalkKm >= 100.0) await _tryUnlock('walk_total_100k');

    // --- Sports ---
    final swimDays = dayLogs.where((d) => d.hasSwim).toList();
    if (swimDays.isNotEmpty) await _tryUnlock('sport_first_swim');

    final footballDays = dayLogs.where((d) => d.hasFootball).length;
    if (footballDays >= 5) await _tryUnlock('sport_football_5');

    final ttDays = dayLogs.where((d) => d.hasTT).length;
    if (ttDays >= 5) await _tryUnlock('sport_tt_5');

    final badmintonDays = dayLogs.where((d) => d.hasBadminton).length;
    if (badmintonDays >= 5) await _tryUnlock('sport_badminton_5');

    // --- Plank ---
    final plankDays = dayLogs.where((d) => (d.plankSeconds ?? 0) > 0).toList();
    if (plankDays.isNotEmpty) await _tryUnlock('plank_first');
    if (plankDays.any((d) => d.plankSeconds! >= 60)) await _tryUnlock('plank_60s');
    if (plankDays.any((d) => d.plankSeconds! >= 120)) await _tryUnlock('plank_120s');
    final plankStreak = _calculateDayLogStreak(dayLogs, (d) => (d.plankSeconds ?? 0) > 0);
    if (plankStreak >= 7) await _tryUnlock('plank_streak_7');

    // --- Pushups ---
    final pushupDays = dayLogs.where((d) => (d.pushupsCount ?? 0) > 0).toList();
    if (pushupDays.isNotEmpty) await _tryUnlock('pushups_first');
    if (pushupDays.any((d) => d.pushupsCount! >= 25)) await _tryUnlock('pushups_25');
    if (pushupDays.any((d) => d.pushupsCount! >= 50)) await _tryUnlock('pushups_50');
    final pushupStreak = _calculateDayLogStreak(dayLogs, (d) => (d.pushupsCount ?? 0) > 0);
    if (pushupStreak >= 7) await _tryUnlock('pushups_streak_7');
    final totalPushups = dayLogs.fold(0, (sum, d) => sum + (d.pushupsCount ?? 0));
    if (totalPushups >= 1000) await _tryUnlock('pushups_total_1000');

    if (_newlyUnlocked.isNotEmpty) {
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  Future<void> _tryUnlock(String badgeId) async {
    if (isUnlocked(badgeId)) return;

    final achievement = Achievement(
      id: _uuid.v4(),
      badgeId: badgeId,
      dateUnlocked: DateTime.now(),
    );
    await _storage.saveAchievement(achievement);
    _achievements.add(achievement);
    _newlyUnlocked.add(badgeId);

    // Fire an instant notification
    final badge = allBadges.firstWhere((b) => b.id == badgeId);
    NotificationService().showAchievementNotification(
      title: '🏆 Achievement Unlocked!',
      body: '${badge.emoji} ${badge.title} — ${badge.description}',
    );
  }

  /// Calculate the best / current consecutive gym-day streak.
  int _calculateStreak(List<DayLog> gymDays) {
    if (gymDays.isEmpty) return 0;

    final dates =
        gymDays
            .map((d) => DateTime(d.date.year, d.date.month, d.date.day))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a)); // newest first

    int streak = 0;
    var checkDate = DateTime.now();
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    // If today isn't a gym day, start from yesterday
    if (!dates.contains(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (dates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Calculate consecutive days with a sleep log.
  int _calculateSleepStreak(List<SleepLog> sleepLogs) {
    if (sleepLogs.isEmpty) return 0;

    final dates =
        sleepLogs
            .map((l) => DateTime(l.date.year, l.date.month, l.date.day))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    int streak = 0;
    var checkDate = DateTime.now();
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    if (!dates.contains(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (dates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Consecutive days where avg quality >= [minQuality], returns max streak.
  int _calculateQualityStreak(List<SleepLog> logs, int minQuality, int target) {
    if (logs.isEmpty) return 0;
    final sorted = List<SleepLog>.from(logs)
      ..sort((a, b) => a.date.compareTo(b.date));

    int streak = 0;
    int best = 0;
    for (final log in sorted) {
      if (log.quality >= minQuality) {
        streak++;
        if (streak > best) best = streak;
      } else {
        streak = 0;
      }
    }
    return best;
  }

  /// Consecutive days where screentime was avoided.
  int _calculateScreenFreeStreak(List<SleepLog> logs) {
    if (logs.isEmpty) return 0;
    final sorted = List<SleepLog>.from(logs)
      ..sort((a, b) => a.date.compareTo(b.date));

    int streak = 0;
    int best = 0;
    for (final log in sorted) {
      if (log.avoidedScreentime) {
        streak++;
        if (streak > best) best = streak;
      } else {
        streak = 0;
      }
    }
    return best;
  }

  /// Consecutive days where sleep duration >= [minMinutes].
  int _calculateDurationStreak(List<SleepLog> logs, int minMinutes, int target) {
    if (logs.isEmpty) return 0;
    final sorted = List<SleepLog>.from(logs)
      ..sort((a, b) => a.date.compareTo(b.date));

    int streak = 0;
    int best = 0;
    for (final log in sorted) {
      if (log.durationMinutes >= minMinutes) {
        streak++;
        if (streak > best) best = streak;
      } else {
        streak = 0;
      }
    }
    return best;
  }

  /// Consecutive days where step count >= [goal], returns current streak.
  int _calculateStepGoalStreak(List<DayLog> dayLogs, int goal) {
    if (dayLogs.isEmpty) return 0;

    final daysWithSteps = dayLogs
        .where((d) => (d.steps ?? 0) > 0)
        .toList();

    final dates = daysWithSteps
        .where((d) => (d.steps ?? 0) >= goal)
        .map((d) => DateTime(d.date.year, d.date.month, d.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    if (dates.isEmpty) return 0;

    int streak = 0;
    var checkDate = DateTime.now();
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    if (!dates.contains(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (dates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Generic DayLog streak calculator. Counts consecutive days (from today
  /// backwards) where [test] returns true.
  int _calculateDayLogStreak(List<DayLog> dayLogs, bool Function(DayLog) test) {
    final dates = dayLogs
        .where(test)
        .map((d) => DateTime(d.date.year, d.date.month, d.date.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a)); // newest first

    if (dates.isEmpty) return 0;

    int streak = 0;
    var checkDate = DateTime.now();
    checkDate = DateTime(checkDate.year, checkDate.month, checkDate.day);

    if (!dates.contains(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (dates.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }
}
