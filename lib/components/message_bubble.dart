import 'package:flutter/material.dart';
import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String? headImagePath;

  const MessageBubble({
    super.key,
    required this.message,
    this.headImagePath,
  });

  int _calculateTokens(String text) {
    int chineseCharCount = 0;
    int otherCharCount = 0;

    for (int i = 0; i < text.length; i++) {
      int codeUnit = text.codeUnitAt(i);
      if (codeUnit >= 0x4E00 && codeUnit <= 0x9FFF) {
        chineseCharCount++;
      } else {
        otherCharCount++;
      }
    }

    return (chineseCharCount / 1.5).ceil() + otherCharCount;
  }

  @override
  Widget build(BuildContext context) {
    final tokenCount = _calculateTokens(message.content);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: message.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment:
                message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                if (headImagePath != null)
                  ClipOval(
                    child: Image.asset(
                      headImagePath!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 8, top: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
              ],
              Flexible(
                child: Container(
                  key: ValueKey('${message.timestamp.toIso8601String()}-${message.content.length}'),
                  constraints: BoxConstraints(
                    maxWidth: message.isUser
                        ? MediaQuery.of(context).size.width * 0.5
                        : double.infinity,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? const Color(0xFF007AFF)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SelectableText(
                    message.content,
                    style: TextStyle(
                      fontSize: 15,
                      color: message.isUser ? Colors.white : const Color(0xFF1A1A1A),
                      height: 1.5,
                    ),
                  ),
                ),
              ),
              if (message.isUser) ...[
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.grey,
                    size: 18,
                  ),
                ),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Token预估: $tokenCount',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
