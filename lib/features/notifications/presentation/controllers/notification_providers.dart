import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/notifications/data/repositories/firestore_notification_repository.dart';
import 'package:gymrank/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:gymrank/features/notifications/domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return FirestoreNotificationRepository(ref.watch(firestoreProvider));
});

final myNotificationsProvider = StreamProvider<List<AppNotificationEntity>>((ref) {
  final uid = ref.watch(authStateProvider).valueOrNull;
  if (uid == null) return Stream.value(const []);
  return ref.watch(notificationRepositoryProvider).watchAll(uid);
});
