import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/utils/date_formatter.dart';
import 'package:gymrank/features/plans/domain/entities/plan_entity.dart';
import 'package:gymrank/features/plans/presentation/controllers/plan_providers.dart';
import 'package:gymrank/features/plans/presentation/screens/my_plans_screen.dart';
import 'package:gymrank/features/plans/presentation/widgets/upload_document_sheet.dart';

/// Seção "Planes y documentos" da ficha do aluno: planos vigentes,
/// documentos em processamento/revisão e o botão de upload.
class StudentPlansCard extends ConsumerWidget {
  const StudentPlansCard({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(studentPlansProvider(userId)).valueOrNull ?? [];
    final documents = ref.watch(studentDocumentsProvider(userId)).valueOrNull ?? [];
    final pending = documents
        .where((d) => d.status != PlanDocumentStatus.publicado)
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(child: Text('Planes y documentos', style: AppTextStyles.title)),
                TextButton.icon(
                  onPressed: () => showUploadDocumentSheet(context, userId: userId),
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Subir'),
                ),
              ],
            ),
            if (plans.isEmpty && pending.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Sube el PDF de la nutrióloga o el plan de entrenamiento; '
                  'el app lo convierte en dieta, macros o rutina para revisar '
                  'y publicar.',
                  style: AppTextStyles.bodyMuted,
                ),
              ),
            for (final p in plans)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: PlanTile(plan: p),
              ),
            if (pending.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text('En proceso', style: AppTextStyles.caption),
              for (final d in pending) _DocumentRow(document: d),
            ],
          ],
        ),
      ),
    );
  }
}

class _DocumentRow extends ConsumerWidget {
  const _DocumentRow({required this.document});

  final PlanDocumentEntity document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final d = document;
    final (color, icon) = switch (d.status) {
      PlanDocumentStatus.listo => (AppColors.success, Icons.rate_review_outlined),
      PlanDocumentStatus.error => (AppColors.danger, Icons.error_outline),
      PlanDocumentStatus.publicado => (AppColors.textSecondary, Icons.check),
      _ => (AppColors.warning, Icons.hourglass_top),
    };
    final isReady = d.status == PlanDocumentStatus.listo;
    final isError = d.status == PlanDocumentStatus.error;

    return InkWell(
      onTap: isReady
          ? () => context.push('/coach/documents/${d.id}/review')
          : isError
              ? () => _showError(context, ref)
              : null,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${d.kind.labelEs} · ${d.fileName}',
                      style: AppTextStyles.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    '${d.status.labelEs} · ${DateFormatter.relative(d.updatedAt)}',
                    style: AppTextStyles.caption.copyWith(color: color),
                  ),
                ],
              ),
            ),
            if (isReady)
              const Text('Revisar', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
            if (isError)
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Future<void> _showError(BuildContext context, WidgetRef ref) async {
    final retry = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('No se pudo leer el archivo'),
        content: Text(document.errorMessage ?? 'Error desconocido.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
    if (retry == true) {
      await ref.read(planRepositoryProvider).retryDocument(document.id);
    }
  }
}
