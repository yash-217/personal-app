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
  @HiveField(3)
  football,
  @HiveField(4)
  tt,
  @HiveField(5)
  badminton,
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

  @HiveField(5)
  final int? steps;

  @HiveField(6)
  final double? walkDistanceKm;

  DayLog({
    required this.id,
    required this.date,
    required this.activities,
    this.sessionId,
    this.runLogId,
    this.steps,
    this.walkDistanceKm,
  });

  DayLog copyWith({
    String? id,
    DateTime? date,
    List<ActivityType>? activities,
    String? sessionId,
    String? runLogId,
    int? steps,
    double? walkDistanceKm,
  }) {
    return DayLog(
      id: id ?? this.id,
      date: date ?? this.date,
      activities: activities ?? this.activities,
      sessionId: sessionId ?? this.sessionId,
      runLogId: runLogId ?? this.runLogId,
      steps: steps ?? this.steps,
      walkDistanceKm: walkDistanceKm ?? this.walkDistanceKm,
    );
  }

  bool get hasGym => activities.contains(ActivityType.gym);
  bool get hasRun => activities.contains(ActivityType.run);
  bool get hasSwim => activities.contains(ActivityType.swim);
  bool get hasFootball => activities.contains(ActivityType.football);
  bool get hasTT => activities.contains(ActivityType.tt);
  bool get hasBadminton => activities.contains(ActivityType.badminton);

  /// Date key for calendar lookups (yyyy-MM-dd)
  String get dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
