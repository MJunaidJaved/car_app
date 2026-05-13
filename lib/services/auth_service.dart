import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Passenger path: anonymous Firebase user so Firestore rules can use request.auth.uid.
  Future<User> signInOrRestoreCustomerSession() async {
    final cur = _auth.currentUser;
    if (cur != null && cur.isAnonymous) {
      return cur;
    }
    if (cur != null) {
      await _auth.signOut();
    }
    final cred = await _auth.signInAnonymously();
    return cred.user!;
  }

  Future<void> ensureCustomerUserDocument(String uid) async {
    final ref = _firestore.collection('users').doc(uid);
    final snap = await ref.get();
    if (snap.exists) return;

    final model = UserModel(
      id: uid,
      email: '',
      name: 'Passenger',
      phone: '',
      role: 'customer',
      isVerified: false,
      rating: 0,
      totalRides: 0,
      createdAt: DateTime.now(),
    );
    await ref.set(model.toMap());
  }

  void startCaptainPhoneVerification({
    required String e164Phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(Object error) onError,
    required Future<void> Function(PhoneAuthCredential credential) onAutoVerified,
  }) {
    _auth.verifyPhoneNumber(
      phoneNumber: e164Phone,
      timeout: const Duration(seconds: 120),
      verificationCompleted: (cred) async {
        try {
          await onAutoVerified(cred);
        } catch (e) {
          onError(e);
        }
      },
      verificationFailed: (e) => onError(e),
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> signInCaptainWithSms({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode.trim(),
    );
    await _auth.signInWithCredential(credential);
  }

  Future<void> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    await _auth.signInWithCredential(credential);
  }

  Future<bool> captainProfileExists() async {
    final u = _auth.currentUser;
    if (u == null || u.isAnonymous) return false;
    final doc = await _firestore.collection('users').doc(u.uid).get();
    if (!doc.exists) return false;
    final data = doc.data();
    return data != null && data['role'] == 'captain';
  }

  Future<void> completeCaptainRegistrationFromPhone({
    required String name,
    required String cnic,
    required String vehicleName,
    required String vehicleNumber,
  }) async {
    final u = _auth.currentUser;
    if (u == null || u.isAnonymous) {
      throw Exception('Captain phone sign-in required');
    }

    final phone = u.phoneNumber ?? '';
    final model = UserModel(
      id: u.uid,
      email: '',
      name: name.trim(),
      phone: phone,
      role: 'captain',
      isVerified: true,
      cnic: cnic.trim(),
      vehicleMake: vehicleName.trim(),
      vehicleModel: '',
      vehicleRegistration: vehicleNumber.trim(),
      rating: 0,
      totalRides: 0,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(u.uid).set(model.toMap());
    await _firestore.collection('wallets').doc(u.uid).set({
      'userId': u.uid,
      'balance': 0.0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Legacy email/password (optional / dev) ---

  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String? cnic,
    String? vehicleMake,
    String? vehicleModel,
    String? vehicleRegistration,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userModel = UserModel(
        id: userCredential.user!.uid,
        email: email,
        name: name,
        phone: phone,
        role: role,
        isVerified: false,
        cnic: cnic,
        vehicleMake: vehicleMake,
        vehicleModel: vehicleModel,
        vehicleRegistration: vehicleRegistration,
        rating: 0.0,
        totalRides: 0,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set(userModel.toMap());

      if (role == 'captain') {
        await _firestore.collection('wallets').doc(userCredential.user!.uid).set({
          'userId': userCredential.user!.uid,
          'balance': 0.0,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Sign up failed');
    }
  }

  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Sign in failed');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Password reset failed');
    }
  }
}
