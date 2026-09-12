import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/utils/date_formatter.dart';
import 'package:gymrank/features/gamification/data/achievement_catalog.dart';
import 'package:gymrank/features/gamification/domain/entities/achievement_entity.dart';
import 'package:gymrank/features/gamification/presentation/controllers/achievement_providers.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(unlockedAchievementsProvider).valueOrNull ?? [];
    final unlockedByCode = {for (final a in unlocked) a.code: a};
    final total = AchievementCatalog.all.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logros'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${unlockedByCode.length} de $total',
                style: AppTextStyles.caption,
              ),
            ),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: total,
        itemBuilder: (context, i) {
          final def = AchievementCatalog.all[i];
          final earned = unlockedByCode[def.code];
          return _AchievementTile(
            definition: def,
            earned: earned,
            onTap: () => _showDetail(context, def, earned),
          );
        },
      ),
    );
  }

  void _showDetail(
    BuildContext context,
    AchievementDefinition def,
    UserAchievementEntity? earned,
  ) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: earned != null
                  ? AppColors.gold.withValues(alpha: 0.2)
                  : AppColors.surfaceElevated,
              child: Icon(
                Icons.emoji_events,
                size: 40,
                color: earned != null ? AppColors.gold : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            Text(def.title, style: AppTextStyles.headline),
            const SizedBox(height: 6),
            Text(
              def.description,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (earned != null ? AppColors.gold : AppColors.textSecondary)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                earned != null
                    ? 'Desbloqueado el ${DateFormatter.shortDate(earned.unlockedAt)}'
                    : 'Todavía no lo desbloqueas',
                style: AppTextStyles.caption.copyWith(
                  color: earned != null ? AppColors.gold : AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({
    required this.definition,
    required this.earned,
    required this.onTap,
  });

  final AchievementDefinition definition;
  final UserAchievementEntity? earned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = earned != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Opacity(
        opacity: isUnlocked ? 1 : 0.4,
        child: Column(
          children: [
            const SizedBox(height: 6),
            CircleAvatar(
              radius: 28,
              backgroundColor: isUnlocked
                  ? AppColors.gold.withValues(alpha: 0.2)
                  : AppColors.surfaceElevated,
              child: Icon(
                Icons.emoji_events,
                color: isUnlocked ? AppColors.gold : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              definition.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
