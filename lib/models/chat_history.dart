import 'avatar_type.dart';

class ChatHistory {
  final String title;
  final String lastMessage;
  final String timestamp;
  final AvatarType avatarType;
  final String? counselorId;

  ChatHistory({
    required this.title,
    required this.lastMessage,
    required this.timestamp,
    required this.avatarType,
    this.counselorId,
  });
}
