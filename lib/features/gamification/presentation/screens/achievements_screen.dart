import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/gamification/data/achievement_catalog.dart';
import 'package:gymrank/features/gamification/presentation/controllers/achievement_providers.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unlocked = ref.watch(unlockedAchievementsProvider).valueOrNull ?? [];
    final unlockedCodes = unlocked.map((a) => a.code).toSet();

    return Scaffold(
      appBar: AppBar(title: const Text('Logros')),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: AchievementCatalog.all.length,
        itemBuilder: (context, i) {
          final def = AchievementCatalog.all[i];
          final isUnlocked = unlockedCodes.contains(def.code);
          return Opacity(
            opacity: isUnlocked ? 1 : 0.35,
            child: Column(
              children: [
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
                  def.title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
