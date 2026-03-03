// ignore_for_file: depend_on_referenced_packages

import 'dart:async';
import 'dart:io';

/// Returns true if [error] is a transient network error (connection failure,
/// timeout, etc.) that may succeed on retry.
bool isTransientNetworkError(Object? error) {
  if (error == null) return false;
  if (error is TimeoutException) return true;
  if (error is SocketException) return true;
  if (error is OSError) {
    final msg = error.message.toLowerCase();
    return msg.contains('connection') ||
        msg.contains('network') ||
        msg.contains('host');
  }
  return false;
}
