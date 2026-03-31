import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'booking_history_types.dart';
import 'history_widget.dart' show HistoryWidget;
import 'package:flutter/material.dart';

class HistoryModel extends FlutterFlowModel<HistoryWidget> {
  ApiCallResponse? rideHistoryResponse;
  ApiCallResponse? paymentHistoryResponse;
  String? rideErrorMessage;
  String? paymentErrorMessage;

  /// Booking history (aggregated pages).
  List<dynamic> bookingRides = [];
  BookingStatusTab statusTab = BookingStatusTab.ongoing;
  DateRangePreset datePreset = DateRangePreset.allTime;
  DateTime? customRangeStart;
  DateTime? customRangeEnd;

  int currentPage = 0;
  bool hasMorePages = true;
  bool isLoadingInitial = false;
  bool isLoadingMore = false;
  int totalBookings = 0;

  static const int _pageSize = 20;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}

  /// User-facing empty copy for current filters.
  String bookingEmptyMessage() {
    final status = statusTab.label;
    if (datePreset == DateRangePreset.allTime) {
      switch (statusTab) {
        case BookingStatusTab.ongoing:
          return 'No ongoing bookings found';
        case BookingStatusTab.completed:
          return 'No completed bookings found';
        case BookingStatusTab.cancelled:
          return 'No cancelled bookings available';
      }
    }
    if (datePreset == DateRangePreset.custom &&
        (customRangeStart == null || customRangeEnd == null)) {
      return 'Select a start and end date for your custom range';
    }
    return 'No $status bookings found for this date range';
  }

  (String?, String?) _apiDates() {
    return datePresetToApiRange(
      datePreset,
      customStart: customRangeStart,
      customEnd: customRangeEnd,
    );
  }

  Future<void> reloadBookings() async {
    bookingRides = [];
    currentPage = 0;
    hasMorePages = true;
    rideHistoryResponse = null;
    await loadBookingPage(reset: true);
  }

  Future<void> loadBookingPage({bool reset = false}) async {
    final userId = FFAppState().userid;
    final token = FFAppState().accessToken;

    if (userId <= 0 || token.isEmpty) {
      rideErrorMessage = 'Sign in to see your bookings';
      return;
    }

    if (reset) {
      if (isLoadingInitial) return;
      isLoadingInitial = true;
      rideErrorMessage = null;
    } else {
      if (isLoadingMore || !hasMorePages || isLoadingInitial) return;
      isLoadingMore = true;
    }

    final nextPage = reset ? 1 : currentPage + 1;
    final (startD, endD) = _apiDates();

    final res = await GetRideHistoryCall.call(
      userId: userId,
      token: token,
      page: nextPage,
      pageSize: _pageSize,
      statusGroup: statusTab.apiValue,
      startDate: startD,
      endDate: endD,
    );

    if (!res.succeeded) {
      rideErrorMessage = res.userFriendlyMessage;
      isLoadingInitial = false;
      isLoadingMore = false;
      return;
    }

    rideHistoryResponse = res;
    rideErrorMessage = null;

    final pageList = GetRideHistoryCall.rides(res.jsonBody) ?? [];
    final total = GetRideHistoryCall.total(res.jsonBody) ?? 0;
    final reportedPage = GetRideHistoryCall.page(res.jsonBody) ?? nextPage;
    final reportedSize = GetRideHistoryCall.pageSize(res.jsonBody) ?? _pageSize;

    if (reset) {
      bookingRides = List<dynamic>.from(pageList);
    } else {
      bookingRides = [...bookingRides, ...pageList];
    }

    currentPage = reportedPage;
    totalBookings = total;
    hasMorePages = (reportedPage * reportedSize) < total;

    isLoadingInitial = false;
    isLoadingMore = false;
  }

  Future<void> fetchRideHistory() async {
    await reloadBookings();
  }

  Future<void> fetchPaymentHistory() async {
    final userId = FFAppState().userid;
    final token = FFAppState().accessToken;

    paymentErrorMessage = null;
    if (userId <= 0 || token.isEmpty) {
      paymentErrorMessage = 'Sign in to see payments';
      return;
    }
    paymentHistoryResponse = await GetUserTransactionsCall.call(
      userId: userId,
      token: token,
      page: 1,
      limit: 50,
    );
    if (paymentHistoryResponse?.succeeded != true) {
      paymentErrorMessage =
          paymentHistoryResponse?.userFriendlyMessage ??
              'Could not load payments';
    }
  }
}
