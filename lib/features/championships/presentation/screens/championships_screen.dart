import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/championships/presentation/controllers/championship_providers.dart';

class ChampionshipsScreen extends ConsumerWidget {
  const ChampionshipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final championships = ref.watch(communityChampionshipsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Torneos')),
      body: championships.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aún no hay torneos en tu comunidad.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final c = list[i];
              return Card(
                child: ListTile(
                  title: Text(c.name, style: AppTextStyles.title),
                  subtitle: Text(c.description),
                  trailing: Text(c.isFinished ? 'Terminado' : 'En curso'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
