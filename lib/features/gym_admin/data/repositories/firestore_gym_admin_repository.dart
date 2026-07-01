import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/features/gym_admin/domain/entities/gym_entity.dart';
import 'package:gymrank/features/gym_admin/domain/repositories/gym_admin_repository.dart';
import 'package:gymrank/features/profile/data/dtos/user_dto.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';

class FirestoreGymAdminRepository implements GymAdminRepository {
  FirestoreGymAdminRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<GymDashboardStats> watchDashboardStats(String gymId) {
    return _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('stats')
        .doc('current')
        .snapshots()
        .map((doc) {
      final data = doc.data() ?? const {};
      return GymDashboardStats(
        totalStudents: data['totalStudents'] as int? ?? 0,
        checkInsToday: data['checkInsToday'] as int? ?? 0,
        checkInsThisWeek: data['checkInsThisWeek'] as int? ?? 0,
        newStudentsThisMonth: data['newStudentsThisMonth'] as int? ?? 0,
        inactiveStudents30d: data['inactiveStudents30d'] as int? ?? 0,
        retentionRate: (data['retentionRate'] as num?)?.toDouble() ?? 0,
        calculatedAt:
            (data['calculatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
    });
  }

  @override
  Stream<List<UserEntity>> watchStudents(String gymId, {int limit = 50}) {
    return _firestore
        .collection('users')
        .where('gymId', isEqualTo: gymId)
        .where('role', isEqualTo: UserRole.aluno.name)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(UserDto.fromSnapshot).toList());
  }

  @override
  Stream<GymEntity?> watchGym(String gymId) {
    return _firestore.collection('gyms').doc(gymId).snapshots().map((doc) {
      if (!doc.exists) return null;
      final data = doc.data()!;
      return GymEntity(
        id: doc.id,
        name: data['name'] as String,
        city: data['city'] as String,
        logoUrl: data['logoUrl'] as String?,
        brandColorHex: data['brandColorHex'] as String?,
        qrCodeSecret: data['qrCodeSecret'] as String,
        plan: SubscriptionPlan.values.byName(data['plan'] as String? ?? 'free'),
        studentCount: data['studentCount'] as int? ?? 0,
        activeChallengeCount: data['activeChallengeCount'] as int? ?? 0,
        createdAt: (data['createdAt'] as Timestamp).toDate(),
      );
    });
  }
}
