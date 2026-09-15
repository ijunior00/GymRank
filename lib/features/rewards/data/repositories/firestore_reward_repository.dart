import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gymrank/core/error/failure.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/rewards/domain/entities/reward_entity.dart';
import 'package:gymrank/features/rewards/domain/repositories/reward_repository.dart';

class FirestoreRewardRepository implements RewardRepository {
  FirestoreRewardRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _rewards =>
      _firestore.collection('rewards');

  @override
  Stream<List<RewardGrantEntity>> watchMyGrants(String userId) {
    return _firestore
        .collectionGroup('grants')
        .where('userId', isEqualTo: userId)
        .orderBy('grantedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((doc) {
              final data = doc.data();
              return RewardGrantEntity(
                id: doc.id,
                rewardId: data['rewardId'] as String,
                userId: data['userId'] as String,
                sourceType: data['sourceType'] as String,
                sourceId: data['sourceId'] as String,
                status: RewardStatus.values.byName(data['status'] as String),
                grantedAt: (data['grantedAt'] as Timestamp).toDate(),
                redeemedAt: (data['redeemedAt'] as Timestamp?)?.toDate(),
              );
            }).toList());
  }

  @override
  Stream<RewardEntity?> watchReward(String rewardId) {
    return _rewards.doc(rewardId).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      return _fromData(doc.id, data);
    });
  }

  @override
  Stream<List<RewardEntity>> watchByCoach(String coachId) {
    // Sem orderBy: dispensa índice composto; a lista é pequena e a ordem
    // alfabética sai daqui mesmo.
    return _rewards.where('coachId', isEqualTo: coachId).snapshots().map((s) {
      final list = s.docs.map((d) => _fromData(d.id, d.data())).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  @override
  Future<Result<RewardEntity>> save(
    RewardEntity reward, {
    Uint8List? imageBytes,
  }) async {
    try {
      final ref = reward.id.isEmpty ? _rewards.doc() : _rewards.doc(reward.id);
      var saved = reward.copyWith(id: ref.id, name: reward.name.trim());
      if (reward.id.isEmpty) {
        await ref.set({
          'coachId': saved.coachId,
          'name': saved.name,
          'type': saved.type.name,
          'stock': saved.stock,
          'imageUrl': saved.imageUrl,
          'createdAt': Timestamp.now(),
        });
      } else {
        await ref.update({
          'name': saved.name,
          'type': saved.type.name,
          'stock': saved.stock,
        });
      }

      // A foto só depois de existir o documento: a regra do Storage
      // confere que o prêmio é desta treinadora antes de aceitar o upload.
      if (imageBytes != null) {
        final path = 'reward_images/${ref.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final fileRef = _storage.ref(path);
        await fileRef.putData(imageBytes, SettableMetadata(contentType: 'image/jpeg'));
        final url = await fileRef.getDownloadURL();
        await ref.update({'imageUrl': url});
        saved = saved.copyWith(imageUrl: url);
      }
      return Result.success(saved);
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  /// Prêmios são cadastrados à mão no console ou pela treinadora: campo
  /// faltando não pode virar tela quebrada.
  RewardEntity _fromData(String id, Map<String, dynamic> data) {
    return RewardEntity(
      id: id,
      coachId: data['coachId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      imageUrl: data['imageUrl'] as String?,
      type: RewardType.values.asNameMap()[data['type'] as String? ?? ''] ??
          RewardType.acessorio,
      stock: (data['stock'] as num?)?.toInt() ?? 0,
    );
  }

  Failure _mapException(FirebaseException e) {
    return switch (e.code) {
      'permission-denied' => const Failure.permissionDenied(),
      'not-found' => const Failure.notFound(),
      'unavailable' => const Failure.network(),
      'canceled' => const Failure.validation('Subida cancelada.'),
      _ => Failure.unexpected(e.message ?? e.code),
    };
  }
}
