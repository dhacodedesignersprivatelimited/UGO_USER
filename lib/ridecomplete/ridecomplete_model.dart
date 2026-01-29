import '/components/ridecomplet_widget.dart';
import '/components/trip_summary_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'ridecomplete_widget.dart' show RidecompleteWidget;
import 'package:flutter/material.dart';

class RidecompleteModel extends FlutterFlowModel<RidecompleteWidget> {
  ///  State fields for stateful widgets in this page.
  int currentStep = 0;

  // Model for ridecomplet component.
  late RidecompletModel ridecompletModel;
  // Model for tripSummary component.
  late TripSummaryModel tripSummaryModel;

  @override
  void initState(BuildContext context) {
    ridecompletModel = createModel(context, () => RidecompletModel());
    tripSummaryModel = createModel(context, () => TripSummaryModel());
  }

  @override
  void dispose() {
    ridecompletModel.dispose();
    tripSummaryModel.dispose();
  }
}
