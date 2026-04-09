class ChatMessageItem {
  const ChatMessageItem({
    required this.messageId,
    required this.message,
    required this.senderId,
    required this.userId,
    required this.conversationId,
    required this.createdAt,
  });

  final String messageId;
  final String message;
  final String senderId;
  final String userId;
  final String conversationId;
  final DateTime? createdAt;

  factory ChatMessageItem.fromMap(Map<String, dynamic> map) {
    return ChatMessageItem(
      messageId: (map['message_id'] ?? '').toString(),
      message: (map['message'] ?? '').toString(),
      senderId: (map['sender_id'] ?? '').toString(),
      userId: (map['user_id'] ?? '').toString(),
      conversationId: (map['conversation_id'] ?? '').toString(),
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()),
    );
  }
}
