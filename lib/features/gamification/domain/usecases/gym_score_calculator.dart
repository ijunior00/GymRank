import 'package:gymrank/core/constants/app_constants.dart';

/// Entradas normalizadas (0.0 a 1.0) usadas para compor o Gym Score.
/// A normalização (ex.: check-ins da semana / dias da semana) é feita
/// pela Cloud Function `recalculateGymScore`; esta classe só aplica os
/// pesos definidos no produto, mantendo a fórmula testável e única em
/// todo o app.
class GymScoreInputs {
  const GymScoreInputs({
    required this.frequency,
    required this.consistency,
    required this.challengeParticipation,
    required this.individualEvolution,
  });

  final double frequency;
  final double consistency;
  final double challengeParticipation;
  final double individualEvolution;
}

/// Algoritmo proprietário do Gym Score. Propositalmente NÃO usa métricas
/// de composição corporal absolutas (ex.: massa muscular total) para
/// evitar favorecer genética/volume em vez de disciplina — ver seção
/// "Gym Score" do briefing de produto.
abstract final class GymScoreCalculator {
  static double calculate(GymScoreInputs inputs) {
    final score = inputs.frequency * AppConstants.gymScoreWeightFrequency +
        inputs.consistency * AppConstants.gymScoreWeightConsistency +
        inputs.challengeParticipation *
            AppConstants.gymScoreWeightChallenges +
        inputs.individualEvolution * AppConstants.gymScoreWeightEvolution;
    return (score * 1000).clamp(0, 1000).roundToDouble();
  }
}
