import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      _userid = prefs.getInt('ff_userid') ?? _userid;
    });
    _safeInit(() {
      _bookingInProgress = prefs.getBool('ff_bookingInProgress') ?? _bookingInProgress;
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
  _dropLongitude =
      prefs.getDouble('ff_dropLongitude') ?? _dropLongitude;
});
_safeInit(() {
  _vehicleselect =
      prefs.getString('ff_vehicleselect') ?? _vehicleselect;
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

  // User Authentication
  String _accessToken = '';
  String get accessToken => _accessToken;
  set accessToken(String value) {
    _accessToken = value;
    prefs.setString('ff_accessToken', value);
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


  // Clear ride data
  void clearRideData() {
    _pickuplocation = '';
    _pickupLatitude = null;
    _pickupLongitude = null;
    _droplocation = '';
    _dropLatitude = null;
    _dropLongitude = null;
    _vehicleselect = '';
    _selectedlocation = false;
    _appliedCouponCode = '';
    _discountAmount = 0.0;
     _selectedBaseFare = 0.0;
  _selectedPricePerKm = 0.0;
  prefs.remove('ff_selectedBaseFare');
  prefs.remove('ff_selectedPricePerKm');
    notifyListeners();
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class FFAppState extends ChangeNotifier {
//   static FFAppState _instance = FFAppState._internal();

//   factory FFAppState() {
//     return _instance;
//   }

//   FFAppState._internal();

//   static void reset() {
//     _instance = FFAppState._internal();
//   }

//   Future initializePersistedState() async {
//     prefs = await SharedPreferences.getInstance();
//     _safeInit(() {
//       _accessToken = prefs.getString('ff_accessToken') ?? _accessToken;
//     });
//     _safeInit(() {
//       _userid = prefs.getInt('ff_userid') ?? _userid;
//     });
//     _safeInit(() {
//       _bookingInProgress = prefs.getBool('ff_bookingInProgress') ?? _bookingInProgress;
//     });
//     _safeInit(() {
//   _selectedBaseFare =
//       prefs.getDouble('ff_selectedBaseFare') ?? _selectedBaseFare;
// });

// _safeInit(() {
//   _selectedPricePerKm =
//       prefs.getDouble('ff_selectedPricePerKm') ?? _selectedPricePerKm;
// });

//   }

//   void update(VoidCallback callback) {
//     callback();
//     notifyListeners();
//   }

//   late SharedPreferences prefs;

//   // Voucher / Discount state
//   String _appliedCouponCode = '';
//   String get appliedCouponCode => _appliedCouponCode;
//   set appliedCouponCode(String value) {
//     _appliedCouponCode = value;
//     notifyListeners();
//   }

//   double _discountAmount = 0.0;
//   double get discountAmount => _discountAmount;
//   set discountAmount(double value) {
//     _discountAmount = value;
//     notifyListeners();
//   }

//   // selectedlocation: true = pickup, false = drop
//   bool _selectedlocation = false;
//   bool get selectedlocation => _selectedlocation;
//   set selectedlocation(bool value) {
//     _selectedlocation = value;
//     notifyListeners();
//   }

//   // Pickup Location
//   String _pickuplocation = '';
//   String get pickuplocation => _pickuplocation;
//   set pickuplocation(String value) {
//     _pickuplocation = value;
//     notifyListeners();
//   }

//   double? _pickupLatitude;
//   double? get pickupLatitude => _pickupLatitude;
//   set pickupLatitude(double? value) {
//     _pickupLatitude = value;
//     notifyListeners();
//   }

//   double? _pickupLongitude;
//   double? get pickupLongitude => _pickupLongitude;
//   set pickupLongitude(double? value) {
//     _pickupLongitude = value;
//     notifyListeners();
//   }

//   // Drop Location
//   String _droplocation = '';
//   String get droplocation => _droplocation;
//   set droplocation(String value) {
//     _droplocation = value;
//     notifyListeners();
//   }

//   double? _dropLatitude;
//   double? get dropLatitude => _dropLatitude;
//   set dropLatitude(double? value) {
//     _dropLatitude = value;
//     notifyListeners();
//   }

//   double? _dropLongitude;
//   double? get dropLongitude => _dropLongitude;
//   set dropLongitude(double? value) {
//     _dropLongitude = value;
//     notifyListeners();
//   }

//   // Vehicle Selection
//   String _vehicleselect = '';
//   String get vehicleselect => _vehicleselect;
//   set vehicleselect(String value) {
//     _vehicleselect = value;
//     notifyListeners();
//   }

//   // User Authentication
//   String _accessToken = '';
//   String get accessToken => _accessToken;
//   set accessToken(String value) {
//     _accessToken = value;
//     prefs.setString('ff_accessToken', value);
//   }

//   bool _bookingInProgress = false;
//   bool get bookingInProgress => _bookingInProgress;
//   set bookingInProgress(bool value) {
//     _bookingInProgress = value;
//     prefs.setBool('ff_bookingInProgress', value);
//   }

//   int _userid = 0;
//   int get userid => _userid;
//   set userid(int value) {
//     _userid = value;
//     prefs.setInt('ff_userid', value);
//   }

//   String _fcmToken = '';
//   String get fcmToken => _fcmToken;
//   set fcmToken(String value) {
//     _fcmToken = value;
//     prefs.setString('ff_fcmToken', value);
//   }
//   // Fare Details
// double _selectedBaseFare = 0.0;
// double get selectedBaseFare => _selectedBaseFare;
// set selectedBaseFare(double value) {
//   _selectedBaseFare = value;
//   prefs.setDouble('ff_selectedBaseFare', value);
//   notifyListeners();
// }

// double _selectedPricePerKm = 0.0;
// double get selectedPricePerKm => _selectedPricePerKm;
// set selectedPricePerKm(double value) {
//   _selectedPricePerKm = value;
//   prefs.setDouble('ff_selectedPricePerKm', value);
//   notifyListeners();
// }


//   // Clear ride data
//   void clearRideData() {
//     _pickuplocation = '';
//     _pickupLatitude = null;
//     _pickupLongitude = null;
//     _droplocation = '';
//     _dropLatitude = null;
//     _dropLongitude = null;
//     _vehicleselect = '';
//     _selectedlocation = false;
//     _appliedCouponCode = '';
//     _discountAmount = 0.0;
//     _selectedBaseFare = 0.0;
//   _selectedPricePerKm = 0.0;
//   prefs.remove('ff_selectedBaseFare');
//   prefs.remove('ff_selectedPricePerKm');
//     notifyListeners();
//   }
// }

// void _safeInit(Function() initializeField) {
//   try {
//     initializeField();
//   } catch (_) {}
// }
