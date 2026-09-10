import { onSchedule } from 'firebase-functions/v2/scheduler';
import { db, Timestamp } from '../admin';

const DAY_MS = 24 * 60 * 60 * 1000;

interface WeekWorkout {
  userId: string;
  dateMs: number;
}

/**
 * Recalcula `coaches/{coachId}/stats/current` para todas as treinadoras.
 * A atividade considerada é o treino registrado (`workouts`) — para
 * alunos online não existe check-in por QR — mais o check-in presencial
 * quando houver (`users.lastCheckInAt`).
 */
export const recalculateCoachDashboard = onSchedule('every 1 hours', async () => {
  const now = Date.now();

  // Uma única leitura dos treinos da semana para todas as comunidades.
  const weekWorkoutsSnap = await db
    .collection('workouts')
    .where('date', '>=', Timestamp.fromMillis(now - 7 * DAY_MS))
    .get();
  const weekWorkouts: WeekWorkout[] = weekWorkoutsSnap.docs.map((d) => ({
    userId: d.data().userId as string,
    dateMs: (d.data().date as Timestamp).toMillis(),
  }));

  const coachesSnap = await db.collection('coaches').get();

  for (const coachDoc of coachesSnap.docs) {
    const coachId = coachDoc.id;

    const [studentsSnap, clientsSnap] = await Promise.all([
      db.collection('users').where('coachId', '==', coachId).where('role', '==', 'alumno').get(),
      coachDoc.ref.collection('clients').get(),
    ]);

    const statusById = new Map(
      clientsSnap.docs.map((d) => [d.id, (d.data().status as string | undefined) ?? 'activo']),
    );
    const activeStudentDocs = studentsSnap.docs.filter(
      (d) => (statusById.get(d.id) ?? 'activo') === 'activo',
    );
    const studentIds = new Set(studentsSnap.docs.map((d) => d.id));

    const communityWeek = weekWorkouts.filter((w) => studentIds.has(w.userId));
    const workoutsToday = communityWeek.filter((w) => w.dateMs >= now - DAY_MS).length;

    const activeThisWeek = new Set(communityWeek.map((w) => w.userId));
    for (const d of studentsSnap.docs) {
      const lastCheckIn = (d.data().lastCheckInAt as Timestamp | undefined)?.toMillis() ?? 0;
      if (now - lastCheckIn <= 7 * DAY_MS) activeThisWeek.add(d.id);
    }

    const newStudentsThisMonth = clientsSnap.docs.filter((d) => {
      const createdAt = (d.data().createdAt as Timestamp | undefined)?.toMillis() ?? 0;
      return now - createdAt <= 30 * DAY_MS;
    }).length;

    const inactiveStudents7d = activeStudentDocs.filter((d) => !activeThisWeek.has(d.id)).length;

    const activeStudents = activeStudentDocs.length;
    const retentionRate =
      activeStudents === 0
        ? 0
        : activeStudentDocs.filter((d) => activeThisWeek.has(d.id)).length / activeStudents;

    await Promise.all([
      coachDoc.ref.collection('stats').doc('current').set({
        totalStudents: studentsSnap.size,
        activeStudents,
        workoutsToday,
        workoutsThisWeek: communityWeek.length,
        newStudentsThisMonth,
        inactiveStudents7d,
        retentionRate,
        calculatedAt: Timestamp.now(),
      }),
      coachDoc.ref.update({ studentCount: studentsSnap.size }),
    ]);
  }
});
