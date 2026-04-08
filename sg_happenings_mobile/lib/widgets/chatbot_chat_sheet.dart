import 'package:flutter/material.dart';

import '../api/app_api.dart';
import '../api/llm_chat_repository.dart';

/// Opens the LLM chat panel (call from the floating chatbot button).
Future<void> openChatbotSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const _ChatbotChatSheet(),
  );
}

class _ChatMessage {
  const _ChatMessage({required this.isUser, required this.text});

  final bool isUser;
  final String text;
}

class _ChatbotChatSheet extends StatefulWidget {
  const _ChatbotChatSheet();

  @override
  State<_ChatbotChatSheet> createState() => _ChatbotChatSheetState();
}

class _ChatbotChatSheetState extends State<_ChatbotChatSheet> {
  final _scroll = ScrollController();
  final _input = TextEditingController();
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      isUser: false,
      text: 'Hi! I can help with SG Happenings — events, locations, and tips. What would you like to know?',
    ),
  ];
  bool _sending = false;

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  List<LlmChatTurn> _turnsForApi() {
    final start = _messages.indexWhere((m) => m.isUser);
    if (start < 0) return [];
    return _messages
        .sublist(start)
        .map(
          (m) => LlmChatTurn(
            role: m.isUser ? 'user' : 'assistant',
            content: m.text,
          ),
        )
        .toList();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _messages.add(_ChatMessage(isUser: true, text: text));
      _input.clear();
      _sending = true;
    });
    _scrollToEnd();

    try {
      final reply = await llmChatRepository.sendChat(_turnsForApi());
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(isUser: false, text: reply));
        _sending = false;
      });
    } on LlmChatException catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            isUser: false,
            text: 'Sorry, something went wrong.\n${e.message}',
          ),
        );
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(isUser: false, text: 'Sorry, an unexpected error occurred.'),
        );
        _sending = false;
      });
    }
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _clearChat() {
    setState(() {
      _messages
        ..clear()
        ..add(
          const _ChatMessage(
            isUser: false,
            text: 'Chat cleared. How can I help?',
          ),
        );
    });
    _scrollToEnd();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: const Color(0xFFF7EEDC),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxH, minHeight: 320),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.brown.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                  child: Row(
                    children: [
                      Icon(Icons.smart_toy_outlined, color: Colors.brown.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Assistant',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.brown.shade900,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _clearChat,
                        child: const Text('Clear'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.brown.withValues(alpha: 0.15)),
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, i) {
                      final m = _messages[i];
                      return _Bubble(message: m);
                    },
                  ),
                ),
                if (_sending)
                  const LinearProgressIndicator(
                    minHeight: 2,
                    color: Color(0xFFFF6B35),
                    backgroundColor: Color(0x33FF6B35),
                  ),
                Container(
                  color: const Color(0xFFF0E8DC),
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _input,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          decoration: InputDecoration(
                            hintText: 'Message…',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFFF6B35) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SelectableText(
          message.text,
          style: TextStyle(
            fontSize: 15,
            height: 1.35,
            color: isUser ? Colors.white : const Color(0xFF3E2723),
          ),
        ),
      ),
    );
  }
}
