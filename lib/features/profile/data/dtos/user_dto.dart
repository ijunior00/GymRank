import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';

/// Mapeia `users/{uid}` <-> [UserEntity]. Mapeamento manual (em vez de
/// json_serializable) porque o Firestore usa [Timestamp] em vez de
/// String ISO-8601 e temos poucos campos aninhados.
class UserDto {
  const UserDto(this.entity);

  final UserEntity entity;

  static UserEntity fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserEntity(
      id: doc.id,
      name: data['name'] as String,
      username: data['username'] as String,
      photoUrl: data['photoUrl'] as String?,
      birthDate: (data['birthDate'] as Timestamp).toDate(),
      sex: data['sex'] as String,
      heightCm: (data['heightCm'] as num).toDouble(),
      city: data['city'] as String,
      gymId: data['gymId'] as String?,
      goal: UserGoal.values.byName(data['goal'] as String),
      role: UserRole.values.byName(data['role'] as String),
      level: data['level'] as int? ?? 1,
      xpTotal: data['xpTotal'] as int? ?? 0,
      xpCurrentSeason: data['xpCurrentSeason'] as int? ?? 0,
      gymScore: (data['gymScore'] as num?)?.toDouble() ?? 0,
      currentStreakDays: data['currentStreakDays'] as int? ?? 0,
      longestStreakDays: data['longestStreakDays'] as int? ?? 0,
      lastCheckInAt: (data['lastCheckInAt'] as Timestamp?)?.toDate(),
      plan: SubscriptionPlan.values.byName(
        data['plan'] as String? ?? 'free',
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': entity.name,
      'username': entity.username,
      'usernameLowercase': entity.username.toLowerCase(),
      'photoUrl': entity.photoUrl,
      'birthDate': Timestamp.fromDate(entity.birthDate),
      'sex': entity.sex,
      'heightCm': entity.heightCm,
      'city': entity.city,
      'gymId': entity.gymId,
      'goal': entity.goal.name,
      'role': entity.role.name,
      'level': entity.level,
      'xpTotal': entity.xpTotal,
      'xpCurrentSeason': entity.xpCurrentSeason,
      'gymScore': entity.gymScore,
      'currentStreakDays': entity.currentStreakDays,
      'longestStreakDays': entity.longestStreakDays,
      'lastCheckInAt': entity.lastCheckInAt == null
          ? null
          : Timestamp.fromDate(entity.lastCheckInAt!),
      'plan': entity.plan.name,
      'createdAt': Timestamp.fromDate(entity.createdAt),
    };
  }
}
