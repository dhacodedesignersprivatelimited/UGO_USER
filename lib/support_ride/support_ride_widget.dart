import '/components/ride_detais_widget.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'support_ride_model.dart';
export 'support_ride_model.dart';

/// Page name: choose_trip
/// Primary color: #FF7B10
///
/// AppBar
///
/// Background: #FF7B10
///
/// Leading: back arrow
///
/// Title: Choose a trip (white, 18, medium)
///
/// Elevation: 0
///
/// Body
///
/// Use SingleChildScrollView → Column (crossAxisStart, spacing 16, padding 0
/// top, 0 left/right, 0 bottom).
///
/// Add repeated Trip Card containers (3–4 examples) with the layout below.
/// Cards sit on a light gray page background.
///
/// Trip Card (one item)
///
/// Container
///
/// Width: max, Background: white, Radius: 0, Shadow: subtle (y=1, blur=4),
/// Margin top 0, Bottom 16
///
/// Child: Column (spacing 12, padding: 16 all)
///
/// Top row
///
/// Row → spaceBetween
///
/// Left (Column, crossStart)
///
/// Text: 1/18/25, 11:12 AM (12, #555)
///
/// Text: Hero Glamour (14, #111, medium)
///
/// Right (Row, center)
///
/// Column (crossEnd)
///
/// Text: ₹103.00 (14, #111, medium)
///
/// Text: CASH (12, #777)
///
/// Icon: chevron_right (size 20, #111)
///
/// Map preview
///
/// Container (height 160, radius 8)
///
/// Child: GoogleMap (or Image placeholder if no key)
///
/// Initial camera: lat/lng around Hyderabad (or any)
///
/// Zoom: 13
///
/// All gestures enabled is fine, but height must stay 160 so scroll works
/// well inside SingleChildScrollView.
///
/// Divider (color #EEEEEE)
///
/// Repeat the Trip Card 3–4 times with different example data:
///
/// 11/17/24, 5:20 PM | Hero Passion Plus | ₹25.00 | CASH
///
/// 11/14/24, 2:02 PM | Honda CB Shine | ₹48.00 | CASH
///
/// 11/14/24, 1:46 PM | Yamaha FZS | ₹0.00 | Canceled
///
/// Interactions
///
/// Tapping a card or the chevron: Navigate to trip_details (create if
/// missing).
///
/// Notes / Constraints
///
/// The parent is SingleChildScrollView (not ListView).
///
/// All map previews have fixed height (160) to avoid unbounded height.
///
/// Page background: #F6F6F6.
class SupportRideWidget extends StatefulWidget {
  const SupportRideWidget({super.key});

  static String routeName = 'support_ride';
  static String routePath = '/supportRide';

  @override
  State<SupportRideWidget> createState() => _SupportRideWidgetState();
}

class _SupportRideWidgetState extends State<SupportRideWidget> {
  late SupportRideModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SupportRideModel());
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Color(0xFFF6F6F6),
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 30.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            FFLocalizations.of(context).getText(
              'gnde4jfz' /* Choose a trip */,
            ),
            style: FlutterFlowTheme.of(context).titleMedium.override(
                  font: GoogleFonts.interTight(
                    fontWeight: FontWeight.w500,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleMedium.fontStyle,
                  ),
                  color: Colors.white,
                  fontSize: 18.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                  fontStyle: FlutterFlowTheme.of(context).titleMedium.fontStyle,
                ),
          ),
          actions: [],
          centerTitle: true,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 4.0,
                        color: Color(0x1A000000),
                        offset: Offset(
                          0.0,
                          1.0,
                        ),
                      )
                    ],
                    borderRadius: BorderRadius.circular(0.0),
                  ),
                  child: wrapWithModel(
                    model: _model.rideDetaisModel1,
                    updateCallback: () => safeSetState(() {}),
                    child: RideDetaisWidget(),
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 4.0,
                        color: Color(0x1A000000),
                        offset: Offset(
                          0.0,
                          1.0,
                        ),
                      )
                    ],
                    borderRadius: BorderRadius.circular(0.0),
                  ),
                  child: wrapWithModel(
                    model: _model.rideDetaisModel2,
                    updateCallback: () => safeSetState(() {}),
                    child: RideDetaisWidget(),
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 4.0,
                        color: Color(0x1A000000),
                        offset: Offset(
                          0.0,
                          1.0,
                        ),
                      )
                    ],
                    borderRadius: BorderRadius.circular(0.0),
                  ),
                  child: wrapWithModel(
                    model: _model.rideDetaisModel3,
                    updateCallback: () => safeSetState(() {}),
                    child: RideDetaisWidget(),
                  ),
                ),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 4.0,
                        color: Color(0x1A000000),
                        offset: Offset(
                          0.0,
                          1.0,
                        ),
                      )
                    ],
                    borderRadius: BorderRadius.circular(0.0),
                  ),
                  child: wrapWithModel(
                    model: _model.rideDetaisModel4,
                    updateCallback: () => safeSetState(() {}),
                    child: RideDetaisWidget(),
                  ),
                ),
              ]
                  .divide(SizedBox(height: 16.0))
                  .addToStart(SizedBox(height: 0.0)),
            ),
          ),
        ),
      ),
    );
  }
}
