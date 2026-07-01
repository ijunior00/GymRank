import 'package:gymrank/features/gamification/domain/entities/achievement_entity.dart';

abstract interface class AchievementRepository {
  /// Conquistas desbloqueadas são gravadas por Cloud Functions ao detectar
  /// o evento correspondente (ex.: sequência de 7 dias). O catálogo
  /// completo é estático e vive em [AchievementCatalog].
  Stream<List<UserAchievementEntity>> watchUnlocked(String userId);
}
