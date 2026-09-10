import { db, Timestamp } from '../admin';

function isSameCalendarDay(a: Date, b: Date): boolean {
  return (
    a.getUTCFullYear() === b.getUTCFullYear() &&
    a.getUTCMonth() === b.getUTCMonth() &&
    a.getUTCDate() === b.getUTCDate()
  );
}

function isNextCalendarDay(previous: Date, current: Date): boolean {
  const next = new Date(previous);
  next.setUTCDate(next.getUTCDate() + 1);
  return isSameCalendarDay(next, current);
}

/**
 * Registra um dia de atividade (check-in presencial ou treino concluído)
 * na sequência do usuário: incrementa se for o dia seguinte, reinicia se
 * houve intervalo e não conta duas vezes no mesmo dia. Atualiza
 * `users/{uid}.lastCheckInAt/currentStreakDays/longestStreakDays`.
 * Única porta de entrada para a sequência — ver docs/architecture.md.
 */
export async function registerActivityDay(
  userId: string,
  now: Date,
): Promise<{ currentStreakDays: number; countedForStreak: boolean }> {
  const userRef = db.collection('users').doc(userId);
  const userSnap = await userRef.get();
  const userData = userSnap.data() ?? {};
  const lastAt = (userData.lastCheckInAt as Timestamp | undefined)?.toDate();

  let currentStreakDays = (userData.currentStreakDays as number) ?? 0;
  let countedForStreak = true;
  if (lastAt && isSameCalendarDay(lastAt, now)) {
    countedForStreak = false; // já contou hoje
  } else if (lastAt && isNextCalendarDay(lastAt, now)) {
    currentStreakDays += 1;
  } else {
    currentStreakDays = 1;
  }
  const longestStreakDays = Math.max(
    currentStreakDays,
    (userData.longestStreakDays as number) ?? 0,
  );

  // Não recua `lastCheckInAt` se já houve atividade mais recente hoje.
  const lastCheckInAt =
    lastAt && lastAt.getTime() > now.getTime() ? Timestamp.fromDate(lastAt) : Timestamp.fromDate(now);

  await userRef.update({ lastCheckInAt, currentStreakDays, longestStreakDays });
  return { currentStreakDays, countedForStreak };
}
