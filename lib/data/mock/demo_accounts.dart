import '../models/people.dart';

/// Demo logins shown on the Login screen so markers can try each portal.
/// The seed script (tools/seed) creates these accounts in Firebase Auth.
const demoPassword = 'alchemy123';

const demoOrganisation = Organisation(
  id: 'org-northlight',
  name: 'Northlight Housing',
  sector: 'Housing and community services',
  size: '250 to 500 employees',
  seats: {'leading-through-change': 3, 'team-trust-reset': 5},
);

/// One account per signed-in role (ids are replaced by Auth uids when seeded).
const demoUsers = <AppUser>[
  AppUser(
    id: 'u-amara',
    name: 'Amara Osei',
    email: 'amara@example.com',
    role: UserRole.individual,
    gender: 'Female',
    country: 'Malaysia',
    hobbies: ['Reading', 'Travel'],
  ),
  AppUser(
    id: 'u-priya',
    name: 'Priya Shah',
    email: 'priya@northlight.example.com',
    role: UserRole.employer,
    organisationId: 'org-northlight',
  ),
  AppUser(
    id: 'u-maya',
    name: 'Maya Thompson',
    email: 'maya@mtalchemy.example.com',
    role: UserRole.trainer,
  ),
  AppUser(
    id: 'u-admin',
    name: 'Daniel Lim',
    email: 'admin@mtalchemy.example.com',
    role: UserRole.superAdmin,
  ),
  // An employee of the demo organisation who learns through assigned courses.
  AppUser(
    id: 'u-callum',
    name: 'Callum Reid',
    email: 'callum@northlight.example.com',
    role: UserRole.individual,
    organisationId: 'org-northlight',
  ),
];

const demoEmployees = <Employee>[
  Employee(
    id: 'e-1',
    name: 'Callum Reid',
    email: 'callum@northlight.example.com',
    team: 'Lettings',
    orgId: 'org-northlight',
  ),
  Employee(
    id: 'e-2',
    name: 'Fatima Begum',
    email: 'fatima@northlight.example.com',
    team: 'Lettings',
    orgId: 'org-northlight',
  ),
  Employee(
    id: 'e-3',
    name: 'Owen Hughes',
    email: 'owen@northlight.example.com',
    team: 'Maintenance',
    orgId: 'org-northlight',
  ),
  Employee(
    id: 'e-4',
    name: 'Leah Morgan',
    email: 'leah@northlight.example.com',
    team: 'Customer Care',
    orgId: 'org-northlight',
  ),
];
