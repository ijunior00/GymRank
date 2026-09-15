import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/utils/date_formatter.dart';
import 'package:gymrank/core/utils/load_error_text.dart';
import 'package:gymrank/core/widgets/entrance.dart';
import 'package:gymrank/features/challenges/domain/entities/challenge_entity.dart';
import 'package:gymrank/features/challenges/presentation/controllers/challenge_providers.dart';
import 'package:gymrank/features/rewards/presentation/controllers/reward_providers.dart';

/// Retos da comunidade, na visão da treinadora: ativos em cima,
/// terminados embaixo, botão para criar. Cada cartão abre o detalhe com
/// as inscritas.
class CoachChallengesScreen extends ConsumerWidget {
  const CoachChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(coachChallengesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Retos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/coach/challenges/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo reto'),
      ),
      body: challenges.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(describeLoadError(e), textAlign: TextAlign.center),
          ),
        ),
        data: (list) {
          if (list.isEmpty) return const _EmptyState();
          final active = list.where((c) => c.isActive).toList();
          final finished = list.where((c) => !c.isActive).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            children: [
              if (active.isNotEmpty) ...[
                const Text('Activos', style: AppTextStyles.headline),
                const SizedBox(height: 12),
                for (final (i, c) in active.indexed)
                  Entrance(
                    delay: Duration(milliseconds: 60 * i),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CoachChallengeTile(challenge: c),
                    ),
                  ),
              ],
              if (finished.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Terminados', style: AppTextStyles.headline),
                const SizedBox(height: 12),
                for (final c in finished)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CoachChallengeTile(challenge: c),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events_outlined,
                size: 56, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            const Text('Todavía no hay retos', style: AppTextStyles.title),
            const SizedBox(height: 8),
            const Text(
              'Crea el primero: elige una meta de días entrenados o de '
              'check-ins, cuánto XP vale y, si quieres, un premio.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.push('/coach/challenges/new'),
              icon: const Icon(Icons.add),
              label: const Text('Crear reto'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cartão de um reto na lista da treinadora.
class CoachChallengeTile extends ConsumerWidget {
  const CoachChallengeTile({super.key, required this.challenge});

  final ChallengeEntity challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = challenge;
    final reward = c.rewardId == null
        ? null
        : ref.watch(rewardByIdProvider(c.rewardId!)).valueOrNull;
    final ended = c.endsAt.isBefore(DateTime.now());

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/coach/challenges/${c.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(c.title, style: AppTextStyles.title)),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: !c.isActive
                        ? 'Terminado'
                        : ended
                            ? 'Venció'
                            : 'Activo',
                    color: !c.isActive
                        ? AppColors.textSecondary
                        : ended
                            ? AppColors.warning
                            : AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${c.metric.labelEs} · meta ${c.targetValue.toInt()} · '
                '${DateFormatter.shortDate(c.startsAt)} → ${DateFormatter.shortDate(c.endsAt)}',
                style: AppTextStyles.bodyMuted,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  _Fact(icon: Icons.bolt, color: AppColors.gold, text: '+${c.xpReward} XP'),
                  _Fact(
                    icon: Icons.people_outline,
                    text: '${c.participantCount} inscritas',
                  ),
                  if (c.rewardId != null)
                    _Fact(
                      icon: Icons.card_giftcard,
                      color: AppColors.primary,
                      text: reward?.name ?? 'Premio',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label, style: AppTextStyles.caption.copyWith(color: color)),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? AppColors.textSecondary),
        const SizedBox(width: 4),
        // Flexible: um nome de prêmio comprido encolhe com reticências em
        // vez de estourar a largura do cartão em tela estreita.
        Flexible(
          child: Text(
            text,
            style: AppTextStyles.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
