import 'package:flutter/material.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({required this.user, super.key});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cartão estreito (metade da tela): o título encolhe em vez
            // de estourar.
            const Row(
              children: [
                Icon(Icons.local_fire_department, color: AppColors.warning),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Racha',
                    style: AppTextStyles.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('${user.currentStreakDays} días', style: AppTextStyles.statValue),
            const SizedBox(height: 4),
            Text(
              'Récord: ${user.longestStreakDays} días',
              style: AppTextStyles.caption,
            ),
          ],
        ),
      ),
    );
  }
}
