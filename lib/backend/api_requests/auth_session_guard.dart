import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Result of a refresh attempt.
/// - [refreshed]: new tokens stored → retry the request.
/// - [rejected]: the server refused the session (expired / revoked / blocked) → log out.
/// - [transient]: network error, timeout, 5xx… → keep the session, don't log out.
enum RefreshOutcome { refreshed, rejected, transient }

/// Single place that decides what an auth failure means, shared by every HTTP
/// path in the app (ApiManager, Dio, raw http).
///
/// Rules (backend sends a `code`, see backend utils/authErrors.js):
/// - Only requests that carried a Bearer token can end the session; public calls
///   (login, signup, OTP) never trigger logout.
/// - 401 TOKEN_EXPIRED / TOKEN_INVALID (or no code, for older servers) → one shared
///   refresh (single-flight), then retry once with the new token.
/// - If another request already refreshed, just retry with the current token.
/// - 401 SESSION_* / ACCOUNT_NOT_FOUND / REFRESH_* / TOKEN_MISSING → logout.
/// - 403 ACCOUNT_BLOCKED → logout. Any other 403 is a permission error → no logout.
/// - Network failures and 5xx never log out.
/// - Logout fires at most once per burst (several 401s at the same time).
/// Tokens are never logged.
class AuthSessionGuard {
  AuthSessionGuard._();

  static const Set<String> _sessionEndingCodes = {
    'SESSION_REVOKED',
    'SESSION_REPLACED',
    'ACCOUNT_NOT_FOUND',
    'ACCOUNT_BLOCKED',
    'REFRESH_EXPIRED',
    'REFRESH_INVALID',
    'TOKEN_MISSING',
  };

  // ---- Configured once by ApiManager --------------------------------------
  static String Function() baseUrl = () => '';
  static String Function() readAccessToken = () => '';
  static String Function() readRefreshToken = () => '';
  static void Function(String access, String? refresh) writeTokens = (_, __) {};
  static Map<String, String> Function() extraHeaders = () => const {};
  static void Function()? onRefreshed;
  static void Function(String reason)? onSessionEnded;
  static bool configured = false;

  static Future<RefreshOutcome>? _inFlight;
  static DateTime? _lastSessionEndAt;

  static void _log(String msg) => debugPrint('[auth] $msg');

  @visibleForTesting
  static void resetForTest() {
    _inFlight = null;
    _lastSessionEndAt = null;
  }

  /// Backend auth code from any response shape (`code`, `error.code`, `data.code`).
  static String? codeOf(dynamic body) {
    if (body is! Map) return null;
    String? pick(dynamic m) =>
        (m is Map && m['code'] != null) ? m['code'].toString() : null;
    final code = pick(body) ?? pick(body['error']) ?? pick(body['data']);
    if (code != null) return code;
    // Older servers: only a reason string.
    final reason = (body['reason'] ?? (body['error'] is Map ? body['error']['reason'] : null))
        ?.toString();
    if (reason != null && reason.contains('another_device')) return 'SESSION_REPLACED';
    return null;
  }

  static bool endsSession(int status, dynamic body) {
    final code = codeOf(body);
    if (status == 403) return code == 'ACCOUNT_BLOCKED';
    if (status == 401) return code != null && _sessionEndingCodes.contains(code);
    return false;
  }

  /// Single-flight refresh: concurrent callers share one network call.
  static Future<RefreshOutcome> refresh() {
    final existing = _inFlight;
    if (existing != null) return existing;
    final future = _doRefresh();
    _inFlight = future;
    future.whenComplete(() => _inFlight = null);
    return future;
  }

  static Future<RefreshOutcome> _doRefresh() async {
    final refreshToken = readRefreshToken();
    if (refreshToken.isEmpty) {
      _log('no refresh token stored → cannot refresh');
      return RefreshOutcome.rejected;
    }
    try {
      final res = await http
          .post(
            Uri.parse('${baseUrl()}/api/auth/refresh'),
            headers: {'Content-Type': 'application/json', ...extraHeaders()},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(const Duration(seconds: 15));
      dynamic body;
      try {
        body = jsonDecode(res.body);
      } catch (_) {}

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final access = _pickToken(body, const ['accessToken', 'access_token']);
        final refresh = _pickToken(body, const ['refreshToken', 'refresh_token']);
        if (access == null) {
          _log('refresh response had no access token → treating as transient');
          return RefreshOutcome.transient;
        }
        writeTokens(access, refresh);
        _log('access token refreshed');
        try {
          onRefreshed?.call();
        } catch (_) {}
        return RefreshOutcome.refreshed;
      }
      if (res.statusCode == 400 || res.statusCode == 401 || res.statusCode == 403) {
        _log('refresh rejected (${codeOf(body) ?? res.statusCode})');
        return RefreshOutcome.rejected;
      }
      _log('refresh failed transiently (HTTP ${res.statusCode}) → keeping session');
      return RefreshOutcome.transient;
    } catch (e) {
      _log('refresh network error (${e.runtimeType}) → keeping session');
      return RefreshOutcome.transient;
    }
  }

  static String? _pickToken(dynamic body, List<String> keys) {
    if (body is! Map) return null;
    final data = body['data'];
    for (final k in keys) {
      final direct = body[k];
      if (direct is String && direct.isNotEmpty && direct != 'null') return direct;
      if (data is Map) {
        final nested = data[k];
        if (nested is String && nested.isNotEmpty && nested != 'null') return nested;
      }
    }
    return null;
  }

  /// Ends the session once (several simultaneous 401s → one logout).
  static void endSession(String reason) {
    final now = DateTime.now();
    if (_lastSessionEndAt != null &&
        now.difference(_lastSessionEndAt!) < const Duration(seconds: 5)) {
      return;
    }
    _lastSessionEndAt = now;
    _log('session ended: $reason');
    try {
      onSessionEnded?.call(reason);
    } catch (_) {}
  }

  /// Decide what to do with a finished authenticated request.
  /// Returns a token to retry with, or null (no retry). May end the session.
  static Future<String?> handleAuthFailure({
    required int status,
    required dynamic body,
    required String requestToken,
    required bool alreadyRetried,
  }) async {
    if (endsSession(status, body)) {
      endSession(codeOf(body) ?? 'session_ended');
      return null;
    }
    if (status != 401) return null; // 403 permission, 5xx, network → not a session problem

    if (alreadyRetried) {
      // A freshly refreshed token was still refused.
      endSession(codeOf(body) ?? 'unauthorized_after_refresh');
      return null;
    }

    final current = readAccessToken();
    if (current.isNotEmpty && current != requestToken) {
      return current; // another request already refreshed — just retry
    }

    switch (await refresh()) {
      case RefreshOutcome.refreshed:
        final fresh = readAccessToken();
        return fresh.isNotEmpty ? fresh : null;
      case RefreshOutcome.rejected:
        endSession('refresh_rejected');
        return null;
      case RefreshOutcome.transient:
        return null; // keep the user logged in; the call simply failed this time
    }
  }
}
