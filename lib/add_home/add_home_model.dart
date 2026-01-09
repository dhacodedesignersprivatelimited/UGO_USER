import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'add_home_widget.dart' show AddHomeWidget;
import 'package:flutter/material.dart';

class AddHomeModel extends FlutterFlowModel<AddHomeWidget> {
  // State fields for form
  String? addressLabel;
  String? addressText;
  double? latitude;
  double? longitude;
  
  // Loading and error states
  bool isLoading = false;
  String? errorMessage;
  String? successMessage;

  @override
  void initState(BuildContext context) {
    // Initialize with empty values
    addressLabel = '';
    addressText = '';
    latitude = null;
    longitude = null;
  }

  @override
  void dispose() {
    // Clean up any resources
  }

  // Validation method
  bool validateForm() {
    if (addressLabel == null || addressLabel!.isEmpty) {
      errorMessage = 'Please enter an address label';
      return false;
    }
    if (addressText == null || addressText!.isEmpty) {
      errorMessage = 'Please enter the address';
      return false;
    }
    if (latitude == null || longitude == null) {
      errorMessage = 'Please select a location on the map';
      return false;
    }
    errorMessage = null;
    return true;
  }

  // Clear form data
  void clearForm() {
    addressLabel = '';
    addressText = '';
    latitude = null;
    longitude = null;
    errorMessage = null;
    successMessage = null;
  }

  // Set location data
  void setLocation(double lat, double lng, String address) {
    latitude = lat;
    longitude = lng;
    if (addressText == null || addressText!.isEmpty) {
      addressText = address;
    }
  }
}