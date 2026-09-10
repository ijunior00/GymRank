import { db, Timestamp, FieldValue } from '../admin';
import { dispatchNotification } from '../notifications/dispatchNotification';

/**
 * Concede um prêmio a um usuário, decrementando o estoque de forma
 * atômica. `sourceType`/`sourceId` registram a origem (desafio ou
 * campeonato) para auditoria.
 */
export async function grantReward(params: {
  rewardId: string;
  userId: string;
  sourceType: 'challenge' | 'championship' | 'season';
  sourceId: string;
}): Promise<void> {
  const rewardRef = db.collection('rewards').doc(params.rewardId);

  const granted = await db.runTransaction(async (tx) => {
    const rewardSnap = await tx.get(rewardRef);
    if (!rewardSnap.exists) return false;
    const stock = (rewardSnap.data()!.stock as number) ?? 0;
    if (stock <= 0) return false;

    tx.update(rewardRef, { stock: FieldValue.increment(-1) });
    tx.set(rewardRef.collection('grants').doc(), {
      rewardId: params.rewardId,
      userId: params.userId,
      sourceType: params.sourceType,
      sourceId: params.sourceId,
      status: 'granted',
      grantedAt: Timestamp.now(),
    });
    return true;
  });

  if (!granted) return;

  await dispatchNotification({
    userId: params.userId,
    type: 'rewardAvailable',
    title: '¡Ganaste un premio!',
    body: 'Revisa tu nuevo premio en el app.',
    deepLink: '/rewards',
  });
}
