import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';

/// Local session only — backend team will replace with Firestore later.
/// Look for `SessionStorage` / keys prefixed with `car_pool_`.
class SessionStorage {
  SessionStorage._();

  static const _kLoggedIn = 'car_pool_session_logged_in';
  static const _kGoogleId = 'car_pool_google_id';
  static const _kEmail = 'car_pool_email';
  static const _kName = 'car_pool_name';
  static const _kPhotoUrl = 'car_pool_photo_url';
  static const _kRole = 'car_pool_role';
  static const _kCaptainPending = 'car_pool_captain_docs_pending';
  static const _kPhone = 'car_pool_phone';

  static Future<bool> isLoggedIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kLoggedIn) == true;
  }

  /// Null if user has not chosen Passenger/Captain yet (empty role string).
  static Future<String?> getRole() async {
    final p = await SharedPreferences.getInstance();
    final r = p.getString(_kRole);
    if (r == null || r.isEmpty) return null;
    return r;
  }

  static Future<void> saveGoogleAccount(GoogleSignInAccount account) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kLoggedIn, true);
    await p.setString(_kGoogleId, account.id);
    await p.setString(_kEmail, account.email);
    await p.setString(_kName, account.displayName ?? 'User');
    await p.setString(_kPhotoUrl, account.photoUrl ?? '');
  }

  /// Demo login (email/password UI) — no Google account.
  static Future<void> saveDemoUser({
    required String id,
    required String email,
    required String name,
  }) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kLoggedIn, true);
    await p.setString(_kGoogleId, id);
    await p.setString(_kEmail, email);
    await p.setString(_kName, name);
    await p.setString(_kPhotoUrl, '');
  }

  static Future<void> setRole(String role) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kRole, role);
  }

  static Future<void> setCaptainDocsPending(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kCaptainPending, value);
  }

  static Future<void> setPhone(String phone) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPhone, phone);
  }

  /// Builds [UserModel] from prefs. Uses role string from storage (may be empty).
  static Future<UserModel?> loadUserModel() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(_kLoggedIn) != true) return null;

    final id = p.getString(_kGoogleId);
    final roleRaw = p.getString(_kRole) ?? '';
    final pending = p.getBool(_kCaptainPending) ?? false;

    return UserModel(
      id: (id == null || id.isEmpty) ? 'local-user' : id,
      email: p.getString(_kEmail) ?? '',
      name: p.getString(_kName) ?? 'User',
      phone: p.getString(_kPhone) ?? '',
      role: roleRaw,
      photoUrl: _blankToNull(p.getString(_kPhotoUrl)),
      captainVerificationStatus:
          pending ? 'pending_verification' : null,
      isVerified: false,
      rating: 4.8,
      totalRides: 24,
      createdAt: DateTime.now(),
    );
  }

  static String? _blankToNull(String? s) {
    if (s == null || s.isEmpty) return null;
    return s;
  }

  static Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kLoggedIn);
    await p.remove(_kGoogleId);
    await p.remove(_kEmail);
    await p.remove(_kName);
    await p.remove(_kPhotoUrl);
    await p.remove(_kRole);
    await p.remove(_kCaptainPending);
    await p.remove(_kPhone);
  }
}



