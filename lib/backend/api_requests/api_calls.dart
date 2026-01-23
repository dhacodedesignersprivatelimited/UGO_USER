import 'dart:convert';
import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

class CreateUserCall {
  static Future<ApiCallResponse> call({
    int? mobileNumber,
    String? firstName = '',
    String? lastName = '',
    String? email = '',
    FFUploadedFile? profileImage,
    String? fcmToken,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'createUser',
      apiUrl: 'https://ugotaxi.icacorp.org/api/users/post',
      callType: ApiCallType.POST,
      headers: {},
      params: {
        'mobile_number': mobileNumber,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'profile_image': profileImage,
        'fcm_token': fcmToken,
      },
      bodyType: BodyType.MULTIPART,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class LoginCall {
  static Future<ApiCallResponse> call({
    int? mobile,
    String? fcmToken = '',
  }) async {
    final ffApiRequestBody = '''
{
  "mobile_number": "${mobile}",
  "fcm_token": "${fcmToken}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'login',
      apiUrl: 'https://ugotaxi.icacorp.org/api/users/login',
      callType: ApiCallType.POST,
      headers: {},
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? accesToken(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.accessToken''',
      ));
  static int? userid(dynamic response) => castToType<int>(getJsonField(
    response,
    r'''$.data.user.id''',
  ));
}

class GetVehicleDetailsCall {
  static Future<ApiCallResponse> call() async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetVehicleDetails',
      apiUrl: 'https://ugotaxi.icacorp.org/api/admins/api/admins/vehicles',
      callType: ApiCallType.GET,
      headers: {},
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static List? data(dynamic response) => getJsonField(
    response,
    r'''$.data''',
    true,
  ) as List?;
  static List<String>? vehiclename(dynamic response) => (getJsonField(
    response,
    r'''$.data[:].vehicle_name''',
    true,
  ) as List?)
      ?.withoutNulls
      .map((x) => castToType<String>(x))
      .withoutNulls
      .toList();
  static List<String>? vehicletype(dynamic response) => (getJsonField(
    response,
    r'''$.data[:].vehicle_type''',
    true,
  ) as List?)
      ?.withoutNulls
      .map((x) => castToType<String>(x))
      .withoutNulls
      .toList();
  static List<double>? price(dynamic response) => (getJsonField(
    response,
    r'''$.data[:].kilometer_per_price''',
    true,
  ) as List?)
      ?.withoutNulls
      .map((x) => castToType<double>(x))
      .withoutNulls
      .toList();
  static List<int>? seating(dynamic response) => (getJsonField(
    response,
    r'''$.data[:].seating_capacity''',
    true,
  ) as List?)
      ?.withoutNulls
      .map((x) => castToType<int>(x))
      .withoutNulls
      .toList();
  static List<int>? luggage(dynamic response) => (getJsonField(
    response,
    r'''$.data[:].luggage_capacity''',
    true,
  ) as List?)
      ?.withoutNulls
      .map((x) => castToType<int>(x))
      .withoutNulls
      .toList();
  static List<String>? vehicleimage(dynamic response) => (getJsonField(
    response,
    r'''$.data[:].vehicle_image''',
    true,
  ) as List?)
      ?.withoutNulls
      .map((x) => castToType<String>(x))
      .withoutNulls
      .toList();
  static List<String>? vehicleurl(dynamic response) => (getJsonField(
    response,
    r'''$.data[:].vehicle_image_url''',
    true,
  ) as List?)
      ?.withoutNulls
      .map((x) => castToType<String>(x))
      .withoutNulls
      .toList();
}

class GetRideStatus {
  static Future<ApiCallResponse> call({
    required int userId,
    String? token,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetRideStatus',
      apiUrl:
      'https://ugotaxi.icacorp.org/api/rides/users/$userId/pending-rides',
      callType: ApiCallType.GET,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {},
      returnBody: true,
      cache: false,
    );
  }

  static int? count(dynamic response) => castToType<int>(
    getJsonField(
      response,
      r'''$.data.count''',
    ),
  );

  static List? rides(dynamic response) => getJsonField(
    response,
    r'''$.data.rides''',
    true,
  ) as List?;

  static List<String>? rideStatus(dynamic response) {
    final list = getJsonField(
      response,
      r'''$.data.rides[:].ride_status''',
      true,
    ) as List?;

    return list
        ?.where((e) => e != null)
        .map((e) => e.toString())
        .toList();
  }

  static List<String?>? dropAddress(dynamic response) => (getJsonField(
    response,
    r'''$.data.rides[:].drop_location_address''',
    true,
  ) as List?)
      ?.withoutNulls
      .map((x) => castToType<String>(x))
      .toList();

  static List<double>? pickupLat(dynamic response) {
    final list = getJsonField(
      response,
      r'''$.data.rides[:].pickup_latitude''',
      true,
    ) as List?;

    return list
        ?.where((e) => e != null)
        .map((e) => double.parse(e.toString()))
        .toList();
  }

  static List<double>? pickupLng(dynamic response) => (getJsonField(
    response,
    r'''$.data.rides[:].pickup_longitude''',
    true,
  ) as List?)
      ?.map((x) => double.parse(x.toString()))
      .toList();
}

class GetRideDetailsCall {
  static Future<ApiCallResponse> call({
    required int rideId,
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'getRideDetails',
      apiUrl: 'https://ugotaxi.icacorp.org/api/rides/$rideId',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $token',
      },
      params: {},
      returnBody: true,
      cache: false,
    );
  }
}

class CreateRideCall {
  static Future<ApiCallResponse> call({
    int? userId,
    String? pickuplocation = '',
    String? droplocation = '',
    String? ridetype = '',
    String? token = '',
    double? pickuplat,
    double? pickuplon,
    double? droplat,
    double? droplon,

  }) async {
    print('Bearer ${token}');
    final ffApiRequestBody = '''
{
  "user_id": "${userId}",
  "pickup_location_address": "${escapeStringForJson(pickuplocation)}",
  "drop_location_address": "${escapeStringForJson(droplocation)}",
  "drop_latitude": "${droplon}",
  "drop_longitude": "${droplat}",
  "ride_type": "${escapeStringForJson(ridetype)}",
 "pickup_latitude":"${pickuplat}",
  "pickup_longitude": "${pickuplon}"
  
}''';
    return ApiManager.instance.makeApiCall(

      callName: 'createRide',
      apiUrl: 'https://ugotaxi.icacorp.org/api/rides/post',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${token}',

      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

// ---------------------------------------------------------------------------
// ✅ DriverIdfetchCall CLASS DEFINITION (Added this missing class)
// ---------------------------------------------------------------------------
class DriverIdfetchCall {
  static Future<ApiCallResponse> call({
    String? token = '',
    int? id,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'driverIdfetch',
      apiUrl: 'https://ugotaxi.icacorp.org/api/drivers/${id}',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer ${token}',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static bool? isonline(dynamic response) => castToType<bool>(getJsonField(
    response,
    r'''$.data.is_online''',
  ));
  static String? kycstatus(dynamic response) => castToType<String>(getJsonField(
    response,
    r'''$.data.kyc_status''',
  ));
  static dynamic driverData(dynamic response) => getJsonField(
    response,
    r'''$.data''',
  );
  static String? referralCode(dynamic response) => castToType<String>(getJsonField(
    response,
    r'''$.data.referral_code''',
  ));

  /// Get profile image URL
  static String? profileImage(dynamic response) => castToType<String>(getJsonField(
    response,
    r'''$.data.profile_image''',
  ));

  /// Get license image URL
  static String? licenseImage(dynamic response) => castToType<String>(getJsonField(
    response,
    r'''$.data.license_image''',
  ));

  /// Get aadhaar image URL
  static String? aadhaarImage(dynamic response) => castToType<String>(getJsonField(
    response,
    r'''$.data.aadhaar_image''',
  ));

  /// Get PAN image URL
  static String? panImage(dynamic response) => castToType<String>(getJsonField(
    response,
    r'''$.data.pan_image''',
  ));

  /// Get vehicle image URL
  static String? vehicleImage(dynamic response) => castToType<String>(getJsonField(
    response,
    r'''$.data.vehicle_image''',
  ));

  /// Get RC image URL
  static String? rcImage(dynamic response) => castToType<String>(getJsonField(
    response,
    r'''$.data.rc_image''',
  ));

  /// Get driver first name
  static String? firstName(dynamic response) => castToType<String>(getJsonField(
    response,
    r'''$.data.first_name''',
  ));

  /// Get driver last name
  static String? lastName(dynamic response) => castToType<String>(getJsonField(
    response,
    r'''$.data.last_name''',
  ));

  /// Get driver email
  static String? email(dynamic response) => castToType<String>(getJsonField(
    response,
    r'''$.data.email''',
  ));

  /// Get driver mobile number
  static String? mobileNumber(dynamic response) => castToType<String>(getJsonField(
    response,
    r'''$.data.mobile_number''',
  ));

  /// Get wallet balance
  static String? walletBalance(dynamic response) => castToType<String>(getJsonField(
    response,
    r'''$.data.wallet_balance''',
  ));

  /// Get driver rating
  static String? driverRating(dynamic response) => castToType<String>(getJsonField(
    response,
    r'''$.data.driver_rating''',
  ));

  /// Get total rides completed
  static int? totalRidesCompleted(dynamic response) => castToType<int>(getJsonField(
    response,
    r'''$.data.total_rides_completed''',
  ));

  /// Get total earnings
  static String? totalEarnings(dynamic response) => castToType<String>(getJsonField(
    response,
    r'''$.data.total_earnings''',
  ));

  /// Check if driver is active
  static bool? isActive(dynamic response) => castToType<bool>(getJsonField(
    response,
    r'''$.data.is_active''',
  ));

  /// Get account status
  static String? accountStatus(dynamic response) => castToType<String>(getJsonField(
    response,
    r'''$.data.account_status''',
  ));
}

// ---------------------------------------------------------------------------
// ✅ GetDriverDetailsCall WRAPPER (Now correctly references DriverIdfetchCall)
// ---------------------------------------------------------------------------
class GetDriverDetailsCall {
  static Future<ApiCallResponse> call({
    required dynamic driverId,
    String? token = '',
  }) async {
    return DriverIdfetchCall.call(
      id: driverId is int ? driverId : int.tryParse(driverId.toString()),
      token: token,
    );
  }

  // ✅ DRIVER PERSONAL INFO (from DriverIdfetchCall - nested under $.data)
  static String? name(dynamic response) {
    final firstName = DriverIdfetchCall.firstName(response) ?? '';
    final lastName = DriverIdfetchCall.lastName(response) ?? '';

    if (firstName.isNotEmpty && lastName.isNotEmpty) {
      return '$firstName $lastName';
    } else if (firstName.isNotEmpty) {
      return firstName;
    } else if (lastName.isNotEmpty) {
      return lastName;
    }
    return 'Captain';
  }

  static String? rating(dynamic response) =>
      DriverIdfetchCall.driverRating(response) ?? '4.8';

  static int? totalRides(dynamic response) =>
      DriverIdfetchCall.totalRidesCompleted(response) ?? 0;

  static String? profileImage(dynamic response) {
    final imagePath = DriverIdfetchCall.profileImage(response);
    if (imagePath != null && imagePath.isNotEmpty) {
      return imagePath.startsWith('http')
          ? imagePath
          : 'https://ugotaxi.icacorp.org/$imagePath';
    }
    return null;
  }

  // ✅ VEHICLE INFO (from ride response - flat structure)
  // These are from the ride's vehicle object you showed in Postman
  static String? vehicleModel(dynamic response) {
    // Check root level first (your Postman response)
    var model = castToType<String>(getJsonField(response, r'''$.vehicle_model'''));
    if (model != null) return model;

    // Check data wrapper (DriverIdfetchCall response)
    model = castToType<String>(getJsonField(response, r'''$.data.vehicle_model'''));
    if (model != null) return model;

    return 'Auto'; // ✅ Fallback
  }

  static String? vehicleNumber(dynamic response) {
    // Try license_plate first
    var number = castToType<String>(getJsonField(response, r'''$.license_plate'''));
    if (number != null) return number;

    // Try registration_number
    number = castToType<String>(getJsonField(response, r'''$.registration_number'''));
    if (number != null) return number;

    // Check data wrapper
    number = castToType<String>(getJsonField(response, r'''$.data.license_plate'''));
    if (number != null) return number;

    return 'AP-00-XX-0000'; // ✅ Fallback
  }

  static String? vehicleType(dynamic response) {
    var type = castToType<String>(getJsonField(response, r'''$.vehicle_type'''));
    type ??= castToType<String>(getJsonField(response, r'''$.vehicle_name'''));
    return type ?? 'Auto';
  }

  static String? vehicleStatus(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.vehicle_status''')) ??
          'pending_verification';

  // ✅ ADDITIONAL HELPFUL METHODS
  static bool? isOnline(dynamic response) =>
      DriverIdfetchCall.isonline(response);

  static String? kycStatus(dynamic response) =>
      DriverIdfetchCall.kycstatus(response);

  static bool? isActive(dynamic response) =>
      DriverIdfetchCall.isActive(response);

  static String? walletBalance(dynamic response) =>
      DriverIdfetchCall.walletBalance(response);

  static String? accountStatus(dynamic response) =>
      DriverIdfetchCall.accountStatus(response);
}

class GetNearbyDriversCall {
  static Future<ApiCallResponse> call({
    double? lat,
    double? lon,
    double? radius = 5.0, // km
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'getNearbyDrivers',
      apiUrl: 'https://ugotaxi.icacorp.org/api/drivers/nearby',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $token',
      },
      params: {
        'latitude': lat,
        'longitude': lon,
        'radius': radius,
      },
      returnBody: true,
      cache: false,
    );
  }
}

class SaveAddressCall {
  static Future<ApiCallResponse> call({
    int? userId,
    String? addressLabel = '',
    String? addressText = '',
    double? latitude,
    double? longitude,
    String? token = '',
  }) async {
    final ffApiRequestBody = '''
{
  "user_id": ${userId},
  "address_label": "${escapeStringForJson(addressLabel)}",
  "address_text": "${escapeStringForJson(addressText)}",
  "latitude": ${latitude},
  "longitude": ${longitude}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'SaveAddress',
      apiUrl: 'https://ugotaxi.icacorp.org/api/saved-addresses/post',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${token}',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  // Parse response data
  static int? addressId(dynamic response) => castToType<int>(getJsonField(
    response,
    r'''$.data.id''',
  ));

  static String? message(dynamic response) => castToType<String>(getJsonField(
    response,
    r'''$.message''',
  ));

  static bool? success(dynamic response) => castToType<bool>(getJsonField(
    response,
    r'''$.success''',
  ));

  static String? addressType(dynamic response) => castToType<String>(getJsonField(
    response,
    r'''$.data.address_type''',
  ));

  static bool? isDefault(dynamic response) => castToType<bool>(getJsonField(
    response,
    r'''$.data.is_default''',
  ));
}

// ✅ FIXED CANCEL RIDE CALL
class CancelRide {
  static Future<ApiCallResponse> call({
    required int rideId,           // ✅ Made required
    String? cancellationReason,    // ✅ Renamed for consistency
    String? token = '',
    String? cancelledBy = 'user',  // ✅ Defaulted to 'user'
  }) async {
    final ffApiRequestBody = '''
{
  "ride_id": ${rideId},
  "cancellation_reason": "${escapeStringForJson(cancellationReason ?? '')}",
  "cancelled_by": "${escapeStringForJson(cancelledBy ?? 'user')}"
}'''; // ✅ FIXED: Added missing commas & proper JSON structure

    return ApiManager.instance.makeApiCall(
      callName: 'cancelRide',
      apiUrl: 'https://ugotaxi.icacorp.org/api/rides/rides/cancel',
      callType: ApiCallType.PATCH,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json', // ✅ Added content type
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
    );
  }

  // ✅ Added Response Helper Methods
  static bool? success(dynamic response) => castToType<bool>(
    getJsonField(response, r'''$.success'''),
  );

  static String? message(dynamic response) => castToType<String>(
    getJsonField(response, r'''$.message'''),
  );
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}
