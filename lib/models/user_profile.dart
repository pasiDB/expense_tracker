import 'package:hive/hive.dart';

part 'user_profile.g.dart';

@HiveType(typeId: 2)
class UserProfile extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double monthlyIncome;

  @HiveField(2)
  final String? profileImagePath;

  @HiveField(3)
  final double savingsTarget;

  UserProfile({
    this.name = '',
    this.monthlyIncome = 0.0,
    this.profileImagePath,
    this.savingsTarget = 0.0,
  });
}
