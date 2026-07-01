import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/di/firebase_providers.dart';
import 'package:gymrank/features/social_feed/data/repositories/firestore_feed_repository.dart';
import 'package:gymrank/features/social_feed/domain/entities/post_entity.dart';
import 'package:gymrank/features/social_feed/domain/repositories/feed_repository.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FirestoreFeedRepository(ref.watch(firestoreProvider));
});

final feedPostsProvider = StreamProvider<List<PostEntity>>((ref) {
  return ref.watch(feedRepositoryProvider).watchFeed();
});
