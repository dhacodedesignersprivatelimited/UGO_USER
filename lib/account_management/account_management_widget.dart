import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'account_management_model.dart';
export 'account_management_model.dart';

/// 🚀 Modern Responsive Account Management (FIXED & CRASH-FREE)
class AccountManagementWidget extends StatefulWidget {
  const AccountManagementWidget({super.key});

  static String routeName = 'AccountManagement';
  static String routePath = '/accountManagement';

  @override
  State<AccountManagementWidget> createState() =>
      _AccountManagementWidgetState();
}

class _AccountManagementWidgetState extends State<AccountManagementWidget> {
  late AccountManagementModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AccountManagementModel());
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
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFF7B10),
          automaticallyImplyLeading: false,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: FlutterFlowIconButton(
              borderColor: Colors.transparent,
              borderRadius: 30.0,
              borderWidth: 1.0,
              buttonSize: 44.0,
              fillColor: Colors.white.withOpacity(0.2), // ✅ Corrected background
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24.0, // ✅ Correctly passed Icon widget
              ),
              onPressed: () async {
                context.pop();
              },
            ),
          ),
          title: Text(
            FFLocalizations.of(context).getText('87zx8uve' /* Account */),
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [],
          centerTitle: true,
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = constraints.maxWidth;
              final isNarrow = screenWidth < 360;
              final padding = isNarrow ? 16.0 : 24.0;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(padding, 32, padding, 20),
                child: Column(
                  children: [
                    // 1. Profile Section
                    _buildProfileSection(isNarrow),

                    SizedBox(height: isNarrow ? 32 : 48),

                    // 2. Quick Actions Grid
                    _buildQuickActionsGrid(isNarrow),

                    SizedBox(height: isNarrow ? 32 : 48),

                    // 3. Settings List
                    _buildSettingsList(isNarrow),

                    // 4. Bottom Spacer
                    SizedBox(height: isNarrow ? 80 : 120),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(bool isNarrow) {
    return Column(
      children: [
        // Profile Image
        GestureDetector(
          onTap: () => context.pushNamed(ProfileSettingWidget.routeName),
          child: Container(
            width: isNarrow ? 90 : 110,
            height: isNarrow ? 90 : 110,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.white.withOpacity(0.8)],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF7B10),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Image.asset(
                'assets/images/profile_placeholder.png', // ✅ Replace with actual profile
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.person,
                  color: const Color(0xFFFF7B10),
                  size: isNarrow ? 45 : 55,
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: isNarrow ? 16 : 20),

        // Company Name
        Text(
          FFLocalizations.of(context).getText('xr4zc3rw' /* GO CODE DESIGNERS */),
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: isNarrow ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(bool isNarrow) {
    final crossAxisCount = isNarrow ? 3 : 3;
    final childAspectRatio = isNarrow ? 1.1 : 1.3;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: isNarrow ? 12 : 16,
      mainAxisSpacing: isNarrow ? 12 : 16,
      childAspectRatio: childAspectRatio,
      children: [
        _buildActionCard(
          icon: Icons.support_agent_rounded,
          label: FFLocalizations.of(context).getText('oc8ggcgd' /* Support */),
          color: const Color(0xFF2196F3),
          onTap: () => context.pushNamed(SupportWidget.routeName),
        ),
        _buildActionCard(
          icon: Icons.account_balance_wallet_rounded,
          label: FFLocalizations.of(context).getText('6ghijs7n' /* Wallet */),
          color: const Color(0xFF4CAF50),
          onTap: () => context.pushNamed(WalletWidget.routeName),
        ),
        _buildActionCard(
          icon: Icons.history_rounded,
          label: FFLocalizations.of(context).getText('p32bt3aj' /* History */),
          color: const Color(0xFFFF9800),
          onTap: () => context.pushNamed(BookinghistoryWidget.routeName),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(height: 12),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: 0.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList(bool isNarrow) {
    // Defines menu items structure
    final listItems = [
      {'icon': Icons.settings_rounded, 'label': 'Settings', 'route': SettingsPageWidget.routeName},
      {'icon': Icons.language_rounded, 'label': 'Languages', 'route': LanguageWidget.routeName},
      {'icon': Icons.message_rounded, 'label': 'Messages', 'route': MessagesWidget.routeName},
      {'icon': Icons.gavel_rounded, 'label': 'Legal', 'route': null}, // Route null for placeholder
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: List.generate(listItems.length, (index) {
          final item = listItems[index];
          final route = item['route'] as String?;

          return Column(
            children: [
              InkWell(
                onTap: route != null
                    ? () => context.pushNamed(route)
                    : null,
                borderRadius: BorderRadius.vertical(
                  bottom: index == listItems.length - 1
                      ? const Radius.circular(20)
                      : Radius.zero,
                ),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 20 : 24,
                    vertical: 20,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF7B10).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          item['icon'] as IconData,
                          color: const Color(0xFFFF7B10),
                          size: 22,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item['label'] as String,
                          style: GoogleFonts.poppins(
                            fontSize: isNarrow ? 16 : 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (index < listItems.length - 1)
                Divider(height: 1, color: Colors.grey[200]),
            ],
          );
        }),
      ),
    );
  }
}
