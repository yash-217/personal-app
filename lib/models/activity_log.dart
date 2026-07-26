import 'package:hive_ce/hive_ce.dart';
import 'day_log.dart';

part 'activity_log.g.dart';

@HiveType(typeId: 15)
class ActivityLog extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final ActivityType type;

  @HiveField(3)
  final int durationMinutes;

  @HiveField(4)
  final int perceivedEffort; // RPE 1-10

  @HiveField(5)
  final String? notes;

  ActivityLog({
    required this.id,
    required this.date,
    required this.type,
    required this.durationMinutes,
    this.perceivedEffort = 5,
    this.notes,
  });

  /// Formatted duration like "45 min"
  String get formattedDuration => '${durationMinutes}m';

  /// RPE label for UI display
  String get effortLabel {
    switch (perceivedEffort) {
      case 1:
      case 2:
        return 'Very Light';
      case 3:
      case 4:
        return 'Light';
      case 5:
      case 6:
        return 'Moderate';
      case 7:
      case 8:
        return 'Hard';
      case 9:
        return 'Very Hard';
      case 10:
        return 'Max Effort';
      default:
        return 'Moderate';
    }
  }

  ActivityLog copyWith({
    String? id,
    DateTime? date,
    ActivityType? type,
    int? durationMinutes,
    int? perceivedEffort,
    String? notes,
  }) {
    return ActivityLog(
      id: id ?? this.id,
      date: date ?? this.date,
      type: type ?? this.type,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      perceivedEffort: perceivedEffort ?? this.perceivedEffort,
      notes: notes ?? this.notes,
    );
  }
}
