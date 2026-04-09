import 'package:admindoorstep/chat/models/chat_message_item.dart';
import 'package:admindoorstep/chat/repositories/chat_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatDetailViewModel extends ChangeNotifier {
  ChatDetailViewModel({
    required this.conversationId,
    required this.userId,
    required this.supportUserId,
    ChatRepository? repository,
  }) : _repository = repository ?? ChatRepository();

  static const int pageSize = 10;

  final String conversationId;
  final String userId;
  final String supportUserId;
  final ChatRepository _repository;
  final List<ChatMessageItem> _messages = [];

  List<ChatMessageItem> get messages => List.unmodifiable(_messages);

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isSending = false;
  bool _hasMore = true;
  bool _bootstrapped = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isSending => _isSending;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  Future<void> bootstrap() async {
    if (_bootstrapped) {
      return;
    }

    _bootstrapped = true;
    try {
      await _repository.markSupportUnreadAsRead(conversationId);
    } on PostgrestException catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    }
    await loadInitial();
  }

  Future<void> loadInitial() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _hasMore = true;
    _messages.clear();
    notifyListeners();

    try {
      final items = await _repository.fetchMessagesPage(
        userId: userId,
        conversationId: conversationId,
        offset: 0,
        limit: pageSize,
      );
      _messages.addAll(items.reversed);
      _hasMore = items.length == pageSize;
    } catch (_) {
      _errorMessage = 'Unable to load messages right now.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) {
      return;
    }

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final items = await _repository.fetchMessagesPage(
        userId: userId,
        conversationId: conversationId,
        offset: _messages.length,
        limit: pageSize,
      );
      _messages.insertAll(0, items.reversed);
      _hasMore = items.length == pageSize;
    } catch (_) {
      _errorMessage = 'Unable to load older messages.';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String text) async {
    if (_isSending) {
      return false;
    }

    final message = text.trim();
    if (message.isEmpty) {
      return false;
    }

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final inserted = await _repository.sendSupportMessage(
        conversationId: conversationId,
        userId: userId,
        supportUserId: supportUserId,
        message: message,
      );
      _messages.add(inserted);
      return true;
    } on PostgrestException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }
}
