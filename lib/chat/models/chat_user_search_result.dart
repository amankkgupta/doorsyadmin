class ChatUserSearchResult {
  const ChatUserSearchResult({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.conversationId,
  });

  final String userId;
  final String userName;
  final String userEmail;
  final String? conversationId;
}

