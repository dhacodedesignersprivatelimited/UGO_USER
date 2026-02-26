import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart'; // Required for FFButtonWidget
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart'; // ✅ Import Scanner

import '/driver_details/driver_details_widget.dart'; // Import destination
import 'scan_to_book_model.dart';
export 'scan_to_book_model.dart';

class ScanToBookWidget extends StatefulWidget {
  const ScanToBookWidget({super.key});

  static String routeName = 'scan_to_book';
  static String routePath = '/scanToBook';

  @override
  State<ScanToBookWidget> createState() => _ScanToBookWidgetState();
}

class _ScanToBookWidgetState extends State<ScanToBookWidget> {
  late ScanToBookModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ScanToBookModel());
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  // ✅ FUNCTIONALITY: Start Camera Scan
  Future<void> _startQRScan() async {
    if (_isScanning) return;
    setState(() => _isScanning = true);

    try {
      // Calls the native camera scanner
      String scanResult = await FlutterBarcodeScanner.scanBarcode(
        '#FF7B10', // Scanning line color (Orange)
        'Cancel',  // Cancel button text
        true,      // Show flash icon
        ScanMode.QR,
      );

      // '-1' indicates the user cancelled the scan
      if (scanResult != '-1' && mounted) {
        _handleScanResult(scanResult);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Scanner Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  // ✅ FUNCTIONALITY: Process Data & Navigate
  void _handleScanResult(String rawData) {
    print("🔍 Scanned Data: $rawData");

    int? driverId;
    int? vehicleType;
    double? baseFare;
    double? pricePerKm;
    double? baseKmStart;
    double? baseKmEnd;

    try {
      // 1. Attempt to parse JSON (e.g., {"driver_id": 123, "pricing": {...}})
      if (rawData.trim().startsWith('{')) {
        final data = jsonDecode(rawData);
        driverId = int.tryParse(data['driver_id']?.toString() ?? '');
        vehicleType = int.tryParse(data['vehicle_type_id']?.toString() ?? '');

        if (data['pricing'] != null) {
          final pricing = data['pricing'];
          baseFare = double.tryParse(pricing['base_fare']?.toString() ?? '0');
          pricePerKm = double.tryParse(pricing['price_per_km']?.toString() ?? '0');
          baseKmStart = double.tryParse(pricing['base_km_start']?.toString() ?? '1');
          baseKmEnd = double.tryParse(pricing['base_km_end']?.toString() ?? '5');
        }
      }
      // 2. Fallback: Assume raw string is just the Driver ID
      else {
        driverId = int.tryParse(rawData);
      }

      // 3. Navigate if we have a Driver ID
      if (driverId != null) {
        context.pushNamed(
          DriverDetailsWidget.routeName,
          queryParameters: {
            'driverId': driverId.toString(),
            'vehicleType': vehicleType?.toString() ?? '',
            'baseFare': baseFare?.toString() ?? '',
            'pricePerKm': pricePerKm?.toString() ?? '',
            'baseKmStart': baseKmStart?.toString() ?? '',
            'baseKmEnd': baseKmEnd?.toString() ?? '',
          },
        );
      } else {
        throw Exception("Invalid QR Data");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid QR Code. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFFF7B10),
          automaticallyImplyLeading: false,
          leading: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 0.0, 0.0),
            child: FlutterFlowIconButton(
              borderRadius: 30.0,
              buttonSize: 40.0,
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24.0),
              onPressed: () => context.safePop(),
            ),
          ),
          title: Text(
            'Scan to Ride',
            style: FlutterFlowTheme.of(context).titleMedium.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
              color: Colors.white,
              fontSize: 18.0,
            ),
          ),
          centerTitle: true,
          elevation: 0.0,
        ),
        body: SafeArea(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Visual Icon
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFFF7B10).withValues(alpha:0.3), width: 2),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 100,
                      color: Color(0xFFFF7B10),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                Text(
                  'Scan Driver QR',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).headlineMedium.override(
                    font: GoogleFonts.interTight(fontWeight: FontWeight.bold),
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Point your camera at the QR code in the vehicle to book your ride instantly.',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                    font: GoogleFonts.inter(),
                    color: Colors.grey[600],
                    fontSize: 16.0,
                  ),
                ),

                const SizedBox(height: 40),

                // SCAN BUTTON
                FFButtonWidget(
                  onPressed: _startQRScan,
                  text: _isScanning ? 'Starting Camera...' : 'Open Scanner',
                  icon: const Icon(Icons.camera_alt_outlined, size: 24),
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 56.0,
                    color: const Color(0xFFFF7B10),
                    textStyle: FlutterFlowTheme.of(context).titleMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      color: Colors.white,
                      fontSize: 18.0,
                    ),
                    elevation: 3.0,
                    borderRadius: BorderRadius.circular(12.0),
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