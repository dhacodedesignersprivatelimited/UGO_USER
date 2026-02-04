import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

/// ---------------------------------------------------------------------------
/// USER MANAGEMENT
/// ---------------------------------------------------------------------------

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

class GetUserDetailsCall {
  static Future<ApiCallResponse> call({
    required int userId,
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'getUserDetails',
      apiUrl: 'https://ugotaxi.icacorp.org/api/users/$userId',
      callType: ApiCallType.GET,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {},
      returnBody: true,
      cache: false,
    );
  }

  // ---------- Root helpers ----------
  static dynamic dataRoot(dynamic response) =>
      getJsonField(response, r'''$.data''');
  static int? id(dynamic response) =>
      castToType<int>(getJsonField(response, r'''$.data.id''')) ??
          castToType<int>(getJsonField(response, r'''$.data[0].id'''));
  static String? mobileNumber(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.data.mobile_number''')) ??
          castToType<String>(
              getJsonField(response, r'''$.data[0].mobile_number'''));
  static String? firstName(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.data.first_name''')) ??
          castToType<String>(getJsonField(response, r'''$.data[0].first_name'''));
  static String? lastName(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.data.last_name''')) ??
          castToType<String>(getJsonField(response, r'''$.data[0].last_name'''));
  static String? email(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.data.email''')) ??
          castToType<String>(getJsonField(response, r'''$.data[0].email'''));
  static String? profileImage(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.data.profile_image''')) ??
          castToType<String>(
              getJsonField(response, r'''$.data[0].profile_image'''));
  static String? overallRating(dynamic response) => castToType<String>(
    getJsonField(response, r'''$.data.overall_rating'''),
  ) ??
      castToType<String>(
          getJsonField(response, r'''$.data[0].overall_rating'''));
  static int? totalRides(dynamic response) =>
      castToType<int>(getJsonField(response, r'''$.data.total_rides''')) ??
          castToType<int>(getJsonField(response, r'''$.data[0].total_rides'''));
  static String? accountStatus(dynamic response) => castToType<String>(
    getJsonField(response, r'''$.data.account_status'''),
  ) ??
      castToType<String>(
          getJsonField(response, r'''$.data[0].account_status'''));
  static String? accountType(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.data.account_type''')) ??
          castToType<String>(getJsonField(response, r'''$.data[0].account_type'''));
  static String? createdAt(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.data.created_at''')) ??
          castToType<String>(getJsonField(response, r'''$.data[0].created_at'''));
  static String? updatedAt(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.data.updated_at''')) ??
          castToType<String>(getJsonField(response, r'''$.data[0].updated_at'''));
  static String? lastLogin(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.data.last_login''')) ??
          castToType<String>(getJsonField(response, r'''$.data[0].last_login'''));
  static bool? isBlocked(dynamic response) =>
      castToType<bool>(getJsonField(response, r'''$.data.is_blocked''')) ??
          castToType<bool>(getJsonField(response, r'''$.data[0].is_blocked'''));
  static String? fcmToken(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.data.fcm_token''')) ??
          castToType<String>(getJsonField(response, r'''$.data[0].fcm_token'''));
}

class UpdateUserByIdCall {
  static Future<ApiCallResponse> call({
    required int userId,
    String? token = '',
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    final ffApiRequestBody = '''
{
  "first_name": "${escapeStringForJson(firstName ?? '')}",
  "last_name": "${escapeStringForJson(lastName ?? '')}",
  "email": "${escapeStringForJson(email ?? '')}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'updateUserById',
      apiUrl: 'https://ugotaxi.icacorp.org/api/users/$userId',
      callType: ApiCallType.PUT,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      cache: false,
    );
  }
}

class UpdateProfileImageCall {
  static Future<ApiCallResponse> call({
    required int userId,
    String? token = '',
    required FFUploadedFile profileImage,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'updateProfileImage',
      apiUrl: 'https://ugotaxi.icacorp.org/api/users/profile-image/$userId',
      callType: ApiCallType.PUT,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {
        'profile_image': profileImage,
      },
      bodyType: BodyType.MULTIPART,
      returnBody: true,
      cache: false,
    );
  }
}

/// ---------------------------------------------------------------------------
/// RIDE HISTORY
/// ---------------------------------------------------------------------------

class GetRideHistoryCall {
  static Future<ApiCallResponse> call({
    required int userId,
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'getRideHistory',
      apiUrl: 'https://ugotaxi.icacorp.org/api/users/ride-history/$userId',
      callType: ApiCallType.GET,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {},
      returnBody: true,
      cache: false,
    );
  }

  // ---------- Root helpers ----------
  static bool? success(dynamic response) =>
      castToType<bool>(getJsonField(response, r'''$.success'''));
  static int? statusCode(dynamic response) =>
      castToType<int>(getJsonField(response, r'''$.statusCode'''));
  static String? message(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.message'''));

  // ---------- Data helpers ----------
  static dynamic dataRoot(dynamic response) =>
      getJsonField(response, r'''$.data''');
  static int? page(dynamic response) =>
      castToType<int>(getJsonField(response, r'''$.data.page'''));
  static int? pageSize(dynamic response) =>
      castToType<int>(getJsonField(response, r'''$.data.pageSize'''));
  static int? total(dynamic response) =>
      castToType<int>(getJsonField(response, r'''$.data.total'''));
  static List? rides(dynamic response) =>
      getJsonField(response, r'''$.data.rides''', true) as List?;

  // ---------- Individual ride helpers ----------
  static List<int>? rideIds(dynamic response) => (getJsonField(
    response,
    r'''$.data.rides[:].ride_id''',
    true,
  ) as List?)
      ?.withoutNulls
      .map((x) => castToType<int>(x))
      .withoutNulls
      .toList();
  static List<String>? driverNames(dynamic response) => (getJsonField(
    response,
    r'''$.data.rides[:].driver_name''',
    true,
  ) as List?)
      ?.withoutNulls
      .map((x) => castToType<String>(x))
      .withoutNulls
      .toList();
  static List<String>? fromLocations(dynamic response) => (getJsonField(
    response,
    r'''$.data.rides[:].from_location''',
    true,
  ) as List?)
      ?.withoutNulls
      .map((x) => castToType<String>(x))
      .withoutNulls
      .toList();
  static List<String>? toLocations(dynamic response) => (getJsonField(
    response,
    r'''$.data.rides[:].to_location''',
    true,
  ) as List?)
      ?.withoutNulls
      .map((x) => castToType<String>(x))
      .withoutNulls
      .toList();
  static List<double>? amounts(dynamic response) => (getJsonField(
    response,
    r'''$.data.rides[:].amount''',
    true,
  ) as List?)
      ?.withoutNulls
      .map((x) => castToType<double>(x))
      .withoutNulls
      .toList();
  static List<String>? dates(dynamic response) => (getJsonField(
    response,
    r'''$.data.rides[:].date''',
    true,
  ) as List?)
      ?.withoutNulls
      .map((x) => castToType<String>(x))
      .withoutNulls
      .toList();
  static List<String>? times(dynamic response) => (getJsonField(
    response,
    r'''$.data.rides[:].time''',
    true,
  ) as List?)
      ?.withoutNulls
      .map((x) => castToType<String>(x))
      .withoutNulls
      .toList();
  static List<String?>? ratings(dynamic response) => (getJsonField(
    response,
    r'''$.data.rides[:].rating''',
    true,
  ) as List?)
      ?.withoutNulls
      .map((x) => castToType<String>(x))
      .toList();

  // ---------- Convenience methods ----------
  static int ridesCount(dynamic response) => (rides(response)?.length ?? 0);

  static bool hasMorePages(dynamic response) {
    final currentPage = page(response) ?? 1;
    final totalRides = total(response) ?? 0;
    final pageSizeVal = pageSize(response) ?? 10;
    return (currentPage * pageSizeVal) < totalRides;
  }

  // ---------- First ride convenience methods ----------
  static int? firstRideId(dynamic response) => rideIds(response)?.firstOrNull;
  static String? firstDriverName(dynamic response) =>
      driverNames(response)?.firstOrNull;
  static String? firstFromLocation(dynamic response) =>
      fromLocations(response)?.firstOrNull;
  static String? firstToLocation(dynamic response) =>
      toLocations(response)?.firstOrNull;
  static double? firstAmount(dynamic response) =>
      amounts(response)?.firstOrNull;
  static String? firstDate(dynamic response) => dates(response)?.firstOrNull;
  static String? firstTime(dynamic response) => times(response)?.firstOrNull;
}

/// ---------------------------------------------------------------------------
/// VEHICLE & RIDE MANAGEMENT
/// ---------------------------------------------------------------------------

class GetVehicleDetailsCall {
  // Instance members for object usage
  bool? success;
  int? statusCode;
  String? messageText; // Renamed to avoid conflict
  List<VehicleData>? vehicleDataList; // Renamed to avoid conflict

  GetVehicleDetailsCall(
      {this.success, this.statusCode, this.messageText, this.vehicleDataList});

  GetVehicleDetailsCall.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    statusCode = json['statusCode'];
    messageText = json['message'];
    if (json['data'] != null) {
      vehicleDataList = <VehicleData>[];
      json['data'].forEach((v) {
        vehicleDataList!.add(new VehicleData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['statusCode'] = this.statusCode;
    data['message'] = this.messageText;
    if (this.vehicleDataList != null) {
      data['data'] = this.vehicleDataList!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  // ✅ STATIC API CALL (Required for widget)
  static Future<ApiCallResponse> call({int retryCount = 0}) async {
    const int maxRetries = 3; // Maximum number of retries
    const Duration delayDuration = Duration(seconds: 2); // Delay between retries

    ApiCallResponse? response;
    int currentRetry = retryCount;

    while (currentRetry <= maxRetries) {
      response = await ApiManager.instance.makeApiCall(
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

      if (response.statusCode == 200) {
        // Assuming 200 indicates success
        return response;
      } else {
        if (kDebugMode) {
          print(
              'GetVehicleDetailsCall failed with status code: ${response.statusCode}. Retrying...');
        }
        currentRetry++;
        if (currentRetry <= maxRetries) {
          await Future.delayed(delayDuration);
        }
      }
    }
    return response!; // Return the last response, even if it failed
  }

  // ✅ STATIC HELPER METHODS (Required for widget)
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

class VehicleData {
  int? id;
  int? vehicleTypeId;
  int? rideCategory;
  String? vehicleName;
  String? vehicleType;
  double? kilometerPerPrice;
  int? seatingCapacity;
  int? luggageCapacity;
  String? vehicleImage;
  String? createdAt;
  String? updatedAt;
  String? vehicleImageUrl;

  VehicleData({
    this.id,
    this.vehicleTypeId,
    this.rideCategory,
    this.vehicleName,
    this.vehicleType,
    this.kilometerPerPrice,
    this.seatingCapacity,
    this.luggageCapacity,
    this.vehicleImage,
    this.createdAt,
    this.updatedAt,
    this.vehicleImageUrl,
  });

  VehicleData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    vehicleTypeId = json['vehicle_type_id'];
    rideCategory = json['ride_category'];
    vehicleName = json['vehicle_name'];
    vehicleType = json['vehicle_type'];
    kilometerPerPrice = json['kilometer_per_price']?.toDouble();
    seatingCapacity = json['seating_capacity'];
    luggageCapacity = json['luggage_capacity'];
    vehicleImage = json['vehicle_image'];
    createdAt = json['createdAt'];
    updatedAt = json['updatedAt'];
    vehicleImageUrl = json['vehicle_image_url'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['vehicle_type_id'] = this.vehicleTypeId;
    data['ride_category'] = this.rideCategory;
    data['vehicle_name'] = this.vehicleName;
    data['vehicle_type'] = this.vehicleType;
    data['kilometer_per_price'] = this.kilometerPerPrice;
    data['seating_capacity'] = this.seatingCapacity;
    data['luggage_capacity'] = this.luggageCapacity;
    data['vehicle_image'] = this.vehicleImage;
    data['createdAt'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['vehicle_image_url'] = this.vehicleImageUrl;
    return data;
  }
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
    return list?.where((e) => e != null).map((e) => e.toString()).toList();
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

// ✅ FIXED: CreateRideCall updated to match expected API Body
// Uses "admin_vehicle_id" (INT) instead of "ride_type"
class CreateRideCall {
  bool? success;
  int? statusCode;
  String? message;
  Data? data;

  CreateRideCall({this.success, this.statusCode, this.message, this.data});

  CreateRideCall.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    statusCode = json['statusCode'];
    message = json['message'];
    data = json['data'] != null ? new Data.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['success'] = this.success;
    data['statusCode'] = this.statusCode;
    data['message'] = this.message;
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    return data;
  }

  // ✅ STATIC CALL METHOD
  static Future<ApiCallResponse> call({
    String? token,
    int? userId,
    String? pickupLocationAddress,
    String? dropLocationAddress,
    double? pickupLatitude,
    double? pickupLongitude,
    double? dropLatitude,
    double? dropLongitude,
    int? adminVehicleId, // ✅ Changed from rideType (String) to adminVehicleId (int)
    String? guestName,
    String? guestPhone,
    String? guestInstructions,
    String? estimatedFare,
    String? rideStatus,
    int retryCount = 0,
    int? driverId,
  }) async {
    const int maxRetries = 3;
    const Duration delayDuration = Duration(seconds: 2);

    ApiCallResponse? response;
    int currentRetry = retryCount;

    while (currentRetry <= maxRetries) {
      // ✅ Construct JSON exactly like the working cURL request
      final Map<String, dynamic> requestBody = {
        "user_id": userId,
        "pickup_location_address": pickupLocationAddress,
        "pickup_latitude": pickupLatitude,
        "pickup_longitude": pickupLongitude,
        "drop_location_address": dropLocationAddress,
        "drop_latitude": dropLatitude,
        "drop_longitude": dropLongitude,
        "admin_vehicle_id": adminVehicleId, // Sending INT
        "estimated_fare": estimatedFare ?? "0",
        "ride_status": rideStatus ?? "pending",
       
      };
if (driverId != null) {
        requestBody["driver_id"] = driverId;
      }

      // Add guest fields if present
      if (guestName != null && guestName.isNotEmpty) {
        requestBody["guest_name"] = guestName;
      }
      if (guestPhone != null && guestPhone.isNotEmpty) {
        requestBody["guest_phone"] = guestPhone;
      }
      if (guestInstructions != null && guestInstructions.isNotEmpty) {
        requestBody["guest_instructions"] = guestInstructions;
      }

      response = await ApiManager.instance.makeApiCall(
        callName: 'CreateRide',
        apiUrl: 'https://ugotaxi.icacorp.org/api/rides/post',
        callType: ApiCallType.POST,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        params: {},
        body: jsonEncode(requestBody), // Cleaner JSON encoding
        bodyType: BodyType.JSON,
        returnBody: true,
        encodeBodyUtf8: false,
        decodeUtf8: false,
        cache: false,
        isStreamingApi: false,
        alwaysAllowBody: false,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      } else {
        if (kDebugMode) {
          print(
              'CreateRideCall failed with status code: ${response.statusCode}. Retrying...');
        }
        currentRetry++;
        if (currentRetry <= maxRetries) {
          await Future.delayed(delayDuration);
        }
      }
    }
    return response!;
  }

  // Response helper methods
  static String? getResponseMessage(dynamic response) =>
      castToType<String>(getJsonField(response, r'$.message'));
  static int? rideId(dynamic response) =>
      castToType<int>(getJsonField(response, r'$.data.id'));
}

class Data {
  String? createdAt;
  String? updatedAt;
  int? id;
  int? userId;
  String? pickupLocationAddress;
  double? pickupLatitude;
  double? pickupLongitude;
  String? dropLocationAddress;
  double? dropLatitude;
  double? dropLongitude;
  String? rideType;
  String? bookingMode;
  String? rideDistanceKm;
  String? estimatedFare;
  String? rideStatus;
  String? requestTime;
  String? guestName;
  String? guestPhone;
  String? guestInstructions;
  Null? otp;
  Null? otpHash;
  Null? otpExpiresAt;
  int? otpAttempts;
  Null? otpVerifiedAt;

  Data(
      {this.createdAt,
        this.updatedAt,
        this.id,
        this.userId,
        this.pickupLocationAddress,
        this.pickupLatitude,
        this.pickupLongitude,
        this.dropLocationAddress,
        this.dropLatitude,
        this.dropLongitude,
        this.rideType,
        this.bookingMode,
        this.rideDistanceKm,
        this.estimatedFare,
        this.rideStatus,
        this.requestTime,
        this.guestName,
        this.guestPhone,
        this.guestInstructions,
        this.otp,
        this.otpHash,
        this.otpExpiresAt,
        this.otpAttempts,
        this.otpVerifiedAt});

  Data.fromJson(Map<String, dynamic> json) {
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    id = json['id'];
    userId = json['user_id'];
    pickupLocationAddress = json['pickup_location_address'];
    pickupLatitude = json['pickup_latitude'];
    pickupLongitude = json['pickup_longitude'];
    dropLocationAddress = json['drop_location_address'];
    dropLatitude = json['drop_latitude'];
    dropLongitude = json['drop_longitude'];
    rideType = json['ride_type'];
    bookingMode = json['booking_mode'];
    rideDistanceKm = json['ride_distance_km'];
    estimatedFare = json['estimated_fare'];
    rideStatus = json['ride_status'];
    requestTime = json['request_time'];
    guestName = json['guest_name'];
    guestPhone = json['guest_phone'];
    guestInstructions = json['guest_instructions'];
    otp = json['otp'];
    otpHash = json['otp_hash'];
    otpExpiresAt = json['otp_expires_at'];
    otpAttempts = json['otp_attempts'];
    otpVerifiedAt = json['otp_verified_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['id'] = this.id;
    data['user_id'] = this.userId;
    data['pickup_location_address'] = this.pickupLocationAddress;
    data['pickup_latitude'] = this.pickupLatitude;
    data['pickup_longitude'] = this.pickupLongitude;
    data['drop_location_address'] = this.dropLocationAddress;
    data['drop_latitude'] = this.dropLatitude;
    data['drop_longitude'] = this.dropLongitude;
    data['ride_type'] = this.rideType;
    data['booking_mode'] = this.bookingMode;
    data['ride_distance_km'] = this.rideDistanceKm;
    data['estimated_fare'] = this.estimatedFare;
    data['ride_status'] = this.rideStatus;
    data['request_time'] = this.requestTime;
    data['guest_name'] = this.guestName;
    data['guest_phone'] = this.guestPhone;
    data['guest_instructions'] = this.guestInstructions;
    data['otp'] = this.otp;
    data['otp_hash'] = this.otpHash;
    data['otp_expires_at'] = this.otpExpiresAt;
    data['otp_attempts'] = this.otpAttempts;
    data['otp_verified_at'] = this.otpVerifiedAt;
    return data;
  }
}

/// ---------------------------------------------------------------------------
/// DRIVER MANAGEMENT
/// ---------------------------------------------------------------------------

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
  static String? referralCode(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.referral_code''',
      ));

  /// Get profile image URL
  static String? profileImage(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.profile_image''',
      ));

  /// Get license image URL
  static String? licenseImage(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.license_image''',
      ));

  /// Get aadhaar image URL
  static String? aadhaarImage(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.aadhaar_image''',
      ));

  /// Get PAN image URL
  static String? panImage(dynamic response) => castToType<String>(getJsonField(
    response,
    r'''$.data.pan_image''',
  ));

  /// Get vehicle image URL
  static String? vehicleImage(dynamic response) =>
      castToType<String>(getJsonField(
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
  static String? mobileNumber(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.mobile_number''',
      ));

  /// Get wallet balance
  static String? walletBalance(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.wallet_balance''',
      ));

  /// Get driver rating
  static String? driverRating(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.driver_rating''',
      ));

  /// Get total rides completed
  static int? totalRidesCompleted(dynamic response) =>
      castToType<int>(getJsonField(
        response,
        r'''$.data.total_rides_completed''',
      ));

  /// Get total earnings
  static String? totalEarnings(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.total_earnings''',
      ));

  /// Check if driver is active
  static bool? isActive(dynamic response) => castToType<bool>(getJsonField(
    response,
    r'''$.data.is_active''',
  ));

  /// Get account status
  static String? accountStatus(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.account_status''',
      ));
}

// ---------------------------------------------------------------------------
// ✅ GetDriverDetailsCall WRAPPER
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

  // ✅ DRIVER PERSONAL INFO
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

  static String? vehicleModel(dynamic response) {
    var model =
    castToType<String>(getJsonField(response, r'''$.vehicle_model'''));
    if (model != null) return model;
    model =
        castToType<String>(getJsonField(response, r'''$.data.vehicle_model'''));
    return model ?? 'Auto';
  }

  static String? vehicleNumber(dynamic response) {
    var number =
    castToType<String>(getJsonField(response, r'''$.license_plate'''));
    if (number != null) return number;
    number = castToType<String>(
        getJsonField(response, r'''$.registration_number'''));
    if (number != null) return number;
    number =
        castToType<String>(getJsonField(response, r'''$.data.license_plate'''));
    return number ?? 'AP-00-XX-0000';
  }

  static String? vehicleType(dynamic response) {
    var type =
    castToType<String>(getJsonField(response, r'''$.vehicle_type'''));
    type ??= castToType<String>(getJsonField(response, r'''$.vehicle_name'''));
    type ??=
        castToType<String>(getJsonField(response, r'''$.data.vehicle_type'''));
    return type ?? 'Auto';
  }

  static String? vehicleStatus(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.vehicle_status''')) ??
          'pending_verification';
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
  static String? addressType(dynamic response) =>
      castToType<String>(getJsonField(
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
    required int rideId,
    String? cancellationReason,
    String? token = '',
    String? cancelledBy = 'user',
  }) async {
    final ffApiRequestBody = '''
{
  "ride_id": ${rideId},
  "cancellation_reason": "${escapeStringForJson(cancellationReason ?? '')}",
  "cancelled_by": "${escapeStringForJson(cancelledBy ?? 'user')}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'cancelRide',
      apiUrl: 'https://ugotaxi.icacorp.org/api/rides/rides/cancel',
      callType: ApiCallType.PATCH,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
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

class GetAllNotificationsCall {
  static Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'getAllNotifications',
      apiUrl: 'https://ugotaxi.icacorp.org/api/notifications/getall',
      callType: ApiCallType.GET,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {},
      returnBody: true,
      cache: false,
    );
  }

  static List? notifications(dynamic response) => getJsonField(
    response,
    r'''$.data.notifications''',
    true,
  ) as List?;
  static int? total(dynamic response) => castToType<int>(getJsonField(
    response,
    r'''$.data.total''',
  ));
}
class SubmitRideRatingCall {
  static Future<ApiCallResponse> call({
    required int rideId,
    required int userId,
    required int driverId,
    required String ratingGivenBy,
    required int ratingScore,
    String? ratingComment,
  }) async {
    final ffApiRequestBody = jsonEncode({
      "ride_id": rideId,
      "user_id": userId,
      "driver_id": driverId,
      "rating_given_by": ratingGivenBy,
      "rating_score": ratingScore,
      if (ratingComment != null && ratingComment.isNotEmpty)
        "rating_comment": ratingComment,
    });

    print('📤 API Request Body: $ffApiRequestBody');

    return ApiManager.instance.makeApiCall(
      callName: 'submitRideRating',
      apiUrl: 'https://ugotaxi.icacorp.org/api/ratings/post',
      callType: ApiCallType.POST,
      headers: {
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

  // Response helpers
  static bool? success(dynamic response) =>
      castToType<bool>(getJsonField(response, r'''$.success'''));

  static int? statusCode(dynamic response) =>
      castToType<int>(getJsonField(response, r'''$.statusCode'''));

  static String? message(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.message'''));

  static int? ratingId(dynamic response) =>
      castToType<int>(getJsonField(response, r'''$.data.id'''));
}

class GetAllVouchersCall {
  static Future<ApiCallResponse> call({String? token}) async {
    return ApiManager.instance.makeApiCall(
      callName: 'getAllVouchers',
      apiUrl: 'https://ugotaxi.icacorp.org/api/promo-codes/getall',
      callType: ApiCallType.GET,
      headers: {
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
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

  static List? data(dynamic response) => getJsonField(
    response,
    r'''$.data''',
    true,
  ) as List?;
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
  list ??= <dynamic>[];
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
      .replaceAll('"', '\"')
      .replaceAll('\n', '\n')
      .replaceAll('\t', '\t');
}