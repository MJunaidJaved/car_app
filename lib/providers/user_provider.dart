import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/wallet_model.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;
  WalletModel? _wallet;
  bool _isLoading = false;

  UserModel? get currentUser => _currentUser;
  UserModel? get user => _currentUser;
  WalletModel? get wallet => _wallet;
  bool get isLoading => _isLoading;
  bool get isCaptain => _currentUser?.role == 'captain';
  bool get isCustomer =>
      _currentUser?.role == 'customer' || _currentUser?.role == 'passenger';

  void setUser(UserModel? user) {
    _currentUser = user;
    notifyListeners();
  }

  void setWallet(WalletModel? wallet) {
    _wallet = wallet;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void updateUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  void updateWallet(WalletModel wallet) {
    _wallet = wallet;
    notifyListeners();
  }

  void clear() {
    _currentUser = null;
    _wallet = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> reloadWallet() async {
    try {
      final res = await ApiService.get('/wallet');
      final data = res['wallet'] as Map<String, dynamic>?;
      if (data != null) {
        _wallet = WalletModel.fromMap(data);
        notifyListeners();
      }
    } catch (_) {}
  }
}
