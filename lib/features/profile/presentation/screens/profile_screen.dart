import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_controller.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/coach_panel/presentation/controllers/coach_panel_providers.dart';
import 'package:gymrank/features/coach_panel/presentation/widgets/join_coach_dialog.dart';
import 'package:gymrank/features/gamification/presentation/widgets/level_progress_card.dart';
import 'package:gymrank/features/gamification/presentation/widgets/streak_card.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final coach = ref.watch(currentCoachProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          if (user?.isStaff ?? false)
            IconButton(
              tooltip: 'Panel de coach',
              icon: const Icon(Icons.dashboard_customize_outlined),
              onPressed: () => context.push('/coach'),
            ),
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ProfileHeader(user: user),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: LevelProgressCard(user: user)),
                    const SizedBox(width: 12),
                    Expanded(child: StreakCard(user: user)),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatColumn(label: 'Gym Score', value: user.gymScore.toStringAsFixed(0)),
                        _StatColumn(label: 'XP total', value: '${user.xpTotal}'),
                        const _StatColumn(label: 'Amigos', value: '—'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Vínculo com a treinadora: painel (coach), nome da coach
                // (aluno vinculado) ou entrada por código (aluno solto).
                if (user.isStaff)
                  ListTile(
                    leading: const Icon(Icons.dashboard_customize_outlined),
                    title: const Text('Panel de coach'),
                    subtitle: Text(coach?.name ?? 'Configura tu marca'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/coach'),
                  )
                else if (user.coachId != null)
                  ListTile(
                    leading: const Icon(Icons.verified_outlined, color: AppColors.primary),
                    title: const Text('Tu coach'),
                    subtitle: Text(coach?.name ?? 'Cargando…'),
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.group_add_outlined),
                    title: const Text('Unirme a mi coach'),
                    subtitle: const Text('Escribe el código que te compartió'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showJoinCoachDialog(context, ref, userId: user.id),
                  ),
                ListTile(
                  leading: const Icon(Icons.assignment_outlined),
                  title: const Text('Mis planes'),
                  subtitle: const Text('Entrenamiento, alimentación y macros'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/plans'),
                ),
                ListTile(
                  leading: const Icon(Icons.timeline_outlined),
                  title: const Text('Progreso corporal'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/body-measurement'),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Fotos de progreso'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/progress-photos'),
                ),
                ListTile(
                  leading: const Icon(Icons.emoji_events_outlined),
                  title: const Text('Logros'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/achievements'),
                ),
                ListTile(
                  leading: const Icon(Icons.people_outline),
                  title: const Text('Amigos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/friends'),
                ),
                ListTile(
                  leading: const Icon(Icons.card_giftcard_outlined),
                  title: const Text('Mis premios'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/rewards'),
                ),
                ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: const Text('Suscripción Premium'),
                  trailing: Text(user.isPremium ? 'Activa' : 'Gratis', style: AppTextStyles.caption),
                ),
              ],
            ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: AppColors.streakGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.background,
            child: CircleAvatar(
              radius: 33,
              backgroundColor: AppColors.surfaceElevated,
              backgroundImage:
                  user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
              child: user.photoUrl == null
                  ? const Icon(Icons.person, size: 34, color: AppColors.textSecondary)
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: AppTextStyles.headline),
              const SizedBox(height: 2),
              Text('@${user.username}', style: AppTextStyles.bodyMuted),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Nivel ${user.level}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.statValue),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
