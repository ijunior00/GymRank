import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/gym_admin/presentation/controllers/gym_admin_providers.dart';

/// Painel administrativo da academia: estatísticas de retenção,
/// check-ins, alunos ativos/inativos. Dados agregados por Cloud Function
/// (`recalculateGymDashboard`) e servidos como leitura direta.
class GymAdminDashboardScreen extends ConsumerWidget {
  const GymAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(gymDashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Painel da academia')),
      body: stats.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (data) {
          if (data == null) {
            return const Center(child: Text('Nenhuma estatística disponível.'));
          }
          return GridView.count(
            padding: const EdgeInsets.all(16),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _StatCard(label: 'Alunos', value: '${data.totalStudents}'),
              _StatCard(label: 'Check-ins hoje', value: '${data.checkInsToday}'),
              _StatCard(label: 'Check-ins na semana', value: '${data.checkInsThisWeek}'),
              _StatCard(label: 'Novos alunos (mês)', value: '${data.newStudentsThisMonth}'),
              _StatCard(label: 'Inativos (30d)', value: '${data.inactiveStudents30d}'),
              _StatCard(
                label: 'Retenção',
                value: '${(data.retentionRate * 100).toStringAsFixed(0)}%',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: AppTextStyles.displayLarge.copyWith(fontSize: 26)),
            const SizedBox(height: 4),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
