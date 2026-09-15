import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/checkin/domain/entities/checkin_entity.dart';
import 'package:gymrank/features/checkin/domain/entities/checkin_location.dart';

abstract interface class CheckInRepository {
  /// Envia o payload lido do QR Code para a Cloud Function
  /// `validateCheckIn`, que valida (token rotativo com TTL de
  /// [AppConstants.qrCodeTokenTtl], ou QR fixo de academia + localização),
  /// aplica o cooldown anti-fraude e concede XP. O cliente nunca escreve o
  /// documento de check-in diretamente (ver firestore.rules).
  ///
  /// [position] é obrigatória para o QR de academia (impresso).
  Future<Result<CheckInEntity>> submitQrPayload(
    String qrPayload, {
    CheckInPosition? position,
  });

  Stream<List<CheckInEntity>> watchRecent(String userId, {int limit});

  // --- pontos de check-in (visão da treinadora) -----------------------------

  Stream<List<CheckInLocation>> watchLocations(String coachId);

  /// Cria (id vazio) ou atualiza uma academia. Para "gerar QR novo", salve
  /// com `qrVersion + 1`.
  Future<Result<CheckInLocation>> saveLocation(CheckInLocation location);

  Future<Result<void>> deleteLocation({
    required String coachId,
    required String locationId,
  });

  /// O conteúdo do QR impresso (um link assinado pelo servidor).
  Future<Result<String>> issueLocationQr(String locationId);
}

/// De onde vem a posição do celular. Separado para o preview e os testes
/// não dependerem de GPS.
abstract interface class PositionSource {
  Future<Result<CheckInPosition>> current();
}
