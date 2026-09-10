import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/coach_panel/presentation/controllers/coach_panel_providers.dart';

/// Diálogo em que o aluno digita o código de convite da treinadora.
/// Retorna `true` se o vínculo foi criado.
Future<bool> showJoinCoachDialog(
  BuildContext context,
  WidgetRef ref, {
  required String userId,
}) async {
  final joined = await showDialog<bool>(
    context: context,
    builder: (context) => _JoinCoachDialog(userId: userId),
  );
  return joined ?? false;
}

class _JoinCoachDialog extends ConsumerStatefulWidget {
  const _JoinCoachDialog({required this.userId});

  final String userId;

  @override
  ConsumerState<_JoinCoachDialog> createState() => _JoinCoachDialogState();
}

class _JoinCoachDialogState extends ConsumerState<_JoinCoachDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref.read(coachPanelRepositoryProvider).joinCoach(
          userId: widget.userId,
          inviteCode: _controller.text,
        );
    if (!mounted) return;
    result.when(
      success: (coach) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Listo! Ahora entrenas con ${coach.name}.')),
        );
      },
      failure: (failure) => setState(() {
        _loading = false;
        _error = failure.maybeWhen(
          validation: (m) => m,
          permissionDenied: () => 'No tienes permiso para unirte. Intenta más tarde.',
          network: () => 'Sin conexión. Revisa tu internet.',
          orElse: () => 'No se pudo completar. Intenta de nuevo.',
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Unirme a mi coach'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Escribe el código de 6 caracteres que te compartió tu coach.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              LengthLimitingTextInputFormatter(8),
              FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
            ],
            style: AppTextStyles.headline.copyWith(letterSpacing: 4),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: 'ABC123',
              errorText: _error,
            ),
            onSubmitted: (_) => _join(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _join,
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Unirme'),
        ),
      ],
    );
  }
}
