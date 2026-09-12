import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/utils/date_formatter.dart';
import 'package:gymrank/features/rewards/domain/entities/reward_entity.dart';
import 'package:gymrank/features/rewards/presentation/controllers/reward_providers.dart';

class MyRewardsScreen extends ConsumerWidget {
  const MyRewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grants = ref.watch(myRewardGrantsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis premios')),
      body: grants.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Aún no has ganado premios. Los retos y torneos de tu '
                  'comunidad son el camino.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMuted,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _GrantTile(grant: list[i]),
          );
        },
      ),
    );
  }
}

class _GrantTile extends ConsumerWidget {
  const _GrantTile({required this.grant});

  final RewardGrantEntity grant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reward = ref.watch(rewardByIdProvider(grant.rewardId)).valueOrNull;
    final color = _statusColor(grant.status);

    return Card(
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_iconFor(reward?.type), color: color),
        ),
        // Antes mostrava "Premio #r1": o código interno em vez do nome.
        title: Text(reward?.name ?? 'Cargando…', style: AppTextStyles.title),
        subtitle: Text(
          'Ganado en un ${rewardSourceLabelEs(grant.sourceType)} · '
          '${DateFormatter.shortDate(grant.grantedAt)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            grant.status.labelEs,
            style: AppTextStyles.caption.copyWith(color: color),
          ),
        ),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          showDragHandle: true,
          builder: (context) => _GrantSheet(grant: grant, reward: reward),
        ),
      ),
    );
  }

  static Color _statusColor(RewardStatus s) => switch (s) {
        RewardStatus.available || RewardStatus.granted => AppColors.gold,
        RewardStatus.redeemed => AppColors.success,
        RewardStatus.expired => AppColors.textSecondary,
      };

  static IconData _iconFor(RewardType? t) => switch (t) {
        RewardType.suplemento => Icons.local_drink_outlined,
        RewardType.vestuario => Icons.checkroom_outlined,
        RewardType.consultoria => Icons.person_pin_outlined,
        RewardType.mensalidadeGratis => Icons.savings_outlined,
        RewardType.acessorio => Icons.watch_outlined,
        RewardType.valeCompras => Icons.confirmation_number_outlined,
        null => Icons.card_giftcard,
      };
}

/// Detalhe do prêmio. O canje é presencial com a treinadora (ela marca
/// como canjeado do lado dela); por isso não há botão de "canjear" aqui,
/// só a instrução.
class _GrantSheet extends StatelessWidget {
  const _GrantSheet({required this.grant, required this.reward});

  final RewardGrantEntity grant;
  final RewardEntity? reward;

  @override
  Widget build(BuildContext context) {
    final color = _GrantTile._statusColor(grant.status);
    final pending = grant.status == RewardStatus.granted ||
        grant.status == RewardStatus.available;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_GrantTile._iconFor(reward?.type), color: color, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reward?.name ?? 'Premio', style: AppTextStyles.headline),
                    if (reward != null)
                      Text(reward!.type.labelEs, style: AppTextStyles.bodyMuted),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _Row(
            icon: Icons.emoji_events_outlined,
            text: 'Ganado en un ${rewardSourceLabelEs(grant.sourceType)}',
          ),
          _Row(
            icon: Icons.event_outlined,
            text: 'Otorgado el ${DateFormatter.shortDate(grant.grantedAt)}',
          ),
          if (grant.redeemedAt != null)
            _Row(
              icon: Icons.check_circle_outline,
              text: 'Canjeado el ${DateFormatter.shortDate(grant.redeemedAt!)}',
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              pending
                  ? 'Muéstrale esta pantalla a tu coach para canjearlo. Ella lo '
                      'marca como entregado.'
                  : grant.status == RewardStatus.redeemed
                      ? 'Este premio ya fue entregado. ¡Disfrútalo!'
                      : 'Este premio venció sin canjearse.',
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
