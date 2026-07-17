import 'package:hive_ce/hive_ce.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 6)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int age; // Legacy field, now calculated from birthDate if available

  @HiveField(2)
  final double height; // cm

  @HiveField(3)
  final double weight; // kg

  @HiveField(4)
  final String gender;

  @HiveField(5)
  final int weeklyGoal; // gym days per week

  @HiveField(6)
  final String weightUnit; // 'kg' or 'lbs'

  @HiveField(7)
  final DateTime? birthDate;

  @HiveField(8)
  final int? dailyStepGoal; // default 10000

  @HiveField(9)
  final double? dailyWalkKmGoal; // default 5.0

  UserProfile({
    required this.name,
    required this.age,
    required this.height,
    required this.weight,
    required this.gender,
    this.weeklyGoal = 4,
    this.weightUnit = 'kg',
    this.birthDate,
    this.dailyStepGoal,
    this.dailyWalkKmGoal,
  });

  int get calculatedAge {
    if (birthDate == null) return age;
    final now = DateTime.now();
    int ageYears = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      ageYears--;
    }
    return ageYears;
  }

  double get bmi {
    if (height <= 0) return 0;
    final heightM = height / 100;
    return weight / (heightM * heightM);
  }

  String get bmiCategory {
    final b = bmi;
    if (b < 18.5) return 'Underweight';
    if (b < 25) return 'Normal';
    if (b < 30) return 'Overweight';
    return 'Obese';
  }

  UserProfile copyWith({
    String? name,
    int? age,
    double? height,
    double? weight,
    String? gender,
    int? weeklyGoal,
    String? weightUnit,
    DateTime? birthDate,
    int? dailyStepGoal,
    double? dailyWalkKmGoal,
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      weightUnit: weightUnit ?? this.weightUnit,
      birthDate: birthDate ?? this.birthDate,
      dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
      dailyWalkKmGoal: dailyWalkKmGoal ?? this.dailyWalkKmGoal,
    );
  }
}
