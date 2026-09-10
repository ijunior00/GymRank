import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymrank/features/coach_panel/domain/entities/client_entity.dart';

/// Mapeia `coaches/{coachId}/clients/{userId}` <-> [ClientEntity] e a
/// subcoleção `notes` <-> [CoachNoteEntity].
abstract final class ClientDto {
  static ClientEntity fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required String coachId,
  }) {
    final data = doc.data() ?? const {};
    return ClientEntity(
      userId: doc.id,
      coachId: coachId,
      status: ClientStatus.values.byName(data['status'] as String? ?? 'activo'),
      planName: data['planName'] as String?,
      startedAt: (data['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nextPaymentAt: (data['nextPaymentAt'] as Timestamp?)?.toDate(),
      tags: List<String>.from(data['tags'] as List? ?? const []),
      lastWorkoutAt: (data['lastWorkoutAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> toMap(ClientEntity client) {
    return {
      'userId': client.userId,
      'coachId': client.coachId,
      'status': client.status.name,
      'planName': client.planName,
      'startedAt': Timestamp.fromDate(client.startedAt),
      'nextPaymentAt': client.nextPaymentAt == null
          ? null
          : Timestamp.fromDate(client.nextPaymentAt!),
      'tags': client.tags,
      'lastWorkoutAt': client.lastWorkoutAt == null
          ? null
          : Timestamp.fromDate(client.lastWorkoutAt!),
      'createdAt': Timestamp.fromDate(client.createdAt),
    };
  }

  static CoachNoteEntity noteFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return CoachNoteEntity(
      id: doc.id,
      authorId: data['authorId'] as String,
      text: data['text'] as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
