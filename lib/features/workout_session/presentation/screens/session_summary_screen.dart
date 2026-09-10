import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymrank/core/theme/app_colors.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/workout_session/domain/entities/workout_session.dart';
import 'package:gymrank/features/workout_session/presentation/controllers/workout_session_providers.dart';

/// Resumo de uma sessão concluída. A validação, o XP, a sequência e os
/// recordes chegam pela Cloud Function `onWorkoutSessionCompleted`, então
/// a tela mostra "calculando…" até `validated` deixar de ser nulo.
class SessionSummaryScreen extends ConsumerWidget {
  const SessionSummaryScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(sessionProvider(sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen'),
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Listo'),
          ),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (s) {
          if (s == null) {
            return const Center(child: Text('Sesión no encontrada.'));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _Header(session: s),
              const SizedBox(height: 20),
              _StatsRow(session: s),
              const SizedBox(height: 16),
              if (s.validated == null)
                const _InfoCard(
                  icon: Icons.hourglass_top,
                  color: AppColors.warning,
                  title: 'Calculando tu progreso…',
                  body: 'En unos segundos verás el XP y tus récords.',
                )
              else if (s.validated == false)
                _InfoCard(
                  icon: Icons.info_outline,
                  color: AppColors.warning,
                  title: 'No contó para tu racha',
                  body: s.validationReason ??
                      'La sesión no cumplió el mínimo para registrarse.',
                )
              else ...[
                _InfoCard(
                  icon: Icons.bolt,
                  color: AppColors.primary,
                  title: '+${s.xpGranted ?? 0} XP',
                  body: s.countedForStreak == true
                      ? '¡Sumaste un día a tu racha!'
                      : 'Hoy ya habías sumado a tu racha.',
                ),
                if (s.prs.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _PrCard(prs: s.prs),
                ],
              ],
              const SizedBox(height: 20),
              const Text('Lo que hiciste', style: AppTextStyles.title),
              const SizedBox(height: 8),
              for (final ex in s.exercises)
                if (ex.doneSets > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Icon(Icons.check,
                              size: 15, color: AppColors.success),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(ex.name, style: AppTextStyles.body),
                        ),
                        Text(
                          '${ex.doneSets} × ${_bestSet(ex)}',
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

  static String _bestSet(SessionExercise ex) {
    final done = ex.sets.where((s) => s.done).toList();
    if (done.isEmpty) return '—';
    done.sort((a, b) => (b.load ?? 0).compareTo(a.load ?? 0));
    final best = done.first;
    final reps = best.reps?.toString() ?? '—';
    if (best.load == null) return '$reps reps';
    final load = best.load! == best.load!.roundToDouble()
        ? best.load!.toStringAsFixed(0)
        : best.load!.toStringAsFixed(1);
    return '$reps × $load kg';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.session});

  final WorkoutSessionEntity session;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: AppColors.xpGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Icon(Icons.check, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 14),
        Text(
          '¡Entrenamiento completado!',
          textAlign: TextAlign.center,
          style: AppTextStyles.displayLarge.copyWith(fontSize: 24),
        ),
        const SizedBox(height: 4),
        Text(session.dayName, style: AppTextStyles.bodyMuted),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.session});

  final WorkoutSessionEntity session;

  @override
  Widget build(BuildContext context) {
    final minutes = ((session.durationSec ?? 0) / 60).round();
    final volume = session.totalVolumeKg;
    final items = [
      ('Duración', '$minutes min'),
      ('Series', '${session.doneSets}'),
      (
        'Volumen',
        volume >= 1000
            ? '${(volume / 1000).toStringAsFixed(1)} t'
            : '${volume.toStringAsFixed(0)} kg'
      ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            for (final (label, value) in items)
              Expanded(
                child: Column(
                  children: [
                    Text(value, style: AppTextStyles.statValue),
                    const SizedBox(height: 2),
                    Text(label, style: AppTextStyles.caption),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.title.copyWith(color: color)),
                Text(body, style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrCard extends StatelessWidget {
  const _PrCard({required this.prs});

  final List<PersonalRecord> prs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: AppColors.streakGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                prs.length == 1 ? 'Récord personal' : '${prs.length} récords personales',
                style: AppTextStyles.title.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final pr in prs)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '${pr.exercise}: ${_fmt(pr.load)} kg × ${pr.reps}',
                style: AppTextStyles.body.copyWith(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}
