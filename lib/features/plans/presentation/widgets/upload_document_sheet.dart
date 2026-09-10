import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/coach_panel/presentation/controllers/coach_panel_providers.dart';
import 'package:gymrank/features/plans/domain/entities/plan_entity.dart';
import 'package:gymrank/features/plans/presentation/controllers/plan_providers.dart';

const _maxBytes = 20 * 1024 * 1024;

const _contentTypes = {
  'pdf': 'application/pdf',
  'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
};

/// Bottom sheet "Subir plan": escolhe o tipo, o arquivo (PDF, Word ou
/// foto) e envia. Também oferece a captura manual, sem arquivo.
Future<void> showUploadDocumentSheet(
  BuildContext context, {
  required String userId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _UploadSheet(userId: userId),
  );
}

class _UploadSheet extends ConsumerStatefulWidget {
  const _UploadSheet({required this.userId});

  final String userId;

  @override
  ConsumerState<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends ConsumerState<_UploadSheet> {
  PlanKind _kind = PlanKind.entrenamiento;
  bool _uploading = false;

  Future<void> _pickAndUpload() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _contentTypes.keys.toList(),
      withData: true,
    );
    final file = picked?.files.single;
    if (file == null || !mounted) return;

    final bytes = file.bytes;
    final ext = (file.extension ?? '').toLowerCase();
    final contentType = _contentTypes[ext];
    if (bytes == null || contentType == null) {
      _snack('Formato no compatible. Usa PDF, Word (.docx) o una foto.');
      return;
    }
    if (bytes.length > _maxBytes) {
      _snack('El archivo pesa más de 20 MB. Comprímelo o divídelo.');
      return;
    }

    final coachId = ref.read(currentCoachIdProvider);
    final uid = ref.read(authStateProvider).valueOrNull;
    if (coachId == null || uid == null) return;

    setState(() => _uploading = true);
    final result = await ref.read(planRepositoryProvider).uploadDocument(
          coachId: coachId,
          userId: widget.userId,
          uploadedBy: uid,
          kind: _kind,
          fileName: file.name,
          bytes: bytes,
          contentType: contentType,
        );
    if (!mounted) return;
    setState(() => _uploading = false);

    result.when(
      success: (_) {
        Navigator.of(context).pop();
        _snack('Archivo subido. Te avisamos cuando esté listo para revisar.');
      },
      failure: (f) => _snack('No se pudo subir: $f'),
    );
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Subir plan', style: AppTextStyles.headline),
          const SizedBox(height: 4),
          const Text(
            'El app lee el archivo y te muestra el plan para que lo revises '
            'antes de publicarlo.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 16),
          const Text('¿Qué es?', style: AppTextStyles.caption),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final k in PlanKind.values)
                ChoiceChip(
                  label: Text(k.labelEs),
                  selected: _kind == k,
                  onSelected: _uploading ? null : (_) => setState(() => _kind = k),
                ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _uploading ? null : _pickAndUpload,
            icon: _uploading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.upload_file),
            label: Text(_uploading ? 'Subiendo…' : 'Elegir PDF, Word o foto'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _uploading
                ? null
                : () {
                    Navigator.of(context).pop();
                    context.push(
                      '/coach/clients/${widget.userId}/plans/new?kind=${_kind.name}',
                    );
                  },
            icon: const Icon(Icons.edit_note),
            label: const Text('Capturar a mano'),
          ),
          const SizedBox(height: 8),
          Text(
            'Máximo 20 MB. Los PDF escaneados y las fotos también funcionan.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
