/// ============================================================================
/// MESSAGING PROVIDERS - Riverpod State Management
/// ============================================================================
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/messaging_models.dart';
import '../../data/repositories/messaging_repository.dart';

// ============================================================================
// REPOSITORY PROVIDER
// ============================================================================

final messagingRepositoryProvider = Provider<MessagingRepository>((ref) {
  return MessagingRepository();
});

// ============================================================================
// CONVERSATIONS STATE
// ============================================================================

class ConversationsState {
  final bool isLoading;
  final List<ConversationModel> conversations;
  final int totalUnreadCount;
  final String? errorMessage;

  const ConversationsState({
    this.isLoading = false,
    this.conversations = const [],
    this.totalUnreadCount = 0,
    this.errorMessage,
  });

  ConversationsState copyWith({
    bool? isLoading,
    List<ConversationModel>? conversations,
    int? totalUnreadCount,
    String? errorMessage,
  }) {
    return ConversationsState(
      isLoading: isLoading ?? this.isLoading,
      conversations: conversations ?? this.conversations,
      totalUnreadCount: totalUnreadCount ?? this.totalUnreadCount,
      errorMessage: errorMessage,
    );
  }

  List<ConversationModel> get pinnedConversations =>
      conversations.where((c) => c.isPinned).toList();

  List<ConversationModel> get regularConversations =>
      conversations.where((c) => !c.isPinned && !c.isArchived).toList();

  List<ConversationModel> get archivedConversations =>
      conversations.where((c) => c.isArchived).toList();
}

class ConversationsNotifier extends Notifier<ConversationsState> {
  late final MessagingRepository _repository;
  RealtimeChannel? _channel;

  @override
  ConversationsState build() {
    _repository = ref.watch(messagingRepositoryProvider);
    
    // Auto-load and subscribe
    Future.microtask(() {
      loadConversations();
      _subscribeToUpdates();
    });

    // Cleanup on dispose
    ref.onDispose(() {
      if (_channel != null) {
        _repository.unsubscribe(_channel!);
      }
    });

    return const ConversationsState(isLoading: true);
  }

  void _subscribeToUpdates() {
    try {
      _channel = _repository.subscribeToConversations(
        onUpdate: () => loadConversations(),
      );
    } catch (e) {
      // Ignore subscription errors
    }
  }

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: state.conversations.isEmpty, errorMessage: null);

    try {
      final conversations = await _repository.getConversations();
      final unreadCount = await _repository.getTotalUnreadCount();

      state = state.copyWith(
        isLoading: false,
        conversations: conversations,
        totalUnreadCount: unreadCount,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load conversations: ${e.toString()}',
      );
    }
  }

  Future<String?> startConversation(String otherUserId) async {
    try {
      final conversationId = await _repository.getOrCreateConversation(otherUserId);
      await loadConversations();
      return conversationId;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().contains('Cannot message')
            ? 'Cannot message this user'
            : 'Failed to start conversation',
      );
      return null;
    }
  }

  Future<bool> deleteConversation(String conversationId) async {
    try {
      final success = await _repository.deleteConversation(conversationId);
      if (success) {
        await loadConversations();
      }
      return success;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete conversation');
      return false;
    }
  }

  Future<bool> updateSettings({
    required String conversationId,
    bool? muted,
    bool? archived,
    bool? pinned,
    int? disappearingHours,
  }) async {
    try {
      final success = await _repository.updateConversationSettings(
        conversationId: conversationId,
        muted: muted,
        archived: archived,
        pinned: pinned,
        disappearingHours: disappearingHours,
      );

      if (success) {
        await loadConversations();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final conversationsProvider =
    NotifierProvider<ConversationsNotifier, ConversationsState>(() {
  return ConversationsNotifier();
});

// ============================================================================
// CHAT STATE (Single conversation messages)
// ============================================================================

class ChatState {
  final bool isLoading;
  final bool isSending;
  final String? conversationId;
  final ConversationModel? conversation;
  final List<MessageModel> messages;
  final String? errorMessage;
  final bool hasMore;

  const ChatState({
    this.isLoading = false,
    this.isSending = false,
    this.conversationId,
    this.conversation,
    this.messages = const [],
    this.errorMessage,
    this.hasMore = true,
  });

  ChatState copyWith({
    bool? isLoading,
    bool? isSending,
    String? conversationId,
    ConversationModel? conversation,
    List<MessageModel>? messages,
    String? errorMessage,
    bool? hasMore,
  }) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      conversationId: conversationId ?? this.conversationId,
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  late final MessagingRepository _repository;
  RealtimeChannel? _channel;

  @override
  ChatState build() {
    _repository = ref.watch(messagingRepositoryProvider);

    ref.onDispose(() {
      if (_channel != null) {
        _repository.unsubscribe(_channel!);
      }
    });

    return const ChatState();
  }

  Future<void> loadChat(String conversationId) async {
    // Unsubscribe from previous channel
    if (_channel != null) {
      await _repository.unsubscribe(_channel!);
      _channel = null;
    }

    state = state.copyWith(
      isLoading: true,
      conversationId: conversationId,
      messages: [],
      errorMessage: null,
    );

    try {
      // Load conversation and messages
      final conversation = await _repository.getConversation(conversationId);
      final messages = await _repository.getMessages(conversationId);

      // Mark as read
      await _repository.markMessagesRead(conversationId);

      state = state.copyWith(
        isLoading: false,
        conversation: conversation,
        messages: messages,
        hasMore: messages.length >= 50,
      );

      // Subscribe to new messages
      _subscribeToMessages(conversationId);

      // Refresh conversations list to update unread count
      ref.read(conversationsProvider.notifier).loadConversations();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load chat: ${e.toString()}',
      );
    }
  }

  void _subscribeToMessages(String conversationId) {
    _channel = _repository.subscribeToMessages(
      conversationId: conversationId,
      onNewMessage: (message) {
        // Add new message to the list
        final updatedMessages = [message, ...state.messages];
        state = state.copyWith(messages: updatedMessages);

        // Mark as read if from other user
        if (message.senderId != _repository.currentUserId) {
          _repository.markMessagesRead(conversationId);
        }
      },
      onMessageUpdate: (message) {
        // Update existing message
        final updatedMessages = state.messages.map((m) {
          return m.id == message.id ? message : m;
        }).toList();
        state = state.copyWith(messages: updatedMessages);
      },
    );
  }

  Future<void> loadMoreMessages() async {
    if (!state.hasMore || state.isLoading || state.conversationId == null) return;

    final oldestMessage = state.messages.isNotEmpty ? state.messages.last : null;

    try {
      final moreMessages = await _repository.getMessages(
        state.conversationId!,
        before: oldestMessage?.createdAt,
      );

      state = state.copyWith(
        messages: [...state.messages, ...moreMessages],
        hasMore: moreMessages.length >= 50,
      );
    } catch (e) {
      // Ignore pagination errors
    }
  }

  Future<bool> sendMessage(String content) async {
    if (state.conversationId == null || content.trim().isEmpty) return false;

    state = state.copyWith(isSending: true);

    try {
      await _repository.sendMessage(
        conversationId: state.conversationId!,
        content: content.trim(),
      );

      state = state.copyWith(isSending: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        errorMessage: 'Failed to send message',
      );
      return false;
    }
  }

  Future<bool> sendAudioMessage({
    required String fileUrl,
    required int durationSeconds,
    String? fileName,
    int? fileSize,
  }) async {
    if (state.conversationId == null) return false;

    state = state.copyWith(isSending: true);

    try {
      await _repository.sendAudioMessage(
        conversationId: state.conversationId!,
        fileUrl: fileUrl,
        durationSeconds: durationSeconds,
        fileName: fileName,
        fileSize: fileSize,
      );

      state = state.copyWith(isSending: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        errorMessage: 'Failed to send audio message',
      );
      return false;
    }
  }

  Future<bool> sendImageMessage({
    required String fileUrl,
    String? fileName,
    int? fileSize,
  }) async {
    if (state.conversationId == null) return false;

    state = state.copyWith(isSending: true);

    try {
      await _repository.sendImageMessage(
        conversationId: state.conversationId!,
        fileUrl: fileUrl,
        fileName: fileName,
        fileSize: fileSize,
      );

      state = state.copyWith(isSending: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isSending: false,
        errorMessage: 'Failed to send image',
      );
      return false;
    }
  }

  Future<bool> saveAudioMessage(String messageId) async {
    try {
      final success = await _repository.saveAudioMessage(messageId);
      if (success) {
        // Update message in state
        final updatedMessages = state.messages.map((m) {
          if (m.id == messageId) {
            return m.copyWith(
              savedBy: _repository.currentUserId,
              savedAt: DateTime.now(),
            );
          }
          return m;
        }).toList();
        state = state.copyWith(messages: updatedMessages);
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().contains('does not allow')
            ? 'User does not allow saving audio messages'
            : 'Failed to save audio message',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void clear() {
    if (_channel != null) {
      _repository.unsubscribe(_channel!);
      _channel = null;
    }
    state = const ChatState();
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(() {
  return ChatNotifier();
});

// ============================================================================
// BLOCKED USERS STATE
// ============================================================================

class BlockedUsersState {
  final bool isLoading;
  final List<BlockedUserModel> blockedUsers;
  final String? errorMessage;

  const BlockedUsersState({
    this.isLoading = false,
    this.blockedUsers = const [],
    this.errorMessage,
  });

  BlockedUsersState copyWith({
    bool? isLoading,
    List<BlockedUserModel>? blockedUsers,
    String? errorMessage,
  }) {
    return BlockedUsersState(
      isLoading: isLoading ?? this.isLoading,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      errorMessage: errorMessage,
    );
  }
}

class BlockedUsersNotifier extends Notifier<BlockedUsersState> {
  late final MessagingRepository _repository;

  @override
  BlockedUsersState build() {
    _repository = ref.watch(messagingRepositoryProvider);
    return const BlockedUsersState();
  }

  Future<void> loadBlockedUsers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final blocked = await _repository.getBlockedUsers();
      state = state.copyWith(isLoading: false, blockedUsers: blocked);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load blocked users',
      );
    }
  }

  Future<bool> blockUser(String userId, {String? reason}) async {
    try {
      final success = await _repository.blockUser(userId, reason: reason);
      if (success) {
        await loadBlockedUsers();
        // Refresh conversations
        ref.read(conversationsProvider.notifier).loadConversations();
      }
      return success;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to block user');
      return false;
    }
  }

  Future<bool> unblockUser(String userId) async {
    try {
      final success = await _repository.unblockUser(userId);
      if (success) {
        await loadBlockedUsers();
        ref.read(conversationsProvider.notifier).loadConversations();
      }
      return success;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to unblock user');
      return false;
    }
  }

  Future<String?> reportUser({
    required String userId,
    required String reason,
    String? description,
    String? messageId,
  }) async {
    try {
      final reportId = await _repository.reportUser(
        userId: userId,
        reason: reason,
        description: description,
        messageId: messageId,
      );
      return reportId;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to submit report');
      return null;
    }
  }
}

final blockedUsersProvider =
    NotifierProvider<BlockedUsersNotifier, BlockedUsersState>(() {
  return BlockedUsersNotifier();
});

// ============================================================================
// MESSAGING PREFERENCES STATE
// ============================================================================

class MessagingPrefsState {
  final bool isLoading;
  final MessagingPreferencesModel? preferences;
  final String? errorMessage;

  const MessagingPrefsState({
    this.isLoading = false,
    this.preferences,
    this.errorMessage,
  });

  MessagingPrefsState copyWith({
    bool? isLoading,
    MessagingPreferencesModel? preferences,
    String? errorMessage,
  }) {
    return MessagingPrefsState(
      isLoading: isLoading ?? this.isLoading,
      preferences: preferences ?? this.preferences,
      errorMessage: errorMessage,
    );
  }
}

class MessagingPrefsNotifier extends Notifier<MessagingPrefsState> {
  late final MessagingRepository _repository;

  @override
  MessagingPrefsState build() {
    _repository = ref.watch(messagingRepositoryProvider);
    Future.microtask(() => loadPreferences());
    return const MessagingPrefsState(isLoading: true);
  }

  Future<void> loadPreferences() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final prefs = await _repository.getMessagingPreferences();
      state = state.copyWith(isLoading: false, preferences: prefs);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load preferences',
      );
    }
  }

  Future<bool> updatePreferences(MessagingPreferencesModel prefs) async {
    try {
      final success = await _repository.updateMessagingPreferences(prefs);
      if (success) {
        state = state.copyWith(preferences: prefs);
      }
      return success;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update preferences');
      return false;
    }
  }

  Future<bool> setAllowAudioSave(bool allow) async {
    if (state.preferences == null) return false;
    
    final updatedPrefs = state.preferences!.copyWith(allowAudioSave: allow);
    return updatePreferences(updatedPrefs);
  }

  Future<bool> setDefaultDisappearingHours(int? hours) async {
    if (state.preferences == null) return false;
    
    final updatedPrefs = state.preferences!.copyWith(defaultDisappearingHours: hours);
    return updatePreferences(updatedPrefs);
  }

  Future<bool> setReadReceipts(bool enabled) async {
    if (state.preferences == null) return false;
    
    final updatedPrefs = state.preferences!.copyWith(readReceiptsEnabled: enabled);
    return updatePreferences(updatedPrefs);
  }

  Future<bool> setNotifications(bool enabled) async {
    if (state.preferences == null) return false;
    
    final updatedPrefs = state.preferences!.copyWith(messageNotifications: enabled);
    return updatePreferences(updatedPrefs);
  }
}

final messagingPrefsProvider =
    NotifierProvider<MessagingPrefsNotifier, MessagingPrefsState>(() {
  return MessagingPrefsNotifier();
});
