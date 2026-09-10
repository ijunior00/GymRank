import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/utils/date_formatter.dart';
import 'package:gymrank/core/widgets/entrance.dart';
import 'package:gymrank/features/plans/domain/entities/plan_entity.dart';
import 'package:gymrank/features/plans/presentation/controllers/plan_providers.dart';

/// "Mis planes": o que a treinadora e a nutrióloga publicaram para o
/// aluno logado, um cartão por tipo.
class MyPlansScreen extends ConsumerWidget {
  const MyPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(myPlansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis planes')),
      body: plans.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.assignment_outlined,
                        size: 40, color: AppColors.textSecondary),
                    SizedBox(height: 12),
                    Text(
                      'Todavía no tienes planes publicados. Cuando tu coach '
                      'suba tu entrenamiento o tu dieta, aparecerán aquí.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMuted,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              EntranceList(
                children: [
                  for (final p in list)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PlanTile(plan: p),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Cartão de um plano (usado pelo aluno e pela ficha do aluno no painel).
class PlanTile extends StatelessWidget {
  const PlanTile({required this.plan, super.key});

  final PlanEntity plan;

  @override
  Widget build(BuildContext context) {
    final icon = switch (plan.kind) {
      PlanKind.entrenamiento => Icons.fitness_center,
      PlanKind.dieta => Icons.restaurant_outlined,
      PlanKind.macros => Icons.pie_chart_outline,
      PlanKind.evaluacion => Icons.straighten,
      PlanKind.otro => Icons.description_outlined,
    };
    return Card(
      child: InkWell(
        onTap: () => context.push('/plans/${plan.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.kind.labelEs.toUpperCase(),
                        style: AppTextStyles.caption.copyWith(letterSpacing: 1)),
                    Text(plan.title,
                        style: AppTextStyles.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(
                      'v${plan.currentVersion} · ${DateFormatter.shortDate(plan.publishedAt)}',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
