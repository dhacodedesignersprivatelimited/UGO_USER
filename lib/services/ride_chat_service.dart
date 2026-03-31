import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '/core/app_config.dart';

/// In-ride chat (WebSocket) — same events as backend `chatHandler.js`.
class RideChatMessage {
  RideChatMessage({
    this.dbId,
    required this.rideId,
    required this.text,
    required this.senderId,
    required this.senderType,
    required this.timestamp,
  });

  /// Server row id (for dedupe when replaying [chat_history] after reconnect).
  final int? dbId;
  final int rideId;
  final String text;
  final int senderId;
  final String senderType;
  final DateTime timestamp;

  static RideChatMessage? fromPayload(dynamic raw) {
    if (raw is! Map) return null;
    final m = Map<String, dynamic>.from(raw);
    final rid = m['rideId'] ?? m['ride_id'];
    final sid = m['senderId'] ?? m['sender_id'];
    final ts = m['timestamp']?.toString();
    final idRaw = m['id'];
    final dbId = idRaw is int
        ? idRaw
        : (idRaw != null ? int.tryParse(idRaw.toString()) : null);
    return RideChatMessage(
      dbId: dbId,
      rideId: rid is int ? rid : int.tryParse(rid?.toString() ?? '') ?? 0,
      text: m['message']?.toString() ?? '',
      senderId: sid is int ? sid : int.tryParse(sid?.toString() ?? '') ?? 0,
      senderType:
          m['senderType']?.toString() ?? m['sender_type']?.toString() ?? '',
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

  void connect() {
    if (token.isEmpty) {
      _errors.add('Not signed in');
      return;
    }

    _socket?.dispose();
    _socket = IO.io(
      AppConfig.baseApiUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(5)
          .setAuth({'token': token})
          .setQuery({'token': token})
          .build(),
    );

    _socket!.onConnect((_) {
      if (kDebugMode) debugPrint('[RideChat] connected');
      _socket!.emit('join_chat', {'rideId': rideId, 'ride_id': rideId});
    });

    _socket!.on('chat_history', (data) {
      if (data is! Map) return;
      final list = data['messages'];
      if (list is! List) return;
      final batch = <RideChatMessage>[];
      for (final raw in list) {
        final msg = RideChatMessage.fromPayload(raw);
        if (msg != null && msg.text.isNotEmpty) batch.add(msg);
      }
      if (batch.isNotEmpty) _history.add(batch);
    });

    _socket!.on('chat_joined', (_) {
      _joined.add(true);
    });

    _socket!.on('chat_message', (data) {
      final msg = RideChatMessage.fromPayload(data);
      if (msg != null && msg.text.isNotEmpty) _messages.add(msg);
    });

    _socket!.on('chat_typing', (data) {
      if (data is! Map) return;
      final m = Map<String, dynamic>.from(data);
      final sid = m['senderId'] ?? m['sender_id'];
      final otherId =
          sid is int ? sid : int.tryParse(sid?.toString() ?? '') ?? -1;
      if (otherId == myUserId) return;
      final typing = m['isTyping'] != false;
      _typingOther.add(typing);
    });

    _socket!.on('chat_error', (data) {
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

  void sendMessage(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    if (_socket == null || !(_socket!.connected)) {
      _errors.add('Chat is reconnecting. Please try again.');
      return;
    }
    _socket!.emit('send_chat_message', {
      'rideId': rideId,
      'ride_id': rideId,
      'message': t,
    });
  }

  void setTyping(bool typing) {
    if (_socket == null || !(_socket!.connected)) return;
    _socket!.emit('chat_typing', {
      'rideId': rideId,
      'ride_id': rideId,
      'isTyping': typing
    });
  }

  void dispose() {
    _socket?.dispose();
    _socket = null;
    _messages.close();
    _history.close();
    _typingOther.close();
    _errors.close();
    _joined.close();
  }
}
