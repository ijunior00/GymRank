import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gymrank/core/constants/app_constants.dart';

part 'gym_entity.freezed.dart';

/// Documento canônico de `gyms/{gymId}`.
@freezed
class GymEntity with _$GymEntity {
  const factory GymEntity({
    required String id,
    required String name,
    required String city,
    required String? logoUrl,
    required String? brandColorHex,
    required String qrCodeSecret,
    required SubscriptionPlan plan,
    required int studentCount,
    required int activeChallengeCount,
    required DateTime createdAt,
  }) = _GymEntity;
}

/// Estatísticas agregadas do painel administrativo (calculadas por Cloud
/// Function e armazenadas em `gyms/{gymId}/stats/current`).
@freezed
class GymDashboardStats with _$GymDashboardStats {
  const factory GymDashboardStats({
    required int totalStudents,
    required int checkInsToday,
    required int checkInsThisWeek,
    required int newStudentsThisMonth,
    required int inactiveStudents30d,
    required double retentionRate,
    required DateTime calculatedAt,
  }) = _GymDashboardStats;
}
