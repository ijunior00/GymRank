import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/notifications/domain/entities/app_notification_entity.dart';

abstract interface class NotificationRepository {
  Stream<List<AppNotificationEntity>> watchAll(String userId);

  Future<Result<void>> markRead(String notificationId);

  /// Registra o token FCM do dispositivo em `users/{uid}/fcmTokens/{token}`
  /// para que a Cloud Function `dispatchNotification` possa enviar push.
  Future<Result<void>> registerDeviceToken({
    required String userId,
    required String token,
  });

  /// Apaga o token ao sair da conta: sem isso o aparelho continuaria
  /// recebendo os pushes de quem saiu.
  Future<Result<void>> removeDeviceToken({
    required String userId,
    required String token,
  });
}
