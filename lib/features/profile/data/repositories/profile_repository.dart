/// ============================================================================
/// PROFILE REPOSITORY
/// ============================================================================
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/config/app_config.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  final SupabaseClient _supabase = SupabaseService.client;

  /// Get user profile
  Future<ProfileModel?> getProfile(String userId) async {
    try {
      if (AppConfig.debugMode) {
        print('📋 Fetching profile for user: $userId');
      }

      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        if (AppConfig.debugMode) {
          print('⚠️ No profile found in profiles table, trying views...');
        }
        
        // Fallback 1: Try from user_network (for connected users)
        final networkResponse = await _supabase
            .from('user_network')
            .select()
            .eq('contact_user_id', userId)
            .maybeSingle();
            
        if (networkResponse != null) {
          // Map view columns to profile model keys
          final viewData = Map<String, dynamic>.from(networkResponse);
          viewData['id'] = viewData['contact_user_id']; // Remap ID
          
          final profile = ProfileModel.fromJson(viewData);
          if (AppConfig.debugMode) print('✅ Profile loaded from user_network view');
          return profile;
        }

        // Fallback 2: Try from suggested_connections (for non-connected users)
        final suggestedResponse = await _supabase
            .from('suggested_connections')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        if (suggestedResponse != null) {
          // Map view columns to profile model keys
          final viewData = Map<String, dynamic>.from(suggestedResponse);
          viewData['id'] = viewData['user_id']; // Remap ID
          
          final profile = ProfileModel.fromJson(viewData);
          if (AppConfig.debugMode) print('✅ Profile loaded from suggested_connections view');
          return profile;
        }

        if (AppConfig.debugMode) {
          print('❌ Profile truly not found anywhere');
        }
        return null;
      }

      final profile = ProfileModel.fromJson(response);

      if (AppConfig.debugMode) {
        print('✅ Profile loaded: ${profile.fullName}');
        print('📊 Profile completed: ${profile.profileCompleted}');
      }

      return profile;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error fetching profile: $e');
      }
      rethrow;
    }
  }

  /// Create or update profile
  Future<ProfileModel> upsertProfile(ProfileModel profile) async {
    try {
      if (AppConfig.debugMode) {
        print('💾 Saving profile for user: ${profile.id}');
      }

      final data = profile.toJson();

      final response = await _supabase
          .from('profiles')
          .upsert(data)
          .select()
          .single();

      final savedProfile = ProfileModel.fromJson(response);

      if (AppConfig.debugMode) {
        print('✅ Profile saved successfully');
      }

      return savedProfile;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error saving profile: $e');
      }
      rethrow;
    }
  }

  /// Check if profile is completed
  Future<bool> isProfileCompleted(String userId) async {
    try {
      final profile = await getProfile(userId);

      if (profile == null) return false;

      // Check if all required fields are filled
      final isComplete =
          profile.firstName != null &&
          profile.firstName!.isNotEmpty &&
          profile.lastName != null &&
          profile.lastName!.isNotEmpty &&
          profile.email != null &&
          profile.email!.isNotEmpty;

      return isComplete;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error checking profile completion: $e');
      }
      return false;
    }
  }

  /// Update profile completion status
  Future<void> markProfileAsCompleted(String userId) async {
    try {
      await _supabase
          .from('profiles')
          .update({'profile_completed': true})
          .eq('id', userId);

      if (AppConfig.debugMode) {
        print('✅ Profile marked as completed');
      }
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error updating profile status: $e');
      }
      rethrow;
    }
  }

  /// Update avatar (implement later with image picker)
  // Future<String> uploadAvatar(String userId, File file) async {
  //   try {
  //     if (AppConfig.debugMode) {
  //       print('📤 Uploading avatar for user: $userId');
  //     }

  //     final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.jpg';

  //     await _supabase.storage
  //         .from('avatars')
  //         .upload(fileName, file);

  //     final avatarUrl = _supabase.storage
  //         .from('avatars')
  //         .getPublicUrl(fileName);

  //     if (AppConfig.debugMode) {
  //       print('✅ Avatar uploaded: $avatarUrl');
  //     }

  //     return avatarUrl;
  //   } catch (e) {
  //     if (AppConfig.debugMode) {
  //       print('❌ Error uploading avatar: $e');
  //     }
  //     rethrow;
  //   }
  // }
}
