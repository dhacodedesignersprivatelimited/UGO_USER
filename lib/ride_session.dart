class RideSession {
  static final RideSession _instance = RideSession._internal();
  factory RideSession() => _instance;
  RideSession._internal();

  Map<String, dynamic>? rideData;
  Map<String, dynamic>? driverData;

  void clear() {
    rideData = null;
    driverData = null;
  }
}
