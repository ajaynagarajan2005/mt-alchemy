import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// The Firebase services every store talks to. Tests pass fakes
/// (FakeFirebaseFirestore, MockFirebaseAuth) instead of the real instances.
class Backend {
  Backend({required this.auth, required this.db});

  factory Backend.live() =>
      Backend(auth: FirebaseAuth.instance, db: FirebaseFirestore.instance);

  final FirebaseAuth auth;
  final FirebaseFirestore db;

  CollectionReference<Map<String, dynamic>> col(String name) =>
      db.collection(name);
}

/// Turns Firebase errors into sentences a learner can act on.
String friendlyError(Object e) {
  if (e is FirebaseAuthException) {
    return switch (e.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' ||
      'invalid-email' => 'That email and password do not match an account.',
      'email-already-in-use' => 'An account with that email already exists.',
      'weak-password' => 'Choose a password with at least 8 characters.',
      'too-many-requests' =>
        'Too many attempts. Please wait a minute and try again.',
      'network-request-failed' =>
        'We could not reach the server. Check your connection and try again.',
      'user-disabled' => 'This account has been disabled. Please contact us.',
      _ => e.message ?? 'Something went wrong. Please try again.',
    };
  }
  if (e is FirebaseException) {
    return switch (e.code) {
      'permission-denied' => 'You do not have permission to do that.',
      'unavailable' =>
        'We could not reach the server. Check your connection and try again.',
      _ => e.message ?? 'Something went wrong. Please try again.',
    };
  }
  if (e is StateError) return e.message;
  return 'Something went wrong. Please try again.';
}
