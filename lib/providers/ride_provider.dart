import 'package:flutter/foundation.dart';
import '../models/ride_model.dart';
import '../models/deal_model.dart';

class RideProvider with ChangeNotifier {
  List<RideModel> _availableRides = [];
  List<RideModel> _myRides = [];
  List<DealModel> _myDeals = [];
  List<DealModel> _pendingRequests = [];
  bool _isLoading = false;
  String? _selectedRideType = 'all';

  List<RideModel> get availableRides => _availableRides;
  List<RideModel> get myRides => _myRides;
  List<DealModel> get myDeals => _myDeals;
  List<DealModel> get pendingRequests => _pendingRequests;
  bool get isLoading => _isLoading;
  String? get selectedRideType => _selectedRideType;

  void setAvailableRides(List<RideModel> rides) {
    _availableRides = rides;
    notifyListeners();
  }

  void setMyRides(List<RideModel> rides) {
    _myRides = rides;
    notifyListeners();
  }

  void setMyDeals(List<DealModel> deals) {
    _myDeals = deals;
    notifyListeners();
  }

  void setPendingRequests(List<DealModel> requests) {
    _pendingRequests = requests;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setRideType(String? type) {
    _selectedRideType = type;
    notifyListeners();
  }

  List<RideModel> getFilteredRides() {
    if (_selectedRideType == null || _selectedRideType == 'all') {
      return _availableRides;
    }
    return _availableRides.where((ride) => ride.rideType == _selectedRideType).toList();
  }

  void clear() {
    _availableRides = [];
    _myRides = [];
    _myDeals = [];
    _pendingRequests = [];
    _isLoading = false;
    _selectedRideType = 'all';
    notifyListeners();
  }
}



