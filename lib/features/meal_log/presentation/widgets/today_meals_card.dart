import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/meal_log/domain/entities/meal_log_entity.dart';
import 'package:gymrank/features/meal_log/presentation/controllers/meal_log_providers.dart';
import 'package:gymrank/features/plans/domain/entities/plan_content.dart';
import 'package:gymrank/features/plans/domain/entities/plan_entity.dart';
import 'package:gymrank/features/plans/presentation/controllers/plan_providers.dart';

/// "Comidas de hoy": as refeições do plano de alimentação com um toque
/// para marcar como hecha, cambiada ou saltada. Alimenta a adesão que a
/// treinadora vê no painel.
class TodayMealsCard extends ConsumerWidget {
  const TodayMealsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final plans = ref.watch(myPlansProvider).valueOrNull;
    if (user == null || plans == null) return const SizedBox.shrink();

    PlanEntity? diet;
    for (final p in plans) {
      if (p.kind == PlanKind.dieta) {
        diet = p;
        break;
      }
    }
    if (diet == null) return const SizedBox.shrink();

    final meals = DietPlanContent.fromMap(diet.content).meals;
    if (meals.isEmpty) return const SizedBox.shrink();

    final logs = ref.watch(todayMealLogsProvider).valueOrNull ?? [];
    final byIndex = {for (final l in logs) l.mealIndex: l.status};
    final doneCount = byIndex.values.where((s) => s != MealStatus.saltada).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Comidas de hoy', style: AppTextStyles.title),
                ),
                Text('$doneCount/${meals.length}',
                    style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 4),
            for (var i = 0; i < meals.length; i++)
              _MealRow(
                meal: meals[i],
                status: byIndex[i],
                onTap: () => _pick(
                  context,
                  ref,
                  userId: user.id,
                  coachId: user.coachId,
                  planId: diet!.id,
                  index: i,
                  name: meals[i].name,
                  current: byIndex[i],
                ),
              ),
            TextButton(
              onPressed: () => context.push('/plans/${diet!.id}'),
              child: const Text('Ver plan completo'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(
    BuildContext context,
    WidgetRef ref, {
    required String userId,
    required String? coachId,
    required String planId,
    required int index,
    required String name,
    required MealStatus? current,
  }) async {
    final picked = await showModalBottomSheet<Object?>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(name, style: AppTextStyles.headline),
            ),
            for (final s in MealStatus.values)
              ListTile(
                leading: Icon(_iconFor(s), color: _colorFor(s)),
                title: Text(_labelFor(s)),
                trailing: current == s
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(s),
              ),
            if (current != null)
              ListTile(
                leading: const Icon(Icons.undo,
                    color: AppColors.textSecondary),
                title: const Text('Quitar marca'),
                onTap: () => Navigator.of(context).pop('clear'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked == null) return;

    await ref.read(mealLogRepositoryProvider).setStatus(
          userId: userId,
          coachId: coachId,
          planId: planId,
          date: MealLogEntity.dateKey(DateTime.now()),
          mealIndex: index,
          mealName: name,
          status: picked is MealStatus ? picked : null,
        );
  }
}

IconData _iconFor(MealStatus s) => switch (s) {
      MealStatus.hecha => Icons.check_circle,
      MealStatus.cambiada => Icons.swap_horiz,
      MealStatus.saltada => Icons.cancel_outlined,
    };

Color _colorFor(MealStatus s) => switch (s) {
      MealStatus.hecha => AppColors.success,
      MealStatus.cambiada => AppColors.warning,
      MealStatus.saltada => AppColors.danger,
    };

String _labelFor(MealStatus s) => switch (s) {
      MealStatus.hecha => 'La hice',
      MealStatus.cambiada => 'La cambié',
      MealStatus.saltada => 'Me la salté',
    };

class _MealRow extends StatelessWidget {
  const _MealRow({
    required this.meal,
    required this.status,
    required this.onTap,
  });

  final Meal meal;
  final MealStatus? status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = status;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(
              s == null ? Icons.radio_button_unchecked : _iconFor(s),
              size: 22,
              color: s == null ? AppColors.textSecondary : _colorFor(s),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(meal.name, style: AppTextStyles.body),
                  Text(
                    [
                      if (meal.time != null && meal.time!.isNotEmpty) meal.time!,
                      if (meal.items.isNotEmpty)
                        meal.items.map((i) => i.food).join(', '),
                    ].join(' · '),
                    style: AppTextStyles.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
