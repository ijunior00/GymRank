import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/social_feed/domain/entities/post_entity.dart';
import 'package:gymrank/features/social_feed/presentation/controllers/feed_providers.dart';

class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(feedPostsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Feed')),
      body: posts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Nenhuma novidade ainda.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _PostCard(post: list[i]),
          );
        },
      ),
    );
  }
}

class _PostCard extends ConsumerWidget {
  const _PostCard({required this.post});

  final PostEntity post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).valueOrNull;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.surfaceElevated,
                  backgroundImage: post.authorPhotoUrl != null
                      ? NetworkImage(post.authorPhotoUrl!)
                      : null,
                  child: post.authorPhotoUrl == null
                      ? const Icon(Icons.person, size: 18)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(post.authorName, style: AppTextStyles.title),
              ],
            ),
            const SizedBox(height: 10),
            Text(post.text, style: AppTextStyles.body),
            const SizedBox(height: 12),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.favorite_border, size: 20),
                  onPressed: uid == null
                      ? null
                      : () => ref.read(feedRepositoryProvider).toggleLike(
                            postId: post.id,
                            userId: uid,
                            liked: true,
                          ),
                ),
                Text('${post.likeCount}', style: AppTextStyles.caption),
                const SizedBox(width: 16),
                const Icon(Icons.mode_comment_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${post.commentCount}', style: AppTextStyles.caption),
                const Spacer(),
                const Icon(Icons.share_outlined, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
