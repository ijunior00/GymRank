import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { db } from '../admin';
import { QR_TOKEN_TTL_MS } from '../constants';
import { getOrCreateQrSecret, signCheckInToken } from './qrSecret';

/**
 * Gera o conteúdo do QR de check-in que a treinadora mostra na academia:
 * `coachId.issuedAt.assinatura`, válido por `QR_TOKEN_TTL_MS`. Só a dona
 * da comunidade chama; o segredo nunca sai do servidor. O app da coach
 * chama de novo a cada rotação.
 */
export const issueCheckInToken = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Inicia sesión para continuar.');

  const userSnap = await db.collection('users').doc(uid).get();
  const user = userSnap.data();
  const coachId = user?.coachId as string | undefined;
  if (!user || user.role !== 'coach' || !coachId) {
    throw new HttpsError('permission-denied', 'Solo la coach de la comunidad genera el QR.');
  }

  const secret = await getOrCreateQrSecret(coachId);
  const issuedAt = Date.now();
  return {
    payload: `${coachId}.${issuedAt}.${signCheckInToken(coachId, issuedAt, secret)}`,
    expiresAt: new Date(issuedAt + QR_TOKEN_TTL_MS).toISOString(),
  };
});
