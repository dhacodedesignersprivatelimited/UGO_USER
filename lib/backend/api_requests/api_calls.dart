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
      apiUrl: 'http://www.ugotaxi.com/api/users/post',
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
      apiUrl: 'http://www.ugotaxi.com/api/users/login',
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
      apiUrl: 'http://www.ugotaxi.com/api/admins/api/admins/vehicles',
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
      apiUrl: 'http://www.ugotaxi.com/api/rides/post',
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
      apiUrl: 'http://www.ugotaxi.com/api/saved-addresses/post',
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
