/// Signed-in roles. A signed-out visitor is a guest (no [AppUser]).
enum UserRole { individual, employer, trainer, superAdmin }

extension UserRoleLabel on UserRole {
  String get label => switch (this) {
    UserRole.individual => 'Individual',
    UserRole.employer => 'Employer',
    UserRole.trainer => 'Trainer',
    UserRole.superAdmin => 'Super Admin',
  };

  bool get isStaff => this == UserRole.trainer || this == UserRole.superAdmin;
}

UserRole userRoleFrom(Object? name) {
  for (final r in UserRole.values) {
    if (r.name == name) return r;
  }
  return UserRole.individual;
}

DateTime? dateFrom(Object? v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  // Firestore Timestamp, without importing cloud_firestore into models.
  try {
    return (v as dynamic).toDate() as DateTime;
  } catch (_) {
    return null;
  }
}

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.organisationId,
    this.gender,
    this.country,
    this.hobbies = const [],
    this.disabled = false,
    this.createdAt,
    this.careerStage,
    this.interests = const [],
  });

  /// Firebase Auth uid.
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? organisationId;
  final String? gender;
  final String? country;
  final List<String> hobbies;
  final bool disabled;
  final DateTime? createdAt;

  /// [CareerStage] name chosen at registration (see eligibility.dart).
  final String? careerStage;

  /// Practice-area slugs the learner wants to grow in.
  final List<String> interests;

  String get firstName => name.split(' ').first;

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'role': role.name,
    'orgId': organisationId,
    'gender': gender,
    'country': country,
    'hobbies': hobbies,
    'disabled': disabled,
    'careerStage': careerStage,
    'interests': interests,
  };

  factory AppUser.fromMap(String id, Map<String, dynamic> m) => AppUser(
    id: id,
    name: m['name'] as String? ?? '',
    email: m['email'] as String? ?? '',
    role: userRoleFrom(m['role']),
    organisationId: m['orgId'] as String?,
    gender: m['gender'] as String?,
    country: m['country'] as String?,
    hobbies: List<String>.from(m['hobbies'] as List? ?? const []),
    disabled: m['disabled'] as bool? ?? false,
    createdAt: dateFrom(m['createdAt']),
    careerStage: m['careerStage'] as String?,
    interests: List<String>.from(m['interests'] as List? ?? const []),
  );

  AppUser copyWith({
    String? name,
    UserRole? role,
    String? organisationId,
    bool? disabled,
  }) => AppUser(
    id: id,
    name: name ?? this.name,
    email: email,
    role: role ?? this.role,
    organisationId: organisationId ?? this.organisationId,
    gender: gender,
    country: country,
    hobbies: hobbies,
    disabled: disabled ?? this.disabled,
    createdAt: createdAt,
    careerStage: careerStage,
    interests: interests,
  );
}

class Organisation {
  const Organisation({
    required this.id,
    required this.name,
    required this.sector,
    required this.size,
    this.ownerId,
    this.seats = const {},
  });

  final String id;
  final String name;
  final String sector;
  final String size;
  final String? ownerId;

  /// Purchased, unassigned seats per course id.
  final Map<String, int> seats;

  int seatsFor(String courseId) => seats[courseId] ?? 0;

  Map<String, dynamic> toMap() => {
    'name': name,
    'sector': sector,
    'size': size,
    'ownerId': ownerId,
    'seats': seats,
  };

  factory Organisation.fromMap(String id, Map<String, dynamic> m) =>
      Organisation(
        id: id,
        name: m['name'] as String? ?? '',
        sector: m['sector'] as String? ?? '',
        size: m['size'] as String? ?? '',
        ownerId: m['ownerId'] as String?,
        seats: {
          for (final e in (m['seats'] as Map? ?? const {}).entries)
            e.key as String: (e.value as num).toInt(),
        },
      );
}

class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.team,
    this.orgId = '',
  });

  final String id;
  final String name;
  final String email;
  final String team;
  final String orgId;

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email.toLowerCase(),
    'team': team,
    'orgId': orgId,
  };

  factory Employee.fromMap(String id, Map<String, dynamic> m) => Employee(
    id: id,
    name: m['name'] as String? ?? '',
    email: m['email'] as String? ?? '',
    team: m['team'] as String? ?? '',
    orgId: m['orgId'] as String? ?? '',
  );
}
