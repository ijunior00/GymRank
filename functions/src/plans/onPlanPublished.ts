import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { dispatchNotification } from '../notifications/dispatchNotification';

const KIND_TITLES: Record<string, string> = {
  entrenamiento: 'Tu nuevo plan de entrenamiento ya está listo 🔥',
  dieta: 'Tu nuevo plan de alimentación ya está listo 🥗',
  macros: 'Tus nuevas metas de macros ya están listas',
  evaluacion: 'Tu evaluación física ya está en el app',
  otro: 'Tu coach publicó un nuevo documento',
};

/**
 * Avisa o aluno sempre que a treinadora publica (ou republica) um plano:
 * `plans/{planId}` criado ou `currentVersion` incrementada.
 */
export const onPlanPublished = onDocumentWritten('plans/{planId}', async (event) => {
  const after = event.data?.after?.data();
  if (!after) return;
  const before = event.data?.before?.data();
  if (before && before.currentVersion === after.currentVersion) return;

  const kind = (after.kind as string) ?? 'otro';
  await dispatchNotification({
    userId: after.userId as string,
    type: 'planPublished',
    title: KIND_TITLES[kind] ?? KIND_TITLES.otro,
    body: (after.title as string) ?? 'Ábrelo en Mis planes.',
    deepLink: `/plans/${event.params.planId}`,
  });
});
