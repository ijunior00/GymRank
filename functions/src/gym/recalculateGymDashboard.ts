import { onSchedule } from 'firebase-functions/v2/scheduler';
import { db, Timestamp } from '../admin';

const DAY_MS = 24 * 60 * 60 * 1000;

/** Recalcula `gyms/{gymId}/stats/current` para todas as academias. */
export const recalculateGymDashboard = onSchedule('every 1 hours', async () => {
  const gymsSnap = await db.collection('gyms').get();
  const now = Date.now();

  for (const gymDoc of gymsSnap.docs) {
    const gymId = gymDoc.id;

    const [studentsSnap, checkInsTodaySnap, checkInsWeekSnap] = await Promise.all([
      db.collection('users').where('gymId', '==', gymId).get(),
      gymDoc.ref
        .collection('checkins')
        .where('checkedInAt', '>=', Timestamp.fromMillis(now - DAY_MS))
        .get(),
      gymDoc.ref
        .collection('checkins')
        .where('checkedInAt', '>=', Timestamp.fromMillis(now - 7 * DAY_MS))
        .get(),
    ]);

    const totalStudents = studentsSnap.size;
    const newStudentsThisMonth = studentsSnap.docs.filter((d) => {
      const createdAt = (d.data().createdAt as Timestamp | undefined)?.toMillis() ?? 0;
      return now - createdAt <= 30 * DAY_MS;
    }).length;

    const activeUserIds = new Set(checkInsWeekSnap.docs.map((d) => d.data().userId));
    const inactiveStudents30d = studentsSnap.docs.filter((d) => {
      const lastCheckIn = (d.data().lastCheckInAt as Timestamp | undefined)?.toMillis() ?? 0;
      return now - lastCheckIn > 30 * DAY_MS;
    }).length;

    const retentionRate = totalStudents === 0 ? 0 : activeUserIds.size / totalStudents;

    await gymDoc.ref.collection('stats').doc('current').set({
      totalStudents,
      checkInsToday: checkInsTodaySnap.size,
      checkInsThisWeek: checkInsWeekSnap.size,
      newStudentsThisMonth,
      inactiveStudents30d,
      retentionRate,
      calculatedAt: Timestamp.now(),
    });
  }
});
