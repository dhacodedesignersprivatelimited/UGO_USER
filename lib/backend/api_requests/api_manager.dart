// ignore_for_file: constant_identifier_names, depend_on_referenced_packages, prefer_final_fields

import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;

import 'network_exceptions_io.dart'
    if (dart.library.html) 'network_exceptions_stub.dart' as net;
import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime_type/mime_type.dart';

import '/app_state.dart';
import '/core/app_config.dart';
import '/flutter_flow/uploaded_file.dart';

import 'get_streamed_response.dart';
import 'http_client.dart';

enum ApiCallType {
  GET,
  POST,
  DELETE,
  PUT,
  PATCH,
}

enum BodyType {
  NONE,
  JSON,
  TEXT,
  X_WWW_FORM_URL_ENCODED,
  MULTIPART,
}

class ApiCallOptions extends Equatable {
  const ApiCallOptions({
    this.callName = '',
    required this.callType,
    required this.apiUrl,
    required this.headers,
    required this.params,
    this.bodyType,
    this.body,
    this.returnBody = true,
    this.encodeBodyUtf8 = false,
    this.decodeUtf8 = false,
    this.alwaysAllowBody = false,
    this.cache = false,
    this.isStreamingApi = false,
  });

  final String callName;
  final ApiCallType callType;
  final String apiUrl;
  final Map<String, dynamic> headers;
  final Map<String, dynamic> params;
  final BodyType? bodyType;
  final String? body;
  final bool returnBody;
  final bool encodeBodyUtf8;
  final bool decodeUtf8;
  final bool alwaysAllowBody;
  final bool cache;
  final bool isStreamingApi;

  /// Creates a new [ApiCallOptions] with optionally updated parameters.
  ///
  /// This helper function allows creating a copy of the current options while
  /// selectively modifying specific fields. Any parameter that is not provided
  /// will retain its original value from the current instance.
  ApiCallOptions copyWith({
    String? callName,
    ApiCallType? callType,
    String? apiUrl,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? params,
    BodyType? bodyType,
    String? body,
    bool? returnBody,
    bool? encodeBodyUtf8,
    bool? decodeUtf8,
    bool? alwaysAllowBody,
    bool? cache,
    bool? isStreamingApi,
  }) {
    return ApiCallOptions(
      callName: callName ?? this.callName,
      callType: callType ?? this.callType,
      apiUrl: apiUrl ?? this.apiUrl,
      headers: headers ?? _cloneMap(this.headers),
      params: params ?? _cloneMap(this.params),
      bodyType: bodyType ?? this.bodyType,
      body: body ?? this.body,
      returnBody: returnBody ?? this.returnBody,
      encodeBodyUtf8: encodeBodyUtf8 ?? this.encodeBodyUtf8,
      decodeUtf8: decodeUtf8 ?? this.decodeUtf8,
      alwaysAllowBody: alwaysAllowBody ?? this.alwaysAllowBody,
      cache: cache ?? this.cache,
      isStreamingApi: isStreamingApi ?? this.isStreamingApi,
    );
  }

  ApiCallOptions clone() => ApiCallOptions(
        callName: callName,
        callType: callType,
        apiUrl: apiUrl,
        headers: _cloneMap(headers),
        params: _cloneMap(params),
        bodyType: bodyType,
        body: body,
        returnBody: returnBody,
        encodeBodyUtf8: encodeBodyUtf8,
        decodeUtf8: decodeUtf8,
        alwaysAllowBody: alwaysAllowBody,
        cache: cache,
        isStreamingApi: isStreamingApi,
      );

  @override
  List<Object?> get props => [
        callName,
        callType.name,
        apiUrl,
        headers,
        params,
        bodyType,
        body,
        returnBody,
        encodeBodyUtf8,
        decodeUtf8,
        alwaysAllowBody,
        cache,
        isStreamingApi,
      ];

  static Map<String, dynamic> _cloneMap(Map<String, dynamic> map) {
    try {
      return json.decode(json.encode(map)) as Map<String, dynamic>;
    } catch (_) {
      return Map.from(map);
    }
  }
}

class ApiCallResponse {
  const ApiCallResponse(
    this.jsonBody,
    this.headers,
    this.statusCode, {
    this.response,
    this.streamedResponse,
    this.exception,
  });
  final dynamic jsonBody;
  final Map<String, String> headers;
  final int statusCode;
  final http.Response? response;
  final http.StreamedResponse? streamedResponse;
  final Object? exception;
  // Whether we received a 2xx status (which generally marks success).
  bool get succeeded => statusCode >= 200 && statusCode < 300;
  String getHeader(String headerName) => headers[headerName] ?? '';
  // Return the raw body from the response, or if this came from a cloud call
  // and the body is not a string, then the json encoded body.
  String get bodyText =>
      response?.body ??
      (jsonBody is String ? jsonBody as String : jsonEncode(jsonBody));
  String get exceptionMessage => exception.toString();
  String get userFriendlyMessage {
    if (statusCode == 401 || statusCode == 403) {
      return 'Your session expired. Please sign in again.';
    }
    if (statusCode >= 500) {
      return 'Server is busy right now. Please try again in a moment.';
    }
    if (statusCode == 0 || statusCode == -1) {
      return 'Network issue detected. Check your connection and try again.';
    }
    final serverMessage = _extractServerMessage(jsonBody);
    if (serverMessage != null && serverMessage.isNotEmpty) {
      return serverMessage;
    }
    return succeeded
        ? 'Request completed successfully.'
        : 'Something went wrong. Please try again.';
  }

  /// Creates a new [ApiCallResponse] with optionally updated parameters.
  ///
  /// This helper function allows creating a copy of the current response while
  /// selectively modifying specific fields. Any parameter that is not provided
  /// will retain its original value from the current instance.
  ApiCallResponse copyWith({
    dynamic jsonBody,
    Map<String, String>? headers,
    int? statusCode,
    http.Response? response,
    http.StreamedResponse? streamedResponse,
    Object? exception,
  }) {
    return ApiCallResponse(
      jsonBody ?? this.jsonBody,
      headers ?? this.headers,
      statusCode ?? this.statusCode,
      response: response ?? this.response,
      streamedResponse: streamedResponse ?? this.streamedResponse,
      exception: exception ?? this.exception,
    );
  }

  static ApiCallResponse fromHttpResponse(
    http.Response response,
    bool returnBody,
    bool decodeUtf8,
  ) {
    dynamic jsonBody;
    try {
      final responseBody = decodeUtf8 && returnBody
          ? const Utf8Decoder().convert(response.bodyBytes)
          : response.body;
      jsonBody = returnBody ? json.decode(responseBody) : null;
    } catch (_) {}
    return ApiCallResponse(
      jsonBody,
      response.headers,
      response.statusCode,
      response: response,
    );
  }

  static ApiCallResponse fromCloudCallResponse(Map<String, dynamic> response) =>
      ApiCallResponse(
        response['body'],
        ApiManager.toStringMap(response['headers'] ?? {}),
        response['statusCode'] ?? 400,
      );

  static String? _extractServerMessage(dynamic body) {
    if (body is Map) {
      final dynamic message = body['message'] ?? body['error'] ?? body['detail'];
      if (message != null) return message.toString();
    }
    if (body is String && body.isNotEmpty) return body;
    return null;
  }
}

class ApiManager {
  ApiManager._();

  // Cache that will ensure identical calls are not repeatedly made.
  static Map<ApiCallOptions, ApiCallResponse> _apiCache = {};
  static Future<String?>? _refreshInFlight;
  static void Function()? onAccessTokenRefreshed;
  static void Function(String? reason)? onUnauthenticated;

  static ApiManager? _instance;
  static ApiManager get instance => _instance ??= ApiManager._();

  /// Invalidates cached results for a given call (e.g. when data changes).
  static void clearCache(String callName) => _apiCache.keys
      .toSet()
      .forEach((k) => k.callName == callName ? _apiCache.remove(k) : null);

  static Map<String, String> toStringMap(Map map) =>
      map.map((key, value) => MapEntry(key.toString(), value.toString()));

  static String asQueryParams(Map<String, dynamic> map) => map.entries
      .map((e) =>
          "${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value.toString())}")
      .join('&');

  static String _platformLabel() =>
      kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();

  static Map<String, dynamic> _injectDeviceHeaders(Map<String, dynamic> headers) {
    final withHeaders = Map<String, dynamic>.from(headers);
    final appState = FFAppState();
    if (appState.deviceId.isNotEmpty &&
        !withHeaders.keys.any((k) => k.toLowerCase() == 'x-device-id')) {
      withHeaders['x-device-id'] = appState.deviceId;
    }
    if (!withHeaders.keys.any((k) => k.toLowerCase() == 'x-platform')) {
      withHeaders['x-platform'] = _platformLabel();
    }
    return withHeaders;
  }

  static Future<ApiCallResponse> urlRequest(
    ApiCallType callType,
    String apiUrl,
    Map<String, dynamic> headers,
    Map<String, dynamic> params,
    bool returnBody,
    bool decodeUtf8,
    bool isStreamingApi, {
    http.Client? client,
  }) async {
    final c = client ?? TimeoutHttpClient.instance;
    if (params.isNotEmpty) {
      final specifier =
          Uri.parse(apiUrl).queryParameters.isNotEmpty ? '&' : '?';
      apiUrl = '$apiUrl$specifier${asQueryParams(params)}';
    }
    if (isStreamingApi) {
      final request =
          http.Request(callType.toString().split('.').last, Uri.parse(apiUrl))
            ..headers.addAll(toStringMap(headers));
      final streamedResponse = await getStreamedResponse(request);
      return ApiCallResponse(
        null,
        streamedResponse.headers,
        streamedResponse.statusCode,
        streamedResponse: streamedResponse,
      );
    }
    final makeRequest = callType == ApiCallType.GET ? c.get : c.delete;
    final response =
        await makeRequest(Uri.parse(apiUrl), headers: toStringMap(headers));
    return ApiCallResponse.fromHttpResponse(response, returnBody, decodeUtf8);
  }

  static Future<ApiCallResponse> requestWithBody(
    ApiCallType type,
    String apiUrl,
    Map<String, dynamic> headers,
    Map<String, dynamic> params,
    String? body,
    BodyType? bodyType,
    bool returnBody,
    bool encodeBodyUtf8,
    bool decodeUtf8,
    bool alwaysAllowBody,
    bool isStreamingApi, {
    http.Client? client,
  }) async {
    final c = client ?? TimeoutHttpClient.instance;
    assert(
      {ApiCallType.POST, ApiCallType.PUT, ApiCallType.PATCH}.contains(type) ||
          (alwaysAllowBody && type == ApiCallType.DELETE),
      'Invalid ApiCallType $type for request with body',
    );
    final postBody =
        createBody(headers, params, body, bodyType, encodeBodyUtf8);
    if (isStreamingApi) {
      final request =
          http.Request(type.toString().split('.').last, Uri.parse(apiUrl))
            ..headers.addAll(toStringMap(headers));
      request.body = postBody;
      final streamedResponse = await getStreamedResponse(request);
      return ApiCallResponse(
        null,
        streamedResponse.headers,
        streamedResponse.statusCode,
        streamedResponse: streamedResponse,
      );
    }

    if (bodyType == BodyType.MULTIPART) {
      return multipartRequest(type, apiUrl, headers, params, returnBody,
          decodeUtf8, alwaysAllowBody);
    }

    final requestFn = {
      ApiCallType.POST: c.post,
      ApiCallType.PUT: c.put,
      ApiCallType.PATCH: c.patch,
      ApiCallType.DELETE: c.delete,
    }[type]!;
    final response = await requestFn(Uri.parse(apiUrl),
        headers: toStringMap(headers), body: postBody);
    return ApiCallResponse.fromHttpResponse(response, returnBody, decodeUtf8);
  }

  static Future<ApiCallResponse> multipartRequest(
    ApiCallType? type,
    String apiUrl,
    Map<String, dynamic> headers,
    Map<String, dynamic> params,
    bool returnBody,
    bool decodeUtf8,
    bool alwaysAllowBody,
  ) async {
    assert(
      {ApiCallType.POST, ApiCallType.PUT, ApiCallType.PATCH}.contains(type) ||
          (alwaysAllowBody && type == ApiCallType.DELETE),
      'Invalid ApiCallType $type for request with body',
    );

    bool isFile(dynamic e) =>
        e is FFUploadedFile ||
        e is List<FFUploadedFile> ||
        (e is List && e.firstOrNull is FFUploadedFile);

    final nonFileParams = toStringMap(
        Map.fromEntries(params.entries.where((e) => !isFile(e.value))));

    List<http.MultipartFile> files = [];
    params.entries.where((e) => isFile(e.value)).forEach((e) {
      final param = e.value;
      final uploadedFiles = param is List
          ? param as List<FFUploadedFile>
          : [param as FFUploadedFile];
      for (var uploadedFile in uploadedFiles) {
        files.add(
          http.MultipartFile.fromBytes(
            e.key,
            uploadedFile.bytes ?? Uint8List.fromList([]),
            filename: uploadedFile.name,
            contentType: _getMediaType(uploadedFile.name),
          ),
        );
      }
    });

    final request = http.MultipartRequest(
        type.toString().split('.').last, Uri.parse(apiUrl))
      ..headers.addAll(toStringMap(headers))
      ..files.addAll(files);
    nonFileParams.forEach((key, value) => request.fields[key] = value);

    final streamedResponse =
        await TimeoutHttpClient.instance.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    return ApiCallResponse.fromHttpResponse(response, returnBody, decodeUtf8);
  }

  static MediaType? _getMediaType(String? filename) {
    final contentType = mime(filename);
    if (contentType == null) {
      return null;
    }
    final parts = contentType.split('/');
    if (parts.length != 2) {
      return null;
    }
    return MediaType(parts.first, parts.last);
  }

  static dynamic createBody(
    Map<String, dynamic> headers,
    Map<String, dynamic>? params,
    String? body,
    BodyType? bodyType,
    bool encodeBodyUtf8,
  ) {
    String? contentType;
    dynamic postBody;
    switch (bodyType) {
      case BodyType.JSON:
        contentType = 'application/json';
        postBody = body ?? json.encode(params ?? {});
        break;
      case BodyType.TEXT:
        contentType = 'text/plain';
        postBody = body ?? json.encode(params ?? {});
        break;
      case BodyType.X_WWW_FORM_URL_ENCODED:
        contentType = 'application/x-www-form-urlencoded';
        postBody = toStringMap(params ?? {});
        break;
      case BodyType.MULTIPART:
        contentType = 'multipart/form-data';
        postBody = params;
        break;
      case BodyType.NONE:
      case null:
        break;
    }
    // Set "Content-Type" header if it was previously unset.
    if (contentType != null &&
        !headers.keys.any((h) => h.toLowerCase() == 'content-type')) {
      headers['Content-Type'] = contentType;
    }
    return encodeBodyUtf8 && postBody is String
        ? utf8.encode(postBody)
        : postBody;
  }

  Future<ApiCallResponse> call(
    ApiCallOptions options, {
    http.Client? client,
  }) =>
      makeApiCall(
        callName: options.callName,
        apiUrl: options.apiUrl,
        callType: options.callType,
        headers: options.headers,
        params: options.params,
        body: options.body,
        bodyType: options.bodyType,
        returnBody: options.returnBody,
        encodeBodyUtf8: options.encodeBodyUtf8,
        decodeUtf8: options.decodeUtf8,
        alwaysAllowBody: options.alwaysAllowBody,
        cache: options.cache,
        isStreamingApi: options.isStreamingApi,
        options: options,
        client: client,
      );

  /// Whether a failure is transient and safe to retry.
  static bool _isTransientFailure(Object? error, ApiCallResponse? response) {
    if (net.isTransientNetworkError(error)) return true;
    if (response != null) {
      final code = response.statusCode;
      if (code == 502 || code == 503 || code == 504) return true;
    }
    return false;
  }

  static bool _isAuthFailure(ApiCallResponse response) {
    if (response.statusCode == 401 || response.statusCode == 403) return true;
    final body = response.bodyText.toLowerCase();
    return body.contains('invalid or expired access token') ||
        body.contains('invalid token') ||
        body.contains('token expired') ||
        body.contains('jwt expired') ||
        body.contains('unauthorized');
  }

  static String? _extractBearerToken(Map<String, dynamic> headers) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'authorization') {
        final value = entry.value?.toString() ?? '';
        const prefix = 'bearer ';
        if (value.toLowerCase().startsWith(prefix)) {
          return value.substring(prefix.length).trim();
        }
      }
    }
    return null;
  }

  static Map<String, dynamic> _headersWithAccessToken(
    Map<String, dynamic> headers,
    String accessToken,
  ) {
    final updated = Map<String, dynamic>.from(headers);
    String? existingAuthKey;
    for (final key in updated.keys) {
      if (key.toLowerCase() == 'authorization') {
        existingAuthKey = key;
        break;
      }
    }
    updated[existingAuthKey ?? 'Authorization'] = 'Bearer $accessToken';
    return updated;
  }

  static String? _extractTokenFromBody(dynamic body, List<String> keys) {
    if (body is! Map) return null;
    final data = body['data'];
    for (final key in keys) {
      final direct = body[key];
      if (direct is String && direct.isNotEmpty) return direct;
      if (data is Map) {
        final nested = data[key];
        if (nested is String && nested.isNotEmpty) return nested;
      }
    }
    return null;
  }

  static Future<String?> _tryRefreshAccessToken(String oldAccessToken) async {
    if (_refreshInFlight != null) {
      return _refreshInFlight;
    }
    final completer = Completer<String?>();
    _refreshInFlight = completer.future;
    final appState = FFAppState();
    final refreshToken = appState.refreshToken;
    if (refreshToken.isEmpty) {
      completer.complete(null);
      _refreshInFlight = null;
      return null;
    }

    final endpoints = <String>[
      '/api/auth/refresh',
      '/api/users/refresh-token',
      '/api/users/refresh',
      '/api/auth/refresh-token',
    ];

    for (final path in endpoints) {
      try {
        final response = await TimeoutHttpClient.instance.post(
          Uri.parse('${AppConfig.baseApiUrl}$path'),
          headers: {
            'Content-Type': 'application/json',
            ..._injectDeviceHeaders(const {}),
          },
          body: jsonEncode({
            'refreshToken': refreshToken,
            'refresh_token': refreshToken,
            'accessToken': oldAccessToken,
            'access_token': oldAccessToken,
          }),
        );
        if (response.statusCode < 200 || response.statusCode >= 300) continue;

        dynamic decoded;
        try {
          decoded = jsonDecode(response.body);
        } catch (_) {
          continue;
        }

        final newAccessToken = _extractTokenFromBody(
          decoded,
          const ['accessToken', 'access_token', 'token'],
        );
        if (newAccessToken == null || newAccessToken.isEmpty) continue;

        final newRefreshToken = _extractTokenFromBody(
          decoded,
          const ['refreshToken', 'refresh_token'],
        );

        appState.accessToken = newAccessToken;
        if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
          appState.refreshToken = newRefreshToken;
        }
        onAccessTokenRefreshed?.call();
        completer.complete(newAccessToken);
        _refreshInFlight = null;
        return newAccessToken;
      } catch (_) {
        // Try next endpoint candidate.
      }
    }
    completer.complete(null);
    _refreshInFlight = null;
    return null;
  }

  Future<ApiCallResponse> makeApiCall({
    required String callName,
    required String apiUrl,
    required ApiCallType callType,
    Map<String, dynamic> headers = const {},
    Map<String, dynamic> params = const {},
    String? body,
    BodyType? bodyType,
    bool returnBody = true,
    bool encodeBodyUtf8 = false,
    bool decodeUtf8 = false,
    bool alwaysAllowBody = false,
    bool cache = false,
    bool isStreamingApi = false,
    bool enableRetry = true,
    bool hasRetriedAuth = false,
    ApiCallOptions? options,
    http.Client? client,
  }) async {
    headers = _injectDeviceHeaders(headers);
    final callOptions = options ??
        ApiCallOptions(
          callName: callName,
          callType: callType,
          apiUrl: apiUrl,
          headers: headers,
          params: params,
          bodyType: bodyType,
          body: body,
          returnBody: returnBody,
          encodeBodyUtf8: encodeBodyUtf8,
          decodeUtf8: decodeUtf8,
          alwaysAllowBody: alwaysAllowBody,
          cache: cache,
          isStreamingApi: isStreamingApi,
        );
    if (!apiUrl.startsWith('http')) {
      apiUrl = 'https://$apiUrl';
    }

    // If we've already made this exact call before and caching is on,
    // return the cached result.
    if (cache && _apiCache.containsKey(callOptions)) {
      return _apiCache[callOptions]!;
    }

    const int maxRetries = 3;
    const List<Duration> backoffDelays = [
      Duration(seconds: 1),
      Duration(seconds: 2),
      Duration(seconds: 4),
    ];

    ApiCallResponse? result;
    Object? lastError;
    int attempt = 0;

    while (true) {
      result = null;
      lastError = null;

      try {
        switch (callType) {
          case ApiCallType.GET:
            result = await urlRequest(
              callType,
              apiUrl,
              headers,
              params,
              returnBody,
              decodeUtf8,
              isStreamingApi,
              client: client,
            );
            break;
          case ApiCallType.DELETE:
            result = alwaysAllowBody
                ? await requestWithBody(
                    callType,
                    apiUrl,
                    headers,
                    params,
                    body,
                    bodyType,
                    returnBody,
                    encodeBodyUtf8,
                    decodeUtf8,
                    alwaysAllowBody,
                    isStreamingApi,
                    client: client,
                  )
                : await urlRequest(
                    callType,
                    apiUrl,
                    headers,
                    params,
                    returnBody,
                    decodeUtf8,
                    isStreamingApi,
                    client: client,
                  );
            break;
          case ApiCallType.POST:
          case ApiCallType.PUT:
          case ApiCallType.PATCH:
            result = await requestWithBody(
              callType,
              apiUrl,
              headers,
              params,
              body,
              bodyType,
              returnBody,
              encodeBodyUtf8,
              decodeUtf8,
              alwaysAllowBody,
              isStreamingApi,
              client: client,
            );
            break;
        }
      } catch (e) {
        lastError = e;
        result = ApiCallResponse(null, {}, -1, exception: e);
      }

      final shouldRetry = enableRetry &&
          attempt < maxRetries &&
          _isTransientFailure(lastError, result);

      if (!shouldRetry) {
        break;
      }

      await Future<void>.delayed(backoffDelays[attempt]);
      attempt++;
    }

    var response = result;

    final requestToken = _extractBearerToken(headers);
    final currentToken = FFAppState().accessToken;
    final canAttemptRefresh = !hasRetriedAuth &&
        response.statusCode > 0 &&
        _isAuthFailure(response) &&
        requestToken != null &&
        requestToken.isNotEmpty &&
        currentToken.isNotEmpty;

    if (canAttemptRefresh) {
      final refreshedToken = await _tryRefreshAccessToken(currentToken);
      if (refreshedToken != null && refreshedToken.isNotEmpty) {
        final updatedHeaders = _headersWithAccessToken(headers, refreshedToken);
        response = await makeApiCall(
          callName: callName,
          apiUrl: apiUrl,
          callType: callType,
          headers: updatedHeaders,
          params: params,
          body: body,
          bodyType: bodyType,
          returnBody: returnBody,
          encodeBodyUtf8: encodeBodyUtf8,
          decodeUtf8: decodeUtf8,
          alwaysAllowBody: alwaysAllowBody,
          cache: cache,
          isStreamingApi: isStreamingApi,
          enableRetry: enableRetry,
          hasRetriedAuth: true,
          client: client,
        );
      } else {
        onUnauthenticated?.call('refresh_failed');
      }
    }

    if (response.statusCode == 401) {
      final body = response.jsonBody;
      String? reason;
      if (body is Map) {
        reason = (body['code'] ?? (body['data'] is Map ? body['data']['code'] : null))
            ?.toString();
      }
      onUnauthenticated?.call(reason);
    }

    if (cache && response.statusCode >= 200 && response.statusCode < 300) {
      _apiCache[callOptions] = response;
    }

    return response;
  }
}
