import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_config.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/auth_screen.dart';
import 'features/home/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: AppConfig.firebaseOptions);
    if (AppConfig.useEmulators) {
      await FirebaseAuth.instance.useAuthEmulator(AppConfig.emulatorHost, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(
        AppConfig.emulatorHost,
        8081,
      );
      await FirebaseStorage.instance.useStorageEmulator(
        AppConfig.emulatorHost,
        9199,
      );
    }
    runApp(const ProviderScope(child: UniSphereApp()));
  } catch (error) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Firebase setup failed: $error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UniSphereApp extends ConsumerWidget {
  const UniSphereApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    title: 'UniSphere AI',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2947A9)),
      useMaterial3: true,
    ),
    darkTheme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF89A7FF),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ),
    home: const AuthGate(),
  );
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          Scaffold(body: Center(child: Text('Session error: $error'))),
      data: (user) {
        if (user == null) return const AuthScreen();
        if (!user.emailVerified) return const VerifyEmailScreen();
        final profile = ref.watch(profileProvider(user.uid));
        return profile.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Profile unavailable: $error'),
                  Text('Check your connection and retry.'),
                ],
              ),
            ),
          ),
          data: (value) {
            if (value == null) {
              return const Scaffold(
                body: Center(
                  child: Text(
                    'Your profile is missing. Contact a campus administrator.',
                  ),
                ),
              );
            }
            if (value.suspended) {
              return const Scaffold(
                body: Center(
                  child: Text(
                    'This account has been suspended. Contact a campus administrator.',
                  ),
                ),
              );
            }
            return HomeShell(profile: value);
          },
        );
      },
    );
  }
}
