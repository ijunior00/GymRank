import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { db, FieldValue } from '../admin';

/**
 * O que qualquer conta logada pode saber de uma pessoa: o suficiente
 * para a busca por @, a lista de amigas e o ranking. Nada de data de
 * nascimento, sexo, altura, cidade, plano ou quem indicou — isso fica em
 * `users/{uid}`, que só a dona e o staff da comunidade dela leem.
 */
export function publicProfileOf(data: FirebaseFirestore.DocumentData) {
  const username = (data.username as string | undefined) ?? '';
  return {
    name: (data.name as string | undefined) ?? '',
    username,
    usernameLowercase:
      (data.usernameLowercase as string | undefined) ?? username.toLowerCase(),
    photoUrl: (data.photoUrl as string | null | undefined) ?? null,
    level: (data.level as number | undefined) ?? 1,
    coachId: (data.coachId as string | null | undefined) ?? null,
    updatedAt: FieldValue.serverTimestamp(),
  };
}

/** Espelha `users/{uid}` em `public_profiles/{uid}` a cada escrita. */
export const onUserWritten = onDocumentWritten('users/{userId}', async (event) => {
  const after = event.data?.after;
  const ref = db.collection('public_profiles').doc(event.params.userId);
  if (!after?.exists) {
    await ref.delete().catch(() => undefined);
    return;
  }
  await ref.set(publicProfileOf(after.data()!), { merge: true });
});
