import * as crypto from 'crypto';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { db, Timestamp } from '../admin';
import { CHECKIN_COOLDOWN_MS, QR_TOKEN_TTL_MS, XP } from '../constants';
import { grantXp } from '../gamification/grantXp';
import { registerActivityDay } from '../gamification/streak';
import { incrementChallengeProgress } from '../challenges/updateChallengeProgress';

function parsePayload(payload: string): { coachId: string; issuedAtRaw: string; signature: string } {
  const parts = payload.split('.');
  if (parts.length !== 3) throw new HttpsError('invalid-argument', 'Código QR mal formado.');
  const [coachId, issuedAtRaw, signature] = parts;
  return { coachId, issuedAtRaw, signature };
}

function verifySignature(
  { coachId, issuedAtRaw, signature }: { coachId: string; issuedAtRaw: string; signature: string },
  secret: string,
): number {
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(`${coachId}.${issuedAtRaw}`)
    .digest('hex');

  const provided = Buffer.from(signature);
  const expected = Buffer.from(expectedSignature);
  if (provided.length !== expected.length || !crypto.timingSafeEqual(provided, expected)) {
    throw new HttpsError('invalid-argument', 'Código QR inválido.');
  }

  const issuedAtMs = Number(issuedAtRaw);
  if (Number.isNaN(issuedAtMs) || Date.now() - issuedAtMs > QR_TOKEN_TTL_MS) {
    throw new HttpsError('invalid-argument', 'El código QR venció, vuelve a escanearlo.');
  }

  return issuedAtMs;
}

/**
 * Cloud Function callable que valida o check-in presencial via QR Code
 * da treinadora (token rotativo assinado com
 * `coaches/{coachId}.qrCodeSecret`, TTL de 30s). É a única forma de criar
 * um documento em `coaches/{coachId}/checkins` — o cliente nunca escreve
 * diretamente (ver firestore.rules), o que evita fraude de check-in.
 */
export const validateCheckIn = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Inicia sesión para continuar.');

  const qrPayload = request.data?.qrPayload as string | undefined;
  if (!qrPayload) throw new HttpsError('invalid-argument', 'Falta el código QR.');

  const parsed = parsePayload(qrPayload);
  const coachRef = db.collection('coaches').doc(parsed.coachId);
  const coachSnap = await coachRef.get();
  if (!coachSnap.exists) throw new HttpsError('not-found', 'Coach no encontrado.');

  verifySignature(parsed, coachSnap.data()!.qrCodeSecret as string);
  const coachId = parsed.coachId;

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

  const checkInRef = checkInsRef.doc();
  await checkInRef.set({
    userId: uid,
    coachId,
    checkedInAt: Timestamp.fromDate(now),
    xpGranted: XP.checkIn,
    countedForStreak,
  });

  await grantXp(uid, XP.checkIn);
  await incrementChallengeProgress(uid, 'checkIns', 1);

  return {
    checkInId: checkInRef.id,
    userId: uid,
    coachId,
    checkedInAt: now.toISOString(),
    xpGranted: XP.checkIn,
    countedForStreak,
  };
});
