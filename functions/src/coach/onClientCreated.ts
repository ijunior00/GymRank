import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { db, FieldValue } from '../admin';
import { XP } from '../constants';
import { grantXp } from '../gamification/grantXp';
import { dispatchNotification } from '../notifications/dispatchNotification';

/**
 * Um aluno entrou na comunidade (pelo código de convite ou cadastrado
 * pela treinadora): atualiza o contador da marca, avisa a treinadora e,
 * quando o aluno disse quem o indicou, credita o embaixador.
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

    const studentName = (userSnap.data()?.name as string | undefined) ?? 'Un nuevo alumno';
    const ownerUserId = coachSnap.data()?.ownerUserId as string | undefined;

    if (ownerUserId && ownerUserId !== userId) {
      await dispatchNotification({
        userId: ownerUserId,
        type: 'newStudent',
        title: 'Nuevo alumno',
        body: `${studentName} se unió a tu comunidad.`,
        deepLink: `/coach/clients/${userId}`,
      });
    }

    await creditReferrer(userId, studentName, userSnap.data()?.referredBy);
  },
);

/**
 * Programa de indicação: quem trouxe o aluno ganha XP, um ponto no
 * contador de embaixador e uma notificação. O `referredBy` é o
 * `username` digitado no cadastro, então a busca é pelo espelho em
 * minúsculas — e nunca credita o próprio aluno.
 */
async function creditReferrer(
  newUserId: string,
  newUserName: string,
  referredBy: unknown,
): Promise<void> {
  if (typeof referredBy !== 'string' || referredBy.trim() === '') return;

  const username = referredBy.replace('@', '').trim().toLowerCase();
  const snap = await db
    .collection('users')
    .where('usernameLowercase', '==', username)
    .limit(1)
    .get();

  const referrer = snap.docs[0];
  if (!referrer || referrer.id === newUserId) return;

  await referrer.ref.update({ referralCount: FieldValue.increment(1) });
  await grantXp(referrer.id, XP.friendInvited);
  await dispatchNotification({
    userId: referrer.id,
    type: 'referralJoined',
    title: '¡Tu invitación funcionó! 🎉',
    body: `${newUserName} se unió con tu recomendación. +${XP.friendInvited} XP.`,
    deepLink: '/profile',
  });
}
