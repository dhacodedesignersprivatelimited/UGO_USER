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

  /// ✅ Extract count (MOST IMPORTANT)
  static int? count(dynamic response) => castToType<int>(
        getJsonField(
          response,
          r'''$.data.count''',
        ),
      );

  /// ✅ Extract rides list
  static List? rides(dynamic response) => getJsonField(
        response,
        r'''$.data.rides''',
        true,
      ) as List?;

  /// ✅ Ride status (accepted / pending)
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

  /// ✅ Drop address
  static List<String?>? dropAddress(dynamic response) => (getJsonField(
        response,
        r'''$.data.rides[:].drop_location_address''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .toList();

  /// ✅ Pickup LatLng
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

class GetDriverDetailsCall {
  static Future<ApiCallResponse> call({
    required dynamic driverId,
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'getDriverDetails',
      apiUrl: 'https://ugotaxi.icacorp.org/api/drivers/$driverId',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $token',
      },
      params: {},
      returnBody: true,
      cache: false,
    );
  }

  static dynamic driverData(dynamic response) => getJsonField(
        response,
        r'''$.data''',
      );
  
  static String? driverName(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.name''',
      ));

  static String? vehicleNumber(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.vehicle.number''',
      ));

  static String? vehicleModel(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.data.vehicle.model''',
      ));
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
