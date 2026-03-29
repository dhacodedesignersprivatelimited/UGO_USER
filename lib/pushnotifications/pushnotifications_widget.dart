import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_util.dart';
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
      // Mark that user has viewed notifications at this time
      FFAppState().lastNotificationCheckTime = DateTime.now();
      FFAppState().update(() {});
      debugPrint('📝 Saved last check time: ${DateTime.now()}');
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
          actions: [
            Builder(
              builder: (context) {
                final raw = GetAllNotificationsCall.notifications(
                    _model.notificationsResponse?.jsonBody);
                final hasUnread = raw?.any(
                        (n) => getJsonField(n, r'''$.is_read''') != true) ??
                    false;
                if (!hasUnread) return const SizedBox.shrink();
                return TextButton(
                  onPressed: () async {
                    final token = FFAppState().accessToken;
                    if (token.isEmpty) return;
                    await MarkAllNotificationsReadCall.call(token: token);
                    if (mounted) await _loadNotifications();
                  },
                  child: Text(
                    'Mark all read',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                );
              },
            ),
          ],
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

    final userNotifications = GetAllNotificationsCall.notifications(
        _model.notificationsResponse?.jsonBody);

    debugPrint('📊 Inbox notifications: ${userNotifications?.length ?? 0}');

    if (userNotifications == null || userNotifications.isEmpty) {
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
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: _buildGroupedNotificationList(userNotifications),
      ),
    );
  }

  String _dayBucket(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final day = DateTime(d.year, d.month, d.day);
    if (day == today) return 'Today';
    if (day == yesterday) return 'Yesterday';
    return 'Earlier';
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.grey[700],
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  List<Widget> _buildGroupedNotificationList(List<dynamic> items) {
    final sorted = List<dynamic>.from(items);
    sorted.sort((a, b) {
      final da = DateTime.tryParse(
              getJsonField(a, r'''$.created_at''')?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final db = DateTime.tryParse(
              getJsonField(b, r'''$.created_at''')?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });

    String? lastBucket;
    final out = <Widget>[];
    for (final item in sorted) {
      final createdAt =
          getJsonField(item, r'''$.created_at''')?.toString() ?? '';
      final date =
          DateTime.tryParse(createdAt) ?? DateTime.now();
      final bucket = _dayBucket(date);
      if (bucket != lastBucket) {
        out.add(_buildSectionHeader(bucket));
        lastBucket = bucket;
      }
      out.add(_buildNotificationItem(item));
      out.add(
          const Divider(height: 1, indent: 72, color: Color(0xFFEEEEEE)));
    }
    return out;
  }

  Widget _buildNotificationItem(dynamic item) {
    // Extract data based on Postman response
    final title = getJsonField(item, r'''$.notification_title''')?.toString() ?? 
                  getJsonField(item, r'''$.title''')?.toString() ?? 'Notification';
    final message = getJsonField(item, r'''$.notification_body''')?.toString() ?? 
                    getJsonField(item, r'''$.message''')?.toString() ?? '';
    final createdAt = getJsonField(item, r'''$.created_at''')?.toString();
    final isRead = getJsonField(item, r'''$.is_read''') == true;
    final type = getJsonField(item, r'''$.type''')?.toString().toLowerCase() ?? 'info';

    IconData iconData = Icons.notifications_rounded;
    Color iconColor = const Color(0xFFFF7B10);

    if (type.contains('ride') || type.contains('trip')) {
      iconData = Icons.directions_car_filled_rounded;
    } else if (type.contains('payment')) {
      iconData = Icons.account_balance_wallet_rounded;
      iconColor = Colors.green;
    } else if (type.contains('promo')) {
      iconData = Icons.local_offer_rounded;
      iconColor = Colors.blue;
    } else if (type.contains('cancel')) {
      iconData = Icons.cancel_rounded;
      iconColor = Colors.red;
    }

    DateTime? date;
    if (createdAt != null) {
      date = DateTime.tryParse(createdAt);
    }

    return InkWell(
      onTap: () async {
        final idRaw = getJsonField(item, r'''$.id''');
        final nid = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
        final token = FFAppState().accessToken;
        if (!isRead && nid != null && token.isNotEmpty) {
          await MarkNotificationReadCall.call(notificationId: nid, token: token);
          if (mounted) await _loadNotifications();
        }
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
                color: iconColor.withValues(alpha:0.1),
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