import 'package:freezed_annotation/freezed_annotation.dart';

part 'checkin_entity.freezed.dart';

/// Documento canônico de `gyms/{gymId}/checkins/{checkInId}`. Criado
/// exclusivamente pela Cloud Function `validateCheckIn`, nunca
/// diretamente pelo cliente, para permitir validação anti-fraude
/// (token de QR rotativo + cooldown + geofencing opcional).
@freezed
class CheckInEntity with _$CheckInEntity {
  const factory CheckInEntity({
    required String id,
    required String userId,
    required String gymId,
    required DateTime checkedInAt,
    required int xpGranted,
    required bool countedForStreak,
  }) = _CheckInEntity;
}
