import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/core/utils/date_formatter.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/coach_panel/domain/entities/client_entity.dart';
import 'package:gymrank/features/coach_panel/presentation/controllers/coach_panel_providers.dart';
import 'package:gymrank/features/coach_panel/presentation/widgets/student_activity_chip.dart';
import 'package:gymrank/features/plans/presentation/widgets/student_plans_card.dart';
import 'package:gymrank/features/profile/domain/entities/user_entity.dart';

/// Ficha do aluno vista pela treinadora: perfil, situação, plano e
/// próximo pago, progreso corporal, últimos treinos e notas privadas.
class ClientDetailScreen extends ConsumerWidget {
  const ClientDetailScreen({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(studentUserProvider(userId));
    final client = ref.watch(clientDetailProvider(userId)).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(user.valueOrNull?.name ?? 'Alumno')),
      body: user.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (u) {
          if (u == null) {
            return const Center(child: Text('No encontramos a este alumno.'));
          }
          final view = CoachStudentView(user: u, client: client);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            children: [
              _Header(view: view),
              const SizedBox(height: 16),
              _StatsRow(user: u),
              const SizedBox(height: 16),
              _PlanCard(
                view: view,
                onEdit: client == null
                    ? null
                    : () => _showPlanSheet(context, ref, client),
                onStatusChanged: client == null
                    ? null
                    : (status) => _updateClient(
                          context,
                          ref,
                          client.copyWith(status: status),
                        ),
              ),
              const SizedBox(height: 16),
              _MeasurementsCard(userId: userId),
              const SizedBox(height: 16),
              _WorkoutsCard(userId: userId),
              const SizedBox(height: 16),
              StudentPlansCard(userId: userId),
              const SizedBox(height: 16),
              _NotesCard(userId: userId),
            ],
          );
        },
      ),
    );
  }

  Future<void> _updateClient(
    BuildContext context,
    WidgetRef ref,
    ClientEntity client,
  ) async {
    final result =
        await ref.read(coachPanelRepositoryProvider).updateClient(client);
    if (!context.mounted) return;
    final failure = result.failureOrNull;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failure == null ? 'Cambios guardados.' : 'No se pudo guardar: $failure',
        ),
      ),
    );
  }

  Future<void> _showPlanSheet(
    BuildContext context,
    WidgetRef ref,
    ClientEntity client,
  ) async {
    final updated = await showModalBottomSheet<ClientEntity>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _PlanForm(client: client),
    );
    if (updated != null && context.mounted) {
      await _updateClient(context, ref, updated);
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.view});

  final CoachStudentView view;

  @override
  Widget build(BuildContext context) {
    final user = view.user;
    return Row(
      children: [
        CircleAvatar(
          radius: 34,
          backgroundColor: AppColors.surfaceElevated,
          backgroundImage:
              user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
          child: user.photoUrl == null
              ? const Icon(Icons.person, size: 32, color: AppColors.textSecondary)
              : null,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user.name, style: AppTextStyles.headline),
              Text('@${user.username} · ${user.city}',
                  style: AppTextStyles.bodyMuted),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (view.status != ClientStatus.activo)
                    StudentStatusChip(label: view.status.labelEs)
                  else
                    StudentActivityChip(activity: view.activity),
                  StudentStatusChip(label: 'Objetivo: ${user.goal.labelEs}'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Nivel', '${user.level}'),
      ('Racha', '${user.currentStreakDays} d'),
      ('Gym Score', user.gymScore.toStringAsFixed(0)),
      ('XP temporada', '${user.xpCurrentSeason}'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Row(
          children: [
            for (final (label, value) in items)
              Expanded(
                child: Column(
                  children: [
                    Text(value, style: AppTextStyles.statValue),
                    const SizedBox(height: 2),
                    Text(label,
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.view,
    required this.onEdit,
    required this.onStatusChanged,
  });

  final CoachStudentView view;
  final VoidCallback? onEdit;
  final ValueChanged<ClientStatus>? onStatusChanged;

  @override
  Widget build(BuildContext context) {
    final client = view.client;
    final rows = <(String, String)>[
      ('Alumno desde', client == null ? '—' : DateFormatter.shortDate(client.startedAt)),
      ('Plan', client?.planName ?? 'Sin plan asignado'),
      (
        'Próximo pago',
        client?.nextPaymentAt == null
            ? '—'
            : DateFormatter.shortDate(client!.nextPaymentAt!)
      ),
      (
        'Último check-in',
        view.user.lastCheckInAt == null
            ? 'nunca'
            : DateFormatter.relative(view.user.lastCheckInAt!)
      ),
      (
        'Último entrenamiento',
        client?.lastWorkoutAt == null
            ? 'sin registros'
            : DateFormatter.relative(client!.lastWorkoutAt!)
      ),
    ];

    return _SectionCard(
      title: 'Seguimiento',
      action: onEdit == null
          ? null
          : TextButton(onPressed: onEdit, child: const Text('Editar')),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Estado do aluno como controle segmentado, dentro do cartão e
          // ao alcance do polegar (em vez de um menu no canto superior).
          if (client != null && onStatusChanged != null) ...[
            SegmentedButton<ClientStatus>(
              segments: const [
                ButtonSegment(
                  value: ClientStatus.activo,
                  label: Text('Activo'),
                ),
                ButtonSegment(
                  value: ClientStatus.pausado,
                  label: Text('En pausa'),
                ),
                ButtonSegment(
                  value: ClientStatus.inactivo,
                  label: Text('Inactivo'),
                ),
              ],
              selected: {client.status},
              showSelectedIcon: false,
              onSelectionChanged: (selection) =>
                  onStatusChanged!(selection.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
            ),
            const SizedBox(height: 10),
          ],
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Text(label, style: AppTextStyles.bodyMuted),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value,
                      style: AppTextStyles.body,
                      textAlign: TextAlign.end,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (client == null)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Este alumno apunta a tu comunidad pero todavía no tiene '
                'vínculo registrado. Pídele que entre con tu código.',
                style: AppTextStyles.caption,
              ),
            ),
        ],
      ),
    );
  }
}

class _MeasurementsCard extends ConsumerWidget {
  const _MeasurementsCard({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(studentMeasurementsProvider(userId));
    return _SectionCard(
      title: 'Progreso corporal',
      child: history.when(
        loading: () => const _InlineLoader(),
        error: (e, _) => Text('Error: $e', style: AppTextStyles.bodyMuted),
        data: (list) {
          if (list.isEmpty) {
            return const Text('Aún no hay medidas registradas.',
                style: AppTextStyles.bodyMuted);
          }
          final first = list.first;
          final last = list.last;
          return Column(
            children: [
              _MetricRow(
                label: 'Peso',
                unit: 'kg',
                first: first.pesoKg,
                last: last.pesoKg,
              ),
              _MetricRow(
                label: '% de grasa',
                unit: '%',
                first: first.percentualGordura,
                last: last.percentualGordura,
              ),
              _MetricRow(
                label: 'Masa muscular',
                unit: 'kg',
                first: first.massaMuscularKg,
                last: last.massaMuscularKg,
                higherIsBetter: true,
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${list.length} registros · último ${DateFormatter.shortDate(last.recordedAt)}',
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.label,
    required this.unit,
    required this.first,
    required this.last,
    this.higherIsBetter = false,
  });

  final String label;
  final String unit;
  final double? first;
  final double? last;
  final bool higherIsBetter;

  @override
  Widget build(BuildContext context) {
    if (last == null) return const SizedBox.shrink();
    final delta = (first == null) ? null : last! - first!;
    Color deltaColor = AppColors.textSecondary;
    if (delta != null && delta != 0) {
      final improved = higherIsBetter ? delta > 0 : delta < 0;
      deltaColor = improved ? AppColors.success : AppColors.warning;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.bodyMuted)),
          Text('${last!.toStringAsFixed(1)} $unit', style: AppTextStyles.body),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: Text(
              delta == null
                  ? ''
                  : '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
              textAlign: TextAlign.right,
              style: AppTextStyles.caption
                  .copyWith(color: deltaColor, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkoutsCard extends ConsumerWidget {
  const _WorkoutsCard({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workouts = ref.watch(studentWorkoutsProvider(userId));
    return _SectionCard(
      title: 'Últimos entrenamientos',
      child: workouts.when(
        loading: () => const _InlineLoader(),
        error: (e, _) => Text('Error: $e', style: AppTextStyles.bodyMuted),
        data: (list) {
          if (list.isEmpty) {
            return const Text('Todavía no registra entrenamientos.',
                style: AppTextStyles.bodyMuted);
          }
          return Column(
            children: [
              for (final w in list.take(5))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      const Icon(Icons.fitness_center,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${w.muscleGroup.labelEs} · ${w.intensity.labelEs.toLowerCase()}',
                          style: AppTextStyles.body,
                        ),
                      ),
                      Text(
                        '${w.duration.inMinutes} min · ${DateFormatter.shortDate(w.date)}',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _NotesCard extends ConsumerStatefulWidget {
  const _NotesCard({required this.userId});

  final String userId;

  @override
  ConsumerState<_NotesCard> createState() => _NotesCardState();
}

class _NotesCardState extends ConsumerState<_NotesCard> {
  final _controller = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    final coachId = ref.read(currentCoachIdProvider);
    final authorId = ref.read(authStateProvider).valueOrNull;
    if (text.isEmpty || coachId == null || authorId == null) return;

    setState(() => _saving = true);
    final result = await ref.read(coachPanelRepositoryProvider).addNote(
          coachId: coachId,
          userId: widget.userId,
          authorId: authorId,
          text: text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    final failure = result.failureOrNull;
    if (failure == null) {
      _controller.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar la nota: $failure')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(clientNotesProvider(widget.userId));
    return _SectionCard(
      title: 'Notas privadas',
      subtitle: 'Solo tú las ves.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: 'Escribe una nota (lesión, ajuste, recordatorio…)',
              suffixIcon: _saving
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Agregar nota',
                      icon: const Icon(Icons.send),
                      onPressed: _submit,
                    ),
            ),
          ),
          const SizedBox(height: 12),
          notes.when(
            loading: () => const _InlineLoader(),
            error: (e, _) => Text('Error: $e', style: AppTextStyles.bodyMuted),
            data: (list) {
              if (list.isEmpty) {
                return const Text('Sin notas todavía.', style: AppTextStyles.bodyMuted);
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final n in list)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(n.text, style: AppTextStyles.body),
                          const SizedBox(height: 4),
                          Text(DateFormatter.relative(n.createdAt),
                              style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PlanForm extends StatefulWidget {
  const _PlanForm({required this.client});

  final ClientEntity client;

  @override
  State<_PlanForm> createState() => _PlanFormState();
}

class _PlanFormState extends State<_PlanForm> {
  late final TextEditingController _plan =
      TextEditingController(text: widget.client.planName ?? '');
  late DateTime? _nextPayment = widget.client.nextPaymentAt;

  @override
  void dispose() {
    _plan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Plan y cobro', style: AppTextStyles.headline),
          const SizedBox(height: 16),
          TextField(
            controller: _plan,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Nombre del plan',
              hintText: 'Ej. Online mensual, Presencial 3x, Elite',
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event_outlined),
            title: Text(
              _nextPayment == null
                  ? 'Próximo pago (opcional)'
                  : 'Próximo pago: ${DateFormatter.shortDate(_nextPayment!)}',
            ),
            trailing: _nextPayment == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _nextPayment = null),
                  ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _nextPayment ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 730)),
              );
              if (picked != null) setState(() => _nextPayment = picked);
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(
              widget.client.copyWith(
                planName: _plan.text.trim().isEmpty ? null : _plan.text.trim(),
                nextPaymentAt: _nextPayment,
              ),
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.title),
                      if (subtitle != null)
                        Text(subtitle!, style: AppTextStyles.caption),
                    ],
                  ),
                ),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _InlineLoader extends StatelessWidget {
  const _InlineLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
