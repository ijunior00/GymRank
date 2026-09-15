import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/utils/date_formatter.dart';
import 'package:gymrank/core/utils/load_error_text.dart';
import 'package:gymrank/features/challenges/domain/entities/challenge_entity.dart';
import 'package:gymrank/features/challenges/presentation/controllers/challenge_providers.dart';
import 'package:gymrank/features/profile/presentation/controllers/user_repository_provider.dart';
import 'package:gymrank/features/rewards/presentation/controllers/reward_providers.dart';

/// Um reto visto pela treinadora: resumo, quem está dentro e como vai
/// cada uma, botões de editar e terminar.
class CoachChallengeDetailScreen extends ConsumerWidget {
  const CoachChallengeDetailScreen({super.key, required this.challengeId});

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenge = ref.watch(challengeByIdProvider(challengeId));
    final participants = ref.watch(challengeParticipantsProvider(challengeId));

    return Scaffold(
      appBar: AppBar(
        title: Text(challenge.valueOrNull?.title ?? 'Reto'),
        actions: [
          if (challenge.valueOrNull != null)
            IconButton(
              tooltip: 'Editar',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/coach/challenges/$challengeId/edit'),
            ),
        ],
      ),
      body: challenge.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(describeLoadError(e))),
        data: (c) {
          if (c == null) {
            return const Center(child: Text('Este reto ya no existe.'));
          }
          final list = participants.valueOrNull ?? const [];
          final completed = list.where((p) => p.completed).length;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              _SummaryCard(challenge: c),
              const SizedBox(height: 12),
              _Actions(challenge: c),
              const SizedBox(height: 24),
              Text(
                'Inscritas (${list.length})'
                '${completed > 0 ? ' · $completed completaron' : ''}',
                style: AppTextStyles.headline,
              ),
              const SizedBox(height: 8),
              if (participants.isLoading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (list.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Nadie se ha unido todavía. Las alumnas lo ven en la '
                    'pestaña Retos y entran con un toque.',
                    style: AppTextStyles.bodyMuted,
                  ),
                )
              else
                for (final p in list)
                  _ParticipantTile(participant: p, target: c.targetValue),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCard extends ConsumerWidget {
  const _SummaryCard({required this.challenge});

  final ChallengeEntity challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = challenge;
    final reward = c.rewardId == null
        ? null
        : ref.watch(rewardByIdProvider(c.rewardId!)).valueOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (c.description.isNotEmpty) ...[
              Text(c.description, style: AppTextStyles.body),
              const SizedBox(height: 12),
            ],
            _Line(
              icon: Icons.flag_outlined,
              text: '${c.metric.labelEs}: meta ${c.targetValue.toInt()}',
            ),
            _Line(
              icon: Icons.calendar_today_outlined,
              text:
                  '${DateFormatter.shortDate(c.startsAt)} → ${DateFormatter.shortDate(c.endsAt)}'
                  ' (${c.period.labelEs.toLowerCase()})',
            ),
            _Line(
              icon: Icons.bolt,
              color: AppColors.gold,
              text: '+${c.xpReward} XP al completar',
            ),
            if (c.rewardId != null)
              _Line(
                icon: Icons.card_giftcard,
                color: AppColors.primary,
                text: reward == null
                    ? 'Premio: cargando…'
                    : 'Premio: ${reward.name} (${reward.stock} disponibles)',
              ),
            _Line(
              icon: c.isActive ? Icons.check_circle_outline : Icons.pause_circle_outline,
              color: c.isActive ? AppColors.success : AppColors.textSecondary,
              text: c.isActive
                  ? 'Activo: las alumnas pueden unirse'
                  : 'Terminado: ya no acepta inscripciones ni progreso',
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text, this.color});

  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color ?? AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextStyles.bodyMuted)),
        ],
      ),
    );
  }
}

class _Actions extends ConsumerStatefulWidget {
  const _Actions({required this.challenge});

  final ChallengeEntity challenge;

  @override
  ConsumerState<_Actions> createState() => _ActionsState();
}

class _ActionsState extends ConsumerState<_Actions> {
  bool _busy = false;

  Future<void> _toggle() async {
    final c = widget.challenge;
    final closing = c.isActive;
    if (closing) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Terminar el reto?'),
          content: const Text(
            'Las alumnas dejan de sumar progreso y ya nadie puede unirse. '
            'Puedes reactivarlo después.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Terminar'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    setState(() => _busy = true);
    final result = await ref
        .read(challengeRepositoryProvider)
        .setActive(challengeId: c.id, active: !closing);
    if (!mounted) return;
    setState(() => _busy = false);
    final failure = result.failureOrNull;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure == null
              ? (closing ? 'Reto terminado.' : 'Reto reactivado.')
              : 'No se pudo: ${failure.labelEs}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.challenge;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/coach/challenges/${c.id}/edit'),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: _busy ? null : _toggle,
            icon: Icon(c.isActive ? Icons.stop_circle_outlined : Icons.play_circle_outline),
            label: Text(c.isActive ? 'Terminar' : 'Reactivar'),
          ),
        ),
      ],
    );
  }
}

class _ParticipantTile extends ConsumerWidget {
  const _ParticipantTile({required this.participant, required this.target});

  final ChallengeParticipantEntity participant;
  final double target;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = participant;
    final profile = ref.watch(userByIdProvider(p.userId)).valueOrNull;
    final progress = target <= 0 ? 0.0 : (p.currentValue / target).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    profile?.name ?? 'Cargando…',
                    style: AppTextStyles.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (p.completed)
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20)
                else
                  Text(
                    '${p.currentValue.toInt()}/${target.toInt()}',
                    style: AppTextStyles.caption,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                color: p.completed ? AppColors.success : AppColors.primary,
                backgroundColor: AppColors.surfaceElevated,
              ),
            ),
            if (p.completed && p.completedAt != null) ...[
              const SizedBox(height: 6),
              Text(
                'Completó el ${DateFormatter.shortDate(p.completedAt!)}',
                style: AppTextStyles.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
