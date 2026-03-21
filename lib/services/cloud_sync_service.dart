import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'storage_service.dart';

/// Service to backup and restore all local Hive data to/from Firebase Firestore.
class CloudSyncService {
  final StorageService _storage;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CloudSyncService(this._storage);

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  static const String _lastAutoBackupKey = 'lastAutoBackupMillis';
  static const int _autoBackupIntervalDays = 7;

  /// Performs a backup if the user is signed in and 7+ days have passed
  /// since the last auto-backup. Runs silently — does not throw.
  Future<void> autoBackupIfNeeded() async {
    try {
      final uid = _uid;
      if (uid == null) {
        debugPrint('[AutoBackup] Skipped — user not signed in');
        return;
      }

      final lastMillis = _storage.settingsBox.get(_lastAutoBackupKey) as int?;
      final now = DateTime.now();

      if (lastMillis != null) {
        final lastBackup = DateTime.fromMillisecondsSinceEpoch(lastMillis);
        final daysSince = now.difference(lastBackup).inDays;
        if (daysSince < _autoBackupIntervalDays) {
          debugPrint('[AutoBackup] Skipped — last backup was $daysSince day(s) ago');
          return;
        }
      }

      debugPrint('[AutoBackup] Starting weekly auto-backup...');
      final counts = await backup();
      await _storage.settingsBox.put(_lastAutoBackupKey, now.millisecondsSinceEpoch);
      debugPrint('[AutoBackup] Complete: $counts');
    } catch (e, st) {
      debugPrint('[AutoBackup] Failed (non-fatal): $e\n$st');
    }
  }

  /// Returns the last auto-backup time, or null if never backed up automatically.
  DateTime? get lastAutoBackupTime {
    final millis = _storage.settingsBox.get(_lastAutoBackupKey) as int?;
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  /// Upload all local data to Firestore under users/{uid}/
  Future<Map<String, int>> backup() async {
    final uid = _uid;
    if (uid == null) throw Exception('Not signed in');

    final userDoc = _firestore.collection('users').doc(uid);
    final counts = <String, int>{};

    // --- Day Logs ---
    final dayLogs = _storage.dayLogsBox.values
        .map(
          (d) => {
            'id': d.id,
            'dateKey': d.dateKey,
            'date': d.date.toIso8601String(),
            'activities': d.activities.map((a) => a.index).toList(),
          },
        )
        .toList();
    await userDoc.set({'dayLogs': dayLogs}, SetOptions(merge: true));
    counts['dayLogs'] = dayLogs.length;

    // --- Workout Sessions ---
    final sessions = _storage.sessionsBox.values
        .map(
          (s) => {
            'id': s.id,
            'date': s.date.toIso8601String(),
            'targetMuscleGroups': s.targetMuscleGroups,
            'exerciseIds': s.exerciseIds,
            'completed': s.completed,
            'performance': s.performance.map(
              (key, sets) => MapEntry(
                key,
                sets
                    .map(
                      (ws) => {
                        'weightLbs': ws.weightLbs,
                        'weightKg': ws.weightKg,
                        'reps': ws.reps,
                      },
                    )
                    .toList(),
              ),
            ),
          },
        )
        .toList();
    await userDoc.set({'workoutSessions': sessions}, SetOptions(merge: true));
    counts['sessions'] = sessions.length;

    // --- Run Logs ---
    final runLogs = _storage.runLogsBox.values
        .map(
          (r) => {
            'id': r.id,
            'date': r.date.toIso8601String(),
            'distanceKm': r.distanceKm,
            'durationSeconds': r.durationSeconds,
            'elevationGain': r.elevationGain,
            'source': r.source,
            'notes': r.notes,
          },
        )
        .toList();
    await userDoc.set({'runLogs': runLogs}, SetOptions(merge: true));
    counts['runLogs'] = runLogs.length;

    // --- Sleep Logs ---
    final sleepLogs = _storage.sleepLogsBox.values
        .map(
          (s) => {
            'id': s.id,
            'date': s.date.toIso8601String(),
            'bedtime': s.bedtime.toIso8601String(),
            'wakeTime': s.wakeTime.toIso8601String(),
            'avoidedScreentime': s.avoidedScreentime,
            'quality': s.quality,
            'mood': s.mood,
            'notes': s.notes,
          },
        )
        .toList();
    await userDoc.set({'sleepLogs': sleepLogs}, SetOptions(merge: true));
    counts['sleepLogs'] = sleepLogs.length;

    // --- Body Metrics ---
    final bodyMetrics = _storage.bodyMetricsBox.values
        .map(
          (m) => {
            'id': m.id,
            'date': m.date.toIso8601String(),
            'weight': m.weight,
            'bodyFatPercentage': m.bodyFatPercentage,
            'basalMetabolicRate': m.basalMetabolicRate,
            'visceralFatLevel': m.visceralFatLevel,
            'protein': m.protein,
            'totalBodyWater': m.totalBodyWater,
            'bodyFatMass': m.bodyFatMass,
            'recommendedCalorieIntake': m.recommendedCalorieIntake,
          },
        )
        .toList();
    await userDoc.set({'bodyMetrics': bodyMetrics}, SetOptions(merge: true));
    counts['bodyMetrics'] = bodyMetrics.length;

    // --- Profile ---
    if (_storage.profileBox.isNotEmpty) {
      final p = _storage.profileBox.values.first;
      await userDoc.set({
        'profile': {
          'name': p.name,
          'age': p.age,
          'height': p.height,
          'weight': p.weight,
          'gender': p.gender,
          'birthDate': p.birthDate?.toIso8601String(),
          'weeklyGoal': p.weeklyGoal,
          'weightUnit': p.weightUnit,
        },
      }, SetOptions(merge: true));
    }

    // --- Routines ---
    final routines = _storage.routinesBox.values
        .map(
          (r) => {
            'id': r.id,
            'name': r.name,
            'exerciseIds': r.exerciseIds,
            'color': r.color,
            'targetMuscles': r.targetMuscles,
          },
        )
        .toList();
    await userDoc.set({'routines': routines}, SetOptions(merge: true));
    counts['routines'] = routines.length;

    // --- Achievements ---
    final achievements = _storage.achievementsBox.values
        .map(
          (a) => {
            'id': a.id,
            'badgeId': a.badgeId,
            'dateUnlocked': a.dateUnlocked.toIso8601String(),
            'hasViewed': a.hasViewed,
          },
        )
        .toList();
    await userDoc.set({'achievements': achievements}, SetOptions(merge: true));
    counts['achievements'] = achievements.length;

    // Store backup timestamp (remote + local auto-backup timer)
    await userDoc.set({
      'lastBackup': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _storage.settingsBox.put(
      _lastAutoBackupKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    return counts;
  }

  /// Get the timestamp of the last backup, or null.
  Future<DateTime?> getLastBackupTime() async {
    final uid = _uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null || data['lastBackup'] == null) return null;

    return (data['lastBackup'] as Timestamp).toDate();
  }

  /// Download data from Firestore and return a summary of what was found.
  /// Does NOT overwrite local data — just returns counts for the user to confirm.
  Future<Map<String, int>?> peekCloudData() async {
    final uid = _uid;
    if (uid == null) return null;

    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;

    return {
      'dayLogs': (data['dayLogs'] as List?)?.length ?? 0,
      'sessions': (data['workoutSessions'] as List?)?.length ?? 0,
      'runLogs': (data['runLogs'] as List?)?.length ?? 0,
      'sleepLogs': (data['sleepLogs'] as List?)?.length ?? 0,
      'bodyMetrics': (data['bodyMetrics'] as List?)?.length ?? 0,
      'routines': (data['routines'] as List?)?.length ?? 0,
      'achievements': (data['achievements'] as List?)?.length ?? 0,
    };
  }
}
