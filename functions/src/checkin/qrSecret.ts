import * as crypto from 'crypto';
import { db, FieldValue } from '../admin';

/**
 * Segredo do QR de check-in de uma treinadora. Mora em
 * `coaches/{coachId}/private/qr`, que as regras do Firestore fecham para
 * todo mundo: só as functions (Admin SDK) leem. Antes ficava no próprio
 * `coaches/{coachId}`, legível por qualquer conta logada — e quem lê o
 * segredo fabrica check-ins válidos sem pisar na academia.
 *
 * Cria o segredo na primeira vez que alguém precisa dele e, se ainda
 * existir o campo antigo no documento público, apaga-o de vez.
 */
export async function getOrCreateQrSecret(coachId: string): Promise<string> {
  const coachRef = db.collection('coaches').doc(coachId);
  const privateRef = coachRef.collection('private').doc('qr');

  const secret = await db.runTransaction(async (tx) => {
    const snap = await tx.get(privateRef);
    const existing = snap.data()?.secret as string | undefined;
    if (existing) return existing;
    const fresh = crypto.randomBytes(32).toString('hex');
    tx.set(privateRef, { secret: fresh, createdAt: FieldValue.serverTimestamp() });
    return fresh;
  });

  const coachSnap = await coachRef.get();
  if (coachSnap.exists && coachSnap.data()?.qrCodeSecret !== undefined) {
    await coachRef.update({ qrCodeSecret: FieldValue.delete() });
  }
  return secret;
}

/** Assinatura de `coachId.issuedAt`, a parte do QR que só o servidor produz. */
export function signCheckInToken(coachId: string, issuedAtMs: number, secret: string): string {
  return crypto.createHmac('sha256', secret).update(`${coachId}.${issuedAtMs}`).digest('hex');
}
