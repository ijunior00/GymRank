import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';

part 'client_entity.freezed.dart';

/// Situação comercial do aluno com a treinadora (definida por ela).
enum ClientStatus { activo, pausado, inactivo }

/// Situação de atividade derivada dos registros (treinos/check-ins),
/// calculada no cliente a partir de [CoachStudentView.lastActivityAt].
enum StudentActivity { alDia, enRiesgo, sinActividad, sinRegistros }

/// Documento canônico de `coaches/{coachId}/clients/{userId}`: o vínculo
/// aluno <-> treinadora. Criado pelo próprio aluno ao entrar com o código
/// de convite (status inicial `activo`) ou pela treinadora; só ela edita.
@freezed
class ClientEntity with _$ClientEntity {
  const factory ClientEntity({
    required String userId,
    required String coachId,
    required ClientStatus status,
    required String? planName,
    required DateTime startedAt,
    required DateTime? nextPaymentAt,
    required List<String> tags,

    /// Atualizado pela Cloud Function `onWorkoutCreated`.
    required DateTime? lastWorkoutAt,
    required DateTime createdAt,
  }) = _ClientEntity;
}

/// Anotação privada da treinadora sobre um aluno
/// (`coaches/{coachId}/clients/{userId}/notes/{noteId}`). O aluno nunca lê.
@freezed
class CoachNoteEntity with _$CoachNoteEntity {
  const factory CoachNoteEntity({
    required String id,
    required String authorId,
    required String text,
    required DateTime createdAt,
  }) = _CoachNoteEntity;
}

/// Visão combinada usada pela lista do painel: o perfil público do aluno
/// (`users/{uid}`) mais o vínculo com a treinadora, quando já existir.
class CoachStudentView {
  const CoachStudentView({required this.user, required this.client});

  final UserEntity user;
  final ClientEntity? client;

  ClientStatus get status => client?.status ?? ClientStatus.activo;

  /// Última atividade registrada: check-in presencial ou treino.
  DateTime? get lastActivityAt {
    final candidates = [user.lastCheckInAt, client?.lastWorkoutAt]
        .whereType<DateTime>()
        .toList();
    if (candidates.isEmpty) return null;
    candidates.sort();
    return candidates.last;
  }

  int? get daysSinceActivity {
    final last = lastActivityAt;
    if (last == null) return null;
    return DateTime.now().difference(last).inDays;
  }

  StudentActivity get activity {
    final days = daysSinceActivity;
    if (days == null) return StudentActivity.sinRegistros;
    if (days >= AppConstants.studentInactiveAfterDays) {
      return StudentActivity.sinActividad;
    }
    if (days >= AppConstants.studentAtRiskAfterDays) {
      return StudentActivity.enRiesgo;
    }
    return StudentActivity.alDia;
  }

  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return user.name.toLowerCase().contains(q) ||
        user.username.toLowerCase().contains(q);
  }
}
