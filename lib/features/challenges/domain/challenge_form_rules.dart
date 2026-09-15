import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/features/challenges/domain/entities/challenge_entity.dart';

/// Limites do formulário de reto da treinadora. São os mesmos que as
/// regras do Firestore impõem (ver `validChallenge` em firestore.rules);
/// aqui servem para a pessoa ver o erro antes de salvar, em espanhol.
abstract final class ChallengeFormRules {
  static const int minXp = 10;
  static const int maxXp = 1000;
  static const int maxTarget = 10000;
  static const int maxTitle = 80;
  static const int maxDescription = 500;
  static const int maxDurationDays = 366;

  /// Métricas cujo progresso o servidor já calcula sozinho. As outras
  /// (kg perdidos, masa muscular, km) só entram no formulário quando
  /// existir a origem de dados — senão a aluna entra num reto que nunca
  /// avança.
  static const List<ChallengeMetric> availableMetrics = [
    ChallengeMetric.diasTreinados,
    ChallengeMetric.checkIns,
  ];

  static String? titleError(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Ponle un nombre al reto.';
    if (v.length > maxTitle) return 'Máximo $maxTitle caracteres.';
    return null;
  }

  static String? descriptionError(String value) {
    if (value.trim().length > maxDescription) {
      return 'Máximo $maxDescription caracteres.';
    }
    return null;
  }

  /// A meta é um inteiro: dias ou check-ins, nunca "2,5 días".
  static String? targetError(String raw) {
    final v = int.tryParse(raw.trim());
    if (v == null) return 'Escribe un número entero.';
    if (v <= 0) return 'La meta tiene que ser mayor que cero.';
    if (v > maxTarget) return 'Máximo $maxTarget.';
    return null;
  }

  static String? xpError(int xp) {
    if (xp < minXp) return 'Mínimo $minXp XP.';
    if (xp > maxXp) return 'Máximo $maxXp XP, para no desbalancear el ranking.';
    return null;
  }

  static String? datesError(DateTime start, DateTime end) {
    if (!end.isAfter(start)) return 'El fin tiene que ser después del inicio.';
    if (end.difference(start).inDays > maxDurationDays) {
      return 'Un reto dura como máximo un año.';
    }
    return null;
  }

  /// O enum guardado só tem semanal/mensal; a partir de 11 dias é mensal.
  static ChallengePeriod periodFor(DateTime start, DateTime end) {
    return end.difference(start).inDays <= 10
        ? ChallengePeriod.semanal
        : ChallengePeriod.mensal;
  }
}
