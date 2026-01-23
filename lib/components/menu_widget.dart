import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'menu_model.dart';
export 'menu_model.dart';

/// 🚀 Modern Responsive Drawer Menu with User Details
class MenuWidget extends StatefulWidget {
  const MenuWidget({super.key});

  @override
  State<MenuWidget> createState() => _MenuWidgetState();
}

class _MenuWidgetState extends State<MenuWidget> with TickerProviderStateMixin {
  late MenuModel _model;

  // Animation Controllers
  late AnimationController _hoverController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;

  // Design Constants
  static const Color primaryOrange = Color(0xFFFF7B10);
  static const Color secondaryBlue = Color(0xFF2196F3);
  static const Color accentPurple = Color(0xFF9C27B0);
  static const Color surfaceColor = Color(0xFFF8FAFC);
  static const Color gradientStart = Color(0xFFFFA726);
  static const Color gradientEnd = Color(0xFFFF5722);

  // User State Variables
  String _profileImageUrl = "";

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MenuModel());

    // Initialize Animations
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    )..forward();

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack));

    // ✅ FIX 1: Safe assignment with toString()
    // If you were fetching profile image from somewhere that returned Object
    // _profileImageUrl = someObject.toString();
  }

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void dispose() {
    _hoverController.dispose();
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

        final itemPadding = isNarrow ? 12.0 : 20.0;
        final iconSize = isNarrow ? 28.0 : isTablet ? 32.0 : 30.0;
        final fontSize = isNarrow ? 16.0 : isTablet ? 18.0 : 17.0;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                surfaceColor,
                Colors.white,
                surfaceColor,
              ],
            ),
          ),
          child: Column(
            children: [
              // 1. HEADER SECTION
              _buildHeader(isNarrow),
              const SizedBox(height: 20),

              // 2. MENU ITEMS (Animated Slide)
              Expanded(
                child: SlideTransition(
                  position: _slideAnimation,
                  child: ListView(
                    padding: EdgeInsets.symmetric(
                      horizontal: itemPadding,
                      vertical: isNarrow ? 20 : 40,
                    ),
                    shrinkWrap: true,
                    children: [
                      _buildMenuItem(
                        context,
                        icon: Icons.home_outlined,
                        iconColor: primaryOrange,
                        labelKey: 'dc4d2jzu', // Home
                        route: HomeWidget.routeName,
                        isActive: true,
                        iconSize: iconSize,
                        fontSize: fontSize,
                      ),
                      SizedBox(height: isNarrow ? 16 : 24),

                      _buildMenuItem(
                        context,
                        icon: Icons.apps_outlined,
                        iconColor: secondaryBlue,
                        labelKey: '7gtos5g5', // Services
                        route: ServiceoptionsWidget.routeName,
                        iconSize: iconSize,
                        fontSize: fontSize,
                      ),
                      SizedBox(height: isNarrow ? 16 : 24),

                      _buildMenuItem(
                        context,
                        icon: Icons.history_outlined,
                        iconColor: const Color(0xFF4CAF50),
                        labelKey: 'b6qjqpkc', // History
                        route: BookinghistoryWidget.routeName,
                        iconSize: iconSize,
                        fontSize: fontSize,
                      ),
                      SizedBox(height: isNarrow ? 16 : 24),

                      _buildMenuItem(
                        context,
                        icon: Icons.account_circle_outlined,
                        iconColor: accentPurple,
                        labelKey: 'yzazzu72', // Account
                        route: AccountManagementWidget.routeName,
                        iconSize: iconSize,
                        fontSize: fontSize,
                      ),
                    ],
                  ),
                ),
              ),

              // 3. FOOTER SECTION
              _buildFooter(isNarrow),
              SizedBox(height: isNarrow ? 20 : 30),
            ],
          ),
        );
      },
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader(bool isNarrow) {
    // ✅ FIX 2: Safely access user ID, defaulting to "Guest"
    // Since 'userMobile' doesn't exist, we use 'userid' which usually exists.
    final String displayUser = FFAppState().userid != 0
        ? "User ID: ${FFAppState().userid}"
        : "Guest User";

    return Container(
      padding: EdgeInsets.all(isNarrow ? 20 : 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientEnd.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Avatar
          Container(
            width: isNarrow ? 50 : 60,
            height: isNarrow ? 50 : 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: _profileImageUrl.isNotEmpty
                  ? Image.network(
                _profileImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person,
                  color: gradientStart,
                  size: isNarrow ? 24 : 28,
                ),
              )
                  : Icon(
                Icons.person,
                color: gradientStart,
                size: isNarrow ? 24 : 28,
              ),
            ),
          ),
          SizedBox(width: isNarrow ? 12 : 16),

          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back!',
                  style: GoogleFonts.poppins(
                    fontSize: isNarrow ? 12 : 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                Text(
                  displayUser, // ✅ Uses the safe variable from above
                  style: GoogleFonts.poppins(
                    fontSize: isNarrow ? 16 : 18,
                    fontWeight: FontWeight.w700,
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
    );
  }

  // ==================== MENU ITEM BUILDER ====================
  Widget _buildMenuItem(
      BuildContext context, {
        required IconData icon,
        required Color iconColor,
        required String labelKey,
        required String route,
        required double iconSize,
        required double fontSize,
        bool isActive = false,
      }) {
    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return MouseRegion(
          onEnter: (_) => _hoverController.forward(),
          onExit: (_) => _hoverController.reverse(),
          child: InkWell(
            onTap: () => context.pushNamed(route),
            borderRadius: BorderRadius.circular(20),
            splashColor: iconColor.withOpacity(0.1),
            highlightColor: iconColor.withOpacity(0.05),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isActive
                    ? iconColor.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: isActive
                    ? Border.all(color: iconColor.withOpacity(0.3), width: 1.5)
                    : null,
                boxShadow: isActive
                    ? [
                  BoxShadow(
                    color: iconColor.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
                    : null,
              ),
              child: Row(
                children: [
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: iconSize + 8,
                      height: iconSize + 8,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            iconColor.withOpacity(0.15),
                            iconColor.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: iconSize,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      FFLocalizations.of(context).getText(labelKey),
                      style: GoogleFonts.poppins(
                        fontSize: fontSize,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                        color: isActive ? iconColor : FlutterFlowTheme.of(context).primaryText,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: iconColor.withOpacity(isActive ? 1.0 : 0.4),
                    size: iconSize * 0.6,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==================== FOOTER ====================
  Widget _buildFooter(bool isNarrow) {
    return InkWell(
      onTap: () async {
        FFAppState().accessToken = "";
        FFAppState().userid = 0;

        // Ensure you have a 'LoginWidget' route defined in your app
        // context.goNamed('LoginWidget');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logged Out Successfully")),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 24),
        padding: EdgeInsets.all(isNarrow ? 16 : 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: isNarrow ? 40 : 48,
                  height: isNarrow ? 40 : 48,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryOrange, gradientEnd],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: isNarrow ? 20 : 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign Out',
                        style: GoogleFonts.poppins(
                          fontSize: isNarrow ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'Leave the app',
                        style: GoogleFonts.inter(
                          fontSize: isNarrow ? 11 : 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
