import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/backend/api_requests/api_calls.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'menu_model.dart';
export 'menu_model.dart';

class MenuWidget extends StatefulWidget {
  const MenuWidget({super.key});
  static String routeName = 'menu';
  static String routePath = '/menuoptions';

  @override
  State<MenuWidget> createState() => _MenuWidgetState();
}

class _MenuWidgetState extends State<MenuWidget> with TickerProviderStateMixin {
  late MenuModel _model;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  // Theme constants - will be dynamic based on context in build
  Color get primaryOrange => FlutterFlowTheme.of(context).primary;
  Color get secondaryBlue => FlutterFlowTheme.of(context).secondary;
  Color get accentPurple => FlutterFlowTheme.of(context).accent1;
  Color get successGreen => FlutterFlowTheme.of(context).success;
  Color get surfaceColor => FlutterFlowTheme.of(context).primaryBackground;
  Color get gradientStart => FlutterFlowTheme.of(context).primary;
  Color get gradientEnd => FlutterFlowTheme.of(context).secondary;

  // User UI state
  String _profileImageUrl = '';
  String _userDisplayName = 'Guest User';
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MenuModel());

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
    );

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = FFAppState().userid;
      final token = FFAppState().accessToken;

      // Not logged in
      if (userId == 0 || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _userDisplayName = FFLocalizations.of(context).getText('guest_user');
          _profileImageUrl = '';
          _isLoadingUser = false;
        });
        return;
      }

      final response = await GetUserDetailsCall.call(
        userId: userId,
        token: token,
      );

      if (!mounted) return;

      if (response.succeeded) {
        final firstName =
        (GetUserDetailsCall.firstName(response.jsonBody) ?? '').trim();
        final lastName =
        (GetUserDetailsCall.lastName(response.jsonBody) ?? '').trim();
        final rawProfileImg =
        (GetUserDetailsCall.profileImage(response.jsonBody) ?? '').trim();

        final fullName =
        [firstName, lastName].where((x) => x.isNotEmpty).join(' ');

        // Efficiently build URL: AppConfig.baseApiUrl + / + rawProfileImg
        final imgUrl = rawProfileImg.isNotEmpty
            ? (rawProfileImg.startsWith('http')
                ? rawProfileImg
                : '${AppConfig.baseApiUrl}${rawProfileImg.startsWith('/') ? '' : '/'}$rawProfileImg')
            : '';

        setState(() {
          _userDisplayName = fullName.isNotEmpty ? fullName : FFLocalizations.of(context).getText('user_label');
          _profileImageUrl = imgUrl;
          _isLoadingUser = false;
        });
      } else {
        if (response.statusCode == 401 || response.statusCode == 403) {
          FFAppState().clearAuthSession();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please sign in again.'),
            ),
          );
          context.goNamedAuth(LoginWidget.routeName, context.mounted);
          return;
        }
        setState(() {
          _userDisplayName = FFLocalizations.of(context).getText('user_label');
          _profileImageUrl = '';
          _isLoadingUser = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _userDisplayName = 'User';
        _profileImageUrl = '';
        _isLoadingUser = false;
      });
    }
  }


  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _model.maybeDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isNarrow = screenWidth < 360;
        final isTablet = screenWidth >= 768;

        final itemPadding = isNarrow
            ? 12.0
            : isTablet
                ? 24.0
                : 28.0;
        final iconSize = isNarrow
            ? 28.0
            : isTablet
                ? 34.0
                : 32.0;
        final fontSize = isNarrow
            ? 16.0
            : isTablet
                ? 19.0
                : 18.0;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                FlutterFlowTheme.of(context).primaryBackground,
                FlutterFlowTheme.of(context).secondaryBackground,
                FlutterFlowTheme.of(context).primaryBackground
              ],
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 32),
              _buildHeader(isNarrow, isTablet),
              const SizedBox(height: 20),
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: itemPadding,
                      vertical: isNarrow ? 16 : 32,
                    ),
                    shrinkWrap: true,
                    children: [
                      _buildMenuItem(
                        context,
                        Icons.home_outlined,
                        primaryOrange,
                        'dc4d2jzu',
                        HomeWidget.routeName,
                        true,
                        iconSize,
                        fontSize,
                      ),
                      SizedBox(height: isNarrow ? 16 : 24),
                      _buildMenuItem(
                        context,
                        Icons.apps_outlined,
                        secondaryBlue,
                        '7gtos5g5',
                        ServiceoptionsWidget.routeName,
                        false,
                        iconSize,
                        fontSize,
                      ),
                      SizedBox(height: isNarrow ? 16 : 24),
                      _buildMenuItem(
                        context,
                        Icons.history_outlined,
                        successGreen,
                        'b6qjqpkc',
                        HistoryWidget.routeName,
                        false,
                        iconSize,
                        fontSize,
                      ),
                      SizedBox(height: isNarrow ? 16 : 24),
                      _buildMenuItem(
                        context,
                        Icons.account_circle_outlined,
                        accentPurple,
                        'yzazzu72', // Account Management string key? (Assuming it resolves correctly)
                        AccountManagementWidget.routeName,
                        false,
                        iconSize,
                        fontSize,
                      ),
                      // SizedBox(height: isNarrow ? 16 : 24),
                      // _buildMenuItem(
                      //   context,
                      //   Icons.settings_outlined,
                      //   Colors.blueGrey,
                      //   'menu_settings',
                      //   SettingsPageWidget.routeName,
                      //   false,
                      //   iconSize,
                      //   fontSize,
                      // ),
                      SizedBox(height: isNarrow ? 16 : 24),
                      _buildMenuItem(
                        context,
                        Icons.support_agent_outlined,
                        Colors.teal,
                        'menu_support',
                        CustomerSuportWidget.routeName,
                        false,
                        iconSize,
                        fontSize,
                      ),
                      SizedBox(height: isNarrow ? 16 : 24),
                      _buildMenuItem(
                        context,
                        Icons.card_giftcard,
                        primaryOrange,
                        'menu_refer_and_earn',
                        ReferAndEarnWidget.routeName,
                        false,
                        iconSize,
                        fontSize,
                      ),
                    ],
                  ),
                ),
              ),
              _buildFooter(isNarrow, isTablet),
              SizedBox(height: isNarrow ? 20 : 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isNarrow, bool isTablet) {
    final avatarSize = isNarrow
        ? 52.0
        : isTablet
        ? 68.0
        : 64.0;

    return InkWell(
      onTap: () {
        Navigator.of(context).pop(); // close drawer
        context.pushNamed(ProfileSettingWidget.routeName);
      },

      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [gradientStart, gradientEnd]),
          boxShadow: [
            BoxShadow(
              color: gradientEnd.withValues(alpha:0.3),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.12),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: _isLoadingUser
                    ? Icon(Icons.person,
                    color: gradientStart.withValues(alpha:0.75),
                    size: isNarrow ? 26 : 30)
                    : (_profileImageUrl.isNotEmpty
                    ? Image.network(
                  _profileImageUrl,
                  fit: BoxFit.cover,
                  // Shows a fallback while bytes load
                  loadingBuilder: (context, child, progress) =>
                  progress == null
                      ? child
                      : Icon(Icons.person,
                      color: gradientStart.withValues(alpha:0.75),
                      size: isNarrow ? 26 : 30),
                  // Shows a fallback on error
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.person,
                    color: gradientStart,
                    size: isNarrow ? 26 : 30,
                  ),
                )
                    : Icon(Icons.person,
                    color: gradientStart, size: isNarrow ? 26 : 30)),
              ),
            ),
            SizedBox(width: isNarrow ? 14 : 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back!',
                    style: GoogleFonts.poppins(
                      fontSize: isNarrow ? 16 : 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha:0.95),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _isLoadingUser
                      ? SizedBox(
                    width: 120,
                    height: 14,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withValues(alpha:0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                      : Text(
                    _userDisplayName,
                    style: GoogleFonts.poppins(
                      fontSize: isNarrow ? 16 : 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    IconData icon,
    Color iconColor,
    String labelKey,
    String route,
    bool isActive,
    double iconSize,
    double fontSize,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
           context.pushNamed(route);

          },
          borderRadius: BorderRadius.circular(20),
          splashColor: iconColor.withValues(alpha:0.15),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color:
                  isActive ? iconColor.withValues(alpha:0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: isActive
                  ? Border.all(color: iconColor.withValues(alpha:0.4), width: 2)
                  : null,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: iconColor.withValues(alpha:0.2),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: iconSize + 12,
                  height: iconSize + 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        iconColor.withValues(alpha:0.2),
                        iconColor.withValues(alpha:0.08)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: iconColor, size: iconSize),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    FFLocalizations.of(context).getText(labelKey),
                    style: GoogleFonts.poppins(
                      fontSize: fontSize,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                      color: isActive
                          ? iconColor
                          : FlutterFlowTheme.of(context).primaryText,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: iconColor.withValues(alpha:isActive ? 1.0 : 0.5),
                  size: iconSize * 0.65,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isNarrow, bool isTablet) {
    return InkWell(
      onTap: () async {
        try {
          final token = FFAppState().accessToken;
          if (token.isNotEmpty) {
            await UserLogoutCall.call(token: token);
          }
          await FirebaseAuth.instance.signOut();

          FFAppState().clearAuthSession();

          context.goNamedAuth(LoginWidget.routeName, context.mounted);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(FFLocalizations.of(context).getText('logged_out_success')),
              backgroundColor: primaryOrange,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Logout error: $e')),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 24),
        padding: EdgeInsets.all(isNarrow ? 18 : 24),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: FlutterFlowTheme.of(context).alternate.withValues(alpha: 0.5),
              width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: isNarrow ? 44 : 52,
              height: isNarrow ? 44 : 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [primaryOrange, gradientEnd]),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.logout_rounded,
                  color: Colors.white, size: isNarrow ? 22 : 26),
            ),
            SizedBox(width: isNarrow ? 14 : 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    FFLocalizations.of(context).getText('sign_out'),
                    style: GoogleFonts.poppins(
                      fontSize: isNarrow ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      color: FlutterFlowTheme.of(context).primaryText,
                    ),
                  ),
                  Text(
                    FFLocalizations.of(context).getText('leave_session'),
                    style: GoogleFonts.inter(
                      fontSize: isNarrow ? 12 : 13,
                      color: FlutterFlowTheme.of(context).secondaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
