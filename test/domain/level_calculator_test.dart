import 'package:flutter_test/flutter_test.dart';
import 'package:gymrank/features/gamification/domain/usecases/level_calculator.dart';

/// A curva de níveis é a mesma no app e na Cloud Function; se mudar aqui,
/// tem de mudar em functions/src/gamification/.
void main() {
  group('LevelCalculator.xpRequiredFor', () {
    test('nível 1 não exige XP e a curva é crescente', () {
      expect(LevelCalculator.xpRequiredFor(0), 0);
      expect(LevelCalculator.xpRequiredFor(1), 0);
      expect(LevelCalculator.xpRequiredFor(2), 150);
      expect(LevelCalculator.xpRequiredFor(3), 400);
      expect(LevelCalculator.xpRequiredFor(4), 750);
    });

    test('cada nível custa mais que o anterior', () {
      for (var level = 2; level <= 60; level++) {
        final step = LevelCalculator.xpRequiredFor(level) -
            LevelCalculator.xpRequiredFor(level - 1);
        final previousStep = level == 2
            ? 0
            : LevelCalculator.xpRequiredFor(level - 1) -
                LevelCalculator.xpRequiredFor(level - 2);
        expect(step, greaterThan(previousStep),
            reason: 'o salto para o nível $level deveria crescer');
      }
    });
  });

  group('LevelCalculator.levelForXp', () {
    test('sobe de nível exatamente no limiar', () {
      expect(LevelCalculator.levelForXp(0), 1);
      expect(LevelCalculator.levelForXp(149), 1);
      expect(LevelCalculator.levelForXp(150), 2);
      expect(LevelCalculator.levelForXp(399), 2);
      expect(LevelCalculator.levelForXp(400), 3);
    });

    test('é consistente com xpRequiredFor em toda a curva', () {
      for (var level = 1; level <= 40; level++) {
        final floor = LevelCalculator.xpRequiredFor(level);
        expect(LevelCalculator.levelForXp(floor), level);
        expect(LevelCalculator.levelForXp(floor - 1),
            level == 1 ? 1 : level - 1);
      }
    });
  });

  group('LevelCalculator.progressToNextLevel', () {
    test('zera ao subir de nível e chega perto de 1 antes do próximo', () {
      expect(LevelCalculator.progressToNextLevel(150), 0);
      expect(LevelCalculator.progressToNextLevel(275), closeTo(0.5, 0.0001));
      expect(LevelCalculator.progressToNextLevel(399),
          closeTo(249 / 250, 0.0001));
    });

    test('nunca sai de 0..1', () {
      for (final xp in [0, 1, 149, 150, 1000, 999999]) {
        final p = LevelCalculator.progressToNextLevel(xp);
        expect(p, inInclusiveRange(0, 1));
      }
    });
  });

  test('xpToNextLevel é o que falta para o próximo limiar', () {
    expect(LevelCalculator.xpToNextLevel(150), 250);
    expect(LevelCalculator.xpToNextLevel(0), 150);
    expect(LevelCalculator.xpToNextLevel(399), 1);
  });
}
