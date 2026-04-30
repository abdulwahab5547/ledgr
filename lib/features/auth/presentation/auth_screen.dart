import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/ambient_backdrop.dart';
import '../../../core/design/components/ledgr_buttons.dart';
import '../../../core/design/components/ledgr_text_field.dart';
import '../../../core/design/ledgr_colors.dart';
import '../../../core/design/ledgr_typography.dart';
import '../../../core/haptics/haptics.dart';
import '../data/auth_service.dart';
import '../domain/auth_providers.dart';

enum _AuthMode { signIn, signUp }

/// Full-screen auth surface — matches the lock screen's branding so the
/// transition feels native. Toggles between sign-in and sign-up; both share
/// the same email + password fields.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  _AuthMode _mode = _AuthMode.signIn;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  bool get _isSignUp => _mode == _AuthMode.signUp;

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = ref.read(authServiceProvider);
    try {
      if (_isSignUp) {
        await auth.signUp(email: _email.text, password: _password.text);
      } else {
        await auth.signIn(email: _email.text, password: _password.text);
      }
      await Haptics.success();
      // The router redirect normally catches auth-state changes and pushes
      // us forward, but Firebase Web has a known edge case where
      // `authStateChanges` does not re-emit on a returning sign-in within
      // the same browser session. Navigate explicitly so the user always
      // moves on after a successful auth call.
      if (mounted) context.go('/lock');
    } on Object catch (e) {
      await Haptics.warn();
      if (!mounted) return;
      setState(() => _error = AuthService.describeError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AmbientBackdrop(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        'L',
                        style: LedgrType.serif(
                          fontSize: 80,
                          fontStyle: FontStyle.italic,
                          color: LedgrColors.lime,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Ledgr',
                        style: LedgrType.serif(fontSize: 28),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        _isSignUp
                            ? 'Create your account'
                            : 'Welcome back',
                        style: LedgrType.eyebrow(
                          color: LedgrColors.textMute,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    LedgrTextField(
                      controller: _email,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      textCapitalization: TextCapitalization.none,
                      autofocus: true,
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Required';
                        if (!value.contains('@') ||
                            !value.contains('.')) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    LedgrTextField(
                      controller: _password,
                      label: 'Password',
                      keyboardType: TextInputType.visiblePassword,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        if (_isSignUp && v.length < 8) {
                          return 'Use at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: LedgrType.sans(
                          fontSize: 12,
                          color: LedgrColors.neg,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    LedgrPrimaryButton(
                      label: _busy
                          ? (_isSignUp ? 'Creating…' : 'Signing in…')
                          : (_isSignUp ? 'Create account' : 'Sign in'),
                      onPressed: _busy ? null : _submit,
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: TextButton(
                        onPressed: _busy
                            ? null
                            : () => setState(() {
                                  _mode = _isSignUp
                                      ? _AuthMode.signIn
                                      : _AuthMode.signUp;
                                  _error = null;
                                }),
                        child: RichText(
                          text: TextSpan(
                            style: LedgrType.sans(
                              fontSize: 13,
                              color: LedgrColors.textDim,
                            ),
                            children: [
                              TextSpan(
                                text: _isSignUp
                                    ? 'Already have an account? '
                                    : "Don't have an account? ",
                              ),
                              TextSpan(
                                text:
                                    _isSignUp ? 'Sign in' : 'Create one',
                                style: LedgrType.sans(
                                  fontSize: 13,
                                  color: LedgrColors.lime,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
