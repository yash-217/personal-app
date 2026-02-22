import 'package:hive_ce/hive_ce.dart';

part 'achievement.g.dart';

@HiveType(typeId: 14)
class Achievement extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String badgeId;

  @HiveField(2)
  final DateTime dateUnlocked;

  @HiveField(3)
  bool hasViewed;

  Achievement({
    required this.id,
    required this.badgeId,
    required this.dateUnlocked,
    this.hasViewed = false,
  });
}
