import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Live auth state. Anywhere in the app that needs to know "is the user
/// signed in?" should `ref.watch(authStateProvider)` and check for null.
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

/// Convenience: just the user (or null), with loading collapsed to null.
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// True once the auth state has emitted at least once. Important for the
/// router redirect: before the first emission we don't know if the user is
/// signed in, so we shouldn't redirect anywhere.
final isAuthResolvedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider).hasValue;
});
