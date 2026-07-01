import 'package:gymrank/features/gym_admin/domain/entities/gym_entity.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';

abstract interface class GymAdminRepository {
  Stream<GymDashboardStats> watchDashboardStats(String gymId);

  Stream<List<UserEntity>> watchStudents(String gymId, {int limit});

  Stream<GymEntity?> watchGym(String gymId);
}
