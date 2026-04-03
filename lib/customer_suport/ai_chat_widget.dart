import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  ChatMessage(
      {required this.text, required this.isUser, required this.timestamp});
}

class _AiChatWidgetState extends State<AiChatWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _aiLoading = false;

  List<ChatMessage> messages = [
    ChatMessage(
      text:
          "Hi! I'm UGO AI. Each reply uses a fresh snapshot of your rides, wallet, and notifications from our servers—ask about trips, balance, or your current ride.",
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _aiLoading) return;

    final token = FFAppState().accessToken;
    if (token.isEmpty || FFAppState().userid == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to use UGO AI.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      messages.add(ChatMessage(
        text: trimmed,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _aiLoading = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final res = await AiAgentChatCall.call(
        message: trimmed,
        token: token,
      );
      if (!mounted) return;

      String reply;
      if (res.succeeded) {
        reply = AiAgentChatCall.replyText(res.jsonBody)?.trim() ?? '';
        if (reply.isEmpty) {
          reply =
              'I could not read the AI response. Please try again in a moment.';
        }
      } else {
        final err = getJsonField(res.jsonBody, r'$.message')?.toString();
        reply = (err != null && err.isNotEmpty)
            ? err
            : 'Something went wrong. Please try again.';
      }

      setState(() {
        messages.add(ChatMessage(
          text: reply,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _aiLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        messages.add(ChatMessage(
          text: 'Network error. Check your connection and try again.',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _aiLoading = false;
      });
    }
    _scrollToBottom();
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
        backgroundColor: theme.primaryBackground,
        appBar: AppBar(
          backgroundColor: theme.primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 30.0,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'UGO AI (live data)',
            style: GoogleFonts.interTight(
              color: Colors.white,
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
          elevation: 2.0,
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: messages.length + (_aiLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_aiLoading && index == messages.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: theme.primary,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'UGO AI is checking your account…',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: theme.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final msg = messages[index];
                  return _buildMessageBubble(msg, theme, isDark);
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

  Widget _buildMessageBubble(
      ChatMessage message, FlutterFlowTheme theme, bool isDark) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? theme.primary
              : (isDark ? theme.secondaryBackground : const Color(0xFFE8F0FF)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16.0),
            topRight: const Radius.circular(16.0),
            bottomLeft: Radius.circular(message.isUser ? 16.0 : 0.0),
            bottomRight: Radius.circular(message.isUser ? 0.0 : 16.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: GoogleFonts.inter(
                color: message.isUser ? Colors.white : theme.primaryText,
                fontSize: 15.0,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              "${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')} ${message.timestamp.hour >= 12 ? 'PM' : 'AM'}",
              style: GoogleFonts.inter(
                color: message.isUser ? Colors.white70 : theme.secondaryText,
                fontSize: 10.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplies(FlutterFlowTheme theme) {
    final replies = [
      "Where is my driver?",
      "Payment issue",
      "Cancel my ride",
    ];

    return Container(
      height: 50.0,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: replies.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              backgroundColor: theme.primaryBackground,
              side: BorderSide(color: theme.primary.withOpacity(0.5)),
              label: Text(
                replies[index],
                style: GoogleFonts.inter(color: theme.primary, fontSize: 13.0),
              ),
              onPressed: () => _sendMessage(replies[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInput(FlutterFlowTheme theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16.0,
        right: 16.0,
        top: 12.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12.0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: TextField(
                controller: _textController,
                style: theme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle:
                      theme.bodyMedium.copyWith(color: theme.secondaryText),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Container(
            decoration: BoxDecoration(
              color: theme.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: _aiLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white),
              onPressed:
                  _aiLoading ? null : () => _sendMessage(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}
