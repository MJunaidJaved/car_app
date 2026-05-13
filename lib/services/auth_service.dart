import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';
import 'session_storage.dart';

/// Frontend-only auth: Google Sign-In + [SharedPreferences] via [SessionStorage].
/// No Firebase — backend will replace persistence later.
class AuthService {
  AuthService();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
  );

  /// Opens the Google account picker; persists profile to SharedPreferences on success.
  Future<UserModel?> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) return null;
    await SessionStorage.saveGoogleAccount(account);
    return SessionStorage.loadUserModel();
  }

  Future<UserModel?> restoreSession() => SessionStorage.loadUserModel();

  Future<UserModel?> getUserData(String uid) async {
    final u = await SessionStorage.loadUserModel();
    if (u == null || u.id != uid) return null;
    return u;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await SessionStorage.clear();
  }

  /// Passenger role — local only.
  Future<UserModel> savePassengerRoleAndProfile() async {
    await SessionStorage.setRole('passenger');
    final u = await SessionStorage.loadUserModel();
    if (u == null) {
      throw Exception('No session');
    }
    return u;
  }

  /// Demo email/password sign-in — 2s delay, sets role `passenger`, goes to Home in UI.
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    await _googleSignIn.signOut();
    await SessionStorage.clear();
    await SessionStorage.saveDemoUser(
      id: 'demo-${email.hashCode}',
      email: email,
      name: email.split('@').first,
    );
    await SessionStorage.setRole('passenger');
    final u = await SessionStorage.loadUserModel();
    if (u == null) throw Exception('Session failed');
    return u;
  }

  /// Demo sign-up — 2s delay, no role yet (Role Select in UI).
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String role,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));
    await SessionStorage.clear();
    await SessionStorage.saveDemoUser(
      id: 'demo-${email.hashCode}',
      email: email,
      name: name,
    );
    await SessionStorage.setPhone(phone);
    final u = await SessionStorage.loadUserModel();
    if (u == null) throw Exception('Session failed');
    return u;
  }

  // --- Stubs kept for legacy screens (captain phone / app gate). Safe no-ops. ---

  Future<void> signInOrRestoreCustomerSession() async {}

  Future<void> ensureCustomerUserDocument(String uid) async {}

  Future<void> ensureWallet(String uid) async {}

  Future<bool> captainProfileExists() async => false;

  Future<void> completeCaptainRegistrationFromPhone({
    required String name,
    required String cnic,
    required String vehicleName,
    required String vehicleNumber,
  }) async {}

  void startCaptainPhoneVerification({
    required String e164Phone,
    required void Function(String verificationId) onCodeSent,
    required void Function(Object error) onError,
    required Future<void> Function(dynamic credential) onAutoVerified,
  }) {}

  Future<void> signInCaptainWithSms({
    required String verificationId,
    required String smsCode,
  }) async {}

  Future<void> signInWithPhoneCredential(dynamic credential) async {}

  Future<void> resetPassword(String email) async {}

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {}
}
