// Seeds Firestore and Firebase Auth with the MT Alchemy demo data.
// Normally run through `npm run seed`, which opens bootstrap rules first and
// redeploys the real firestore.rules afterwards. Safe to run repeatedly:
// every document has a fixed id and accounts are reused if they exist.
import { readFileSync } from 'node:fs';

// No npm packages: Firebase Auth and Firestore are called over REST, so the
// script runs on any machine with Node 18+.
const options = readFileSync(new URL('../../lib/firebase_options.dart', import.meta.url), 'utf8');
const webBlock = options.slice(options.indexOf('FirebaseOptions web'));
const pick = (key) => webBlock.match(new RegExp(`${key}: '([^']+)'`))[1];
const apiKey = pick('apiKey');
const projectId = pick('projectId');
const seed = JSON.parse(readFileSync(new URL('./seed.json', import.meta.url), 'utf8'));

const TS = Symbol('timestamp');
const ts = (date) => ({ [TS]: date });
const serverTimestamp = () => ts(new Date());
const daysAgo = (n) => ts(new Date(Date.now() - n * 86400000));

async function post(url, body, token) {
  const res = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: JSON.stringify(body),
  });
  const json = await res.json();
  if (!res.ok) {
    const err = new Error(json.error?.message ?? res.statusText);
    err.code = json.error?.message;
    throw err;
  }
  return json;
}

const identity = (method, body) =>
  post(`https://identitytoolkit.googleapis.com/v1/accounts:${method}?key=${apiKey}`, { ...body, returnSecureToken: true });

async function account(email, password) {
  try {
    return await identity('signUp', { email, password });
  } catch (e) {
    if (!String(e.code).startsWith('EMAIL_EXISTS')) throw e;
    return identity('signInWithPassword', { email, password });
  }
}

function encode(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (v[TS]) return { timestampValue: v[TS].toISOString() };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'string') return { stringValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(encode) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, encode(x)])) } };
}

const docName = (path) => `projects/${projectId}/databases/(default)/documents/${path.join('/')}`;

async function commit(writes, token) {
  for (let i = 0; i < writes.length; i += 400) {
    await post(
      `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents:commit`,
      { writes: writes.slice(i, i + 400) },
      token,
    );
  }
}

async function main() {
  const uids = {};
  const profileWrites = [];
  // Employees of the demo organisation get learner accounts too, so the
  // employer dashboard shows real progress.
  const employeeUsers = Object.values(seed.employees)
    .filter((e) => !seed.users.some((u) => u.email === e.email))
    .map((e) => ({ key: e.email, name: e.name, email: e.email, role: 'individual', orgId: seed.organization.id }));

  for (const u of [...seed.users, ...employeeUsers]) {
    const user = await account(u.email, seed.password);
    uids[u.email] = user.localId;
    const { key, ...profile } = u;
    profileWrites.push({ update: { name: docName(['users', user.localId]), fields: encode({ hobbies: [], disabled: false, ...profile, createdAt: serverTimestamp() }).mapValue.fields } });
    console.log(`  account  ${u.role.padEnd(11)} ${u.email}`);
  }

  // Any signed-in account may write while the bootstrap rules are live.
  const { idToken } = await identity('signInWithPassword', { email: 'admin@mtalchemy.example.com', password: seed.password });
  const writes = [...profileWrites];
  const put = (path, data) => writes.push({ update: { name: docName(path), fields: encode(data).mapValue.fields } });

  for (const [id, c] of Object.entries(seed.courses)) put(['courses', id], { ...c, createdAt: serverTimestamp() });
  for (const [id, p] of Object.entries(seed.products)) put(['products', id], p);
  for (const [id, c] of Object.entries(seed.productCategories)) put(['productCategories', id], c);
  for (const [id, a] of Object.entries(seed.articles)) put(['articles', id], a);
  for (const [id, f] of Object.entries(seed.founders)) put(['founders', id], f);
  for (const [id, s] of Object.entries(seed.impactStories)) put(['impactStories', id], { ...s, createdAt: serverTimestamp() });

  const { id: orgId, ...org } = seed.organization;
  put(['organizations', orgId], { ...org, ownerId: uids['priya@northlight.example.com'], createdAt: serverTimestamp() });
  for (const [id, e] of Object.entries(seed.employees)) put(['employees', id], e);

  // Employer assignments and the learning progress behind them.
  const plan = [
    ['e-1', 'callum@northlight.example.com', 'first-time-manager', 3, 24],
    ['e-2', 'fatima@northlight.example.com', 'first-time-manager', 1, 24],
    ['e-3', 'owen@northlight.example.com', 'sustainable-performance', 4, 19],
    ['e-4', 'leah@northlight.example.com', 'ei-foundations', 0, 10],
    ['e-1', 'callum@northlight.example.com', 'ei-foundations', 99, 6],
    ['e-3', 'owen@northlight.example.com', 'team-trust-reset', 2, 4],
  ];
  for (const [employeeId, email, courseId, done, ago] of plan) {
    const assignmentId = `${orgId}_${employeeId}_${courseId}`;
    put(['assignments', assignmentId], { orgId, employeeId, employeeEmail: email, courseId, assignedAt: daysAgo(ago) });
    if (done === 0) continue;
    const modules = seed.courses[courseId].modules;
    const completed = modules.slice(0, Math.min(done, modules.length)).map((m) => m.id);
    const complete = completed.length === modules.length;
    const quizIds = modules.filter((m) => m.type === 'quiz').map((m) => m.id);
    const scores = Object.fromEntries(quizIds.filter((q) => completed.includes(q)).map((q) => [q, 1]));
    const attempts = Object.fromEntries(Object.keys(scores).map((q) => [q, 1]));
    const uid = uids[email];
    put(['enrolments', `${uid}_${courseId}`], {
      userId: uid, userName: Object.values(seed.employees).find((e) => e.email === email)?.name ?? email, userEmail: email, courseId, orgId, assignmentId, source: 'assignment',
      completedModuleIds: completed, quizScores: scores, quizAttempts: attempts,
      progress: completed.length / modules.length, status: complete ? 'complete' : 'active',
      enrolledAt: daysAgo(ago), updatedAt: daysAgo(Math.max(0, ago - done * 2)),
    });
    if (complete) {
      const code = `MTA-${courseId.slice(0, 3).toUpperCase()}-${uid.slice(0, 6).toUpperCase()}`;
      put(['certificates', code], { userId: uid, userName: Object.values(seed.employees).find((e) => e.email === email)?.name ?? email, courseId, courseTitle: seed.courses[courseId].title, issuedAt: daysAgo(1),
        review: `${(Object.values(seed.employees).find((e) => e.email === email)?.name ?? email).split(' ')[0]}, you worked through all ${modules.length} lessons of ${seed.courses[courseId].title} across 3 phases in ${ago} days. Finishing within two weeks is a steady rhythm: long enough to try ideas at work between lessons, short enough to keep momentum. You passed every quiz on the first attempt, with an average of 100%, so the core ideas were clear from the start.` });
    }
  }

  // Amara: a paid individual course with two lessons done.
  const amara = uids['amara@example.com'];
  put(['orders', 'MTA-10001'], {
    userId: amara, email: 'amara@example.com', kind: 'course', status: 'paid',
    items: [{ id: 'ei-foundations', name: seed.courses['ei-foundations'].title, kind: 'course', price: 149, quantity: 1 }],
    subtotal: 149, shipping: 0, total: 149, createdAt: daysAgo(12),
  });
  put(['payments', 'pay-MTA-10001'], { userId: amara, orderId: 'MTA-10001', amount: 149, method: 'card', last4: '4242', status: 'paid', createdAt: daysAgo(12) });
  put(['enrolments', `${amara}_ei-foundations`], {
    userId: amara, userName: 'Amara Osei', userEmail: 'amara@example.com', courseId: 'ei-foundations', orderId: 'MTA-10001',
    source: 'purchase', amountPaid: 149,
    completedModuleIds: seed.courses['ei-foundations'].modules.slice(0, 3).map((m) => m.id),
    quizScores: { 'ei-foundations-q1': 0.75 }, quizAttempts: { 'ei-foundations-q1': 2 },
    progress: 3 / seed.courses['ei-foundations'].modules.length, status: 'active',
    enrolledAt: daysAgo(12), updatedAt: daysAgo(2),
  });
  // A physical order already on its way, and a digital download.
  put(['orders', 'MTA-10002'], {
    userId: amara, email: 'amara@example.com', kind: 'store', status: 'paid',
    items: [
      { id: 'feedback-conversation-cards', name: 'Feedback Conversation Cards', kind: 'physical', price: 24, quantity: 1 },
      { id: 'ei-self-coaching-toolkit', name: 'EI Self-Coaching Toolkit', kind: 'digital', price: 39, quantity: 1 },
    ],
    subtotal: 63, shipping: 0, total: 63, createdAt: daysAgo(5),
  });
  put(['payments', 'pay-MTA-10002'], { userId: amara, orderId: 'MTA-10002', amount: 63, method: 'card', last4: '4242', status: 'paid', createdAt: daysAgo(5) });
  put(['shipping', 'MTA-10002'], {
    userId: amara, orderId: 'MTA-10002', status: 'shipped', tracking: 'MY4207155820',
    address: { name: 'Amara Osei', line1: '12 Jalan Ampang', city: 'Kuala Lumpur', postcode: '50450', country: 'Malaysia' },
    history: [{ status: 'processing', at: daysAgo(5) }, { status: 'shipped', at: daysAgo(3) }],
  });
  put(['downloads', `${amara}_ei-self-coaching-toolkit`], {
    userId: amara, productId: 'ei-self-coaching-toolkit', name: 'EI Self-Coaching Toolkit', orderId: 'MTA-10002',
    url: seed.products['ei-self-coaching-toolkit'].fileUrl, downloadCount: 1, createdAt: daysAgo(5),
  });

  put(['reviews', 'rev-1'], { targetId: 'ei-foundations', userId: uids['callum@northlight.example.com'], userName: 'Callum R.', rating: 5, comment: 'The ninety second pause has genuinely changed how I handle tense calls.', createdAt: daysAgo(3) });
  put(['reviews', 'rev-2'], { targetId: 'feedback-conversation-cards', userId: amara, userName: 'Amara O.', rating: 5, comment: 'We use one card at the start of every one-to-one.', createdAt: daysAgo(2) });
  put(['reviews', 'rev-3'], { targetId: 'first-time-manager', userId: uids['fatima@northlight.example.com'], userName: 'Fatima B.', rating: 4, comment: 'Practical and kind. The delegation module was the most useful.', createdAt: daysAgo(8) });

  put(['enquiries', 'enq-1'], {
    organisation: 'Harbour Health Trust', name: 'Grace Tan', email: 'grace@harbourhealth.example.com',
    size: '500 to 1000 employees', interest: 'Leadership Development', status: 'in-discussion',
    message: 'We are restructuring our ward management and want a six-month programme for 40 new team leads.',
    proposal: 'Draft: 3 cohorts of 14, blended (2 workshops + LMS), pulse survey at months 0, 3, 6.',
    createdAt: daysAgo(4),
  });

  put(['notifications', 'n-1'], { userId: amara, title: 'Your order MTA-10002 has shipped', body: 'Tracking MY4207155820', link: '/portal/me/orders', read: false, createdAt: daysAgo(3) });
  put(['notifications', 'n-2'], { userId: uids['callum@northlight.example.com'], title: 'New course assigned', body: 'Priya assigned you Emotional Intelligence Foundations', link: '/portal/me', read: false, createdAt: daysAgo(6) });

  await commit(writes, idToken);
  console.log(`Seed complete: ${writes.length} documents.`);
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
