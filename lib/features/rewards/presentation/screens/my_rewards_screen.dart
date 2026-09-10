import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/features/rewards/presentation/controllers/reward_providers.dart';

class MyRewardsScreen extends ConsumerWidget {
  const MyRewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grants = ref.watch(myRewardGrantsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mis premios')),
      body: grants.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aún no has ganado premios.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final g = list[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.card_giftcard),
                  title: Text('Premio #${g.rewardId}'),
                  subtitle: Text('Origen: ${rewardSourceLabelEs(g.sourceType)}'),
                  trailing: Text(g.status.labelEs),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
