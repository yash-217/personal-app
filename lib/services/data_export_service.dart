import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'storage_service.dart';

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

    // Import counts for summary
    counts['dayLogs'] = (data['dayLogs'] as List?)?.length ?? 0;
    counts['workoutSessions'] = (data['workoutSessions'] as List?)?.length ?? 0;
    counts['runLogs'] = (data['runLogs'] as List?)?.length ?? 0;
    counts['sleepLogs'] = (data['sleepLogs'] as List?)?.length ?? 0;
    counts['bodyMetrics'] = (data['bodyMetrics'] as List?)?.length ?? 0;
    counts['routines'] = (data['routines'] as List?)?.length ?? 0;

    return counts;
  }
}
