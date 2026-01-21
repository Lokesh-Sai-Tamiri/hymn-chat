/// ============================================================================
/// CHAT SESSION MODEL - Inara AI
/// ============================================================================
library;

import 'chat_message_model.dart';

class ChatSessionModel {
  final String sessionId;
  final String? userId;
  final String title;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<ChatMessageModel> messages;

  ChatSessionModel({
    required this.sessionId,
    this.userId,
    required this.title,
    required this.createdAt,
    this.updatedAt,
    this.messages = const [],
  });

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    // Parse history into messages
    List<ChatMessageModel> messages = [];
    if (json['history'] != null) {
      for (var turn in json['history']) {
        final role = turn['role'] as String?;
        final parts = turn['parts'] as List<dynamic>?;
        final timestamp = turn['timestamp'] != null
            ? DateTime.tryParse(turn['timestamp'])
            : DateTime.now();

        if (parts != null) {
          for (var part in parts) {
            if (part is Map<String, dynamic>) {
              // Skip inline_data for now (images from history)
              if (part.containsKey('text')) {
                messages.add(ChatMessageModel(
                  id: '${json['session_id']}_${messages.length}',
                  role: role == 'user' ? MessageRole.user : MessageRole.ai,
                  type: MessageType.text,
                  content: part['text'] ?? '',
                  timestamp: timestamp ?? DateTime.now(),
                ));
              }
            }
          }
        }
      }
    }

    return ChatSessionModel(
      sessionId: json['session_id'] ?? '',
      userId: json['user_id'],
      title: json['title'] ?? 'New Chat',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      messages: messages,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'user_id': userId,
      'title': title,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  ChatSessionModel copyWith({
    String? sessionId,
    String? userId,
    String? title,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessageModel>? messages,
  }) {
    return ChatSessionModel(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }
}

/// Lightweight session item for listing (without messages)
class ChatSessionListItem {
  final String sessionId;
  final String? userId;
  final String title;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int messageCount;

  ChatSessionListItem({
    required this.sessionId,
    this.userId,
    required this.title,
    required this.createdAt,
    this.updatedAt,
    this.messageCount = 0,
  });

  factory ChatSessionListItem.fromJson(Map<String, dynamic> json) {
    return ChatSessionListItem(
      sessionId: json['session_id'] ?? '',
      userId: json['user_id'],
      title: json['title'] ?? 'New Chat',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      messageCount: json['message_count'] ?? 0,
    );
  }
}
