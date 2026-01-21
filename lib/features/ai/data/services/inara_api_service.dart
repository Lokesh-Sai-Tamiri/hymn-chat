/// ============================================================================
/// INARA API SERVICE - HTTP Client for Inara AI Backend
/// ============================================================================
library;

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../models/chat_session_model.dart';

/// Result wrapper for API responses
class ApiResult<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResult._({this.data, this.error, required this.isSuccess});

  factory ApiResult.success(T data) =>
      ApiResult._(data: data, isSuccess: true);

  factory ApiResult.failure(String error) =>
      ApiResult._(error: error, isSuccess: false);
}

/// Chat response from the API
class ChatApiResponse {
  final String response;
  final String sessionId;

  ChatApiResponse({required this.response, required this.sessionId});

  factory ChatApiResponse.fromJson(Map<String, dynamic> json) {
    return ChatApiResponse(
      response: json['response'] ?? '',
      sessionId: json['session_id'] ?? '',
    );
  }
}

class InaraApiService {
  final String baseUrl;
  final http.Client _client;

  InaraApiService({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? AppConfig.inaraApiBaseUrl,
        _client = client ?? http.Client();

  /// Helper to get timeout duration
  Duration get _timeout => Duration(seconds: AppConfig.apiTimeoutSeconds);

  /// Create a new chat session
  Future<ApiResult<ChatSessionModel>> createSession({
    String? userId,
    String? title,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl${AppConfig.inaraSessionsEndpoint}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'title': title,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ApiResult.success(ChatSessionModel.fromJson(json));
      } else {
        return ApiResult.failure(
          'Failed to create session: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error creating session: $e');
      return ApiResult.failure(_getErrorMessage(e));
    }
  }

  /// Get a specific session with full history
  Future<ApiResult<ChatSessionModel>> getSession(String sessionId) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl${AppConfig.inaraSessionsEndpoint}/$sessionId'),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ApiResult.success(ChatSessionModel.fromJson(json));
      } else if (response.statusCode == 404) {
        return ApiResult.failure('Session not found');
      } else {
        return ApiResult.failure(
          'Failed to get session: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error getting session: $e');
      return ApiResult.failure(_getErrorMessage(e));
    }
  }

  /// Get all sessions for a user (lightweight, without full history)
  Future<ApiResult<List<ChatSessionListItem>>> getUserSessions(
    String userId,
  ) async {
    try {
      final response = await _client
          .get(
            Uri.parse(
              '$baseUrl${AppConfig.inaraUserSessionsEndpoint}/$userId/sessions',
            ),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final sessions =
            jsonList.map((json) => ChatSessionListItem.fromJson(json)).toList();
        return ApiResult.success(sessions);
      } else {
        return ApiResult.failure(
          'Failed to get sessions: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error getting user sessions: $e');
      return ApiResult.failure(_getErrorMessage(e));
    }
  }

  /// Delete a session
  Future<ApiResult<bool>> deleteSession(String sessionId) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('$baseUrl${AppConfig.inaraSessionsEndpoint}/$sessionId'),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return ApiResult.success(true);
      } else if (response.statusCode == 404) {
        return ApiResult.failure('Session not found');
      } else {
        return ApiResult.failure(
          'Failed to delete session: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error deleting session: $e');
      return ApiResult.failure(_getErrorMessage(e));
    }
  }

  /// Send a chat message (text only)
  Future<ApiResult<ChatApiResponse>> sendMessage({
    required String message,
    String? sessionId,
    String? userId,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl${AppConfig.inaraChatEndpoint}'),
      );

      request.fields['message'] = message;
      if (sessionId != null) {
        request.fields['session_id'] = sessionId;
      }
      if (userId != null) {
        request.fields['user_id'] = userId;
      }

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ApiResult.success(ChatApiResponse.fromJson(json));
      } else {
        final errorBody = response.body;
        debugPrint('Chat error: $errorBody');
        return ApiResult.failure(
          'Failed to send message: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
      return ApiResult.failure(_getErrorMessage(e));
    }
  }

  /// Send a chat message with an image (using bytes for web compatibility)
  Future<ApiResult<ChatApiResponse>> sendMessageWithImage({
    required String message,
    required Uint8List imageBytes,
    required String fileName,
    String? sessionId,
    String? userId,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl${AppConfig.inaraChatEndpoint}'),
      );

      request.fields['message'] = message;
      if (sessionId != null) {
        request.fields['session_id'] = sessionId;
      }
      if (userId != null) {
        request.fields['user_id'] = userId;
      }

      // Add image file from bytes (works on both web and mobile)
      final mimeType = _getMimeType(fileName);
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
        contentType: http.MediaType.parse(mimeType),
      ));

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return ApiResult.success(ChatApiResponse.fromJson(json));
      } else {
        return ApiResult.failure(
          'Failed to send message with image: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error sending message with image: $e');
      return ApiResult.failure(_getErrorMessage(e));
    }
  }

  /// Check if the backend is online
  Future<bool> checkHealth() async {
    try {
      final response = await _client
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }

  /// Get MIME type from file path
  String _getMimeType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  /// Convert exception to user-friendly error message
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString();
    if (errorStr.contains('SocketException') || errorStr.contains('Connection refused')) {
      return 'Unable to connect to server. Please check your connection.';
    } else if (errorStr.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  void dispose() {
    _client.close();
  }
}
