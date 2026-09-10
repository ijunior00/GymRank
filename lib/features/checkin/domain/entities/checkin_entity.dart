import 'package:freezed_annotation/freezed_annotation.dart';

part 'checkin_entity.freezed.dart';

/// Documento canônico de `coaches/{coachId}/checkins/{checkInId}`. Criado
/// exclusivamente pela Cloud Function `validateCheckIn`, nunca
/// diretamente pelo cliente, para permitir validação anti-fraude
/// (token de QR rotativo + cooldown). Usado só no atendimento presencial;
/// alunos online pontuam pela conclusão do treino.
@freezed
class CheckInEntity with _$CheckInEntity {
  const factory CheckInEntity({
    required String id,
    required String userId,
    required String coachId,
    required DateTime checkedInAt,
    required int xpGranted,
    required bool countedForStreak,
  }) = _CheckInEntity;
}
