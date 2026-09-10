import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/meal_log/data/repositories/firestore_meal_log_repository.dart';
import 'package:gymrank/features/meal_log/domain/entities/meal_log_entity.dart';
import 'package:gymrank/features/meal_log/domain/repositories/meal_log_repository.dart';
import 'package:gymrank/features/plans/domain/entities/plan_content.dart';
import 'package:gymrank/features/plans/domain/entities/plan_entity.dart';
import 'package:gymrank/features/plans/presentation/controllers/plan_providers.dart';

const int dietAdherenceWindowDays = 7;

final mealLogRepositoryProvider = Provider<MealLogRepository>((ref) {
  return FirestoreMealLogRepository(ref.watch(firestoreProvider));
});

/// Registros de hoje do usuário logado.
final todayMealLogsProvider = StreamProvider<List<MealLogEntity>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull;
  if (uid == null) return Stream.value(const []);
  return ref
      .watch(mealLogRepositoryProvider)
      .watchDay(uid, MealLogEntity.dateKey(DateTime.now()));
});

/// Registros dos últimos [dietAdherenceWindowDays] dias de um aluno.
final mealLogsLastWeekProvider =
    StreamProvider.family<List<MealLogEntity>, String>((ref, userId) {
  final now = DateTime.now();
  final from = now.subtract(const Duration(days: dietAdherenceWindowDays - 1));
  return ref.watch(mealLogRepositoryProvider).watchRange(
        userId,
        fromDate: MealLogEntity.dateKey(from),
        toDate: MealLogEntity.dateKey(now),
      );
});

/// Adesão à dieta na última semana (aluno ou, no painel, um aluno dado).
/// `null` enquanto carrega ou quando não há plano de alimentação.
final dietAdherenceProvider =
    Provider.family<DietAdherence?, String>((ref, userId) {
  final plans = ref.watch(studentPlansProvider(userId)).valueOrNull;
  final logs = ref.watch(mealLogsLastWeekProvider(userId)).valueOrNull;
  if (plans == null || logs == null) return null;

  PlanEntity? diet;
  for (final p in plans) {
    if (p.kind == PlanKind.dieta) {
      diet = p;
      break;
    }
  }
  if (diet == null) return null;
  final meals = DietPlanContent.fromMap(diet.content).meals.length;
  return DietAdherence.compute(
    logs: logs,
    mealsPerDay: meals,
    days: dietAdherenceWindowDays,
  );
});
