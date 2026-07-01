import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/features/social_feed/domain/entities/post_entity.dart';

abstract interface class FeedRepository {
  /// Feed paginado. A maioria dos posts é gerada automaticamente por
  /// Cloud Functions; usuários também podem publicar posts custom.
  Stream<List<PostEntity>> watchFeed({int limit});

  Future<Result<void>> toggleLike({
    required String postId,
    required String userId,
    required bool liked,
  });

  Future<Result<void>> addComment(CommentEntity comment);

  Stream<List<CommentEntity>> watchComments(String postId);
}
