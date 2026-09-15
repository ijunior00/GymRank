import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/utils/load_error_text.dart';
import 'package:gymrank/features/rewards/domain/entities/reward_entity.dart';
import 'package:gymrank/features/rewards/presentation/controllers/reward_providers.dart';
import 'package:gymrank/features/rewards/presentation/widgets/reward_form_sheet.dart';

/// Catálogo de prêmios da comunidade (visão da treinadora): o que ela
/// consegue entregar de verdade, com quantos tem de cada.
class CoachRewardsScreen extends ConsumerWidget {
  const CoachRewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rewards = ref.watch(coachRewardsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Premios')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showRewardFormSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo premio'),
      ),
      body: rewards.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(describeLoadError(e))),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.card_giftcard,
                        size: 56, color: AppColors.textSecondary),
                    const SizedBox(height: 16),
                    const Text('Sin premios todavía', style: AppTextStyles.title),
                    const SizedBox(height: 8),
                    const Text(
                      'Registra lo que puedes entregar (playera, sesión '
                      'presencial, mensualidad) y úsalo en un reto.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodyMuted,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: () => showRewardFormSheet(context),
                      icon: const Icon(Icons.add),
                      label: const Text('Crear premio'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _RewardTile(reward: list[i]),
          );
        },
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({required this.reward});

  final RewardEntity reward;

  @override
  Widget build(BuildContext context) {
    final r = reward;
    return Card(
      child: ListTile(
        onTap: () => showRewardFormSheet(context, initial: r),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            image: r.imageUrl == null
                ? null
                : DecorationImage(image: NetworkImage(r.imageUrl!), fit: BoxFit.cover),
          ),
          child: r.imageUrl == null
              ? const Icon(Icons.card_giftcard, color: AppColors.primary)
              : null,
        ),
        title: Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${r.type.labelEs} · ${r.stock == 0 ? 'agotado' : '${r.stock} disponibles'}',
          style: AppTextStyles.caption.copyWith(
            color: r.stock == 0 ? AppColors.warning : null,
          ),
        ),
        trailing: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
      ),
    );
  }
}
