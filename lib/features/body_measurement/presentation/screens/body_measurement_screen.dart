import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/utils/date_formatter.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/body_measurement/domain/entities/body_measurement_entity.dart';
import 'package:gymrank/features/body_measurement/presentation/controllers/body_measurement_providers.dart';

class BodyMeasurementScreen extends ConsumerWidget {
  const BodyMeasurementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(bodyMeasurementHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Progreso corporal')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Registrar'),
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Agrega tu primer registro para ver tu evolución.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted,
                ),
              ),
            );
          }
          final weights =
              entries.where((e) => e.pesoKg != null).toList(growable: false);
          final first = entries.first;
          final last = entries.last;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              if (weights.length >= 2)
                _SummaryCard(first: first, last: last, count: entries.length),
              const SizedBox(height: 16),
              const Text('Peso (kg)', style: AppTextStyles.title),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: weights.length < 2
                    ? const Center(
                        child: Text(
                          'Con dos registros ya aparece la gráfica.',
                          style: AppTextStyles.bodyMuted,
                        ),
                      )
                    : LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (spots) => [
                                for (final s in spots)
                                  LineTooltipItem(
                                    '${s.y.toStringAsFixed(1)} kg\n'
                                    '${DateFormatter.shortDate(weights[s.x.toInt()].recordedAt)}',
                                    AppTextStyles.caption
                                        .copyWith(color: AppColors.textPrimary),
                                  ),
                              ],
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                for (var i = 0; i < weights.length; i++)
                                  FlSpot(i.toDouble(), weights[i].pesoKg!),
                              ],
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 3,
                              dotData: const FlDotData(show: true),
                              belowBarData: BarAreaData(
                                show: true,
                                color: AppColors.primary.withValues(alpha: 0.12),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 24),
              const Text('Historial', style: AppTextStyles.title),
              const SizedBox(height: 8),
              for (final entry in entries.reversed) _MeasurementTile(entry: entry),
            ],
          );
        },
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _AddMeasurementSheet(),
    );
  }
}

/// De onde saiu para onde chegou, no primeiro e no último registro.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.first,
    required this.last,
    required this.count,
  });

  final BodyMeasurementEntity first;
  final BodyMeasurementEntity last;
  final int count;

  @override
  Widget build(BuildContext context) {
    Widget metric(String label, double? a, double? b, String unit,
        {bool higherIsBetter = false}) {
      if (b == null) return const SizedBox.shrink();
      final delta = a == null ? null : b - a;
      Color color = AppColors.textSecondary;
      if (delta != null && delta != 0) {
        final improved = higherIsBetter ? delta > 0 : delta < 0;
        color = improved ? AppColors.success : AppColors.warning;
      }
      return Expanded(
        child: Column(
          children: [
            Text('${b.toStringAsFixed(1)} $unit', style: AppTextStyles.statValue),
            Text(label, style: AppTextStyles.caption),
            if (delta != null)
              Text(
                '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
                style: AppTextStyles.caption
                    .copyWith(color: color, fontWeight: FontWeight.w700),
              ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                metric('Peso', first.pesoKg, last.pesoKg, 'kg'),
                metric('% grasa', first.percentualGordura, last.percentualGordura,
                    '%'),
                metric('Músculo', first.massaMuscularKg, last.massaMuscularKg,
                    'kg',
                    higherIsBetter: true),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$count registros desde ${DateFormatter.shortDate(first.recordedAt)}',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMeasurementSheet extends ConsumerStatefulWidget {
  const _AddMeasurementSheet();

  @override
  ConsumerState<_AddMeasurementSheet> createState() =>
      _AddMeasurementSheetState();
}

class _AddMeasurementSheetState extends ConsumerState<_AddMeasurementSheet> {
  final _peso = TextEditingController();
  final _grasa = TextEditingController();
  final _musculo = TextEditingController();
  bool _saving = false;

  /// Aviso de validação dentro da própria folha: um SnackBar aqui ficaria
  /// escondido atrás dela (e do teclado).
  String? _error;

  @override
  void dispose() {
    _peso.dispose();
    _grasa.dispose();
    _musculo.dispose();
    super.dispose();
  }

  double? _num(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    final uid = ref.read(authStateProvider).valueOrNull;
    if (uid == null) return;
    final peso = _num(_peso);
    final grasa = _num(_grasa);
    final musculo = _num(_musculo);
    if (peso == null && grasa == null && musculo == null) {
      setState(() => _error = 'Escribe al menos un dato.');
      return;
    }
    if (peso != null && (peso < 20 || peso > 400)) {
      setState(() => _error = 'Revisa el peso: parece fuera de rango.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(bodyMeasurementRepositoryProvider).add(
          BodyMeasurementEntity(
            id: '',
            userId: uid,
            recordedAt: DateTime.now(),
            pesoKg: peso,
            percentualGordura: grasa,
            massaMuscularKg: musculo,
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    final failure = result.failureOrNull;
    if (failure != null) {
      setState(() => _error = 'No se pudo guardar: $failure');
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Registro guardado. ¡Sigue así!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Nuevo registro', style: AppTextStyles.headline),
          const SizedBox(height: 4),
          const Text(
            'Llena lo que tengas; lo demás puede quedar vacío.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _peso,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Peso',
              suffixText: 'kg',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _grasa,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Grasa corporal',
              suffixText: '%',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _musculo,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Masa muscular',
              suffixText: 'kg',
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Text(
              _error!,
              style: AppTextStyles.caption.copyWith(color: AppColors.danger),
            ),
            const SizedBox(height: 8),
          ],
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _MeasurementTile extends StatelessWidget {
  const _MeasurementTile({required this.entry});

  final BodyMeasurementEntity entry;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (entry.pesoKg != null) '${entry.pesoKg!.toStringAsFixed(1)} kg',
      if (entry.percentualGordura != null)
        '${entry.percentualGordura!.toStringAsFixed(1)}% grasa',
      if (entry.massaMuscularKg != null)
        '${entry.massaMuscularKg!.toStringAsFixed(1)} kg músculo',
    ];
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.monitor_weight_outlined, color: AppColors.primary),
      title: Text(parts.isEmpty ? '—' : parts.join(' · ')),
      subtitle: Text(
        DateFormatter.shortDate(entry.recordedAt),
        style: AppTextStyles.caption,
      ),
    );
  }
}
