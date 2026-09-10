import 'package:freezed_annotation/freezed_annotation.dart';

part 'plan_entity.freezed.dart';

/// Tipo de plano/documento. Os nomes são os valores persistidos.
enum PlanKind { entrenamiento, dieta, macros, evaluacion, otro }

/// Ciclo de vida de um documento enviado pela treinadora/nutrióloga:
/// `subido` → `procesando` (Cloud Function `parseDocument`) → `listo`
/// (aguardando revisão) → `publicado`; ou `error` (com `errorMessage`,
/// pode ser reenviado voltando para `subido`).
enum PlanDocumentStatus { subido, procesando, listo, error, publicado }

/// Documento canônico de `documents/{docId}`: o arquivo original (PDF,
/// Word ou foto) e o resultado da leitura automática, antes da revisão.
@freezed
class PlanDocumentEntity with _$PlanDocumentEntity {
  const factory PlanDocumentEntity({
    required String id,
    required String coachId,
    required String userId,
    required String uploadedBy,
    required PlanKind kind,
    required String fileName,
    required String storagePath,
    required String? downloadUrl,
    required String contentType,
    required int sizeBytes,
    required PlanDocumentStatus status,
    required String? errorMessage,

    /// Saída estruturada do parser (esquema por [kind], ver
    /// functions/src/plans/planSchemas.ts). `null` até `listo`.
    required Map<String, dynamic>? parsedPlan,
    required String? planId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _PlanDocumentEntity;
}

/// Documento canônico de `plans/{planId}`: o plano vigente de um aluno
/// para um [kind]. Cada publicação incrementa `currentVersion` e grava
/// uma cópia imutável em `versions/{n}`.
@freezed
class PlanEntity with _$PlanEntity {
  const factory PlanEntity({
    required String id,
    required String coachId,
    required String userId,
    required PlanKind kind,
    required String title,
    required int currentVersion,
    required Map<String, dynamic> content,
    required String? sourceDocumentId,
    required DateTime publishedAt,
    required String publishedBy,
  }) = _PlanEntity;
}

/// Documento canônico de `plans/{planId}/versions/{n}` (append-only).
@freezed
class PlanVersionEntity with _$PlanVersionEntity {
  const factory PlanVersionEntity({
    required int number,
    required String title,
    required Map<String, dynamic> content,
    required String? sourceDocumentId,
    required DateTime publishedAt,
    required String publishedBy,
  }) = _PlanVersionEntity;
}
