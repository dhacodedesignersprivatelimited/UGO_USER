import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'refer_and_earn_widget.dart' show ReferAndEarnWidget;
import 'package:flutter/material.dart';

class ReferAndEarnModel extends FlutterFlowModel<ReferAndEarnWidget> {
  final unfocusNode = FocusNode();
  ApiCallResponse? referralStats;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    unfocusNode.dispose();
  }
}
