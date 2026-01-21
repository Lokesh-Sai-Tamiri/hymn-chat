/// ============================================================================
/// PROFILE PROVIDERS
/// ============================================================================
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/profile_model.dart';
import '../../data/repositories/profile_repository.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/supabase_service.dart';

/// Profile Repository Provider
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

/// Current Profile Provider
final currentProfileProvider = FutureProvider<ProfileModel?>((ref) async {
  final user = SupabaseService.currentUser;
  if (user == null) return null;

  final repository = ref.watch(profileRepositoryProvider);
  return await repository.getProfile(user.id);
});

/// Profile Notifier Provider
final profileNotifierProvider =
    AsyncNotifierProvider<ProfileNotifier, ProfileModel?>(
      () => ProfileNotifier(),
    );

/// Profile Notifier
class ProfileNotifier extends AsyncNotifier<ProfileModel?> {
  late final ProfileRepository _repository;

  @override
  Future<ProfileModel?> build() async {
    _repository = ref.watch(profileRepositoryProvider);
    return await _loadProfile();
  }

  /// Load profile
  Future<ProfileModel?> _loadProfile() async {
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        return null;
      }

      final profile = await _repository.getProfile(user.id);
      return profile;
    } catch (e) {
      rethrow;
    }
  }

  /// Save profile
  Future<bool> saveProfile(ProfileModel profile) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final savedProfile = await _repository.upsertProfile(profile);

      // Mark as completed if all required fields are filled
      if (savedProfile.firstName != null &&
          savedProfile.lastName != null &&
          savedProfile.email != null) {
        await _repository.markProfileAsCompleted(savedProfile.id);
      }

      if (AppConfig.debugMode) {
        print('✅ Profile saved successfully');
      }

      return savedProfile;
    });

    return !state.hasError;
  }

  /// Reload profile
  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }
}
