import { db } from '../admin';
import { levelForXp } from '../constants';
import { generateAutoPost } from '../social/generatePost';
import { dispatchNotification } from '../notifications/dispatchNotification';

/**
 * Única porta de entrada para conceder XP a um usuário. Recalcula o
 * nível a partir do XP total e, se houve level up, gera post automático
 * no feed e notificação — nunca deixe um caller incrementar `level`
 * diretamente.
 */
export async function grantXp(userId: string, amount: number): Promise<void> {
  const userRef = db.collection('users').doc(userId);

  // A transação só cuida do incremento atômico de XP/nível. Efeitos
  // colaterais (post, notificação) rodam depois de commitada, pois
  // transações podem ser reexecutadas em caso de contenção e não devem
  // disparar escritas fora de si mesmas mais de uma vez.
  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    if (!snap.exists) return null;

    const data = snap.data()!;
    const previousLevel = (data.level as number) ?? 1;
    const newXpTotal = ((data.xpTotal as number) ?? 0) + amount;
    const newXpSeason = ((data.xpCurrentSeason as number) ?? 0) + amount;
    const newLevel = levelForXp(newXpTotal);

    tx.update(userRef, {
      xpTotal: newXpTotal,
      xpCurrentSeason: newXpSeason,
      level: newLevel,
    });

    return {
      name: (data.name as string) ?? '',
      photoUrl: (data.photoUrl as string | null) ?? null,
      leveledUp: newLevel > previousLevel,
      newLevel,
    };
  });

  if (!result?.leveledUp) return;

  await generateAutoPost({
    userId,
    authorName: result.name,
    authorPhotoUrl: result.photoUrl,
    type: 'levelUp',
    text: `¡${result.name} subió al nivel ${result.newLevel}!`,
  });
  await dispatchNotification({
    userId,
    type: 'newLevel',
    title: '¡Nuevo nivel!',
    body: `Llegaste al nivel ${result.newLevel}.`,
  });
}
