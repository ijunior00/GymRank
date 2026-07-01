import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/checkin/domain/entities/checkin_entity.dart';

abstract interface class CheckInRepository {
  /// Envia o payload lido do QR Code da academia para a Cloud Function
  /// `validateCheckIn`, que valida o token rotativo (TTL de
  /// [AppConstants.qrCodeTokenTtl]), aplica o cooldown anti-fraude e
  /// concede XP. O cliente nunca escreve o documento de check-in
  /// diretamente (ver firestore.rules).
  Future<Result<CheckInEntity>> submitQrPayload(String qrPayload);

  Stream<List<CheckInEntity>> watchRecent(String userId, {int limit});
}
