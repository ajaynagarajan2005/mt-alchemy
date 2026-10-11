/// A member of the MT Alchemy team (illustrative content for the prototype).
class TeamMember {
  const TeamMember({required this.name, required this.role, required this.bio});

  final String name;
  final String role;
  final String bio;
}

const team = <TeamMember>[
  TeamMember(
    name: 'Maya Thompson',
    role: 'Founder and Lead Facilitator',
    bio: 'Twenty years in people development. Maya leads our emotional intelligence and change work.',
  ),
  TeamMember(
    name: 'Daniel Okafor',
    role: 'Leadership Coach',
    bio: 'A former operations manager who coaches first-time managers and senior teams.',
  ),
  TeamMember(
    name: 'Grace Whitfield',
    role: 'Well-being Practitioner',
    bio: 'Grace designs workload and well-being programmes that managers can run themselves.',
  ),
  TeamMember(
    name: 'Tom Hargreaves',
    role: 'Programme Manager',
    bio: 'Tom keeps every programme on track, from the first call to the final review.',
  ),
];
