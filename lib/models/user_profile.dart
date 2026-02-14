import 'package:hive_ce/hive_ce.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 6)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int age;

  @HiveField(2)
  final double height; // cm

  @HiveField(3)
  final double weight; // kg

  @HiveField(4)
  final String gender;

  @HiveField(5)
  final int weeklyGoal; // gym days per week

  UserProfile({
    required this.name,
    required this.age,
    required this.height,
    required this.weight,
    required this.gender,
    this.weeklyGoal = 4,
  });

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
  }) {
    return UserProfile(
      name: name ?? this.name,
      age: age ?? this.age,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
    );
  }
}
