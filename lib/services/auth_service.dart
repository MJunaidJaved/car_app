import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import 'api_service.dart';
import 'session_storage.dart';
import 'storage_service.dart';

class AuthService {
  AuthService();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
  );
  final StorageService _storage = StorageService();

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
    if (user.role.isNotEmpty) {
      await SessionStorage.setRole(user.role);
    }
  }

  Map<String, dynamic> _buildSyncBody({
    required String role,
    String? name,
    String? phone,
    String? cnic,
    String? cnicFrontUrl,
    String? cnicBackUrl,
    String? vehicleMake,
    String? vehicleModel,
    String? vehicleColor,
    String? vehicleRegistration,
    int? vehicleYear,
    int? vehicleSeats,
    String? city,
    String? photoUrl,
    String? vehiclePhotoUrl,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? captainVerificationStatus,
  }) {
    final body = <String, dynamic>{'role': role};
    void put(String key, dynamic value) {
      if (value != null && value.toString().trim().isNotEmpty) {
        body[key] = value;
      }
    }

    put('name', name);
    put('phone', phone);
    put('cnic', cnic);
    put('cnicFrontUrl', cnicFrontUrl);
    put('cnicBackUrl', cnicBackUrl);
    put('vehicleMake', vehicleMake);
    put('vehicleModel', vehicleModel);
    put('vehicleColor', vehicleColor);
    put('vehicleRegistration', vehicleRegistration);
    if (vehicleYear != null) body['vehicleYear'] = vehicleYear;
    if (vehicleSeats != null) body['vehicleSeats'] = vehicleSeats;
    put('city', city);
    put('photoUrl', photoUrl);
    put('vehiclePhotoUrl', vehiclePhotoUrl);
    put('emergencyContactName', emergencyContactName);
    put('emergencyContactPhone', emergencyContactPhone);
    put('captainVerificationStatus', captainVerificationStatus);
    return body;
  }

  Future<UserModel> syncRole({
    required String role,
    String? name,
    String? phone,
    String? cnic,
    String? cnicFrontUrl,
    String? cnicBackUrl,
    String? vehicleMake,
    String? vehicleModel,
    String? vehicleColor,
    String? vehicleRegistration,
    int? vehicleYear,
    int? vehicleSeats,
    String? city,
    String? photoUrl,
    String? vehiclePhotoUrl,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? captainVerificationStatus,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    final body = _buildSyncBody(
      role: role,
      name: name,
      phone: phone,
      cnic: cnic,
      cnicFrontUrl: cnicFrontUrl,
      cnicBackUrl: cnicBackUrl,
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      vehicleColor: vehicleColor,
      vehicleRegistration: vehicleRegistration,
      vehicleYear: vehicleYear,
      vehicleSeats: vehicleSeats,
      city: city,
      photoUrl: photoUrl,
      vehiclePhotoUrl: vehiclePhotoUrl,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      captainVerificationStatus: captainVerificationStatus,
    );

    debugPrint('DEBUG: Calling ApiService.post(/auth/sync) with body: $body');
    try {
      final response = await ApiService.post('/auth/sync', body);
      debugPrint('DEBUG: ApiService.post(/auth/sync) response received: $response');
      final user = _userFromResponse(response['user'] as Map<String, dynamic>, uid);
      await _persistUser(user);
      await _pushFcmToken();
      return user;
    } catch (e) {
      debugPrint('DEBUG: ApiService.post(/auth/sync) failed with exception: $e');
      rethrow;
    }
  }

  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user?.uid;
    if (uid == null) throw Exception('Failed to create user');
    return syncRole(role: role, name: name, phone: phone);
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

    final response = await ApiService.get('/auth/profile');
    final user = _userFromResponse(response['user'] as Map<String, dynamic>, uid);
    await _persistUser(user);
    await _pushFcmToken();
    return user;
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

    final authResult = await FirebaseAuth.instance.signInWithCredential(credential);
    final uid = authResult.user?.uid;
    final name = authResult.user?.displayName ?? 'User';
    if (uid == null) throw Exception('Google sign-in failed');

    try {
      final response = await ApiService.get('/auth/profile');
      final user = _userFromResponse(response['user'] as Map<String, dynamic>, uid);
      await _persistUser(user);
      await _pushFcmToken();
      return user;
    } catch (e) {
      debugPrint('Google user not in DB, syncing: $e');
      return syncRole(role: 'passenger', name: name, phone: '');
    }
  }

  Future<UserModel> savePassengerRoleAndProfile() async {
    final stored = await SessionStorage.loadUserModel();
    return syncRole(
      role: 'passenger',
      name: stored?.name,
      phone: stored?.phone,
    );
  }

  Future<UserModel> completeCaptainRegistration({
    required String phone,
    required String cnic,
    required String city,
    required String vehicleMake,
    required String vehicleModel,
    required String vehicleColor,
    required String vehicleRegistration,
    required int vehicleYear,
    required int vehicleSeats,
    required String emergencyContactName,
    required String emergencyContactPhone,
    required XFile cnicFront,
    required XFile cnicBack,
    XFile? profilePhoto,
    XFile? vehiclePhoto,
    String? name,
  }) async {
    final stored = await SessionStorage.loadUserModel();
    final displayName = (name ?? stored?.name ?? '').trim();

    debugPrint('DEBUG: starting completeCaptainRegistration upload process...');

    String cnicFrontUrl;
    try {
      debugPrint('DEBUG: Uploading CNIC Front...');
      cnicFrontUrl = await _storage.uploadUserFile(
        file: File(cnicFront.path),
        path: 'cnic_front.jpg',
      );
      debugPrint('DEBUG: CNIC Front upload complete! URL: $cnicFrontUrl');
    } catch (e) {
      debugPrint('DEBUG: CNIC Front upload FAILED: $e');
      rethrow;
    }

    String cnicBackUrl;
    try {
      debugPrint('DEBUG: Uploading CNIC Back...');
      cnicBackUrl = await _storage.uploadUserFile(
        file: File(cnicBack.path),
        path: 'cnic_back.jpg',
      );
      debugPrint('DEBUG: CNIC Back upload complete! URL: $cnicBackUrl');
    } catch (e) {
      debugPrint('DEBUG: CNIC Back upload FAILED: $e');
      rethrow;
    }

    String? photoUrl;
    if (profilePhoto != null) {
      try {
        debugPrint('DEBUG: Uploading Profile Photo...');
        photoUrl = await _storage.uploadUserFile(
          file: File(profilePhoto.path),
          path: 'profile.jpg',
        );
        debugPrint('DEBUG: Profile Photo upload complete! URL: $photoUrl');
      } catch (e) {
        debugPrint('DEBUG: Profile Photo upload FAILED: $e');
        rethrow;
      }
    }

    String? vehiclePhotoUrl;
    if (vehiclePhoto != null) {
      try {
        debugPrint('DEBUG: Uploading Vehicle Photo...');
        vehiclePhotoUrl = await _storage.uploadUserFile(
          file: File(vehiclePhoto.path),
          path: 'vehicle.jpg',
        );
        debugPrint('DEBUG: Vehicle Photo upload complete! URL: $vehiclePhotoUrl');
      } catch (e) {
        debugPrint('DEBUG: Vehicle Photo upload FAILED: $e');
        rethrow;
      }
    }

    debugPrint('DEBUG: All files uploaded. Calling syncRole...');
    return syncRole(
      role: 'captain',
      name: displayName.isNotEmpty ? displayName : null,
      phone: phone,
      cnic: cnic,
      cnicFrontUrl: cnicFrontUrl,
      cnicBackUrl: cnicBackUrl,
      vehicleMake: vehicleMake,
      vehicleModel: vehicleModel,
      vehicleColor: vehicleColor,
      vehicleRegistration: vehicleRegistration,
      vehicleYear: vehicleYear,
      vehicleSeats: vehicleSeats,
      city: city,
      photoUrl: photoUrl,
      vehiclePhotoUrl: vehiclePhotoUrl,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      captainVerificationStatus: 'pending_verification',
    );
  }

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    final response = await ApiService.patch('/auth/profile', data);
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final user = _userFromResponse(response['user'] as Map<String, dynamic>, uid);
    await _persistUser(user);
    return user;
  }
}