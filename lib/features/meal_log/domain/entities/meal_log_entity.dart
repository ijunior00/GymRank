import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal_log_entity.freezed.dart';

/// Como o aluno marcou uma refeição do plano de alimentação.
enum MealStatus { hecha, cambiada, saltada }

/// Documento canônico de `meal_logs/{userId_date_mealIndex}`: id
/// determinístico para que remarcar substitua em vez de duplicar.
@freezed
class MealLogEntity with _$MealLogEntity {
  const factory MealLogEntity({
    required String id,
    required String userId,
    required String? coachId,
    required String planId,

    /// Dia no formato `yyyy-MM-dd` (fuso do aparelho).
    required String date,
    required int mealIndex,
    required String mealName,
    required MealStatus status,
    required DateTime createdAt,
  }) = _MealLogEntity;

  const MealLogEntity._();

  static String idFor(String userId, String date, int mealIndex) =>
      '${userId}_${date}_$mealIndex';

  static String dateKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Adesão à dieta em uma janela de dias: `hecha` vale 1, `cambiada` 0,5,
/// `saltada` 0; o denominador é refeições por dia × dias da janela.
class DietAdherence {
  const DietAdherence({
    required this.days,
    required this.mealsPerDay,
    required this.logged,
    required this.score,
  });

  final int days;
  final int mealsPerDay;
  final int logged;
  final double score;

  /// 0..1 (ou `null` sem refeições no plano).
  double? get ratio {
    final total = days * mealsPerDay;
    if (total == 0) return null;
    return (score / total).clamp(0, 1);
  }

  static DietAdherence compute({
    required List<MealLogEntity> logs,
    required int mealsPerDay,
    required int days,
  }) {
    var score = 0.0;
    for (final l in logs) {
      score += switch (l.status) {
        MealStatus.hecha => 1,
        MealStatus.cambiada => 0.5,
        MealStatus.saltada => 0,
      };
    }
    return DietAdherence(
      days: days,
      mealsPerDay: mealsPerDay,
      logged: logs.length,
      score: score,
    );
  }
}
