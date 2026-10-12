import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:mt_alchemy/data/backend.dart';
import 'package:mt_alchemy/data/models/people.dart';
import 'package:mt_alchemy/state/auth_store.dart';

/// A signed-in user on an in-memory Firestore, with their profile written,
/// and an [AuthStore] that has finished loading it.
class FakeSession {
  FakeSession._(this.backend, this.auth, this.user);

  final Backend backend;
  final AuthStore auth;
  final AppUser user;

  FakeFirebaseFirestore get db => backend.db as FakeFirebaseFirestore;

  static Future<FakeSession> signedIn({
    String uid = 'u-test',
    String name = 'Test Learner',
    String email = 'learner@example.com',
    UserRole role = UserRole.individual,
    String? orgId,
    Map<String, dynamic>? organisation,
  }) async {
    final db = FakeFirebaseFirestore();
    final mockAuth = MockFirebaseAuth(
      signedIn: true,
      mockUser: MockUser(uid: uid, email: email, displayName: name),
    );
    final user = AppUser(
      id: uid,
      name: name,
      email: email,
      role: role,
      organisationId: orgId,
    );
    await db.collection('users').doc(uid).set(user.toMap());
    if (orgId != null && organisation != null) {
      await db.collection('organizations').doc(orgId).set(organisation);
    }
    final backend = Backend(auth: mockAuth, db: db);
    final auth = AuthStore(backend);
    // Let the auth and profile streams deliver.
    for (var i = 0; i < 20 && auth.currentUser == null; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    if (orgId != null) {
      for (var i = 0; i < 20 && auth.currentOrganisation == null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
    }
    return FakeSession._(backend, auth, user);
  }
}

/// Waits for Firestore snapshot listeners to catch up.
Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 30));
