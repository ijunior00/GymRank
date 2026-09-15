import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { db, Timestamp } from '../admin';
import { XP, XP_LIMITS } from '../constants';
import { grantXp } from './grantXp';
import { dayKey, weekKey } from './periodKeys';
import { incrementChallengeProgress } from '../challenges/updateChallengeProgress';

/**
 * Concede XP quando um treino é registrado (um por dia vale pontos),
 * atualiza desafios de dias treinados e marca a última atividade no
 * vínculo com a treinadora (`coaches/{coachId}/clients/{uid}.lastWorkoutAt`),
 * que alimenta a lista de alunos do painel.
 */
export const onWorkoutCreated = onDocumentCreated('workouts/{workoutId}', async (event) => {
  const data = event.data?.data();
  if (!data) return;
  const userId = data.userId as string;

  const xp = await grantXp(userId, XP.workoutLogged, {
    bucket: `workout:${dayKey()}`,
    max: XP_LIMITS.workoutLoggedPerDay,
  });
  // O desafio "dias treinados" conta dias, não treinos: só avança quando
  // o treino do dia valeu XP (o primeiro).
  if (xp.granted) await incrementChallengeProgress(userId, 'diasTreinados', 1);

  const userSnap = await db.collection('users').doc(userId).get();
  const coachId = userSnap.data()?.coachId as string | undefined;
  if (!coachId) return;

  const workoutDate = (data.date as Timestamp | undefined) ?? Timestamp.now();
  await db
    .collection('coaches')
    .doc(coachId)
    .collection('clients')
    .doc(userId)
    .set({ lastWorkoutAt: workoutDate }, { merge: true });
});

/** Concede XP quando uma nova medição corporal é registrada (uma por semana vale). */
export const onBodyMeasurementCreated = onDocumentCreated(
  'body_measurements/{measurementId}',
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    await grantXp(data.userId as string, XP.bodyMeasurement, {
      bucket: `measurement:${weekKey()}`,
      max: XP_LIMITS.bodyMeasurementPerWeek,
    });
  },
);

/** Concede XP quando uma nova foto de evolução é enviada (uma por dia vale). */
export const onProgressPhotoCreated = onDocumentCreated(
  'progress_photos/{photoId}',
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    await grantXp(data.userId as string, XP.progressPhoto, {
      bucket: `photo:${dayKey()}`,
      max: XP_LIMITS.progressPhotoPerDay,
    });
  },
);

/**
 * Concede XP a quem convidou quando a amizade transiciona para "accepted".
 * Divide o teto semanal com as indicações: contas falsas aceitando
 * amizade deixam de ser uma fábrica de pontos.
 */
export const onFriendshipUpdated = onDocumentUpdated(
  'friendships/{friendshipId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === 'accepted' || after.status !== 'accepted') return;

    await grantXp(after.requesterId as string, XP.friendInvited, {
      bucket: `social:${weekKey()}`,
      max: XP_LIMITS.socialPerWeek,
    });
  },
);
