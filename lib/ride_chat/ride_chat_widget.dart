import 'dart:async';

import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/ride_chat_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ride_chat_model.dart';
export 'ride_chat_model.dart';

/// Uber-style in-ride chat with driver (WebSocket).
class RideChatWidget extends StatefulWidget {
  const RideChatWidget({
    super.key,
    required this.rideId,
    this.partnerName = 'Driver',
  });

  final int rideId;
  final String partnerName;

  static String routeName = 'RideChat';
  static String routePath = '/rideChat';

  @override
  State<RideChatWidget> createState() => _RideChatWidgetState();
}

class _RideChatWidgetState extends State<RideChatWidget> {
  late RideChatModel _model;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _items = <RideChatMessage>[];
  RideChatService? _svc;
  StreamSubscription? _subMsg;
  StreamSubscription? _subHistory;
  StreamSubscription? _subErr;
  StreamSubscription? _subTyping;
  bool _otherTyping = false;
  Timer? _typingDebounce;
  bool _joined = false;

  static const _orange = Color(0xFFFF7B10);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RideChatModel());
    _startChat();
  }

  void _startChat() {
    final app = FFAppState();
    final uid = app.userid;
    final token = app.accessToken;
    if (uid <= 0 || token.isEmpty) return;

    _svc = RideChatService(
      token: token,
      rideId: widget.rideId,
      myRole: 'user',
      myUserId: uid,
    );

    _subHistory = _svc!.chatHistory.listen((batch) {
      if (!mounted) return;
      setState(() {
        for (final m in batch) {
          if (m.dbId != null && _items.any((x) => x.dbId == m.dbId)) continue;
          _items.add(m);
        }
        _items.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _otherTyping = false;
      });
      _scrollToEnd();
    });

    _subMsg = _svc!.messages.listen((m) {
      if (!mounted) return;
      if (m.dbId != null && _items.any((x) => x.dbId == m.dbId)) return;
      setState(() {
        _items.add(m);
        _items.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _otherTyping = false;
      });
      _scrollToEnd();
    });

    _subErr = _svc!.errors.listen((e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e)));
    });

    _subTyping = _svc!.typingFromOther.listen((t) {
      if (!mounted) return;
      setState(() => _otherTyping = t);
    });

    _svc!.joined.listen((j) {
      if (mounted) setState(() => _joined = j);
    });

    _svc!.connect();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  bool _isMine(RideChatMessage m) {
    if (m.senderId != FFAppState().userid) return false;
    final t = m.senderType.toLowerCase();
    return t.isEmpty || t == 'user';
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _subMsg?.cancel();
    _subHistory?.cancel();
    _subErr?.cancel();
    _subTyping?.cancel();
    _svc?.dispose();
    _input.dispose();
    _scroll.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F7),
        appBar: AppBar(
          backgroundColor: _orange,
          elevation: 0,
          leading: FlutterFlowIconButton(
            borderRadius: 30,
            buttonSize: 48,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.partnerName,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              Text(
                _joined ? 'In-trip messages' : 'Connecting…',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                itemCount: _items.length + (_otherTyping ? 1 : 0),
                itemBuilder: (context, i) {
                  if (_otherTyping && i == _items.length) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${widget.partnerName} is typing…',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  }
                  final m = _items[i];
                  final mine = _isMine(m);
                  return Align(
                    alignment:
                        mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width * 0.78,
                      ),
                      decoration: BoxDecoration(
                        color: mine ? _orange : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: Radius.circular(mine ? 18 : 4),
                          bottomRight: Radius.circular(mine ? 4 : 18),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        m.text,
                        style: GoogleFonts.inter(
                          color: mine ? Colors.white : Colors.black87,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Material(
              elevation: 8,
              color: FlutterFlowTheme.of(context).secondaryBackground,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 4,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Message ${widget.partnerName}…',
                            filled: true,
                            fillColor: const Color(0xFFF0F0F5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          onChanged: (_) {
                            _svc?.setTyping(true);
                            _typingDebounce?.cancel();
                            _typingDebounce = Timer(
                              const Duration(milliseconds: 600),
                              () => _svc?.setTyping(false),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: _orange,
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: () {
                            final t = _input.text;
                            _input.clear();
                            _svc?.setTyping(false);
                            _svc?.sendMessage(t);
                          },
                          icon: const Icon(Icons.send_rounded,
                              color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
