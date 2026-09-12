import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/utils/date_formatter.dart';
import 'package:gymrank/core/widgets/entrance.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/challenges/domain/entities/challenge_entity.dart';
import 'package:gymrank/features/challenges/presentation/controllers/challenge_providers.dart';
import 'package:gymrank/features/rewards/presentation/controllers/reward_providers.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(activeChallengesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Retos')),
      body: challenges.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('No hay retos activos por ahora.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => Entrance(
              delay: Duration(milliseconds: 70 * i),
              child: _ChallengeCard(challenge: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _ChallengeCard extends ConsumerStatefulWidget {
  const _ChallengeCard({required this.challenge});

  final ChallengeEntity challenge;

  @override
  ConsumerState<_ChallengeCard> createState() => _ChallengeCardState();
}

class _ChallengeCardState extends ConsumerState<_ChallengeCard> {
  bool _joining = false;

  Future<void> _join() async {
    final uid = ref.read(authStateProvider).valueOrNull;
    if (uid == null) return;
    setState(() => _joining = true);
    final result = await ref.read(challengeRepositoryProvider).join(
          challengeId: widget.challenge.id,
          userId: uid,
        );
    if (!mounted) return;
    setState(() => _joining = false);
    final failure = result.failureOrNull;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure == null
              ? '¡Estás dentro! Tu progreso se actualiza solo con cada '
                  'entrenamiento.'
              : 'No se pudo entrar: $failure',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    final participation =
        ref.watch(challengeParticipationProvider(challenge.id)).valueOrNull;
    final daysLeft = challenge.endsAt.difference(DateTime.now()).inDays;

    return Card(
      child: InkWell(
        onTap: () => _showDetail(context, challenge, participation),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(challenge.title, style: AppTextStyles.title),
                  ),
                  _ScopeBadge(scope: challenge.scope),
                ],
              ),
              const SizedBox(height: 6),
              Text(challenge.description, style: AppTextStyles.bodyMuted),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.bolt, size: 16, color: AppColors.gold),
                  const SizedBox(width: 4),
                  Text('+${challenge.xpReward} XP', style: AppTextStyles.caption),
                  const SizedBox(width: 16),
                  const Icon(Icons.people_outline,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('${challenge.participantCount} participantes',
                      style: AppTextStyles.caption),
                  const Spacer(),
                  Text(
                    daysLeft <= 0
                        ? 'termina hoy'
                        : daysLeft == 1
                            ? 'termina mañana'
                            : 'quedan $daysLeft días',
                    style: AppTextStyles.caption,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (participation == null)
                ElevatedButton(
                  onPressed: _joining ? null : _join,
                  child: _joining
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Unirme al reto'),
                )
              else
                _ProgressBlock(challenge: challenge, participation: participation),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(
    BuildContext context,
    ChallengeEntity challenge,
    ChallengeParticipantEntity? participation,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _ChallengeDetailSheet(
        challenge: challenge,
        participation: participation,
        onJoin: participation == null && !_joining
            ? () {
                Navigator.of(context).pop();
                _join();
              }
            : null,
      ),
    );
  }
}

/// Barra de progresso de quem já está no reto. O valor vem do backend
/// (Cloud Function), nunca de auto-declaração — por isso não há botão de
/// "marcar como feito".
class _ProgressBlock extends StatelessWidget {
  const _ProgressBlock({required this.challenge, required this.participation});

  final ChallengeEntity challenge;
  final ChallengeParticipantEntity participation;

  @override
  Widget build(BuildContext context) {
    final target = challenge.targetValue <= 0 ? 1.0 : challenge.targetValue;
    final ratio = (participation.currentValue / target).clamp(0.0, 1.0);
    final done = participation.completed || ratio >= 1;
    final current = _fmt(participation.currentValue);
    final goal = _fmt(challenge.targetValue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              done ? Icons.check_circle : Icons.flag_circle_outlined,
              size: 18,
              color: done ? AppColors.success : AppColors.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                done
                    ? '¡Reto completado!'
                    : 'Ya participas · $current de $goal ${challenge.metric.labelEs.toLowerCase()}',
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            backgroundColor: AppColors.surfaceElevated,
            color: done ? AppColors.success : AppColors.primary,
          ),
        ),
      ],
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

class _ChallengeDetailSheet extends ConsumerWidget {
  const _ChallengeDetailSheet({
    required this.challenge,
    required this.participation,
    required this.onJoin,
  });

  final ChallengeEntity challenge;
  final ChallengeParticipantEntity? participation;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewardId = challenge.rewardId;
    final reward =
        rewardId == null ? null : ref.watch(rewardByIdProvider(rewardId)).valueOrNull;

    final rows = <(IconData, String)>[
      (Icons.flag_outlined, '${challenge.scope.labelEs} · ${challenge.period.labelEs}'),
      (
        Icons.track_changes,
        'Meta: ${_ProgressBlock._fmt(challenge.targetValue)} ${challenge.metric.labelEs.toLowerCase()}'
      ),
      (
        Icons.event_outlined,
        'Del ${DateFormatter.shortDate(challenge.startsAt)} al ${DateFormatter.shortDate(challenge.endsAt)}'
      ),
      (Icons.bolt, '+${challenge.xpReward} XP al completarlo'),
      if (rewardId != null)
        (Icons.card_giftcard_outlined, 'Premio: ${reward?.name ?? 'cargando…'}'),
      (Icons.people_outline, '${challenge.participantCount} participantes'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(challenge.title, style: AppTextStyles.headline),
          const SizedBox(height: 6),
          Text(challenge.description, style: AppTextStyles.bodyMuted),
          const SizedBox(height: 16),
          for (final (icon, text) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(child: Text(text, style: AppTextStyles.body)),
                ],
              ),
            ),
          const SizedBox(height: 16),
          if (participation != null)
            _ProgressBlock(challenge: challenge, participation: participation!)
          else if (onJoin != null)
            ElevatedButton(
              onPressed: onJoin,
              child: const Text('Unirme al reto'),
            ),
        ],
      ),
    );
  }
}

class _ScopeBadge extends StatelessWidget {
  const _ScopeBadge({required this.scope});

  final ChallengeScope scope;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        scope.labelEs,
        style: AppTextStyles.caption.copyWith(color: AppColors.primary),
      ),
    );
  }
}
