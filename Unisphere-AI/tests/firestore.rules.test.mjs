import { readFileSync } from 'node:fs';
import test, { before, after } from 'node:test';
import { initializeTestEnvironment, assertSucceeds, assertFails } from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc, getDoc, collection, query, where, getDocs } from 'firebase/firestore';

let env;
before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-unisphere',
    firestore: { rules: readFileSync('firestore.rules', 'utf8'), host: '127.0.0.1', port: 8081 },
  });
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users', 'alice'), {
      name: 'Alice', email: 'alice@example.edu', branch: 'BCA', year: 2,
      role: 'STUDENT', bio: '', suspended: false,
    });
    await setDoc(doc(db, 'users', 'bob'), {
      name: 'Bob', email: 'bob@example.edu', branch: 'BCA', year: 2,
      role: 'STUDENT', bio: '', suspended: false,
    });
    await setDoc(doc(db, 'events', 'published'), {title: 'Workshop', status: 'PUBLISHED'});
    await setDoc(doc(db, 'events', 'draft'), {title: 'Draft', status: 'DRAFT'});
    await setDoc(doc(db, 'notes', 'pending-bob'), {
      title: 'Draft note', subject: 'Math', uploaderUid: 'bob', status: 'PENDING',
    });
  });
});

test('note uploads require ownership and pending moderation', async () => {
  const db = env.authenticatedContext('alice', {email: 'alice@example.edu', email_verified: true}).firestore();
  const base = {
    title: 'Calculus', description: 'Limits', subject: 'Math', branch: 'BCA', year: 2,
    tags: ['calculus'], uploaderUid: 'alice', filePath: 'notes/alice/new-note',
    fileType: 'PDF', status: 'PENDING', downloadCount: 0, createdAt: new Date(),
  };
  await assertSucceeds(setDoc(doc(db, 'notes', 'new-note'), base));
  await assertFails(setDoc(doc(db, 'notes', 'fake-note'), {...base, uploaderUid: 'bob'}));
  await assertFails(getDoc(doc(db, 'notes', 'pending-bob')));
});
after(async () => { if (env) await env.cleanup(); });

test('student can edit permitted profile fields but cannot grant a role', async () => {
  const db = env.authenticatedContext('alice', {email: 'alice@example.edu', email_verified: true}).firestore();
  await assertSucceeds(updateDoc(doc(db, 'users', 'alice'), {bio: 'Learning Flutter'}));
  await assertFails(updateDoc(doc(db, 'users', 'alice'), {role: 'SUPER_ADMIN'}));
  await assertFails(updateDoc(doc(db, 'users', 'bob'), {name: 'Changed'}));
});

test('students can query published events only', async () => {
  const db = env.authenticatedContext('alice', {email: 'alice@example.edu', email_verified: true}).firestore();
  await assertSucceeds(getDoc(doc(db, 'events', 'published')));
  await assertFails(getDoc(doc(db, 'events', 'draft')));
  await assertSucceeds(getDocs(query(collection(db, 'events'), where('status', '==', 'PUBLISHED'))));
  await assertFails(getDocs(collection(db, 'events')));
});
