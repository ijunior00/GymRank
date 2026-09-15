import { db, FieldValue } from '../admin';
import { levelForXp } from '../constants';
import { generateAutoPost } from '../social/generatePost';
import { dispatchNotification } from '../notifications/dispatchNotification';

/**
 * Teto de concessões por período para uma fonte de XP. `bucket` é a chave
 * do período (ex.: `workout:2026-09-15`, `social:2026-W38`) e `max`
 * quantas vezes essa fonte pode render XP dentro dele. O registro fica em
 * `users/{uid}/xp_ledger/{bucket}`, que só o servidor escreve.
 */
export interface XpLimit {
  bucket: string;
  max: number;
}

export interface GrantXpResult {
  granted: boolean;
  amount: number;
}

/**
 * Única porta de entrada para conceder XP a um usuário. Recalcula o
 * nível a partir do XP total e, se houve level up, gera post automático
 * no feed e notificação — nunca deixe um caller incrementar `level`
 * diretamente.
 *
 * Com `limit`, respeita o teto do período: passou dele, não concede nada
 * (e devolve `granted: false`). É o que impede "registrar" 200 treinos
 * numa tarde para subir no ranking — as regras do Firestore limitam as
 * datas, e aqui fica o limite de quantas vezes cada coisa vale XP.
 */
export async function grantXp(
  userId: string,
  amount: number,
  limit?: XpLimit,
): Promise<GrantXpResult> {
  const userRef = db.collection('users').doc(userId);
  const ledgerRef = limit ? userRef.collection('xp_ledger').doc(limit.bucket) : null;

  // A transação só cuida do incremento atômico de XP/nível (e do
  // registro do teto). Efeitos colaterais (post, notificação) rodam
  // depois de commitada, pois transações podem ser reexecutadas em caso
  // de contenção e não devem disparar escritas fora de si mesmas mais de
  // uma vez.
  const result = await db.runTransaction(async (tx) => {
    const snap = await tx.get(userRef);
    if (!snap.exists) return null;

    if (ledgerRef && limit) {
      const ledger = await tx.get(ledgerRef);
      const used = (ledger.data()?.count as number | undefined) ?? 0;
      if (used >= limit.max) return { capped: true as const };
      tx.set(
        ledgerRef,
        { count: used + 1, xp: FieldValue.increment(amount), updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
    }

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
      capped: false as const,
      name: (data.name as string) ?? '',
      photoUrl: (data.photoUrl as string | null) ?? null,
      leveledUp: newLevel > previousLevel,
      newLevel,
    };
  });

  if (!result || result.capped) return { granted: false, amount: 0 };
  if (!result.leveledUp) return { granted: true, amount };

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
  return { granted: true, amount };
}
