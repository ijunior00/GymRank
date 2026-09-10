import 'package:flutter/material.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/plans/domain/entities/plan_content.dart';

/// Renderização somente leitura de um [PlanContent], compartilhada pela
/// visão do aluno e pela pré-visualização da treinadora. Pensada para
/// celular: uma coluna, cartões por dia/refeição, linhas curtas.
class PlanContentView extends StatelessWidget {
  const PlanContentView({required this.content, super.key});

  final PlanContent content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (content.summary != null && content.summary!.isNotEmpty) ...[
          Text(content.summary!, style: AppTextStyles.bodyMuted),
          const SizedBox(height: 16),
        ],
        ...switch (content) {
          WorkoutPlanContent c => _workout(c),
          DietPlanContent c => _diet(c),
          MacrosPlanContent c => _macros(c),
          EvaluationContent c => _evaluation(c),
          GenericContent c => _generic(c),
          _ => const <Widget>[],
        },
        if (content.generalNotes != null && content.generalNotes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _SectionCard(
            title: 'Notas generales',
            child: Text(content.generalNotes!, style: AppTextStyles.body),
          ),
        ],
      ],
    );
  }

  List<Widget> _workout(WorkoutPlanContent c) => [
        if (c.weeksDuration != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Duración: ${c.weeksDuration} semanas',
                style: AppTextStyles.caption),
          ),
        for (final day in c.days)
          _SectionCard(
            title: day.name,
            subtitle: day.focus,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final ex in day.exercises)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Icon(Icons.fitness_center,
                              size: 14, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ex.name, style: AppTextStyles.body),
                              if (ex.prescription.isNotEmpty)
                                Text(ex.prescription,
                                    style: AppTextStyles.caption.copyWith(
                                        color: AppColors.textPrimary)),
                              if (ex.technique != null && ex.technique!.isNotEmpty)
                                Text(ex.technique!, style: AppTextStyles.caption),
                              if (ex.notes != null && ex.notes!.isNotEmpty)
                                Text(ex.notes!, style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (day.notes != null && day.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(day.notes!, style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
      ];

  List<Widget> _diet(DietPlanContent c) => [
        for (final meal in c.meals)
          _SectionCard(
            title: meal.name,
            subtitle: meal.time,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final item in meal.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.food, style: AppTextStyles.body),
                              if (item.notes != null && item.notes!.isNotEmpty)
                                Text(item.notes!, style: AppTextStyles.caption),
                            ],
                          ),
                        ),
                        if (item.quantity != null)
                          Text(item.quantity!,
                              style: AppTextStyles.body
                                  .copyWith(color: AppColors.primary)),
                      ],
                    ),
                  ),
                if (meal.notes != null && meal.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(meal.notes!, style: AppTextStyles.caption),
                ],
              ],
            ),
          ),
        if (c.substitutions.isNotEmpty)
          _SectionCard(
            title: 'Equivalencias',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final s in c.substitutions)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text('• $s', style: AppTextStyles.body),
                  ),
              ],
            ),
          ),
      ];

  List<Widget> _macros(MacrosPlanContent c) => [
        for (final t in c.targets)
          _SectionCard(
            title: t.label,
            child: Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                if (t.kcal != null) _Macro('kcal', _fmt(t.kcal!)),
                if (t.proteinG != null) _Macro('Proteína', '${_fmt(t.proteinG!)} g'),
                if (t.carbsG != null) _Macro('Carbs', '${_fmt(t.carbsG!)} g'),
                if (t.fatG != null) _Macro('Grasa', '${_fmt(t.fatG!)} g'),
                if (t.fiberG != null) _Macro('Fibra', '${_fmt(t.fiberG!)} g'),
                if (t.waterMl != null) _Macro('Agua', '${_fmt(t.waterMl!)} ml'),
              ],
            ),
          ),
      ];

  List<Widget> _evaluation(EvaluationContent c) => [
        _SectionCard(
          title: 'Mediciones',
          subtitle: c.recordedAt,
          child: Column(
            children: [
              for (final m in c.metrics)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text(m.label, style: AppTextStyles.bodyMuted)),
                      Text('${m.value}${m.unit == null ? '' : ' ${m.unit}'}',
                          style: AppTextStyles.body),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ];

  List<Widget> _generic(GenericContent c) => [
        for (final s in c.sections)
          _SectionCard(
            title: s.heading,
            child: Text(s.content, style: AppTextStyles.body),
          ),
      ];

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

class _Macro extends StatelessWidget {
  const _Macro(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTextStyles.statValue),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.title),
            if (subtitle != null && subtitle!.isNotEmpty)
              Text(subtitle!, style: AppTextStyles.caption),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

/// Faixa de avisos do parser (confiança + trechos duvidosos), exibida à
/// treinadora na revisão.
class ParserWarningsBanner extends StatelessWidget {
  const ParserWarningsBanner({required this.content, super.key});

  final PlanContent content;

  @override
  Widget build(BuildContext context) {
    final color = switch (content.confidence) {
      'alta' => AppColors.success,
      'baja' => AppColors.danger,
      _ => AppColors.warning,
    };
    final label = switch (content.confidence) {
      'alta' => 'Lectura confiable',
      'baja' => 'Lectura poco confiable: revisa con cuidado',
      _ => 'Lectura con dudas: revisa antes de publicar',
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 16, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: AppTextStyles.caption
                        .copyWith(color: color, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          for (final w in content.warnings) ...[
            const SizedBox(height: 6),
            Text('• $w', style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}
