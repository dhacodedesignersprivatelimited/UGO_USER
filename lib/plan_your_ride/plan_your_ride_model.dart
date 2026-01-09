import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'plan_your_ride_widget.dart' show PlanYourRideWidget;
import 'package:flutter/material.dart';

class PlanYourRideModel extends FlutterFlowModel<PlanYourRideWidget> {
  ///  State fields for stateful widgets in this page.

  // Text controllers for location inputs
  final pickupController = TextEditingController();
  final dropController = TextEditingController();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    pickupController.dispose();
    dropController.dispose();
  }
}
