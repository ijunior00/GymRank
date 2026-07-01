import 'package:gymrank/features/gamification/domain/entities/achievement_entity.dart';

/// Catálogo estático de conquistas (não muda por usuário, não precisa de
/// leitura ao Firestore). Ícones referenciam `assets/icons/achievements/`.
abstract final class AchievementCatalog {
  static const List<AchievementDefinition> all = [
    AchievementDefinition(
      code: AchievementCode.primeiroTreino,
      title: 'Primeiro treino',
      description: 'Você registrou seu primeiro treino.',
      iconAsset: 'assets/icons/achievements/primeiro_treino.png',
    ),
    AchievementDefinition(
      code: AchievementCode.sequencia7Dias,
      title: '7 dias',
      description: 'Sequência de 7 dias treinando.',
      iconAsset: 'assets/icons/achievements/sequencia_7.png',
    ),
    AchievementDefinition(
      code: AchievementCode.sequencia30Dias,
      title: '30 dias',
      description: 'Sequência de 30 dias treinando.',
      iconAsset: 'assets/icons/achievements/sequencia_30.png',
    ),
    AchievementDefinition(
      code: AchievementCode.sequencia100Dias,
      title: '100 dias',
      description: 'Sequência de 100 dias treinando.',
      iconAsset: 'assets/icons/achievements/sequencia_100.png',
    ),
    AchievementDefinition(
      code: AchievementCode.sequencia365Dias,
      title: '365 dias',
      description: 'Sequência de 365 dias treinando.',
      iconAsset: 'assets/icons/achievements/sequencia_365.png',
    ),
    AchievementDefinition(
      code: AchievementCode.primeiraFoto,
      title: 'Primeira foto',
      description: 'Você enviou sua primeira foto de evolução.',
      iconAsset: 'assets/icons/achievements/primeira_foto.png',
    ),
    AchievementDefinition(
      code: AchievementCode.primeiroAmigo,
      title: 'Primeiro amigo',
      description: 'Você adicionou seu primeiro amigo.',
      iconAsset: 'assets/icons/achievements/primeiro_amigo.png',
    ),
    AchievementDefinition(
      code: AchievementCode.primeiroDesafio,
      title: 'Primeiro desafio',
      description: 'Você concluiu seu primeiro desafio.',
      iconAsset: 'assets/icons/achievements/primeiro_desafio.png',
    ),
    AchievementDefinition(
      code: AchievementCode.top10,
      title: 'Top 10',
      description: 'Você terminou uma temporada no Top 10.',
      iconAsset: 'assets/icons/achievements/top10.png',
    ),
    AchievementDefinition(
      code: AchievementCode.top3,
      title: 'Top 3',
      description: 'Você terminou uma temporada no Top 3.',
      iconAsset: 'assets/icons/achievements/top3.png',
    ),
    AchievementDefinition(
      code: AchievementCode.top1,
      title: 'Top 1',
      description: 'Você foi campeão de uma temporada.',
      iconAsset: 'assets/icons/achievements/top1.png',
    ),
  ];
}
