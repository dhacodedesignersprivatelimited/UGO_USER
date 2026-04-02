import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '/app_state.dart';
import '/flutter_flow/nav/nav.dart';
import '/ride_chat/ride_chat_widget.dart';

bool _isOnRideChat(GoRouter router, int rideId) {
  final loc = router.getCurrentLocation();
  return loc.contains(RideChatWidget.routePath) &&
      loc.contains('rideId=$rideId');
}

/// Opens ride chat from FCM `data` map (`ride_id`, optional `sender_name`).
void openRideChatFromFcmData(GoRouter router, Map<String, dynamic> data) {
  final raw = data['ride_id'] ?? data['rideId'] ?? data['rideID'];
  final rideId = raw is int ? raw : int.tryParse(raw?.toString() ?? '');
  if (rideId == null || FFAppState().userid == 0) return;
  if (_isOnRideChat(router, rideId)) return;
  final sender = data['sender_name']?.toString().trim();
  router.pushNamed(
    RideChatWidget.routeName,
    queryParameters: {
      'rideId': rideId.toString(),
      if (sender != null && sender.isNotEmpty) 'partnerName': sender,
    },
  );
}

void openRideChatForRide(
  GoRouter router,
  int rideId, {
  String? partnerName,
}) {
  if (FFAppState().userid == 0) return;
  if (_isOnRideChat(router, rideId)) return;
  router.pushNamed(
    RideChatWidget.routeName,
    queryParameters: {
      'rideId': rideId.toString(),
      if (partnerName != null && partnerName.isNotEmpty)
        'partnerName': partnerName,
    },
  );
}

/// Floating SnackBar for new driver→rider chat while user is elsewhere in the app.
void showRideChatInAppSnackBar(
  GoRouter router, {
  required int rideId,
  required String title,
  required String preview,
  required VoidCallback onOpen,
}) {
  if (_isOnRideChat(router, rideId)) return;

  final messenger = appScaffoldMessengerKey.currentState;
  if (messenger == null) return;

  final cleanedPreview = preview.trim();
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF2C1A08),
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      duration: const Duration(seconds: 6),
      content: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFF7A00),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: Colors.white,
                  ),
                ),
                if (cleanedPreview.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    cleanedPreview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.25,
                      color: Color(0xFFFFD7B2),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      action: SnackBarAction(
        label: 'Reply',
        textColor: const Color(0xFFFFA047),
        onPressed: onOpen,
      ),
    ),
  );
}

/// Foreground FCM: same UI as socket path.
void showRideChatInAppFromForegroundFcm(
  GoRouter router,
  RemoteMessage message,
  Map<String, dynamic> data,
  int rideId,
) {
  final title = message.notification?.title ?? 'New message';
  final preview =
      data['message_preview']?.toString() ?? message.notification?.body ?? '';
  showRideChatInAppSnackBar(
    router,
    rideId: rideId,
    title: title,
    preview: preview,
    onOpen: () => openRideChatFromFcmData(router, data),
  );
}
