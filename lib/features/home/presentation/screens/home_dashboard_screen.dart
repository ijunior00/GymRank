import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/widgets/animated_count_text.dart';
import 'package:gymrank/core/widgets/entrance.dart';
import 'package:gymrank/core/widgets/level_ring.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/challenges/domain/entities/challenge_entity.dart';
import 'package:gymrank/features/challenges/presentation/controllers/challenge_providers.dart';
import 'package:gymrank/features/coach_panel/domain/entities/coach_entity.dart';
import 'package:gymrank/features/coach_panel/presentation/controllers/coach_panel_providers.dart';
import 'package:gymrank/features/friendship/presentation/controllers/friendship_providers.dart';
import 'package:gymrank/features/gamification/domain/usecases/level_calculator.dart';
import 'package:gymrank/features/gamification/presentation/controllers/achievement_providers.dart';
import 'package:gymrank/features/meal_log/presentation/widgets/today_meals_card.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';
import 'package:gymrank/features/workout_session/presentation/widgets/today_workout_card.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final challenges = ref.watch(activeChallengesProvider).valueOrNull ?? [];
    final coach = ref.watch(currentCoachProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${user?.name.split(' ').first ?? ''} 👋'),
        actions: [
          IconButton(
            tooltip: 'Notificaciones',
            icon: const Icon(Icons.notifications_none),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                if (user.isStaff) ...[
                  Entrance(child: _CoachPanelCard(coach: coach)),
                  const SizedBox(height: 16),
                ],
                const Entrance(child: TodayWorkoutCard()),
                Entrance(child: _HeroHeader(user: user, coach: coach)),
                const SizedBox(height: 20),
                Entrance(
                  delay: const Duration(milliseconds: 90),
                  child: _HighlightsRow(user: user),
                ),
                const SizedBox(height: 22),
                Entrance(
                  delay: const Duration(milliseconds: 160),
                  child: _QuickActionsBar(),
                ),
                const SizedBox(height: 16),
                const Entrance(
                  delay: Duration(milliseconds: 200),
                  child: TodayMealsCard(),
                ),
                const SizedBox(height: 24),
                Entrance(
                  delay: const Duration(milliseconds: 220),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Retos activos', style: AppTextStyles.title),
                      TextButton(
                        onPressed: () => context.go('/challenges'),
                        child: const Text('Ver todos'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if (challenges.isEmpty)
                  const _EmptyState(
                    icon: Icons.flag_outlined,
                    message: 'No hay retos activos por ahora.',
                  )
                else
                  EntranceList(
                    initialDelay: const Duration(milliseconds: 260),
                    children: [
                      for (final c in challenges.take(3))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ChallengePreview(challenge: c),
                        ),
                    ],
                  ),
              ],
            ),
    );
  }
}

/// Atalho para o painel, só para quem tem papel de staff (coach,
/// nutrióloga, admin).
class _CoachPanelCard extends StatelessWidget {
  const _CoachPanelCard({required this.coach});

  final CoachEntity? coach;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.push('/coach'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.dashboard_customize,
                    color: AppColors.onPrimary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Panel de coach', style: AppTextStyles.title),
                    const SizedBox(height: 2),
                    Text(
                      coach == null
                          ? 'Configura tu marca y genera tu código'
                          : '${coach!.name} · ${coach!.studentCount} alumnos',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.user, required this.coach});

  final UserEntity user;
  final CoachEntity? coach;

  @override
  Widget build(BuildContext context) {
    final progress = LevelCalculator.progressToNextLevel(user.xpTotal);
    final xpToNext = LevelCalculator.xpToNextLevel(user.xpTotal);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.heroGradient,
        ),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          LevelRing(
            progress: progress,
            centerLabel: '${user.level}',
            caption: 'NIVEL',
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedCountText(
                      user.gymScore,
                      style: AppTextStyles.displayLarge.copyWith(fontSize: 30),
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 5),
                      child: Text('Gym Score', style: AppTextStyles.caption),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Te faltan $xpToNext XP para el nivel ${user.level + 1}',
                  style: AppTextStyles.bodyMuted,
                ),
                if (!user.isStaff && coach != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Entrenas con ${coach!.name}',
                    style: AppTextStyles.caption.copyWith(color: AppColors.primary),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: AppColors.warning, size: 18),
                    const SizedBox(width: 4),
                    AnimatedCountText(
                      user.currentStreakDays,
                      suffix: ' días',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Icon(Icons.bolt, color: AppColors.primary, size: 18),
                    const SizedBox(width: 2),
                    AnimatedCountText(
                      user.xpCurrentSeason,
                      suffix: ' XP',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Atalhos redondos. Cada um leva à tela onde aquele número "mora":
/// racha e nivel no perfil, Gym Score no ranking, logros na vitrine,
/// amigos na lista.
class _HighlightsRow extends ConsumerWidget {
  const _HighlightsRow({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achievements =
        ref.watch(unlockedAchievementsProvider).valueOrNull?.length;
    final friends = ref.watch(friendCountProvider);

    final items = [
      (
        Icons.local_fire_department,
        '${user.currentStreakDays}',
        'Racha',
        () => context.go('/profile'),
      ),
      (
        Icons.military_tech,
        '${user.level}',
        'Nivel',
        () => context.go('/profile'),
      ),
      (
        Icons.speed,
        user.gymScore.toStringAsFixed(0),
        'Gym Score',
        () => context.go('/rankings'),
      ),
      (
        Icons.emoji_events,
        achievements == null ? '…' : '$achievements',
        'Logros',
        () => context.push('/achievements'),
      ),
      (
        Icons.people_outline,
        friends == null ? '…' : '$friends',
        'Amigos',
        () => context.push('/friends'),
      ),
    ];
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, i) => _Highlight(
          icon: items[i].$1,
          value: items[i].$2,
          label: items[i].$3,
          onTap: items[i].$4,
        ),
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: AppColors.streakGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.assignment_outlined,
                label: 'Mi plan',
                onTap: () => context.push('/plans'),
              ),
            ),
            Expanded(
              child: _QuickAction(
                icon: Icons.fitness_center,
                label: 'Entrenar',
                onTap: () => context.push('/workout/new'),
              ),
            ),
            Expanded(
              child: _QuickAction(
                icon: Icons.qr_code_scanner,
                label: 'Check-in',
                onTap: () => context.push('/checkin'),
              ),
            ),
            Expanded(
              child: _QuickAction(
                icon: Icons.monitor_weight_outlined,
                label: 'Progreso',
                onTap: () => context.push('/body-measurement'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _ChallengePreview extends StatelessWidget {
  const _ChallengePreview({required this.challenge});

  final ChallengeEntity challenge;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go('/challenges'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flag, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(challenge.title, style: AppTextStyles.title),
                    const SizedBox(height: 2),
                    Text(
                      '+${challenge.xpReward} XP · ${challenge.participantCount} participantes',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.textSecondary),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.bodyMuted),
          ],
        ),
      ),
    );
  }
}
