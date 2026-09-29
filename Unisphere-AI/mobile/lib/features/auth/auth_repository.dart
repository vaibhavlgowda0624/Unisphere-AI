import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) =>
      FirebaseAuthRepository(FirebaseAuth.instance, FirebaseFirestore.instance),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authChanges(),
);

final profileProvider = StreamProvider.family<UserProfile?, String>(
  (ref, uid) => ref.watch(authRepositoryProvider).profileChanges(uid),
);

class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.branch,
    required this.year,
    required this.role,
    this.bio = '',
    this.photoUrl,
    this.suspended = false,
  });

  final String uid;
  final String name;
  final String email;
  final String branch;
  final int year;
  final String role;
  final String bio;
  final String? photoUrl;
  final bool suspended;

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserProfile(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      branch: data['branch'] as String? ?? '',
      year: (data['year'] as num?)?.toInt() ?? 1,
      role: data['role'] as String? ?? 'STUDENT',
      bio: data['bio'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      suspended: data['suspended'] as bool? ?? false,
    );
  }
}

abstract class AuthRepository {
  Stream<User?> authChanges();
  Stream<UserProfile?> profileChanges(String uid);
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String branch,
    required int year,
    required String requestedRole,
  });
  Future<void> signIn(String email, String password);
  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<void> resendVerification();
  Future<void> updateProfile(
    String uid, {
    required String name,
    required String bio,
    required String branch,
    required int year,
  });
  Future<void> requestRole(String uid, String role);
}

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this.auth, this.db);
  final FirebaseAuth auth;
  final FirebaseFirestore db;

  @override
  Stream<User?> authChanges() => auth.authStateChanges();

  @override
  Stream<UserProfile?> profileChanges(String uid) => db
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.exists ? UserProfile.fromDoc(doc) : null);

  @override
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String branch,
    required int year,
    required String requestedRole,
  }) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    try {
      await user.updateDisplayName(name);
      final batch = db.batch();
      batch.set(db.collection('users').doc(user.uid), {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'branch': branch.trim(),
        'year': year,
        'role': 'STUDENT',
        'bio': '',
        'suspended': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (requestedRole != 'STUDENT') {
        batch.set(db.collection('role_requests').doc(), {
          'uid': user.uid,
          'requestedRole': requestedRole,
          'status': 'PENDING',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      await user.sendEmailVerification();
      await auth.signOut();
    } catch (_) {
      try {
        await user.delete();
      } catch (_) {
        /* Firebase may require recent login. */
      }
      rethrow;
    }
  }

  @override
  Future<void> signIn(String email, String password) async =>
      auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  @override
  Future<void> signOut() => auth.signOut();

  @override
  Future<void> sendPasswordReset(String email) =>
      auth.sendPasswordResetEmail(email: email.trim());

  @override
  Future<void> resendVerification() async =>
      auth.currentUser?.sendEmailVerification();

  @override
  Future<void> updateProfile(
    String uid, {
    required String name,
    required String bio,
    required String branch,
    required int year,
  }) => db.collection('users').doc(uid).update({
    'name': name.trim(),
    'bio': bio.trim(),
    'branch': branch.trim(),
    'year': year,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  @override
  Future<void> requestRole(String uid, String role) async {
    if (role != 'FACULTY' && role != 'CLUB_ADMIN') {
      throw ArgumentError('Invalid requested role');
    }
    final existing = await db
        .collection('role_requests')
        .where('uid', isEqualTo: uid)
        .where('status', isEqualTo: 'PENDING')
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw StateError('A role request is already pending');
    }
    await db.collection('role_requests').add({
      'uid': uid,
      'requestedRole': role,
      'status': 'PENDING',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
