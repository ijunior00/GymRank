import * as crypto from 'crypto';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { db } from '../admin';
import { PUBLIC_APP_URL } from '../constants';
import { getOrCreateQrSecret } from './qrSecret';

/**
 * QR fixo de uma academia (`coaches/{coachId}/locations/{locationId}`),
 * impresso e colado na recepção. É um link do próprio site, então abre o
 * app mesmo escaneado com a câmera do celular:
 *
 *   https://…/checkin?c=<coachId>&l=<locationId>&v=<versão>&s=<assinatura>
 *
 * A assinatura sai do mesmo segredo do QR rotativo e inclui a versão: a
 * coach "gera um novo" subindo `qrVersion`, e o papel antigo morre. Como
 * o QR é fixo, quem protege contra a foto do QR é a localização do
 * celular na hora do scan (ver validateCheckIn).
 */
export interface LocationQr {
  coachId: string;
  locationId: string;
  version: number;
  signature: string;
}

const SIGNATURE_CHARS = 32; // 128 bits: suficiente e mantém o QR pequeno para imprimir

export function signLocation(
  coachId: string,
  locationId: string,
  version: number,
  secret: string,
): string {
  return crypto
    .createHmac('sha256', secret)
    .update(`loc.${coachId}.${locationId}.${version}`)
    .digest('hex')
    .slice(0, SIGNATURE_CHARS);
}

export function buildLocationQrUrl(qr: LocationQr): string {
  const params = new URLSearchParams({
    c: qr.coachId,
    l: qr.locationId,
    v: String(qr.version),
    s: qr.signature,
  });
  return `${PUBLIC_APP_URL}/checkin?${params.toString()}`;
}

/**
 * Reconhece o QR de academia num payload escaneado (URL completa ou só a
 * query). Devolve `null` se não for esse formato — aí é o QR rotativo.
 */
export function parseLocationQr(payload: string): LocationQr | null {
  let params: URLSearchParams;
  try {
    // URL completa, caminho `/checkin?…` ou só a query: fica só a query.
    const query = payload.includes('://')
      ? new URL(payload).search
      : payload.slice(payload.indexOf('?') + 1);
    params = new URLSearchParams(query);
  } catch {
    return null;
  }
  const coachId = params.get('c');
  const locationId = params.get('l');
  const version = Number(params.get('v'));
  const signature = params.get('s');
  if (!coachId || !locationId || !signature || !Number.isInteger(version) || version < 1) {
    return null;
  }
  if (!/^[A-Za-z0-9_-]{1,64}$/.test(coachId) || !/^[A-Za-z0-9_-]{1,64}$/.test(locationId)) {
    return null;
  }
  if (!/^[0-9a-f]{32}$/.test(signature)) return null;
  return { coachId, locationId, version, signature };
}

export function signatureMatches(qr: LocationQr, secret: string): boolean {
  const expected = Buffer.from(signLocation(qr.coachId, qr.locationId, qr.version, secret));
  const provided = Buffer.from(qr.signature);
  return provided.length === expected.length && crypto.timingSafeEqual(provided, expected);
}

/**
 * Gera o conteúdo do QR de uma academia para a coach imprimir. Só a dona
 * da comunidade; a assinatura nunca é calculada no app.
 */
export const issueLocationQr = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Inicia sesión para continuar.');

  const locationId = request.data?.locationId;
  if (typeof locationId !== 'string' || !/^[A-Za-z0-9_-]{1,64}$/.test(locationId)) {
    throw new HttpsError('invalid-argument', 'Falta el punto de check-in.');
  }

  const userSnap = await db.collection('users').doc(uid).get();
  const user = userSnap.data();
  const coachId = user?.coachId as string | undefined;
  if (!user || user.role !== 'coach' || !coachId) {
    throw new HttpsError('permission-denied', 'Solo la coach de la comunidad genera el QR.');
  }

  const locSnap = await db
    .collection('coaches')
    .doc(coachId)
    .collection('locations')
    .doc(locationId)
    .get();
  const loc = locSnap.data();
  if (!loc) throw new HttpsError('not-found', 'Ese punto de check-in no existe.');

  const version = Math.max(1, Math.trunc((loc.qrVersion as number) ?? 1));
  const secret = await getOrCreateQrSecret(coachId);
  const qr: LocationQr = {
    coachId,
    locationId,
    version,
    signature: signLocation(coachId, locationId, version, secret),
  };
  return { url: buildLocationQrUrl(qr), version, name: (loc.name as string) ?? '' };
});
