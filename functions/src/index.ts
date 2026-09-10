import { setGlobalOptions } from 'firebase-functions/v2';

import { FUNCTIONS_REGION } from './constants';

// Região de TODAS as functions. Precisa ser a mesma do
// `firebaseFunctionsProvider` em lib/core/di/firebase_providers.dart, senão
// as chamadas do app (hoje `validateCheckIn`) batem em outra região e
// voltam NOT_FOUND. us-central1 é a região padrão do Firebase e a de menor
// latência para o México entre as que têm todos os recursos.
setGlobalOptions({ region: FUNCTIONS_REGION });

export { validateCheckIn } from './checkin/validateCheckIn';

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
