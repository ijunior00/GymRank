import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymrank/core/error/failure.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';
import 'package:gymrank/features/sharing/domain/entities/share_card.dart';
import 'package:gymrank/features/sharing/domain/repositories/share_repository.dart';

class FirestoreShareRepository implements ShareRepository {
  FirestoreShareRepository(this._firestore, this._user);

  final FirebaseFirestore _firestore;

  /// Perfil do usuário logado no momento da chamada (pode ser nulo).
  final UserEntity? _user;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('share_cards');

  @override
  Future<Result<void>> recordShare(ShareCardKind kind) async {
    final user = _user;
    if (user == null) return const Result.success(null);
    try {
      await _collection.add({
        'userId': user.id,
        'userName': user.name,
        'coachId': user.coachId,
        'type': kind.name,
        'sharedAt': Timestamp.now(),
      });
      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(Failure.unexpected(e.message ?? e.code));
    }
  }

  @override
  Stream<List<ShareEventEntity>> watchRecent(String coachId, {int limit = 15}) {
    return _collection
        .where('coachId', isEqualTo: coachId)
        .orderBy('sharedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((doc) {
              final d = doc.data();
              return ShareEventEntity(
                id: doc.id,
                userId: d['userId'] as String? ?? '',
                userName: d['userName'] as String? ?? '',
                kind: ShareCardKind.values
                    .asNameMap()[d['type'] as String? ?? '']
                    ?? ShareCardKind.entrenamiento,
                sharedAt: (d['sharedAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
              );
            }).toList());
  }
}
