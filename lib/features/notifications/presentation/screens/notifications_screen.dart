import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/utils/date_formatter.dart';
import 'package:gymrank/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:gymrank/features/notifications/presentation/controllers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(myNotificationsProvider);
    final unread =
        notifications.valueOrNull?.where((n) => !n.read).toList() ?? const [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (unread.isNotEmpty)
            TextButton(
              onPressed: () {
                final repo = ref.read(notificationRepositoryProvider);
                for (final n in unread) {
                  repo.markRead(n.id);
                }
              },
              child: const Text('Marcar leídas'),
            ),
        ],
      ),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aún no hay notificaciones.'));
          }
          return ListView.separated(
            itemCount: list.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (context, i) => _NotificationTile(notification: list[i]),
          );
        },
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.notification});

  final AppNotificationEntity notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = notification;
    final hasLink = n.deepLink != null && n.deepLink!.startsWith('/');
    return ListTile(
      tileColor: n.read ? null : AppColors.primary.withValues(alpha: 0.06),
      leading: Icon(
        _iconFor(n.type),
        color: n.read ? AppColors.textSecondary : AppColors.primary,
      ),
      title: Text(
        n.title,
        style: n.read
            ? AppTextStyles.body
            : AppTextStyles.title,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(n.body, style: AppTextStyles.bodyMuted),
          const SizedBox(height: 2),
          Text(DateFormatter.relative(n.createdAt), style: AppTextStyles.caption),
        ],
      ),
      trailing: hasLink
          ? const Icon(Icons.chevron_right, color: AppColors.textSecondary)
          : null,
      // Marca como lida e leva à tela de que a notificação fala — antes só
      // marcava, e o toque parecia não fazer nada.
      onTap: () {
        if (!n.read) {
          ref.read(notificationRepositoryProvider).markRead(n.id);
        }
        if (hasLink) context.push(n.deepLink!);
      },
    );
  }

  IconData _iconFor(NotificationType type) => switch (type) {
        NotificationType.workoutReminder => Icons.fitness_center,
        NotificationType.newChallenge => Icons.flag_outlined,
        NotificationType.friendOvertook => Icons.leaderboard_outlined,
        NotificationType.newLevel => Icons.military_tech_outlined,
        NotificationType.newAchievement => Icons.emoji_events_outlined,
        NotificationType.championshipEnded => Icons.workspace_premium_outlined,
        NotificationType.rewardAvailable => Icons.card_giftcard_outlined,
        NotificationType.newStudent => Icons.person_add_alt_1_outlined,
        NotificationType.planPublished => Icons.assignment_outlined,
        NotificationType.personalRecord => Icons.bolt_outlined,
        NotificationType.referralJoined => Icons.volunteer_activism_outlined,
      };
}
