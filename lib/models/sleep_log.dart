import 'package:hive_ce/hive_ce.dart';

part 'sleep_log.g.dart';

@HiveType(typeId: 13)
class SleepLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final DateTime bedtime;

  @HiveField(3)
  final DateTime wakeTime;

  @HiveField(4)
  final bool avoidedScreentime;

  @HiveField(5)
  final int quality; // 1-10

  @HiveField(6)
  final String? mood;

  @HiveField(7)
  final String? notes;

  SleepLog({
    required this.id,
    required this.date,
    required this.bedtime,
    required this.wakeTime,
    this.avoidedScreentime = false,
    this.quality = 5,
    this.mood,
    this.notes,
  });

  /// Duration in minutes
  int get durationMinutes => wakeTime.difference(bedtime).inMinutes;

  /// Formatted duration like "7h 30m"
  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  SleepLog copyWith({
    String? id,
    DateTime? date,
    DateTime? bedtime,
    DateTime? wakeTime,
    bool? avoidedScreentime,
    int? quality,
    String? mood,
    String? notes,
  }) {
    return SleepLog(
      id: id ?? this.id,
      date: date ?? this.date,
      bedtime: bedtime ?? this.bedtime,
      wakeTime: wakeTime ?? this.wakeTime,
      avoidedScreentime: avoidedScreentime ?? this.avoidedScreentime,
      quality: quality ?? this.quality,
      mood: mood ?? this.mood,
      notes: notes ?? this.notes,
    );
  }
}
