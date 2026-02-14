import 'package:hive_ce/hive_ce.dart';

part 'day_log.g.dart';

@HiveType(typeId: 1)
enum ActivityType {
  @HiveField(0)
  gym,
  @HiveField(1)
  run,
  @HiveField(2)
  swim,
}

@HiveType(typeId: 2)
class DayLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final List<ActivityType> activities;

  @HiveField(3)
  final String? sessionId;

  @HiveField(4)
  final String? runLogId;

  DayLog({
    required this.id,
    required this.date,
    required this.activities,
    this.sessionId,
    this.runLogId,
  });

  DayLog copyWith({
    String? id,
    DateTime? date,
    List<ActivityType>? activities,
    String? sessionId,
    String? runLogId,
  }) {
    return DayLog(
      id: id ?? this.id,
      date: date ?? this.date,
      activities: activities ?? this.activities,
      sessionId: sessionId ?? this.sessionId,
      runLogId: runLogId ?? this.runLogId,
    );
  }

  bool get hasGym => activities.contains(ActivityType.gym);
  bool get hasRun => activities.contains(ActivityType.run);
  bool get hasSwim => activities.contains(ActivityType.swim);

  /// Date key for calendar lookups (yyyy-MM-dd)
  String get dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
