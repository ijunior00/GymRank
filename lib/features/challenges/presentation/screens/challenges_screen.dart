import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/widgets/entrance.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/challenges/domain/entities/challenge_entity.dart';
import 'package:gymrank/features/challenges/presentation/controllers/challenge_providers.dart';

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

class _ChallengeCard extends ConsumerWidget {
  const _ChallengeCard({required this.challenge});

  final ChallengeEntity challenge;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).valueOrNull;

    return Card(
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
                const Icon(Icons.people_outline, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${challenge.participantCount} participantes', style: AppTextStyles.caption),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: uid == null
                  ? null
                  : () => ref.read(challengeRepositoryProvider).join(
                        challengeId: challenge.id,
                        userId: uid,
                      ),
              child: const Text('Unirme al reto'),
            ),
          ],
        ),
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
