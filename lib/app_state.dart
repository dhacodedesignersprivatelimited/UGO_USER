import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {
    prefs = await SharedPreferences.getInstance();
    _safeInit(() {
      _accessToken = prefs.getString('ff_accessToken') ?? _accessToken;
    });
    _safeInit(() {
      _refreshToken = prefs.getString('ff_refreshToken') ?? _refreshToken;
    });
    _safeInit(() {
      _userid = prefs.getInt('ff_userid') ?? _userid;
    });
    _safeInit(() {
      _bookingInProgress =
          prefs.getBool('ff_bookingInProgress') ?? _bookingInProgress;
    });
    _safeInit(() {
      _pickupLatitude =
          prefs.getDouble('ff_pickupLatitude') ?? _pickupLatitude;
    });
    _safeInit(() {
      _pickupLongitude =
          prefs.getDouble('ff_pickupLongitude') ?? _pickupLongitude;
    });
    _safeInit(() {
      _droplocation = prefs.getString('ff_droplocation') ?? _droplocation;
    });
    _safeInit(() {
      _dropLatitude = prefs.getDouble('ff_dropLatitude') ?? _dropLatitude;
    });
    _safeInit(() {
      _selectedBaseFare =
          prefs.getDouble('ff_selectedBaseFare') ?? _selectedBaseFare;
    });
    _safeInit(() {
      _selectedPricePerKm =
          prefs.getDouble('ff_selectedPricePerKm') ?? _selectedPricePerKm;
    });
    _safeInit(() {
      _dropLongitude = prefs.getDouble('ff_dropLongitude') ?? _dropLongitude;
    });
    _safeInit(() {
      _vehicleselect = prefs.getString('ff_vehicleselect') ?? _vehicleselect;
    });
    _safeInit(() {
      _currentRideId = prefs.getInt('ff_currentRideId');
    });
    _safeInit(() {
      _selectedPaymentMethod =
          prefs.getString('ff_selectedPaymentMethod') ?? _selectedPaymentMethod;
    });
    _safeInit(() {
      _walletBalance = prefs.getDouble('ff_walletBalance') ?? _walletBalance;
    });
    _safeInit(() {
      _coinsBalance = prefs.getInt('ff_coinsBalance') ?? _coinsBalance;
    });
    _safeInit(() {
      _recentSearches = prefs.getStringList('ff_recentSearches') ?? _recentSearches;
    });
    _safeInit(() {
      _selectedBaseKmStart =
          prefs.getDouble('ff_selectedBaseKmStart') ?? _selectedBaseKmStart;
    });
    _safeInit(() {
      _selectedBaseKmEnd =
          prefs.getDouble('ff_selectedBaseKmEnd') ?? _selectedBaseKmEnd;
    });
    _safeInit(() {
      _firebaseUid = prefs.getString('ff_firebaseUid') ?? _firebaseUid;
    });
  }

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  // Voucher / Discount state
  String _appliedCouponCode = '';
  String get appliedCouponCode => _appliedCouponCode;
  set appliedCouponCode(String value) {
    _appliedCouponCode = value;
    notifyListeners();
  }

  double _discountAmount = 0.0;
  double get discountAmount => _discountAmount;
  set discountAmount(double value) {
    _discountAmount = value;
    notifyListeners();
  }

  // selectedlocation: true = pickup, false = drop
  bool _selectedlocation = false;
  bool get selectedlocation => _selectedlocation;
  set selectedlocation(bool value) {
    _selectedlocation = value;
    notifyListeners();
  }

  // Pickup Location
  String _pickuplocation = '';
  String get pickuplocation => _pickuplocation;
  set pickuplocation(String value) {
    _pickuplocation = value;
    notifyListeners();
  }

  // Current Ride OTP (Secure Ride Start)
  String currentRideOtp = '';

  // Current Ride ID
  int? _currentRideId;
  int? get currentRideId => _currentRideId;
  set currentRideId(int? value) {
    _currentRideId = value;
    if (value == null) {
      prefs.remove('ff_currentRideId');
    } else {
      prefs.setInt('ff_currentRideId', value);
    }
    notifyListeners();
  }

  double? _pickupLatitude;
  double? get pickupLatitude => _pickupLatitude;
  set pickupLatitude(double? value) {
    _pickupLatitude = value;
    prefs.setDouble('ff_pickupLatitude', value ?? 0.0);
    notifyListeners();
  }

  double? _pickupLongitude;
  double? get pickupLongitude => _pickupLongitude;
  set pickupLongitude(double? value) {
    _pickupLongitude = value;
    prefs.setDouble('ff_pickupLongitude', value ?? 0.0);
    notifyListeners();
  }

  // Drop Location
  String _droplocation = '';
  String get droplocation => _droplocation;
  set droplocation(String value) {
    _droplocation = value;
    prefs.setString('ff_droplocation', value);
    notifyListeners();
  }

  double? _dropLatitude;
  double? get dropLatitude => _dropLatitude;
  set dropLatitude(double? value) {
    _dropLatitude = value;
    prefs.setDouble('ff_dropLatitude', value ?? 0.0);
    notifyListeners();
  }

  double? _dropLongitude;
  double? get dropLongitude => _dropLongitude;
  set dropLongitude(double? value) {
    _dropLongitude = value;
    prefs.setDouble('ff_dropLongitude', value ?? 0.0);
    notifyListeners();
  }

  // Vehicle Selection
  String _vehicleselect = '';
  String get vehicleselect => _vehicleselect;
  set vehicleselect(String value) {
    _vehicleselect = value;
    notifyListeners();
  }

  // Ride category for home cards: 'bike', 'car', 'auto' (null = show all)
  String? _selectedRideCategory;
  String? get selectedRideCategory => _selectedRideCategory;
  set selectedRideCategory(String? value) {
    _selectedRideCategory = value;
    notifyListeners();
  }

  // User Authentication
  String _accessToken = '';
  String get accessToken => _accessToken;
  set accessToken(String value) {
    _accessToken = value;
    prefs.setString('ff_accessToken', value);
  }

  String _refreshToken = '';
  String get refreshToken => _refreshToken;
  set refreshToken(String value) {
    _refreshToken = value;
    prefs.setString('ff_refreshToken', value);
  }

  bool _bookingInProgress = false;
  bool get bookingInProgress => _bookingInProgress;
  set bookingInProgress(bool value) {
    _bookingInProgress = value;
    prefs.setBool('ff_bookingInProgress', value);
  }

  int _userid = 0;
  int get userid => _userid;
  set userid(int value) {
    _userid = value;
    prefs.setInt('ff_userid', value);
  }

  String _fcmToken = '';
  String get fcmToken => _fcmToken;
  set fcmToken(String value) {
    _fcmToken = value;
    prefs.setString('ff_fcmToken', value);
  }

  String _firebaseUid = '';
  String get firebaseUid => _firebaseUid;
  set firebaseUid(String value) {
    _firebaseUid = value;
    prefs.setString('ff_firebaseUid', value);
  }

  double _selectedBaseFare = 0.0;
  double get selectedBaseFare => _selectedBaseFare;
  set selectedBaseFare(double value) {
    _selectedBaseFare = value;
    prefs.setDouble('ff_selectedBaseFare', value);
    notifyListeners();
  }

  double _selectedPricePerKm = 0.0;
  double get selectedPricePerKm => _selectedPricePerKm;
  set selectedPricePerKm(double value) {
    _selectedPricePerKm = value;
    prefs.setDouble('ff_selectedPricePerKm', value);
    notifyListeners();
  }

  double _selectedBaseKmStart = 1.0;
  double get selectedBaseKmStart => _selectedBaseKmStart;
  set selectedBaseKmStart(double value) {
    _selectedBaseKmStart = value;
    prefs.setDouble('ff_selectedBaseKmStart', value);
    notifyListeners();
  }

  double _selectedBaseKmEnd = 5.0;
  double get selectedBaseKmEnd => _selectedBaseKmEnd;
  set selectedBaseKmEnd(double value) {
    _selectedBaseKmEnd = value;
    prefs.setDouble('ff_selectedBaseKmEnd', value);
    notifyListeners();
  }

  String _selectedPaymentMethod = 'cash';
  String get selectedPaymentMethod => _selectedPaymentMethod;
  set selectedPaymentMethod(String value) {
    _selectedPaymentMethod = value;
    prefs.setString('ff_selectedPaymentMethod', value);
    notifyListeners();
  }

  // ✅ ADDED: Wallet Balance
  double _walletBalance = 0.0;
  double get walletBalance => _walletBalance;
  set walletBalance(double value) {
    _walletBalance = value;
    prefs.setDouble('ff_walletBalance', value);
    notifyListeners();
  }

  /// Referral reward coins from backend (10 coins = ₹1 off rides).
  int _coinsBalance = 0;
  int get coinsBalance => _coinsBalance;
  /// Rupee value of coins for display only (not withdrawable cash).
  double get referralCoinsValueRs => _coinsBalance / 10.0;
  set coinsBalance(int value) {
    _coinsBalance = value < 0 ? 0 : value;
    prefs.setInt('ff_coinsBalance', _coinsBalance);
    notifyListeners();
  }

  // Dynamic Recent Searches
  List<String> _recentSearches = [];
  List<String> get recentSearches => _recentSearches;
  set recentSearches(List<String> value) {
    _recentSearches = value;
    prefs.setStringList('ff_recentSearches', value);
    notifyListeners();
  }

  void addToRecentSearches(Map<String, dynamic> location) {
    final String encoded = jsonEncode({
      'name': location['name'] ?? '',
      'address': location['address'] ?? '',
      'lat': (location['lat'] as num?)?.toDouble() ?? 0.0,
      'lng': (location['lng'] as num?)?.toDouble() ?? 0.0,
      'icon_name': location['icon_name'] ?? 'history',
    });
    
    _recentSearches.removeWhere((item) {
      try {
        final decoded = jsonDecode(item);
        return decoded['address'] == location['address'];
      } catch (_) {
        return false;
      }
    });
    
    _recentSearches.insert(0, encoded);
    
    if (_recentSearches.length > 10) {
      _recentSearches = _recentSearches.sublist(0, 10);
    }
    
    prefs.setStringList('ff_recentSearches', _recentSearches);
    notifyListeners();
  }

  // Notification Check
  DateTime? lastNotificationCheckTime;

  // Clear ride data
  void clearRideData() {
    _pickuplocation = '';
    _pickupLatitude = null;
    _pickupLongitude = null;
    _droplocation = '';
    _dropLatitude = null;
    _dropLongitude = null;
    _vehicleselect = '';
    _selectedRideCategory = null;
    _selectedlocation = false;
    _appliedCouponCode = '';
    _discountAmount = 0.0;
    _selectedBaseFare = 0.0;
    _selectedPricePerKm = 0.0;
    _selectedBaseKmStart = 1.0;
    _selectedBaseKmEnd = 5.0;
    prefs.remove('ff_selectedBaseFare');
    prefs.remove('ff_selectedPricePerKm');
    prefs.remove('ff_selectedBaseKmStart');
    prefs.remove('ff_selectedBaseKmEnd');
    _selectedPaymentMethod = 'cash';
    prefs.remove('ff_selectedPaymentMethod');
    currentRideOtp = '';
    _currentRideId = null;
    prefs.remove('ff_currentRideId');
    notifyListeners();
  }

  void clearAuthSession() {
    _accessToken = '';
    _refreshToken = '';
    _userid = 0;
    _coinsBalance = 0;
    prefs.remove('ff_accessToken');
    prefs.remove('ff_refreshToken');
    prefs.remove('ff_userid');
    prefs.remove('ff_coinsBalance');
    notifyListeners();
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}