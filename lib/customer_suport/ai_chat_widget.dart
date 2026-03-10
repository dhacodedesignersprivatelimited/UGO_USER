import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../backend/ai_support_service.dart';
import '../backend/api_requests/api_calls.dart';

class AiChatWidget extends StatefulWidget {
  const AiChatWidget({super.key});

  static String routeName = 'AiChat';
  static String routePath = '/aiChat';

  @override
  State<AiChatWidget> createState() => _AiChatWidgetState();
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isUser, required this.timestamp});
}

class _AiChatWidgetState extends State<AiChatWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> messages = [
    ChatMessage(
      text: "Hi! I'm your UGO Assistant. I'm reviewing your account now. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  bool _isTyping = false;
  final AiSupportService _aiService = AiSupportService();
  List<String> _quickReplies = ["Where is my driver?", "Payment issue", "Refund status"];

  // Contextual Data for AI
  String? _lastRideId;

  @override
  void initState() {
    super.initState();
    _loadDynamicReplies();
  }

  Future<void> _loadDynamicReplies() async {
    final appState = FFAppState();
    try {
      final response = await GetRideHistoryCall.call(
        userId: appState.userid,
        token: appState.accessToken,
      );
      if (response.succeeded) {
        final rides = GetRideHistoryCall.rides(response.jsonBody);
        if (rides != null && rides.isNotEmpty) {
          final lastRide = rides.first;
          _lastRideId = lastRide['ride_id'].toString(); // Save for AI context
          setState(() {
            _quickReplies = [
              "Help with my last ride",
              "Where is my receipt?",
              "I lost an item",
            ];
          });
        }
      }
    } catch (_) {}
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = text.trim();
    setState(() {
      messages.add(ChatMessage(text: userMsg, isUser: true, timestamp: DateTime.now()));
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();

    // --- BEST WAY TO USE AI: CONTEXT INJECTION ---
    // Instead of just sending the user text, append hidden system context.
    // Example: "User asked: [userMsg]. Context: Last ride ID is [_lastRideId]"
    final enrichedPrompt = _lastRideId != null
        ? "Context: User's last ride ID is $_lastRideId. User says: $userMsg"
        : userMsg;

    // Call Real AI Service
    final aiResponse = await _aiService.generateResponse(enrichedPrompt);

    if (mounted) {
      setState(() {
        _isTyping = false;
        messages.add(ChatMessage(text: aiResponse, isUser: false, timestamp: DateTime.now()));
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 50,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: isDark ? theme.primaryBackground : const Color(0xFFF4F6F9), // Slight tint for contrast
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.primary, const Color(0xFFFF9F4D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'UGO AI Support',
                style: GoogleFonts.interTight(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          centerTitle: true,
          elevation: 4.0,
          shadowColor: theme.primary.withOpacity(0.3),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                itemCount: messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length) return _buildTypingIndicator(theme, isDark);
                  return _buildMessageBubble(messages[index], theme, isDark);
                },
              ),
            ),
            _buildQuickReplies(theme),
            _buildMessageInput(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(FlutterFlowTheme theme, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: isDark ? theme.secondaryBackground : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20.0), topRight: Radius.circular(20.0),
            bottomRight: Radius.circular(20.0), bottomLeft: Radius.circular(4.0),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: theme.primary),
            ),
            const SizedBox(width: 12),
            Text(
              'UGO AI is typing...',
              style: GoogleFonts.inter(color: theme.secondaryText, fontSize: 13.0, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, FlutterFlowTheme theme, bool isDark) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: message.isUser ? theme.primary : (isDark ? theme.secondaryBackground : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20.0),
            topRight: const Radius.circular(20.0),
            bottomLeft: Radius.circular(message.isUser ? 20.0 : 4.0), // Sharp corner indicates speaker
            bottomRight: Radius.circular(message.isUser ? 4.0 : 20.0),
          ),
          boxShadow: [
            if (!message.isUser) // Only shadow AI messages for depth
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: GoogleFonts.inter(
                color: message.isUser ? Colors.white : theme.primaryText,
                fontSize: 15.0,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 6.0),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')} ${message.timestamp.hour >= 12 ? 'PM' : 'AM'}",
                style: GoogleFonts.inter(
                  color: message.isUser ? Colors.white.withOpacity(0.7) : theme.secondaryText,
                  fontSize: 10.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplies(FlutterFlowTheme theme) {
    return Container(
      height: 44.0,
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _quickReplies.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              backgroundColor: theme.primaryBackground,
              elevation: 0,
              pressElevation: 2,
              side: BorderSide(color: theme.primary.withOpacity(0.3), width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
              label: Text(
                _quickReplies[index],
                style: GoogleFonts.inter(color: theme.primary, fontSize: 13.0, fontWeight: FontWeight.w600),
              ),
              onPressed: () => _sendMessage(_quickReplies[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInput(FlutterFlowTheme theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 24.0),
      decoration: BoxDecoration(
        color: isDark ? theme.primaryBackground : const Color(0xFFF4F6F9),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
                borderRadius: BorderRadius.circular(30.0),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2)),
                ],
              ),
              child: TextField(
                controller: _textController,
                style: theme.bodyLarge,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: theme.bodyMedium.copyWith(color: theme.secondaryText),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          InkWell(
            onTap: () => _sendMessage(_textController.text),
            child: Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [theme.primary, const Color(0xFFFF9F4D)]),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: theme.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}