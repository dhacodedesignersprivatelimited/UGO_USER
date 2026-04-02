import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '/core/app_config.dart';

/// In-ride chat: legacy `chat_*` events + v2 `ride_chat_*` / `receive_ride_message`.
class RideChatMessage {
  RideChatMessage({
    this.dbId,
    required this.rideId,
    required this.text,
    required this.senderId,
    required this.senderType,
    required this.timestamp,
  });

  /// Server row id (dedupe REST + socket + reopen).
  final int? dbId;
  final int rideId;
  final String text;
  final int senderId;
  final String senderType;
  final DateTime timestamp;

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  /// Socket payloads (camelCase and snake_case; `message` or `message_text`).
  static RideChatMessage? fromPayload(dynamic raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final rid = m['rideId'] ?? m['ride_id'];
    final sid = m['senderId'] ?? m['sender_id'];
    final text = (m['message_text'] ?? m['message'])?.toString() ?? '';
    if (text.trim().isEmpty) return null;
    final ts = (m['timestamp'] ?? m['sent_at'])?.toString();
    final dbId = _parseInt(m['id']);
    return RideChatMessage(
      dbId: dbId,
      rideId: rid is int ? rid : int.tryParse(rid?.toString() ?? '') ?? 0,
      text: text.trim(),
      senderId: sid is int ? sid : int.tryParse(sid?.toString() ?? '') ?? 0,
      senderType:
          m['senderType']?.toString() ?? m['sender_type']?.toString() ?? '',
      timestamp: DateTime.tryParse(ts ?? '') ?? DateTime.now(),
    );
  }

  /// REST `GET /api/chat/ride/:id/messages` items.
  static RideChatMessage? fromApiJson(Map<String, dynamic> m, int rideId) {
    final text = (m['message_text'] ?? m['message'])?.toString().trim() ?? '';
    if (text.isEmpty) return null;
    final sid = _parseInt(m['sender_id']);
    if (sid == null) return null;
    final ts = m['sent_at']?.toString();
    return RideChatMessage(
      dbId: _parseInt(m['id']),
      rideId: rideId,
      text: text,
      senderId: sid,
      senderType: m['sender_type']?.toString() ?? '',
      timestamp: DateTime.tryParse(ts ?? '') ?? DateTime.now(),
    );
  }
}

class RideChatService {
  RideChatService({
    required this.token,
    required this.rideId,
    required this.myRole,
    required this.myUserId,
  });

  final String token;
  final int rideId;

  /// Backend JWT role: `user` or `driver`
  final String myRole;
  final int myUserId;

  IO.Socket? _socket;
  final _messages = StreamController<RideChatMessage>.broadcast();
  final _history = StreamController<List<RideChatMessage>>.broadcast();
  final _typingOther = StreamController<bool>.broadcast();
  final _errors = StreamController<String>.broadcast();
  final _joined = StreamController<bool>.broadcast();

  Stream<RideChatMessage> get messages => _messages.stream;
  Stream<List<RideChatMessage>> get chatHistory => _history.stream;
  Stream<bool> get typingFromOther => _typingOther.stream;
  Stream<String> get errors => _errors.stream;
  Stream<bool> get joined => _joined.stream;

  bool get isConnected => _socket?.connected ?? false;

  void _emitJoinRooms() {
    if (_socket == null || !_socket!.connected) return;
    final payload = {'rideId': rideId, 'ride_id': rideId};
    _socket!.emit('join_chat', payload);
    _socket!.emit('join_ride_chat', payload);
  }

  void _handleHistoryPayload(dynamic data) {
    if (data is! Map) return;
    final list = data['messages'];
    if (list is! List) return;
    final batch = <RideChatMessage>[];
    for (final raw in list) {
      final msg = RideChatMessage.fromPayload(raw);
      if (msg != null) batch.add(msg);
    }
    if (batch.isNotEmpty) _history.add(batch);
  }

  void connect() {
    if (token.isEmpty) {
      _errors.add('Not signed in');
      return;
    }

    final cleanToken = token.replaceFirst('Bearer ', '').trim();
    if (cleanToken.isEmpty ||
        cleanToken.toLowerCase() == 'null' ||
        cleanToken.toLowerCase() == 'undefined') {
      _errors.add('Not signed in');
      return;
    }

    _socket?.dispose();
    _socket = IO.io(
      AppConfig.baseApiUrl,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setAuth({'token': cleanToken})
          .setQuery({'token': cleanToken})
          .build(),
    );

    _socket!.onConnect((_) {
      if (kDebugMode) debugPrint('[RideChat] connected');
      _joined.add(true);
      _emitJoinRooms();
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (_socket?.connected == true) _emitJoinRooms();
      });
    });

    _socket!.onReconnect((_) {
      _joined.add(true);
      _emitJoinRooms();
    });

    _socket!.onDisconnect((_) {
      _joined.add(false);
    });

    _socket!.on('chat_history', _handleHistoryPayload);
    _socket!.on('ride_chat_history', _handleHistoryPayload);

    _socket!.on('chat_joined', (_) {
      _joined.add(true);
    });
    _socket!.on('ride_chat_joined', (_) {
      _joined.add(true);
    });

    void onLiveMessage(dynamic data) {
      final msg = RideChatMessage.fromPayload(data);
      if (msg != null) _messages.add(msg);
    }

    _socket!.on('chat_message', onLiveMessage);
    _socket!.on('receive_ride_message', onLiveMessage);

    _socket!.on('chat_typing', (data) {
      if (data is! Map) return;
      final m = Map<String, dynamic>.from(data);
      final sid = m['senderId'] ?? m['sender_id'];
      final otherId =
          sid is int ? sid : int.tryParse(sid?.toString() ?? '') ?? -1;
      if (otherId == myUserId) return;
      final typing = m['isTyping'] == true || m['is_typing'] == true;
      _typingOther.add(typing);
    });

    _socket!.on('typing_status', (data) {
      if (data is! Map) return;
      final m = Map<String, dynamic>.from(data);
      final sid = m['senderId'] ?? m['sender_id'];
      final otherId =
          sid is int ? sid : int.tryParse(sid?.toString() ?? '') ?? -1;
      if (otherId == myUserId) return;
      final typing = m['isTyping'] == true || m['is_typing'] == true;
      _typingOther.add(typing);
    });

    _socket!.on('chat_error', (data) {
      final msg = data is Map ? data['message']?.toString() : data?.toString();
      _errors.add(msg ?? 'Chat error');
    });
    _socket!.on('ride_chat_error', (data) {
      final msg = data is Map ? data['message']?.toString() : data?.toString();
      _errors.add(msg ?? 'Chat error');
    });
    _socket!.on('error', (data) {
      final msg = data is Map ? data['message']?.toString() : data?.toString();
      _errors.add(msg ?? 'Chat error');
    });

    _socket!.onConnectError((e) => _errors.add('Connection failed'));
    _socket!.onError((e) => _errors.add('Network error'));

    _socket!.connect();
  }

  void sendMessage(String text, {String? messageType}) {
    final t = text.trim();
    if (t.isEmpty) return;
    if (_socket == null || !(_socket!.connected)) {
      _errors.add('Chat is reconnecting. Please try again.');
      return;
    }
    final payload = {
      'rideId': rideId,
      'ride_id': rideId,
      'message': t,
      if (messageType != null) 'message_type': messageType,
    };
    /** Single path: backend persists once and mirrors to legacy `chat_*` room. */
    _socket!.emit('send_ride_message', payload);
  }

  void setTyping(bool typing) {
    if (_socket == null || !(_socket!.connected)) return;
    final payload = {
      'rideId': rideId,
      'ride_id': rideId,
      'isTyping': typing,
      'is_typing': typing,
    };
    _socket!.emit('chat_typing', payload);
    _socket!.emit('typing_status', payload);
  }

  void dispose() {
    try {
      if (_socket != null && _socket!.connected) {
        final leave = {'rideId': rideId, 'ride_id': rideId};
        _socket!.emit('leave_ride_chat', leave);
      }
    } catch (_) {
      /* ignore */
    }
    _socket?.dispose();
    _socket = null;
    _messages.close();
    _history.close();
    _typingOther.close();
    _errors.close();
    _joined.close();
  }
}
