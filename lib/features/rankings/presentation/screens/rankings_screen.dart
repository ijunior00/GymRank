import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/widgets/entrance.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/rankings/domain/entities/ranking_entry_entity.dart';
import 'package:gymrank/features/rankings/presentation/controllers/ranking_providers.dart';

class RankingsScreen extends ConsumerStatefulWidget {
  const RankingsScreen({super.key});

  @override
  ConsumerState<RankingsScreen> createState() => _RankingsScreenState();
}

class _RankingsScreenState extends ConsumerState<RankingsScreen> {
  RankingScope _scope = RankingScope.comunidad;
  RankingCriteria _criteria = RankingCriteria.gymScore;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final scopeId = switch (_scope) {
      RankingScope.comunidad => user?.coachId,
      RankingScope.ciudad => user?.city,
      RankingScope.amigos => user?.id,
      RankingScope.nacional => null,
    };
    final query = RankingQuery(
      scope: _scope,
      criteria: _criteria,
      scopeId: scopeId,
    );
    final entries = ref.watch(rankingEntriesProvider(query));
    final noCommunity = _scope == RankingScope.comunidad && user?.coachId == null;

    return Scaffold(
      appBar: AppBar(title: const Text('Ranking')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _ChipRow(
                  values: RankingScope.values,
                  selected: _scope,
                  labelOf: (s) => s.labelEs,
                  onSelected: (s) => setState(() => _scope = s),
                ),
                const SizedBox(height: 8),
                _ChipRow(
                  values: RankingCriteria.values,
                  selected: _criteria,
                  labelOf: (c) => c.labelEs,
                  onSelected: (c) => setState(() => _criteria = c),
                ),
              ],
            ),
          ),
          Expanded(
            child: noCommunity
                ? const _EmptyText(
                    'Únete a tu coach desde Perfil para ver el ranking de tu '
                    'comunidad.',
                  )
                : entries.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                    data: (list) {
                      if (list.isEmpty) {
                        return const _EmptyText(
                          'Aún no hay datos para este ranking.',
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) => Entrance(
                          delay: Duration(milliseconds: 45 * i),
                          child: _RankingTile(
                            entry: list[i],
                            isMe: list[i].userId == user?.id,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(text,
            textAlign: TextAlign.center, style: AppTextStyles.bodyMuted),
      ),
    );
  }
}

class _ChipRow<T> extends StatelessWidget {
  const _ChipRow({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: values
            .map(
              (v) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(labelOf(v)),
                  selected: v == selected,
                  onSelected: (_) => onSelected(v),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _RankingTile extends StatelessWidget {
  const _RankingTile({required this.entry, required this.isMe});

  final RankingEntryEntity entry;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final medalColor = switch (entry.position) {
      1 => AppColors.gold,
      2 => AppColors.silver,
      3 => AppColors.bronze,
      _ => null,
    };

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: medalColor ?? AppColors.surfaceElevated,
          child: Text(
            '${entry.position}',
            style: TextStyle(
              color: medalColor != null ? Colors.black : AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(isMe ? '${entry.userName} (tú)' : entry.userName),
        trailing: Text(
          entry.value.toStringAsFixed(0),
          style: AppTextStyles.statValue,
        ),
      ),
    );
  }
}
