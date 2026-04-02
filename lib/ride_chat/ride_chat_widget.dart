import 'dart:async';

import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/ride_chat_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ride_chat_model.dart';
export 'ride_chat_model.dart';

/// In-ride chat (Rapido-style): loads full history from REST on every open, then WebSocket for live.
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
  StreamSubscription? _subJoined;
  bool _otherTyping = false;
  Timer? _typingDebounce;
  Timer? _markReadDebounce;
  bool _joined = false;
  bool _loadingHistory = true;

  static const _waBg = Color(0xFFFFF4EB);
  static const _waAppBar = Color(0xFFFF7A00);
  static const _waOutgoing = Color(0xFFFFB067);
  static const _waIncoming = Color(0xFFFFFFFF);
  static const _waText = Color(0xFF2B2B2B);
  static const _waMeta = Color(0xFF7A6A58);
  static const _waSend = Color(0xFFFF7A00);
  static const _waComposerBg = Color(0xFFFFE6CF);

  static const _quickReplies = <String>[
    'I am at the pickup spot',
    'Coming to the gate',
    'Please wait 2 minutes',
    'Can you call me?',
  ];

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RideChatModel());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_bootstrapChat());
    });
  }

  List<dynamic> _messageRowsFromApiBody(dynamic jsonBody) {
    final raw = getJsonField(jsonBody, r'$.data.messages');
    if (raw is List) return raw;
    try {
      if (jsonBody is Map) {
        final data = jsonBody['data'];
        if (data is Map && data['messages'] is List) {
          return List<dynamic>.from(data['messages'] as List);
        }
      }
    } catch (_) {}
    return const [];
  }

  List<RideChatMessage> _messagesFromRows(List<dynamic> rows) {
    final batch = <RideChatMessage>[];
    for (final item in rows) {
      if (item is Map<String, dynamic>) {
        final m = RideChatMessage.fromApiJson(item, widget.rideId);
        if (m != null) batch.add(m);
      } else if (item is Map) {
        final m = RideChatMessage.fromApiJson(
            Map<String, dynamic>.from(item), widget.rideId);
        if (m != null) batch.add(m);
      }
    }
    return batch;
  }

  Future<void> _pullRefresh() async {
    final token = FFAppState().accessToken;
    if (token.isEmpty || widget.rideId <= 0) return;
    try {
      final res = await RideChatGetMessagesCall.call(
        rideId: widget.rideId,
        token: token,
        limit: 100,
      );
      if (!mounted || !res.succeeded) return;
      final batch = _messagesFromRows(_messageRowsFromApiBody(res.jsonBody));
      setState(() => _mergeIncoming(batch));
      _scrollToEnd();
      unawaited(RideChatMarkReadCall.call(rideId: widget.rideId, token: token));
    } catch (_) {}
  }

  void _markReadSoon() {
    final token = FFAppState().accessToken;
    if (token.isEmpty || widget.rideId <= 0) return;
    _markReadDebounce?.cancel();
    _markReadDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(RideChatMarkReadCall.call(rideId: widget.rideId, token: token));
    });
  }

  Future<void> _bootstrapChat() async {
    final app = FFAppState();
    final uid = app.userid;
    final token = app.accessToken;
    if (widget.rideId <= 0) {
      if (mounted) setState(() => _loadingHistory = false);
      return;
    }
    if (uid <= 0 || token.isEmpty) {
      if (mounted) setState(() => _loadingHistory = false);
      return;
    }

    try {
      unawaited(RideChatInitCall.call(rideId: widget.rideId, token: token));
      final res = await RideChatGetMessagesCall.call(
        rideId: widget.rideId,
        token: token,
        limit: 100,
      );
      if (res.succeeded && mounted) {
        final batch = _messagesFromRows(_messageRowsFromApiBody(res.jsonBody));
        setState(() {
          _mergeIncoming(batch);
          _loadingHistory = false;
        });
        _scrollToEnd();
      } else if (mounted) {
        setState(() => _loadingHistory = false);
      }

      unawaited(RideChatMarkReadCall.call(rideId: widget.rideId, token: token));
    } catch (_) {
      if (mounted) setState(() => _loadingHistory = false);
    }

    if (!mounted) return;
    _startSocket(uid, token);
  }

  bool _messageForThisRide(RideChatMessage m) =>
      m.rideId == 0 || m.rideId == widget.rideId;

  void _mergeIncoming(Iterable<RideChatMessage> incoming) {
    for (final m in incoming) {
      if (!_messageForThisRide(m)) continue;
      if (m.dbId != null && _items.any((x) => x.dbId == m.dbId)) continue;
      _items.add(m);
    }
    _items.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  void _stripOptimisticEcho(RideChatMessage confirmed) {
    final idx = _items.indexWhere((x) =>
        x.dbId == null && _isMine(x) && x.text.trim() == confirmed.text.trim());
    if (idx >= 0) _items.removeAt(idx);
  }

  void _sendOutgoing(String text, {String? messageType}) {
    final t = text.trim();
    if (t.isEmpty) return;
    if (_svc == null || !_svc!.isConnected) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('Not connected. Try again in a moment.')),
      );
      return;
    }
    _svc!.setTyping(false);
    final optimistic = RideChatMessage(
      dbId: null,
      rideId: widget.rideId,
      text: t,
      senderId: FFAppState().userid,
      senderType: 'rider',
      timestamp: DateTime.now(),
    );
    setState(() {
      _items.add(optimistic);
      _items.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    });
    _scrollToEnd();
    _svc!.sendMessage(t, messageType: messageType);
  }

  void _startSocket(int uid, String token) {
    _subMsg?.cancel();
    _subHistory?.cancel();
    _subErr?.cancel();
    _subTyping?.cancel();
    _subJoined?.cancel();
    _subMsg = null;
    _subHistory = null;
    _subErr = null;
    _subTyping = null;
    _subJoined = null;
    _svc?.dispose();

    _svc = RideChatService(
      token: token,
      rideId: widget.rideId,
      myRole: 'user',
      myUserId: uid,
    );

    _subHistory = _svc!.chatHistory.listen((batch) {
      if (!mounted) return;
      setState(() {
        _mergeIncoming(batch);
        _otherTyping = false;
      });
      _scrollToEnd();
    });

    _subMsg = _svc!.messages.listen((m) {
      if (!mounted) return;
      if (!_messageForThisRide(m)) return;
      setState(() {
        if (m.dbId != null && _items.any((x) => x.dbId == m.dbId)) return;
        if (m.dbId != null) _stripOptimisticEcho(m);
        _items.add(m);
        _items.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _otherTyping = false;
      });
      if (!_isMine(m)) _markReadSoon();
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

    _subJoined = _svc!.joined.listen((j) {
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
    return t.isEmpty || t == 'user' || t == 'rider';
  }

  static bool _sameCalendarDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _formatTime(DateTime t) {
    return DateFormat('HH:mm').format(t.toLocal());
  }

  String _dateLabel(DateTime day) {
    final local = DateTime(day.year, day.month, day.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (local == today) return 'Today';
    if (local == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('d MMMM y').format(local);
  }

  List<Widget> _buildChatListChildren(BuildContext context) {
    final out = <Widget>[];
    DateTime? lastDay;
    for (var i = 0; i < _items.length; i++) {
      final m = _items[i];
      final d = DateTime(m.timestamp.year, m.timestamp.month, m.timestamp.day);
      if (lastDay == null || d != lastDay) {
        out.add(_buildDateDivider(d));
        lastDay = d;
      }
      final mine = _isMine(m);
      final gPrev = i > 0 &&
          _isMine(_items[i - 1]) == mine &&
          _sameCalendarDay(_items[i - 1].timestamp, m.timestamp);
      final gNext = i < _items.length - 1 &&
          _isMine(_items[i + 1]) == mine &&
          _sameCalendarDay(_items[i + 1].timestamp, m.timestamp);
      out.add(_buildBubble(context, m, mine: mine, gPrev: gPrev, gNext: gNext));
    }
    if (_otherTyping) out.add(_buildTypingBubble(context));
    return out;
  }

  Widget _buildDateDivider(DateTime day) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFD1CDC7).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            _dateLabel(day),
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF54656F),
            ),
          ),
        ),
      ),
    );
  }

  BorderRadius _bubbleRadius(bool mine, bool gPrev, bool gNext) {
    const big = 9.0;
    const tight = 3.0;
    if (mine) {
      return BorderRadius.only(
        topLeft: const Radius.circular(big),
        topRight: Radius.circular(gPrev ? tight : big),
        bottomLeft: const Radius.circular(big),
        bottomRight: Radius.circular(gNext ? tight : big),
      );
    }
    return BorderRadius.only(
      topLeft: Radius.circular(gPrev ? tight : big),
      topRight: const Radius.circular(big),
      bottomLeft: Radius.circular(gNext ? tight : big),
      bottomRight: const Radius.circular(big),
    );
  }

  Widget _buildBubble(
    BuildContext context,
    RideChatMessage m, {
    required bool mine,
    required bool gPrev,
    required bool gNext,
  }) {
    final top = gPrev ? 2.0 : 10.0;
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.82,
          ),
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
          decoration: BoxDecoration(
            color: mine ? _waOutgoing : _waIncoming,
            borderRadius: _bubbleRadius(mine, gPrev, gNext),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                m.text,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.38,
                  color: _waText,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _formatTime(m.timestamp),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: _waMeta,
                    ),
                  ),
                  if (mine) ...[
                    const SizedBox(width: 4),
                    if (m.dbId == null)
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: _waMeta.withValues(alpha: 0.85),
                      )
                    else
                      Icon(
                        _joined ? Icons.done_all_rounded : Icons.done_rounded,
                        size: 15,
                        color: _joined ? const Color(0xFF53BDEB) : _waMeta,
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypingBubble(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, left: 4, bottom: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _waIncoming,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF8696A0)
                          .withValues(alpha: 0.45 + i * 0.2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Material(
      color: _waComposerBg,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _input,
                    minLines: 1,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                    style: GoogleFonts.inter(fontSize: 16, color: _waText),
                    decoration: InputDecoration(
                      hintText: 'Message',
                      hintStyle:
                          GoogleFonts.inter(color: _waMeta, fontSize: 16),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (_) {
                      _svc?.setTyping(true);
                      _typingDebounce?.cancel();
                      _typingDebounce = Timer(
                        const Duration(milliseconds: 600),
                        () => _svc?.setTyping(false),
                      );
                      setState(() {});
                    },
                    onSubmitted: (value) {
                      final t = value.trim();
                      if (t.isEmpty) return;
                      _input.clear();
                      _sendOutgoing(t);
                      setState(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: _input,
                builder: (context, v, _) {
                  final canSend = v.text.trim().isNotEmpty;
                  return Material(
                    color: canSend ? _waSend : const Color(0xFFBDBDBD),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: canSend
                          ? () {
                              final t = _input.text;
                              _input.clear();
                              _sendOutgoing(t);
                              setState(() {});
                            }
                          : null,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    _markReadDebounce?.cancel();
    _subMsg?.cancel();
    _subHistory?.cancel();
    _subErr?.cancel();
    _subTyping?.cancel();
    _subJoined?.cancel();
    _svc?.dispose();
    _input.dispose();
    _scroll.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.partnerName.trim();
    final initials = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _waBg,
        appBar: AppBar(
          backgroundColor: _waAppBar,
          elevation: 0,
          leading: FlutterFlowIconButton(
            borderRadius: 30,
            buttonSize: 48,
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.white24,
                radius: 20,
                child: Text(
                  initials,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.partnerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      _joined ? 'online now' : 'connecting...',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildConnectionBanner(),
            Expanded(
              child: _loadingHistory && _items.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: _waAppBar),
                    )
                  : RefreshIndicator(
                      color: _waAppBar,
                      onRefresh: _pullRefresh,
                      child: _items.isEmpty && !_loadingHistory
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              controller: _scroll,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 12),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.sizeOf(context).height * 0.42,
                                  child: Center(
                                    child: Text(
                                      'No messages yet.\nSay hi to ${widget.partnerName}!',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        color: _waMeta,
                                        height: 1.45,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              controller: _scroll,
                              keyboardDismissBehavior:
                                  ScrollViewKeyboardDismissBehavior.onDrag,
                              padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
                              children: _buildChatListChildren(context),
                            ),
                    ),
            ),
            _buildQuickReplies(),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplies() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
      color: _waComposerBg,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final q in _quickReplies) ...[
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(
                    q,
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                  onPressed: () => _sendOutgoing(q, messageType: 'quick_reply'),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionBanner() {
    if (_joined) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFD9B3),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: _waAppBar),
          ),
          const SizedBox(width: 8),
          Text(
            'Reconnecting to chat...',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6D3A00),
            ),
          ),
        ],
      ),
    );
  }
}
