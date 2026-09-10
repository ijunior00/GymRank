import 'package:flutter/material.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/coach_panel/domain/entities/client_entity.dart';

/// Chip semântico da situação de atividade do aluno (verde / âmbar /
/// vermelho / cinza). Cor separada do acento amarelo da marca.
class StudentActivityChip extends StatelessWidget {
  const StudentActivityChip({required this.activity, super.key});

  final StudentActivity activity;

  @override
  Widget build(BuildContext context) {
    final color = switch (activity) {
      StudentActivity.alDia => AppColors.success,
      StudentActivity.enRiesgo => AppColors.warning,
      StudentActivity.sinActividad => AppColors.danger,
      StudentActivity.sinRegistros => AppColors.textSecondary,
    };
    return _Chip(label: activity.labelEs, color: color);
  }
}

/// Chip neutro para status comercial (en pausa / inactivo).
class StudentStatusChip extends StatelessWidget {
  const StudentStatusChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return _Chip(label: label, color: AppColors.textSecondary);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
