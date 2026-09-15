import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { db, Timestamp } from '../admin';
import {
  CHECKIN_ACCURACY_ALLOWANCE_M,
  CHECKIN_COOLDOWN_MS,
  CHECKIN_MAX_ACCURACY_M,
  QR_TOKEN_TTL_MS,
  XP,
  XP_LIMITS,
} from '../constants';
import { grantXp } from '../gamification/grantXp';
import { dayKey } from '../gamification/periodKeys';
import { registerActivityDay } from '../gamification/streak';
import { incrementChallengeProgress } from '../challenges/updateChallengeProgress';
import { distanceMeters, parsePosition } from './geo';
import { parseLocationQr, signatureMatches } from './locationQr';
import { getOrCreateQrSecret, signCheckInToken } from './qrSecret';
import * as crypto from 'crypto';

function parseRotatingPayload(payload: string): { coachId: string; issuedAtRaw: string; signature: string } {
  const parts = payload.split('.');
  if (parts.length !== 3) throw new HttpsError('invalid-argument', 'Código QR mal formado.');
  const [coachId, issuedAtRaw, signature] = parts;
  return { coachId, issuedAtRaw, signature };
}

function verifyRotatingSignature(
  { coachId, issuedAtRaw, signature }: { coachId: string; issuedAtRaw: string; signature: string },
  secret: string,
): void {
  const issuedAtParsed = Number(issuedAtRaw);
  if (!Number.isInteger(issuedAtParsed)) {
    throw new HttpsError('invalid-argument', 'Código QR mal formado.');
  }
  const expected = Buffer.from(signCheckInToken(coachId, issuedAtParsed, secret));
  const provided = Buffer.from(signature);
  if (provided.length !== expected.length || !crypto.timingSafeEqual(provided, expected)) {
    throw new HttpsError('invalid-argument', 'Código QR inválido.');
  }
  if (Date.now() - issuedAtParsed > QR_TOKEN_TTL_MS) {
    throw new HttpsError('invalid-argument', 'El código QR venció, vuelve a escanearlo.');
  }
}

interface ResolvedQr {
  coachId: string;
  locationId: string | null;
  locationName: string | null;
  distanceM: number | null;
}

/**
 * QR de academia (impresso): confere assinatura, versão e que a aluna
 * está fisicamente perto. A distância aceita é o raio do ponto mais a
 * imprecisão que o próprio celular declara (até um teto).
 */
async function resolveLocationQr(
  payload: string,
  rawPosition: unknown,
): Promise<ResolvedQr | null> {
  const qr = parseLocationQr(payload);
  if (!qr) return null;

  const position = parsePosition(rawPosition);
  if (!position) {
    throw new HttpsError(
      'failed-precondition',
      'Para el check-in en la academia necesitamos tu ubicación. Activa el GPS, permite el acceso e intenta de nuevo.',
    );
  }
  if (position.accuracy > CHECKIN_MAX_ACCURACY_M) {
    throw new HttpsError(
      'failed-precondition',
      `Tu ubicación no es precisa ahora mismo (±${Math.round(position.accuracy)} m). ` +
        'Activa la ubicación precisa o acércate a una ventana e intenta de nuevo.',
    );
  }

  const locSnap = await db
    .collection('coaches')
    .doc(qr.coachId)
    .collection('locations')
    .doc(qr.locationId)
    .get();
  const loc = locSnap.data();
  const invalid = new HttpsError(
    'invalid-argument',
    'Este código QR ya no es válido. Pídele a tu coach el nuevo.',
  );
  if (!loc || loc.active === false) throw invalid;
  if (Math.trunc((loc.qrVersion as number) ?? 1) !== qr.version) throw invalid;
  if (!signatureMatches(qr, await getOrCreateQrSecret(qr.coachId))) throw invalid;

  const target = { lat: loc.lat as number, lng: loc.lng as number };
  const distance = distanceMeters(position, target);
  const radius = (loc.radiusM as number) ?? 150;
  const allowed = radius + Math.min(position.accuracy, CHECKIN_ACCURACY_ALLOWANCE_M);
  const name = (loc.name as string) ?? 'la academia';
  if (distance > allowed) {
    throw new HttpsError(
      'failed-precondition',
      `Estás a ${Math.round(distance)} m de ${name}. Acércate a la academia para hacer check-in.`,
    );
  }
  return { coachId: qr.coachId, locationId: qr.locationId, locationName: name, distanceM: Math.round(distance) };
}

/**
 * Cloud Function callable que valida o check-in presencial. Aceita dois
 * QRs: o rotativo (tela da coach, assinado com o segredo de
 * `coaches/{coachId}/private/qr`, TTL de 30s, emitido por
 * `issueCheckInToken`) e o fixo de academia (impresso, emitido por
 * `issueLocationQr`, exige a localização do celular). É a única forma de
 * criar um documento em `coaches/{coachId}/checkins` — o cliente nunca
 * escreve diretamente (ver firestore.rules), o que evita fraude.
 */
export const validateCheckIn = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Inicia sesión para continuar.');

  const qrPayload = request.data?.qrPayload;
  if (typeof qrPayload !== 'string' || qrPayload.length === 0 || qrPayload.length > 600) {
    throw new HttpsError('invalid-argument', 'Falta el código QR.');
  }

  let resolved = await resolveLocationQr(qrPayload, request.data?.position);
  if (!resolved) {
    const parsed = parseRotatingPayload(qrPayload);
    const coachSnap = await db.collection('coaches').doc(parsed.coachId).get();
    if (!coachSnap.exists) throw new HttpsError('not-found', 'Coach no encontrado.');
    verifyRotatingSignature(parsed, await getOrCreateQrSecret(parsed.coachId));
    resolved = { coachId: parsed.coachId, locationId: null, locationName: null, distanceM: null };
  }
  const { coachId } = resolved;
  const coachRef = db.collection('coaches').doc(coachId);

  const now = new Date();
  const checkInsRef = coachRef.collection('checkins');

  const recentSnap = await checkInsRef
    .where('userId', '==', uid)
    .orderBy('checkedInAt', 'desc')
    .limit(1)
    .get();

  const lastCheckIn = recentSnap.docs[0]?.data();
  if (lastCheckIn) {
    const lastAt = (lastCheckIn.checkedInAt as Timestamp).toDate();
    if (now.getTime() - lastAt.getTime() < CHECKIN_COOLDOWN_MS) {
      throw new HttpsError('already-exists', 'Ya hiciste check-in hace poco.');
    }
  }

  const { countedForStreak } = await registerActivityDay(uid, now);

  const xp = await grantXp(uid, XP.checkIn, {
    bucket: `checkin:${dayKey(now)}`,
    max: XP_LIMITS.checkInPerDay,
  });

  const checkInRef = checkInsRef.doc();
  await checkInRef.set({
    userId: uid,
    coachId,
    checkedInAt: Timestamp.fromDate(now),
    xpGranted: xp.amount,
    countedForStreak,
    locationId: resolved.locationId,
    locationName: resolved.locationName,
    distanceM: resolved.distanceM,
  });

  await incrementChallengeProgress(uid, 'checkIns', 1);

  return {
    checkInId: checkInRef.id,
    userId: uid,
    coachId,
    checkedInAt: now.toISOString(),
    xpGranted: xp.amount,
    countedForStreak,
    locationName: resolved.locationName,
  };
});
