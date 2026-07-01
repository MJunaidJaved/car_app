import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';
import 'api_service.dart';
import 'session_storage.dart';

class AuthService {
  AuthService();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
  );

  Future<void> _pushFcmToken() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) return;
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await ApiService.patch('/auth/fcm-token', {'fcmToken': token});
      }
    } catch (_) {}
  }

  UserModel _userFromResponse(Map<String, dynamic> userData, String uid) {
    return UserModel.fromMap(userData, uid);
  }

  Future<void> _persistUser(UserModel user) async {
    await SessionStorage.saveDemoUser(
      id: user.id,
      email: user.email,
      name: user.name,
    );
    if (user.phone.trim().isNotEmpty) {
      await SessionStorage.setPhone(user.phone);
    }
  }

  Map<String, dynamic> _buildSyncBody({
    required String role,
    String? gender,
    String? name,
    String? phone,
    String? vehicleMake,
    String? vehicleModel,
    String? captainVehicleType,
    String? vehicleColor,
    String? vehicleRegistration,
    int? vehicleYear,
    int? vehicleSeats,
    String? city,
    String? photoUrl,
    String? vehiclePhotoUrl,
    String? captainVerificationStatus,
  }) {
    final body = <String, dynamic>{'role': role};
    void put(String key, dynamic value) {
      if (value != null && value.toString().trim().isNotEmpty) {
        body[key] = value;
      }
    }

    put('gender', gender);
    put('name', name);
    put('phone', phone);
    put('vehicleMake', vehicleMake);
    put('vehicleModel', vehicleModel);
    put('captainVehicleType', captainVehicleType);
    put('vehicleColor', vehicleColor);
    put('vehicleRegistration', vehicleRegistration);
    if (vehicleYear != null) body['vehicleYear'] = vehicleYear;
    if (vehicleSeats != null) body['vehicleSeats'] = vehicleSeats;
    put('city', city);
    put('photoUrl', photoUrl);
    put('vehiclePhotoUrl', vehiclePhotoUrl);
    put('captainVerificationStatus', captainVerificationStatus);
    return body;
  }

  Future<UserModel> syncRole({
    required String role,
    String? gender,
    String? name,
    String? phone,
    String? vehicleMake,
    String? vehicleModel,
    String? captainVehicleType,
    String? vehicleColor,
    String? vehicleRegistration,
    int? vehicleYear,
    int? vehicleSeats,
    String? city,
    String? photoUrl,
    String? vehiclePhotoUrl,
    String? captainVerificationStatus,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    final body = _buildSyncBody(
      role: role,
      gender: gender,
      name: name,
      phone: phone,
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      captainVehicleType: captainVehicleType,
      vehicleColor: vehicleColor,
      vehicleRegistration: vehicleRegistration,
      vehicleYear: vehicleYear,
      vehicleSeats: vehicleSeats,
      city: city,
      photoUrl: photoUrl,
      vehiclePhotoUrl: vehiclePhotoUrl,
      captainVerificationStatus: captainVerificationStatus,
    );

    debugPrint('DEBUG: Calling ApiService.post(/auth/sync) with body: $body');
    try {
      final response = await ApiService.post('/auth/sync', body);
      debugPrint(
          'DEBUG: ApiService.post(/auth/sync) response received: $response');
      final user =
          _userFromResponse(response['user'] as Map<String, dynamic>, uid);
      await _persistUser(user);
      await _pushFcmToken();
      return user;
    } catch (e) {
      debugPrint(
          'DEBUG: ApiService.post(/auth/sync) failed with exception: $e');
      rethrow;
    }
  }

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
    String? gender,
  }) async {
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user?.uid;
    if (uid == null) throw Exception('Failed to create user');
    return syncRole(role: role, name: name, phone: phone, gender: gender);
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user?.uid;
    if (uid == null) throw Exception('Failed to sign in');

    try {
      final response = await ApiService.get('/auth/profile');
      final user =
          _userFromResponse(response['user'] as Map<String, dynamic>, uid);
      await _persistUser(user);
      await _pushFcmToken();
      return user;
    } on ApiException catch (e) {
      if (e.statusCode != 404 && e.code != 'USER_NOT_FOUND') rethrow;
      final firebaseUser = FirebaseAuth.instance.currentUser!;
      final fallbackUser = UserModel(
        id: uid,
        email: firebaseUser.email ?? email,
        name: firebaseUser.displayName ?? email.split('@').first,
        phone: firebaseUser.phoneNumber ?? '',
        role: '',
        photoUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
      );
      await _persistUser(fallbackUser);
      return fallbackUser;
    }
  }

  Future<UserModel?> restoreSession() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;

    // Always fetch fresh from backend — no stale cache
    try {
      final response = await ApiService.get('/auth/profile');
      final user = _userFromResponse(
        response['user'] as Map<String, dynamic>,
        currentUser.uid,
      );
      await _persistUser(user);
      return user;
    } catch (e) {
      debugPrint('AuthService: restoreSession backend failed: $e');
      return SessionStorage.loadUserModel();
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      final response = await ApiService.get('/auth/profile');
      return _userFromResponse(response['user'] as Map<String, dynamic>, uid);
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await FirebaseAuth.instance.signOut();
    await SessionStorage.clear();
  }

  Future<void> resetPassword(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }

  Future<UserModel?> signInWithGoogle() async {
    await _googleSignIn.signOut(); // force account picker every time

    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final authResult =
        await FirebaseAuth.instance.signInWithCredential(credential);
    final uid = authResult.user?.uid;
    final name = authResult.user?.displayName ?? 'User';
    if (uid == null) throw Exception('Google sign-in failed');

    try {
      final response = await ApiService.get('/auth/profile');
      final user =
          _userFromResponse(response['user'] as Map<String, dynamic>, uid);
      await _persistUser(user);
      await _pushFcmToken();
      return user;
    } catch (e) {
      debugPrint('Google user not in DB yet, sending to role selection: $e');
      final user = UserModel(
        id: uid,
        email: authResult.user?.email ?? googleUser.email,
        name: name,
        phone: '',
        role: '',
        photoUrl: authResult.user?.photoURL,
        createdAt: DateTime.now(),
      );
      await _persistUser(user);
      return user;
    }
  }

  Future<UserModel> savePassengerRoleAndProfile() async {
    final stored = await SessionStorage.loadUserModel();
    return syncRole(
      role: 'passenger',
      name: stored?.name,
      phone: stored?.phone,
      gender: stored?.gender,
    );
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await ApiService.patch('/auth/profile', data);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final user =
        _userFromResponse(response['user'] as Map<String, dynamic>, uid);
    await _persistUser(user);
    return user;
  }
}
