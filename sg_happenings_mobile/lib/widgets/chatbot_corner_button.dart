import 'package:flutter/material.dart';

import 'chatbot_chat_sheet.dart';

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
          onTap: () => openChatbotSheet(context),
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
}
