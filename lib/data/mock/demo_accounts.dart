import '../models/people.dart';

/// Demo logins shown on the Login screen so markers can try each portal.
const demoPassword = 'alchemy123';

const demoOrganisation = Organisation(
  id: 'org-northlight',
  name: 'Northlight Housing',
  sector: 'Housing and community services',
  size: '250 to 500 employees',
);

const demoUsers = <AppUser>[
  AppUser(
    id: 'u-amara',
    name: 'Amara Osei',
    email: 'amara@example.com',
    password: demoPassword,
    role: UserRole.individual,
  ),
  AppUser(
    id: 'u-priya',
    name: 'Priya Shah',
    email: 'priya@northlight.example.com',
    password: demoPassword,
    role: UserRole.employer,
    organisationId: 'org-northlight',
  ),
  AppUser(
    id: 'u-maya',
    name: 'Maya Thompson',
    email: 'maya@mtalchemy.example.com',
    password: demoPassword,
    role: UserRole.trainer,
  ),
];

const demoEmployees = <Employee>[
  Employee(
    id: 'e-1',
    name: 'Callum Reid',
    email: 'callum@northlight.example.com',
    team: 'Lettings',
  ),
  Employee(
    id: 'e-2',
    name: 'Fatima Begum',
    email: 'fatima@northlight.example.com',
    team: 'Lettings',
  ),
  Employee(
    id: 'e-3',
    name: 'Owen Hughes',
    email: 'owen@northlight.example.com',
    team: 'Maintenance',
  ),
  Employee(
    id: 'e-4',
    name: 'Leah Morgan',
    email: 'leah@northlight.example.com',
    team: 'Customer Care',
  ),
];
