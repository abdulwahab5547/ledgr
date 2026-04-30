import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper over Firebase Auth — gives us a single seam to mock in tests
/// and a stable API to use throughout the app.
///
/// Public surface intentionally tiny: sign in / sign up / sign out / current
/// user. Anything fancier (password reset, email verification, third-party
/// providers) gets added here when it's needed, not pre-emptively.
class AuthService {
  AuthService({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Stream of the current user. Emits null when signed out, a [User] when
  /// signed in. Replays the latest value to new listeners — perfect for
  /// driving the auth gate in the router.
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  /// Maps `FirebaseAuthException` codes to short, user-readable messages.
  /// Covers the ones a Ledgr user is likely to hit during email/password
  /// flows; falls back to the raw message for anything else.
  static String describeError(Object error) {
    if (error is! FirebaseAuthException) return error.toString();
    switch (error.code) {
      case 'invalid-email':
        return 'That doesn\'t look like a valid email.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account with that email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use 8+ characters.';
      case 'network-request-failed':
        return 'Network error. Check your connection and retry.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment and try again.';
      default:
        return error.message ?? 'Authentication failed (${error.code}).';
    }
  }
}
