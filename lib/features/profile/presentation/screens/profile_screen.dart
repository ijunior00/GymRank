import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/utils/date_formatter.dart';
import 'package:gymrank/core/utils/share_text.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_controller.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/coach_panel/domain/entities/coach_entity.dart';
import 'package:gymrank/features/coach_panel/presentation/controllers/coach_panel_providers.dart';
import 'package:gymrank/features/coach_panel/presentation/widgets/join_coach_dialog.dart';
import 'package:gymrank/features/friendship/presentation/controllers/friendship_providers.dart';
import 'package:gymrank/features/gamification/presentation/widgets/level_progress_card.dart';
import 'package:gymrank/features/gamification/presentation/widgets/streak_card.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';
import 'package:gymrank/features/sharing/domain/entities/share_card.dart';
import 'package:gymrank/features/sharing/presentation/controllers/share_providers.dart';
import 'package:gymrank/features/sharing/presentation/screens/share_card_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final coach = ref.watch(currentCoachProvider).valueOrNull;
    final friends = ref.watch(friendCountProvider);

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
                    // Um terço da largura para cada, senão o rótulo mais
                    // longo ("Gym Score") empurra os outros para fora.
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatColumn(
                            label: 'Gym Score',
                            value: user.gymScore.toStringAsFixed(0),
                          ),
                        ),
                        Expanded(
                          child: _StatColumn(
                            label: 'XP total',
                            value: '${user.xpTotal}',
                          ),
                        ),
                        Expanded(
                          child: _StatColumn(
                            label: 'Amigos',
                            value: friends == null ? '—' : '$friends',
                            onTap: () => context.push('/friends'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ShareAndInviteCard(user: user),
                const SizedBox(height: 16),
                // Vínculo com a treinadora: painel (coach), ficha da coach
                // (aluno vinculado) ou entrada por código (aluno solto).
                if (user.isStaff)
                  ListTile(
                    leading: const Icon(Icons.dashboard_customize_outlined),
                    title: const Text('Panel de coach'),
                    subtitle: Text(coach?.name ?? 'Configura tu marca'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/coach'),
                  )
                else if (user.coachId != null) ...[
                  ListTile(
                    leading: const Icon(Icons.verified_outlined, color: AppColors.primary),
                    title: const Text('Tu coach'),
                    subtitle: Text(coach?.name ?? 'Cargando…'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: coach == null
                        ? null
                        : () => showCoachSheet(context, coach),
                  ),
                  _MyPlanTile(coach: coach),
                ] else
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
                  title: const Text('Torneos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/championships'),
                ),
              ],
            ),
    );
  }
}

/// O plano que o aluno tem com a treinadora (nome do plano e próximo
/// pago), lido do vínculo `clients`. Substitui a antiga "Suscripción
/// Premium", que era do app genérico e aqui não fazia sentido: quem cobra
/// é a coach, não o app.
class _MyPlanTile extends ConsumerWidget {
  const _MyPlanTile({required this.coach});

  final CoachEntity? coach;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final client = ref.watch(myClientProvider).valueOrNull;
    final plan = client?.planName;
    final nextPayment = client?.nextPaymentAt;
    final subtitle = [
      plan ?? 'Sin plan asignado todavía',
      if (nextPayment != null)
        'próximo pago ${DateFormatter.shortDate(nextPayment)}',
    ].join(' · ');

    return ListTile(
      leading: const Icon(Icons.receipt_long_outlined),
      title: Text(coach == null ? 'Mi plan' : 'Mi plan con ${coach!.name}'),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: coach == null ? null : () => showCoachSheet(context, coach!),
    );
  }
}

/// Ficha pública da treinadora: quem é, onde está, Instagram e o código
/// de convite para o aluno passar adiante.
Future<void> showCoachSheet(BuildContext context, CoachEntity coach) {
  // Copiar e invitar fecham a folha antes de mostrar o aviso: um SnackBar
  // com a folha aberta fica escondido atrás dela.
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                backgroundImage:
                    coach.logoUrl != null ? NetworkImage(coach.logoUrl!) : null,
                child: coach.logoUrl == null
                    ? Text(
                        coach.name.isEmpty ? '?' : coach.name[0].toUpperCase(),
                        style: AppTextStyles.headline
                            .copyWith(color: AppColors.primary),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(coach.name, style: AppTextStyles.headline),
                    if (coach.tagline != null)
                      Text(coach.tagline!, style: AppTextStyles.bodyMuted),
                    Text(
                      '${coach.city} · ${coach.studentCount} alumnos',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (coach.instagramHandle != null)
            OutlinedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse('https://instagram.com/${coach.instagramHandle}'),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: Text('@${coach.instagramHandle}'),
            ),
          const SizedBox(height: 16),
          Text('CÓDIGO DE INVITACIÓN',
              style: AppTextStyles.caption.copyWith(letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  coach.inviteCode,
                  style: AppTextStyles.displayLarge.copyWith(
                    fontSize: 28,
                    letterSpacing: 4,
                    color: AppColors.primary,
                  ),
                ),
              ),
              IconButton.filledTonal(
                tooltip: 'Copiar',
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await Clipboard.setData(ClipboardData(text: coach.inviteCode));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Código copiado.')),
                  );
                },
                icon: const Icon(Icons.copy),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(sheetContext).pop();
              shareText(
                context,
                'Entreno con ${coach.name} 💪 Únete a la comunidad en '
                'AnahiFitness con el código ${coach.inviteCode}.',
              );
            },
            icon: const Icon(Icons.ios_share, size: 18),
            label: const Text('Invitar a alguien'),
          ),
        ],
      ),
    ),
  );
}

/// Marketing na mão do aluno: compartilhar a racha ou o nível e ver
/// quantas pessoas já entraram por indicação dele.
class _ShareAndInviteCard extends ConsumerWidget {
  const _ShareAndInviteCard({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coach = ref.watch(currentCoachProvider).valueOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Comparte tu progreso',
                      style: AppTextStyles.title),
                ),
                if (user.referralCount > 0)
                  Text('${user.referralCount} invitados',
                      style: AppTextStyles.caption
                          .copyWith(color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              coach == null
                  ? 'Presume tu racha y tu nivel con una imagen lista para '
                      'historias.'
                  : 'Cada imagen lleva la marca de ${coach.name} y el código '
                      '${coach.inviteCode} para que te sigan.',
              style: AppTextStyles.bodyMuted,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showShareCard(
                      context,
                      buildShareCard(
                        ref,
                        kind: ShareCardKind.racha,
                        eyebrow: 'Mi racha',
                        value: '${user.currentStreakDays} días',
                        caption: 'entrenando sin parar',
                      ),
                    ),
                    icon: const Icon(Icons.local_fire_department, size: 18),
                    label: const Text('Racha'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => showShareCard(
                      context,
                      buildShareCard(
                        ref,
                        kind: ShareCardKind.nivel,
                        eyebrow: 'Mi nivel',
                        value: 'Nivel ${user.level}',
                        caption: '${user.xpTotal} XP acumulados',
                      ),
                    ),
                    icon: const Icon(Icons.military_tech, size: 18),
                    label: const Text('Nivel'),
                  ),
                ),
              ],
            ),
          ],
        ),
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
  const _StatColumn({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final column = Column(
      children: [
        Text(
          value,
          style: AppTextStyles.statValue,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
    if (onTap == null) return column;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: column,
      ),
    );
  }
}
