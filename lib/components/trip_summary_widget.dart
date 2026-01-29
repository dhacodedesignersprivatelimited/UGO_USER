import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'trip_summary_model.dart';
export 'trip_summary_model.dart';

class TripSummaryWidget extends StatefulWidget {
  const TripSummaryWidget({
    super.key,
    this.onNext,
  });

  final VoidCallback? onNext;

  @override
  State<TripSummaryWidget> createState() => _TripSummaryWidgetState();
}

class _TripSummaryWidgetState extends State<TripSummaryWidget> {
  late TripSummaryModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TripSummaryModel());
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
                    child: Text(
                      'Trip Details',
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                            font: GoogleFonts.interTight(),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 0.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Color(0xFF00A859), size: 18.0),
                            SizedBox(width: 8.0),
                            Text('Pickup: ', style: FlutterFlowTheme.of(context).bodyMedium),
                            Text('MG Road', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), fontWeight: FontWeight.bold)),
                          ],
                        ),
                        SizedBox(height: 12.0),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Color(0xFFE53935), size: 18.0),
                            SizedBox(width: 8.0),
                            Text('Drop-off: ', style: FlutterFlowTheme.of(context).bodyMedium),
                            Text('HSR Layout', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Divider(height: 32.0, thickness: 1.0, indent: 16.0, endIndent: 16.0),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Distance: 12.5 km', style: FlutterFlowTheme.of(context).bodyMedium),
                        Text('Duration: 28 mins', style: FlutterFlowTheme.of(context).bodyMedium),
                      ],
                    ),
                  ),
                  Divider(height: 32.0, thickness: 1.0, indent: 16.0, endIndent: 16.0),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                    child: Text(
                      'Fare Breakdown',
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                            font: GoogleFonts.interTight(),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
                    child: Column(
                      children: [
                        _buildFareRow('Base Fare', '₹50'),
                        _buildFareRow('Distance Fare', '₹120'),
                        _buildFareRow('Tax & Fees', '₹18'),
                        Divider(height: 24.0, thickness: 1.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total', style: FlutterFlowTheme.of(context).headlineSmall.override(font: GoogleFonts.interTight(), fontWeight: FontWeight.bold)),
                            Text('₹188', style: FlutterFlowTheme.of(context).headlineSmall.override(font: GoogleFonts.interTight(), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(16.0, 32.0, 16.0, 16.0),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: FlutterFlowTheme.of(context).alternate),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Color(0xFF00A859)),
                          SizedBox(width: 8.0),
                          Text('Paid via UPI', style: FlutterFlowTheme.of(context).bodyMedium),
                          Spacer(),
                          Text('Change', style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 40.0),
            child: FFButtonWidget(
              onPressed: () async {
                if (widget.onNext != null) {
                  widget.onNext!();
                }
              },
              text: 'Proceed to Rating',
              options: FFButtonOptions(
                width: double.infinity,
                height: 50.0,
                color: Color(0xFF00A859),
                textStyle: FlutterFlowTheme.of(context).titleSmall.override(font: GoogleFonts.interTight(), color: Colors.white),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFareRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).secondaryText)),
          Text(value, style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
