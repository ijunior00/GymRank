import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/utils/date_formatter.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/plans/domain/entities/plan_content.dart';
import 'package:gymrank/features/plans/domain/entities/plan_entity.dart';
import 'package:gymrank/features/plans/presentation/controllers/plan_providers.dart';
import 'package:gymrank/features/plans/presentation/widgets/plan_content_view.dart';

/// Plano vigente, como o aluno vê. Para a treinadora mostra também o
/// histórico de versões e o atalho para editar e republicar.
class PlanDetailScreen extends ConsumerWidget {
  const PlanDetailScreen({required this.planId, super.key});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planByIdProvider(planId));
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isStaff = user?.isStaff ?? false;

    return plan.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const Text('Plan')),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Plan')),
        body: Center(child: Text('Error: $e')),
      ),
      data: (p) {
        if (p == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Plan')),
            body: const Center(child: Text('Este plan ya no está disponible.')),
          );
        }
        final content = PlanContent.fromMap(p.kind, p.content);
        return Scaffold(
          appBar: AppBar(title: Text(p.kind.labelEs)),
          floatingActionButton: isStaff
              ? FloatingActionButton.extended(
                  onPressed: () => context.push('/coach/plans/${p.id}/edit'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              Text(p.title, style: AppTextStyles.headline),
              const SizedBox(height: 4),
              Text(
                'Versión ${p.currentVersion} · publicado ${DateFormatter.shortDate(p.publishedAt)}',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 16),
              PlanContentView(content: content),
              if (isStaff)
                _VersionHistory(
                  planId: p.id,
                  kind: p.kind,
                  current: p.currentVersion,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _VersionHistory extends ConsumerWidget {
  const _VersionHistory({
    required this.planId,
    required this.kind,
    required this.current,
  });

  final String planId;
  final PlanKind kind;
  final int current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versions = ref.watch(planVersionsProvider(planId)).valueOrNull ?? [];
    if (versions.length < 2) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Historial de versiones', style: AppTextStyles.title),
              const SizedBox(height: 2),
              const Text('Toca una versión para ver cómo era.',
                  style: AppTextStyles.caption),
              const SizedBox(height: 8),
              for (final v in versions)
                InkWell(
                  onTap: () => _showVersion(context, v),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Icon(
                          v.number == current ? Icons.check_circle : Icons.history,
                          size: 16,
                          color: v.number == current
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text('v${v.number} · ${v.title}',
                              style: AppTextStyles.body,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text(DateFormatter.shortDate(v.publishedAt),
                            style: AppTextStyles.caption),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right,
                            size: 16, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// A versão antiga, só leitura, para comparar o que mudou.
  void _showVersion(BuildContext context, PlanVersionEntity v) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            Text('Versión ${v.number}', style: AppTextStyles.headline),
            Text(
              '${v.title} · publicada ${DateFormatter.shortDate(v.publishedAt)}'
              '${v.number == current ? ' · vigente' : ''}',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 16),
            PlanContentView(content: PlanContent.fromMap(kind, v.content)),
          ],
        ),
      ),
    );
  }
}
