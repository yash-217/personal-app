import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'storage_service.dart';
import '../models/day_log.dart';
import '../models/workout_session.dart';
import '../models/run_log.dart';
import '../models/sleep_log.dart';
import '../models/body_metrics.dart';
import '../models/workout_routine.dart';
import '../models/user_profile.dart';

/// Service to export all Hive data as JSON and import it back.
class DataExportService {
  final StorageService _storage;

  DataExportService(this._storage);

  /// Export all data as a JSON string.
  String exportToJson() {
    final data = <String, dynamic>{
      'exportDate': DateTime.now().toIso8601String(),
      'version': 1,
      'dayLogs': _storage.dayLogsBox.values
          .map(
            (d) => {
              'id': d.id,
              'dateKey': d.dateKey,
              'date': d.date.toIso8601String(),
              'activities': d.activities.map((a) => a.index).toList(),
            },
          )
          .toList(),
      'workoutSessions': _storage.sessionsBox.values
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
          .toList(),
      'runLogs': _storage.runLogsBox.values
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
          .toList(),
      'sleepLogs': _storage.sleepLogsBox.values
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
          .toList(),
      'bodyMetrics': _storage.bodyMetricsBox.values
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
          .toList(),
      'profile': _storage.profileBox.isNotEmpty
          ? (() {
              final p = _storage.profileBox.values.first;
              return {
                'name': p.name,
                'height': p.height,
                'weight': p.weight,
                'birthDate': p.birthDate?.toIso8601String(),
                'weeklyGoal': p.weeklyGoal,
                'weightUnit': p.weightUnit,
              };
            })()
          : null,
      'routines': _storage.routinesBox.values
          .map(
            (r) => {
              'id': r.id,
              'name': r.name,
              'exerciseIds': r.exerciseIds,
              'color': r.color,
              'targetMuscles': r.targetMuscles,
            },
          )
          .toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Export data to a JSON file and share it.
  Future<void> exportAndShare() async {
    final json = exportToJson();
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final file = File('${dir.path}/fitprint_backup_$timestamp.json');
    await file.writeAsString(json);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'FitPrint Backup',
        text: 'My FitPrint data backup',
      ),
    );
  }

  /// Import data from a user-selected JSON file.
  /// Returns a summary map of counts or null if cancelled/failed.
  Future<Map<String, int>?> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return null;

    final file = File(result.files.single.path!);
    final jsonStr = await file.readAsString();
    final data = json.decode(jsonStr) as Map<String, dynamic>;

    final counts = <String, int>{};

    // Day Logs
    final dayLogsList = data['dayLogs'] as List?;
    if (dayLogsList != null) {
      for (final item in dayLogsList) {
        final dl = DayLog(
          id: item['id'],
          date: DateTime.parse(item['date']),
          activities: (item['activities'] as List)
              .map((i) => ActivityType.values[i as int])
              .toList(),
        );
        await _storage.dayLogsBox.put(dl.id, dl);
      }
      counts['dayLogs'] = dayLogsList.length;
    }

    // Workout Sessions
    final sessionsList = data['workoutSessions'] as List?;
    if (sessionsList != null) {
      for (final item in sessionsList) {
        final perfData = item['performance'] as Map?;
        final perf = <String, List<WorkoutSet>>{};
        if (perfData != null) {
          for (final entry in perfData.entries) {
            perf[entry.key] = (entry.value as List)
                .map(
                  (s) => WorkoutSet(
                    weightLbs: (s['weightLbs'] as num).toDouble(),
                    weightKg: (s['weightKg'] as num).toDouble(),
                    reps: s['reps'] as int,
                  ),
                )
                .toList();
          }
        }
        final ws = WorkoutSession(
          id: item['id'],
          date: DateTime.parse(item['date']),
          targetMuscleGroups: List<String>.from(
            item['targetMuscleGroups'] ?? [],
          ),
          exerciseIds: List<String>.from(item['exerciseIds'] ?? []),
          completed: item['completed'] ?? false,
          performance: perf,
        );
        await _storage.sessionsBox.put(ws.id, ws);
      }
      counts['workoutSessions'] = sessionsList.length;
    }

    // Run Logs
    final runLogsList = data['runLogs'] as List?;
    if (runLogsList != null) {
      for (final item in runLogsList) {
        final rl = RunLog(
          id: item['id'],
          date: DateTime.parse(item['date']),
          distanceKm: (item['distanceKm'] as num).toDouble(),
          durationSeconds: item['durationSeconds'] as int,
          elevationGain: item['elevationGain'] != null
              ? (item['elevationGain'] as num).toDouble()
              : null,
          source: item['source'] ?? 'manual',
          notes: item['notes'],
        );
        await _storage.runLogsBox.put(rl.id, rl);
      }
      counts['runLogs'] = runLogsList.length;
    }

    // Sleep Logs
    final sleepLogsList = data['sleepLogs'] as List?;
    if (sleepLogsList != null) {
      for (final item in sleepLogsList) {
        final sl = SleepLog(
          id: item['id'],
          date: DateTime.parse(item['date']),
          bedtime: DateTime.parse(item['bedtime']),
          wakeTime: DateTime.parse(item['wakeTime']),
          avoidedScreentime: item['avoidedScreentime'] ?? false,
          quality: item['quality'] ?? 5,
          mood: item['mood'],
          notes: item['notes'],
        );
        await _storage.sleepLogsBox.put(sl.id, sl);
      }
      counts['sleepLogs'] = sleepLogsList.length;
    }

    // Body Metrics
    final bodyMetricsList = data['bodyMetrics'] as List?;
    if (bodyMetricsList != null) {
      for (final item in bodyMetricsList) {
        final bm = BodyMetrics(
          id: item['id'],
          date: DateTime.parse(item['date']),
          weight: (item['weight'] as num).toDouble(),
          bodyFatPercentage:
              (item['bodyFatPercentage'] as num?)?.toDouble() ?? 0,
          basalMetabolicRate:
              (item['basalMetabolicRate'] as num?)?.toDouble() ?? 0,
          visceralFatLevel: (item['visceralFatLevel'] as num?)?.toDouble() ?? 0,
          protein: (item['protein'] as num?)?.toDouble() ?? 0,
          totalBodyWater: (item['totalBodyWater'] as num?)?.toDouble() ?? 0,
          bodyFatMass: (item['bodyFatMass'] as num?)?.toDouble() ?? 0,
          recommendedCalorieIntake:
              (item['recommendedCalorieIntake'] as num?)?.toDouble() ?? 0,
        );
        await _storage.bodyMetricsBox.put(bm.id, bm);
      }
      counts['bodyMetrics'] = bodyMetricsList.length;
    }

    // Routines
    final routinesList = data['routines'] as List?;
    if (routinesList != null) {
      for (final item in routinesList) {
        final r = WorkoutRoutine(
          id: item['id'],
          name: item['name'],
          exerciseIds: List<String>.from(item['exerciseIds'] ?? []),
          color: item['color'] ?? 0xFF000000,
          targetMuscles: List<String>.from(item['targetMuscles'] ?? []),
        );
        await _storage.routinesBox.put(r.id, r);
      }
      counts['routines'] = routinesList.length;
    }

    // Profile
    final profileData = data['profile'] as Map?;
    if (profileData != null) {
      final p = UserProfile(
        name: profileData['name'] ?? '',
        age: profileData['age'] ?? 25,
        height: (profileData['height'] as num?)?.toDouble() ?? 170.0,
        weight: (profileData['weight'] as num?)?.toDouble() ?? 70.0,
        gender: profileData['gender'] ?? 'Other',
        birthDate: profileData['birthDate'] != null
            ? DateTime.parse(profileData['birthDate'])
            : null,
        weeklyGoal: profileData['weeklyGoal'] ?? 3,
        weightUnit: profileData['weightUnit'] ?? 'kg',
      );
      await _storage.profileBox.put('current', p);
    }

    return counts;
  }
}
