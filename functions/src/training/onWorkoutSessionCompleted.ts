import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { db, Timestamp } from '../admin';
import { XP } from '../constants';
import { registerActivityDay } from '../gamification/streak';
import { dispatchNotification } from '../notifications/dispatchNotification';
import { generateAutoPost } from '../social/generatePost';

/** Menos que isso não conta como treino (anti-fraude). */
const MIN_DURATION_SEC = 10 * 60;
const MIN_DONE_SETS = 1;

interface SessionSet {
  reps?: number | null;
  load?: number | null;
  done?: boolean;
}

interface SessionExercise {
  name: string;
  sets?: SessionSet[];
}

interface PersonalRecord {
  exercise: string;
  load: number;
  reps: number;
  estimated1Rm: number;
}

/** 1RM estimado (Epley). */
function estimate1Rm(load: number, reps: number): number {
  return load * (1 + reps / 30);
}

function normalize(name: string): string {
  return name.trim().toLowerCase();
}

/** Melhor 1RM estimado por exercício (só séries concluídas com carga). */
function bestByExercise(exercises: SessionExercise[]): Map<string, PersonalRecord> {
  const best = new Map<string, PersonalRecord>();
  for (const ex of exercises) {
    for (const set of ex.sets ?? []) {
      if (!set.done || !set.load || !set.reps || set.load <= 0 || set.reps <= 0) continue;
      const e1rm = estimate1Rm(set.load, set.reps);
      const current = best.get(normalize(ex.name));
      if (!current || e1rm > current.estimated1Rm) {
        best.set(normalize(ex.name), {
          exercise: ex.name,
          load: set.load,
          reps: set.reps,
          estimated1Rm: e1rm,
        });
      }
    }
  }
  return best;
}

/**
 * Conclusão de uma sessão de treino do plano: é o "check-in" do aluno
 * online. Valida (duração mínima e ao menos uma série feita), registra o
 * dia na sequência, cria o resumo em `workouts` (que concede XP e avança
 * desafios via `onWorkoutCreated`) e detecta recordes pessoais comparando
 * o 1RM estimado com as sessões anteriores.
 */
export const onWorkoutSessionCompleted = onDocumentWritten(
  'workout_sessions/{sessionId}',
  async (event) => {
    const after = event.data?.after;
    if (!after?.exists) return;
    const data = after.data()!;
    const before = event.data?.before?.data();
    if (data.status !== 'completada' || before?.status === 'completada') return;
    if (data.validated !== undefined) return; // já processada

    const userId = data.userId as string;
    const exercises = (data.exercises as SessionExercise[] | undefined) ?? [];
    const durationSec = (data.durationSec as number | undefined) ?? 0;
    const doneSets = exercises.reduce(
      (n, ex) => n + (ex.sets ?? []).filter((s) => s.done).length,
      0,
    );
    const totalVolumeKg = exercises.reduce(
      (v, ex) =>
        v +
        (ex.sets ?? []).reduce(
          (sv, s) => sv + (s.done && s.reps && s.load ? s.reps * s.load : 0),
          0,
        ),
      0,
    );

    let validationReason: string | null = null;
    if (durationSec < MIN_DURATION_SEC) {
      validationReason = 'Sesión demasiado corta para contar (mínimo 10 min).';
    } else if (doneSets < MIN_DONE_SETS) {
      validationReason = 'Ninguna serie marcada como hecha.';
    }

    if (validationReason) {
      await after.ref.update({
        validated: false,
        validationReason,
        totalVolumeKg,
        countedForStreak: false,
        xpGranted: 0,
        prs: [],
        updatedAt: Timestamp.now(),
      });
      return;
    }

    const finishedAt = ((data.finishedAt as Timestamp | undefined) ?? Timestamp.now()).toDate();

    // Recordes: compara com as sessões válidas anteriores do aluno.
    const previousSnap = await db
      .collection('workout_sessions')
      .where('userId', '==', userId)
      .where('validated', '==', true)
      .orderBy('finishedAt', 'desc')
      .limit(60)
      .get();
    const previousBest = new Map<string, number>();
    for (const doc of previousSnap.docs) {
      if (doc.id === after.id) continue;
      for (const [key, pr] of bestByExercise((doc.data().exercises as SessionExercise[]) ?? [])) {
        previousBest.set(key, Math.max(previousBest.get(key) ?? 0, pr.estimated1Rm));
      }
    }
    const prs: PersonalRecord[] = [];
    for (const [key, pr] of bestByExercise(exercises)) {
      const prev = previousBest.get(key);
      if (prev !== undefined && pr.estimated1Rm > prev) prs.push(pr);
    }

    const streak = await registerActivityDay(userId, finishedAt);

    // Resumo em `workouts`: alimenta o painel da coach, o histórico do
    // aluno e dispara `onWorkoutCreated` (XP + desafios + lastWorkoutAt).
    await db.collection('workouts').add({
      userId,
      date: Timestamp.fromDate(finishedAt),
      durationMinutes: Math.round(durationSec / 60),
      muscleGroup: 'corpoInteiro',
      intensity: 'moderada',
      source: 'plan',
      note: data.dayName ?? null,
      sessionId: after.id,
      createdAt: Timestamp.now(),
    });

    await after.ref.update({
      validated: true,
      validationReason: null,
      totalVolumeKg,
      countedForStreak: streak.countedForStreak,
      xpGranted: XP.workoutLogged,
      prs,
      updatedAt: Timestamp.now(),
    });

    if (prs.length === 0) return;

    const userSnap = await db.collection('users').doc(userId).get();
    const name = (userSnap.data()?.name as string | undefined) ?? 'Alguien';
    const photoUrl = (userSnap.data()?.photoUrl as string | null | undefined) ?? null;
    const top = prs.sort((a, b) => b.estimated1Rm - a.estimated1Rm)[0];

    await generateAutoPost({
      userId,
      authorName: name,
      authorPhotoUrl: photoUrl,
      type: 'personalRecord',
      text: `¡${name} rompió su récord en ${top.exercise}: ${formatKg(top.load)} kg × ${top.reps}!`,
    });
    await dispatchNotification({
      userId,
      type: 'personalRecord',
      title: prs.length === 1 ? '¡Nuevo récord personal! 🏆' : `¡${prs.length} récords personales! 🏆`,
      body: `${top.exercise}: ${formatKg(top.load)} kg × ${top.reps}.`,
      deepLink: `/workout/session/${after.id}`,
    });
  },
);

function formatKg(v: number): string {
  return Number.isInteger(v) ? `${v}` : v.toFixed(1);
}
