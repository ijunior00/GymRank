import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gymrank/core/constants/app_constants.dart';
import 'package:gymrank/core/error/result.dart';
import 'package:gymrank/core/l10n/labels_es.dart';
import 'package:gymrank/core/theme/app_text_styles.dart';
import 'package:gymrank/features/auth/presentation/controllers/auth_providers.dart';
import 'package:gymrank/features/workout/domain/entities/workout_entity.dart';
import 'package:gymrank/features/workout/presentation/controllers/workout_providers.dart';

/// Registro manual, para quem treinou fora do plano (ou ainda não tem
/// plano). O treino do dia com séries fica em `workout_session`.
class LogWorkoutScreen extends ConsumerStatefulWidget {
  const LogWorkoutScreen({super.key});

  @override
  ConsumerState<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends ConsumerState<LogWorkoutScreen> {
  MuscleGroup _group = MuscleGroup.corpoInteiro;
  WorkoutIntensity _intensity = WorkoutIntensity.moderada;
  int _minutes = 60;
  bool _saving = false;

  Future<void> _save() async {
    final uid = ref.read(authStateProvider).valueOrNull;
    if (uid == null) return;
    setState(() => _saving = true);
    final result = await ref.read(workoutRepositoryProvider).log(
          WorkoutEntity(
            id: '',
            userId: uid,
            date: DateTime.now(),
            duration: Duration(minutes: _minutes),
            muscleGroup: _group,
            intensity: _intensity,
            source: WorkoutSource.manual,
            createdAt: DateTime.now(),
          ),
        );
    if (!mounted) return;
    setState(() => _saving = false);
    final failure = result.failureOrNull;
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $failure')),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    // Se a tela foi aberta direto pela URL (web), não há para onde voltar:
    // vai para o início em vez de deixar a tela em branco.
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Entrenamiento guardado: ${_group.labelEs}, $_minutes min. '
          '+${AppConstants.xpWorkoutLogged} XP en camino.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar entrenamiento')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Para lo que hiciste fuera del plan. Cuenta para tu racha y '
            'suma XP igual.',
            style: AppTextStyles.bodyMuted,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<MuscleGroup>(
            initialValue: _group,
            decoration: const InputDecoration(labelText: 'Grupo muscular'),
            items: MuscleGroup.values
                .map((g) => DropdownMenuItem(value: g, child: Text(g.labelEs)))
                .toList(),
            onChanged: (v) => setState(() => _group = v ?? _group),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<WorkoutIntensity>(
            initialValue: _intensity,
            decoration: const InputDecoration(labelText: 'Intensidad'),
            items: WorkoutIntensity.values
                .map((i) => DropdownMenuItem(value: i, child: Text(i.labelEs)))
                .toList(),
            onChanged: (v) => setState(() => _intensity = v ?? _intensity),
          ),
          const SizedBox(height: 16),
          Text('Duración: $_minutes min', style: AppTextStyles.title),
          Slider(
            value: _minutes.toDouble(),
            min: 10,
            max: 180,
            divisions: 17,
            label: '$_minutes min',
            onChanged: (v) => setState(() => _minutes = v.round()),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Guardar entrenamiento'),
          ),
        ],
      ),
    );
  }
}
