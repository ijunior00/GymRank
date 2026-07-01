import 'package:freezed_annotation/freezed_annotation.dart';

part 'reward_entity.freezed.dart';

enum RewardType {
  suplemento,
  vestuario,
  consultoria,
  mensalidadeGratis,
  acessorio,
  valeCompras,
}

enum RewardStatus { available, granted, redeemed, expired }

/// Documento canônico de `rewards/{rewardId}`, cadastrado por uma
/// academia e distribuído automaticamente pelo sistema ao vencedor de um
/// desafio ou campeonato (ver functions/src/rewards/grantReward.ts).
@freezed
class RewardEntity with _$RewardEntity {
  const factory RewardEntity({
    required String id,
    required String gymId,
    required String name,
    required String? imageUrl,
    required RewardType type,
    required int stock,
  }) = _RewardEntity;
}

/// Documento canônico de `rewards/{rewardId}/grants/{grantId}`: uma
/// instância de prêmio concedida a um usuário específico.
@freezed
class RewardGrantEntity with _$RewardGrantEntity {
  const factory RewardGrantEntity({
    required String id,
    required String rewardId,
    required String userId,
    required String sourceType,
    required String sourceId,
    required RewardStatus status,
    required DateTime grantedAt,
    DateTime? redeemedAt,
  }) = _RewardGrantEntity;
}
