import 'package:admindoorstep/chat/models/conversation_summary.dart';
import 'package:admindoorstep/chat/repositories/chat_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupportInboxViewModel extends ChangeNotifier {
  SupportInboxViewModel({ChatRepository? repository})
      : _repository = repository ?? ChatRepository();

  static const int pageSize = 10;

  final ChatRepository _repository;
  final List<ConversationSummary> _conversations = [];

  List<ConversationSummary> get conversations => List.unmodifiable(_conversations);

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;

  Future<void> loadInitial() async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _hasMore = true;
    _conversations.clear();
    notifyListeners();

    try {
      final items = await _repository.fetchInboxPage(offset: 0, limit: pageSize);
      _conversations.addAll(items);
      _hasMore = items.length == pageSize;
    } on PostgrestException catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
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
      final items = await _repository.fetchInboxPage(
        offset: _conversations.length,
        limit: pageSize,
      );
      _conversations.addAll(items);
      _hasMore = items.length == pageSize;
    } on PostgrestException catch (error) {
      _errorMessage = error.message;
    } catch (error) {
      _errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> markConversationRead(ConversationSummary conversation) async {
    final index = _conversations.indexWhere(
      (item) => item.conversationId == conversation.conversationId,
    );
    if (index == -1) {
      return true;
    }

    final existing = _conversations[index];
    _conversations.removeAt(index);
    notifyListeners();

    try {
      await _repository.markSupportUnreadAsRead(conversation.conversationId);
      return true;
    } catch (error) {
      _conversations.insert(index, existing);
      _errorMessage = error is PostgrestException
          ? error.message
          : 'Unable to mark conversation as read.';
      notifyListeners();
      return false;
    }
  }
}
