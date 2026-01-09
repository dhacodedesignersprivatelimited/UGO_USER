import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'settings_page_model.dart';
export 'settings_page_model.dart';

/// App Settings Menu
class SettingsPageWidget extends StatefulWidget {
  const SettingsPageWidget({super.key});

  static String routeName = 'settings_page';
  static String routePath = '/settingsPage';

  @override
  State<SettingsPageWidget> createState() => _SettingsPageWidgetState();
}

class _SettingsPageWidgetState extends State<SettingsPageWidget> {
  late SettingsPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SettingsPageModel());
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
              'rotnxdvl' /* App Settings */,
            ),
            style: FlutterFlowTheme.of(context).bodyLarge.override(
                  font: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                  fontSize: 16.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w500,
                  fontStyle: FlutterFlowTheme.of(context).bodyLarge.fontStyle,
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
                Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                      child: InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          context.pushNamed(AddHomeWidget.routeName);
                        },
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 12.0, 0.0, 12.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Icon(
                                      Icons.home_outlined,
                                      color: FlutterFlowTheme.of(context)
                                          .primaryText,
                                      size: 24.0,
                                    ),
                                    Text(
                                      FFLocalizations.of(context).getText(
                                        'vd2ymh90' /* Add Home */,
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyLarge
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight: FontWeight.normal,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .fontStyle,
                                            ),
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            fontSize: 16.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyLarge
                                                    .fontStyle,
                                          ),
                                    ),
                                  ].divide(SizedBox(width: 12.0)),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 20.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1.0,
                      thickness: 1.0,
                      color: FlutterFlowTheme.of(context).alternate,
                    ),
                    // Padding(
                    //   padding:
                    //       EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                    //   child: InkWell(
                    //     splashColor: Colors.transparent,
                    //     focusColor: Colors.transparent,
                    //     hoverColor: Colors.transparent,
                    //     highlightColor: Colors.transparent,
                    //     onTap: () async {
                    //       context.pushNamed(AddOfficeWidget.routeName);
                    //     },
                    //     child: Container(
                    //       width: double.infinity,
                    //       decoration: BoxDecoration(
                    //         color: FlutterFlowTheme.of(context)
                    //             .secondaryBackground,
                    //       ),
                    //       child: Padding(
                    //         padding: EdgeInsetsDirectional.fromSTEB(
                    //             0.0, 12.0, 0.0, 12.0),
                    //         child: Row(
                    //           mainAxisSize: MainAxisSize.max,
                    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //           crossAxisAlignment: CrossAxisAlignment.center,
                    //           children: [
                    //             Row(
                    //               mainAxisSize: MainAxisSize.max,
                    //               children: [
                    //                 Icon(
                    //                   Icons.work_outline,
                    //                   color: FlutterFlowTheme.of(context)
                    //                       .primaryText,
                    //                   size: 24.0,
                    //                 ),
                    //                 Text(
                    //                   FFLocalizations.of(context).getText(
                    //                     'rw4zfx8g' /* Add Work */,
                    //                   ),
                    //                   style: FlutterFlowTheme.of(context)
                    //                       .bodyLarge
                    //                       .override(
                    //                         font: GoogleFonts.inter(
                    //                           fontWeight: FontWeight.normal,
                    //                           fontStyle:
                    //                               FlutterFlowTheme.of(context)
                    //                                   .bodyLarge
                    //                                   .fontStyle,
                    //                         ),
                    //                         color: FlutterFlowTheme.of(context)
                    //                             .primaryText,
                    //                         fontSize: 16.0,
                    //                         letterSpacing: 0.0,
                    //                         fontWeight: FontWeight.normal,
                    //                         fontStyle:
                    //                             FlutterFlowTheme.of(context)
                    //                                 .bodyLarge
                    //                                 .fontStyle,
                    //                       ),
                    //                 ),
                    //               ].divide(SizedBox(width: 12.0)),
                    //             ),
                    //             Icon(
                    //               Icons.chevron_right,
                    //               color: FlutterFlowTheme.of(context)
                    //                   .secondaryText,
                    //               size: 20.0,
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // Divider(
                    //   height: 1.0,
                    //   thickness: 1.0,
                    //   color: FlutterFlowTheme.of(context).alternate,
                    // ),
                    // Padding(
                    //   padding:
                    //       EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                    //   child: InkWell(
                    //     splashColor: Colors.transparent,
                    //     focusColor: Colors.transparent,
                    //     hoverColor: Colors.transparent,
                    //     highlightColor: Colors.transparent,
                    //     onTap: () async {
                    //       context.pushNamed(SavedAddWidget.routeName);
                    //     },
                    //     child: Container(
                    //       width: double.infinity,
                    //       decoration: BoxDecoration(
                    //         color: FlutterFlowTheme.of(context)
                    //             .secondaryBackground,
                    //       ),
                    //       child: Padding(
                    //         padding: EdgeInsetsDirectional.fromSTEB(
                    //             0.0, 12.0, 0.0, 12.0),
                    //         child: Row(
                    //           mainAxisSize: MainAxisSize.max,
                    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //           crossAxisAlignment: CrossAxisAlignment.center,
                    //           children: [
                    //             Row(
                    //               mainAxisSize: MainAxisSize.max,
                    //               children: [
                    //                 Icon(
                    //                   Icons.location_pin,
                    //                   color: FlutterFlowTheme.of(context)
                    //                       .primaryText,
                    //                   size: 24.0,
                    //                 ),
                    //                 Text(
                    //                   FFLocalizations.of(context).getText(
                    //                     'xth2lr6p' /* Shortcuts */,
                    //                   ),
                    //                   style: FlutterFlowTheme.of(context)
                    //                       .bodyLarge
                    //                       .override(
                    //                         font: GoogleFonts.inter(
                    //                           fontWeight: FontWeight.normal,
                    //                           fontStyle:
                    //                               FlutterFlowTheme.of(context)
                    //                                   .bodyLarge
                    //                                   .fontStyle,
                    //                         ),
                    //                         color: FlutterFlowTheme.of(context)
                    //                             .primaryText,
                    //                         fontSize: 16.0,
                    //                         letterSpacing: 0.0,
                    //                         fontWeight: FontWeight.normal,
                    //                         fontStyle:
                    //                             FlutterFlowTheme.of(context)
                    //                                 .bodyLarge
                    //                                 .fontStyle,
                    //                       ),
                    //                 ),
                    //               ].divide(SizedBox(width: 12.0)),
                    //             ),
                    //             Icon(
                    //               Icons.chevron_right,
                    //               color: FlutterFlowTheme.of(context)
                    //                   .secondaryText,
                    //               size: 20.0,
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // Divider(
                    //   height: 1.0,
                    //   thickness: 1.0,
                    //   color: FlutterFlowTheme.of(context).alternate,
                    // ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                      child: InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          context
                              .pushNamed(AccessibilitySettingsWidget.routeName);
                        },
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 12.0, 0.0, 12.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Icon(
                                            Icons.accessibility,
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            size: 24.0,
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  '78rilzrv' /* Accessibility */,
                                                ),
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyLarge
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyLarge
                                                                .fontStyle,
                                                      ),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                      fontSize: 16.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyLarge
                                                              .fontStyle,
                                                    ),
                                              ),
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'jmqxj8q4' /* Manage your accessibility sett... */,
                                                ),
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodySmall
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodySmall
                                                                .fontStyle,
                                                      ),
                                                      color: Color(0xFF636363),
                                                      fontSize: 12.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ].divide(SizedBox(width: 12.0)),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 20.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1.0,
                      thickness: 1.0,
                      color: FlutterFlowTheme.of(context).alternate,
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                      child: InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          context.pushNamed(CommunicationWidget.routeName);
                        },
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 12.0, 0.0, 12.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Icon(
                                            Icons.chat_bubble_outline,
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            size: 24.0,
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'xkgf70lf' /* Communication */,
                                                ),
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyLarge
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyLarge
                                                                .fontStyle,
                                                      ),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                      fontSize: 16.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyLarge
                                                              .fontStyle,
                                                    ),
                                              ),
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  '9o8esdqp' /* Manage contact and notificatio... */,
                                                ),
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodySmall
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodySmall
                                                                .fontStyle,
                                                      ),
                                                      color: Color(0xFF636363),
                                                      fontSize: 12.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ].divide(SizedBox(width: 12.0)),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 20.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1.0,
                      thickness: 1.0,
                      color: FlutterFlowTheme.of(context).alternate,
                    ),
                  ].divide(SizedBox(height: 0.0)),
                ),
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(24.0, 24.0, 24.0, 12.0),
                  child: Text(
                    FFLocalizations.of(context).getText(
                      'u9kk66zb' /* Safety */,
                    ),
                    style: FlutterFlowTheme.of(context).headlineSmall.override(
                          font: GoogleFonts.interTight(
                            fontWeight: FontWeight.w500,
                            fontStyle: FlutterFlowTheme.of(context)
                                .headlineSmall
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).primaryText,
                          fontSize: 20.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w500,
                          fontStyle: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .fontStyle,
                        ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                      child: InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          context.pushNamed(SafetypreferencesWidget.routeName);
                        },
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 12.0, 0.0, 12.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Icon(
                                            Icons.security,
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            size: 24.0,
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'qv71xhj1' /* Safety preferences */,
                                                ),
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyLarge
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyLarge
                                                                .fontStyle,
                                                      ),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                      fontSize: 16.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyLarge
                                                              .fontStyle,
                                                    ),
                                              ),
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'Choose and schedule your favorite' /* Choose and schedule your favorite*/,
                                                ),
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodySmall
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodySmall
                                                                .fontStyle,
                                                      ),
                                                      color: Color(0xFF636363),
                                                      fontSize: 12.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ].divide(SizedBox(width: 12.0)),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 20.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1.0,
                      thickness: 1.0,
                      color: FlutterFlowTheme.of(context).alternate,
                    ),
                    // Padding(
                    //   padding:
                    //       EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                    //   child: InkWell(
                    //     splashColor: Colors.transparent,
                    //     focusColor: Colors.transparent,
                    //     hoverColor: Colors.transparent,
                    //     highlightColor: Colors.transparent,
                    //     onTap: () async {
                    //       context.pushNamed(TrustedcontactsWidget.routeName);
                    //     },
                    //     child: Container(
                    //       width: double.infinity,
                    //       decoration: BoxDecoration(
                    //         color: FlutterFlowTheme.of(context)
                    //             .secondaryBackground,
                    //       ),
                    //       child: Padding(
                    //         padding: EdgeInsetsDirectional.fromSTEB(
                    //             0.0, 12.0, 0.0, 12.0),
                    //         child: Row(
                    //           mainAxisSize: MainAxisSize.max,
                    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //           crossAxisAlignment: CrossAxisAlignment.center,
                    //           children: [
                    //             Expanded(
                    //               child: Column(
                    //                 mainAxisSize: MainAxisSize.max,
                    //                 crossAxisAlignment:
                    //                     CrossAxisAlignment.start,
                    //                 children: [
                    //                   Row(
                    //                     mainAxisSize: MainAxisSize.max,
                    //                     children: [
                    //                       Icon(
                    //                         Icons.people,
                    //                         color: FlutterFlowTheme.of(context)
                    //                             .primaryText,
                    //                         size: 24.0,
                    //                       ),
                    //                       Column(
                    //                         mainAxisSize: MainAxisSize.max,
                    //                         crossAxisAlignment:
                    //                             CrossAxisAlignment.start,
                    //                         children: [
                    //                           Text(
                    //                             FFLocalizations.of(context)
                    //                                 .getText(
                    //                               '4851qjtq' /* Manage Trusted Contacts */,
                    //                             ),
                    //                             style: FlutterFlowTheme.of(
                    //                                     context)
                    //                                 .bodyLarge
                    //                                 .override(
                    //                                   font: GoogleFonts.inter(
                    //                                     fontWeight:
                    //                                         FontWeight.normal,
                    //                                     fontStyle:
                    //                                         FlutterFlowTheme.of(
                    //                                                 context)
                    //                                             .bodyLarge
                    //                                             .fontStyle,
                    //                                   ),
                    //                                   color:
                    //                                       FlutterFlowTheme.of(
                    //                                               context)
                    //                                           .primaryText,
                    //                                   fontSize: 16.0,
                    //                                   letterSpacing: 0.0,
                    //                                   fontWeight:
                    //                                       FontWeight.normal,
                    //                                   fontStyle:
                    //                                       FlutterFlowTheme.of(
                    //                                               context)
                    //                                           .bodyLarge
                    //                                           .fontStyle,
                    //                                 ),
                    //                           ),
                    //                           Text(
                    //                             FFLocalizations.of(context)
                    //                                 .getText(
                    //                               '5dgmooor' /* Share your trip status with fa... */,
                    //                             ),
                    //                             style: FlutterFlowTheme.of(
                    //                                     context)
                    //                                 .bodySmall
                    //                                 .override(
                    //                                   font: GoogleFonts.inter(
                    //                                     fontWeight:
                    //                                         FontWeight.normal,
                    //                                     fontStyle:
                    //                                         FlutterFlowTheme.of(
                    //                                                 context)
                    //                                             .bodySmall
                    //                                             .fontStyle,
                    //                                   ),
                    //                                   color: Color(0xFF636363),
                    //                                   fontSize: 12.0,
                    //                                   letterSpacing: 0.0,
                    //                                   fontWeight:
                    //                                       FontWeight.normal,
                    //                                   fontStyle:
                    //                                       FlutterFlowTheme.of(
                    //                                               context)
                    //                                           .bodySmall
                    //                                           .fontStyle,
                    //                                 ),
                    //                           ),
                    //                         ],
                    //                       ),
                    //                     ].divide(SizedBox(width: 12.0)),
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //             Icon(
                    //               Icons.chevron_right,
                    //               color: FlutterFlowTheme.of(context)
                    //                   .secondaryText,
                    //               size: 20.0,
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // Divider(
                    //   height: 1.0,
                    //   thickness: 1.0,
                    //   color: FlutterFlowTheme.of(context).alternate,
                    // ),
                    // Padding(
                    //   padding:
                    //       EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                    //   child: InkWell(
                    //     splashColor: Colors.transparent,
                    //     focusColor: Colors.transparent,
                    //     hoverColor: Colors.transparent,
                    //     highlightColor: Colors.transparent,
                    //     onTap: () async {
                    //       context.pushNamed(RidecheckWidget.routeName);
                    //     },
                    //     child: Container(
                    //       width: double.infinity,
                    //       decoration: BoxDecoration(
                    //         color: FlutterFlowTheme.of(context)
                    //             .secondaryBackground,
                    //       ),
                    //       child: Padding(
                    //         padding: EdgeInsetsDirectional.fromSTEB(
                    //             0.0, 12.0, 0.0, 12.0),
                    //         child: Row(
                    //           mainAxisSize: MainAxisSize.max,
                    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //           crossAxisAlignment: CrossAxisAlignment.center,
                    //           children: [
                    //             Expanded(
                    //               child: Column(
                    //                 mainAxisSize: MainAxisSize.max,
                    //                 crossAxisAlignment:
                    //                     CrossAxisAlignment.start,
                    //                 children: [
                    //                   Row(
                    //                     mainAxisSize: MainAxisSize.max,
                    //                     children: [
                    //                       Icon(
                    //                         Icons.directions_car,
                    //                         color: FlutterFlowTheme.of(context)
                    //                             .primaryText,
                    //                         size: 24.0,
                    //                       ),
                    //                       Column(
                    //                         mainAxisSize: MainAxisSize.max,
                    //                         crossAxisAlignment:
                    //                             CrossAxisAlignment.start,
                    //                         children: [
                    //                           Text(
                    //                             FFLocalizations.of(context)
                    //                                 .getText(
                    //                               'fcbrfwi5' /* RideCheck */,
                    //                             ),
                    //                             style: FlutterFlowTheme.of(
                    //                                     context)
                    //                                 .bodyLarge
                    //                                 .override(
                    //                                   font: GoogleFonts.inter(
                    //                                     fontWeight:
                    //                                         FontWeight.normal,
                    //                                     fontStyle:
                    //                                         FlutterFlowTheme.of(
                    //                                                 context)
                    //                                             .bodyLarge
                    //                                             .fontStyle,
                    //                                   ),
                    //                                   color:
                    //                                       FlutterFlowTheme.of(
                    //                                               context)
                    //                                           .primaryText,
                    //                                   fontSize: 16.0,
                    //                                   letterSpacing: 0.0,
                    //                                   fontWeight:
                    //                                       FontWeight.normal,
                    //                                   fontStyle:
                    //                                       FlutterFlowTheme.of(
                    //                                               context)
                    //                                           .bodyLarge
                    //                                           .fontStyle,
                    //                                 ),
                    //                           ),
                    //                           Text(
                    //                             FFLocalizations.of(context)
                    //                                 .getText(
                    //                               'fd9npakg' /* Manage your RideCheck notifica... */,
                    //                             ),
                    //                             style: FlutterFlowTheme.of(
                    //                                     context)
                    //                                 .bodySmall
                    //                                 .override(
                    //                                   font: GoogleFonts.inter(
                    //                                     fontWeight:
                    //                                         FontWeight.normal,
                    //                                     fontStyle:
                    //                                         FlutterFlowTheme.of(
                    //                                                 context)
                    //                                             .bodySmall
                    //                                             .fontStyle,
                    //                                   ),
                    //                                   color: Color(0xFF636363),
                    //                                   fontSize: 12.0,
                    //                                   letterSpacing: 0.0,
                    //                                   fontWeight:
                    //                                       FontWeight.normal,
                    //                                   fontStyle:
                    //                                       FlutterFlowTheme.of(
                    //                                               context)
                    //                                           .bodySmall
                    //                                           .fontStyle,
                    //                                 ),
                    //                           ),
                    //                         ],
                    //                       ),
                    //                     ].divide(SizedBox(width: 12.0)),
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //             Icon(
                    //               Icons.chevron_right,
                    //               color: FlutterFlowTheme.of(context)
                    //                   .secondaryText,
                    //               size: 20.0,
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // Divider(
                    //   height: 1.0,
                    //   thickness: 1.0,
                    //   color: FlutterFlowTheme.of(context).alternate,
                    // ),
                  ].divide(SizedBox(height: 0.0)),
                ),
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(24.0, 24.0, 24.0, 12.0),
                  child: Text(
                    FFLocalizations.of(context).getText(
                      '8hfqx5dx' /* Ride Preferences */,
                    ),
                    style: FlutterFlowTheme.of(context).headlineSmall.override(
                          font: GoogleFonts.interTight(
                            fontWeight: FontWeight.w500,
                            fontStyle: FlutterFlowTheme.of(context)
                                .headlineSmall
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).primaryText,
                          fontSize: 20.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w500,
                          fontStyle: FlutterFlowTheme.of(context)
                              .headlineSmall
                              .fontStyle,
                        ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Padding(
                    //   padding:
                    //       EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                    //   child: InkWell(
                    //     splashColor: Colors.transparent,
                    //     focusColor: Colors.transparent,
                    //     hoverColor: Colors.transparent,
                    //     highlightColor: Colors.transparent,
                    //     onTap: () async {
                    //       context.pushNamed(TipautomaticallyWidget.routeName);
                    //     },
                    //     child: Container(
                    //       width: double.infinity,
                    //       decoration: BoxDecoration(
                    //         color: FlutterFlowTheme.of(context)
                    //             .secondaryBackground,
                    //       ),
                    //       child: Padding(
                    //         padding: EdgeInsetsDirectional.fromSTEB(
                    //             0.0, 12.0, 0.0, 12.0),
                    //         child: Row(
                    //           mainAxisSize: MainAxisSize.max,
                    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //           crossAxisAlignment: CrossAxisAlignment.center,
                    //           children: [
                    //             Expanded(
                    //               child: Column(
                    //                 mainAxisSize: MainAxisSize.max,
                    //                 crossAxisAlignment:
                    //                     CrossAxisAlignment.start,
                    //                 children: [
                    //                   Row(
                    //                     mainAxisSize: MainAxisSize.max,
                    //                     children: [
                    //                       Icon(
                    //                         Icons.attach_money,
                    //                         color: FlutterFlowTheme.of(context)
                    //                             .primaryText,
                    //                         size: 24.0,
                    //                       ),
                    //                       Column(
                    //                         mainAxisSize: MainAxisSize.max,
                    //                         crossAxisAlignment:
                    //                             CrossAxisAlignment.start,
                    //                         children: [
                    //                           Text(
                    //                             FFLocalizations.of(context)
                    //                                 .getText(
                    //                               'p4jioty0' /* Tip automatically */,
                    //                             ),
                    //                             style: FlutterFlowTheme.of(
                    //                                     context)
                    //                                 .bodyLarge
                    //                                 .override(
                    //                                   font: GoogleFonts.inter(
                    //                                     fontWeight:
                    //                                         FontWeight.normal,
                    //                                     fontStyle:
                    //                                         FlutterFlowTheme.of(
                    //                                                 context)
                    //                                             .bodyLarge
                    //                                             .fontStyle,
                    //                                   ),
                    //                                   color:
                    //                                       FlutterFlowTheme.of(
                    //                                               context)
                    //                                           .primaryText,
                    //                                   fontSize: 16.0,
                    //                                   letterSpacing: 0.0,
                    //                                   fontWeight:
                    //                                       FontWeight.normal,
                    //                                   fontStyle:
                    //                                       FlutterFlowTheme.of(
                    //                                               context)
                    //                                           .bodyLarge
                    //                                           .fontStyle,
                    //                                 ),
                    //                           ),
                    //                           Text(
                    //                             FFLocalizations.of(context)
                    //                                 .getText(
                    //                               'qw85ltwj' /* Set a default tip amount for e... */,
                    //                             ),
                    //                             style: FlutterFlowTheme.of(
                    //                                     context)
                    //                                 .bodySmall
                    //                                 .override(
                    //                                   font: GoogleFonts.inter(
                    //                                     fontWeight:
                    //                                         FontWeight.normal,
                    //                                     fontStyle:
                    //                                         FlutterFlowTheme.of(
                    //                                                 context)
                    //                                             .bodySmall
                    //                                             .fontStyle,
                    //                                   ),
                    //                                   color: Color(0xFF636363),
                    //                                   fontSize: 12.0,
                    //                                   letterSpacing: 0.0,
                    //                                   fontWeight:
                    //                                       FontWeight.normal,
                    //                                   fontStyle:
                    //                                       FlutterFlowTheme.of(
                    //                                               context)
                    //                                           .bodySmall
                    //                                           .fontStyle,
                    //                                 ),
                    //                           ),
                    //                         ],
                    //                       ),
                    //                     ].divide(SizedBox(width: 12.0)),
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //             Icon(
                    //               Icons.chevron_right,
                    //               color: FlutterFlowTheme.of(context)
                    //                   .secondaryText,
                    //               size: 20.0,
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // Divider(
                    //   height: 1.0,
                    //   thickness: 1.0,
                    //   color: FlutterFlowTheme.of(context).alternate,
                    // ),
                    // Padding(
                    //   padding:
                    //       EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                    //   child: InkWell(
                    //     splashColor: Colors.transparent,
                    //     focusColor: Colors.transparent,
                    //     hoverColor: Colors.transparent,
                    //     highlightColor: Colors.transparent,
                    //     onTap: () async {
                    //       context.pushNamed(ReservematchingWidget.routeName);
                    //     },
                    //     child: Container(
                    //       width: double.infinity,
                    //       decoration: BoxDecoration(
                    //         color: FlutterFlowTheme.of(context)
                    //             .secondaryBackground,
                    //       ),
                    //       child: Padding(
                    //         padding: EdgeInsetsDirectional.fromSTEB(
                    //             0.0, 12.0, 0.0, 12.0),
                    //         child: Row(
                    //           mainAxisSize: MainAxisSize.max,
                    //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    //           crossAxisAlignment: CrossAxisAlignment.center,
                    //           children: [
                    //             Expanded(
                    //               child: Column(
                    //                 mainAxisSize: MainAxisSize.max,
                    //                 crossAxisAlignment:
                    //                     CrossAxisAlignment.start,
                    //                 children: [
                    //                   Row(
                    //                     mainAxisSize: MainAxisSize.max,
                    //                     children: [
                    //                       Icon(
                    //                         Icons.schedule,
                    //                         color: FlutterFlowTheme.of(context)
                    //                             .primaryText,
                    //                         size: 24.0,
                    //                       ),
                    //                       Column(
                    //                         mainAxisSize: MainAxisSize.max,
                    //                         crossAxisAlignment:
                    //                             CrossAxisAlignment.start,
                    //                         children: [
                    //                           Text(
                    //                             FFLocalizations.of(context)
                    //                                 .getText(
                    //                               'n2gf5xso' /* Reserve */,
                    //                             ),
                    //                             style: FlutterFlowTheme.of(
                    //                                     context)
                    //                                 .bodyLarge
                    //                                 .override(
                    //                                   font: GoogleFonts.inter(
                    //                                     fontWeight:
                    //                                         FontWeight.normal,
                    //                                     fontStyle:
                    //                                         FlutterFlowTheme.of(
                    //                                                 context)
                    //                                             .bodyLarge
                    //                                             .fontStyle,
                    //                                   ),
                    //                                   color:
                    //                                       FlutterFlowTheme.of(
                    //                                               context)
                    //                                           .primaryText,
                    //                                   fontSize: 16.0,
                    //                                   letterSpacing: 0.0,
                    //                                   fontWeight:
                    //                                       FontWeight.normal,
                    //                                   fontStyle:
                    //                                       FlutterFlowTheme.of(
                    //                                               context)
                    //                                           .bodyLarge
                    //                                           .fontStyle,
                    //                                 ),
                    //                           ),
                    //                           Text(
                    //                             FFLocalizations.of(context)
                    //                                 .getText(
                    //                               'iqv3vgu0' /* Manage booking match preferenc... */,
                    //                             ),
                    //                             style: FlutterFlowTheme.of(
                    //                                     context)
                    //                                 .bodySmall
                    //                                 .override(
                    //                                   font: GoogleFonts.inter(
                    //                                     fontWeight:
                    //                                         FontWeight.normal,
                    //                                     fontStyle:
                    //                                         FlutterFlowTheme.of(
                    //                                                 context)
                    //                                             .bodySmall
                    //                                             .fontStyle,
                    //                                   ),
                    //                                   color: Color(0xFF636363),
                    //                                   fontSize: 12.0,
                    //                                   letterSpacing: 0.0,
                    //                                   fontWeight:
                    //                                       FontWeight.normal,
                    //                                   fontStyle:
                    //                                       FlutterFlowTheme.of(
                    //                                               context)
                    //                                           .bodySmall
                    //                                           .fontStyle,
                    //                                 ),
                    //                           ),
                    //                         ],
                    //                       ),
                    //                     ].divide(SizedBox(width: 12.0)),
                    //                   ),
                    //                 ],
                    //               ),
                    //             ),
                    //             Icon(
                    //               Icons.chevron_right,
                    //               color: FlutterFlowTheme.of(context)
                    //                   .secondaryText,
                    //               size: 20.0,
                    //             ),
                    //           ],
                    //         ),
                    //       ),
                    //     ),
                    //   ),
                    // ),
                    // Divider(
                    //   height: 1.0,
                    //   thickness: 1.0,
                    //   color: FlutterFlowTheme.of(context).alternate,
                    // ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                      child: InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          context
                              .pushNamed(DriversnearbyalertsWidget.routeName);
                        },
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 12.0, 0.0, 12.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Icon(
                                            Icons.warning,
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            size: 24.0,
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'nfvd0da4' /* Driver Nearby Alert */,
                                                ),
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyLarge
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyLarge
                                                                .fontStyle,
                                                      ),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                      fontSize: 16.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyLarge
                                                              .fontStyle,
                                                    ),
                                              ),
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'n2cz2j8u' /* Notify me during long waits */,
                                                ),
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodySmall
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodySmall
                                                                .fontStyle,
                                                      ),
                                                      color: Color(0xFF636363),
                                                      fontSize: 12.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ].divide(SizedBox(width: 12.0)),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 20.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1.0,
                      thickness: 1.0,
                      color: FlutterFlowTheme.of(context).alternate,
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(24.0, 0.0, 24.0, 0.0),
                      child: InkWell(
                        splashColor: Colors.transparent,
                        focusColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        onTap: () async {
                          context.pushNamed(CommuteAlertsWidget.routeName);
                        },
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                          ),
                          child: Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 12.0, 0.0, 12.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.max,
                                        children: [
                                          Icon(
                                            Icons.notifications,
                                            color: FlutterFlowTheme.of(context)
                                                .primaryText,
                                            size: 24.0,
                                          ),
                                          Column(
                                            mainAxisSize: MainAxisSize.max,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'chhlv2fh' /* Commute alerts */,
                                                ),
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyLarge
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyLarge
                                                                .fontStyle,
                                                      ),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                      fontSize: 16.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyLarge
                                                              .fontStyle,
                                                    ),
                                              ),
                                              Text(
                                                FFLocalizations.of(context)
                                                    .getText(
                                                  'g7zw1t8g' /* Plan commute with traffic aler... */,
                                                ),
                                                style: FlutterFlowTheme.of(
                                                        context)
                                                    .bodySmall
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodySmall
                                                                .fontStyle,
                                                      ),
                                                      color: Color(0xFF636363),
                                                      fontSize: 12.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodySmall
                                                              .fontStyle,
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ].divide(SizedBox(width: 12.0)),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText,
                                  size: 20.0,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Divider(
                      height: 1.0,
                      thickness: 1.0,
                      color: FlutterFlowTheme.of(context).alternate,
                    ),
                  ].divide(SizedBox(height: 0.0)),
                ),
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(24.0, 24.0, 24.0, 12.0),
                  child: Text(
                    FFLocalizations.of(context).getText(
                      'jwua7y6v' /* Switch account */,
                    ),
                    style: FlutterFlowTheme.of(context).bodyLarge.override(
                          font: GoogleFonts.inter(
                            fontWeight: FontWeight.normal,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyLarge
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).primaryText,
                          fontSize: 16.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.normal,
                          fontStyle:
                              FlutterFlowTheme.of(context).bodyLarge.fontStyle,
                        ),
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(24.0, 24.0, 24.0, 24.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: Color(0xFFFF2F2F),
                        width: 2.0,
                      ),
                    ),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onTap: () async {
                        GoRouter.of(context).prepareAuthEvent();
                        await authManager.signOut();
                        GoRouter.of(context).clearRedirectLocation();

                        context.goNamedAuth(
                            LoginWidget.routeName, context.mounted);
                      },
                      child: Text(
                        FFLocalizations.of(context).getText(
                          'i3g6i1zo' /* Sign out */,
                        ),
                        textAlign: TextAlign.center,
                        style:
                            FlutterFlowTheme.of(context).headlineSmall.override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .headlineSmall
                                        .fontStyle,
                                  ),
                                  color: Color(0xFFFF2F2F),
                                  fontSize: 20.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .headlineSmall
                                      .fontStyle,
                                ),
                      ),
                    ),
                  ),
                ),
              ].divide(SizedBox(height: 0.0)),
            ),
          ),
        ),
      ),
    );
  }
}
