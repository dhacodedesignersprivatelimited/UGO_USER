import '/components/reviews_widget.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'review_widget.dart' show ReviewWidget;
import 'package:flutter/material.dart';

class ReviewModel extends FlutterFlowModel<ReviewWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for reviews component.
  late ReviewsModel reviewsModel;

  @override
  void initState(BuildContext context) {
    reviewsModel = createModel(context, () => ReviewsModel());
  }

  @override
  void dispose() {
    reviewsModel.dispose();
  }
}
