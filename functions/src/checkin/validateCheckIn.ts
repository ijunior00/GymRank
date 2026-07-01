import * as crypto from 'crypto';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { db, Timestamp } from '../admin';
import { CHECKIN_COOLDOWN_MS, QR_TOKEN_TTL_MS, XP } from '../constants';
import { grantXp } from '../gamification/grantXp';
import { incrementChallengeProgress } from '../challenges/updateChallengeProgress';

function parsePayload(payload: string): { gymId: string; issuedAtRaw: string; signature: string } {
  const parts = payload.split('.');
  if (parts.length !== 3) throw new HttpsError('invalid-argument', 'QR Code malformado.');
  const [gymId, issuedAtRaw, signature] = parts;
  return { gymId, issuedAtRaw, signature };
}

function verifySignature(
  { gymId, issuedAtRaw, signature }: { gymId: string; issuedAtRaw: string; signature: string },
  secret: string,
): number {
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(`${gymId}.${issuedAtRaw}`)
    .digest('hex');

  const provided = Buffer.from(signature);
  const expected = Buffer.from(expectedSignature);
  if (provided.length !== expected.length || !crypto.timingSafeEqual(provided, expected)) {
    throw new HttpsError('invalid-argument', 'QR Code inválido.');
  }

  const issuedAtMs = Number(issuedAtRaw);
  if (Number.isNaN(issuedAtMs) || Date.now() - issuedAtMs > QR_TOKEN_TTL_MS) {
    throw new HttpsError('invalid-argument', 'QR Code expirado, tente escanear novamente.');
  }

  return issuedAtMs;
}

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
 * Cloud Function callable que valida o check-in via QR Code exclusivo da
 * academia (token rotativo assinado com `gyms/{gymId}.qrCodeSecret`,
 * TTL de 30s). É a única forma de criar um documento em
 * `gyms/{gymId}/checkins` — o cliente nunca escreve diretamente
 * (ver firestore.rules), o que evita fraude de check-in.
 */
export const validateCheckIn = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Faça login para continuar.');

  const qrPayload = request.data?.qrPayload as string | undefined;
  if (!qrPayload) throw new HttpsError('invalid-argument', 'QR Code ausente.');

  const parsed = parsePayload(qrPayload);
  const gymRef = db.collection('gyms').doc(parsed.gymId);
  const gymSnap = await gymRef.get();
  if (!gymSnap.exists) throw new HttpsError('not-found', 'Academia não encontrada.');

  verifySignature(parsed, gymSnap.data()!.qrCodeSecret as string);
  const gymId = parsed.gymId;

  const now = new Date();
  const checkInsRef = gymRef.collection('checkins');

  const recentSnap = await checkInsRef
    .where('userId', '==', uid)
    .orderBy('checkedInAt', 'desc')
    .limit(1)
    .get();

  const lastCheckIn = recentSnap.docs[0]?.data();
  if (lastCheckIn) {
    const lastAt = (lastCheckIn.checkedInAt as Timestamp).toDate();
    if (now.getTime() - lastAt.getTime() < CHECKIN_COOLDOWN_MS) {
      throw new HttpsError('already-exists', 'Você já fez check-in recentemente.');
    }
  }

  const userRef = db.collection('users').doc(uid);
  const userSnap = await userRef.get();
  const userData = userSnap.data() ?? {};
  const lastCheckInAt = (userData.lastCheckInAt as Timestamp | undefined)?.toDate();

  let currentStreakDays = (userData.currentStreakDays as number) ?? 0;
  let countedForStreak = true;
  if (lastCheckInAt && isSameCalendarDay(lastCheckInAt, now)) {
    countedForStreak = false; // já contou hoje, apenas registra o check-in
  } else if (lastCheckInAt && isNextCalendarDay(lastCheckInAt, now)) {
    currentStreakDays += 1;
  } else {
    currentStreakDays = 1;
  }
  const longestStreakDays = Math.max(
    currentStreakDays,
    (userData.longestStreakDays as number) ?? 0,
  );

  const checkInRef = checkInsRef.doc();
  await checkInRef.set({
    userId: uid,
    gymId,
    checkedInAt: Timestamp.fromDate(now),
    xpGranted: XP.checkIn,
    countedForStreak,
  });

  await userRef.update({
    lastCheckInAt: Timestamp.fromDate(now),
    currentStreakDays,
    longestStreakDays,
  });

  await grantXp(uid, XP.checkIn);
  await incrementChallengeProgress(uid, 'checkIns', 1);

  return {
    checkInId: checkInRef.id,
    userId: uid,
    gymId,
    checkedInAt: now.toISOString(),
    xpGranted: XP.checkIn,
    countedForStreak,
  };
});
