import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { db, FieldValue } from '../admin';
import { dispatchNotification } from '../notifications/dispatchNotification';

/**
 * Um aluno entrou na comunidade (pelo código de convite ou cadastrado
 * pela treinadora): atualiza o contador da marca e avisa a treinadora.
 */
export const onClientCreated = onDocumentCreated(
  'coaches/{coachId}/clients/{userId}',
  async (event) => {
    const { coachId, userId } = event.params;

    const coachRef = db.collection('coaches').doc(coachId);
    const [coachSnap, userSnap] = await Promise.all([
      coachRef.get(),
      db.collection('users').doc(userId).get(),
    ]);
    if (!coachSnap.exists) return;

    await coachRef.update({ studentCount: FieldValue.increment(1) });

    const ownerUserId = coachSnap.data()?.ownerUserId as string | undefined;
    if (!ownerUserId || ownerUserId === userId) return;

    const studentName = (userSnap.data()?.name as string | undefined) ?? 'Un nuevo alumno';
    await dispatchNotification({
      userId: ownerUserId,
      type: 'newStudent',
      title: 'Nuevo alumno',
      body: `${studentName} se unió a tu comunidad.`,
      deepLink: `/coach/clients/${userId}`,
    });
  },
);
