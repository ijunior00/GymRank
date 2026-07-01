import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/notifications/presentation/controllers/notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(myNotificationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notificações')),
      body: notifications.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Nenhuma notificação.'));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final n = list[i];
              return ListTile(
                leading: Icon(
                  n.read ? Icons.notifications_none : Icons.notifications_active,
                  color: n.read ? AppColors.textSecondary : AppColors.primary,
                ),
                title: Text(n.title, style: AppTextStyles.title),
                subtitle: Text(n.body, style: AppTextStyles.bodyMuted),
                onTap: () => ref.read(notificationRepositoryProvider).markRead(n.id),
              );
            },
          );
        },
      ),
    );
  }
}
