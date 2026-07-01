/**
 * Espelha lib/core/constants/app_constants.dart. Mantido em sincronia
 * manualmente — é a única fonte de verdade para valores de negócio no
 * backend, já que o cliente nunca deve poder alterar XP/Gym Score
 * diretamente.
 */
export const XP = {
  checkIn: 20,
  workoutLogged: 50,
  bodyMeasurement: 30,
  progressPhoto: 25,
  challengeCompleted: 200,
  friendInvited: 150,
} as const;

export const GYM_SCORE_WEIGHTS = {
  frequency: 0.35,
  consistency: 0.25,
  challenges: 0.2,
  evolution: 0.2,
} as const;

export const CHECKIN_COOLDOWN_MS = 6 * 60 * 60 * 1000;
export const QR_TOKEN_TTL_MS = 30 * 1000;

export function levelForXp(totalXp: number): number {
  let level = 1;
  while (xpRequiredFor(level + 1) <= totalXp) {
    level++;
  }
  return level;
}

export function xpRequiredFor(level: number): number {
  if (level <= 1) return 0;
  return Math.round(100 * (level - 1) * (level - 1) * 0.5 + 100 * (level - 1));
}
