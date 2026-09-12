import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/core/error/failure.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/progress_photo/domain/entities/progress_photo_entity.dart';
import 'package:gymrank/features/progress_photo/domain/repositories/progress_photo_repository.dart';

class FirebaseProgressPhotoRepository implements ProgressPhotoRepository {
  FirebaseProgressPhotoRepository(this._firestore, this._storage);

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('progress_photos');

  @override
  Stream<List<ProgressPhotoEntity>> watchAll(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('takenAt')
        .snapshots()
        .map((s) => s.docs.map(_fromSnapshot).toList());
  }

  @override
  Future<Result<ProgressPhotoEntity>> upload({
    required String userId,
    required Uint8List bytes,
    required ProgressPhotoCategory category,
    double? weightAtTimeKg,
  }) async {
    try {
      final takenAt = DateTime.now();
      final path =
          'progress_photos/$userId/${takenAt.millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref(path);
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      final doc = await _collection.add({
        'userId': userId,
        'storageUrl': url,
        'thumbnailUrl': url,
        'category': category.name,
        'takenAt': Timestamp.fromDate(takenAt),
        'weightAtTimeKg': weightAtTimeKg,
      });

      return Result.success(
        ProgressPhotoEntity(
          id: doc.id,
          userId: userId,
          storageUrl: url,
          thumbnailUrl: url,
          category: category,
          takenAt: takenAt,
          weightAtTimeKg: weightAtTimeKg,
        ),
      );
    } on FirebaseException catch (e) {
      return Result.failure(Failure.unexpected(e.message ?? e.code));
    }
  }

  ProgressPhotoEntity _fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ProgressPhotoEntity(
      id: doc.id,
      userId: data['userId'] as String,
      storageUrl: data['storageUrl'] as String,
      thumbnailUrl: data['thumbnailUrl'] as String,
      category: ProgressPhotoCategory.values.byName(data['category'] as String),
      takenAt: (data['takenAt'] as Timestamp).toDate(),
      weightAtTimeKg: (data['weightAtTimeKg'] as num?)?.toDouble(),
    );
  }
}
