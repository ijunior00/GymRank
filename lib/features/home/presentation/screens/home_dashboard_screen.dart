import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/gamification/presentation/widgets/level_progress_card.dart';
import 'package:gymrank/features/gamification/presentation/widgets/streak_card.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text('Olá, ${user?.name.split(' ').first ?? ''} 👋'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (user != null) ...[
            Row(
              children: [
                Expanded(child: LevelProgressCard(user: user)),
                const SizedBox(width: 12),
                Expanded(child: StreakCard(user: user)),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.qr_code_scanner,
                      label: 'Check-in',
                      onTap: () => context.push('/checkin'),
                    ),
                  ),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.fitness_center,
                      label: 'Registrar treino',
                      onTap: () => context.push('/workout/new'),
                    ),
                  ),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.monitor_weight_outlined,
                      label: 'Evolução',
                      onTap: () => context.push('/body-measurement'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Desafios ativos', style: AppTextStyles.title),
          const SizedBox(height: 8),
          const _EmptyState(
            icon: Icons.flag_outlined,
            message: 'Você ainda não entrou em nenhum desafio.',
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
          ],
        ),
      ),
    );
  }
}
