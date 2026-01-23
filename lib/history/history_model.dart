import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'history_widget.dart' show HistoryWidget;
import 'package:flutter/material.dart';

class HistoryModel extends FlutterFlowModel<HistoryWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores the API response for ride history.
  ApiCallResponse? rideHistoryResponse;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}

  /// Action: Fetches ride history from the backend.
  Future<ApiCallResponse> fetchRideHistory() async {
    final userId = FFAppState().userid;
    final token = FFAppState().accessToken;

    rideHistoryResponse = await GetRideHistoryCall.call(
      userId: userId,
      token: token,
    );
    return rideHistoryResponse!;
  }
}
