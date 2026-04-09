import 'package:admindoorstep/chat/models/chat_message_item.dart';
import 'package:admindoorstep/chat/models/conversation_summary.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRepository {
  ChatRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<ConversationSummary>> fetchInboxPage({
    required int offset,
    required int limit,
  }) async {
    final rows = await _fetchConversationRows(
      offset: offset,
      limit: limit,
    );

    final conversations = List<Map<String, dynamic>>.from(rows);
    final userIds = conversations
        .map((row) => (row['user_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final messageIds = conversations
        .map((row) => (row['message_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final userMap = await _fetchUsers(userIds);
    final messageMap = await _fetchMessagesByIds(messageIds);

    return conversations.map((row) {
      final userId = (row['user_id'] ?? '').toString();
      final user = userMap[userId] ?? const <String, dynamic>{};
      final messageId = (row['message_id'] ?? '').toString();
      final message = messageMap[messageId] ?? const <String, dynamic>{};

      return ConversationSummary(
        conversationId: (row['conversation_id'] ?? '').toString(),
        userId: userId,
        messageId: messageId,
        supportUnread: int.tryParse((row['support_unread'] ?? 0).toString()) ?? 0,
        modifiedAt: DateTime.tryParse((row['modified_at'] ?? '').toString()),
        userName: _pickUserName(user, userId),
        userEmail: (user['email'] ?? '').toString(),
        userPhone: (user['phone'] ?? user['mobile'] ?? '').toString(),
        latestMessagePreview: (message['message'] ?? '').toString(),
      );
    }).toList();
  }

  Future<List<dynamic>> _fetchConversationRows({
    required int offset,
    required int limit,
  }) async {
    try {
      return await _client
          .from('conversations')
          .select(
            'conversation_id, user_id, message_id, support_unread, modified_at',
          )
          .order('modified_at', ascending: false)
          .range(offset, offset + limit - 1);
    } on PostgrestException {
      rethrow;
    } catch (_) {
      throw Exception('Unable to fetch conversations.');
    }
  }

  Future<void> markSupportUnreadAsRead(String conversationId) async {
    if (conversationId.isEmpty) {
      return;
    }

    try {
      await _client
          .from('conversations')
          .update({'support_unread': 0})
          .eq('conversation_id', conversationId);
    } on PostgrestException {
      rethrow;
    } catch (_) {
      throw Exception('Unable to update support unread count.');
    }
  }

  Future<List<ChatMessageItem>> fetchMessagesPage({
    required String userId,
    required String conversationId,
    required int offset,
    required int limit,
  }) async {
    final baseQuery = _client
        .from('chats')
        .select('message_id, message, sender_id, conversation_id, created_at');

    final filteredQuery = baseQuery.eq('conversation_id', conversationId);

    final response = await filteredQuery
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response)
        .map(ChatMessageItem.fromMap)
        .toList();
  }

  Future<ChatMessageItem> sendSupportMessage({
    required String conversationId,
    required String userId,
    required String supportUserId,
    required String message,
  }) async {
    try {
      final inserted = await _client
          .from('chats')
          .insert({
            'conversation_id': conversationId,
            'sender_id': supportUserId,
            'message': message,
          })
          .select('message_id, message, sender_id, conversation_id, created_at')
          .single();

      final insertedMessage = ChatMessageItem.fromMap(inserted);

      try {
        final conversation = await _client
            .from('conversations')
            .select('user_unread')
            .eq('conversation_id', conversationId)
            .maybeSingle();

        final currentUserUnread =
            int.tryParse((conversation?['user_unread'] ?? 0).toString()) ?? 0;

        await _client
            .from('conversations')
            .update({
              'message_id': insertedMessage.messageId,
              'modified_at': DateTime.now().toIso8601String(),
              'user_unread': currentUserUnread + 1,
              'support_unread': 0,
            })
            .eq('conversation_id', conversationId);
      } on PostgrestException {
        rethrow;
      } catch (_) {
        throw Exception('Unable to update conversation after sending message.');
      }

      return insertedMessage;
    } on PostgrestException {
      rethrow;
    } catch (_) {
      throw Exception('Unable to send support message.');
    }
  }

  Future<Map<String, Map<String, dynamic>>> _fetchUsers(List<String> userIds) async {
    if (userIds.isEmpty) {
      return const {};
    }

    try {
      final rows = await _client
          .from('users')
          .select('*')
          .inFilter('user_id', userIds);

      return {
        for (final row in List<Map<String, dynamic>>.from(rows))
          (row['user_id'] ?? '').toString(): row,
      };
    } catch (_) {
      return const {};
    }
  }

  Future<Map<String, Map<String, dynamic>>> _fetchMessagesByIds(
    List<String> messageIds,
  ) async {
    if (messageIds.isEmpty) {
      return const {};
    }

    try {
      final rows = await _client
          .from('chats')
          .select('message_id, message')
          .inFilter('message_id', messageIds);

      return {
        for (final row in List<Map<String, dynamic>>.from(rows))
          (row['message_id'] ?? '').toString(): row,
      };
    } catch (_) {
      return const {};
    }
  }

  String _pickUserName(Map<String, dynamic> user, String fallbackUserId) {
    final candidates = [
      user['name'],
      user['full_name'],
      user['username'],
      user['email'],
      fallbackUserId,
    ];

    for (final value in candidates) {
      final text = (value ?? '').toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }

    return 'Unknown User';
  }
}
