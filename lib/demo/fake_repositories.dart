// PREVIEW/DEMO ONLY. Implementações in-memory das interfaces de
// repositório, usadas por lib/main_demo.dart para rodar o app sem
// Firebase. Ações de escrita são no-op que retornam sucesso.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

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
import 'package:gymrank/features/plans/domain/entities/plan_entity.dart';
import 'package:gymrank/features/plans/domain/repositories/plan_repository.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';
import 'package:gymrank/features/profile/domain/repositories/user_repository.dart';
import 'package:gymrank/features/progress_photo/domain/entities/progress_photo_entity.dart';
import 'package:gymrank/features/progress_photo/domain/repositories/progress_photo_repository.dart';
import 'package:gymrank/features/sharing/domain/entities/share_card.dart';
import 'package:gymrank/features/sharing/domain/repositories/share_repository.dart';
import 'package:gymrank/features/rankings/domain/entities/ranking_entry_entity.dart';
import 'package:gymrank/features/rankings/domain/repositories/ranking_repository.dart';
import 'package:gymrank/features/rewards/domain/entities/reward_entity.dart';
import 'package:gymrank/features/rewards/domain/repositories/reward_repository.dart';
import 'package:gymrank/features/social_feed/domain/entities/post_entity.dart';
import 'package:gymrank/features/social_feed/domain/repositories/feed_repository.dart';
import 'package:gymrank/features/meal_log/domain/entities/meal_log_entity.dart';
import 'package:gymrank/features/meal_log/domain/repositories/meal_log_repository.dart';
import 'package:gymrank/features/workout/domain/entities/workout_entity.dart';
import 'package:gymrank/features/workout/domain/repositories/workout_repository.dart';
import 'package:gymrank/features/workout_session/domain/entities/workout_session.dart';
import 'package:gymrank/features/workout_session/domain/repositories/workout_session_repository.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Stream<String?> authStateChanges() => Stream.value(DemoData.uid);

  @override
  Future<Result<UserEntity>> currentUser() async =>
      Result.success(DemoData.user);

  @override
  Future<Result<String>> signInWithGoogle() async =>
      const Result.success(DemoData.uid);

  @override
  Future<Result<String>> signInWithApple() async =>
      const Result.success(DemoData.uid);

  @override
  Future<Result<String>> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      const Result.success(DemoData.uid);

  @override
  Future<Result<String>> registerWithEmail({
    required String email,
    required String password,
  }) async =>
      const Result.success(DemoData.uid);

  @override
  Future<Result<void>> sendPhoneVerificationCode(String phoneNumber) async =>
      const Result.success(null);

  @override
  Future<Result<String>> confirmPhoneCode({
    required String verificationId,
    required String smsCode,
  }) async =>
      const Result.success(DemoData.uid);

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

/// Guarda a sessão iniciada em memória para que o preview consiga
/// executar o treino do começo ao fim (incluindo o resumo com recorde).
class FakeWorkoutSessionRepository implements WorkoutSessionRepository {
  WorkoutSessionEntity? _current;

  final _controller = StreamController<WorkoutSessionEntity?>.broadcast();

  void _emit() => _controller.add(_current);

  @override
  Future<Result<WorkoutSessionEntity>> start(WorkoutSessionEntity draft) async {
    _current = draft.copyWithId('demo-session');
    _emit();
    return Result.success(_current!);
  }

  @override
  Future<Result<void>> save(WorkoutSessionEntity session) async {
    _current = session;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> finish(WorkoutSessionEntity session) async {
    final now = DateTime.now();
    _current = WorkoutSessionEntity(
      id: session.id,
      userId: session.userId,
      coachId: session.coachId,
      planId: session.planId,
      planVersion: session.planVersion,
      dayIndex: session.dayIndex,
      dayName: session.dayName,
      status: SessionStatus.completada,
      startedAt: session.startedAt,
      finishedAt: now,
      durationSec: now.difference(session.startedAt).inSeconds,
      exercises: session.exercises,
      totalVolumeKg: session.computedVolume,
      validated: true,
      countedForStreak: true,
      xpGranted: AppConstants.xpWorkoutLogged,
      prs: [
        for (final ex in session.exercises)
          if (ex.sets.any((s) => s.done && s.load != null))
            PersonalRecord(
              exercise: ex.name,
              load: ex.sets.firstWhere((s) => s.done && s.load != null).load!,
              reps: ex.sets.firstWhere((s) => s.done && s.load != null).reps ?? 0,
              estimated1Rm: 0,
            ),
      ].take(1).toList(),
    );
    _emit();
    return const Result.success(null);
  }

  @override
  Future<Result<void>> cancel(String sessionId) async {
    _current = null;
    _emit();
    return const Result.success(null);
  }

  @override
  Stream<WorkoutSessionEntity?> watchActive(String userId) async* {
    yield _current?.status == SessionStatus.enCurso ? _current : null;
    yield* _controller.stream
        .map((s) => s?.status == SessionStatus.enCurso ? s : null);
  }

  @override
  Stream<WorkoutSessionEntity?> watch(String sessionId) async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Stream<List<WorkoutSessionEntity>> watchRecent(String userId, {int limit = 20}) =>
      Stream.value(DemoData.sessions);
}

class FakeMealLogRepository implements MealLogRepository {
  late final List<MealLogEntity> _logs = [...DemoData.todayMealLogs];

  final _controller = StreamController<List<MealLogEntity>>.broadcast();

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
    _logs.removeWhere((l) => l.date == date && l.mealIndex == mealIndex);
    if (status != null) {
      _logs.add(
        MealLogEntity(
          id: MealLogEntity.idFor(userId, date, mealIndex),
          userId: userId,
          coachId: coachId,
          planId: planId,
          date: date,
          mealIndex: mealIndex,
          mealName: mealName,
          status: status,
          createdAt: DateTime.now(),
        ),
      );
    }
    _controller.add(List.of(_logs));
    return const Result.success(null);
  }

  @override
  Stream<List<MealLogEntity>> watchDay(String userId, String date) async* {
    yield _logs.where((l) => l.date == date).toList();
    yield* _controller.stream
        .map((all) => all.where((l) => l.date == date).toList());
  }

  @override
  Stream<List<MealLogEntity>> watchRange(
    String userId, {
    required String fromDate,
    required String toDate,
  }) async* {
    yield List.of(_logs);
    yield* _controller.stream;
  }
}

class FakeShareRepository implements ShareRepository {
  @override
  Future<Result<void>> recordShare(ShareCardKind kind) async =>
      const Result.success(null);

  @override
  Stream<List<ShareEventEntity>> watchRecent(String coachId, {int limit = 15}) =>
      Stream.value(DemoData.shares);
}

class FakePlanRepository implements PlanRepository {
  @override
  Future<Result<PlanDocumentEntity>> uploadDocument({
    required String coachId,
    required String userId,
    required String uploadedBy,
    required PlanKind kind,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final now = DateTime.now();
    return Result.success(
      PlanDocumentEntity(
        id: 'demo-doc',
        coachId: coachId,
        userId: userId,
        uploadedBy: uploadedBy,
        kind: kind,
        fileName: fileName,
        storagePath: '',
        downloadUrl: null,
        contentType: contentType,
        sizeBytes: bytes.length,
        status: PlanDocumentStatus.subido,
        errorMessage: null,
        parsedPlan: null,
        planId: null,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Stream<List<PlanDocumentEntity>> watchDocuments(String userId) =>
      Stream.value(
        DemoData.documents.where((d) => d.userId == userId).toList(),
      );

  @override
  Stream<PlanDocumentEntity?> watchDocument(String documentId) {
    for (final d in DemoData.documents) {
      if (d.id == documentId) return Stream.value(d);
    }
    return Stream.value(null);
  }

  @override
  Future<Result<void>> retryDocument(String documentId) async =>
      const Result.success(null);

  @override
  Future<Result<PlanEntity>> publish({
    required String coachId,
    required String userId,
    required PlanKind kind,
    required String title,
    required Map<String, dynamic> content,
    required String publishedBy,
    String? sourceDocumentId,
  }) async =>
      Result.success(
        PlanEntity(
          id: 'demo-plan',
          coachId: coachId,
          userId: userId,
          kind: kind,
          title: title,
          currentVersion: 1,
          content: content,
          sourceDocumentId: sourceDocumentId,
          publishedAt: DateTime.now(),
          publishedBy: publishedBy,
        ),
      );

  @override
  Stream<List<PlanEntity>> watchPlans(String userId) =>
      Stream.value(DemoData.plans.where((p) => p.userId == userId).toList());

  @override
  Stream<PlanEntity?> watchPlan(String planId) {
    for (final p in DemoData.plans) {
      if (p.id == planId) return Stream.value(p);
    }
    return Stream.value(null);
  }

  @override
  Stream<List<PlanVersionEntity>> watchVersions(String planId) {
    for (final p in DemoData.plans) {
      if (p.id == planId) {
        return Stream.value([
          for (var v = p.currentVersion; v >= 1; v--)
            PlanVersionEntity(
              number: v,
              title: p.title,
              content: p.content,
              sourceDocumentId: p.sourceDocumentId,
              publishedAt:
                  p.publishedAt.subtract(Duration(days: 14 * (p.currentVersion - v))),
              publishedBy: p.publishedBy,
            ),
        ]);
      }
    }
    return Stream.value(const []);
  }
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
