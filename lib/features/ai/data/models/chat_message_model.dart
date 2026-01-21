/// ============================================================================
/// CHAT MESSAGE MODEL - Inara AI
/// ============================================================================
library;

import 'dart:typed_data';

enum MessageRole { user, ai }

enum MessageType { text, image, document }

class ChatMessageModel {
  final String id;
  final MessageRole role;
  final MessageType type;
  final String content;
  final String? fileName;
  final String? filePath;
  final Uint8List? imageBytes; // For web compatibility
  final DateTime timestamp;

  ChatMessageModel({
    required this.id,
    required this.role,
    required this.type,
    required this.content,
    this.fileName,
    this.filePath,
    this.imageBytes,
    required this.timestamp,
  });

  /// Create a user text message
  factory ChatMessageModel.userText(String content) {
    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      type: MessageType.text,
      content: content,
      timestamp: DateTime.now(),
    );
  }

  /// Create an AI text message
  factory ChatMessageModel.aiText(String content) {
    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.ai,
      type: MessageType.text,
      content: content,
      timestamp: DateTime.now(),
    );
  }

  /// Create a user image message with bytes (web compatible)
  factory ChatMessageModel.userImageBytes(Uint8List bytes, String fileName) {
    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      type: MessageType.image,
      content: '[Image: $fileName]',
      fileName: fileName,
      imageBytes: bytes,
      timestamp: DateTime.now(),
    );
  }

  /// Create a user image message from file path (mobile only)
  factory ChatMessageModel.userImage(String filePath) {
    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      type: MessageType.image,
      content: filePath,
      filePath: filePath,
      timestamp: DateTime.now(),
    );
  }

  /// Create a user document message
  factory ChatMessageModel.userDocument(String filePath, String fileName) {
    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      type: MessageType.document,
      content: filePath,
      filePath: filePath,
      fileName: fileName,
      timestamp: DateTime.now(),
    );
  }

  /// Create from API response history part
  factory ChatMessageModel.fromApiPart(Map<String, dynamic> part, String role) {
    final isUser = role == 'user';
    final messageRole = isUser ? MessageRole.user : MessageRole.ai;

    // Check if it's an image
    if (part.containsKey('inline_data')) {
      return ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        role: messageRole,
        type: MessageType.image,
        content: '[Image]',
        timestamp: DateTime.now(),
      );
    }

    // Text message
    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: messageRole,
      type: MessageType.text,
      content: part['text'] ?? '',
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'type': type.name,
      'content': content,
      'fileName': fileName,
      'filePath': filePath,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] ?? '',
      role: MessageRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => MessageRole.user,
      ),
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      content: json['content'] ?? '',
      fileName: json['fileName'],
      filePath: json['filePath'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}
