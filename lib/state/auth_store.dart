import 'package:flutter/foundation.dart';

import '../data/mock/demo_accounts.dart';
import '../data/models/people.dart';

/// Mock authentication held in memory (no backend for the Oct 14 checkpoint).
class AuthStore extends ChangeNotifier {
  final List<AppUser> _users = [...demoUsers];
  final List<Organisation> _organisations = [demoOrganisation];

  AppUser? _current;
  AppUser? get currentUser => _current;
  bool get isSignedIn => _current != null;

  Organisation? get currentOrganisation {
    final orgId = _current?.organisationId;
    if (orgId == null) return null;
    return _organisations.firstWhere((o) => o.id == orgId);
  }

  /// Returns an error message, or null on success.
  String? signIn(String email, String password) {
    final match = _users.where(
      (u) => u.email.toLowerCase() == email.trim().toLowerCase(),
    );
    if (match.isEmpty || match.first.password != password) {
      return 'That email and password do not match an account.';
    }
    _current = match.first;
    notifyListeners();
    return null;
  }

  bool emailTaken(String email) =>
      _users.any((u) => u.email.toLowerCase() == email.trim().toLowerCase());

  /// Registers an individual learner and signs them in.
  String? registerIndividual({
    required String name,
    required String email,
    required String password,
  }) {
    if (emailTaken(email)) return 'An account with that email already exists.';
    _current = AppUser(
      id: 'u-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim(),
      password: password,
      role: UserRole.individual,
    );
    _users.add(_current!);
    notifyListeners();
    return null;
  }

  /// Registers an organisation with its first employer admin and signs them in.
  String? registerOrganisation({
    required String name,
    required String email,
    required String password,
    required String organisationName,
    required String sector,
    required String size,
  }) {
    if (emailTaken(email)) return 'An account with that email already exists.';
    final org = Organisation(
      id: 'org-${DateTime.now().microsecondsSinceEpoch}',
      name: organisationName.trim(),
      sector: sector.trim(),
      size: size,
    );
    _organisations.add(org);
    _current = AppUser(
      id: 'u-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      email: email.trim(),
      password: password,
      role: UserRole.employer,
      organisationId: org.id,
    );
    _users.add(_current!);
    notifyListeners();
    return null;
  }

  void signOut() {
    _current = null;
    notifyListeners();
  }
}
