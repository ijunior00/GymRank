import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { XP } from '../constants';
import { grantXp } from './grantXp';
import { incrementChallengeProgress } from '../challenges/updateChallengeProgress';

/** Concede XP quando um treino é registrado e atualiza desafios de dias treinados. */
export const onWorkoutCreated = onDocumentCreated('workouts/{workoutId}', async (event) => {
  const data = event.data?.data();
  if (!data) return;
  await grantXp(data.userId as string, XP.workoutLogged);
  await incrementChallengeProgress(data.userId as string, 'diasTreinados', 1);
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
