import 'dart:async';

import '/backend/api_requests/api_calls.dart';
import '/core/app_config.dart';
import '/flutter_flow/flutter_flow_place_picker.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;

/// Bottom sheet: UGO-branded flow to pick a new pickup/drop, then PATCH ride locations.
/// The in-app chrome matches your theme; the overlay list still uses Places data.
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
  final String _mapKey = AppConfig.googleMapsApiKey;

  double? _lat;
  double? _lng;
  String _address = '';
  bool _submitting = false;
  bool _resolvingPlace = false;
  bool _reverseGeoBusy = false;

  gm.GoogleMapController? _mapController;
  gm.LatLng? _lastCameraTarget;
  Timer? _reverseGeoDebounce;
  bool _skipFirstMapIdle = true;
  bool _suppressIdleGeocode = false;

  @override
  void initState() {
    super.initState();
    _lat = widget.initialLat;
    _lng = widget.initialLng;
    _address = widget.initialAddress;
    _lastCameraTarget = gm.LatLng(widget.initialLat, widget.initialLng);
  }

  @override
  void dispose() {
    _reverseGeoDebounce?.cancel();
    super.dispose();
  }

  void _scheduleReverseGeocode() {
    _reverseGeoDebounce?.cancel();
    _reverseGeoDebounce = Timer(const Duration(milliseconds: 400), () {
      final t = _lastCameraTarget;
      if (t != null && mounted) {
        _reverseGeocodePinned(t);
      }
    });
  }

  Future<void> _reverseGeocodePinned(gm.LatLng target) async {
    setState(() => _reverseGeoBusy = true);
    try {
      final list = await placemarkFromCoordinates(
        target.latitude,
        target.longitude,
      );
      if (!mounted) return;
      if (list.isEmpty) {
        setState(() {
          _lat = target.latitude;
          _lng = target.longitude;
          _address =
              '${target.latitude.toStringAsFixed(5)}, ${target.longitude.toStringAsFixed(5)}';
          _reverseGeoBusy = false;
        });
        return;
      }
      final p = list.first;
      final addr = _formatPlacemark(p);
      setState(() {
        _lat = target.latitude;
        _lng = target.longitude;
        _address = addr.isNotEmpty
            ? addr
            : '${target.latitude.toStringAsFixed(5)}, ${target.longitude.toStringAsFixed(5)}';
        _reverseGeoBusy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _lat = target.latitude;
        _lng = target.longitude;
        _address =
            '${target.latitude.toStringAsFixed(5)}, ${target.longitude.toStringAsFixed(5)}';
        _reverseGeoBusy = false;
      });
    }
  }

  String _formatPlacemark(Placemark p) {
    final raw = <String>[
      if (p.name != null && p.name!.trim().isNotEmpty) p.name!.trim(),
      if (p.street != null && p.street!.trim().isNotEmpty) p.street!.trim(),
      if (p.subLocality != null && p.subLocality!.trim().isNotEmpty)
        p.subLocality!.trim(),
      if (p.locality != null && p.locality!.trim().isNotEmpty)
        p.locality!.trim(),
      if (p.administrativeArea != null &&
          p.administrativeArea!.trim().isNotEmpty)
        p.administrativeArea!.trim(),
      if (p.postalCode != null && p.postalCode!.trim().isNotEmpty)
        p.postalCode!.trim(),
      if (p.country != null && p.country!.trim().isNotEmpty) p.country!.trim(),
    ];
    final seen = <String>{};
    final parts = <String>[];
    for (final s in raw) {
      if (seen.contains(s)) continue;
      seen.add(s);
      parts.add(s);
    }
    return parts.join(', ');
  }

  Future<void> _goToMyLocation() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('Location permission needed to use My location'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final t = gm.LatLng(pos.latitude, pos.longitude);
      _lastCameraTarget = t;
      await _mapController?.animateCamera(
        gm.CameraUpdate.newLatLngZoom(t, 16),
      );
      if (mounted) await _reverseGeocodePinned(t);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Could not get current location'),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_reverseGeoBusy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Still resolving map location…'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    if (_lat == null || _lng == null || _address.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Choose a place first'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
          SnackBar(
            content: Text(msg),
            backgroundColor: FlutterFlowTheme.of(context).error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: FlutterFlowTheme.of(context).error,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final title = widget.editPickup ? 'Change pickup' : 'Change drop-off';
    final hasSelection = _address.trim().length >= 3;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: theme.primary.withValues(alpha: 0.18),
              blurRadius: 28,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.paddingOf(context).bottom + 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeroHeader(context, theme, title),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildUgoLogoMark(theme),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pin or search',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: theme.primaryText,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Move the map so the pin sits on your spot, or search below. '
                                  'Fare may update based on the new route.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: theme.secondaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildPinMap(theme),
                      const SizedBox(height: 18),
                      Text(
                        'Or search by name',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: theme.secondaryText,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              theme.primary.withValues(alpha: 0.12),
                              theme.secondary.withValues(alpha: 0.08),
                            ],
                          ),
                          border: Border.all(
                            color: theme.primary.withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primary.withValues(alpha: 0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(3),
                        child: FlutterFlowPlacePicker(
                          iOSGoogleMapsApiKey: _mapKey,
                          androidGoogleMapsApiKey: _mapKey,
                          webGoogleMapsApiKey: _mapKey,
                          defaultText: 'Search',
                          icon: Icon(
                            Icons.search_rounded,
                            color: theme.primary,
                            size: 24,
                          ),
                          buttonOptions: FFButtonOptions(
                            width: double.infinity,
                            height: 54,
                            color: theme.secondaryBackground,
                            textStyle: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: theme.primaryText,
                            ),
                            elevation: 0,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          onPlaceDetailsBusy: (busy) {
                            if (mounted) setState(() => _resolvingPlace = busy);
                          },
                          onSelect: (place) async {
                            final lat = place.latLng.latitude;
                            final lng = place.latLng.longitude;
                            setState(() {
                              _lat = lat;
                              _lng = lng;
                              _address = place.address;
                              _lastCameraTarget = gm.LatLng(lat, lng);
                            });
                            final ctrl = _mapController;
                            if (ctrl != null) {
                              _suppressIdleGeocode = true;
                              await ctrl.animateCamera(
                                gm.CameraUpdate.newLatLngZoom(
                                  gm.LatLng(lat, lng),
                                  16,
                                ),
                              );
                              Future<void>.delayed(
                                  const Duration(milliseconds: 450), () {
                                if (mounted) _suppressIdleGeocode = false;
                              });
                            }
                          },
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 8, left: 4, right: 4),
                        child: Text(
                          'Search suggestions are powered by Google.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            height: 1.3,
                            color: theme.secondaryText.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      if (_resolvingPlace) ...[
                        const SizedBox(height: 16),
                        Container(
                          height: 72,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: theme.primaryBackground,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.primary.withValues(alpha: 0.12),
                            ),
                          ),
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: theme.primary,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      _buildSelectedCard(theme, hasSelection),
                      const SizedBox(height: 22),
                      _buildGradientCta(context, theme),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Circular UGO mark (launcher icon) like your in-app reference UI.
  Widget _buildUgoLogoMark(FlutterFlowTheme theme) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/app_launcher_icon.png',
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: theme.primary,
          alignment: Alignment.center,
          child: Text(
            'UGO',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(
      BuildContext context, FlutterFlowTheme theme, String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 14, 8, 22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primary,
            theme.secondary,
            Color.lerp(theme.secondary, theme.tertiary, 0.55)!,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(
                    widget.editPickup
                        ? Icons.trip_origin_rounded
                        : Icons.flag_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.6,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'UGO · quick location update',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.close_rounded, size: 22),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPinMap(FlutterFlowTheme theme) {
    final initial =
        _lastCameraTarget ?? gm.LatLng(widget.initialLat, widget.initialLng);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 220,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: gm.GoogleMap(
                initialCameraPosition: gm.CameraPosition(
                  target: initial,
                  zoom: 15,
                ),
                onMapCreated: (c) => _mapController = c,
                onCameraMove: (pos) => _lastCameraTarget = pos.target,
                onCameraIdle: () {
                  if (_skipFirstMapIdle) {
                    _skipFirstMapIdle = false;
                    return;
                  }
                  if (_suppressIdleGeocode) return;
                  _scheduleReverseGeocode();
                },
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
              ),
            ),
            IgnorePointer(
              child: Transform.translate(
                offset: const Offset(0, -18),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 48,
                  color: theme.primary,
                  shadows: const [
                    Shadow(
                      blurRadius: 6,
                      color: Colors.black38,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Material(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(12),
                elevation: 3,
                shadowColor: theme.primary.withValues(alpha: 0.25),
                child: InkWell(
                  onTap: _goToMyLocation,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.my_location_rounded,
                      color: theme.primary,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
            if (_reverseGeoBusy)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.secondaryBackground.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: theme.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedCard(FlutterFlowTheme theme, bool hasSelection) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.alternate,
            theme.secondaryBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasSelection
              ? theme.success.withValues(alpha: 0.45)
              : theme.primary.withValues(alpha: 0.2),
          width: hasSelection ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.primary.withValues(alpha: hasSelection ? 0.1 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: hasSelection
                  ? theme.success.withValues(alpha: 0.15)
                  : theme.accent4,
              shape: BoxShape.circle,
            ),
            child: Icon(
              hasSelection
                  ? Icons.place_rounded
                  : Icons.edit_location_alt_outlined,
              color: hasSelection ? theme.success : theme.secondaryText,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasSelection ? 'Selected place' : 'No new place yet',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.secondaryText,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasSelection
                      ? _address
                      : 'Pan the map or search, then confirm with the orange button.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color:
                        hasSelection ? theme.primaryText : theme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          if (hasSelection)
            Icon(Icons.check_circle_rounded, color: theme.success, size: 26),
        ],
      ),
    );
  }

  Widget _buildGradientCta(BuildContext context, FlutterFlowTheme theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: (_submitting || _reverseGeoBusy) ? null : _submit,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                theme.primary,
                theme.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: theme.primary.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: (_submitting || _reverseGeoBusy)
                ? const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.send_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Update & notify captain',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
