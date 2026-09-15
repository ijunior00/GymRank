/**
 * Chaves de período no fuso das alunas (Cidade do México). Um "dia" de XP
 * é o dia delas, não o UTC do servidor — senão o teto diário viraria às
 * 18h/19h locais.
 */
export const XP_TIME_ZONE = 'America/Mexico_City';

const dayFormatter = new Intl.DateTimeFormat('en-CA', {
  timeZone: XP_TIME_ZONE,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
});

/** `2026-09-15` no fuso local. */
export function dayKey(date: Date = new Date()): string {
  return dayFormatter.format(date);
}

/**
 * `2026-W38`: a semana ISO (segunda a domingo) do dia local. Calculada
 * sobre a data local para a virada de semana cair na meia-noite delas.
 */
export function weekKey(date: Date = new Date()): string {
  const [year, month, day] = dayKey(date).split('-').map(Number);
  const local = new Date(Date.UTC(year, month - 1, day));
  const weekday = local.getUTCDay() || 7; // domingo = 7
  local.setUTCDate(local.getUTCDate() + 4 - weekday); // quinta da mesma semana ISO
  const yearStart = new Date(Date.UTC(local.getUTCFullYear(), 0, 1));
  const week = Math.ceil(((local.getTime() - yearStart.getTime()) / 86400000 + 1) / 7);
  return `${local.getUTCFullYear()}-W${String(week).padStart(2, '0')}`;
}
