import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/meal_log/domain/entities/meal_log_entity.dart';

abstract interface class MealLogRepository {
  /// Marca (ou remarca) uma refeição do dia. Passar `null` em [status]
  /// desmarca.
  Future<Result<void>> setStatus({
    required String userId,
    required String? coachId,
    required String planId,
    required String date,
    required int mealIndex,
    required String mealName,
    required MealStatus? status,
  });

  Stream<List<MealLogEntity>> watchDay(String userId, String date);

  /// Registros com `date` entre [fromDate] e [toDate] (inclusive, `yyyy-MM-dd`).
  /// [coachId] é obrigatório quando quem lê é a treinadora — ver o mesmo
  /// motivo em `PlanRepository.watchDocuments`.
  Stream<List<MealLogEntity>> watchRange(
    String userId, {
    required String fromDate,
    required String toDate,
    String? coachId,
  });
}
