import 'package:flutter/material.dart';

/// Small floating chatbot control in the bottom-right of the parent [Stack].
class ChatbotCornerButton extends StatelessWidget {
  const ChatbotCornerButton({super.key});

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      right: 12,
      bottom: 12 + bottom,
      child: Material(
        elevation: 6,
        shadowColor: Colors.black26,
        shape: const CircleBorder(),
        color: Colors.white,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _openPlaceholder(context),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(
              Icons.smart_toy_outlined,
              color: Colors.brown.shade800,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  void _openPlaceholder(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: const Color(0xFFF7EEDC),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.smart_toy_outlined, size: 44, color: Colors.brown.shade800),
                const SizedBox(height: 12),
                Text(
                  'Assistant',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.brown.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Chat support will connect here. Replace this sheet with your chatbot UI or webview.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800, height: 1.35),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
