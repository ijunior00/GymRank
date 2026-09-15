import 'dart:typed_data';

import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/rewards/domain/entities/reward_entity.dart';

abstract interface class RewardRepository {
  /// Prêmios concedidos ao usuário (`rewards/*/grants` via collection
  /// group). Toda concessão é feita por Cloud Functions ao finalizar um
  /// desafio ou campeonato — nunca escrita diretamente pelo cliente.
  Stream<List<RewardGrantEntity>> watchMyGrants(String userId);

  /// O prêmio em si (nome, tipo, imagem) — o grant só guarda o id. `null`
  /// se a treinadora o apagou.
  Stream<RewardEntity?> watchReward(String rewardId);

  /// Catálogo de prêmios da comunidade, em ordem alfabética. Visão da
  /// treinadora, para escolher o prêmio de um reto.
  Stream<List<RewardEntity>> watchByCoach(String coachId);

  /// Cria (id vazio) ou atualiza um prêmio. Com [imageBytes], sobe a foto
  /// para `reward_images/{rewardId}/` e grava a URL. O estoque baixa
  /// sozinho a cada concessão (Cloud Function `grantReward`).
  Future<Result<RewardEntity>> save(RewardEntity reward, {Uint8List? imageBytes});
}
