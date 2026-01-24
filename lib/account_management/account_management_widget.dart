import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import '/backend/api_requests/api_calls.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'account_management_model.dart';
export 'account_management_model.dart';

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

  bool _isLoadingUser = true;
  String _userDisplayName = 'Guest User';
  String _profileImageUrl = '';

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AccountManagementModel());
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = FFAppState().userid;
      final token = FFAppState().accessToken;

      if (userId == 0 || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoadingUser = false;
        });
        return;
      }

      final res =
          await GetUserDetailsCall.call(userId: userId, token: token);

      if (!mounted) return;

      if (res.succeeded) {
        final first =
            (GetUserDetailsCall.firstName(res.jsonBody) ?? '').trim();
        final last =
            (GetUserDetailsCall.lastName(res.jsonBody) ?? '').trim();
        final rawImg =
            (GetUserDetailsCall.profileImage(res.jsonBody) ?? '').trim();

        setState(() {
          _userDisplayName =
              [first, last].where((e) => e.isNotEmpty).join(' ');
          _profileImageUrl = rawImg.isNotEmpty
              ? (rawImg.startsWith('http')
                  ? rawImg
                  : 'https://ugotaxi.icacorp.org/$rawImg')
              : '';
          _isLoadingUser = false;
        });
      } else {
        setState(() => _isLoadingUser = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingUser = false);
    }
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
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFF7B10),
          centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.all(8),
            child: FlutterFlowIconButton(
              buttonSize: 44,
              fillColor: Colors.white.withOpacity(0.2),
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
          title: Text(
            'Account',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final isNarrow = width < 360;
              final padding = isNarrow ? 16.0 : 24.0;

              return SingleChildScrollView(
                padding:
                    EdgeInsets.fromLTRB(padding, 32, padding, 24),
                child: Column(
                  children: [
                    _buildProfileSection(isNarrow),
                    SizedBox(height: isNarrow ? 32 : 48),
                    _buildQuickActionsGrid(width),
                    SizedBox(height: isNarrow ? 32 : 48),
                    _buildSettingsList(isNarrow),
                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ---------------- PROFILE ----------------
  Widget _buildProfileSection(bool isNarrow) {
    final avatarSize = isNarrow ? 90.0 : 110.0;

    return Column(
      children: [
        GestureDetector(
          onTap: () =>
              context.pushNamed(ProfileSettingWidget.routeName),
          child: Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border:
                  Border.all(color: const Color(0xFFFF7B10), width: 3),
            ),
            child: ClipOval(
              child: _isLoadingUser
                  ? const Center(child: CircularProgressIndicator())
                  : (_profileImageUrl.isNotEmpty
                      ? Image.network(_profileImageUrl,
                          fit: BoxFit.cover)
                      : Icon(Icons.person,
                          color: const Color(0xFFFF7B10),
                          size: avatarSize / 2)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Text(
            _userDisplayName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: isNarrow ? 16 : 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- QUICK ACTIONS ----------------
  Widget _buildQuickActionsGrid(double width) {
    int crossAxisCount = 3;
    if (width > 600) crossAxisCount = 4;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final data = [
          {
            'icon': Icons.support_agent_rounded,
            'label': 'Support',
            'color': Colors.blue,
            'route': SupportWidget.routeName
          },
          {
            'icon': Icons.account_balance_wallet_rounded,
            'label': 'Wallet',
            'color': Colors.green,
            'route': WalletWidget.routeName
          },
          {
            'icon': Icons.history_rounded,
            'label': 'History',
            'color': Colors.orange,
            'route': HistoryWidget.routeName
          },
        ][index];

        return _buildActionCard(
          icon: data['icon'] as IconData,
          label: data['label'] as String,
          color: data['color'] as Color,
          onTap: () =>
              context.pushNamed(data['route'] as String),
        );
      },
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SETTINGS LIST ----------------
  Widget _buildSettingsList(bool isNarrow) {
    final items = [
      {'icon': Icons.settings, 'label': 'Settings', 'route': SettingsPageWidget.routeName},
      {'icon': Icons.language, 'label': 'Languages', 'route': LanguageWidget.routeName},
      {'icon': Icons.message, 'label': 'Messages', 'route': MessagesWidget.routeName},
      {'icon': Icons.gavel, 'label': 'Legal', 'route': null},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: items.map((item) {
          return ListTile(
            leading: Icon(item['icon'] as IconData,
                color: const Color(0xFFFF7B10)),
            title: Text(
              item['label'] as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: isNarrow ? 16 : 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing:
                const Icon(Icons.chevron_right, size: 20),
            onTap: item['route'] != null
                ? () => context.pushNamed(item['route'] as String)
                : null,
          );
        }).toList(),
      ),
    );
  }
}
