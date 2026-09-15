import { onDocumentCreated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { db, FieldValue } from '../admin';

/**
 * Contadores do feed mantidos pelo servidor. Antes o próprio app somava
 * `likeCount`/`commentCount` no post — o que exigia deixar qualquer conta
 * editar o post de outra pessoa, e permitia inflar o número à vontade.
 * Agora o cliente só cria/apaga a curtida (uma por pessoa, id = uid) e o
 * comentário; o número vem daqui.
 */
export const onLikeWritten = onDocumentWritten('posts/{postId}/likes/{userId}', async (event) => {
  const existedBefore = event.data?.before?.exists ?? false;
  const existsAfter = event.data?.after?.exists ?? false;
  if (existedBefore === existsAfter) return; // edição sem criar/apagar: nada muda
  await db
    .collection('posts')
    .doc(event.params.postId)
    .update({ likeCount: FieldValue.increment(existsAfter ? 1 : -1) })
    .catch((error) => console.error('onLikeWritten: post sumiu?', event.params.postId, error));
});

export const onCommentCreated = onDocumentCreated(
  'posts/{postId}/comments/{commentId}',
  async (event) => {
    await db
      .collection('posts')
      .doc(event.params.postId)
      .update({ commentCount: FieldValue.increment(1) })
      .catch((error) =>
        console.error('onCommentCreated: post sumiu?', event.params.postId, error),
      );
  },
);
