import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: history.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Text('Agrega tu primer registro para comenzar.'),
            );
          }
          final weights = entries
              .where((e) => e.pesoKg != null)
              .toList(growable: false);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Peso (kg)', style: AppTextStyles.title),
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: weights.length < 2
                    ? const Center(child: Text('Datos insuficientes para la gráfica'))
                    : LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                for (var i = 0; i < weights.length; i++)
                                  FlSpot(i.toDouble(), weights[i].pesoKg!),
                              ],
                              isCurved: true,
                              color: AppColors.primary,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
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
    final pesoController = TextEditingController();
    final gorduraController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nuevo registro', style: AppTextStyles.headline),
            const SizedBox(height: 16),
            TextField(
              controller: pesoController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: 'Peso (kg)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: gorduraController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(hintText: '% de grasa'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final uid = ref.read(authStateProvider).valueOrNull;
                if (uid == null) return;
                await ref.read(bodyMeasurementRepositoryProvider).add(
                      BodyMeasurementEntity(
                        id: '',
                        userId: uid,
                        recordedAt: DateTime.now(),
                        pesoKg: double.tryParse(pesoController.text),
                        percentualGordura: double.tryParse(gorduraController.text),
                      ),
                    );
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MeasurementTile extends StatelessWidget {
  const _MeasurementTile({required this.entry});

  final BodyMeasurementEntity entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        '${entry.pesoKg?.toStringAsFixed(1) ?? '-'} kg'
        '${entry.percentualGordura != null ? ' · ${entry.percentualGordura!.toStringAsFixed(1)}% grasa' : ''}',
      ),
      subtitle: Text(
        '${entry.recordedAt.day}/${entry.recordedAt.month}/${entry.recordedAt.year}',
        style: AppTextStyles.caption,
      ),
    );
  }
}
