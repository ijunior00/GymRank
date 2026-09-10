import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymrank/core/error/failure.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:gymrank/features/notifications/domain/repositories/notification_repository.dart';

class FirestoreNotificationRepository implements NotificationRepository {
  FirestoreNotificationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection('notifications');

  @override
  Stream<List<AppNotificationEntity>> watchAll(String userId) {
    return _notifications
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((doc) {
              final data = doc.data();
              return AppNotificationEntity(
                id: doc.id,
                userId: data['userId'] as String,
                type: NotificationType.values.byName(data['type'] as String),
                title: data['title'] as String,
                body: data['body'] as String,
                deepLink: data['deepLink'] as String?,
                read: data['read'] as bool? ?? false,
                createdAt: (data['createdAt'] as Timestamp).toDate(),
              );
            }).toList());
  }

  @override
  Future<Result<void>> markRead(String notificationId) async {
    try {
      await _notifications.doc(notificationId).update({'read': true});
      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(Failure.unexpected(e.message ?? e.code));
    }
  }

  @override
  Future<Result<void>> registerDeviceToken({
    required String userId,
    required String token,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(token)
          .set({'registeredAt': Timestamp.now()});
      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(Failure.unexpected(e.message ?? e.code));
    }
  }

  @override
  Future<Result<void>> removeDeviceToken({
    required String userId,
    required String token,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('fcmTokens')
          .doc(token)
          .delete();
      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(Failure.unexpected(e.message ?? e.code));
    }
  }
}
