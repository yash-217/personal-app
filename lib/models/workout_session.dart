import 'package:hive_ce/hive_ce.dart';

part 'workout_session.g.dart';

@HiveType(typeId: 3)
class WorkoutSession extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final List<String> targetMuscleGroups;

  @HiveField(3)
  final List<String> exerciseIds;

  @HiveField(4)
  final bool completed;

  @HiveField(5)
  final Map<String, List<WorkoutSet>> performance;

  WorkoutSession({
    required this.id,
    required this.date,
    required this.targetMuscleGroups,
    required this.exerciseIds,
    this.completed = false,
    this.performance = const {},
  });

  WorkoutSession copyWith({
    String? id,
    DateTime? date,
    List<String>? targetMuscleGroups,
    List<String>? exerciseIds,
    bool? completed,
    Map<String, List<WorkoutSet>>? performance,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      date: date ?? this.date,
      targetMuscleGroups: targetMuscleGroups ?? this.targetMuscleGroups,
      exerciseIds: exerciseIds ?? this.exerciseIds,
      completed: completed ?? this.completed,
      performance: performance ?? this.performance,
    );
  }
}

@HiveType(typeId: 12)
class WorkoutSet extends HiveObject {
  @HiveField(0)
  final double weightLbs;

  @HiveField(1)
  final double weightKg;

  @HiveField(2)
  final int reps;

  WorkoutSet({
    required this.weightLbs,
    required this.weightKg,
    required this.reps,
  });
}
