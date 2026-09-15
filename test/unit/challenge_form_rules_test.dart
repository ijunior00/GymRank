import 'package:flutter_test/flutter_test.dart';
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/features/challenges/domain/challenge_form_rules.dart';
import 'package:gymrank/features/challenges/domain/entities/challenge_entity.dart';

/// Os limites do formulário de reto são os mesmos das regras do Firestore
/// (validChallenge). Se um mudar sem o outro, a coach vê "sin permiso" em
/// vez de uma mensagem clara — por isso os números ficam travados aqui.
void main() {
  test('XP entre 10 e 1000, como nas regras', () {
    expect(ChallengeFormRules.xpError(9), isNotNull);
    expect(ChallengeFormRules.xpError(10), isNull);
    expect(ChallengeFormRules.xpError(1000), isNull);
    expect(ChallengeFormRules.xpError(1001), isNotNull);
  });

  test('meta é inteiro positivo até 10000', () {
    expect(ChallengeFormRules.targetError(''), isNotNull);
    expect(ChallengeFormRules.targetError('2,5'), isNotNull);
    expect(ChallengeFormRules.targetError('0'), isNotNull);
    expect(ChallengeFormRules.targetError('5'), isNull);
    expect(ChallengeFormRules.targetError('10001'), isNotNull);
  });

  test('título obrigatório e curto; descrição opcional', () {
    expect(ChallengeFormRules.titleError('   '), isNotNull);
    expect(ChallengeFormRules.titleError('Semana fuerte'), isNull);
    expect(ChallengeFormRules.titleError('x' * 81), isNotNull);
    expect(ChallengeFormRules.descriptionError(''), isNull);
    expect(ChallengeFormRules.descriptionError('x' * 501), isNotNull);
  });

  test('fim depois do início e no máximo um ano', () {
    final start = DateTime(2026, 9, 1);
    expect(ChallengeFormRules.datesError(start, start), isNotNull);
    expect(ChallengeFormRules.datesError(start, DateTime(2026, 8, 30)), isNotNull);
    expect(ChallengeFormRules.datesError(start, DateTime(2026, 9, 8)), isNull);
    expect(ChallengeFormRules.datesError(start, DateTime(2027, 9, 3)), isNotNull);
  });

  test('até 10 dias é semanal; acima, mensal', () {
    final start = DateTime(2026, 9, 1);
    expect(ChallengeFormRules.periodFor(start, DateTime(2026, 9, 8)),
        ChallengePeriod.semanal);
    expect(ChallengeFormRules.periodFor(start, DateTime(2026, 10, 1)),
        ChallengePeriod.mensal);
  });

  test('só entram no formulário as métricas que o servidor já calcula', () {
    expect(
      ChallengeFormRules.availableMetrics,
      [ChallengeMetric.diasTreinados, ChallengeMetric.checkIns],
    );
  });
}
