import 'package:hive_ce/hive_ce.dart';

part 'body_metrics.g.dart';

@HiveType(typeId: 7)
class BodyMetrics extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final double weight;

  @HiveField(3)
  final double bodyFatPercentage;

  @HiveField(5)
  final double bmi;

  @HiveField(6)
  final double bodyFatMass;

  @HiveField(7)
  final double totalBodyWater;

  @HiveField(8)
  final double protein;

  @HiveField(9)
  final double minerals;

  @HiveField(10)
  final double visceralFatLevel;

  @HiveField(11)
  final double basalMetabolicRate;

  @HiveField(12)
  final double waistHipRatio;

  @HiveField(13)
  final double recommendedCalorieIntake;

  BodyMetrics({
    required this.id,
    required this.date,
    required this.weight,
    this.bodyFatPercentage = 0,
    this.bmi = 0,
    this.bodyFatMass = 0,
    this.totalBodyWater = 0,
    this.protein = 0,
    this.minerals = 0,
    this.visceralFatLevel = 0,
    this.basalMetabolicRate = 0,
    this.waistHipRatio = 0,
    this.recommendedCalorieIntake = 0,
  });

  double get fatFreeMass => weight - bodyFatMass;
}
