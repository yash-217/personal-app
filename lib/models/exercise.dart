import 'package:hive_ce/hive_ce.dart';

part 'exercise.g.dart';

@HiveType(typeId: 0)
class Exercise extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String bodyPart;

  @HiveField(3)
  final String targetMuscle;

  @HiveField(4)
  final String equipment;

  @HiveField(5)
  final String gifUrl;

  @HiveField(6)
  final List<String> secondaryMuscles;

  @HiveField(7)
  final List<String> instructions;

  @HiveField(8)
  final String difficulty;

  Exercise({
    required this.id,
    required this.name,
    required this.bodyPart,
    required this.targetMuscle,
    required this.equipment,
    required this.gifUrl,
    required this.secondaryMuscles,
    required this.instructions,
    this.difficulty = 'Regular',
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      bodyPart: json['bodyPart']?.toString() ?? '',
      targetMuscle: json['target']?.toString() ?? '',
      equipment: json['equipment']?.toString() ?? '',
      gifUrl: json['gifUrl']?.toString() ?? '',
      secondaryMuscles:
          (json['secondaryMuscles'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      instructions:
          (json['instructions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'bodyPart': bodyPart,
      'target': targetMuscle,
      'equipment': equipment,
      'gifUrl': gifUrl,
      'secondaryMuscles': secondaryMuscles,
      'instructions': instructions,
    };
  }
}
