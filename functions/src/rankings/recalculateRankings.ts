import { onSchedule } from 'firebase-functions/v2/scheduler';
import { db, Timestamp } from '../admin';

interface RankableUser {
  id: string;
  name: string;
  photoUrl: string | null;
  gymId: string | null;
  city: string | null;
  value: number;
}

const CRITERIA_FIELD: Record<string, string> = {
  xp: 'xpCurrentSeason',
  gymScore: 'gymScore',
};

/**
 * Materializa `rankings/{scope}_{criteria}_{scopeId}/entries` para leitura
 * direta e barata pelo cliente. Rodar via scheduler (aqui a cada hora)
 * evita agregações custosas em tempo real quando a base crescer para
 * milhões de usuários.
 */
export const recalculateRankings = onSchedule('every 1 hours', async () => {
  const usersSnap = await db.collection('users').get();
  const users: RankableUser[] = usersSnap.docs.map((doc) => {
    const data = doc.data();
    return {
      id: doc.id,
      name: data.name as string,
      photoUrl: (data.photoUrl as string | null) ?? null,
      gymId: (data.gymId as string | null) ?? null,
      city: (data.city as string | null) ?? null,
      value: 0,
    };
  });

  for (const criteria of ['xp', 'gymScore']) {
    const field = CRITERIA_FIELD[criteria];

    await writeRanking('nacional', 'global', criteria, rankBy(usersSnap, field));

    const byGym = groupBy(users, (u) => u.gymId);
    for (const [gymId, group] of byGym) {
      if (!gymId) continue;
      await writeRanking('academia', gymId, criteria, rankGroup(group, usersSnap, field));
    }

    const byCity = groupBy(users, (u) => u.city);
    for (const [city, group] of byCity) {
      if (!city) continue;
      await writeRanking('cidade', city, criteria, rankGroup(group, usersSnap, field));
    }
  }
});

function rankBy(
  usersSnap: FirebaseFirestore.QuerySnapshot,
  field: string,
): { id: string; name: string; photoUrl: string | null; value: number }[] {
  return usersSnap.docs
    .map((doc) => ({
      id: doc.id,
      name: doc.data().name as string,
      photoUrl: (doc.data().photoUrl as string | null) ?? null,
      value: (doc.data()[field] as number) ?? 0,
    }))
    .sort((a, b) => b.value - a.value);
}

function rankGroup(
  group: RankableUser[],
  usersSnap: FirebaseFirestore.QuerySnapshot,
  field: string,
): { id: string; name: string; photoUrl: string | null; value: number }[] {
  const valueById = new Map(usersSnap.docs.map((d) => [d.id, (d.data()[field] as number) ?? 0]));
  return group
    .map((u) => ({ id: u.id, name: u.name, photoUrl: u.photoUrl, value: valueById.get(u.id) ?? 0 }))
    .sort((a, b) => b.value - a.value);
}

function groupBy<T, K>(items: T[], keyFn: (item: T) => K | null): Map<K, T[]> {
  const map = new Map<K, T[]>();
  for (const item of items) {
    const key = keyFn(item);
    if (key === null) continue;
    if (!map.has(key)) map.set(key, []);
    map.get(key)!.push(item);
  }
  return map;
}

async function writeRanking(
  scope: string,
  scopeId: string,
  criteria: string,
  ranked: { id: string; name: string; photoUrl: string | null; value: number }[],
): Promise<void> {
  const docId = `${scope}_${criteria}_${scopeId}`;
  const entriesRef = db.collection('rankings').doc(docId).collection('entries');

  const batch = db.batch();
  ranked.slice(0, 500).forEach((entry, index) => {
    batch.set(entriesRef.doc(entry.id), {
      userId: entry.id,
      userName: entry.name,
      userPhotoUrl: entry.photoUrl,
      position: index + 1,
      value: entry.value,
      calculatedAt: Timestamp.now(),
    });
  });
  await batch.commit();
}
