import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_notification_entity.freezed.dart';

enum NotificationType {
  workoutReminder,
  newChallenge,
  friendOvertook,
  newLevel,
  newAchievement,
  championshipEnded,
  rewardAvailable,

  /// Para a treinadora: um aluno entrou com o código de convite.
  newStudent,

  /// Para o aluno: a treinadora publicou (ou atualizou) um plano.
  planPublished,

  /// Para o aluno: recorde pessoal detectado ao concluir uma sessão.
  personalRecord,
}

/// Documento canônico de `notifications/{notificationId}`, espelhado
/// como push via FCM pela Cloud Function `dispatchNotification`.
@freezed
class AppNotificationEntity with _$AppNotificationEntity {
  const factory AppNotificationEntity({
    required String id,
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? deepLink,
    required bool read,
    required DateTime createdAt,
  }) = _AppNotificationEntity;
}
