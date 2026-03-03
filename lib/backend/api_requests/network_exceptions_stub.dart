// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

/// Stub for web: only TimeoutException is detectable (no dart:io).
bool isTransientNetworkError(Object? error) {
  if (error == null) return false;
  return error is TimeoutException;
}
