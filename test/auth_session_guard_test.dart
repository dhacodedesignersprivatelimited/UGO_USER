// AuthSessionGuard: refresh / auto-logout policy shared by every HTTP path.
// Same file in the rider and driver apps (the guard is identical in both).
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../lib/backend/api_requests/auth_session_guard.dart';

void main() {
  late String access;
  late String refresh;
  late List<String> ended;
  late int refreshedCallbacks;

  setUp(() {
    AuthSessionGuard.resetForTest();
    access = 'A1';
    refresh = 'R1';
    ended = [];
    refreshedCallbacks = 0;
    AuthSessionGuard.configured = true;
    AuthSessionGuard.baseUrl = () => 'https://api.test';
    AuthSessionGuard.readAccessToken = () => access;
    AuthSessionGuard.readRefreshToken = () => refresh;
    AuthSessionGuard.writeTokens = (a, r) {
      access = a;
      if (r != null) refresh = r;
    };
    AuthSessionGuard.extraHeaders = () => const {};
    AuthSessionGuard.onRefreshed = () => refreshedCallbacks++;
    AuthSessionGuard.onSessionEnded = (reason) => ended.add(reason);
  });

  http.Response ok(String a, String r) => http.Response(
      jsonEncode({'success': true, 'data': {'accessToken': a, 'refreshToken': r}}), 200);
  http.Response err(int status, String code) =>
      http.Response(jsonEncode({'success': false, 'code': code}), status);

  Future<T> withServer<T>(MockClient client, Future<T> Function() body) =>
      http.runWithClient(body, () => client);

  test('2/3: expired access token + valid refresh → refreshed, retry with new token', () async {
    int calls = 0;
    final client = MockClient((req) async {
      calls++;
      expect(req.url.path, '/api/auth/refresh');
      expect(jsonDecode(req.body)['refreshToken'], 'R1');
      return ok('A2', 'R2');
    });
    final retry = await withServer(client, () => AuthSessionGuard.handleAuthFailure(
        status: 401, body: {'code': 'TOKEN_EXPIRED'}, requestToken: 'A1', alreadyRetried: false));
    expect(retry, 'A2');
    expect(access, 'A2');
    expect(refresh, 'R2');
    expect(calls, 1);
    expect(refreshedCallbacks, 1); // driver app reconnects its socket here (scenario 14)
    expect(ended, isEmpty);
  });

  test('13: many simultaneous 401s → exactly one refresh call', () async {
    int calls = 0;
    final gate = Completer<void>();
    final client = MockClient((req) async {
      calls++;
      await gate.future;
      return ok('A2', 'R2');
    });
    final results = withServer(client, () => Future.wait(List.generate(
        5,
        (_) => AuthSessionGuard.handleAuthFailure(
            status: 401, body: {'code': 'TOKEN_EXPIRED'}, requestToken: 'A1', alreadyRetried: false))));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    gate.complete();
    expect(await results, everyElement('A2'));
    expect(calls, 1);
  });

  test('another request already refreshed → retry with current token, no refresh call', () async {
    access = 'A2'; // rotated meanwhile
    final client = MockClient((_) async => fail('must not refresh'));
    final retry = await withServer(client, () => AuthSessionGuard.handleAuthFailure(
        status: 401, body: {'code': 'TOKEN_EXPIRED'}, requestToken: 'A1', alreadyRetried: false));
    expect(retry, 'A2');
  });

  test('4/6: refresh token expired/invalid → logout once', () async {
    final client = MockClient((_) async => err(401, 'REFRESH_EXPIRED'));
    final retry = await withServer(client, () => AuthSessionGuard.handleAuthFailure(
        status: 401, body: {'code': 'TOKEN_EXPIRED'}, requestToken: 'A1', alreadyRetried: false));
    expect(retry, isNull);
    expect(ended, ['refresh_rejected']);
  });

  test('9: no internet during refresh → session kept (no logout)', () async {
    final client = MockClient((_) async => throw http.ClientException('offline'));
    final retry = await withServer(client, () => AuthSessionGuard.handleAuthFailure(
        status: 401, body: {'code': 'TOKEN_EXPIRED'}, requestToken: 'A1', alreadyRetried: false));
    expect(retry, isNull);
    expect(ended, isEmpty);
    expect(access, 'A1');
  });

  test('server error (503) during refresh → session kept', () async {
    final client = MockClient((_) async => http.Response('{}', 503));
    await withServer(client, () => AuthSessionGuard.handleAuthFailure(
        status: 401, body: {'code': 'TOKEN_EXPIRED'}, requestToken: 'A1', alreadyRetried: false));
    expect(ended, isEmpty);
  });

  test('7: 401 with session-ending code → logout immediately, no refresh', () async {
    final client = MockClient((_) async => fail('must not refresh'));
    for (final code in ['SESSION_REVOKED', 'SESSION_REPLACED', 'ACCOUNT_NOT_FOUND', 'TOKEN_MISSING']) {
      AuthSessionGuard.resetForTest();
      ended.clear();
      await withServer(client, () => AuthSessionGuard.handleAuthFailure(
          status: 401, body: {'code': code}, requestToken: 'A1', alreadyRetried: false));
      expect(ended, [code]);
    }
  });

  test('8: plain 403 (permission) → no logout, no refresh', () async {
    final client = MockClient((_) async => fail('must not refresh'));
    final retry = await withServer(client, () => AuthSessionGuard.handleAuthFailure(
        status: 403, body: {'message': 'You can only access your own account'},
        requestToken: 'A1', alreadyRetried: false));
    expect(retry, isNull);
    expect(ended, isEmpty);
  });

  test('15: 403 ACCOUNT_BLOCKED → logout', () async {
    await AuthSessionGuard.handleAuthFailure(
        status: 403, body: {'code': 'ACCOUNT_BLOCKED'}, requestToken: 'A1', alreadyRetried: false);
    expect(ended, ['ACCOUNT_BLOCKED']);
  });

  test('driver KYC pending (403 ACCOUNT_INACTIVE) → stays logged in', () async {
    await AuthSessionGuard.handleAuthFailure(
        status: 403, body: {'code': 'ACCOUNT_INACTIVE'}, requestToken: 'A1', alreadyRetried: false);
    expect(ended, isEmpty);
  });

  test('no infinite loop: 401 again after a refreshed retry → logout, no second refresh', () async {
    final client = MockClient((_) async => fail('must not refresh twice'));
    final retry = await withServer(client, () => AuthSessionGuard.handleAuthFailure(
        status: 401, body: {'code': 'TOKEN_INVALID'}, requestToken: 'A2', alreadyRetried: true));
    expect(retry, isNull);
    expect(ended.length, 1);
  });

  test('burst of session-ending responses → logout handler runs once', () async {
    for (var i = 0; i < 4; i++) {
      await AuthSessionGuard.handleAuthFailure(
          status: 401, body: {'code': 'SESSION_REVOKED'}, requestToken: 'A1', alreadyRetried: false);
    }
    expect(ended.length, 1);
  });

  test('older servers: "another_device" reason maps to SESSION_REPLACED; error.code is read', () {
    expect(AuthSessionGuard.codeOf({'error': {'code': 'session_x', 'reason': 'new_login_another_device'}}),
        'session_x');
    expect(AuthSessionGuard.codeOf({'reason': 'new_login_another_device'}), 'SESSION_REPLACED');
    expect(AuthSessionGuard.codeOf({'error': {'code': 'TOKEN_EXPIRED'}}), 'TOKEN_EXPIRED');
  });

  test('no refresh token stored → cannot refresh → logout', () async {
    refresh = '';
    await AuthSessionGuard.handleAuthFailure(
        status: 401, body: {'code': 'TOKEN_EXPIRED'}, requestToken: 'A1', alreadyRetried: false);
    expect(ended, ['refresh_rejected']);
  });
}
