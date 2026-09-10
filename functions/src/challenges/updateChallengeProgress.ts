import { db, Timestamp } from '../admin';
import { grantXp } from '../gamification/grantXp';
import { grantReward } from '../rewards/grantReward';
import { generateAutoPost } from '../social/generatePost';

type ChallengeMetric =
  | 'diasTreinados'
  | 'distanciaKm'
  | 'pesoPerdidoKg'
  | 'massaMuscularGanhaKg'
  | 'checkIns';

/**
 * Atualiza o progresso de todos os desafios ativos do usuário para a
 * métrica informada. Chamado a partir de eventos de origem confiável
 * (check-in validado, treino registrado) — nunca a partir de um valor
 * enviado diretamente pelo cliente, para evitar trapaça.
 */
export async function incrementChallengeProgress(
  userId: string,
  metric: ChallengeMetric,
  amount: number,
): Promise<void> {
  const participantsSnap = await db
    .collectionGroup('participants')
    .where('userId', '==', userId)
    .where('completed', '==', false)
    .get();

  for (const participantDoc of participantsSnap.docs) {
    const challengeRef = participantDoc.ref.parent.parent;
    if (!challengeRef) continue;

    const challengeSnap = await challengeRef.get();
    const challenge = challengeSnap.data();
    if (!challenge || challenge.metric !== metric || !challenge.isActive) continue;

    const newValue = (participantDoc.data().currentValue as number) + amount;
    const completed = newValue >= (challenge.targetValue as number);

    await participantDoc.ref.update({
      currentValue: newValue,
      completed,
      ...(completed ? { completedAt: Timestamp.now() } : {}),
    });

    if (!completed) continue;

    await grantXp(userId, (challenge.xpReward as number) ?? 0);

    if (challenge.rewardId) {
      await grantReward({
        rewardId: challenge.rewardId as string,
        userId,
        sourceType: 'challenge',
        sourceId: challengeRef.id,
      });
    }

    const userSnap = await db.collection('users').doc(userId).get();
    const userData = userSnap.data();
    await generateAutoPost({
      userId,
      authorName: (userData?.name as string) ?? '',
      authorPhotoUrl: (userData?.photoUrl as string | null) ?? null,
      type: 'challengeCompleted',
      text: `¡${userData?.name} completó el reto "${challenge.title}"!`,
    });
  }
}
