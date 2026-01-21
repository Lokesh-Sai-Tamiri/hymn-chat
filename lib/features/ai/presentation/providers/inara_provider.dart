/// ============================================================================
/// INARA AI PROVIDERS - Riverpod State Management
/// ============================================================================
library;

import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/models/chat_session_model.dart';
import '../../data/repositories/inara_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// ============================================================================
// REPOSITORY PROVIDER
// ============================================================================

final inaraRepositoryProvider = Provider<InaraRepository>((ref) {
  final repo = InaraRepository();
  ref.onDispose(() => repo.dispose());
  return repo;
});

// ============================================================================
// CHAT STATE MODEL
// ============================================================================

enum ChatStatus {
  initial,
  loading,
  loaded,
  sending,
  error,
}

class ChatState {
  final ChatStatus status;
  final String? sessionId;
  final List<ChatMessageModel> messages;
  final String? errorMessage;
  final bool isTyping;

  const ChatState({
    this.status = ChatStatus.initial,
    this.sessionId,
    this.messages = const [],
    this.errorMessage,
    this.isTyping = false,
  });

  ChatState copyWith({
    ChatStatus? status,
    String? sessionId,
    List<ChatMessageModel>? messages,
    String? errorMessage,
    bool? isTyping,
  }) {
    return ChatState(
      status: status ?? this.status,
      sessionId: sessionId ?? this.sessionId,
      messages: messages ?? this.messages,
      errorMessage: errorMessage,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  /// Check if this is a new chat (no session yet)
  bool get isNewChat => sessionId == null;
}

// ============================================================================
// CHAT NOTIFIER
// ============================================================================

class ChatNotifier extends Notifier<ChatState> {
  late final InaraRepository _repository;

  @override
  ChatState build() {
    _repository = ref.watch(inaraRepositoryProvider);
    return const ChatState();
  }

  /// Get current user ID from auth state
  String? get _currentUserId {
    final authState = ref.read(authStateProvider);
    return authState.user?.id;
  }

  /// Start a new chat (clears current state)
  void startNewChat() {
    state = const ChatState();
  }

  /// Load an existing session
  Future<void> loadSession(String sessionId) async {
    state = state.copyWith(status: ChatStatus.loading);

    final result = await _repository.getSession(sessionId);

    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        status: ChatStatus.loaded,
        sessionId: result.data!.sessionId,
        messages: result.data!.messages,
      );
    } else {
      state = state.copyWith(
        status: ChatStatus.error,
        errorMessage: result.error,
      );
    }
  }

  /// Send a text message
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message to UI immediately
    final userMessage = ChatMessageModel.userText(message);
    state = state.copyWith(
      status: ChatStatus.sending,
      messages: [...state.messages, userMessage],
      isTyping: true,
    );

    // Send to API
    final result = await _repository.sendMessage(
      message: message,
      sessionId: state.sessionId,
      userId: _currentUserId,
    );

    if (result.isSuccess && result.data != null) {
      // Add AI response
      state = state.copyWith(
        status: ChatStatus.loaded,
        messages: [...state.messages, result.data!],
        isTyping: false,
      );

      // If this was the first message, we need to get the session ID
      // The backend creates a session automatically if not provided
      if (state.sessionId == null) {
        // Fetch user sessions to get the latest session
        await _refreshSessionId();
      }
    } else {
      state = state.copyWith(
        status: ChatStatus.error,
        errorMessage: result.error,
        isTyping: false,
      );
    }
  }

  /// Send a message with an image (using bytes for web compatibility)
  Future<void> sendMessageWithImage(String message, Uint8List imageBytes, String fileName) async {
    // Add user image message to UI immediately
    final userImageMessage = ChatMessageModel.userImageBytes(imageBytes, fileName);

    state = state.copyWith(
      status: ChatStatus.sending,
      messages: [
        ...state.messages,
        userImageMessage,
      ],
      isTyping: true,
    );

    // Send to API
    final result = await _repository.sendMessageWithImage(
      message: message.isEmpty ? 'Please analyze this image.' : message,
      imageBytes: imageBytes,
      fileName: fileName,
      sessionId: state.sessionId,
      userId: _currentUserId,
    );

    if (result.isSuccess && result.data != null) {
      state = state.copyWith(
        status: ChatStatus.loaded,
        messages: [...state.messages, result.data!],
        isTyping: false,
      );

      if (state.sessionId == null) {
        await _refreshSessionId();
      }
    } else {
      state = state.copyWith(
        status: ChatStatus.error,
        errorMessage: result.error,
        isTyping: false,
      );
    }
  }

  /// Refresh to get the session ID after first message
  Future<void> _refreshSessionId() async {
    final userId = _currentUserId;
    if (userId == null) return;

    final sessionsResult = await _repository.getUserSessions(userId);
    if (sessionsResult.isSuccess && sessionsResult.data!.isNotEmpty) {
      // Get the most recent session
      final latestSession = sessionsResult.data!.first;
      state = state.copyWith(sessionId: latestSession.sessionId);
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// ============================================================================
// CHAT PROVIDER
// ============================================================================

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(() {
  return ChatNotifier();
});

// ============================================================================
// SESSIONS LIST STATE
// ============================================================================

class SessionsListState {
  final bool isLoading;
  final List<ChatSessionListItem> sessions;
  final String? errorMessage;

  const SessionsListState({
    this.isLoading = false,
    this.sessions = const [],
    this.errorMessage,
  });

  SessionsListState copyWith({
    bool? isLoading,
    List<ChatSessionListItem>? sessions,
    String? errorMessage,
  }) {
    return SessionsListState(
      isLoading: isLoading ?? this.isLoading,
      sessions: sessions ?? this.sessions,
      errorMessage: errorMessage,
    );
  }
}

// ============================================================================
// SESSIONS LIST NOTIFIER
// ============================================================================

class SessionsListNotifier extends Notifier<SessionsListState> {
  late final InaraRepository _repository;

  @override
  SessionsListState build() {
    _repository = ref.watch(inaraRepositoryProvider);
    return const SessionsListState();
  }

  /// Get current user ID from auth state
  String? get _currentUserId {
    final authState = ref.read(authStateProvider);
    return authState.user?.id;
  }

  /// Load all sessions for the current user
  Future<void> loadSessions() async {
    final userId = _currentUserId;
    if (userId == null) {
      state = state.copyWith(
        errorMessage: 'User not authenticated',
      );
      return;
    }

    state = state.copyWith(isLoading: true);

    final result = await _repository.getUserSessions(userId);

    if (result.isSuccess) {
      state = state.copyWith(
        isLoading: false,
        sessions: result.data ?? [],
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.error,
      );
    }
  }

  /// Delete a session
  Future<bool> deleteSession(String sessionId) async {
    final result = await _repository.deleteSession(sessionId);

    if (result.isSuccess) {
      // Remove from local list
      state = state.copyWith(
        sessions: state.sessions
            .where((s) => s.sessionId != sessionId)
            .toList(),
      );
      return true;
    }
    return false;
  }

  /// Refresh sessions list
  Future<void> refresh() async {
    await loadSessions();
  }
}

// ============================================================================
// SESSIONS LIST PROVIDER
// ============================================================================

final sessionsListProvider =
    NotifierProvider<SessionsListNotifier, SessionsListState>(() {
  return SessionsListNotifier();
});

// ============================================================================
// BACKEND STATUS PROVIDER
// ============================================================================

final backendStatusProvider = FutureProvider<bool>((ref) async {
  final repository = ref.watch(inaraRepositoryProvider);
  return await repository.isBackendAvailable();
});
