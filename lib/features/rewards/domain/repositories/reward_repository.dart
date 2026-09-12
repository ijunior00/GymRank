import 'package:gymrank/features/rewards/domain/entities/reward_entity.dart';

abstract interface class RewardRepository {
  /// Prêmios concedidos ao usuário (`rewards/*/grants` via collection
  /// group). Toda concessão é feita por Cloud Functions ao finalizar um
  /// desafio ou campeonato — nunca escrita diretamente pelo cliente.
  Stream<List<RewardGrantEntity>> watchMyGrants(String userId);

  /// O prêmio em si (nome, tipo, imagem) — o grant só guarda o id. `null`
  /// se a treinadora o apagou.
  Stream<RewardEntity?> watchReward(String rewardId);
}
