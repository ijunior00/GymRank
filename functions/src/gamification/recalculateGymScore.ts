import { onSchedule } from 'firebase-functions/v2/scheduler';
import { db, Timestamp } from '../admin';
import { GYM_SCORE_WEIGHTS } from '../constants';

interface ScoreInputs {
  frequency: number;
  consistency: number;
  challenges: number;
  evolution: number;
}

function computeScore(inputs: ScoreInputs): number {
  const raw =
    inputs.frequency * GYM_SCORE_WEIGHTS.frequency +
    inputs.consistency * GYM_SCORE_WEIGHTS.consistency +
    inputs.challenges * GYM_SCORE_WEIGHTS.challenges +
    inputs.evolution * GYM_SCORE_WEIGHTS.evolution;
  return Math.min(1000, Math.round(raw * 1000));
}

const WINDOW_DAYS = 28;

/**
 * Recalcula o Gym Score de todos os usuários uma vez por dia. O
 * algoritmo evita métricas absolutas de composição corporal (ver seção
 * "Gym Score" do briefing de produto) — usa apenas frequência,
 * consistência, participação em desafios e evolução individual
 * normalizada, para premiar disciplina em vez de genética/volume.
 */
export const recalculateGymScore = onSchedule('every day 03:00', async () => {
  const windowStart = Timestamp.fromMillis(Date.now() - WINDOW_DAYS * 24 * 60 * 60 * 1000);
  const usersSnap = await db.collection('users').get();

  for (const userDoc of usersSnap.docs) {
    const userId = userDoc.id;

    const [checkinsSnap, challengesSnap, measurementsSnap] = await Promise.all([
      db
        .collectionGroup('checkins')
        .where('userId', '==', userId)
        .where('checkedInAt', '>=', windowStart)
        .get(),
      db
        .collectionGroup('participants')
        .where('userId', '==', userId)
        .get(),
      db
        .collection('body_measurements')
        .where('userId', '==', userId)
        .where('recordedAt', '>=', windowStart)
        .get(),
    ]);

    const checkInDays = new Set(
      checkinsSnap.docs.map((d) => (d.data().checkedInAt as Timestamp).toDate().toDateString()),
    );
    const frequency = Math.min(1, checkInDays.size / WINDOW_DAYS);

    const activeWeeks = new Set(
      checkinsSnap.docs.map((d) => weekKey((d.data().checkedInAt as Timestamp).toDate())),
    );
    const consistency = Math.min(1, activeWeeks.size / Math.ceil(WINDOW_DAYS / 7));

    const totalChallenges = challengesSnap.size;
    const completedChallenges = challengesSnap.docs.filter((d) => d.data().completed).length;
    const challenges = totalChallenges === 0 ? 0 : completedChallenges / totalChallenges;

    const evolution = measurementsSnap.empty ? 0 : Math.min(1, measurementsSnap.size / 4);

    const inputs: ScoreInputs = { frequency, consistency, challenges, evolution };
    const totalScore = computeScore(inputs);

    await userDoc.ref.update({ gymScore: totalScore });

    await db.collection('gym_score_history').add({
      userId,
      calculatedAt: Timestamp.now(),
      frequencyScore: inputs.frequency,
      consistencyScore: inputs.consistency,
      challengesScore: inputs.challenges,
      evolutionScore: inputs.evolution,
      totalScore,
      seasonId: userDoc.data().activeSeasonId ?? null,
    });
  }
});

function weekKey(date: Date): string {
  const firstDayOfYear = new Date(Date.UTC(date.getUTCFullYear(), 0, 1));
  const days = Math.floor((date.getTime() - firstDayOfYear.getTime()) / 86400000);
  const week = Math.ceil((days + firstDayOfYear.getUTCDay() + 1) / 7);
  return `${date.getUTCFullYear()}-W${week}`;
}
