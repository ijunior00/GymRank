import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/workout_session/domain/entities/workout_session.dart';
import 'package:gymrank/features/workout_session/presentation/controllers/workout_session_providers.dart';

/// Execução do treino do dia, um exercício por página. Marcar a série
/// dispara o descanso; concluir a sessão vale como check-in (a validação,
/// o XP, a sequência e os recordes são calculados no backend).
///
/// Tudo aqui é pensado para uma mão: alvos grandes, teclado numérico e a
/// ação principal fixa no rodapé.
class WorkoutSessionScreen extends ConsumerStatefulWidget {
  const WorkoutSessionScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  ConsumerState<WorkoutSessionScreen> createState() =>
      _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends ConsumerState<WorkoutSessionScreen> {
  WorkoutSessionEntity? _session;
  final _pageController = PageController();
  final _elapsed = ValueNotifier<Duration>(Duration.zero);
  final _rest = ValueNotifier<int?>(null);
  Timer? _ticker;
  int _page = 0;
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _pageController.dispose();
    _elapsed.dispose();
    _rest.dispose();
    super.dispose();
  }

  void _tick() {
    final session = _session;
    if (session != null) {
      _elapsed.value = DateTime.now().difference(session.startedAt);
    }
    final rest = _rest.value;
    if (rest == null) return;
    if (rest <= 1) {
      _rest.value = null;
      HapticFeedback.mediumImpact();
    } else {
      _rest.value = rest - 1;
    }
  }

  Future<void> _persist() async {
    final session = _session;
    if (session == null) return;
    await ref.read(workoutSessionRepositoryProvider).save(session);
  }

  void _onSetToggled(SessionExercise exercise, SessionSet set) {
    setState(() => set.done = !set.done);
    HapticFeedback.selectionClick();
    if (set.done && exercise.restSeconds != null && exercise.restSeconds! > 0) {
      _rest.value = exercise.restSeconds;
    }
    unawaited(_persist());
  }

  Future<void> _confirmCancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir del entrenamiento?'),
        content: const Text(
          'Puedes salir y continuar más tarde, o descartarlo por completo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Seguir después'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (ok == true) {
      await ref
          .read(workoutSessionRepositoryProvider)
          .cancel(widget.sessionId);
      if (mounted) context.pop();
    } else {
      await _persist();
      if (mounted) context.pop();
    }
  }

  Future<void> _finish() async {
    final session = _session;
    if (session == null) return;

    if (session.doneSets == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Marca al menos una serie antes de terminar.'),
        ),
      );
      return;
    }
    if (session.doneSets < session.totalSets) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Terminar así?'),
          content: Text(
            'Marcaste ${session.doneSets} de ${session.totalSets} series. '
            'Las que faltan no se registrarán.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Seguir'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Terminar'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    setState(() => _finishing = true);
    final result =
        await ref.read(workoutSessionRepositoryProvider).finish(session);
    if (!mounted) return;
    setState(() => _finishing = false);

    final failure = result.failureOrNull;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo terminar: $failure')),
      );
      return;
    }
    context.pushReplacement('/workout/session/${widget.sessionId}/summary');
  }

  @override
  Widget build(BuildContext context) {
    // Carrega uma única vez; depois a tela vive do rascunho local.
    if (_session == null) {
      final async = ref.watch(sessionProvider(widget.sessionId));
      return async.when(
        loading: () => const _Scaffold(child: CircularProgressIndicator()),
        error: (e, _) => _Scaffold(child: Text('Error: $e')),
        data: (s) {
          if (s == null) {
            return const _Scaffold(child: Text('Sesión no encontrada.'));
          }
          if (s.status != SessionStatus.enCurso) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                context.pushReplacement(
                  '/workout/session/${widget.sessionId}/summary',
                );
              }
            });
            return const _Scaffold(child: CircularProgressIndicator());
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _session == null) setState(() => _session = s);
          });
          return const _Scaffold(child: CircularProgressIndicator());
        },
      );
    }

    final session = _session!;
    final exercises = session.exercises;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmCancel();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _confirmCancel,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(session.dayName, style: AppTextStyles.title),
              ValueListenableBuilder<Duration>(
                valueListenable: _elapsed,
                builder: (context, value, _) => Text(
                  _formatDuration(value),
                  style: AppTextStyles.caption,
                ),
              ),
            ],
          ),
        ),
        body: exercises.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Esta sesión no tiene ejercicios. Pídele a tu coach que '
                    'revise el plan.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMuted,
                  ),
                ),
              )
            : Column(
                children: [
                  _ProgressBar(
                    done: session.doneSets,
                    total: session.totalSets,
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: exercises.length,
                      onPageChanged: (i) => setState(() => _page = i),
                      itemBuilder: (context, i) => _ExercisePage(
                        exercise: exercises[i],
                        index: i,
                        total: exercises.length,
                        onToggle: (set) => _onSetToggled(exercises[i], set),
                        onChanged: () {
                          setState(() {});
                          unawaited(_persist());
                        },
                      ),
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<int?>(
                  valueListenable: _rest,
                  builder: (context, value, _) => value == null
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RestBar(
                            remaining: value,
                            onAdd: () => _rest.value = value + 15,
                            onSkip: () => _rest.value = null,
                          ),
                        ),
                ),
                Row(
                  children: [
                    if (_page > 0)
                      IconButton.filledTonal(
                        onPressed: () => _pageController.previousPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        ),
                        icon: const Icon(Icons.chevron_left),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _page < exercises.length - 1
                          ? ElevatedButton(
                              onPressed: () => _pageController.nextPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              ),
                              child: const Text('Siguiente ejercicio'),
                            )
                          : ElevatedButton.icon(
                              onPressed: _finishing ? null : _finish,
                              icon: _finishing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.check),
                              label: Text(
                                _finishing
                                    ? 'Guardando…'
                                    : 'Terminar entrenamiento',
                              ),
                            ),
                    ),
                  ],
                ),
                if (_page < exercises.length - 1)
                  TextButton(
                    onPressed: _finishing ? null : _finish,
                    child: const Text('Terminar entrenamiento'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return h > 0 ? '$h:$m:$s' : '$m:$s';
}

class _Scaffold extends StatelessWidget {
  const _Scaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Entrenamiento')),
      body: Center(child: child),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: total == 0 ? 0 : done / total,
                minHeight: 6,
                backgroundColor: AppColors.surfaceElevated,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('$done/$total series', style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _RestBar extends StatelessWidget {
  const _RestBar({
    required this.remaining,
    required this.onAdd,
    required this.onSkip,
  });

  final int remaining;
  final VoidCallback onAdd;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Text(
            'Descanso ${_formatDuration(Duration(seconds: remaining))}',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const Spacer(),
          TextButton(onPressed: onAdd, child: const Text('+15 s')),
          TextButton(onPressed: onSkip, child: const Text('Saltar')),
        ],
      ),
    );
  }
}

class _ExercisePage extends StatelessWidget {
  const _ExercisePage({
    required this.exercise,
    required this.index,
    required this.total,
    required this.onToggle,
    required this.onChanged,
  });

  final SessionExercise exercise;
  final int index;
  final int total;
  final ValueChanged<SessionSet> onToggle;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Text(
          'EJERCICIO ${index + 1} DE $total',
          style: AppTextStyles.caption.copyWith(letterSpacing: 1.2),
        ),
        const SizedBox(height: 4),
        Text(exercise.name, style: AppTextStyles.displayLarge.copyWith(fontSize: 26)),
        const SizedBox(height: 6),
        Text(exercise.prescription, style: AppTextStyles.bodyMuted),
        if (exercise.technique != null && exercise.technique!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _Note(icon: Icons.auto_awesome, text: exercise.technique!),
        ],
        if (exercise.notes != null && exercise.notes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _Note(icon: Icons.sticky_note_2_outlined, text: exercise.notes!),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            const SizedBox(width: 34),
            Expanded(
              child: Text('REPS',
                  style: AppTextStyles.caption.copyWith(letterSpacing: 1)),
            ),
            Expanded(
              child: Text('KG',
                  style: AppTextStyles.caption.copyWith(letterSpacing: 1)),
            ),
            const SizedBox(width: 52),
          ],
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < exercise.sets.length; i++)
          _SetRow(
            key: ValueKey('${exercise.name}_$i'),
            number: i + 1,
            set: exercise.sets[i],
            onToggle: () => onToggle(exercise.sets[i]),
            onChanged: onChanged,
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            TextButton.icon(
              onPressed: () {
                final last = exercise.sets.isEmpty ? null : exercise.sets.last;
                exercise.sets.add(
                  SessionSet(reps: last?.reps, load: last?.load),
                );
                onChanged();
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Agregar serie'),
            ),
            const Spacer(),
            if (exercise.sets.length > 1)
              TextButton(
                onPressed: () {
                  exercise.sets.removeLast();
                  onChanged();
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                child: const Text('Quitar'),
              ),
          ],
        ),
      ],
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppTextStyles.caption)),
      ],
    );
  }
}

class _SetRow extends StatefulWidget {
  const _SetRow({
    required this.number,
    required this.set,
    required this.onToggle,
    required this.onChanged,
    super.key,
  });

  final int number;
  final SessionSet set;
  final VoidCallback onToggle;
  final VoidCallback onChanged;

  @override
  State<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<_SetRow> {
  late final TextEditingController _reps =
      TextEditingController(text: widget.set.reps?.toString() ?? '');
  late final TextEditingController _load =
      TextEditingController(text: _formatLoad(widget.set.load));

  static String _formatLoad(double? v) {
    if (v == null) return '';
    return v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _reps.dispose();
    _load.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = widget.set.done;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: done
            ? AppColors.primary.withValues(alpha: 0.12)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done ? AppColors.primary.withValues(alpha: 0.45) : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text('${widget.number}',
                style: AppTextStyles.title.copyWith(
                  color: done ? AppColors.primary : AppColors.textSecondary,
                )),
          ),
          Expanded(
            child: _NumberField(
              controller: _reps,
              hint: '—',
              onChanged: (v) {
                widget.set.reps = int.tryParse(v.trim());
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _NumberField(
              controller: _load,
              hint: '—',
              decimal: true,
              onChanged: (v) {
                widget.set.load =
                    double.tryParse(v.trim().replaceAll(',', '.'));
                widget.onChanged();
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: done ? 'Deshacer' : 'Serie hecha',
            onPressed: widget.onToggle,
            iconSize: 28,
            icon: Icon(
              done ? Icons.check_circle : Icons.radio_button_unchecked,
              color: done ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.decimal = false,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.numberWithOptions(decimal: decimal),
      textAlign: TextAlign.center,
      style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: AppColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
