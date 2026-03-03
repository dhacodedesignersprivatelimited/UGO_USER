// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:http/http.dart' as http;

/// A custom HTTP client that enforces a strict timeout on all requests.
/// Wraps the standard [http.Client] and applies [timeout] to every [send] call.
///
/// Use [instance] for a shared singleton with default 30-second timeout.
/// Use [create] to obtain a custom-configured client.
class TimeoutHttpClient extends http.BaseClient {
  TimeoutHttpClient({
    this.timeout = const Duration(seconds: 30),
    http.Client? inner,
  }) : _inner = inner ?? http.Client();

  final Duration timeout;
  final http.Client _inner;

  /// Default singleton with 30-second timeout.
  static TimeoutHttpClient? _instance;
  static TimeoutHttpClient get instance =>
      _instance ??= TimeoutHttpClient(timeout: const Duration(seconds: 30));

  /// Create a client with custom timeout.
  static TimeoutHttpClient create({Duration timeout = const Duration(seconds: 30)}) {
    return TimeoutHttpClient(timeout: timeout);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request).timeout(
      timeout,
      onTimeout: () => throw TimeoutException(
        'Request to ${request.url} timed out after ${timeout.inSeconds}s',
        timeout,
      ),
    );
  }

  /// Close the underlying client. Call when shutting down the app.
  void close() {
    _inner.close();
  }
}
