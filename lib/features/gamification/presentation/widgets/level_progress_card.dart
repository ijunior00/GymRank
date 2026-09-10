import 'package:flutter/material.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/gamification/domain/usecases/level_calculator.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';

class LevelProgressCard extends StatelessWidget {
  const LevelProgressCard({required this.user, super.key});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final progress = LevelCalculator.progressToNextLevel(user.xpTotal);
    final xpToNext = LevelCalculator.xpToNextLevel(user.xpTotal);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.military_tech, color: AppColors.gold),
                const SizedBox(width: 6),
                Text('Nivel ${user.level}', style: AppTextStyles.title),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppColors.surfaceElevated,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            const SizedBox(height: 8),
            Text('$xpToNext XP para el siguiente nivel', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
