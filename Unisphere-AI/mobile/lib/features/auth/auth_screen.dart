import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_config.dart';
import 'auth_repository.dart';
import 'auth_validation.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  final branch = TextEditingController();
  bool registering = false;
  bool busy = false;
  int year = 1;
  String requestedRole = 'STUDENT';

  @override
  void dispose() {
    for (final controller in [name, email, password, confirm, branch]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      final repository = ref.read(authRepositoryProvider);
      if (registering) {
        await repository.register(
          name: name.text,
          email: email.text,
          password: password.text,
          branch: branch.text,
          year: year,
          requestedRole: requestedRole,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Account created. Verify your email, then sign in.',
              ),
            ),
          );
        }
        setState(() => registering = false);
      } else {
        await repository.signIn(email.text, password.text);
      }
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message ?? 'Authentication failed. Try again.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not complete the request: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> resetPassword() async {
    final error = AuthValidation.email(
      email.text,
      AppConfig.allowedEmailDomain,
    );
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    try {
      await ref.read(authRepositoryProvider).sendPasswordReset(email.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'If this email has an account, a reset link has been sent.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset failed: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.school_rounded,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'UniSphere AI',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    registering ? 'Create your campus account' : 'Welcome back',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (registering) ...[
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          AuthValidation.required(value, 'Full name'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'University email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => AuthValidation.email(
                      value,
                      AppConfig.allowedEmailDomain,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: password,
                    obscureText: true,
                    autofillHints: [
                      registering
                          ? AutofillHints.newPassword
                          : AutofillHints.password,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => registering
                        ? AuthValidation.password(value)
                        : AuthValidation.required(value, 'Password'),
                  ),
                  if (registering) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: confirm,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          AuthValidation.confirmPassword(password.text, value),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: branch,
                      decoration: const InputDecoration(
                        labelText: 'Branch / department',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          AuthValidation.required(value, 'Branch'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int>(
                      initialValue: year,
                      decoration: const InputDecoration(
                        labelText: 'Academic year',
                        border: OutlineInputBorder(),
                      ),
                      items: [1, 2, 3, 4, 5, 6]
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text('Year $value'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() => year = value ?? 1),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: requestedRole,
                      decoration: const InputDecoration(
                        labelText: 'Requested role',
                        border: OutlineInputBorder(),
                      ),
                      items: const ['STUDENT', 'FACULTY', 'CLUB_ADMIN']
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value.replaceAll('_', ' ')),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => requestedRole = value ?? 'STUDENT'),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'All new accounts start as students. Elevated roles require approval.',
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: busy ? null : submit,
                    child: busy
                        ? const CircularProgressIndicator()
                        : Text(registering ? 'Create account' : 'Sign in'),
                  ),
                  if (!registering)
                    TextButton(
                      onPressed: busy ? null : resetPassword,
                      child: const Text('Forgot password?'),
                    ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() => registering = !registering),
                    child: Text(
                      registering
                          ? 'Already have an account? Sign in'
                          : 'Create an account',
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

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key});
  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool busy = false;
  Future<void> refresh() async {
    setState(() => busy = true);
    try {
      await FirebaseAuth.instance.currentUser?.reload();
      ref.invalidate(authStateProvider);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Verify email')),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.mark_email_unread_outlined, size: 64),
            const SizedBox(height: 16),
            const Text('Open the verification link sent to your email.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy ? null : refresh,
              child: const Text('I verified my email'),
            ),
            TextButton(
              onPressed: () async {
                await ref.read(authRepositoryProvider).resendVerification();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verification email sent.')),
                  );
                }
              },
              child: const Text('Resend link'),
            ),
            TextButton(
              onPressed: () => ref.read(authRepositoryProvider).signOut(),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    ),
  );
}
