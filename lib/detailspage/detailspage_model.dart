import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'detailspage_widget.dart' show DetailspageWidget;
import 'package:flutter/material.dart';

class DetailspageModel extends FlutterFlowModel<DetailspageWidget> {
  final unfocusNode = FocusNode();
  final formKey = GlobalKey<FormState>();

  // State fields
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;

  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;

  FocusNode? textFieldFocusNode3;
  TextEditingController? textController3;
  String? Function(BuildContext, String?)? textController3Validator;

  // Logic fields
  ApiCallResponse? apiResultRegister;
  bool isRegistering = false;
  FFUploadedFile uploadedLocalFile = FFUploadedFile(bytes: Uint8List.fromList([]));

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    unfocusNode.dispose();
    textFieldFocusNode1?.dispose();
    textController1?.dispose();
    textFieldFocusNode2?.dispose();
    textController2?.dispose();
    textFieldFocusNode3?.dispose();
    textController3?.dispose();
  }

  // ✅ Validation Logic
  String? validateForm() {
    if (textController1?.text.isEmpty ?? true) return "First name is required";
    if (textController3?.text.isEmpty ?? true) return "Email is required";
    return null;
  }
}