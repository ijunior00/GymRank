// Testes das regras do Firestore contra o emulador (regras reais do repo).
// Cada caso é um buraco que existia ou uma porta que precisa continuar aberta.
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from '@firebase/rules-unit-testing';
import {
  collection, query, where, orderBy, getDocs, getDoc, setDoc, addDoc, updateDoc,
  deleteDoc, doc, Timestamp,
} from 'firebase/firestore';
import { readFileSync } from 'node:fs';

const env = await initializeTestEnvironment({
  projectId: 'demo-gymrank',
  firestore: {
    
    
    rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8'),
  },
});
await env.clearFirestore();

const now = Timestamp.now();
const daysAgo = (d) => Timestamp.fromMillis(Date.now() - d * 86400000);
const minutesAgo = (m) => Timestamp.fromMillis(Date.now() - m * 60000);

await env.withSecurityRulesDisabled(async (ctx) => {
  const db = ctx.firestore();
  const user = (id, extra) =>
    setDoc(doc(db, 'users', id), { name: id, username: id, role: 'alumno', ...extra });
  await user('coach-1', { role: 'coach', coachId: 'c1' });
  await user('nutri-1', { role: 'nutriologo', coachId: 'c1' });
  await user('coach-2', { role: 'coach', coachId: 'c2' });
  await user('coach-nova', { role: 'coach' }); // ainda sem comunidade
  await user('alumna-1', { coachId: 'c1' });
  await user('alumna-2', { coachId: 'c1' });
  await user('solta', {}); // sem treinadora
  await user('estranha', { coachId: 'c2' });

  await setDoc(doc(db, 'coaches', 'c1'), { ownerUserId: 'coach-1', name: 'AF', inviteCode: 'AF2026', plan: 'free' });
  await setDoc(doc(db, 'coaches/c1/private/qr'), { secret: 'super-secreto' });

  await setDoc(doc(db, 'workouts', 'w1'), { userId: 'alumna-1', date: now, durationMinutes: 45 });
  await setDoc(doc(db, 'workouts', 'w-solta'), { userId: 'solta', date: now, durationMinutes: 45 });
  await setDoc(doc(db, 'body_measurements', 'm1'), { userId: 'alumna-1', recordedAt: now, pesoKg: 60 });
  await setDoc(doc(db, 'progress_photos', 'p1'), { userId: 'alumna-1', takenAt: now, storageUrl: 'x' });
  await setDoc(doc(db, 'posts', 'post1'), { userId: 'alumna-2', authorName: 'a2', type: 'custom', text: 'hola', createdAt: now, likeCount: 0, commentCount: 0 });
  await setDoc(doc(db, 'rewards', 'r1'), { coachId: 'c1', name: 'Shaker', type: 'acessorio' });
});

const as = (uid) => env.authenticatedContext(uid).firestore();
let failures = 0;
async function check(label, promise, shouldPass) {
  try {
    if (shouldPass) await assertSucceeds(promise); else await assertFails(promise);
    console.log(`  ok   ${label}`);
  } catch (e) {
    failures++;
    console.log(`  FALHOU ${label}: ${e.message?.split('\n')[0]}`);
  }
}
const listOf = (db, col, userId, order) =>
  getDocs(query(collection(db, col), where('userId', '==', userId), orderBy(order)));

console.log('\n# dados pessoais: treinos, medidas, fotos');
for (const [col, order] of [['workouts', 'date'], ['body_measurements', 'recordedAt'], ['progress_photos', 'takenAt']]) {
  await check(`${col}: a própria aluna lista os seus`, listOf(as('alumna-1'), col, 'alumna-1', order), true);
  await check(`${col}: a coach da comunidade lista os da aluna`, listOf(as('coach-1'), col, 'alumna-1', order), true);
  await check(`${col}: a nutrióloga da comunidade lista os da aluna`, listOf(as('nutri-1'), col, 'alumna-1', order), true);
  await check(`${col}: outra aluna da MESMA comunidade NÃO lista`, listOf(as('alumna-2'), col, 'alumna-1', order), false);
  await check(`${col}: conta de outra comunidade NÃO lista`, listOf(as('estranha'), col, 'alumna-1', order), false);
  await check(`${col}: coach de outra comunidade NÃO lista`, listOf(as('coach-2'), col, 'alumna-1', order), false);
  await check(`${col}: lista sem filtro de userId NÃO passa`, getDocs(collection(as('alumna-1'), col)), false);
}
await check('workouts: coach sem comunidade NÃO lê a aluna solta (buraco do coachId nulo)', listOf(as('coach-nova'), 'workouts', 'solta', 'date'), false);
await check('workouts: leitura direta por id de outra aluna NÃO passa', getDoc(doc(as('alumna-2'), 'workouts', 'w1')), false);

console.log('\n# criação de treino (XP): datas e valores plausíveis');
const w = (extra) => addDoc(collection(as('alumna-1'), 'workouts'), { userId: 'alumna-1', date: now, durationMinutes: 45, muscleGroup: 'pernas', intensity: 'moderada', source: 'manual', note: null, createdAt: now, ...extra });
await check('treino de agora passa', w({}), true);
await check('treino de ontem passa', w({ date: daysAgo(1) }), true);
await check('treino de 30 dias atrás NÃO passa', w({ date: daysAgo(30) }), false);
await check('treino de 5000 minutos NÃO passa', w({ durationMinutes: 5000 }), false);
await check('treino com sessionId (carimbo do servidor) NÃO passa', w({ sessionId: 'falso' }), false);
await check('treino em nome de outra aluna NÃO passa', w({ userId: 'alumna-2' }), false);

console.log('\n# medidas e fotos');
await check('medida de agora passa', addDoc(collection(as('alumna-1'), 'body_measurements'), { userId: 'alumna-1', recordedAt: now, pesoKg: 62.5 }), true);
await check('medida com peso 900 kg NÃO passa', addDoc(collection(as('alumna-1'), 'body_measurements'), { userId: 'alumna-1', recordedAt: now, pesoKg: 900 }), false);
await check('medida de 60 dias atrás NÃO passa', addDoc(collection(as('alumna-1'), 'body_measurements'), { userId: 'alumna-1', recordedAt: daysAgo(60), pesoKg: 60 }), false);
const okUrl = 'https://firebasestorage.googleapis.com/v0/b/gymrank-e1c0d.firebasestorage.app/o/progress_photos%2Falumna-1%2F123.jpg?alt=media&token=abc';
await check('foto apontando para a pasta dela passa', addDoc(collection(as('alumna-1'), 'progress_photos'), { userId: 'alumna-1', storageUrl: okUrl, thumbnailUrl: okUrl, category: 'frente', takenAt: now }), true);
await check('foto apontando para a pasta de OUTRA NÃO passa', addDoc(collection(as('alumna-1'), 'progress_photos'), { userId: 'alumna-1', storageUrl: okUrl.replace('alumna-1', 'alumna-2'), thumbnailUrl: okUrl, category: 'frente', takenAt: now }), false);
await check('foto com URL de fora NÃO passa', addDoc(collection(as('alumna-1'), 'progress_photos'), { userId: 'alumna-1', storageUrl: 'https://evil.example/x.jpg', thumbnailUrl: okUrl, category: 'frente', takenAt: now }), false);

console.log('\n# segredo do QR e documento da coach');
await check('a própria coach NÃO lê private/qr', getDoc(doc(as('coach-1'), 'coaches/c1/private/qr')), false);
await check('uma aluna NÃO lê private/qr', getDoc(doc(as('alumna-1'), 'coaches/c1/private/qr')), false);
await check('a coach NÃO consegue gravar qrCodeSecret no doc público', updateDoc(doc(as('coach-1'), 'coaches', 'c1'), { qrCodeSecret: 'x' }), false);
await check('a coach NÃO muda o próprio plano', updateDoc(doc(as('coach-1'), 'coaches', 'c1'), { plan: 'premium' }), false);
await check('a coach edita o nome normalmente', updateDoc(doc(as('coach-1'), 'coaches', 'c1'), { name: 'Método AF' }), true);
await check('aluna lê o doc público da coach (código de convite)', getDoc(doc(as('alumna-1'), 'coaches', 'c1')), true);

console.log('\n# feed: tamanhos e contadores');
const comment = (text, uid = 'alumna-1') => addDoc(collection(as(uid), 'posts/post1/comments'), { postId: 'post1', userId: uid, authorName: uid, authorPhotoUrl: null, text, createdAt: now });
await check('comentário curto passa', comment('¡Vamos!'), true);
await check('comentário de 501 caracteres NÃO passa', comment('x'.repeat(501)), false);
await check('comentário vazio NÃO passa', comment(''), false);
await check('comentário em nome de outra NÃO passa', addDoc(collection(as('alumna-1'), 'posts/post1/comments'), { postId: 'post1', userId: 'alumna-2', authorName: 'a2', authorPhotoUrl: null, text: 'oi', createdAt: now }), false);
await check('curtir (doc likes/{uid}) passa', setDoc(doc(as('alumna-1'), 'posts/post1/likes/alumna-1'), { userId: 'alumna-1', createdAt: now }), true);
await check('cliente NÃO mexe no likeCount do post', updateDoc(doc(as('alumna-1'), 'posts', 'post1'), { likeCount: 999 }), false);
await check('dona do post edita o texto', updateDoc(doc(as('alumna-2'), 'posts', 'post1'), { text: 'editado' }), true);
await check('post de 1001 caracteres NÃO passa', addDoc(collection(as('alumna-1'), 'posts'), { userId: 'alumna-1', authorName: 'a1', type: 'custom', text: 'x'.repeat(1001), createdAt: now }), false);

console.log('\n# sessão de treino: carimbos de tempo');
const session = (id, extra) => setDoc(doc(as('alumna-1'), 'workout_sessions', id), { userId: 'alumna-1', coachId: 'c1', planId: 'p', status: 'enCurso', startedAt: now, exercises: [], createdAt: now, ...extra });
await check('iniciar sessão agora passa', session('s1', {}), true);
await check('iniciar sessão "há 1 hora" NÃO passa', session('s2', { startedAt: minutesAgo(60) }), false);
await check('concluir com finishedAt de agora passa', updateDoc(doc(as('alumna-1'), 'workout_sessions', 's1'), { status: 'completada', finishedAt: now, durationSec: 5 }), true);
await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'workout_sessions', 's3'), { userId: 'alumna-1', coachId: 'c1', status: 'enCurso', startedAt: now }));
await check('concluir com finishedAt no futuro distante NÃO passa', updateDoc(doc(as('alumna-1'), 'workout_sessions', 's3'), { status: 'completada', finishedAt: Timestamp.fromMillis(Date.now() + 3600000), durationSec: 5 }), false);


console.log('\n# perfil completo x cartão público');
await check('a própria pessoa lê o seu users/{uid}', getDoc(doc(as('alumna-1'), 'users', 'alumna-1')), true);
await check('a coach da comunidade lê o perfil da aluna', getDoc(doc(as('coach-1'), 'users', 'alumna-1')), true);
await check('a nutrióloga da comunidade lê o perfil da aluna', getDoc(doc(as('nutri-1'), 'users', 'alumna-1')), true);
await check('outra aluna NÃO lê o perfil completo', getDoc(doc(as('alumna-2'), 'users', 'alumna-1')), false);
await check('coach de outra comunidade NÃO lê o perfil', getDoc(doc(as('coach-2'), 'users', 'alumna-1')), false);
await check('coach lista as alunas da comunidade (filtro coachId)', getDocs(query(collection(as('coach-1'), 'users'), where('coachId', '==', 'c1'), where('role', '==', 'alumno'))), true);
await check('aluna NÃO lista users', getDocs(query(collection(as('alumna-1'), 'users'), where('coachId', '==', 'c1'))), false);
await check('busca por @ em users NÃO passa para aluna', getDocs(query(collection(as('alumna-1'), 'users'), where('usernameLowercase', '==', 'alumna-2'))), false);
await env.withSecurityRulesDisabled((ctx) => setDoc(doc(ctx.firestore(), 'public_profiles', 'alumna-2'), { name: 'A2', username: 'alumna-2', usernameLowercase: 'alumna-2', level: 3 }));
await check('qualquer conta lê o cartão público', getDoc(doc(as('alumna-1'), 'public_profiles', 'alumna-2')), true);
await check('busca por @ no cartão público passa', getDocs(query(collection(as('alumna-1'), 'public_profiles'), where('usernameLowercase', '==', 'alumna-2'))), true);
await check('ninguém escreve no cartão público', setDoc(doc(as('alumna-2'), 'public_profiles', 'alumna-2'), { name: 'hack' }), false);
await check('aluna NÃO escreve no xp_ledger', setDoc(doc(as('alumna-1'), 'users/alumna-1/xp_ledger/workout:2026-01-01'), { count: 0 }), false);
await check('aluna NÃO muda o próprio xpTotal', updateDoc(doc(as('alumna-1'), 'users', 'alumna-1'), { xpTotal: 99999 }), false);
await check('aluna edita a própria cidade', updateDoc(doc(as('alumna-1'), 'users', 'alumna-1'), { city: 'CDMX' }), true);

console.log('\n# o que já funcionava continua funcionando');
await check('aluna lista os próprios planos', getDocs(query(collection(as('alumna-1'), 'plans'), where('userId', '==', 'alumna-1'), orderBy('publishedAt', 'desc'))), true);
await check('coach lista planos da aluna (com coachId)', getDocs(query(collection(as('coach-1'), 'plans'), where('coachId', '==', 'c1'), where('userId', '==', 'alumna-1'), orderBy('publishedAt', 'desc'))), true);
await check('aluna lê ranking', getDocs(collection(as('alumna-1'), 'rankings/r1/entries')), true);
await check('aluna lê retos ativos', getDocs(query(collection(as('alumna-1'), 'challenges'), where('isActive', '==', true))), true);
await check('aluna NÃO apaga treino de outra', deleteDoc(doc(as('alumna-2'), 'workouts', 'w1')), false);

await env.cleanup();
console.log(failures === 0 ? '\nTODOS OS CASOS PASSARAM' : `\n${failures} CASO(S) FALHARAM`);
process.exit(failures === 0 ? 0 : 1);
