import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/social_feed/data/repositories/firestore_feed_repository.dart';
import 'package:gymrank/features/social_feed/domain/entities/post_entity.dart';
import 'package:gymrank/features/social_feed/domain/repositories/feed_repository.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FirestoreFeedRepository(ref.watch(firestoreProvider));
});

final feedPostsProvider = StreamProvider<List<PostEntity>>((ref) {
  return ref.watch(feedRepositoryProvider).watchFeed();
});

/// Se o usuário logado já curtiu o post: decide o coração preenchido e se
/// o próximo toque curte ou descurte.
final postLikedProvider = StreamProvider.family<bool, String>((ref, postId) {
  final uid = ref.watch(authStateProvider).valueOrNull;
  if (uid == null) return Stream.value(false);
  return ref
      .watch(feedRepositoryProvider)
      .watchLiked(postId: postId, userId: uid);
});

final postCommentsProvider =
    StreamProvider.family<List<CommentEntity>, String>((ref, postId) {
  return ref.watch(feedRepositoryProvider).watchComments(postId);
});
