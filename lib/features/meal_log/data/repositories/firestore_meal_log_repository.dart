import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymrank/core/error/failure.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/meal_log/domain/entities/meal_log_entity.dart';
import 'package:gymrank/features/meal_log/domain/repositories/meal_log_repository.dart';

class FirestoreMealLogRepository implements MealLogRepository {
  FirestoreMealLogRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _logs =>
      _firestore.collection('meal_logs');

  @override
  Future<Result<void>> setStatus({
    required String userId,
    required String? coachId,
    required String planId,
    required String date,
    required int mealIndex,
    required String mealName,
    required MealStatus? status,
  }) async {
    try {
      final ref = _logs.doc(MealLogEntity.idFor(userId, date, mealIndex));
      if (status == null) {
        await ref.delete();
      } else {
        await ref.set({
          'userId': userId,
          'coachId': coachId,
          'planId': planId,
          'date': date,
          'mealIndex': mealIndex,
          'mealName': mealName,
          'status': status.name,
          'createdAt': Timestamp.now(),
        });
      }
      return const Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(_mapException(e));
    }
  }

  @override
  Stream<List<MealLogEntity>> watchDay(String userId, String date) {
    return _logs
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: date)
        .snapshots()
        .map((s) => s.docs.map(_fromSnapshot).toList());
  }

  @override
  Stream<List<MealLogEntity>> watchRange(
    String userId, {
    required String fromDate,
    required String toDate,
  }) {
    return _logs
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: fromDate)
        .where('date', isLessThanOrEqualTo: toDate)
        .snapshots()
        .map((s) => s.docs.map(_fromSnapshot).toList());
  }

  MealLogEntity _fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return MealLogEntity(
      id: doc.id,
      userId: d['userId'] as String,
      coachId: d['coachId'] as String?,
      planId: d['planId'] as String? ?? '',
      date: d['date'] as String,
      mealIndex: (d['mealIndex'] as num).toInt(),
      mealName: d['mealName'] as String? ?? '',
      status: MealStatus.values.byName(d['status'] as String? ?? 'hecha'),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Failure _mapException(FirebaseException e) {
    return switch (e.code) {
      'permission-denied' => const Failure.permissionDenied(),
      'unavailable' => const Failure.network(),
      _ => Failure.unexpected(e.message ?? e.code),
    };
  }
}
