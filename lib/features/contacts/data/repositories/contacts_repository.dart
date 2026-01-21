/// ============================================================================
/// CONTACTS REPOSITORY - HIPAA Compliant
/// ============================================================================
/// 
/// Handles all data operations for connections/contacts.
/// Uses Supabase with Row Level Security for HIPAA compliance.
/// ============================================================================
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/config/app_config.dart';
import '../models/connection_model.dart';

class ContactsRepository {
  final SupabaseClient _supabase = SupabaseService.client;

  // ============================================================================
  // NETWORK (Accepted Connections)
  // ============================================================================

  /// Get user's network (accepted connections with profile info)
  Future<List<NetworkContactModel>> getNetwork() async {
    try {
      if (AppConfig.debugMode) {
        print('👥 Fetching user network...');
      }

      final response = await _supabase
          .from('user_network')
          .select()
          .order('connected_since', ascending: false);

      final contacts = (response as List)
          .map((json) => NetworkContactModel.fromJson(json))
          .toList();

      if (AppConfig.debugMode) {
        print('✅ Network loaded: ${contacts.length} contacts');
      }

      return contacts;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error fetching network: $e');
      }
      rethrow;
    }
  }

  /// Search network contacts
  Future<List<NetworkContactModel>> searchNetwork(String query) async {
    try {
      if (AppConfig.debugMode) {
        print('🔍 Searching network for: $query');
      }

      final response = await _supabase
          .from('user_network')
          .select()
          .or('first_name.ilike.%$query%,last_name.ilike.%$query%,display_name.ilike.%$query%,specialization.ilike.%$query%')
          .order('connected_since', ascending: false);

      return (response as List)
          .map((json) => NetworkContactModel.fromJson(json))
          .toList();
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error searching network: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // SUGGESTIONS
  // ============================================================================

  /// Get suggested connections (doctors not yet connected)
  Future<List<SuggestedContactModel>> getSuggestions() async {
    try {
      if (AppConfig.debugMode) {
        print('💡 Fetching connection suggestions...');
      }

      final response = await _supabase
          .from('suggested_connections')
          .select();

      final suggestions = (response as List)
          .map((json) => SuggestedContactModel.fromJson(json))
          .toList();

      if (AppConfig.debugMode) {
        print('✅ Suggestions loaded: ${suggestions.length}');
      }

      return suggestions;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error fetching suggestions: $e');
      }
      rethrow;
    }
  }

  /// Search for users to connect with
  Future<List<SuggestedContactModel>> searchUsers(String query) async {
    try {
      if (AppConfig.debugMode) {
        print('🔍 Searching users for: $query');
      }

      // Search in profiles that are not already connected
      final response = await _supabase
          .from('suggested_connections')
          .select()
          .or('first_name.ilike.%$query%,last_name.ilike.%$query%,display_name.ilike.%$query%,specialization.ilike.%$query%,clinic_name.ilike.%$query%');

      return (response as List)
          .map((json) => SuggestedContactModel.fromJson(json))
          .toList();
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error searching users: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // PENDING REQUESTS
  // ============================================================================

  /// Get pending connection requests (received)
  Future<List<PendingRequestModel>> getPendingRequests() async {
    try {
      if (AppConfig.debugMode) {
        print('📬 Fetching pending requests...');
      }

      final response = await _supabase
          .from('pending_requests')
          .select()
          .order('created_at', ascending: false);

      final requests = (response as List)
          .map((json) => PendingRequestModel.fromJson(json))
          .toList();

      if (AppConfig.debugMode) {
        print('✅ Pending requests loaded: ${requests.length}');
      }

      return requests;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error fetching pending requests: $e');
      }
      rethrow;
    }
  }

  /// Get sent connection requests (outgoing)
  Future<List<String>> getSentRequestUserIds() async {
    try {
      final response = await _supabase
          .from('sent_requests')
          .select('recipient_id');

      return (response as List)
          .map((json) => json['recipient_id'] as String)
          .toList();
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error fetching sent requests: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // CONNECTION ACTIONS
  // ============================================================================

  /// Send a connection request
  Future<String> sendConnectionRequest(String recipientId, {String? message}) async {
    try {
      if (AppConfig.debugMode) {
        print('📤 Sending connection request to: $recipientId');
      }

      final response = await _supabase
          .rpc('send_connection_request', params: {
            'p_recipient_id': recipientId,
            'p_message': message,
          });

      if (AppConfig.debugMode) {
        print('✅ Connection request sent: $response');
      }

      return response as String;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error sending connection request: $e');
      }
      rethrow;
    }
  }

  /// Accept a connection request
  Future<bool> acceptConnectionRequest(String connectionId) async {
    try {
      if (AppConfig.debugMode) {
        print('✅ Accepting connection request: $connectionId');
      }

      final response = await _supabase
          .rpc('accept_connection_request', params: {
            'p_connection_id': connectionId,
          });

      if (AppConfig.debugMode) {
        print('✅ Connection accepted: $response');
      }

      return response as bool;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error accepting connection: $e');
      }
      rethrow;
    }
  }

  /// Reject a connection request
  Future<bool> rejectConnectionRequest(String connectionId) async {
    try {
      if (AppConfig.debugMode) {
        print('❌ Rejecting connection request: $connectionId');
      }

      final response = await _supabase
          .rpc('reject_connection_request', params: {
            'p_connection_id': connectionId,
          });

      return response as bool;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error rejecting connection: $e');
      }
      rethrow;
    }
  }

  /// Remove a connection (soft delete)
  Future<bool> removeConnection(String connectionId) async {
    try {
      if (AppConfig.debugMode) {
        print('🗑️ Removing connection: $connectionId');
      }

      final response = await _supabase
          .rpc('remove_connection', params: {
            'p_connection_id': connectionId,
          });

      return response as bool;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error removing connection: $e');
      }
      rethrow;
    }
  }

  /// Block a user
  Future<String> blockUser(String userId) async {
    try {
      if (AppConfig.debugMode) {
        print('🚫 Blocking user: $userId');
      }

      final response = await _supabase
          .rpc('block_user', params: {
            'p_user_id': userId,
          });

      return response as String;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error blocking user: $e');
      }
      rethrow;
    }
  }

  // ============================================================================
  // REAL-TIME SUBSCRIPTIONS
  // ============================================================================

  /// Subscribe to connection changes
  /// Note: Supabase realtime doesn't support OR filters directly,
  /// so we subscribe to all changes on the connections table and
  /// filter in the callback
  RealtimeChannel subscribeToConnections({
    required void Function(List<NetworkContactModel>) onNetworkUpdate,
    required void Function(List<PendingRequestModel>) onPendingUpdate,
  }) {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    return _supabase
        .channel('connections_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'connections',
          callback: (payload) async {
            // Check if this change involves the current user
            final newRecord = payload.newRecord;
            final oldRecord = payload.oldRecord;
            
            final isRelevant = 
                newRecord['requester_id'] == userId ||
                newRecord['recipient_id'] == userId ||
                oldRecord['requester_id'] == userId ||
                oldRecord['recipient_id'] == userId;
            
            if (!isRelevant) return;

            // Refresh both lists on any relevant change
            try {
              final network = await getNetwork();
              onNetworkUpdate(network);
              
              final pending = await getPendingRequests();
              onPendingUpdate(pending);
            } catch (e) {
              if (AppConfig.debugMode) {
                print('❌ Error in real-time update: $e');
              }
            }
          },
        )
        .subscribe();
  }

  /// Unsubscribe from connection changes
  Future<void> unsubscribeFromConnections(RealtimeChannel channel) async {
    await _supabase.removeChannel(channel);
  }
}
