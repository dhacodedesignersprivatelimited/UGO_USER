import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'settings_page_model.dart';
export 'settings_page_model.dart';

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
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: theme.secondaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        centerTitle: true,
        elevation: 2,
        leading: FlutterFlowIconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'App Settings',
          style: GoogleFonts.inter(
            color: theme.secondaryBackground,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isSmall = width < 360;
            final horizontalPadding = isSmall ? 16.0 : 24.0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _section(
                    title: 'General',
                    children: [
                      _tile(
                        icon: Icons.home_outlined,
                        title: 'Add Home',
                        onTap: () =>
                            context.pushNamed(AddHomeWidget.routeName),
                      ),
                       _tile(
                        icon: Icons.work_outlined,
                        title: 'Add Work',
                        onTap: () =>
                            // context.pushNamed(AddHomeWidget.routeName),
                            {}
                      ),
                      // _tile(
                      //   icon: Icons.accessibility,
                      //   title: 'Accessibility',
                      //   subtitle: 'Manage your accessibility settings',
                      //   onTap: () => context.pushNamed(
                      //       AccessibilitySettingsWidget.routeName),
                      // ),
                      // _tile(
                      //   icon: Icons.chat_bubble_outline,
                      //   title: 'Communication',
                      //   subtitle: 'Manage contact & notifications',
                      //   onTap: () =>
                      //       context.pushNamed(CommunicationWidget.routeName),
                      // ),
                    ],
                  ),

                  // _section(
                  //   title: 'Safety',
                  //   children: [
                  //     _tile(
                  //       icon: Icons.security,
                  //       title: 'Safety preferences',
                  //       subtitle:
                  //           'Choose and schedule your safety options',
                  //       onTap: () => context.pushNamed(
                  //           SafetypreferencesWidget.routeName),
                  //     ),
                  //   ],
                  // ),

                  // _section(
                  //   title: 'Ride Preferences',
                  //   children: [
                  //     _tile(
                  //       icon: Icons.warning,
                  //       title: 'Driver nearby alert',
                  //       subtitle: 'Notify me during long waits',
                  //       onTap: () => context.pushNamed(
                  //           DriversnearbyalertsWidget.routeName),
                  //     ),
                  //     _tile(
                  //       icon: Icons.notifications,
                  //       title: 'Commute alerts',
                  //       subtitle: 'Traffic & commute notifications',
                  //       onTap: () =>
                  //           context.pushNamed(CommuteAlertsWidget.routeName),
                  //     ),
                  //   ],
                  // ),

                  // _section(
                  //   title: 'Legal',
                  //   children: [
                  //     _tile(
                  //       icon: Icons.privacy_tip_outlined,
                  //       title: 'Privacy Policy',
                  //       subtitle: 'View our data handling policies',
                  //       onTap: () =>
                  //           context.pushNamed(PrivacypolicyWidget.routeName),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------- SECTION WRAPPER ----------------
  Widget _section({required String title, required List<Widget> children}) {
    final theme = FlutterFlowTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  // ---------------- TILE ----------------
  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final theme = FlutterFlowTheme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.bodyLarge,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodySmall.copyWith(
                        color: const Color(0xFF636363),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: theme.secondaryText, size: 20),
          ],
        ),
      ),
    );
  }
}
