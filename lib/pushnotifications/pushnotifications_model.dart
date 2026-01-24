import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'pushnotifications_widget.dart' show PushnotificationsWidget;
import 'package:flutter/material.dart';

class PushnotificationsModel extends FlutterFlowModel<PushnotificationsWidget> {
  ///  State fields for stateful widgets in this page.

  // Stores the API response for notifications.
  ApiCallResponse? notificationsResponse;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}

  /// Action: Fetches all notifications from the backend.
  Future<ApiCallResponse> fetchNotifications() async {
    final token = FFAppState().accessToken;

    notificationsResponse = await GetAllNotificationsCall.call(
      token: token,
    );
    return notificationsResponse!;
  }
}
