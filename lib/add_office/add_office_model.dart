import '/flutter_flow/flutter_flow_google_map.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'add_office_widget.dart' show AddOfficeWidget;
import 'package:flutter/material.dart';

class AddOfficeModel extends FlutterFlowModel<AddOfficeWidget> {
  LatLng? googleMapsCenter;
  final googleMapsController = Completer<GoogleMapController>();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
