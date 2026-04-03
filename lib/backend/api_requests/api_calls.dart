import 'dart:async';
import 'package:flutter/foundation.dart';

import '/core/app_config.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

/// Base API URL - single source of truth.
String get _baseUrl => AppConfig.baseApiUrl;

/// ---------------------------------------------------------------------------
/// USER MANAGEMENT
/// ---------------------------------------------------------------------------

class CreateUserCall {
  static Future<ApiCallResponse> call({
    int? mobileNumber,
    String? firstName = '',
    String? lastName = '',
    String? email = '',
    String? referralCode = '',
    FFUploadedFile? profileImage,
    String? fcmToken,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'createUser',
      apiUrl: '$_baseUrl/api/users/post',
      callType: ApiCallType.POST,
      headers: {},
      params: {
        'mobile_number': mobileNumber,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'referral_code': referralCode,
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

  static String? accessToken(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.accessToken''',
      ));
  static String? refreshToken(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.refreshToken''',
      )) ??
      castToType<String>(getJsonField(
        response,
        r'''$.data.refresh_token''',
      ));
  static int? userid(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.user.id''',
      ));
}

class LoginCall {
  static Future<ApiCallResponse> call({
    int? mobile,
    String? fcmToken = '',
  }) async {
    // Backend Joi: mobile_number + fcm_token are strings (required).
    final ffApiRequestBody = jsonEncode({
      'mobile_number': mobile?.toString() ?? '',
      'fcm_token': fcmToken ?? '',
    });
    return ApiManager.instance.makeApiCall(
      callName: 'login',
      apiUrl: '$_baseUrl/api/users/login',
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

  static String? accessToken(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.accessToken''',
      ));
  static String? refreshToken(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.refreshToken''',
      )) ??
      castToType<String>(getJsonField(
        response,
        r'''$.data.refresh_token''',
      ));
  static int? userid(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.user.id''',
      ));
}

class UserLogoutCall {
  static Future<ApiCallResponse> call({
    required String token,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'userLogout',
      apiUrl: '$_baseUrl/api/users/logout',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      params: {},
      body: '{}',
      bodyType: BodyType.JSON,
      returnBody: true,
      cache: false,
    );
  }
}

class GetUserDetailsCall {
  static Future<ApiCallResponse> call({
    required int userId,
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'getUserDetails',
      apiUrl: '$_baseUrl/api/users/$userId',
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
  static String? overallRating(dynamic response) =>
      castToType<String>(
        getJsonField(response, r'''$.data.overall_rating'''),
      ) ??
      castToType<String>(
          getJsonField(response, r'''$.data[0].overall_rating'''));
  static int? totalRides(dynamic response) =>
      castToType<int>(getJsonField(response, r'''$.data.total_rides''')) ??
      castToType<int>(getJsonField(response, r'''$.data[0].total_rides'''));
  static String? accountStatus(dynamic response) =>
      castToType<String>(
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
  static int? referredByUserId(dynamic response) =>
      castToType<int>(
          getJsonField(response, r'''$.data.referred_by_user_id''')) ??
      castToType<int>(
          getJsonField(response, r'''$.data[0].referred_by_user_id'''));
  static String? usedReferralCodeField(dynamic response) =>
      castToType<String>(
          getJsonField(response, r'''$.data.used_referral_code''')) ??
      castToType<String>(
          getJsonField(response, r'''$.data[0].used_referral_code'''));
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
      apiUrl: '$_baseUrl/api/users/$userId',
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
      apiUrl: '$_baseUrl/api/users/profile-image/$userId',
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

class GetUserReferralStatsCall {
  static Future<ApiCallResponse> call({
    required int userId,
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'getUserReferralStats',
      apiUrl: '$_baseUrl/api/users/referral-stats/$userId',
      callType: ApiCallType.GET,
      headers: {
        'Authorization': 'Bearer $token',
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static dynamic referralCode(dynamic response) => getJsonField(
        response,
        r'''$.data.referral_code''',
      );
  static dynamic totalReferrals(dynamic response) => getJsonField(
        response,
        r'''$.data.total_referrals''',
      );
  static dynamic totalEarned(dynamic response) => getJsonField(
        response,
        r'''$.data.total_earned''',
      );
  static bool referralMasterBadge(dynamic response) {
    final raw = getJsonField(response, r'''$.data.referral_master_badge''');
    if (raw == null) return false;
    if (raw is bool) return raw;
    final s = raw.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  static int? inviterCompletedThisMonth(dynamic response) {
    final raw =
        getJsonField(response, r'''$.data.inviter_completed_this_month''');
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  static int? inviterMonthlyRewardCap(dynamic response) {
    final raw =
        getJsonField(response, r'''$.data.inviter_monthly_reward_cap''');
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  /// Completed Pro rides that paid referral coins to this inviter (backend v2).
  static int? referralProRidePayouts(dynamic response) {
    final raw = getJsonField(response, r'''$.data.referral_pro_ride_payouts''');
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  /// Sum of coins awarded from Pro-ride referrals (earned rows).
  static int? referralRewardCoinsTotal(dynamic response) {
    final raw =
        getJsonField(response, r'''$.data.referral_reward_coins_total''');
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  /// Distinct friends with at least one Pro-ride referral payout.
  static int? referralsWithProReward(dynamic response) {
    final raw = getJsonField(response, r'''$.data.referrals_with_pro_reward''');
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  /// Mirrors `users.coins_balance` from the same payload (keeps app state in sync).
  static int? coinsBalance(dynamic response) {
    final raw = getJsonField(response, r'''$.data.coins_balance''');
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  /// Nested ledger from `wallets` row: earned / used / available (optional).
  static Map<String, int>? walletCoinsLedger(dynamic response) {
    final raw = getJsonField(response, r'''$.data.wallet_coins_ledger''');
    if (raw == null || raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    return {
      'total_earned_coins':
          int.tryParse(m['total_earned_coins']?.toString() ?? '') ?? 0,
      'total_used_coins':
          int.tryParse(m['total_used_coins']?.toString() ?? '') ?? 0,
      'available_coins':
          int.tryParse(m['available_coins']?.toString() ?? '') ?? 0,
    };
  }
}

/// GET /api/users/me/coins/economy — rates, festival multiplier, streak (rider JWT).
class GetMyCoinsEconomyCall {
  static Future<ApiCallResponse> call({required String token}) async {
    return ApiManager.instance.makeApiCall(
      callName: 'getMyCoinsEconomy',
      apiUrl: '$_baseUrl/api/users/me/coins/economy',
      callType: ApiCallType.GET,
      headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {},
      returnBody: true,
      cache: false,
    );
  }

  static double? earnMultiplier(dynamic response) {
    final v = getJsonField(response, r'''$.data.earn_multiplier''');
    if (v == null) return null;
    return double.tryParse(v.toString());
  }
}

/// POST /api/users/me/coins/redeem
/// redemption: free_ride_50 | premium_support (+ ticket_title, ticket_description)
class RedeemCoinsCall {
  static Future<ApiCallResponse> call({
    required String token,
    required String redemption,
    String? ticketTitle,
    String? ticketDescription,
    int? rideId,
  }) async {
    final body = <String, dynamic>{'redemption': redemption};
    if (ticketTitle != null) body['ticket_title'] = ticketTitle;
    if (ticketDescription != null) {
      body['ticket_description'] = ticketDescription;
    }
    if (rideId != null) body['ride_id'] = rideId;
    return ApiManager.instance.makeApiCall(
      callName: 'redeemCoins',
      apiUrl: '$_baseUrl/api/users/me/coins/redeem',
      callType: ApiCallType.POST,
      headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      params: {},
      body: jsonEncode(body),
      bodyType: BodyType.JSON,
      returnBody: true,
      cache: false,
    );
  }
}

/// GET /api/users/me/coins/ledger — each earn/spend row (rider JWT).
class GetMyCoinLedgerCall {
  static Future<ApiCallResponse> call({
    required String token,
    int page = 1,
    int limit = 50,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'getMyCoinLedger',
      apiUrl: '$_baseUrl/api/users/me/coins/ledger?page=$page&limit=$limit',
      callType: ApiCallType.GET,
      headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {},
      returnBody: true,
      cache: false,
    );
  }

  static List<Map<String, dynamic>> transactions(dynamic response) {
    final list = getJsonField(response, r'''$.data.transactions''');
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static int? totalCount(dynamic response) {
    final raw = getJsonField(response, r'''$.data.total''');
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }
}

/// PATCH /api/users/me/date-of-birth — body { "date_of_birth": "YYYY-MM-DD" }
class UpdateUserDateOfBirthCall {
  static Future<ApiCallResponse> call({
    required String token,
    required String dateOfBirth,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'updateUserDob',
      apiUrl: '$_baseUrl/api/users/me/date-of-birth',
      callType: ApiCallType.PATCH,
      headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      params: {},
      body: jsonEncode({'date_of_birth': dateOfBirth}),
      bodyType: BodyType.JSON,
      returnBody: true,
      cache: false,
    );
  }
}

/// GET /api/users/referrals/:userId — people you referred (userController.getReferrals).
class GetUserReferralsCall {
  static Future<ApiCallResponse> call({
    required int userId,
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'getUserReferrals',
      apiUrl: '$_baseUrl/api/users/referrals/$userId',
      callType: ApiCallType.GET,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
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

  static int? total(dynamic response) {
    final raw = getJsonField(response, r'''$.data.total''');
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  static List<dynamic> referrals(dynamic response) {
    final list = getJsonField(response, r'''$.data.referrals''');
    if (list is List) return List<dynamic>.from(list);
    return [];
  }
}

class GenerateReferralCodeCall {
  static Future<ApiCallResponse> call({
    required int userId,
    String? token = '',
  }) async {
    final ffApiRequestBody = '''
{
  "user_id": $userId
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'GenerateReferralCode',
      apiUrl: '$_baseUrl/api/referral/Generate',
      callType: ApiCallType.POST,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
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

  static String? referralCode(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.referral_code''',
      ));
}

class ApplyReferralCodeCall {
  static Future<ApiCallResponse> call({
    required int userId,
    required String referralCode,
    String? token = '',
  }) async {
    final ffApiRequestBody = '''
{
  "user_id": $userId,
  "referral_code": "$referralCode"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'ApplyReferralCode',
      apiUrl: '$_baseUrl/api/referral/Apply',
      callType: ApiCallType.POST,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
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

  static bool? success(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$.success''',
      ));
  static String? message(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$.message''',
      ));
}

class GetReferralStatusCall {
  static Future<ApiCallResponse> call({
    required int userId,
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetReferralStatus',
      apiUrl: '$_baseUrl/api/referral/Status',
      callType: ApiCallType.GET,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {
        'user_id': userId,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? referralCode(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.referral_code''',
      ));
  static int? totalReferrals(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.total_referrals''',
      ));
  static int? successfulConversions(dynamic response) =>
      castToType<int>(getJsonField(
        response,
        r'''$.data.successful_conversions''',
      ));
  static double? coinsEarned(dynamic response) =>
      castToType<double>(getJsonField(
        response,
        r'''$.data.coins_earned''',
      ));
}

class GetReferralHistoryCall {
  static Future<ApiCallResponse> call({
    required int userId,
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetReferralHistory',
      apiUrl: '$_baseUrl/api/referral/History',
      callType: ApiCallType.GET,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {
        'user_id': userId,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static List<dynamic>? history(dynamic response) => (getJsonField(
        response,
        r'''$.data''',
        true,
      ) as List?)
          ?.toList();
}

class GetReferralEarningsCall {
  static Future<ApiCallResponse> call({
    required int userId,
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetReferralEarnings',
      apiUrl: '$_baseUrl/api/referral/Earnings',
      callType: ApiCallType.GET,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {
        'user_id': userId,
      },
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static double? moneyEarned(dynamic response) =>
      castToType<double>(getJsonField(
        response,
        r'''$.data.money_earned''',
      ));
  static double? coinsEarned(dynamic response) =>
      castToType<double>(getJsonField(
        response,
        r'''$.data.coins_earned''',
      ));
}

/// ---------------------------------------------------------------------------
/// ADDRESS MANAGEMENT
/// ---------------------------------------------------------------------------

class SaveAddressCall {
  static Future<ApiCallResponse> call({
    required int userId,
    String? addressLabel = '',
    String? addressText = '',
    required double latitude,
    required double longitude,
    String? token,
  }) async {
    final body = {
      'user_id': userId,
      'address_label': addressLabel ?? '',
      'address_text': addressText ?? '',
      'latitude': latitude,
      'longitude': longitude,
    };
    return ApiManager.instance.makeApiCall(
      callName: 'SaveAddress',
      apiUrl: '$_baseUrl/api/saved-addresses/post',
      callType: ApiCallType.POST,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      params: {},
      body: jsonEncode(body),
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

class GetSavedAddressesCall {
  static Future<ApiCallResponse> call({
    required int userId,
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetSavedAddresses',
      apiUrl: '$_baseUrl/api/saved-addresses/user/$userId',
      callType: ApiCallType.GET,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
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

  // Helpers to parse List<dynamic> from response
  static List<int>? ids(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].id''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();

  static List<String>? addressTexts(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].address_text''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();

  static List<String>? addressTypes(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].address_type''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();

  static List<String>? addressNames(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].address_name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();

  static List<double>? latitudes(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].latitude''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => double.tryParse(x.toString()))
          .withoutNulls
          .toList();

  static List<double>? longitudes(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].longitude''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => double.tryParse(x.toString()))
          .withoutNulls
          .toList();
}

/// ---------------------------------------------------------------------------
/// RIDE HISTORY
/// ---------------------------------------------------------------------------

class GetRideHistoryCall {
  /// [statusGroup]: `all` | `ongoing` | `completed` | `cancelled`
  /// [startDate] / [endDate]: `YYYY-MM-DD` (inclusive), optional.
  static Future<ApiCallResponse> call({
    required int userId,
    String? token = '',
    int page = 1,
    int pageSize = 20,
    String statusGroup = 'all',
    String? startDate,
    String? endDate,
  }) async {
    final qp = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.clamp(1, 50).toString(),
      'statusGroup': statusGroup,
    };
    if (startDate != null && startDate.isNotEmpty) {
      qp['startDate'] = startDate;
    }
    if (endDate != null && endDate.isNotEmpty) {
      qp['endDate'] = endDate;
    }
    final q = qp.entries
        .map((e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return ApiManager.instance.makeApiCall(
      callName: 'getRideHistory',
      apiUrl: '$_baseUrl/api/users/ride-history/$userId?$q',
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
/// WALLET MANAGEMENT
/// ---------------------------------------------------------------------------

class AddMoneyToWalletCall {
  static Future<ApiCallResponse> call({
    required int userId,
    required double amount,
    String? currency = "INR",
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? token,
  }) async {
    final body = <String, dynamic>{
      "user_id": userId,
      "amount": amount,
      "currency": currency ?? "INR",
    };
    if (razorpayPaymentId != null && razorpayPaymentId.isNotEmpty) {
      body['razorpay_payment_id'] = razorpayPaymentId;
    }
    if (razorpayOrderId != null && razorpayOrderId.isNotEmpty) {
      body['razorpay_order_id'] = razorpayOrderId;
    }
    final ffApiRequestBody = jsonEncode(body);

    return ApiManager.instance.makeApiCall(
      callName: 'AddMoneyToWallet',
      apiUrl: '$_baseUrl/api/wallets/add',
      callType: ApiCallType.POST,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
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

  /// Response Helpers
  static bool? success(dynamic response) =>
      castToType<bool>(getJsonField(response, r'''$.success'''));

  static String? message(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.message'''));

  static String? walletBalance(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.data.wallet_balance'''));
}

class CreatePaymentCall {
  static Future<ApiCallResponse> call({
    required int rideId,
    required int userId,
    required num amount,
    required String paymentMethod,
    String paymentStatus = 'success',
    String? token,
  }) async {
    final body = {
      'ride_id': rideId,
      'user_id': userId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_status': paymentStatus,
    };
    return ApiManager.instance.makeApiCall(
      callName: 'CreatePayment',
      apiUrl: '$_baseUrl/api/payments/post',
      callType: ApiCallType.POST,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      params: {},
      body: jsonEncode(body),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static bool? success(dynamic response) =>
      castToType<bool>(getJsonField(response, r'$.success'));
  static String? message(dynamic response) =>
      castToType<String>(getJsonField(response, r'$.message'));
}

/// POST /api/payments/process - Process payment (wallet deduction or UPI initiation)
class PaymentProcessCall {
  static Future<ApiCallResponse> call({
    required int rideId,
    required String paymentMethod,
    required num amount,
    String? token,
  }) async {
    final body = {
      'ride_id': rideId,
      'payment_method': paymentMethod,
      'amount': amount,
    };
    return ApiManager.instance.makeApiCall(
      callName: 'PaymentProcess',
      apiUrl: '$_baseUrl/api/payments/process',
      callType: ApiCallType.POST,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      params: {},
      body: jsonEncode(body),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static bool? success(dynamic response) =>
      castToType<bool>(getJsonField(response, r'$.success'));
  static String? razorpayOrderId(dynamic response) =>
      castToType<String>(getJsonField(response, r'$.data.order_id'));
}

/// POST /api/payments/razorpay/create-order - Create Razorpay order for UPI/Card
class CreateRazorpayOrderCall {
  static Future<ApiCallResponse> call({
    int? rideId,
    num? amount,
    String? token,
  }) async {
    final body = <String, dynamic>{};
    if (rideId != null) body['ride_id'] = rideId;
    if (amount != null) body['amount'] = amount;
    return ApiManager.instance.makeApiCall(
      callName: 'CreateRazorpayOrder',
      apiUrl: '$_baseUrl/api/payments/razorpay/create-order',
      callType: ApiCallType.POST,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      params: {},
      body: jsonEncode(body.isEmpty ? {} : body),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? orderId(dynamic response) =>
      castToType<String>(getJsonField(response, r'$.data.order_id'));
}

/// GET /api/vehicle-types/getall-vehicle - Fetch all vehicle types for Our Services
class GetVehicleTypesCall {
  static Future<ApiCallResponse> call() async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetVehicleTypes',
      apiUrl: '$_baseUrl/api/vehicle-types/getall-vehicle',
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

  static bool? success(dynamic response) =>
      castToType<bool>(getJsonField(response, r'$.success'));
  static List<dynamic>? vehicles(dynamic response) =>
      (getJsonField(response, r'$.data') as List?)?.toList();
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

  // ✅ STATIC API CALL
  static Future<ApiCallResponse> call(
      {int retryCount = 0, String? token}) async {
    const int maxRetries = 3;
    const Duration delayDuration = Duration(seconds: 2);

    ApiCallResponse? response;
    int currentRetry = retryCount;

    while (currentRetry <= maxRetries) {
      response = await ApiManager.instance.makeApiCall(
        callName: 'GetVehicleDetails',
        // ✅ Fixed URL (removed redundant api/admins/)
        apiUrl: '$_baseUrl/api/admins/api/admins/vehicles',
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

      if (response.statusCode == 200) {
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
    return response!;
  }

  // ✅ STATIC HELPER METHODS
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
  static List<int>? rideCategory(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].ride_category''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<int>(x))
          .withoutNulls
          .toList();
}

/// ---------------------------------------------------------------------------
/// GET ALL DRIVERS (filter by vehicle type like Rapido)
/// ---------------------------------------------------------------------------
class GetAllDriversCall {
  static Future<ApiCallResponse> call({String? token}) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetAllDrivers',
      apiUrl: '$_baseUrl/api/drivers/getall',
      callType: ApiCallType.GET,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
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

  static List? drivers(dynamic response) =>
      (getJsonField(response, r'''$.data''') as List?)?.toList();
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
      apiUrl: '$_baseUrl/api/rides/users/$userId/pending-rides',
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
        .map((e) => double.tryParse(e.toString()) ?? 0.0)
        .toList();
  }

  static List<double>? pickupLng(dynamic response) => (getJsonField(
        response,
        r'''$.data.rides[:].pickup_longitude''',
        true,
      ) as List?)
          ?.where((x) => x != null)
          .map((x) => double.tryParse(x.toString()) ?? 0.0)
          .toList();
}

/// GET /api/rides/users/:userId/scheduled-rides
class GetScheduledRidesCall {
  static Future<ApiCallResponse> call({
    required int userId,
    String? token,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetScheduledRides',
      apiUrl: '$_baseUrl/api/rides/users/$userId/scheduled-rides',
      callType: ApiCallType.GET,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {},
      returnBody: true,
      cache: false,
    );
  }

  static List? rides(dynamic response) =>
      getJsonField(response, r'$.data.rides', true) as List?;
}

/// POST /api/rides/estimate-fare - Route-based fare (Google Directions) + Pricing
class EstimateFareCall {
  static Future<ApiCallResponse> call({
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
    required int adminVehicleId,
    String? token,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'EstimateFare',
      apiUrl: '$_baseUrl/api/rides/estimate-fare',
      callType: ApiCallType.POST,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      params: {},
      body: jsonEncode({
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'drop_lat': dropLat,
        'drop_lng': dropLng,
        'admin_vehicle_id': adminVehicleId,
      }),
      bodyType: BodyType.JSON,
      returnBody: true,
      cache: false,
    );
  }

  static double? distanceKm(dynamic r) =>
      castToType<double>(getJsonField(r, r'$.data.distance_km'));
  static int? durationMin(dynamic r) =>
      castToType<int>(getJsonField(r, r'$.data.duration_min'));
  static double? estimatedFare(dynamic r) =>
      castToType<double>(getJsonField(r, r'$.data.estimated_fare'));
  static double? surgeMultiplier(dynamic r) =>
      castToType<double>(getJsonField(r, r'$.data.surge_multiplier'));
  static double? baseFare(dynamic r) =>
      castToType<double>(getJsonField(r, r'$.data.base_fare'));
}

/// GET /api/location/surge-multiplier?lat=&lng=
/// Returns surge multiplier for pickup location (1.0 = no surge)
class GetSurgeMultiplierCall {
  static Future<ApiCallResponse> call({
    required double lat,
    required double lng,
    String? token,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetSurgeMultiplier',
      apiUrl: '$_baseUrl/api/location/surge-multiplier',
      callType: ApiCallType.GET,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {'lat': lat, 'lng': lng},
      returnBody: true,
      cache: false,
    );
  }

  static double? surgeMultiplier(dynamic r) =>
      castToType<double>(getJsonField(r, r'$.data.surge_multiplier'));
}

/// Scan to Book: Uses same endpoint as normal booking - POST /api/rides/post
/// Pass driver_id + admin_vehicle_id (from QR) so ride is created with status 'started'
/// Scan booking is cash-only.
class ScanBookRideCall {
  static Future<ApiCallResponse> call({
    required int driverId,
    required int adminVehicleId,
    required int userId,
    required double pickupLatitude,
    required double pickupLongitude,
    required double dropLatitude,
    required double dropLongitude,
    required String pickupAddress,
    required String dropAddress,
    String? paymentMethod, // Ignored – scan booking always uses cash
    required String estimatedFare,
    String? token,
    String? guestName,
    String? guestPhone,
    String? guestInstructions,
  }) async {
    return CreateRideCall.call(
      token: token,
      userId: userId,
      pickupLocationAddress: pickupAddress,
      dropLocationAddress: dropAddress,
      pickupLatitude: pickupLatitude,
      pickupLongitude: pickupLongitude,
      dropLatitude: dropLatitude,
      dropLongitude: dropLongitude,
      adminVehicleId: adminVehicleId,
      estimatedFare: estimatedFare,
      rideStatus: 'started',
      driverId: driverId,
      paymentType: 'cash', // Scan booking: cash only
      guestName: guestName,
      guestPhone: guestPhone,
      guestInstructions: guestInstructions,
    );
  }

  static int? rideId(dynamic response) =>
      castToType<int>(getJsonField(response, r'$.data.id')) ??
      castToType<int>(getJsonField(response, r'$.data.rideId'));
  static int? rideIdAlt(dynamic response) =>
      castToType<int>(getJsonField(response, r'$.data.id'));
  static String? status(dynamic response) =>
      castToType<String>(getJsonField(response, r'$.data.status'));
}

/// Confirm Scan Start: POST /api/rides/confirm-scan-start
class ConfirmScanStartCall {
  static Future<ApiCallResponse> call({
    required int rideId,
    String? token,
  }) async {
    final body = {'ride_id': rideId};
    return ApiManager.instance.makeApiCall(
      callName: 'ConfirmScanStart',
      apiUrl: '$_baseUrl/api/rides/confirm-scan-start',
      callType: ApiCallType.POST,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      params: {},
      body: jsonEncode(body),
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

class GetRideDetailsCall {
  static Future<ApiCallResponse> call({
    required int rideId,
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'getRideDetails',
      apiUrl: '$_baseUrl/api/rides/$rideId',
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

/// Rapido-style: rider updates pickup/drop mid-ride; backend emits `ride_updated` + slim `ride_location_updated` (coords, distance, estimated_fare, final_fare).
class PatchRideLocationsCall {
  static Future<ApiCallResponse> call({
    required int rideId,
    required String token,
    double? pickupLatitude,
    double? pickupLongitude,
    String? pickupLocationAddress,
    double? dropLatitude,
    double? dropLongitude,
    String? dropLocationAddress,
  }) async {
    final body = <String, dynamic>{};
    if (pickupLatitude != null &&
        pickupLongitude != null &&
        pickupLocationAddress != null &&
        pickupLocationAddress.trim().length >= 3) {
      body['pickup_latitude'] = pickupLatitude;
      body['pickup_longitude'] = pickupLongitude;
      body['pickup_location_address'] = pickupLocationAddress.trim();
    }
    if (dropLatitude != null &&
        dropLongitude != null &&
        dropLocationAddress != null &&
        dropLocationAddress.trim().length >= 3) {
      body['drop_latitude'] = dropLatitude;
      body['drop_longitude'] = dropLongitude;
      body['drop_location_address'] = dropLocationAddress.trim();
    }
    return ApiManager.instance.makeApiCall(
      callName: 'patchRideLocations',
      apiUrl: '$_baseUrl/api/rides/$rideId/locations',
      callType: ApiCallType.PATCH,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      params: {},
      body: jsonEncode(body),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: true,
    );
  }
}

/// Returns valid payment_method (cash|online|wallet), defaults to "cash"
String _createRidePaymentMethod(String? paymentType) {
  final p = (paymentType ?? '').toString().trim().toLowerCase();
  if (p == 'cash' || p == 'online' || p == 'wallet') return p;
  return 'cash';
}

/// Backend [createRideSchema] only allows these uppercase values. Omit to let server default to SEARCHING.
String? _createRideStatusForApi(String? rideStatus) {
  if (rideStatus == null || rideStatus.trim().isEmpty) return null;
  final u = rideStatus.trim().toUpperCase();
  const allowed = {
    'SEARCHING',
    'ACCEPTED',
    'STARTED',
    'COMPLETED',
    'CANCELLED',
  };
  if (allowed.contains(u)) return u;
  if (u == 'PENDING') return 'SEARCHING';
  return null;
}

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

  /// Optional intermediate stops. Format: [{address, latitude, longitude}, ...]
  /// Max 4 stops (per PRD). Backend must support this field.
  static Future<ApiCallResponse> call({
    String? token,
    int? userId,
    String? pickupLocationAddress,
    String? dropLocationAddress,
    double? pickupLatitude,
    double? pickupLongitude,
    double? dropLatitude,
    double? dropLongitude,
    int?
        adminVehicleId, // ✅ Changed from rideType (String) to adminVehicleId (int)
    String? guestName,
    String? guestPhone,
    String? guestInstructions,
    String? estimatedFare,
    String? rideStatus,
    int retryCount = 0,
    int? driverId,
    String? paymentType, // ✅ Added Payment Type (cash/online)
    List<Map<String, dynamic>>? stops, // ✅ PRD: Multiple stops (max 4)
    DateTime? scheduledAt, // ✅ Scheduled rides: ISO 8601 pickup time
    int?
        coinsToUse, // Referral coins; backend: multiple of 10, 10 coins = ₹1 discount
    bool? autoApplyBestVoucher,
    int? userWalletVoucherId,
  }) async {
    const int maxRetries = 3;
    const Duration delayDuration = Duration(seconds: 2);

    ApiCallResponse? response;
    int currentRetry = retryCount;

    while (currentRetry <= maxRetries) {
      // Scan booking (driver_id present): always cash. Normal booking: use paymentType.
      final isScanBooking = driverId != null;
      final paymentMethod =
          isScanBooking ? 'cash' : _createRidePaymentMethod(paymentType);

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
        "payment_method": paymentMethod,
      };
      final statusForApi = _createRideStatusForApi(rideStatus);
      if (statusForApi != null) {
        requestBody["ride_status"] = statusForApi;
      }
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
      // PRD: Multiple stops - send when backend supports it
      if (stops != null && stops.isNotEmpty && stops.length <= 4) {
        requestBody["stops"] = stops
            .map((s) => {
                  "address": s["address"] ?? "",
                  "latitude": (s["latitude"] ?? s["lat"])?.toDouble(),
                  "longitude": (s["longitude"] ?? s["lng"])?.toDouble(),
                })
            .toList();
      }
      // Scheduled rides
      if (scheduledAt != null) {
        requestBody["scheduled_at"] = scheduledAt.toUtc().toIso8601String();
      }
      if (coinsToUse != null && coinsToUse > 0) {
        requestBody["coins_to_use"] = coinsToUse;
      }
      if (autoApplyBestVoucher == true) {
        requestBody["auto_apply_best_voucher"] = true;
      }
      if (userWalletVoucherId != null && userWalletVoucherId > 0) {
        requestBody["user_wallet_voucher_id"] = userWalletVoucherId;
      }

      response = await ApiManager.instance.makeApiCall(
        callName: 'CreateRide',
        apiUrl: '$_baseUrl/api/rides/post',
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
      }
      // 4xx: validation / business rules — retrying the same body will not help.
      if (response.statusCode >= 400 && response.statusCode < 500) {
        if (kDebugMode) {
          print(
              'CreateRideCall failed (${response.statusCode}): ${response.jsonBody}');
        }
        return response;
      }
      if (kDebugMode) {
        print(
            'CreateRideCall failed with status code: ${response.statusCode}. Retrying...');
        print('CreateRideCall body: ${response.jsonBody}');
      }
      currentRetry++;
      if (currentRetry <= maxRetries) {
        await Future.delayed(delayDuration);
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
  Null otp;
  Null otpHash;
  Null otpExpiresAt;
  int? otpAttempts;
  Null otpVerifiedAt;

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
/// ADD TIP TO RIDE
/// ---------------------------------------------------------------------------

class AddTipToRideCall {
  static Future<ApiCallResponse> call({
    required int rideId,
    required int tipAmount,
    String? token = '',
  }) async {
    final body = {
      'ride_id': rideId,
      'tip_amount': tipAmount,
    };
    return ApiManager.instance.makeApiCall(
      callName: 'AddTipToRide',
      apiUrl: '$_baseUrl/api/rides/add-tip',
      callType: ApiCallType.POST,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      params: {},
      body: jsonEncode(body),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static bool? success(dynamic response) =>
      castToType<bool>(getJsonField(response, r'$.success'));
  static String? message(dynamic response) =>
      castToType<String>(getJsonField(response, r'$.message'));
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
      apiUrl: '$_baseUrl/api/drivers/${id}',
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
// ✅ GetVehicleInfoByDriverCall
// ---------------------------------------------------------------------------
class GetVehicleInfoByDriverCall {
  static Future<ApiCallResponse> call({
    required int driverId,
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetVehicleInfoByDriver',
      apiUrl: '$_baseUrl/api/users/by-driver/$driverId',
      callType: ApiCallType.GET,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      returnBody: true,
      cache: false,
    );
  }

  static int? vehicleId(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.vehicle_id''',
      ));
  static String? vehicleModel(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.vehicle_model''',
      ));
  static String? licensePlate(dynamic response) {
    return castToType<String>(
            getJsonField(response, r'''$.data.license_plate''')) ??
        castToType<String>(
            getJsonField(response, r'''$.data.vehicle.license_plate'''));
  }

  /// RC / registration when `license_plate` is empty on `by-driver` user payload.
  static String? registrationNumber(dynamic response) {
    return castToType<String>(
            getJsonField(response, r'''$.data.registration_number''')) ??
        castToType<String>(
            getJsonField(response, r'''$.data.vehicle.registration_number'''));
  }

  static String? vehicleName(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.vehicle_name''',
      ));
  static String? vehicleColor(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.data.vehicle_color''',
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
      return imagePath.startsWith('http') ? imagePath : '$_baseUrl/$imagePath';
    }
    return null;
  }

  static String? vehicleNumber(dynamic response) {
    // From socket payload (flat fields)
    var number =
        castToType<String>(getJsonField(response, r'''$.vehicle_plate'''));
    if (number != null) return number;
    number = castToType<String>(getJsonField(response, r'''$.license_plate'''));
    if (number != null) return number;
    number = castToType<String>(
        getJsonField(response, r'''$.registration_number'''));
    if (number != null) return number;
    // From GET /api/drivers/:id (nested vehicle object)
    number = castToType<String>(
        getJsonField(response, r'''$.data.vehicle.license_plate'''));
    if (number != null) return number;
    number = castToType<String>(
        getJsonField(response, r'''$.data.vehicle.registration_number'''));
    if (number != null) return number;
    number =
        castToType<String>(getJsonField(response, r'''$.data.license_plate'''));
    if (number != null) return number;
    number = castToType<String>(
        getJsonField(response, r'''$.data.registration_number'''));
    if (number != null) return number;
    // Do not fall back to admin vehicle_name (e.g. "Auto") — category label, not a plate.
    return null;
  }

  static String? vehicleModel(dynamic response) {
    // From socket payload
    var m = castToType<String>(getJsonField(response, r'''$.vehicle_model'''));
    if (m != null) return m;
    m = castToType<String>(getJsonField(response, r'''$.vehicle_name'''));
    if (m != null) return m;
    // From GET /api/drivers/:id
    m = castToType<String>(
        getJsonField(response, r'''$.data.vehicle.vehicle_model'''));
    if (m != null) return m;
    m = castToType<String>(
        getJsonField(response, r'''$.data.vehicle.vehicle_name'''));
    if (m != null) return m;
    m = castToType<String>(getJsonField(response, r'''$.data.vehicle_model'''));
    return m;
  }

  static String? vehicleColor(dynamic response) {
    var c = castToType<String>(getJsonField(response, r'''$.vehicle_color'''));
    if (c != null) return c;
    c = castToType<String>(
        getJsonField(response, r'''$.data.vehicle.vehicle_color'''));
    if (c != null) return c;
    return castToType<String>(
        getJsonField(response, r'''$.data.vehicle_color'''));
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
      apiUrl: '$_baseUrl/api/drivers/nearby',
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
      apiUrl: '$_baseUrl/api/rides/rides/cancel',
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

class RebookRideCall {
  static Future<ApiCallResponse> call({
    required int rideId,
    String? token = '',
    int extraFare = 0,
  }) async {
    final body = extraFare > 0 ? '{"extra_fare": $extraFare}' : '{}';
    return ApiManager.instance.makeApiCall(
      callName: 'rebookRide',
      apiUrl: '$_baseUrl/api/rides/rebook/$rideId',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      params: {},
      body: body,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
    );
  }

  static bool? success(dynamic response) => castToType<bool>(
        getJsonField(response, r'''$.success'''),
      );
  static String? message(dynamic response) => castToType<String>(
        getJsonField(response, r'''$.message'''),
      );
  static int? newRideId(dynamic response) => castToType<int>(
        getJsonField(response, r'''$.data.ride_id'''),
      );
  static double? estimatedFare(dynamic response) {
    final v = getJsonField(response, r'''$.data.estimated_fare''');
    if (v == null) return null;
    return double.tryParse(v.toString());
  }

  static double? extraFareResponse(dynamic response) {
    final v = getJsonField(response, r'''$.data.extra_fare''');
    if (v == null) return null;
    return double.tryParse(v.toString());
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// GetUserByIdCall
// GET  $baseUrl/api/users/{userId}
//
// Sample response:
// {
//   "success": true,
//   "statusCode": 200,
//   "message": "User retrieved successfully",
//   "data": {
//     "id": 19,
//     "first_name": "urvashi",
//     "last_name": "s",
//     "referral_code": "USR19THM3",
//     "coins_balance": 0,
//     ...
//   }
// }
// ─────────────────────────────────────────────────────────────────────────────

class GetUserByIdCall {
  static Future<ApiCallResponse> call({
    int? userId,
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'getUserById',
      apiUrl: '$_baseUrl/api/users/$userId',
      callType: ApiCallType.GET,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {},
      returnBody: true,
      cache: false,
    );
  }

  // ── Field extractors ──────────────────────────────────────────────────────
  // All extract directly from $.data.* matching the real API shape.
  // Using ?.toString() instead of castToType<String> to avoid silent null returns.

  static dynamic userData(dynamic response) =>
      getJsonField(response, r'''$.data''');

  static String? referralCode(dynamic response) =>
      getJsonField(response, r'''$.data.referral_code''')?.toString();

  static int? coinsBalance(dynamic response) {
    final raw = getJsonField(response, r'''$.data.coins_balance''');
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  static bool referralMasterBadge(dynamic response) {
    final raw = getJsonField(response, r'''$.data.referral_master_badge''');
    if (raw == null) return false;
    if (raw is bool) return raw;
    final s = raw.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  static String? firstName(dynamic response) =>
      getJsonField(response, r'''$.data.first_name''')?.toString();

  static String? lastName(dynamic response) =>
      getJsonField(response, r'''$.data.last_name''')?.toString();

  static int? userId(dynamic response) {
    final raw = getJsonField(response, r'''$.data.id''');
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  static String? mobileNumber(dynamic response) =>
      getJsonField(response, r'''$.data.mobile_number''')?.toString();

  static String? email(dynamic response) =>
      getJsonField(response, r'''$.data.email''')?.toString();

  static String? accountStatus(dynamic response) =>
      getJsonField(response, r'''$.data.account_status''')?.toString();

  static String? accountType(dynamic response) =>
      getJsonField(response, r'''$.data.account_type''')?.toString();

  static String? usedReferralCode(dynamic response) =>
      getJsonField(response, r'''$.data.used_referral_code''')?.toString();

  static double? overallRating(dynamic response) {
    final raw = getJsonField(response, r'''$.data.overall_rating''');
    if (raw == null) return null;
    if (raw is double) return raw;
    return double.tryParse(raw.toString());
  }

  static int? totalRides(dynamic response) {
    final raw = getJsonField(response, r'''$.data.total_rides''');
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }

  static bool? isBlocked(dynamic response) =>
      getJsonField(response, r'''$.data.is_blocked''') as bool?;

  static String? profileImage(dynamic response) =>
      getJsonField(response, r'''$.data.profile_image''')?.toString();

  static String? fcmToken(dynamic response) =>
      getJsonField(response, r'''$.data.fcm_token''')?.toString();
}

class GetAllNotificationsCall {
  static Future<ApiCallResponse> call({
    String? token = '',
    int page = 1,
    int pageSize = 50,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'getAllNotifications',
      apiUrl: '$_baseUrl/api/notifications/getall',
      callType: ApiCallType.GET,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {
        'page': page,
        'pageSize': pageSize,
      },
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

  /// Server-computed unread count for the authenticated rider inbox.
  static int? unreadCount(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$.data.unread_count''',
      ));
}

class MarkNotificationReadCall {
  static Future<ApiCallResponse> call({
    required int notificationId,
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'markNotificationRead',
      apiUrl: '$_baseUrl/api/notifications/mark-read/$notificationId',
      callType: ApiCallType.PATCH,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {},
      returnBody: true,
      cache: false,
    );
  }
}

class MarkAllNotificationsReadCall {
  static Future<ApiCallResponse> call({
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'markAllNotificationsRead',
      apiUrl: '$_baseUrl/api/notifications/read-all',
      callType: ApiCallType.PATCH,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {},
      returnBody: true,
      cache: false,
    );
  }
}

class GetwalletCall {
  static Future<ApiCallResponse> call({
    int? userId,
    String? token = '',
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'getwallet',
      apiUrl: '$_baseUrl/api/wallets/user/$userId',
      callType: ApiCallType.GET,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {},
      returnBody: true,
      cache: false,
    );
  }

  /// ✅ Wallet Balance (String)
  static String? walletBalance(dynamic response) => getJsonField(
        response,
        r'''$.data.wallet_balance''',
      )?.toString();

  /// Main + cashback (server); falls back to wallet_balance if absent.
  static String? spendableInr(dynamic response) =>
      getJsonField(response, r'''$.data.spendable_inr''')?.toString() ??
      walletBalance(response);

  /// Optional: Convert to double if needed
  static double? walletBalanceDouble(dynamic response) {
    final value = getJsonField(
      response,
      r'''$.data.wallet_balance''',
    )?.toString();
    return value != null ? double.tryParse(value) : null;
  }

  static String? totalRechargeAmount(dynamic response) => getJsonField(
        response,
        r'''$.data.total_recharge_amount''',
      )?.toString();

  static String? totalSpentAmount(dynamic response) => getJsonField(
        response,
        r'''$.data.total_spent_amount''',
      )?.toString();
}

/// GET /api/wallets/me/summary — main, cashback, coins, voucher count (rider JWT).
class GetWalletSummaryCall {
  static Future<ApiCallResponse> call({required String token}) async {
    return ApiManager.instance.makeApiCall(
      callName: 'getWalletSummary',
      apiUrl: '$_baseUrl/api/wallets/me/summary',
      callType: ApiCallType.GET,
      headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {},
      returnBody: true,
      cache: false,
    );
  }

  static double? mainWalletInr(dynamic response) {
    final v = getJsonField(response, r'''$.data.main_wallet_inr''');
    if (v == null) return null;
    return double.tryParse(v.toString());
  }

  static double? cashbackInr(dynamic response) {
    final v = getJsonField(response, r'''$.data.cashback_inr''');
    if (v == null) return null;
    return double.tryParse(v.toString());
  }

  static double? spendableInr(dynamic response) {
    final v = getJsonField(response, r'''$.data.spendable_inr''');
    if (v == null) return null;
    return double.tryParse(v.toString());
  }

  static int? coins(dynamic response) => castToType<int>(
        getJsonField(response, r'''$.data.coins'''),
      );

  static int? vouchersActiveCount(dynamic response) => castToType<int>(
        getJsonField(response, r'''$.data.vouchers_active_count'''),
      );

  /// Server-computed rupee equivalent (10 coins = ₹1).
  static double? coinsValueInr(dynamic response) {
    final v = getJsonField(response, r'''$.data.coins_value_inr''');
    if (v == null) return null;
    return double.tryParse(v.toString());
  }
}

/// GET /api/wallets/me/transactions — rider JWT; optional filters.
class GetWalletTransactionsMeCall {
  static Future<ApiCallResponse> call({
    required String token,
    int page = 1,
    int limit = 20,
    String? transactionType,
    String? from,
    String? to,
    String? q,
  }) async {
    final qp = <String, String>{
      'page': '$page',
      'limit': '$limit',
    };
    if (transactionType != null && transactionType.isNotEmpty) {
      qp['transaction_type'] = transactionType;
    }
    if (from != null && from.isNotEmpty) qp['from'] = from;
    if (to != null && to.isNotEmpty) qp['to'] = to;
    if (q != null && q.isNotEmpty) qp['q'] = q;
    final qs = qp.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');
    return ApiManager.instance.makeApiCall(
      callName: 'getWalletTransactionsMe',
      apiUrl: '$_baseUrl/api/wallets/me/transactions?$qs',
      callType: ApiCallType.GET,
      headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {},
      returnBody: true,
      cache: false,
    );
  }

  static List<dynamic>? transactions(dynamic response) =>
      getJsonField(response, r'''$.data.transactions''') as List<dynamic>?;
}

/// GET /api/users/me/vouchers — rider JWT; optional include_used=1.
class ListMyVouchersCall {
  static Future<ApiCallResponse> call({
    required String token,
    bool includeUsed = false,
  }) async {
    final q = includeUsed ? '?include_used=1' : '';
    return ApiManager.instance.makeApiCall(
      callName: 'listMyVouchers',
      apiUrl: '$_baseUrl/api/users/me/vouchers$q',
      callType: ApiCallType.GET,
      headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {},
      returnBody: true,
      cache: false,
    );
  }

  static List<dynamic>? vouchers(dynamic response) =>
      getJsonField(response, r'''$.data.vouchers''') as List<dynamic>?;
}

/// GET /api/payments/transactions?user_id=&page=&limit=
/// Authenticated user must match user_id (enforced by backend).
class GetUserTransactionsCall {
  static Future<ApiCallResponse> call({
    required int userId,
    required String token,
    int? page,
    int? limit,
  }) async {
    final p = page ?? 1;
    final lim = limit ?? 20;
    return ApiManager.instance.makeApiCall(
      callName: 'getUserTransactions',
      apiUrl:
          '$_baseUrl/api/payments/transactions?user_id=$userId&page=$p&limit=$lim',
      callType: ApiCallType.GET,
      headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      params: {},
      returnBody: true,
      cache: false,
    );
  }

  static List<dynamic>? transactions(dynamic response) =>
      getJsonField(response, r'$.data.transactions', true) as List?;

  static String? itemDescription(dynamic item) =>
      castToType<String>(getJsonField(item, r'$.description'));

  static String? itemType(dynamic item) =>
      castToType<String>(getJsonField(item, r'$.type'));

  static double? itemAmount(dynamic item) {
    final v = getJsonField(item, r'$.amount');
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static String? itemDate(dynamic item) {
    final d =
        getJsonField(item, r'$.created_at') ?? getJsonField(item, r'$.date');
    return d?.toString();
  }
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

    final token = FFAppState().accessToken;

    if (kDebugMode) {
      print('📤 API Request Body: $ffApiRequestBody');
    }

    return ApiManager.instance.makeApiCall(
      callName: 'submitRideRating',
      apiUrl: '$_baseUrl/api/ratings/post',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
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
      apiUrl: '$_baseUrl/api/promo-codes/getall',
      callType: ApiCallType.GET,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
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

/// ---------------------------------------------------------------------------
/// UPDATE RIDE STATUS
/// ---------------------------------------------------------------------------

class UpdateRideStatusCall {
  static Future<ApiCallResponse> call({
    required int? rideId,
    required String? status,
    // allowed: qr_scan | accepted | arrived | started | completed
    String? token = '',
    int retryCount = 0,
  }) async {
    const int maxRetries = 3;
    const Duration delayDuration = Duration(seconds: 2);

    ApiCallResponse? response;
    int currentRetry = retryCount;

    final Map<String, dynamic> requestBody = {
      "ride_id": rideId,
      "status": status,
    };

    while (currentRetry <= maxRetries) {
      response = await ApiManager.instance.makeApiCall(
        callName: 'UpdateRideStatus',
        apiUrl: '$_baseUrl/api/drivers/update-ride-status',
        callType: ApiCallType.POST,
        headers: {
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        params: {},
        body: jsonEncode(requestBody),
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
            'UpdateRideStatus failed (status: ${response.statusCode}). Retrying...',
          );
        }
        currentRetry++;
        if (currentRetry <= maxRetries) {
          await Future.delayed(delayDuration);
        }
      }
    }
    return response!;
  }

  // ✅ Response helpers
  static bool? success(dynamic response) =>
      castToType<bool>(getJsonField(response, r'''$.success'''));

  static String? updatedStatus(dynamic response) =>
      castToType<String>(getJsonField(response, r'''$.data.status'''));

  static int? rideId(dynamic response) =>
      castToType<int>(getJsonField(response, r'''$.data.ride_id'''));
}

/// ---------------------------------------------------------------------------
/// EMERGENCY SOS
/// ---------------------------------------------------------------------------

class EmergencySosCall {
  static Future<ApiCallResponse> call({
    required int rideId,
    required int userId,
    required double latitude,
    required double longitude,
    String? token,
  }) async {
    final body = {
      'ride_id': rideId,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
    };
    return ApiManager.instance.makeApiCall(
      callName: 'EmergencySos',
      apiUrl: '$_baseUrl/api/users/emergencysos',
      callType: ApiCallType.POST,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      params: {},
      body: jsonEncode(body),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static bool? success(dynamic response) =>
      castToType<bool>(getJsonField(response, r'$.success'));
}

/// ---------------------------------------------------------------------------
/// SUPPORT TICKETS
/// ---------------------------------------------------------------------------

class CreateSupportTicketCall {
  static Future<ApiCallResponse> call({
    required String ticketType,
    required String ticketTitle,
    required String ticketDescription,
    required int userId,
    String priorityLevel = 'medium',
    String? token,
  }) async {
    final body = {
      'ticket_type': ticketType,
      'ticket_title': ticketTitle,
      'ticket_description': ticketDescription,
      'user_id': userId,
      'priority_level': priorityLevel,
    };
    return ApiManager.instance.makeApiCall(
      callName: 'CreateSupportTicket',
      apiUrl: '$_baseUrl/api/support-tickets/post',
      callType: ApiCallType.POST,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      params: {},
      body: jsonEncode(body),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static bool? success(dynamic response) =>
      castToType<bool>(getJsonField(response, r'$.success'));
  static int? ticketId(dynamic response) =>
      castToType<int>(getJsonField(response, r'$.data.id'));
}

class GetSupportTicketCall {
  static Future<ApiCallResponse> call({
    required int ticketId,
    String? token,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'GetSupportTicket',
      apiUrl: '$_baseUrl/api/support-tickets/$ticketId',
      callType: ApiCallType.GET,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {},
      returnBody: true,
      cache: false,
    );
  }

  static Map<String, dynamic>? data(dynamic response) {
    final d = getJsonField(response, r'$.data');
    return d is Map ? Map<String, dynamic>.from(d) : null;
  }
}

class DeleteSupportTicketCall {
  static Future<ApiCallResponse> call({
    required int ticketId,
    String? token,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'DeleteSupportTicket',
      apiUrl: '$_baseUrl/api/support-tickets/$ticketId',
      callType: ApiCallType.DELETE,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {},
      returnBody: true,
      cache: false,
    );
  }

  static bool? success(dynamic response) =>
      castToType<bool>(getJsonField(response, r'$.success'));
}

/// ---------------------------------------------------------------------------
/// RIDE CHAT (REST — same thread every time you open; complements WebSocket)
/// ---------------------------------------------------------------------------

class RideChatGetMessagesCall {
  static Future<ApiCallResponse> call({
    required int rideId,
    String? token,
    int? beforeId,
    int limit = 100,
  }) async {
    final q = <String, String>{
      'limit': limit.clamp(1, 100).toString(),
      if (beforeId != null) 'before_id': beforeId.toString(),
    };
    final qs = q.entries.map((e) => '${e.key}=${e.value}').join('&');
    return ApiManager.instance.makeApiCall(
      callName: 'RideChatGetMessages',
      apiUrl: '$_baseUrl/api/chat/ride/$rideId/messages?$qs',
      callType: ApiCallType.GET,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {},
      returnBody: true,
      cache: false,
    );
  }
}

class RideChatMarkReadCall {
  static Future<ApiCallResponse> call({
    required int rideId,
    String? token,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'RideChatMarkRead',
      apiUrl: '$_baseUrl/api/chat/ride/$rideId/read',
      callType: ApiCallType.POST,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      params: {},
      returnBody: true,
      cache: false,
      alwaysAllowBody: true,
    );
  }
}

class RideChatInitCall {
  static Future<ApiCallResponse> call({
    required int rideId,
    String? token,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'RideChatInit',
      apiUrl: '$_baseUrl/api/chat/ride/init',
      callType: ApiCallType.POST,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      params: {},
      body: jsonEncode({'ride_id': rideId}),
      bodyType: BodyType.JSON,
      returnBody: true,
      cache: false,
      alwaysAllowBody: true,
    );
  }
}

/// Registers FCM token for ride-chat pushes (`user_notification_tokens` on backend).
class RideChatRegisterDeviceTokenCall {
  static Future<ApiCallResponse> call({
    required String fcmToken,
    String? platform,
    String? accessToken,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'RideChatRegisterDeviceToken',
      apiUrl: '$_baseUrl/api/chat/device/token',
      callType: ApiCallType.POST,
      headers: {
        if (accessToken != null && accessToken.isNotEmpty)
          'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      params: {},
      body: jsonEncode({
        'fcm_token': fcmToken,
        if (platform != null && platform.isNotEmpty) 'platform': platform,
      }),
      bodyType: BodyType.JSON,
      returnBody: true,
      cache: false,
      alwaysAllowBody: true,
    );
  }
}

/// ---------------------------------------------------------------------------
/// AI AGENT (LLM + server-side database snapshot)
/// ---------------------------------------------------------------------------

class AiAgentChatCall {
  static Future<ApiCallResponse> call({
    required String message,
    String? token,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'AiAgentChat',
      apiUrl: '$_baseUrl/api/ai/agent/chat',
      callType: ApiCallType.POST,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      params: {},
      body: jsonEncode({'message': message}),
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? replyText(dynamic response) =>
      getJsonField(response, r'$.data.reply')?.toString();
}

class AuthGetSessionsCall {
  static Future<ApiCallResponse> call({
    required String token,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'authGetSessions',
      apiUrl: '$_baseUrl/api/auth/sessions',
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

class AuthLogoutAllCall {
  static Future<ApiCallResponse> call({
    required String token,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'authLogoutAll',
      apiUrl: '$_baseUrl/api/auth/logout-all',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      params: {},
      body: '{}',
      bodyType: BodyType.JSON,
      returnBody: true,
      cache: false,
      alwaysAllowBody: true,
    );
  }
}

class AuthRevokeSessionCall {
  static Future<ApiCallResponse> call({
    required String token,
    required int sessionId,
  }) async {
    return ApiManager.instance.makeApiCall(
      callName: 'authRevokeSession',
      apiUrl: '$_baseUrl/api/auth/revoke-session/$sessionId',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      params: {},
      body: '{}',
      bodyType: BodyType.JSON,
      returnBody: true,
      cache: false,
      alwaysAllowBody: true,
    );
  }
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
