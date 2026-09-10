import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/coach_panel/domain/entities/client_entity.dart';
import 'package:gymrank/features/coach_panel/domain/entities/coach_entity.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';

abstract interface class CoachPanelRepository {
  Stream<CoachEntity?> watchCoach(String coachId);

  /// Cria `coaches/{id}` e aponta `users/{ownerUserId}.coachId` para ele,
  /// atomicamente. Só funciona para um usuário que já tem o papel `coach`
  /// (ver firestore.rules).
  Future<Result<CoachEntity>> createCoach(CoachEntity coach);

  Future<Result<CoachEntity>> findByInviteCode(String inviteCode);

  /// Vincula o aluno à treinadora dona do código: grava `coachId` no
  /// perfil do aluno e cria `coaches/{coachId}/clients/{userId}`.
  Future<Result<CoachEntity>> joinCoach({
    required String userId,
    required String inviteCode,
  });

  Stream<CoachDashboardStats?> watchDashboardStats(String coachId);

  /// Perfis públicos dos alunos vinculados (`users` where coachId == ...).
  Stream<List<UserEntity>> watchStudents(String coachId, {int limit});

  Stream<List<ClientEntity>> watchClients(String coachId);

  Stream<ClientEntity?> watchClient({
    required String coachId,
    required String userId,
  });

  Future<Result<void>> updateClient(ClientEntity client);

  Stream<List<CoachNoteEntity>> watchNotes({
    required String coachId,
    required String userId,
  });

  Future<Result<void>> addNote({
    required String coachId,
    required String userId,
    required String authorId,
    required String text,
  });
}
