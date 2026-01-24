import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'choose_destination_widget.dart' show ChooseDestinationWidget;
import 'package:flutter/material.dart';

class ChooseDestinationModel extends FlutterFlowModel<ChooseDestinationWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for pickupLocation widget.
  FocusNode? pickupLocationFocusNode;
  TextEditingController? pickupLocationController;
  String? Function(BuildContext, String?)? pickupLocationControllerValidator;
  
  // State field(s) for destinationLocation widget.
  FocusNode? destinationLocationFocusNode;
  TextEditingController? destinationLocationController;
  String? Function(BuildContext, String?)? destinationLocationControllerValidator;

  // Stores the ride history for recent places.
  List<dynamic>? recentRides;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    pickupLocationFocusNode?.dispose();
    pickupLocationController?.dispose();

    destinationLocationFocusNode?.dispose();
    destinationLocationController?.dispose();
  }

  /// Action: Fetches ride history from the backend.
  Future<void> fetchRecentRides() async {
    final userId = FFAppState().userid;
    final token = FFAppState().accessToken;

    final response = await GetRideHistoryCall.call(
      userId: userId,
      token: token,
    );
    
    if (response.succeeded) {
      recentRides = GetRideHistoryCall.rides(response.jsonBody);
    }
  }
}
