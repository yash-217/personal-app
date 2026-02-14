import 'package:hive_ce/hive_ce.dart';

part 'run_log.g.dart';

@HiveType(typeId: 4)
class RunLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final double distanceKm;

  @HiveField(3)
  final int durationSeconds;

  @HiveField(4)
  final double? elevationGain;

  @HiveField(5)
  final String source; // 'manual' or 'strava'

  @HiveField(6)
  final String? notes;

  RunLog({
    required this.id,
    required this.date,
    required this.distanceKm,
    required this.durationSeconds,
    this.elevationGain,
    this.source = 'manual',
    this.notes,
  });

  /// Pace in minutes per km
  double get paceMinPerKm {
    if (distanceKm <= 0) return 0;
    return (durationSeconds / 60) / distanceKm;
  }

  /// Formatted pace like "5:41"
  String get formattedPace {
    final pace = paceMinPerKm;
    final minutes = pace.floor();
    final seconds = ((pace - minutes) * 60).round();
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Formatted duration like "28:34" or "1:02:15"
  String get formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    final seconds = durationSeconds % 60;
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  RunLog copyWith({
    String? id,
    DateTime? date,
    double? distanceKm,
    int? durationSeconds,
    double? elevationGain,
    String? source,
    String? notes,
  }) {
    return RunLog(
      id: id ?? this.id,
      date: date ?? this.date,
      distanceKm: distanceKm ?? this.distanceKm,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      elevationGain: elevationGain ?? this.elevationGain,
      source: source ?? this.source,
      notes: notes ?? this.notes,
    );
  }
}
