import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/workout_session/domain/entities/workout_session.dart';
import 'package:gymrank/features/workout_session/domain/usecases/today_workout_planner.dart';
import 'package:gymrank/features/workout_session/presentation/controllers/workout_session_providers.dart';

/// Cartão "Entrenamiento de hoy" na home: retoma a sessão em andamento,
/// começa a próxima do plano ou oferece o registro manual quando ainda não
/// há plano publicado. É a ação principal do aluno.
class TodayWorkoutCard extends ConsumerStatefulWidget {
  const TodayWorkoutCard({super.key});

  @override
  ConsumerState<TodayWorkoutCard> createState() => _TodayWorkoutCardState();
}

class _TodayWorkoutCardState extends ConsumerState<TodayWorkoutCard> {
  bool _starting = false;

  Future<void> _start(WorkoutSessionEntity draft) async {
    setState(() => _starting = true);
    final result =
        await ref.read(workoutSessionRepositoryProvider).start(draft);
    if (!mounted) return;
    setState(() => _starting = false);
    result.when(
      success: (session) => context.push('/workout/session/${session.id}'),
      failure: (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo empezar: $f')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(todayWorkoutProvider);
    // A treinadora não precisa do convite "registra tu primer plan": para
    // ela o cartão só aparece quando tem treino próprio publicado.
    final isStaff = ref.watch(currentUserProvider).valueOrNull?.isStaff ?? false;

    return today.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => const SizedBox.shrink(),
      data: (state) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: switch (state) {
          TodayWorkoutInProgress(:final session) => _Shell(
            child: _Body(
              eyebrow: 'ENTRENAMIENTO EN CURSO',
              title: session.dayName,
              subtitle:
                  '${session.doneSets} de ${session.totalSets} series hechas',
              actionLabel: 'Continuar',
              icon: Icons.play_arrow_rounded,
              onPressed: () =>
                  context.push('/workout/session/${session.id}'),
            ),
          ),
          TodayWorkoutReady(:final draft, :final trainedToday) => _Shell(
            child: _Body(
              eyebrow: trainedToday
                  ? 'YA ENTRENASTE HOY · SIGUIENTE SESIÓN'
                  : 'ENTRENAMIENTO DE HOY',
              title: draft.dayName,
              subtitle:
                  '${draft.exercises.length} ejercicios · ~${draft.estimatedMinutes} min',
              actionLabel: _starting ? 'Abriendo…' : 'Empezar',
              icon: Icons.play_arrow_rounded,
              busy: _starting,
              onPressed: _starting ? null : () => _start(draft),
            ),
          ),
          TodayWorkoutNoPlan() => isStaff
              ? const SizedBox.shrink()
              : _Shell(
                  child: _Body(
                    eyebrow: 'ENTRENAMIENTO DE HOY',
                    title: 'Aún no tienes plan',
                    subtitle:
                        'Cuando tu coach publique tu rutina, aparecerá aquí '
                        'lista para entrenar.',
                    actionLabel: 'Registrar a mano',
                    icon: Icons.edit_note,
                    onPressed: () => context.push('/workout/new'),
                  ),
                ),
        },
      ),
    );
  }
}

class _Shell extends StatelessWidget {
  const _Shell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.heroGradient,
        ),
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.icon,
    required this.onPressed,
    this.busy = false,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final String actionLabel;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            eyebrow,
            style: AppTextStyles.caption.copyWith(letterSpacing: 1.2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(title, style: AppTextStyles.displayLarge.copyWith(fontSize: 26)),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.bodyMuted),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
