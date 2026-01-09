import '/flutter_flow/flutter_flow_util.dart';
import 'add_stop_widget.dart' show AddStopWidget;
import 'package:flutter/material.dart';

class AddStopModel extends FlutterFlowModel<AddStopWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // State field(s) for PlacePicker widget.
  FFPlace placePickerValue = FFPlace();

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
