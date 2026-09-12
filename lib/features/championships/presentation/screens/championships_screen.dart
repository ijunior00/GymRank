import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/utils/date_formatter.dart';
import 'package:gymrank/features/championships/domain/entities/championship_entity.dart';
import 'package:gymrank/features/championships/presentation/controllers/championship_providers.dart';
import 'package:gymrank/features/rewards/presentation/controllers/reward_providers.dart';

class ChampionshipsScreen extends ConsumerWidget {
  const ChampionshipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final championships = ref.watch(communityChampionshipsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Torneos')),
      body: championships.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aún no hay torneos en tu comunidad.'));
          }
          final sorted = [...list]..sort((a, b) {
              if (a.isFinished != b.isFinished) return a.isFinished ? 1 : -1;
              return b.startsAt.compareTo(a.startsAt);
            });
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sorted.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _ChampionshipTile(championship: sorted[i]),
          );
        },
      ),
    );
  }
}

class _ChampionshipTile extends StatelessWidget {
  const _ChampionshipTile({required this.championship});

  final ChampionshipEntity championship;

  @override
  Widget build(BuildContext context) {
    final c = championship;
    return Card(
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (c.isFinished ? AppColors.textSecondary : AppColors.gold)
                .withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.workspace_premium,
            color: c.isFinished ? AppColors.textSecondary : AppColors.gold,
          ),
        ),
        title: Text(c.name, style: AppTextStyles.title),
        subtitle: Text(
          '${c.criteria.labelEs} · ${c.participantCount} participantes',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: _StatusChip(finished: c.isFinished),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          isScrollControlled: true,
          builder: (context) => _ChampionshipSheet(championship: c),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.finished});

  final bool finished;

  @override
  Widget build(BuildContext context) {
    final color = finished ? AppColors.textSecondary : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        finished ? 'Terminado' : 'En curso',
        style: AppTextStyles.caption.copyWith(color: color),
      ),
    );
  }
}

class _ChampionshipSheet extends ConsumerWidget {
  const _ChampionshipSheet({required this.championship});

  final ChampionshipEntity championship;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = championship;
    final daysLeft = c.endsAt.difference(DateTime.now()).inDays;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(c.name, style: AppTextStyles.headline)),
              _StatusChip(finished: c.isFinished),
            ],
          ),
          const SizedBox(height: 6),
          Text(c.description, style: AppTextStyles.bodyMuted),
          const SizedBox(height: 16),
          _Row(
            icon: Icons.leaderboard_outlined,
            text: 'Gana quien tenga ${c.criteria.labelEs.toLowerCase()}',
          ),
          _Row(
            icon: Icons.event_outlined,
            text:
                'Del ${DateFormatter.shortDate(c.startsAt)} al ${DateFormatter.shortDate(c.endsAt)}'
                '${c.isFinished ? '' : daysLeft <= 0 ? ' · termina hoy' : ' · quedan $daysLeft días'}',
          ),
          _Row(
            icon: Icons.people_outline,
            text: '${c.participantCount} participantes',
          ),
          if (c.rewardIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('PREMIOS',
                style: AppTextStyles.caption.copyWith(letterSpacing: 1.2)),
            const SizedBox(height: 4),
            for (final (i, id) in c.rewardIds.indexed)
              _RewardRow(position: i + 1, rewardId: id),
          ],
          const SizedBox(height: 16),
          Text(
            c.isFinished
                ? 'El podio y los premios se definieron al cierre. Si ganaste, '
                    'lo verás en "Mis premios".'
                : 'Tu posición se calcula sola con lo que entrenas: no hay que '
                    'inscribirse. Revisa el ranking de tu comunidad.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    );
  }
}

class _RewardRow extends ConsumerWidget {
  const _RewardRow({required this.position, required this.rewardId});

  final int position;
  final String rewardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reward = ref.watch(rewardByIdProvider(rewardId)).valueOrNull;
    final medal = switch (position) {
      1 => AppColors.gold,
      2 => AppColors.silver,
      3 => AppColors.bronze,
      _ => AppColors.textSecondary,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: medal,
            child: Text(
              '$position',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w800, color: Colors.black),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              reward == null ? 'Cargando…' : '${reward.name} · ${reward.type.labelEs}',
              style: AppTextStyles.body,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
