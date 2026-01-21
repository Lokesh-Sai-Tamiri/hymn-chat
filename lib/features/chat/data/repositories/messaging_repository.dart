/// ============================================================================
/// MESSAGING REPOSITORY - HIPAA Compliant
/// ============================================================================
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/config/app_config.dart';
import '../models/messaging_models.dart';

class MessagingRepository {
  final SupabaseClient _supabase = SupabaseService.client;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  // ============================================================================
  // CONVERSATIONS
  // ============================================================================

  /// Get all conversations for current user
  Future<List<ConversationModel>> getConversations({bool includeArchived = false}) async {
    try {
      if (AppConfig.debugMode) {
        print('💬 Fetching conversations...');
      }

      var query = _supabase
          .from('my_conversations')
          .select();
      
      if (!includeArchived) {
        query = query.eq('is_archived', false);
      }

      final response = await query.order('last_message_at', ascending: false);

      final convs = (response as List)
          .map((json) => ConversationModel.fromJson(json))
          .toList();

      if (AppConfig.debugMode) {
        print('✅ Conversations loaded: ${convs.length}');
      }

      return convs;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error fetching conversations: $e');
      }
      rethrow;
    }
  }

  /// Get or create conversation with another user
  Future<String> getOrCreateConversation(String otherUserId) async {
    try {
      if (AppConfig.debugMode) {
        print('💬 Getting/creating conversation with: $otherUserId');
      }

      final response = await _supabase.rpc('get_or_create_conversation', params: {
        'p_other_user_id': otherUserId,
      });

      return response as String;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error getting/creating conversation: $e');
      }
      rethrow;
    }
  }

  /// Get single conversation by ID
  Future<ConversationModel?> getConversation(String conversationId) async {
    try {
      final response = await _supabase
          .from('my_conversations')
          .select()
          .eq('conversation_id', conversationId)
          .maybeSingle();

      if (response == null) return null;

      return ConversationModel.fromJson(response);
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error fetching conversation: $e');
      }
      rethrow;
    }
  }

  /// Update conversation settings
  Future<bool> updateConversationSettings({
    required String conversationId,
    bool? muted,
    bool? archived,
    bool? pinned,
    int? disappearingHours,
  }) async {
    try {
      final response = await _supabase.rpc('update_conversation_settings', params: {
        'p_conversation_id': conversationId,
        'p_muted': muted,
        'p_archived': archived,
        'p_pinned': pinned,
        'p_disappearing_hours': disappearingHours,
      });

      return response as bool;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error updating conversation settings: $e');
      }
      rethrow;
    }
  }

  /// Delete conversation (soft delete for user)
  Future<bool> deleteConversation(String conversationId) async {
    try {
      final response = await _supabase.rpc('delete_conversation', params: {
        'p_conversation_id': conversationId,
      });

      return response as bool;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error deleting conversation: $e');
      }
      rethrow;
    }
  }

  /// Get total unread count
  Future<int> getTotalUnreadCount() async {
    try {
      final response = await _supabase.rpc('get_total_unread_count');
      return response as int? ?? 0;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error getting unread count: $e');
      }
      return 0;
    }
  }

  // ============================================================================
  // MESSAGES
  // ============================================================================

  /// Get messages for a conversation
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int limit = 50,
    DateTime? before,
  }) async {
    try {
      if (AppConfig.debugMode) {
        print('📨 Fetching messages for: $conversationId');
      }

      var query = _supabase
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .isFilter('deleted_at', null);

      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      final messages = (response as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();

      if (AppConfig.debugMode) {
        print('✅ Messages loaded: ${messages.length}');
      }

      return messages;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error fetching messages: $e');
      }
      rethrow;
    }
  }

  /// Send a text message
  Future<String> sendMessage({
    required String conversationId,
    required String content,
    String? replyToId,
  }) async {
    try {
      if (AppConfig.debugMode) {
        print('📤 Sending message to: $conversationId');
      }

      final response = await _supabase.rpc('send_message', params: {
        'p_conversation_id': conversationId,
        'p_content': content,
        'p_message_type': 'text',
        'p_reply_to_id': replyToId,
      });

      return response as String;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error sending message: $e');
      }
      rethrow;
    }
  }

  /// Send an audio message
  Future<String> sendAudioMessage({
    required String conversationId,
    required String fileUrl,
    required int durationSeconds,
    String? fileName,
    int? fileSize,
  }) async {
    try {
      final response = await _supabase.rpc('send_message', params: {
        'p_conversation_id': conversationId,
        'p_message_type': 'audio',
        'p_file_url': fileUrl,
        'p_file_name': fileName,
        'p_file_size': fileSize,
        'p_audio_duration': durationSeconds,
      });

      return response as String;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error sending audio message: $e');
      }
      rethrow;
    }
  }

  /// Send an image message
  Future<String> sendImageMessage({
    required String conversationId,
    required String fileUrl,
    String? fileName,
    int? fileSize,
  }) async {
    try {
      final response = await _supabase.rpc('send_message', params: {
        'p_conversation_id': conversationId,
        'p_message_type': 'image',
        'p_file_url': fileUrl,
        'p_file_name': fileName,
        'p_file_size': fileSize,
      });

      return response as String;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error sending image message: $e');
      }
      rethrow;
    }
  }

  /// Mark messages as read
  Future<int> markMessagesRead(String conversationId) async {
    try {
      final response = await _supabase.rpc('mark_messages_read', params: {
        'p_conversation_id': conversationId,
      });

      return response as int? ?? 0;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error marking messages read: $e');
      }
      rethrow;
    }
  }

  /// Save audio message (Snapchat-style)
  Future<bool> saveAudioMessage(String messageId) async {
    try {
      final response = await _supabase.rpc('save_audio_message', params: {
        'p_message_id': messageId,
      });

      return response as bool;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error saving audio message: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // REAL-TIME SUBSCRIPTIONS
  // ============================================================================

  /// Subscribe to new messages in a conversation
  RealtimeChannel subscribeToMessages({
    required String conversationId,
    required void Function(MessageModel message) onNewMessage,
    required void Function(MessageModel message) onMessageUpdate,
  }) {
    final channel = _supabase
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) {
              final message = MessageModel.fromJson(payload.newRecord);
              onNewMessage(message);
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) {
              final message = MessageModel.fromJson(payload.newRecord);
              onMessageUpdate(message);
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// Subscribe to conversation list updates
  RealtimeChannel subscribeToConversations({
    required void Function() onUpdate,
  }) {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final channel = _supabase
        .channel('conversations:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'conversations',
          callback: (payload) {
            // Check if this conversation involves the current user
            final newRecord = payload.newRecord;
            final oldRecord = payload.oldRecord;
            
            final record = newRecord.isNotEmpty ? newRecord : oldRecord;
            if (record['user1_id'] == userId || record['user2_id'] == userId) {
              onUpdate();
            }
          },
        )
        .subscribe();

    return channel;
  }

  /// Unsubscribe from channel
  Future<void> unsubscribe(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }

  // ============================================================================
  // BLOCKING & REPORTING
  // ============================================================================

  /// Block a user
  Future<bool> blockUser(String userId, {String? reason}) async {
    try {
      if (AppConfig.debugMode) {
        print('🚫 Blocking user: $userId');
      }

      final response = await _supabase.rpc('block_user_messaging', params: {
        'p_user_id': userId,
        'p_reason': reason,
      });

      return response as bool;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error blocking user: $e');
      }
      rethrow;
    }
  }

  /// Unblock a user
  Future<bool> unblockUser(String userId) async {
    try {
      if (AppConfig.debugMode) {
        print('✅ Unblocking user: $userId');
      }

      final response = await _supabase.rpc('unblock_user_messaging', params: {
        'p_user_id': userId,
      });

      return response as bool;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error unblocking user: $e');
      }
      rethrow;
    }
  }

  /// Get blocked users
  Future<List<BlockedUserModel>> getBlockedUsers() async {
    try {
      final response = await _supabase
          .from('my_blocked_users')
          .select()
          .order('blocked_at', ascending: false);

      return (response as List)
          .map((json) => BlockedUserModel.fromJson(json))
          .toList();
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error fetching blocked users: $e');
      }
      rethrow;
    }
  }

  /// Report a user
  Future<String> reportUser({
    required String userId,
    required String reason,
    String? description,
    String? messageId,
  }) async {
    try {
      if (AppConfig.debugMode) {
        print('🚨 Reporting user: $userId');
      }

      final response = await _supabase.rpc('report_user_messaging', params: {
        'p_user_id': userId,
        'p_reason': reason,
        'p_description': description,
        'p_message_id': messageId,
      });

      return response as String;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error reporting user: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // MESSAGING PREFERENCES
  // ============================================================================

  /// Get user's messaging preferences
  Future<MessagingPreferencesModel?> getMessagingPreferences() async {
    try {
      final userId = currentUserId;
      if (userId == null) return null;

      final response = await _supabase
          .from('messaging_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // Create default preferences
        await _supabase.from('messaging_preferences').insert({
          'user_id': userId,
        });
        
        return MessagingPreferencesModel(
          userId: userId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      return MessagingPreferencesModel.fromJson(response);
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error fetching messaging preferences: $e');
      }
      rethrow;
    }
  }

  /// Update messaging preferences
  Future<bool> updateMessagingPreferences(MessagingPreferencesModel prefs) async {
    try {
      await _supabase
          .from('messaging_preferences')
          .upsert(prefs.toJson());

      return true;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error updating messaging preferences: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // FILE UPLOAD
  // ============================================================================

  /// Upload a file to storage
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required List<int> bytes,
    String? contentType,
  }) async {
    try {
      final response = await _supabase.storage.from(bucket).uploadBinary(
        path,
        bytes as dynamic,
        fileOptions: FileOptions(contentType: contentType),
      );

      // Get public URL
      final publicUrl = _supabase.storage.from(bucket).getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error uploading file: $e');
      }
      rethrow;
    }
  }
}
