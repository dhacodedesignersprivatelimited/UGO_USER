import '/flutter_flow/flutter_flow_util.dart';
import 'detailspage_widget.dart' show DetailspageWidget;
import 'package:flutter/material.dart';
import '/backend/api_requests/api_calls.dart';

class DetailspageModel extends FlutterFlowModel<DetailspageWidget> {
  final unfocusNode = FocusNode();
  bool _isRegistering = false;

  // Profile Photo
  bool isDataUploading = false;
  FFUploadedFile uploadedLocalFile = FFUploadedFile(bytes: Uint8List.fromList([]));

  // Text Fields
  FocusNode? textFieldFocusNode1;
  TextEditingController? textController1;
  String? Function(BuildContext, String?)? textController1Validator;

  FocusNode? textFieldFocusNode2;
  TextEditingController? textController2;
  String? Function(BuildContext, String?)? textController2Validator;

  FocusNode? textFieldFocusNode3;
  TextEditingController? textController3;
  String? Function(BuildContext, String?)? textController3Validator;

  ApiCallResponse? apiResultRegister;

  bool get isRegistering => _isRegistering;
  void set isRegistering(bool value) => _isRegistering = value;

  String get firstName => textController1?.text.trim() ?? '';
  String get lastName => textController2?.text.trim() ?? '';
  String get email => textController3?.text.trim() ?? '';

  @override
  void initState(BuildContext context) {
    textFieldFocusNode1 ??= FocusNode();
    textController1 ??= TextEditingController();
    textController1Validator = (context, value) {
      if (value == null || value.isEmpty) return 'First name is required';
      if (value.length < 2) return 'Name must be at least 2 characters';
      return null;
    };

    textFieldFocusNode2 ??= FocusNode();
    textController2 ??= TextEditingController();

    textFieldFocusNode3 ??= FocusNode();
    textController3 ??= TextEditingController();
    textController3Validator = (context, value) {
      if (value == null || value.isEmpty) return 'Email is required';
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
        return 'Please enter a valid email';
      }
      return null;
    };
  }

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

  String? validateForm() {
    if (firstName.isEmpty) return 'First name required';
    if (email.isEmpty || !email.contains('@')) return 'Valid email required';
    return null;
  }
}
