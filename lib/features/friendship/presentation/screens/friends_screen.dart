import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/friendship/domain/entities/friendship_entity.dart';
import 'package:gymrank/features/friendship/presentation/controllers/friendship_providers.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendships = ref.watch(myFriendshipsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Amigos')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFriendDialog(context, ref),
        child: const Icon(Icons.person_add_alt),
      ),
      body: friendships.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Adicione amigos por username.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) => _FriendshipTile(
              friendship: list[i],
              currentUserId: ref.read(authStateProvider).valueOrNull ?? '',
            ),
          );
        },
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar amigo'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '@username'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final uid = ref.read(authStateProvider).valueOrNull;
              if (uid == null) return;
              await ref.read(friendshipRepositoryProvider).sendRequest(
                    requesterId: uid,
                    addresseeUsername: controller.text.trim(),
                  );
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}

class _FriendshipTile extends ConsumerWidget {
  const _FriendshipTile({required this.friendship, required this.currentUserId});

  final FriendshipEntity friendship;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final otherUserId = friendship.requesterId == currentUserId
        ? friendship.addresseeId
        : friendship.requesterId;
    final isIncomingPending = friendship.status == FriendshipStatus.pending &&
        friendship.addresseeId == currentUserId;

    return Card(
      child: ListTile(
        leading: const Icon(Icons.person_outline),
        title: Text(otherUserId),
        subtitle: Text(friendship.status.name),
        trailing: isIncomingPending
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => ref.read(friendshipRepositoryProvider).respond(
                          friendshipId: friendship.id,
                          accept: true,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => ref.read(friendshipRepositoryProvider).respond(
                          friendshipId: friendship.id,
                          accept: false,
                        ),
                  ),
                ],
              )
            : null,
      ),
    );
  }
}
