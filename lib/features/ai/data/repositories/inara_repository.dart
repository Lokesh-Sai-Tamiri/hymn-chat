/// ============================================================================
/// INARA REPOSITORY - Business Logic Layer for Inara AI
/// ============================================================================
library;

import 'dart:typed_data';
import '../models/chat_message_model.dart';
import '../models/chat_session_model.dart';
import '../services/inara_api_service.dart';

/// Result wrapper for repository operations
class RepoResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  RepoResult._({this.data, this.error, required this.isSuccess});

  factory RepoResult.success(T data) =>
      RepoResult._(data: data, isSuccess: true);

  factory RepoResult.failure(String error) =>
      RepoResult._(error: error, isSuccess: false);
}

class InaraRepository {
  final InaraApiService _apiService;

  InaraRepository({InaraApiService? apiService})
      : _apiService = apiService ?? InaraApiService();

  /// Create a new chat session
  Future<RepoResult<ChatSessionModel>> createSession({
    String? userId,
    String? title,
  }) async {
    final result = await _apiService.createSession(
      userId: userId,
      title: title,
    );

    if (result.isSuccess && result.data != null) {
      return RepoResult.success(result.data!);
    }
    return RepoResult.failure(result.error ?? 'Failed to create session');
  }

  /// Get a specific session with full history
  Future<RepoResult<ChatSessionModel>> getSession(String sessionId) async {
    final result = await _apiService.getSession(sessionId);

    if (result.isSuccess && result.data != null) {
      return RepoResult.success(result.data!);
    }
    return RepoResult.failure(result.error ?? 'Failed to get session');
  }

  /// Get all sessions for a user
  Future<RepoResult<List<ChatSessionListItem>>> getUserSessions(
    String userId,
  ) async {
    final result = await _apiService.getUserSessions(userId);

    if (result.isSuccess && result.data != null) {
      return RepoResult.success(result.data!);
    }
    return RepoResult.failure(result.error ?? 'Failed to get sessions');
  }

  /// Delete a session
  Future<RepoResult<bool>> deleteSession(String sessionId) async {
    final result = await _apiService.deleteSession(sessionId);

    if (result.isSuccess) {
      return RepoResult.success(true);
    }
    return RepoResult.failure(result.error ?? 'Failed to delete session');
  }

  /// Send a text message and get AI response
  Future<RepoResult<ChatMessageModel>> sendMessage({
    required String message,
    String? sessionId,
    String? userId,
  }) async {
    final result = await _apiService.sendMessage(
      message: message,
      sessionId: sessionId,
      userId: userId,
    );

    if (result.isSuccess && result.data != null) {
      // Return the AI response as a ChatMessageModel
      return RepoResult.success(ChatMessageModel.aiText(result.data!.response));
    }
    return RepoResult.failure(result.error ?? 'Failed to send message');
  }

  /// Send a message with an image and get AI response
  Future<RepoResult<ChatMessageModel>> sendMessageWithImage({
    required String message,
    required Uint8List imageBytes,
    required String fileName,
    String? sessionId,
    String? userId,
  }) async {
    final result = await _apiService.sendMessageWithImage(
      message: message,
      imageBytes: imageBytes,
      fileName: fileName,
      sessionId: sessionId,
      userId: userId,
    );

    if (result.isSuccess && result.data != null) {
      return RepoResult.success(ChatMessageModel.aiText(result.data!.response));
    }
    return RepoResult.failure(result.error ?? 'Failed to send message');
  }

  /// Check if backend is available
  Future<bool> isBackendAvailable() async {
    return await _apiService.checkHealth();
  }

  void dispose() {
    _apiService.dispose();
  }
}
