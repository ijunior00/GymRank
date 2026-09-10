import { db, messaging, Timestamp } from '../admin';

export type NotificationType =
  | 'workoutReminder'
  | 'newChallenge'
  | 'friendOvertook'
  | 'newLevel'
  | 'newAchievement'
  | 'championshipEnded'
  | 'rewardAvailable'
  | 'newStudent';

interface NotificationInput {
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  deepLink?: string | null;
}

/**
 * Grava a notificação em Firestore (para o centro de notificações do
 * app) e envia push via FCM para todos os tokens registrados do
 * usuário. Falhas de push são logadas e não interrompem a escrita no
 * Firestore.
 */
export async function dispatchNotification(input: NotificationInput): Promise<void> {
  await db.collection('notifications').add({
    userId: input.userId,
    type: input.type,
    title: input.title,
    body: input.body,
    deepLink: input.deepLink ?? null,
    read: false,
    createdAt: Timestamp.now(),
  });

  const tokensSnap = await db
    .collection('users')
    .doc(input.userId)
    .collection('fcmTokens')
    .get();

  const tokens = tokensSnap.docs.map((doc) => doc.id);
  if (tokens.length === 0) return;

  try {
    await messaging.sendEachForMulticast({
      tokens,
      notification: { title: input.title, body: input.body },
      data: input.deepLink ? { deepLink: input.deepLink } : {},
    });
  } catch (error) {
    console.error('Falha ao enviar push notification', error); // log interno, não chega ao usuário
  }
}
