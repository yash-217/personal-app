import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/achievement.dart';
import '../models/day_log.dart';
import '../models/sleep_log.dart';
import '../models/run_log.dart';
import '../services/storage_service.dart';

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
      id: 'early_bird',
      emoji: '🌅',
      title: 'Early Bird',
      description: '5 workouts logged before noon',
      category: 'consistency',
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

    // 5K in a single run
    final has5k = runLogs.any((r) => r.distanceKm >= 5.0);
    if (has5k) await _tryUnlock('run_5k');

    // --- Recovery ---
    if (sleepLogs.isNotEmpty) await _tryUnlock('first_sleep');

    // Sleep streak
    final sleepStreak = _calculateSleepStreak(sleepLogs);
    if (sleepStreak >= 7) await _tryUnlock('sleep_streak_7');

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
}
