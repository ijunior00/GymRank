/// Progressão de níveis infinita e crescente: cada nível exige mais XP
/// que o anterior (curva quadrática suave), incentivando engajamento de
/// longo prazo sem um teto artificial.
abstract final class LevelCalculator {
  /// XP total acumulado necessário para alcançar [level].
  static int xpRequiredFor(int level) {
    if (level <= 1) return 0;
    return (100 * (level - 1) * (level - 1) * 0.5 + 100 * (level - 1)).round();
  }

  static int levelForXp(int totalXp) {
    var level = 1;
    while (xpRequiredFor(level + 1) <= totalXp) {
      level++;
    }
    return level;
  }

  static double progressToNextLevel(int totalXp) {
    final level = levelForXp(totalXp);
    final currentFloor = xpRequiredFor(level);
    final nextCeiling = xpRequiredFor(level + 1);
    final span = nextCeiling - currentFloor;
    if (span <= 0) return 1;
    return ((totalXp - currentFloor) / span).clamp(0, 1).toDouble();
  }

  static int xpToNextLevel(int totalXp) {
    final level = levelForXp(totalXp);
    return xpRequiredFor(level + 1) - totalXp;
  }
}
