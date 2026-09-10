import { onSchedule } from 'firebase-functions/v2/scheduler';
import { db, Timestamp } from '../admin';

const SEASON_DURATIONS_MS = {
  mensal: 30 * 24 * 60 * 60 * 1000,
  trimestral: 90 * 24 * 60 * 60 * 1000,
} as const;

/**
 * Roda diariamente e fecha qualquer temporada cujo `endsAt` já passou.
 * Ao final da temporada (ver seção "Sistema de Temporadas" do produto):
 *  - zera `xpCurrentSeason` e `gymScore` de ranking dos participantes
 *    (o histórico completo em `gym_score_history`/`xpTotal` não é afetado);
 *  - concede badges permanentes ao Top 3 / Top 10;
 *  - inicia a próxima temporada automaticamente.
 */
export const seasonReset = onSchedule('every day 04:00', async () => {
  const now = Timestamp.now();
  const endedSeasonsSnap = await db
    .collection('seasons')
    .where('isActive', '==', true)
    .where('endsAt', '<=', now)
    .get();

  for (const seasonDoc of endedSeasonsSnap.docs) {
    await closeSeason(seasonDoc.id, seasonDoc.data());
  }
});

async function closeSeason(
  seasonId: string,
  season: FirebaseFirestore.DocumentData,
): Promise<void> {
  const coachId = season.coachId as string | null;
  let usersQuery: FirebaseFirestore.Query = db.collection('users');
  if (coachId) usersQuery = usersQuery.where('coachId', '==', coachId);

  const usersSnap = await usersQuery.orderBy('gymScore', 'desc').get();

  // NOTA: `WriteBatch` tem limite de 500 operações. Para comunidades/bases
  // com mais alunos que isso, trocar por `BulkWriter` ou processar em
  // páginas antes de ir para produção em escala nacional.
  const batch = db.batch();
  usersSnap.docs.forEach((userDoc, index) => {
    const position = index + 1;
    const data = userDoc.data();
    const badgeGranted = position <= 10;

    batch.set(db.collection('seasons').doc(seasonId).collection('results').doc(userDoc.id), {
      userId: userDoc.id,
      seasonId,
      finalPosition: position,
      xpEarned: data.xpCurrentSeason ?? 0,
      finalGymScore: data.gymScore ?? 0,
      badgeGranted,
    });

    if (badgeGranted) {
      const badgeCode = position === 1 ? 'top1' : position <= 3 ? 'top3' : 'top10';
      batch.set(userDoc.ref.collection('achievements').doc(badgeCode), {
        unlockedAt: Timestamp.now(),
      });
    }

    batch.update(userDoc.ref, { xpCurrentSeason: 0, gymScore: 0 });
  });

  batch.update(db.collection('seasons').doc(seasonId), {
    isActive: false,
    rewardsDistributed: true,
  });

  const nextSeasonRef = db.collection('seasons').doc();
  const durationMs = SEASON_DURATIONS_MS[season.duration as keyof typeof SEASON_DURATIONS_MS];
  const startsAt = (season.endsAt as Timestamp).toDate();
  const endsAt = new Date(startsAt.getTime() + durationMs);

  batch.set(nextSeasonRef, {
    coachId: coachId ?? null,
    number: (season.number as number) + 1,
    duration: season.duration,
    startsAt: Timestamp.fromDate(startsAt),
    endsAt: Timestamp.fromDate(endsAt),
    isActive: true,
    rewardsDistributed: false,
  });

  await batch.commit();
}
