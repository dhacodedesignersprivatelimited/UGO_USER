// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'flutter_flow/flutter_flow_util.dart';

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
//       _fcmToken = prefs.getString('ff_fcmToken') ?? _fcmToken;
//     });
//   }

//   void update(VoidCallback callback) {
//     callback();
//     notifyListeners();
//   }

//   late SharedPreferences prefs;

//   String _pickuplocation = '';
//   String get pickuplocation => _pickuplocation;
//   set pickuplocation(String value) {
//     _pickuplocation = value;
//   }

//   String _droplocation = '';
//   String get droplocation => _droplocation;
//   set droplocation(String value) {
//     _droplocation = value;
//   }

//   LatLng? _droplongitude;
//   LatLng? get droplongitude => _droplongitude;
//   set droplongitude(LatLng? value) {
//     _droplongitude = value;
//   }

//   LatLng? _droplatitude;
//   LatLng? get droplatitude => _droplatitude;
//   set droplatitude(LatLng? value) {
//     _droplatitude = value;
//   }

//   String _vehicleselect = '';
//   String get vehicleselect => _vehicleselect;
//   set vehicleselect(String value) {
//     _vehicleselect = value;
//   }

//   String _accessToken = '';
//   String get accessToken => _accessToken;
//   set accessToken(String value) {
//     _accessToken = value;
//     prefs.setString('ff_accessToken', value);
//   }

//   int _userid = 0;
//   int get userid => _userid;
//   set userid(int value) {
//     _userid = value;
//     prefs.setInt('ff_userid', value);
//   }

//   LatLng? _pickuplatitude;
//   LatLng? get pickuplatitude => _pickuplatitude;
//   set pickuplatitude(LatLng? value) {
//     _pickuplatitude = value;
//   }

//   LatLng? _pickuplongitude;
//   LatLng? get pickuplongitude => _pickuplongitude;
//   set pickuplongitude(LatLng? value) {
//     _pickuplongitude = value;
//   }

//   bool _selectalocation = false;
//   bool get selectalocation => _selectalocation;
//   set selectalocation(bool value) {
//     _selectalocation = value;
//   }

//   String _fcmToken = '';
//   String get fcmToken => _fcmToken;
//   set fcmToken(String value) {
//     _fcmToken = value;
//     prefs.setString('ff_fcmToken', value);
//   }
// }

// void _safeInit(Function() initializeField) {
//   try {
//     initializeField();
//   } catch (_) {}
// }

// Future _safeInitAsync(Function() initializeField) async {
//   try {
//     await initializeField();
//   } catch (_) {}
// }
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';

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
  }



  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  late SharedPreferences prefs;

  // selectedlocation: true = pickup, false = drop
  bool _selectedlocation = false;
  bool get selectedlocation => _selectedlocation;
  set selectedlocation(bool value) {
    _selectedlocation = value;
    notifyListeners();
    print('selectedlocation updated: $value (${value ? "PICKUP" : "DROP"})');
  }

  // Pickup Location
  String _pickuplocation = '';
  String get pickuplocation => _pickuplocation;
  set pickuplocation(String value) {
    _pickuplocation = value;
    notifyListeners();
    print('pickuplocation updated: $value');
  }

  double? _pickupLatitude;
  double? get pickupLatitude => _pickupLatitude;
  set pickupLatitude(double? value) {
    _pickupLatitude = value;
    notifyListeners();
    print('pickupLatitude updated: $value');
  }

  double? _pickupLongitude;
  double? get pickupLongitude => _pickupLongitude;
  set pickupLongitude(double? value) {
    _pickupLongitude = value;
    notifyListeners();
    print('pickupLongitude updated: $value');
  }

  // Drop Location
  String _droplocation = '';
  String get droplocation => _droplocation;
  set droplocation(String value) {
    _droplocation = value;
    notifyListeners();
    print('droplocation updated: $value');
  }

  double? _dropLatitude;
  double? get dropLatitude => _dropLatitude;
  set dropLatitude(double? value) {
    _dropLatitude = value;
    notifyListeners();
    print('dropLatitude updated: $value');
  }

  double? _dropLongitude;
  double? get dropLongitude => _dropLongitude;
  set dropLongitude(double? value) {
    _dropLongitude = value;
    notifyListeners();
    print('dropLongitude updated: $value');
  }

  // Vehicle Selection
  String _vehicleselect = '';
  String get vehicleselect => _vehicleselect;
  set vehicleselect(String value) {
    _vehicleselect = value;
    notifyListeners();
    print('vehicleselect updated: $value');
  }

  // User Authentication
  String _accessToken = '';
  String get accessToken => _accessToken;
  set accessToken(String value) {
    _accessToken = value;
    prefs.setString('ff_accessToken', value);
    print('accessToken updated: $value');
  }

  bool _bookingInProgress = false;
  bool get bookingInProgress => _bookingInProgress;
  set bookingInProgress(bool value) {
    _bookingInProgress = value;
    prefs.setBool('ff_bookingInProgress', value);
    print('bookingInProgress updated: $value');
  }

  int _userid = 0;
  int get userid => _userid;
  set userid(int value) {
    _userid = value;
    prefs.setInt('ff_userid', value);
    print('userid updated: $value');
  }
   String _fcmToken = '';
  String get fcmToken => _fcmToken;
  set fcmToken(String value) {
    _fcmToken = value;
    prefs.setString('ff_fcmToken', value);
  }


  // Helper method to get API request body
  Map<String, dynamic> getRideRequestBody() {
    return {
      "user_id": _userid,
      "pickup_location_address": _pickuplocation,
      "pickup_latitude": _pickupLatitude,
      "pickup_longitude": _pickupLongitude,
      "drop_location_address": _droplocation,
      "drop_latitude": _dropLatitude,
      "drop_longitude": _dropLongitude,
      "ride_type": _vehicleselect,
    };
  }

  // Helper method to validate ride data
  bool isRideDataValid() {
    return _pickuplocation.isNotEmpty &&
        _pickupLatitude != null &&
        _pickupLongitude != null &&
        _droplocation.isNotEmpty &&
        _dropLatitude != null &&
        _dropLongitude != null &&
        _vehicleselect.isNotEmpty &&
        _userid > 0;
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
    notifyListeners();
  }
}

void _safeInit(Function() initializeField) {
  try {
    initializeField();
  } catch (_) {}
}

Future _safeInitAsync(Function() initializeField) async {
  try {
    await initializeField();
  } catch (_) {}
}