import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_entity.freezed.dart';

enum PostType {
  streakMilestone,
  xpMilestone,
  levelUp,
  personalRecord,
  challengeCompleted,
  custom,
}

/// Documento canônico de `posts/{postId}`. A maioria dos posts é gerada
/// automaticamente por Cloud Functions ao reagir a eventos de gamificação
/// (ver functions/src/social/generatePost.ts).
@freezed
class PostEntity with _$PostEntity {
  const factory PostEntity({
    required String id,
    required String userId,
    required String authorName,
    required String? authorPhotoUrl,
    required PostType type,
    required String text,
    String? imageUrl,
    required int likeCount,
    required int commentCount,
    required int shareCount,
    required DateTime createdAt,
  }) = _PostEntity;
}

/// Documento canônico de `posts/{postId}/comments/{commentId}`.
@freezed
class CommentEntity with _$CommentEntity {
  const factory CommentEntity({
    required String id,
    required String postId,
    required String userId,
    required String authorName,
    required String? authorPhotoUrl,
    required String text,
    required DateTime createdAt,
  }) = _CommentEntity;
}

/// Documento canônico de `posts/{postId}/likes/{userId}`. O id do
/// documento é o próprio `userId` para garantir unicidade de curtida.
@freezed
class LikeEntity with _$LikeEntity {
  const factory LikeEntity({
    required String postId,
    required String userId,
    required DateTime createdAt,
  }) = _LikeEntity;
}
