import '/backend/api_requests/api_calls.dart';
import '/core/app_config.dart';
import '/flutter_flow/flutter_flow_place_picker.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom sheet: search a new pickup or drop (Google Places), then PATCH ride locations.
class RideLocationPatchSheet extends StatefulWidget {
  const RideLocationPatchSheet({
    super.key,
    required this.rideId,
    required this.editPickup,
    required this.initialLat,
    required this.initialLng,
    required this.initialAddress,
  });

  final int rideId;
  final bool editPickup;
  final double initialLat;
  final double initialLng;
  final String initialAddress;

  @override
  State<RideLocationPatchSheet> createState() => _RideLocationPatchSheetState();
}

class _RideLocationPatchSheetState extends State<RideLocationPatchSheet> {
  static const Color _brand = Color(0xFFFF7B10);
  final String _mapKey = AppConfig.googleMapsApiKey;

  double? _lat;
  double? _lng;
  String _address = '';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _lat = widget.initialLat;
    _lng = widget.initialLng;
    _address = widget.initialAddress;
  }

  Future<void> _submit() async {
    if (_lat == null || _lng == null || _address.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a place first')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final token = FFAppState().accessToken;
      final res = await PatchRideLocationsCall.call(
        rideId: widget.rideId,
        token: token,
        pickupLatitude: widget.editPickup ? _lat : null,
        pickupLongitude: widget.editPickup ? _lng : null,
        pickupLocationAddress: widget.editPickup ? _address.trim() : null,
        dropLatitude: widget.editPickup ? null : _lat,
        dropLongitude: widget.editPickup ? null : _lng,
        dropLocationAddress: widget.editPickup ? null : _address.trim(),
      );
      if (!mounted) return;
      if (res.succeeded) {
        Navigator.of(context).pop(true);
      } else {
        setState(() => _submitting = false);
        var msg = getJsonField(res.jsonBody, r'$.message')?.toString() ??
            'Could not update location';
        final reqFare =
            getJsonField(res.jsonBody, r'$.error.required_fare')?.toString();
        final wBal =
            getJsonField(res.jsonBody, r'$.error.wallet_balance')?.toString();
        if (reqFare != null &&
            wBal != null &&
            reqFare != 'null' &&
            wBal != 'null') {
          msg = '$msg (need $reqFare, wallet $wBal)';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.editPickup ? 'Edit pickup' : 'Edit drop';
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.paddingOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Search for the new ${widget.editPickup ? 'pickup' : 'drop'} point. Fare may change based on distance.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          FlutterFlowPlacePicker(
            iOSGoogleMapsApiKey: _mapKey,
            androidGoogleMapsApiKey: _mapKey,
            webGoogleMapsApiKey: _mapKey,
            defaultText: 'Search address',
            icon: const Icon(Icons.search, color: Colors.grey, size: 20),
            buttonOptions: FFButtonOptions(
              width: double.infinity,
              height: 48,
              color: Colors.grey.shade100,
              textStyle: GoogleFonts.inter(),
              elevation: 0,
              borderSide: BorderSide(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            onSelect: (place) {
              setState(() {
                _lat = place.latLng.latitude;
                _lng = place.latLng.longitude;
                _address = place.address;
              });
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _address.isEmpty ? 'No place selected yet' : _address,
              style: GoogleFonts.inter(fontSize: 14, height: 1.35),
            ),
          ),
          const SizedBox(height: 20),
          FFButtonWidget(
            onPressed: _submitting ? null : _submit,
            text: _submitting ? 'Updating…' : 'Update & notify driver',
            options: FFButtonOptions(
              width: double.infinity,
              height: 52,
              color: _brand,
              textStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}
