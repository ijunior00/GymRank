import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/features/coach_panel/domain/entities/coach_entity.dart';

/// Mapeia `coaches/{coachId}` <-> [CoachEntity].
abstract final class CoachDto {
  static CoachEntity fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CoachEntity(
      id: doc.id,
      ownerUserId: data['ownerUserId'] as String,
      name: data['name'] as String,
      tagline: data['tagline'] as String?,
      city: data['city'] as String? ?? '',
      country: data['country'] as String? ?? 'MX',
      logoUrl: data['logoUrl'] as String?,
      brandColorHex: data['brandColorHex'] as String?,
      instagramHandle: data['instagramHandle'] as String?,
      inviteCode: data['inviteCode'] as String,
      qrCodeSecret: data['qrCodeSecret'] as String? ?? '',
      plan: SubscriptionPlan.values.byName(data['plan'] as String? ?? 'free'),
      studentCount: data['studentCount'] as int? ?? 0,
      activeChallengeCount: data['activeChallengeCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  static Map<String, dynamic> toMap(CoachEntity coach) {
    return {
      'ownerUserId': coach.ownerUserId,
      'name': coach.name,
      'tagline': coach.tagline,
      'city': coach.city,
      'country': coach.country,
      'logoUrl': coach.logoUrl,
      'brandColorHex': coach.brandColorHex,
      'instagramHandle': coach.instagramHandle,
      'inviteCode': coach.inviteCode,
      'qrCodeSecret': coach.qrCodeSecret,
      'plan': coach.plan.name,
      'studentCount': coach.studentCount,
      'activeChallengeCount': coach.activeChallengeCount,
      'createdAt': Timestamp.fromDate(coach.createdAt),
    };
  }

  static CoachDashboardStats statsFromMap(Map<String, dynamic> data) {
    return CoachDashboardStats(
      totalStudents: data['totalStudents'] as int? ?? 0,
      activeStudents: data['activeStudents'] as int? ?? 0,
      workoutsToday: data['workoutsToday'] as int? ?? 0,
      workoutsThisWeek: data['workoutsThisWeek'] as int? ?? 0,
      newStudentsThisMonth: data['newStudentsThisMonth'] as int? ?? 0,
      inactiveStudents7d: data['inactiveStudents7d'] as int? ?? 0,
      retentionRate: (data['retentionRate'] as num?)?.toDouble() ?? 0,
      calculatedAt:
          (data['calculatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
