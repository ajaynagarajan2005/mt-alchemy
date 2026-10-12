// End-to-end check of the live Firebase project against the deployed
// security rules. Signs in as each demo role over REST, performs the same
// reads and writes the app makes for Journeys A to E, and confirms that
// forbidden writes are refused. Run: npm run verify
import { readFileSync } from 'node:fs';

const options = readFileSync(new URL('../../lib/firebase_options.dart', import.meta.url), 'utf8');
const webBlock = options.slice(options.indexOf('FirebaseOptions web'));
const pick = (key) => webBlock.match(new RegExp(`${key}: '([^']+)'`))[1];
const apiKey = pick('apiKey');
const projectId = pick('projectId');
const password = JSON.parse(readFileSync(new URL('./seed.json', import.meta.url), 'utf8')).password;
const base = `https://firestore.googleapis.com/v1/projects/${projectId}/databases/(default)/documents`;

let passed = 0;
let failed = 0;
const check = (name, ok, detail = '') => {
  ok ? passed++ : failed++;
  console.log(`${ok ? '  PASS' : '  FAIL'}  ${name}${ok || !detail ? '' : `  (${detail})`}`);
};

async function signIn(email) {
  const res = await fetch(`https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, returnSecureToken: true }),
  });
  const json = await res.json();
  if (!res.ok) throw new Error(`${email}: ${json.error?.message}`);
  return { token: json.idToken, uid: json.localId };
}

const enc = (v) => {
  if (v === null) return { nullValue: null };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'string') return { stringValue: v };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(enc) } };
  return { mapValue: { fields: Object.fromEntries(Object.entries(v).map(([k, x]) => [k, enc(x)])) } };
};

async function call(method, path, token, body) {
  const res = await fetch(`${base}/${path}`, {
    method,
    headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  const json = await res.json().catch(() => ({}));
  // Anything other than allowed (200) or refused by the rules (403) is a
  // network or quota problem, not a rules result: say so.
  if (res.status !== 200 && res.status !== 403) {
    console.log(`    ! ${method} ${path.slice(0, 50)} -> HTTP ${res.status} ${json.error?.status ?? ''}`);
  }
  return { status: res.status, json };
}
const get = (path, token) => call('GET', path, token);
const set = (path, token, data) => call('PATCH', path, token, { fields: enc(data).mapValue.fields });
const del = (path, token) => call('DELETE', path, token);
const query = (token, collection, field, value) =>
  call('POST', ':runQuery', token, {
    structuredQuery: {
      from: [{ collectionId: collection }],
      where: { fieldFilter: { field: { fieldPath: field }, op: 'EQUAL', value: enc(value) } },
    },
  }).then((r) => ({ status: r.status, docs: Array.isArray(r.json) ? r.json.filter((x) => x.document) : [] }));

const stamp = Date.now();

async function main() {
  console.log('\nGuest (signed out)');
  check('reads published courses', (await query(null, 'courses', 'published', true)).docs.length >= 6);
  check('reads products', (await get('products', null)).status === 200);
  check('cannot read users', (await get('users', null)).status === 403);
  check('can send a corporate enquiry (Journey E)', (await set(`enquiries/verify-${stamp}`, null, {
    organisation: 'Verify Ltd', name: 'Script', email: 'v@example.com', size: '1 to 49',
    interest: 'Leadership Development', message: 'Automated check', status: 'new', proposal: '', createdAt: new Date(),
  })).status === 200);
  check('cannot create a course', (await set(`courses/hack-${stamp}`, null, { title: 'x', published: true })).status === 403);

  console.log('\nIndividual (Amara) - Journeys A, B, C');
  const amara = await signIn('amara@example.com');
  check('reads own profile', (await get(`users/${amara.uid}`, amara.token)).status === 200);
  check('cannot promote self to superAdmin', (await call('PATCH', `users/${amara.uid}?updateMask.fieldPaths=role`, amara.token, { fields: { role: enc('superAdmin') } })).status === 403);
  const order = `MTA-V${stamp}`;
  check('places a paid order', (await set(`orders/${order}`, amara.token, {
    userId: amara.uid, email: 'amara@example.com', status: 'paid',
    items: [{ id: 'team-trust-reset', name: 'Team Trust Reset', kind: 'course', price: 199, quantity: 1 }],
    subtotal: 199, shipping: 0, total: 199, createdAt: new Date(),
  })).status === 200);
  check('records the payment', (await set(`payments/pay-${order}`, amara.token, { userId: amara.uid, orderId: order, amount: 199, status: 'paid' })).status === 200);
  check('enrols from the order', (await set(`enrolments/${amara.uid}_team-trust-reset`, amara.token, {
    userId: amara.uid, userEmail: 'amara@example.com', courseId: 'team-trust-reset', orderId: order,
    completedModuleIds: [], quizScores: {}, progress: 0, status: 'active', enrolledAt: new Date(),
  })).status === 200);
  check('cannot enrol without an order', (await set(`enrolments/${amara.uid}_leading-through-change`, amara.token, {
    userId: amara.uid, courseId: 'leading-through-change', orderId: 'not-mine',
  })).status === 403);
  check('cannot issue a certificate for an unfinished course', (await set(`certificates/FAKE-${stamp}`, amara.token, {
    userId: amara.uid, courseId: 'team-trust-reset', userName: 'Amara', courseTitle: 'x', issuedAt: new Date(),
  })).status === 403);
  check('sees own digital download', (await query(amara.token, 'downloads', 'userId', amara.uid)).docs.length >= 1);
  check('sees own shipment', (await query(amara.token, 'shipping', 'userId', amara.uid)).docs.length >= 1);
  check('cannot mark own parcel delivered', (await call('PATCH', `shipping/MTA-10002?updateMask.fieldPaths=status`, amara.token, { fields: { status: enc('delivered') } })).status === 403);
  check('cannot read other users\' orders', (await get('orders/MTA-10001', (await signIn('callum@northlight.example.com')).token)).status === 403);

  console.log('\nEmployer (Priya) - Journey D');
  const priya = await signIn('priya@northlight.example.com');
  check('reads own organisation', (await get('organizations/org-northlight', priya.token)).status === 200);
  check('lists employees', (await query(priya.token, 'employees', 'orgId', 'org-northlight')).docs.length >= 4);
  check('reads team progress', (await query(priya.token, 'enrolments', 'orgId', 'org-northlight')).docs.length >= 3);
  const emp = `verify-${stamp}`;
  check('adds an employee', (await set(`employees/${emp}`, priya.token, { orgId: 'org-northlight', name: 'Verify Person', email: `v${stamp}@northlight.example.com`, team: 'QA' })).status === 200);
  check('assigns a course', (await set(`assignments/org-northlight_${emp}_team-trust-reset`, priya.token, {
    orgId: 'org-northlight', employeeId: emp, employeeEmail: `v${stamp}@northlight.example.com`, courseId: 'team-trust-reset', assignedAt: new Date(),
  })).status === 200);
  check('cannot add employees to another org', (await set(`employees/x-${stamp}`, priya.token, { orgId: 'other-org', name: 'x', email: 'x@x.com', team: 'x' })).status === 403);
  check('cannot read the user list', (await get('users', priya.token)).status === 403);
  await del(`assignments/org-northlight_${emp}_team-trust-reset`, priya.token);
  await del(`employees/${emp}`, priya.token);

  console.log('\nTrainer (Maya) - course CRUD');
  const maya = await signIn('maya@mtalchemy.example.com');
  const draft = `verify-course-${stamp}`;
  check('creates a draft course', (await set(`courses/${draft}`, maya.token, { title: 'Verify course', published: false, price: 1, modules: [] })).status === 200);
  check('guest cannot see the draft', (await get(`courses/${draft}`, null)).status === 403);
  check('deletes the course', (await del(`courses/${draft}`, maya.token)).status === 200);
  check('cannot edit products', (await set('products/verify', maya.token, { name: 'x' })).status === 403);
  const grantId = `${amara.uid}_leading-through-change`;
  const granted = { userId: amara.uid, userName: 'Amara Osei', userEmail: 'amara@example.com', courseId: 'leading-through-change', source: 'granted', grantedBy: maya.uid, completedModuleIds: [], quizScores: {}, progress: 0, status: 'active', enrolledAt: new Date() };
  check('learner cannot give themselves free access', (await set(`enrolments/${grantId}`, amara.token, granted)).status === 403);
  check('trainer grants free access (no payment)', (await set(`enrolments/${grantId}`, maya.token, granted)).status === 200);
  check('learner then sees the course as enrolled', (await get(`enrolments/${grantId}`, amara.token)).status === 200);
  check('trainer lists the students on a course', (await query(maya.token, 'enrolments', 'courseId', 'ei-foundations')).docs.length >= 1);
  check('learner cannot remove their own enrolment', (await del(`enrolments/${grantId}`, amara.token)).status === 403);
  check('trainer removes the access', (await del(`enrolments/${grantId}`, maya.token)).status === 200);

  console.log('\nSuper admin (Daniel) - users, products, shipping, enquiries');
  const admin = await signIn('admin@mtalchemy.example.com');
  check('lists all users', (await get('users', admin.token)).status === 200);
  check('creates a product', (await set(`products/verify-${stamp}`, admin.token, { name: 'Verify', price: 1, type: 'digital' })).status === 200);
  check('deletes the product', (await del(`products/verify-${stamp}`, admin.token)).status === 200);
  check('reads enquiries', (await get('enquiries', admin.token)).status === 200);
  check('moves an enquiry to proposal', (await call('PATCH', `enquiries/verify-${stamp}?updateMask.fieldPaths=status`, admin.token, { fields: { status: enc('proposal') } })).status === 200);
  check('reads all orders', (await get('orders', admin.token)).status === 200);

  // Tidy up the records this script created.
  await del(`enquiries/verify-${stamp}`, admin.token);
  await del(`enrolments/${amara.uid}_team-trust-reset`, admin.token);

  console.log(`\n${passed} passed, ${failed} failed\n`);
  process.exit(failed ? 1 : 0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
