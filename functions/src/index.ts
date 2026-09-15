import { setGlobalOptions } from 'firebase-functions/v2';

import { FUNCTIONS_REGION } from './constants';

// Região de TODAS as functions. Precisa ser a mesma do
// `firebaseFunctionsProvider` em lib/core/di/firebase_providers.dart, senão
// as chamadas do app (hoje `validateCheckIn`) batem em outra região e
// voltam NOT_FOUND. us-central1 é a região padrão do Firebase e a de menor
// latência para o México entre as que têm todos os recursos.
// maxInstances é o teto de custo: por padrão cada function escala até 100
// cópias em paralelo; 10 é muito para o tamanho da comunidade hoje e
// segura a conta se alguém tentar inundar o backend. Suba quando as
// filas (logs "instance limit") aparecerem de verdade.
setGlobalOptions({ region: FUNCTIONS_REGION, maxInstances: 10 });

export { validateCheckIn } from './checkin/validateCheckIn';
export { issueCheckInToken } from './checkin/issueCheckInToken';
export { issueLocationQr } from './checkin/locationQr';
export { onLikeWritten, onCommentCreated } from './social/counters';
export { onUserWritten } from './profiles/publicProfile';
export { onParticipantCreated, onChallengeWritten } from './challenges/challengeCounters';

export {
  onWorkoutCreated,
  onBodyMeasurementCreated,
  onProgressPhotoCreated,
  onFriendshipUpdated,
} from './gamification/onContentCreated';

export { recalculateGymScore } from './gamification/recalculateGymScore';
export { seasonReset } from './seasons/seasonReset';
export { recalculateCoachDashboard } from './coach/recalculateCoachDashboard';
export { onClientCreated } from './coach/onClientCreated';
export { recalculateRankings } from './rankings/recalculateRankings';
export { parseDocument } from './plans/parseDocument';
export { onPlanPublished } from './plans/onPlanPublished';
export { onWorkoutSessionCompleted } from './training/onWorkoutSessionCompleted';
