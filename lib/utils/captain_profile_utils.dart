import '../models/user_model.dart';

class CaptainProfileItem {
  final String label;
  final bool complete;

  CaptainProfileItem({required this.label, required this.complete});
}

class CaptainProfileUtils {
  static bool isVerified(UserModel? user) {
    if (user == null) return false;
    final status = user.captainVerificationStatus;
    return status == 'verified' || status == 'approved' || user.isVerified;
  }

  static List<CaptainProfileItem> checklist(UserModel? user) {
    if (user == null) return [];

    return [
      CaptainProfileItem(
        label: 'CNIC uploaded',
        complete: (user.cnicFrontUrl?.isNotEmpty ?? false) &&
            (user.cnicBackUrl?.isNotEmpty ?? false) &&
            (user.cnic?.isNotEmpty ?? false),
      ),
      CaptainProfileItem(
        label: 'Vehicle details filled',
        complete: _hasText(user.vehicleMake) &&
            _hasText(user.vehicleModel) &&
            _hasText(user.vehicleColor) &&
            _hasText(user.vehicleRegistration),
      ),
      // ✅ Profile Photo Removed - No longer required
      // CaptainProfileItem(
      //   label: 'Profile photo',
      //   complete: user.photoUrl?.isNotEmpty ?? false,
      // ),
      CaptainProfileItem(
        label: 'Phone number',
        complete: _isValidPakPhone(user.phone),
      ),
      CaptainProfileItem(
        label: 'City selected',
        complete: user.city?.isNotEmpty ?? false,
      ),
      CaptainProfileItem(
        label: 'Car photo',
        complete: user.vehiclePhotoUrl?.isNotEmpty ?? false,
      ),
      CaptainProfileItem(
        label: 'Admin verification',
        complete: isVerified(user),
      ),
    ];
  }

  static bool isProfileComplete(UserModel? user) {
    final items = checklist(user);
    return items.every((i) => i.complete);
  }

  static bool _hasText(String? v) => v != null && v.trim().isNotEmpty;

  static bool _isValidPakPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length == 11 && digits.startsWith('03');
  }
}