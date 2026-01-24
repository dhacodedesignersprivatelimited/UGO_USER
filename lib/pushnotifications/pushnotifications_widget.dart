import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pushnotifications_model.dart';
import 'package:timeago/timeago.dart' as timeago;
export 'pushnotifications_model.dart';

/// Notifications List Screen
class PushnotificationsWidget extends StatefulWidget {
  const PushnotificationsWidget({super.key});

  static String routeName = 'Pushnotifications';
  static String routePath = '/pushnotifications';

  @override
  State<PushnotificationsWidget> createState() =>
      _PushnotificationsWidgetState();
}

class _PushnotificationsWidgetState extends State<PushnotificationsWidget> with TickerProviderStateMixin {
  late PushnotificationsModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PushnotificationsModel());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadNotifications();
    });
  }

  Future<void> _loadNotifications() async {
    debugPrint('🔄 Fetching all notifications...');
    await _model.fetchNotifications();
    if (mounted) {
      setState(() {});
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
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color(0xFFFF7B10),
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderRadius: 20.0,
            buttonSize: 40.0,
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 24.0,
            ),
            onPressed: () => context.safePop(),
          ),
          title: Text(
            'Notifications',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 18.0,
            ),
          ),
          centerTitle: false,
          elevation: 0.0,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_model.notificationsResponse == null) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF7B10),
          strokeWidth: 3,
        ),
      );
    }

    final notificationsList = GetAllNotificationsCall.notifications(_model.notificationsResponse?.jsonBody);

    if (notificationsList == null || notificationsList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_none_rounded, size: 48, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              'No notifications',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.black),
            ),
            const SizedBox(height: 12),
            Text(
              'You\'re all caught up! Updates will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 15, color: Colors.grey[600], height: 1.5),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: const Color(0xFFFF7B10),
      backgroundColor: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: notificationsList.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 72, color: Color(0xFFEEEEEE)),
        itemBuilder: (context, index) {
          final item = notificationsList[index];
          return _buildNotificationItem(item);
        },
      ),
    );
  }

  Widget _buildNotificationItem(dynamic item) {
    // Extract data based on Postman response
    final title = getJsonField(item, r'''$.notification_title''')?.toString() ?? 
                  getJsonField(item, r'''$.title''')?.toString() ?? 'Notification';
    final message = getJsonField(item, r'''$.notification_body''')?.toString() ?? 
                    getJsonField(item, r'''$.message''')?.toString() ?? '';
    final createdAt = getJsonField(item, r'''$.created_at''')?.toString();
    final isRead = getJsonField(item, r'''$.is_read''') == true;
    final type = getJsonField(item, r'''$.type''')?.toString()?.toLowerCase() ?? 'info';

    IconData iconData = Icons.notifications_rounded;
    Color iconColor = const Color(0xFFFF7B10);

    if (type.contains('ride')) {
      iconData = Icons.directions_car_filled_rounded;
    } else if (type.contains('payment')) {
      iconData = Icons.account_balance_wallet_rounded;
      iconColor = Colors.green;
    } else if (type.contains('promo')) {
      iconData = Icons.local_offer_rounded;
      iconColor = Colors.blue;
    }

    DateTime? date;
    if (createdAt != null) {
      date = DateTime.tryParse(createdAt);
    }

    return InkWell(
      onTap: () {
        // Handle notification tap
      },
      child: Container(
        color: isRead ? Colors.white : const Color(0xFFFFF9F5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                            color: Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (date != null)
                        Text(
                          timeago.format(date, locale: 'en_short'),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isRead ? Colors.grey[600] : Colors.black87,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Unread dot
            if (!isRead)
              Container(
                margin: const EdgeInsets.only(left: 12, top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF7B10),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
