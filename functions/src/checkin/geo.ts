/** Posição enviada pelo celular da aluna no momento do scan. */
export interface Position {
  lat: number;
  lng: number;
  /** Raio de incerteza em metros, como o aparelho informa. */
  accuracy: number;
}

const EARTH_RADIUS_M = 6371000;

/** Distância em metros entre dois pontos (fórmula de Haversine). */
export function distanceMeters(
  a: { lat: number; lng: number },
  b: { lat: number; lng: number },
): number {
  const toRad = (deg: number) => (deg * Math.PI) / 180;
  const dLat = toRad(b.lat - a.lat);
  const dLng = toRad(b.lng - a.lng);
  const h =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * Math.sin(dLng / 2) ** 2;
  return 2 * EARTH_RADIUS_M * Math.asin(Math.min(1, Math.sqrt(h)));
}

/** Lê e valida a posição vinda do cliente; `null` se não veio ou é lixo. */
export function parsePosition(raw: unknown): Position | null {
  if (!raw || typeof raw !== 'object') return null;
  const { lat, lng, accuracy } = raw as Record<string, unknown>;
  if (typeof lat !== 'number' || typeof lng !== 'number') return null;
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
  const acc = typeof accuracy === 'number' && Number.isFinite(accuracy) ? Math.max(0, accuracy) : 0;
  return { lat, lng, accuracy: acc };
}
