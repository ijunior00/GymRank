import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { db, Timestamp } from '../admin';
import { XP } from '../constants';
import { grantXp } from './grantXp';
import { incrementChallengeProgress } from '../challenges/updateChallengeProgress';

/**
 * Concede XP quando um treino é registrado, atualiza desafios de dias
 * treinados e marca a última atividade no vínculo com a treinadora
 * (`coaches/{coachId}/clients/{uid}.lastWorkoutAt`), que alimenta a lista
 * de alunos do painel.
 */
export const onWorkoutCreated = onDocumentCreated('workouts/{workoutId}', async (event) => {
  const data = event.data?.data();
  if (!data) return;
  const userId = data.userId as string;

  await grantXp(userId, XP.workoutLogged);
  await incrementChallengeProgress(userId, 'diasTreinados', 1);

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

/** Concede XP quando uma nova medição corporal é registrada. */
export const onBodyMeasurementCreated = onDocumentCreated(
  'body_measurements/{measurementId}',
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    await grantXp(data.userId as string, XP.bodyMeasurement);
  },
);

/** Concede XP quando uma nova foto de evolução é enviada. */
export const onProgressPhotoCreated = onDocumentCreated(
  'progress_photos/{photoId}',
  async (event) => {
    const data = event.data?.data();
    if (!data) return;
    await grantXp(data.userId as string, XP.progressPhoto);
  },
);

/** Concede XP a quem convidou quando a amizade transiciona para "accepted". */
export const onFriendshipUpdated = onDocumentUpdated(
  'friendships/{friendshipId}',
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!before || !after) return;
    if (before.status === 'accepted' || after.status !== 'accepted') return;

    await grantXp(after.requesterId as string, XP.friendInvited);
  },
);
