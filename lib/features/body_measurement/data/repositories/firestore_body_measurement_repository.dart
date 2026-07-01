import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymrank/core/error/failure.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/body_measurement/data/dtos/body_measurement_dto.dart';
import 'package:gymrank/features/body_measurement/domain/entities/body_measurement_entity.dart';
import 'package:gymrank/features/body_measurement/domain/repositories/body_measurement_repository.dart';

class FirestoreBodyMeasurementRepository
    implements BodyMeasurementRepository {
  FirestoreBodyMeasurementRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('body_measurements');

  @override
  Stream<List<BodyMeasurementEntity>> watchHistory(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('recordedAt')
        .snapshots()
        .map((s) => s.docs.map(BodyMeasurementDto.fromSnapshot).toList());
  }

  @override
  Future<Result<BodyMeasurementEntity>> add(
    BodyMeasurementEntity entry,
  ) async {
    try {
      final doc = await _collection.add(BodyMeasurementDto.toMap(entry));
      return Result.success(entry.copyWith(id: doc.id));
    } on FirebaseException catch (e) {
      return Result.failure(Failure.unexpected(e.message ?? e.code));
    }
  }
}
