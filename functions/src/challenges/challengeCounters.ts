import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { db, FieldValue } from '../admin';

/**
 * Contadores dos retos mantidos pelo servidor. O app só cria a inscrição
 * (`participants/{uid}`) e a treinadora só edita o próprio reto; os
 * números vêm daqui, para ninguém inflar "participantes" à mão.
 */
export const onParticipantCreated = onDocumentCreated(
  'challenges/{challengeId}/participants/{userId}',
  async (event) => {
    await db
      .collection('challenges')
      .doc(event.params.challengeId)
      .update({ participantCount: FieldValue.increment(1) })
      .catch((error) =>
        console.error('onParticipantCreated: reto sumiu?', event.params.challengeId, error),
      );
  },
);

/** `coaches/{id}.activeChallengeCount` acompanha os retos ativos da comunidade. */
export const onChallengeWritten = onDocumentWritten('challenges/{challengeId}', async (event) => {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  const coachIds = new Set(
    [before?.coachId, after?.coachId].filter((c): c is string => typeof c === 'string' && c !== ''),
  );
  for (const coachId of coachIds) {
    const count = await db
      .collection('challenges')
      .where('coachId', '==', coachId)
      .where('isActive', '==', true)
      .count()
      .get();
    await db
      .collection('coaches')
      .doc(coachId)
      .set({ activeChallengeCount: count.data().count }, { merge: true });
  }
});
