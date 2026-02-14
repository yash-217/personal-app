import 'package:hive_ce/hive_ce.dart';

part 'workout_routine.g.dart';

@HiveType(typeId: 10)
class WorkoutRoutine extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<String> exerciseIds;

  @HiveField(3)
  final int color;

  @HiveField(4)
  final List<String> targetMuscles;

  WorkoutRoutine({
    required this.id,
    required this.name,
    required this.exerciseIds,
    required this.color,
    this.targetMuscles = const [],
  });

  /// Estimated duration in minutes (assuming ~3 mins per exercise)
  int get estimatedDuration => exerciseIds.length * 3;
}
