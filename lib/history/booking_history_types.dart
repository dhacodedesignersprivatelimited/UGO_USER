import 'package:flutter/material.dart';

/// Status tabs → `statusGroup` query for [GetRideHistoryCall].
enum BookingStatusTab {
  ongoing,
  completed,
  cancelled,
}

extension BookingStatusTabX on BookingStatusTab {
  String get apiValue {
    switch (this) {
      case BookingStatusTab.ongoing:
        return 'ongoing';
      case BookingStatusTab.completed:
        return 'completed';
      case BookingStatusTab.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case BookingStatusTab.ongoing:
        return 'Ongoing';
      case BookingStatusTab.completed:
        return 'Completed';
      case BookingStatusTab.cancelled:
        return 'Cancelled';
    }
  }
}

enum DateRangePreset {
  allTime,
  today,
  yesterday,
  thisWeek,
  thisMonth,
  custom,
}

extension DateRangePresetX on DateRangePreset {
  String get label {
    switch (this) {
      case DateRangePreset.allTime:
        return 'All time';
      case DateRangePreset.today:
        return 'Today';
      case DateRangePreset.yesterday:
        return 'Yesterday';
      case DateRangePreset.thisWeek:
        return 'This week';
      case DateRangePreset.thisMonth:
        return 'This month';
      case DateRangePreset.custom:
        return 'Custom range';
    }
  }
}

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Calendar-normalized bounds for custom range validation.
(DateTime?, DateTime?) customCalendarDays(DateTime? start, DateTime? end) {
  if (start == null || end == null) return (null, null);
  final a = DateTime(start.year, start.month, start.day);
  final b = DateTime(end.year, end.month, end.day);
  return (a, b);
}

/// Returns `(startDate, endDate)` as `YYYY-MM-DD` for API, or `(null,null)` when unbounded.
(String? startIso, String? endIso) datePresetToApiRange(
  DateRangePreset preset, {
  DateTime? customStart,
  DateTime? customEnd,
}) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  switch (preset) {
    case DateRangePreset.allTime:
      return (null, null);
    case DateRangePreset.today:
      final s = _ymd(today);
      return (s, s);
    case DateRangePreset.yesterday:
      final y = today.subtract(const Duration(days: 1));
      final s = _ymd(y);
      return (s, s);
    case DateRangePreset.thisWeek:
      // ISO weekday: Monday = 1 (matches typical ride-app “this week”).
      final weekday = today.weekday;
      final start = today.subtract(Duration(days: weekday - 1));
      return (_ymd(start), _ymd(today));
    case DateRangePreset.thisMonth:
      final start = DateTime(today.year, today.month, 1);
      final end = DateTime(today.year, today.month + 1, 0);
      return (_ymd(start), _ymd(end));
    case DateRangePreset.custom:
      final (a, b) = customCalendarDays(customStart, customEnd);
      if (a == null || b == null) return (null, null);
      if (a.isAfter(b)) return (null, null);
      return (_ymd(a), _ymd(b));
  }
}

String displayBookingStatus(String? raw) {
  final u = (raw ?? '').toUpperCase().trim();
  if (u.isEmpty) return 'Unknown';
  if (const {
    'SEARCHING',
    'ACCEPTED',
    'ARRIVED',
    'STARTED',
    'ONTRIP',
  }.contains(u)) {
    return 'Ongoing';
  }
  if (u == 'COMPLETED') return 'Completed';
  if (const {'CANCELLED', 'REJECTED', 'DECLINED'}.contains(u)) {
    return 'Cancelled';
  }
  final r = raw ?? '';
  return r.length > 16 ? '${r.substring(0, 16)}…' : r;
}

/// Backend `booking_mode`: `pro` vs `normal` (vehicle category).
bool isProBookingMode(dynamic bookingMode) {
  final s = (bookingMode ?? '').toString().toLowerCase().trim();
  return s == 'pro';
}

/// Human-readable line for details sheets.
String rideTierDescription(dynamic bookingMode) =>
    isProBookingMode(bookingMode) ? 'Pro ride' : 'Standard ride';

/// Left accent for booking cards (Pro = premium gold, Standard = neutral).
Color rideTierCardAccent(dynamic bookingMode) => isProBookingMode(bookingMode)
    ? const Color(0xFFD97706)
    : const Color(0xFFCBD5E1);

/// Pro chip background (dark) / Standard (light slate).
(Color bg, Color fg) rideTierChipColors(dynamic bookingMode) {
  if (isProBookingMode(bookingMode)) {
    return (const Color(0xFF0F172A), const Color(0xFFFBBF24));
  }
  return (const Color(0xFFF1F5F9), const Color(0xFF475569));
}

/// Pretty-print API `ride_type` (e.g. car, bike). Empty if unknown.
String formatVehicleRideType(dynamic rideType) {
  final raw = (rideType ?? '').toString().trim();
  if (raw.isEmpty) return '';
  if (raw.length == 1) return raw.toUpperCase();
  return '${raw[0].toUpperCase()}${raw.substring(1).toLowerCase()}';
}

Color bookingStatusColor(String? raw) {
  final d = displayBookingStatus(raw);
  switch (d) {
    case 'Completed':
      return const Color(0xFF10B981);
    case 'Cancelled':
      return const Color(0xFFEF4444);
    case 'Ongoing':
      return const Color(0xFFF59E0B);
    default:
      return const Color(0xFFFF7B10);
  }
}
