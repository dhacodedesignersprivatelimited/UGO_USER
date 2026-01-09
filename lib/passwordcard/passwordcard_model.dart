import '/components/password_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'passwordcard_widget.dart' show PasswordcardWidget;
import 'package:flutter/material.dart';

class PasswordcardModel extends FlutterFlowModel<PasswordcardWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for password component.
  late PasswordModel passwordModel;

  @override
  void initState(BuildContext context) {
    passwordModel = createModel(context, () => PasswordModel());
  }

  @override
  void dispose() {
    passwordModel.dispose();
  }
}
