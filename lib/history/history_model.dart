import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'history_widget.dart' show HistoryWidget;
import 'package:flutter/material.dart';

class HistoryModel extends FlutterFlowModel<HistoryWidget> {
  ApiCallResponse? rideHistoryResponse;
  ApiCallResponse? paymentHistoryResponse;
  String? rideErrorMessage;
  String? paymentErrorMessage;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}

  Future<void> fetchRideHistory() async {
    final userId = FFAppState().userid;
    final token = FFAppState().accessToken;

    rideErrorMessage = null;
    rideHistoryResponse = await GetRideHistoryCall.call(
      userId: userId,
      token: token,
      page: 1,
      pageSize: 50,
    );
    if (rideHistoryResponse?.succeeded != true) {
      rideErrorMessage =
          rideHistoryResponse?.userFriendlyMessage ?? 'Could not load trips';
    }
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
