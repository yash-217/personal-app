import 'package:hive_ce/hive_ce.dart';

part 'weight_entry.g.dart';

@HiveType(typeId: 5)
class WeightEntry extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String exerciseId;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final double weight;

  @HiveField(4)
  final int? reps;

  @HiveField(5)
  final int? sets;

  @HiveField(6)
  final String? notes;

  WeightEntry({
    required this.id,
    required this.exerciseId,
    required this.date,
    required this.weight,
    this.reps,
    this.sets,
    this.notes,
  });
}
