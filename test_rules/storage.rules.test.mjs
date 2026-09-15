// Regras do Storage contra o emulador: fotos de evolução e imagens de prêmio.
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { ref, uploadBytes, getBytes } from 'firebase/storage';
import { doc, setDoc } from 'firebase/firestore';
import { readFileSync } from 'node:fs';

const env = await initializeTestEnvironment({
  projectId: 'demo-gymrank',
  firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  storage: { rules: readFileSync(new URL('../storage.rules', import.meta.url), 'utf8') },
});
await env.clearFirestore();
await env.clearStorage();

await env.withSecurityRulesDisabled(async (ctx) => {
  const db = ctx.firestore();
  await setDoc(doc(db, 'users', 'coach-1'), { role: 'coach', coachId: 'c1' });
  await setDoc(doc(db, 'users', 'coach-2'), { role: 'coach', coachId: 'c2' });
  await setDoc(doc(db, 'users', 'alumna-1'), { role: 'alumno', coachId: 'c1' });
  await setDoc(doc(db, 'users', 'alumna-2'), { role: 'alumno', coachId: 'c1' });
  await setDoc(doc(db, 'rewards', 'r1'), { coachId: 'c1', name: 'Shaker' });
  const bytes = new Uint8Array([0xff, 0xd8, 0xff, 0xe0]); // "jpeg"
  await uploadBytes(ref(ctx.storage(), 'progress_photos/alumna-1/1.jpg'), bytes, { contentType: 'image/jpeg' });
});

const as = (uid) => env.authenticatedContext(uid).storage();
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
const img = new Uint8Array([0xff, 0xd8, 0xff, 0xe0]);

console.log('\n# fotos de evolução');
await check('a própria aluna baixa a foto', getBytes(ref(as('alumna-1'), 'progress_photos/alumna-1/1.jpg')), true);
await check('a coach da comunidade baixa a foto', getBytes(ref(as('coach-1'), 'progress_photos/alumna-1/1.jpg')), true);
await check('outra aluna NÃO baixa a foto', getBytes(ref(as('alumna-2'), 'progress_photos/alumna-1/1.jpg')), false);
await check('coach de outra comunidade NÃO baixa a foto', getBytes(ref(as('coach-2'), 'progress_photos/alumna-1/1.jpg')), false);
await check('a aluna sobe foto na própria pasta', uploadBytes(ref(as('alumna-1'), 'progress_photos/alumna-1/2.jpg'), img, { contentType: 'image/jpeg' }), true);
await check('a aluna NÃO sobe foto na pasta de outra', uploadBytes(ref(as('alumna-1'), 'progress_photos/alumna-2/x.jpg'), img, { contentType: 'image/jpeg' }), false);

console.log('\n# imagens de prêmio');
await check('a coach dona do prêmio sobe a imagem', uploadBytes(ref(as('coach-1'), 'reward_images/r1/a.jpg'), img, { contentType: 'image/jpeg' }), true);
await check('uma aluna NÃO sobe imagem de prêmio', uploadBytes(ref(as('alumna-1'), 'reward_images/r1/b.jpg'), img, { contentType: 'image/jpeg' }), false);
await check('coach de outra comunidade NÃO sobe', uploadBytes(ref(as('coach-2'), 'reward_images/r1/c.jpg'), img, { contentType: 'image/jpeg' }), false);
await check('prêmio inexistente NÃO aceita imagem', uploadBytes(ref(as('coach-1'), 'reward_images/nao-existe/c.jpg'), img, { contentType: 'image/jpeg' }), false);

await env.cleanup();
console.log(failures === 0 ? '\nTODOS OS CASOS PASSARAM' : `\n${failures} CASO(S) FALHARAM`);
process.exit(failures === 0 ? 0 : 1);
