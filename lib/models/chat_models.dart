class ChatMessage {
  String content;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatHistory {
  final String title;
  final String lastMessage;
  final String timestamp;
  final AvatarType avatarType;

  ChatHistory({
    required this.title,
    required this.lastMessage,
    required this.timestamp,
    required this.avatarType,
  });
}

enum AvatarType {
  ai,
  user,
}
