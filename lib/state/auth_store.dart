import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide UserInfo;
import 'package:flutter/foundation.dart';

import '../data/backend.dart';
import '../data/models/people.dart';

/// Firebase Authentication plus the signed-in user's profile (users/{uid})
/// and organisation. Signed out means the visitor is a guest.
class AuthStore extends ChangeNotifier {
  AuthStore(this._backend) {
    _authSub = _backend.auth.authStateChanges().listen(_onAuth);
  }

  final Backend _backend;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _orgSub;

  AppUser? _current;
  Organisation? _organisation;

  /// False until Firebase has told us whether someone is signed in.
  bool _ready = false;
  bool get ready => _ready;

  AppUser? get currentUser => _current;
  bool get isSignedIn => _current != null;
  Organisation? get currentOrganisation => _organisation;
  String? get email => _backend.auth.currentUser?.email;

  void _onAuth(User? user) {
    _profileSub?.cancel();
    _orgSub?.cancel();
    _organisation = null;
    if (user == null) {
      _current = null;
      _ready = true;
      notifyListeners();
      return;
    }
    _profileSub = _backend.col('users').doc(user.uid).snapshots().listen(
      (snap) {
        final data = snap.data();
        // A brand new account has no profile until registration writes it.
        if (data == null) return;
        final profile = AppUser.fromMap(user.uid, data);
        if (profile.disabled) {
          _backend.auth.signOut();
          return;
        }
        if (profile.organisationId != _current?.organisationId ||
            _orgSub == null) {
          _watchOrg(profile.organisationId);
        }
        _current = profile;
        _ready = true;
        notifyListeners();
      },
      onError: (_) {
        _ready = true;
        notifyListeners();
      },
    );
  }

  void _watchOrg(String? orgId) {
    _orgSub?.cancel();
    _orgSub = null;
    _organisation = null;
    if (orgId == null) return;
    _orgSub = _backend.col('organizations').doc(orgId).snapshots().listen((
      snap,
    ) {
      final data = snap.data();
      _organisation = data == null ? null : Organisation.fromMap(snap.id, data);
      notifyListeners();
    }, onError: (_) {});
  }

  /// Resolves once the profile for the signed-in account has loaded.
  Future<void> _awaitProfile() async {
    if (_current != null &&
        _current!.id == _backend.auth.currentUser?.uid) {
      return;
    }
    final done = Completer<void>();
    void check() {
      if (_current != null && !done.isCompleted) done.complete();
    }

    addListener(check);
    try {
      await done.future.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      // Fall through: the router will still react when the profile arrives.
    } finally {
      removeListener(check);
    }
  }

  /// Returns an error message, or null on success.
  Future<String?> signIn(String email, String password) async {
    try {
      await _backend.auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _awaitProfile();
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }

  Future<String?> sendPasswordReset(String email) async {
    try {
      await _backend.auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }

  /// Registers an individual learner and signs them in.
  Future<String?> registerIndividual({
    required String name,
    required String email,
    required String password,
    String? gender,
    String? country,
    List<String> hobbies = const [],
  }) async {
    try {
      final cred = await _backend.auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user!.uid;
      // Link to an organisation if an employer has already added this email.
      String? orgId;
      try {
        final invited = await _backend
            .col('employees')
            .where('email', isEqualTo: email.trim().toLowerCase())
            .limit(1)
            .get();
        if (invited.docs.isNotEmpty) {
          orgId = invited.docs.first.data()['orgId'] as String?;
        }
      } catch (_) {
        // Not invited by an employer; register as a standalone learner.
      }
      await _backend.col('users').doc(uid).set({
        ...AppUser(
          id: uid,
          name: name.trim(),
          email: cred.user!.email ?? email.trim(),
          role: UserRole.individual,
          organisationId: orgId,
          gender: gender,
          country: country,
          hobbies: hobbies,
        ).toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      await cred.user!.updateDisplayName(name.trim());
      await _awaitProfile();
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }

  /// Registers an organisation with its first employer admin and signs them in.
  Future<String?> registerOrganisation({
    required String name,
    required String email,
    required String password,
    required String organisationName,
    required String sector,
    required String size,
  }) async {
    try {
      final cred = await _backend.auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user!.uid;
      final orgRef = _backend.col('organizations').doc();
      await orgRef.set({
        ...Organisation(
          id: orgRef.id,
          name: organisationName.trim(),
          sector: sector.trim(),
          size: size,
          ownerId: uid,
        ).toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _backend.col('users').doc(uid).set({
        ...AppUser(
          id: uid,
          name: name.trim(),
          email: cred.user!.email ?? email.trim(),
          role: UserRole.employer,
          organisationId: orgRef.id,
        ).toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _awaitProfile();
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }

  /// Updates the signed-in user's own name and profile details.
  Future<String?> updateProfile({
    required String name,
    String? gender,
    String? country,
    List<String>? hobbies,
  }) async {
    final user = _current;
    if (user == null) return 'Please sign in first.';
    try {
      await _backend.col('users').doc(user.id).update({
        'name': name.trim(),
        'gender': ?gender,
        'country': ?country,
        'hobbies': ?hobbies,
      });
      return null;
    } catch (e) {
      return friendlyError(e);
    }
  }

  Future<void> signOut() => _backend.auth.signOut();

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    _orgSub?.cancel();
    super.dispose();
  }
}
