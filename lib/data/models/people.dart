enum UserRole { individual, employer, trainer }

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
    UserRole.individual => 'Individual',
    UserRole.employer => 'Employer',
    UserRole.trainer => 'Trainer / Admin',
  };
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.organisationId,
  });

  final String id;
  final String name;
  final String email;

  /// Mock only: plain text because there is no backend at this checkpoint.
  final String password;
  final UserRole role;
  final String? organisationId;

  String get firstName => name.split(' ').first;
}

class Organisation {
  const Organisation({
    required this.id,
    required this.name,
    required this.sector,
    required this.size,
  });

  final String id;
  final String name;
  final String sector;
  final String size;
}

class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.team,
  });

  final String id;
  final String name;
  final String email;
  final String team;
}
