import '/components/ride_detais_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'support_ride_widget.dart' show SupportRideWidget;
import 'package:flutter/material.dart';

class SupportRideModel extends FlutterFlowModel<SupportRideWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for ride_detais component.
  late RideDetaisModel rideDetaisModel1;
  // Model for ride_detais component.
  late RideDetaisModel rideDetaisModel2;
  // Model for ride_detais component.
  late RideDetaisModel rideDetaisModel3;
  // Model for ride_detais component.
  late RideDetaisModel rideDetaisModel4;

  @override
  void initState(BuildContext context) {
    rideDetaisModel1 = createModel(context, () => RideDetaisModel());
    rideDetaisModel2 = createModel(context, () => RideDetaisModel());
    rideDetaisModel3 = createModel(context, () => RideDetaisModel());
    rideDetaisModel4 = createModel(context, () => RideDetaisModel());
  }

  @override
  void dispose() {
    rideDetaisModel1.dispose();
    rideDetaisModel2.dispose();
    rideDetaisModel3.dispose();
    rideDetaisModel4.dispose();
  }
}
