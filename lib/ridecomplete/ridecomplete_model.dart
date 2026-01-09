import '/components/ridecomplet_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'ridecomplete_widget.dart' show RidecompleteWidget;
import 'package:flutter/material.dart';

class RidecompleteModel extends FlutterFlowModel<RidecompleteWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for ridecomplet component.
  late RidecompletModel ridecompletModel;

  @override
  void initState(BuildContext context) {
    ridecompletModel = createModel(context, () => RidecompletModel());
  }

  @override
  void dispose() {
    ridecompletModel.dispose();
  }
}
