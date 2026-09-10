import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymrank/core/error/failure.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/friendship/domain/entities/friendship_entity.dart';
import 'package:gymrank/features/friendship/domain/repositories/friendship_repository.dart';

class FirestoreFriendshipRepository implements FriendshipRepository {
  FirestoreFriendshipRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _friendships =>
      _firestore.collection('friendships');

  /// Id determinístico ordenado alfabeticamente para evitar pares
  /// duplicados (A pede B == B pede A).
  String _pairId(String a, String b) {
    final sorted = [a, b]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  @override
  Future<Result<void>> sendRequest({
    required String requesterId,
    required String addresseeUsername,
  }) async {
    try {
      final userQuery = await _firestore
          .collection('users')
          .where('usernameLowercase', isEqualTo: addresseeUsername.toLowerCase())
          .limit(1)
          .get();
      if (userQuery.docs.isEmpty) {
        return const Result.failure(Failure.notFound());
      }
      final addresseeId = userQuery.docs.first.id;
      if (addresseeId == requesterId) {
        return const Result.failure(
          Failure.validation('No puedes agregarte a ti mismo.'),
        );
      }
      final id = _pairId(requesterId, addresseeId);
      await _friendships.doc(id).set({
        'requesterId': requesterId,
        'addresseeId': addresseeId,
        'status': FriendshipStatus.pending.name,
        'createdAt': Timestamp.now(),
      });
      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(Failure.unexpected(e.message ?? e.code));
    }
  }

  @override
  Future<Result<void>> respond({
    required String friendshipId,
    required bool accept,
  }) async {
    try {
      await _friendships.doc(friendshipId).update({
        'status': (accept ? FriendshipStatus.accepted : FriendshipStatus.blocked).name,
        'respondedAt': Timestamp.now(),
      });
      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(Failure.unexpected(e.message ?? e.code));
    }
  }

  @override
  Future<Result<void>> block({
    required String userId,
    required String otherUserId,
  }) async {
    try {
      final id = _pairId(userId, otherUserId);
      await _friendships.doc(id).set({
        'requesterId': userId,
        'addresseeId': otherUserId,
        'status': FriendshipStatus.blocked.name,
        'createdAt': Timestamp.now(),
        'respondedAt': Timestamp.now(),
      }, SetOptions(merge: true));
      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(Failure.unexpected(e.message ?? e.code));
    }
  }

  @override
  Stream<List<FriendshipEntity>> watchFriendships(String userId) {
    final requester = _friendships.where('requesterId', isEqualTo: userId);
    final addressee = _friendships.where('addresseeId', isEqualTo: userId);

    return requester.snapshots().asyncMap((requesterSnap) async {
      final addresseeSnap = await addressee.get();
      final docs = [...requesterSnap.docs, ...addresseeSnap.docs];
      return docs.map((doc) {
        final data = doc.data();
        return FriendshipEntity(
          id: doc.id,
          requesterId: data['requesterId'] as String,
          addresseeId: data['addresseeId'] as String,
          status: FriendshipStatus.values.byName(data['status'] as String),
          createdAt: (data['createdAt'] as Timestamp).toDate(),
          respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
        );
      }).toList();
    });
  }
}
