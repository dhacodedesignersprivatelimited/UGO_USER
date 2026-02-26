import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'safetypreferences_model.dart';
export 'safetypreferences_model.dart';

/// Safety Preferences Settings
class SafetypreferencesWidget extends StatefulWidget {
  const SafetypreferencesWidget({super.key});

  static String routeName = 'Safetypreferences';
  static String routePath = '/safetypreferences';

  @override
  State<SafetypreferencesWidget> createState() =>
      _SafetypreferencesWidgetState();
}

class _SafetypreferencesWidgetState extends State<SafetypreferencesWidget> {
  late SafetypreferencesModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SafetypreferencesModel());
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
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
            child: FlutterFlowIconButton(
              borderRadius: 20.0,
              buttonSize: 40.0,
              icon: Icon(
                Icons.arrow_back,
                color: FlutterFlowTheme.of(context).secondaryBackground,
                size: 24.0,
              ),
              onPressed: () async {
                context.safePop();
              },
            ),
          ),
          title: Text(
            FFLocalizations.of(context).getText(
              'to0i86k9' /* Safety preferences */,
            ),
            style: FlutterFlowTheme.of(context).headlineMedium.override(
              font: GoogleFonts.interTight(
                fontWeight: FontWeight.w500,
              ),
              color: FlutterFlowTheme.of(context).secondaryBackground,
              fontSize: 16.0,
              letterSpacing: 0.0,
            ),
          ),
          actions: const [],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FFLocalizations.of(context).getText(
                      'ixe1axt7' /* These will turn on when you us... */,
                    ),
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(),
                      color: const Color(0xFF868686),
                      fontSize: 14.0,
                      letterSpacing: 0.0,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPreferenceItem(
                        context,
                        icon: Icons.directions_car,
                        title: '6uu87tpc' /* Get more safety check-ins */,
                        subtitle: 'ezx2ad7g' /* Monitor ride for route or time... */,
                        value: _model.checkboxValue1 ??= true,
                        onChanged: (val) => safeSetState(() => _model.checkboxValue1 = val!),
                      ),
                      _buildPreferenceItem(
                        context,
                        icon: Icons.mic,
                        title: 'yjlrlal7' /* Record audio */,
                        subtitle: 'alme3h8l' /* Send a recording with your saf... */,
                        value: _model.checkboxValue2 ??= true,
                        onChanged: (val) => safeSetState(() => _model.checkboxValue2 = val!),
                      ),
                      _buildPreferenceItem(
                        context,
                        icon: Icons.person,
                        title: 'gk9cnj7m' /* Share trip status */,
                        subtitle: 'b4blepbz' /* Share live trip with friends o... */,
                        value: _model.checkboxValue3 ??= true,
                        onChanged: (val) => safeSetState(() => _model.checkboxValue3 = val!),
                      ),
                    ].divide(const SizedBox(height: 24.0)),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        FFLocalizations.of(context).getText('woxk3510' /* Schedule */),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                          color: FlutterFlowTheme.of(context).accent1,
                          fontSize: 16.0,
                          letterSpacing: 0.0,
                        ),
                      ),
                      Text(
                        FFLocalizations.of(context).getText('cyjugduq' /* This is how and when your pref... */),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(),
                          color: const Color(0xFF868686),
                          fontSize: 14.0,
                          letterSpacing: 0.0,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildScheduleItem(
                            context,
                            icon: Icons.directions_car,
                            title: 'ue8ium3r' /* All rides */,
                            subtitle: 'w7emc38a' /* on during every ride */,
                            value: _model.checkboxValue4 ??= true,
                            onChanged: (val) => safeSetState(() => _model.checkboxValue4 = val!),
                          ),
                          _buildScheduleLink(
                            context,
                            icon: Icons.list,
                            title: 'lbu77i6m' /* Some rides */,
                            subtitle: '284tu9bw' /* Choose ride types */,
                            onTap: () => context.pushNamed(ChooserideWidget.routeName),
                          ),
                          _buildScheduleItem(
                            context,
                            icon: Icons.edit_note,
                            title: 'ugclg4l8' /* No rides */,
                            subtitle: 'a3btvneb' /* only turn on manually */,
                            value: _model.checkboxValue5 ??= true,
                            onChanged: (val) => safeSetState(() => _model.checkboxValue5 = val!),
                            showDivider: false,
                          ),
                        ].divide(const SizedBox(height: 24.0)),
                      ),
                    ].divide(const SizedBox(height: 16.0)),
                  ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
                    child: FFButtonWidget(
                      onPressed: () => print('Button pressed ...'),
                      text: FFLocalizations.of(context).getText('j4u6mh08' /* Done */),
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 56.0,
                        padding: const EdgeInsets.all(8.0),
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          font: GoogleFonts.interTight(),
                          color: FlutterFlowTheme.of(context).secondaryBackground,
                          fontSize: 24.0,
                          letterSpacing: 0.0,
                        ),
                        elevation: 0.0,
                        borderRadius: BorderRadius.circular(28.0),
                      ),
                    ),
                  ),
                ]
                    .divide(const SizedBox(height: 24.0))
                    .addToStart(const SizedBox(height: 24.0)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Helper Widgets to Clean Up Code ---

  Widget _buildPreferenceItem(BuildContext context,
      {required IconData icon, required String title, required String subtitle, required bool value, required Function(bool?) onChanged}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: FlutterFlowTheme.of(context).secondaryBackground),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: FlutterFlowTheme.of(context).accent1, size: 20.0),
                  Text(
                    FFLocalizations.of(context).getText(title),
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                      font: GoogleFonts.inter(),
                      color: FlutterFlowTheme.of(context).accent1,
                      fontSize: 14.0,
                    ),
                  ),
                ].divide(const SizedBox(width: 12.0)),
              ),
              _buildStyledCheckbox(context, value, onChanged),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(32.0, 4.0, 32.0, 0.0),
            child: Text(
              FFLocalizations.of(context).getText(subtitle),
              style: FlutterFlowTheme.of(context).bodySmall.override(
                font: GoogleFonts.inter(),
                color: const Color(0xFF7B7A7A),
                fontSize: 12.0,
              ),
            ),
          ),
          const Divider(thickness: 1.0, color: Color(0xFFE0E0E0)),
        ],
      ),
    );
  }

  Widget _buildScheduleItem(BuildContext context,
      {required IconData icon, required String title, required String subtitle, required bool value, required Function(bool?) onChanged, bool showDivider = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: FlutterFlowTheme.of(context).accent1, size: 20.0),
                Text(
                  FFLocalizations.of(context).getText(title),
                  style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).accent1, fontSize: 14.0),
                ),
              ].divide(const SizedBox(width: 12.0)),
            ),
            _buildStyledCheckbox(context, value, onChanged),
          ],
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(32.0, 4.0, 32.0, 0.0),
          child: Text(
            FFLocalizations.of(context).getText(subtitle),
            style: FlutterFlowTheme.of(context).bodySmall.override(font: GoogleFonts.inter(), color: const Color(0xFF7B7A7A), fontSize: 12.0),
          ),
        ),
        if (showDivider) const Divider(thickness: 1.0, color: Color(0xFFE0E0E0)),
      ],
    );
  }

  Widget _buildScheduleLink(BuildContext context, {required IconData icon, required String title, required String subtitle, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: FlutterFlowTheme.of(context).accent1, size: 20.0),
                  Text(
                    FFLocalizations.of(context).getText(title),
                    style: FlutterFlowTheme.of(context).bodyMedium.override(font: GoogleFonts.inter(), color: FlutterFlowTheme.of(context).accent1, fontSize: 14.0),
                  ),
                ].divide(const SizedBox(width: 12.0)),
              ),
              Icon(Icons.chevron_right, color: FlutterFlowTheme.of(context).accent1, size: 20.0),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(32.0, 4.0, 32.0, 0.0),
            child: Text(
              FFLocalizations.of(context).getText(subtitle),
              style: FlutterFlowTheme.of(context).bodySmall.override(font: GoogleFonts.inter(), color: const Color(0xFF7B7A7A), fontSize: 12.0),
            ),
          ),
          const Divider(thickness: 1.0, color: Color(0xFFE0E0E0)),
        ],
      ),
    );
  }

  Widget _buildStyledCheckbox(BuildContext context, bool value, Function(bool?) onChanged) {
    return Container(
      width: 20.0,
      height: 20.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2.0),
        border: Border.all(color: FlutterFlowTheme.of(context).accent1, width: 1.0),
      ),
      child: Theme(
        data: ThemeData(
          checkboxTheme: CheckboxThemeData(
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.0)),
          ),
        ),
        child: Checkbox(
          value: value,
          onChanged: onChanged,
          side: BorderSide(width: 2, color: FlutterFlowTheme.of(context).alternate),
          activeColor: FlutterFlowTheme.of(context).primary,
          checkColor: FlutterFlowTheme.of(context).info,
        ),
      ),
    );
  }
}