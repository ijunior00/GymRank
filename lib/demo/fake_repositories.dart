// PREVIEW/DEMO ONLY. Implementações in-memory das interfaces de
// repositório, usadas por lib/main_demo.dart para rodar o app sem
// Firebase. Ações de escrita são no-op que retornam sucesso.
import 'dart:io';

import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/demo/demo_data.dart';
import 'package:gymrank/features/auth/domain/repositories/auth_repository.dart';
import 'package:gymrank/features/body_measurement/domain/entities/body_measurement_entity.dart';
import 'package:gymrank/features/body_measurement/domain/repositories/body_measurement_repository.dart';
import 'package:gymrank/features/challenges/domain/entities/challenge_entity.dart';
import 'package:gymrank/features/challenges/domain/repositories/challenge_repository.dart';
import 'package:gymrank/features/championships/domain/entities/championship_entity.dart';
import 'package:gymrank/features/championships/domain/repositories/championship_repository.dart';
import 'package:gymrank/features/checkin/domain/entities/checkin_entity.dart';
import 'package:gymrank/features/checkin/domain/repositories/checkin_repository.dart';
import 'package:gymrank/features/coach_panel/domain/entities/client_entity.dart';
import 'package:gymrank/features/coach_panel/domain/entities/coach_entity.dart';
import 'package:gymrank/features/coach_panel/domain/repositories/coach_panel_repository.dart';
import 'package:gymrank/features/friendship/domain/entities/friendship_entity.dart';
import 'package:gymrank/features/friendship/domain/repositories/friendship_repository.dart';
import 'package:gymrank/features/gamification/domain/entities/achievement_entity.dart';
import 'package:gymrank/features/gamification/domain/repositories/achievement_repository.dart';
import 'package:gymrank/features/notifications/domain/entities/app_notification_entity.dart';
import 'package:gymrank/features/notifications/domain/repositories/notification_repository.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';
import 'package:gymrank/features/profile/domain/repositories/user_repository.dart';
import 'package:gymrank/features/progress_photo/domain/entities/progress_photo_entity.dart';
import 'package:gymrank/features/progress_photo/domain/repositories/progress_photo_repository.dart';
import 'package:gymrank/features/rankings/domain/entities/ranking_entry_entity.dart';
import 'package:gymrank/features/rankings/domain/repositories/ranking_repository.dart';
import 'package:gymrank/features/rewards/domain/entities/reward_entity.dart';
import 'package:gymrank/features/rewards/domain/repositories/reward_repository.dart';
import 'package:gymrank/features/social_feed/domain/entities/post_entity.dart';
import 'package:gymrank/features/social_feed/domain/repositories/feed_repository.dart';
import 'package:gymrank/features/workout/domain/entities/workout_entity.dart';
import 'package:gymrank/features/workout/domain/repositories/workout_repository.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Stream<String?> authStateChanges() => Stream.value(DemoData.uid);

  @override
  Future<Result<UserEntity>> currentUser() async =>
      Result.success(DemoData.user);

  @override
  Future<Result<String>> signInWithGoogle() async =>
      Result.success(DemoData.uid);

  @override
  Future<Result<String>> signInWithApple() async =>
      Result.success(DemoData.uid);

  @override
  Future<Result<String>> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      Result.success(DemoData.uid);

  @override
  Future<Result<String>> registerWithEmail({
    required String email,
    required String password,
  }) async =>
      Result.success(DemoData.uid);

  @override
  Future<Result<void>> sendPhoneVerificationCode(String phoneNumber) async =>
      const Result.success(null);

  @override
  Future<Result<String>> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async =>
      Result.success(DemoData.uid);

  @override
  Future<Result<bool>> isUsernameAvailable(String username) async =>
      const Result.success(true);

  @override
  Future<Result<UserEntity>> completeSignUp({
    required String uid,
    required SignUpData data,
  }) async =>
      Result.success(DemoData.user);

  @override
  Future<void> signOut() async {}
}

class FakeUserRepository implements UserRepository {
  UserEntity _resolve(String uid) => DemoData.studentById(uid) ?? DemoData.user;

  @override
  Future<Result<UserEntity>> getById(String uid) async =>
      Result.success(_resolve(uid));

  @override
  Future<Result<UserEntity>> create(UserEntity user) async =>
      Result.success(user);

  @override
  Future<Result<UserEntity>> update(UserEntity user) async =>
      Result.success(user);

  @override
  Future<Result<bool>> isUsernameAvailable(String username) async =>
      const Result.success(true);

  @override
  Stream<Result<UserEntity>> watch(String uid) =>
      Stream.value(Result.success(_resolve(uid)));
}

class FakeBodyMeasurementRepository implements BodyMeasurementRepository {
  @override
  Stream<List<BodyMeasurementEntity>> watchHistory(String userId) =>
      Stream.value(DemoData.measurements);

  @override
  Future<Result<BodyMeasurementEntity>> add(BodyMeasurementEntity entry) async =>
      Result.success(entry);
}

class FakeProgressPhotoRepository implements ProgressPhotoRepository {
  @override
  Stream<List<ProgressPhotoEntity>> watchAll(String userId) =>
      Stream.value(const []);

  @override
  Future<Result<ProgressPhotoEntity>> upload({
    required String userId,
    required File file,
    required ProgressPhotoCategory category,
    double? weightAtTimeKg,
  }) async =>
      Result.success(
        ProgressPhotoEntity(
          id: 'demo',
          userId: userId,
          storageUrl: '',
          thumbnailUrl: '',
          category: category,
          takenAt: DateTime.now(),
        ),
      );
}

class FakeCheckInRepository implements CheckInRepository {
  @override
  Future<Result<CheckInEntity>> submitQrPayload(String qrPayload) async =>
      Result.success(
        CheckInEntity(
          id: 'demo',
          userId: DemoData.uid,
          coachId: DemoData.coachId,
          checkedInAt: DateTime.now(),
          xpGranted: AppConstants.xpCheckIn,
          countedForStreak: true,
        ),
      );

  @override
  Stream<List<CheckInEntity>> watchRecent(String userId, {int limit = 10}) =>
      Stream.value(const []);
}

class FakeWorkoutRepository implements WorkoutRepository {
  @override
  Stream<List<WorkoutEntity>> watchRecent(String userId, {int limit = 20}) =>
      Stream.value(DemoData.workouts);

  @override
  Future<Result<WorkoutEntity>> log(WorkoutEntity workout) async =>
      Result.success(workout);
}

class FakeRankingRepository implements RankingRepository {
  @override
  Stream<List<RankingEntryEntity>> watch({
    required RankingScope scope,
    required RankingCriteria criteria,
    String? scopeId,
    int limit = 100,
  }) =>
      Stream.value(DemoData.rankings(scope, criteria));
}

class FakeChallengeRepository implements ChallengeRepository {
  @override
  Stream<List<ChallengeEntity>> watchActive({String? coachId}) =>
      Stream.value(DemoData.challenges);

  @override
  Future<Result<void>> join({
    required String challengeId,
    required String userId,
  }) async =>
      const Result.success(null);

  @override
  Stream<ChallengeParticipantEntity?> watchParticipation({
    required String challengeId,
    required String userId,
  }) =>
      Stream.value(null);
}

class FakeChampionshipRepository implements ChampionshipRepository {
  @override
  Stream<List<ChampionshipEntity>> watchByCoach(String coachId) =>
      Stream.value(DemoData.championships);
}

class FakeRewardRepository implements RewardRepository {
  @override
  Stream<List<RewardGrantEntity>> watchMyGrants(String userId) =>
      Stream.value(DemoData.rewardGrants);
}

class FakeFeedRepository implements FeedRepository {
  @override
  Stream<List<PostEntity>> watchFeed({int limit = 15}) =>
      Stream.value(DemoData.feed);

  @override
  Future<Result<void>> toggleLike({
    required String postId,
    required String userId,
    required bool liked,
  }) async =>
      const Result.success(null);

  @override
  Future<Result<void>> addComment(CommentEntity comment) async =>
      const Result.success(null);

  @override
  Stream<List<CommentEntity>> watchComments(String postId) =>
      Stream.value(const []);
}

class FakeFriendshipRepository implements FriendshipRepository {
  @override
  Future<Result<void>> sendRequest({
    required String requesterId,
    required String addresseeUsername,
  }) async =>
      const Result.success(null);

  @override
  Future<Result<void>> respond({
    required String friendshipId,
    required bool accept,
  }) async =>
      const Result.success(null);

  @override
  Future<Result<void>> block({
    required String userId,
    required String otherUserId,
  }) async =>
      const Result.success(null);

  @override
  Stream<List<FriendshipEntity>> watchFriendships(String userId) =>
      Stream.value(DemoData.friendships);
}

class FakeNotificationRepository implements NotificationRepository {
  @override
  Stream<List<AppNotificationEntity>> watchAll(String userId) =>
      Stream.value(DemoData.notifications);

  @override
  Future<Result<void>> markRead(String notificationId) async =>
      const Result.success(null);

  @override
  Future<Result<void>> registerDeviceToken({
    required String userId,
    required String token,
  }) async =>
      const Result.success(null);
}

class FakeAchievementRepository implements AchievementRepository {
  @override
  Stream<List<UserAchievementEntity>> watchUnlocked(String userId) =>
      Stream.value(DemoData.achievements);
}

class FakeCoachPanelRepository implements CoachPanelRepository {
  @override
  Stream<CoachEntity?> watchCoach(String coachId) =>
      Stream.value(DemoData.coach);

  @override
  Future<Result<CoachEntity>> createCoach(CoachEntity coach) async =>
      Result.success(coach.copyWith(id: DemoData.coachId));

  @override
  Future<Result<CoachEntity>> findByInviteCode(String inviteCode) async =>
      Result.success(DemoData.coach);

  @override
  Future<Result<CoachEntity>> joinCoach({
    required String userId,
    required String inviteCode,
  }) async =>
      Result.success(DemoData.coach);

  @override
  Stream<CoachDashboardStats?> watchDashboardStats(String coachId) =>
      Stream.value(DemoData.coachStats);

  @override
  Stream<List<UserEntity>> watchStudents(String coachId, {int limit = 200}) =>
      Stream.value(DemoData.students);

  @override
  Stream<List<ClientEntity>> watchClients(String coachId) =>
      Stream.value(DemoData.clients);

  @override
  Stream<ClientEntity?> watchClient({
    required String coachId,
    required String userId,
  }) {
    for (final c in DemoData.clients) {
      if (c.userId == userId) return Stream.value(c);
    }
    return Stream.value(null);
  }

  @override
  Future<Result<void>> updateClient(ClientEntity client) async =>
      const Result.success(null);

  @override
  Stream<List<CoachNoteEntity>> watchNotes({
    required String coachId,
    required String userId,
  }) =>
      Stream.value(DemoData.notes(userId));

  @override
  Future<Result<void>> addNote({
    required String coachId,
    required String userId,
    required String authorId,
    required String text,
  }) async =>
      const Result.success(null);
}
