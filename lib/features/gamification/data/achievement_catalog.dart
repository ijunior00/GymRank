import 'package:gymrank/features/gamification/domain/entities/achievement_entity.dart';

/// Catálogo estático de conquistas (não muda por usuário, não precisa de
/// leitura ao Firestore). Ícones referenciam `assets/icons/achievements/`.
abstract final class AchievementCatalog {
  static const List<AchievementDefinition> all = [
    AchievementDefinition(
      code: AchievementCode.primeiroTreino,
      title: 'Primer entrenamiento',
      description: 'Registraste tu primer entrenamiento.',
      iconAsset: 'assets/icons/achievements/primeiro_treino.png',
    ),
    AchievementDefinition(
      code: AchievementCode.sequencia7Dias,
      title: '7 días',
      description: 'Racha de 7 días entrenando.',
      iconAsset: 'assets/icons/achievements/sequencia_7.png',
    ),
    AchievementDefinition(
      code: AchievementCode.sequencia30Dias,
      title: '30 días',
      description: 'Racha de 30 días entrenando.',
      iconAsset: 'assets/icons/achievements/sequencia_30.png',
    ),
    AchievementDefinition(
      code: AchievementCode.sequencia100Dias,
      title: '100 días',
      description: 'Racha de 100 días entrenando.',
      iconAsset: 'assets/icons/achievements/sequencia_100.png',
    ),
    AchievementDefinition(
      code: AchievementCode.sequencia365Dias,
      title: '365 días',
      description: 'Racha de 365 días entrenando.',
      iconAsset: 'assets/icons/achievements/sequencia_365.png',
    ),
    AchievementDefinition(
      code: AchievementCode.primeiraFoto,
      title: 'Primera foto',
      description: 'Subiste tu primera foto de progreso.',
      iconAsset: 'assets/icons/achievements/primeira_foto.png',
    ),
    AchievementDefinition(
      code: AchievementCode.primeiroAmigo,
      title: 'Primer amigo',
      description: 'Agregaste a tu primer amigo.',
      iconAsset: 'assets/icons/achievements/primeiro_amigo.png',
    ),
    AchievementDefinition(
      code: AchievementCode.primeiroDesafio,
      title: 'Primer reto',
      description: 'Completaste tu primer reto.',
      iconAsset: 'assets/icons/achievements/primeiro_desafio.png',
    ),
    AchievementDefinition(
      code: AchievementCode.top10,
      title: 'Top 10',
      description: 'Terminaste una temporada en el Top 10.',
      iconAsset: 'assets/icons/achievements/top10.png',
    ),
    AchievementDefinition(
      code: AchievementCode.top3,
      title: 'Top 3',
      description: 'Terminaste una temporada en el Top 3.',
      iconAsset: 'assets/icons/achievements/top3.png',
    ),
    AchievementDefinition(
      code: AchievementCode.top1,
      title: 'Top 1',
      description: 'Ganaste una temporada.',
      iconAsset: 'assets/icons/achievements/top1.png',
    ),
  ];
}
