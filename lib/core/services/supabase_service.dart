/// ============================================================================
/// SUPABASE SERVICE - Initialization & Core Service
/// ============================================================================

import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class SupabaseService {
  static SupabaseClient? _client;
  static Timer? _refreshTimer;
  
  /// Get Supabase client instance
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception(
        'Supabase not initialized. Call SupabaseService.initialize() first',
      );
    }
    return _client!;
  }
  
  /// Initialize Supabase
  static Future<void> initialize() async {
    // Validate configuration
    if (!AppConfig.isConfigValid()) {
      throw Exception(
        'Invalid Supabase configuration. Please update values in app_config.dart',
      );
    }
    
    try {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
        debug: AppConfig.debugMode,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
        ),
      );
      
      _client = Supabase.instance.client;
      
      // Start periodic session refresh
      if (AppConfig.autoRefreshToken) {
        _startSessionRefresh();
      }
      
      // Listen to auth state changes
      _client!.auth.onAuthStateChange.listen((data) {
        final event = data.event;
        if (event == AuthChangeEvent.tokenRefreshed) {
          if (AppConfig.debugMode) {
            print('🔄 Token refreshed successfully');
          }
        } else if (event == AuthChangeEvent.signedOut) {
          _refreshTimer?.cancel();
        } else if (event == AuthChangeEvent.signedIn) {
          if (AppConfig.autoRefreshToken) {
            _startSessionRefresh();
          }
        }
      });
      
      if (AppConfig.debugMode) {
        print('✅ Supabase initialized successfully');
        print('📍 Environment: ${AppConfig.getEnvironment()}');
        print('🔄 Auto-refresh: ${AppConfig.autoRefreshToken}');
      }
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Supabase initialization failed: $e');
      }
      rethrow;
    }
  }
  
  /// Start periodic session refresh
  static void _startSessionRefresh() {
    _refreshTimer?.cancel();
    
    if (!AppConfig.autoRefreshToken) return;
    
    // Refresh session periodically (every 50 minutes by default)
    _refreshTimer = Timer.periodic(
      Duration(seconds: AppConfig.sessionRefreshIntervalSeconds),
      (_) async {
        await refreshSession();
      },
    );
  }
  
  /// Manually refresh session
  static Future<bool> refreshSession() async {
    try {
      if (_client == null || _client!.auth.currentSession == null) {
        return false;
      }
      
      if (AppConfig.debugMode) {
        print('🔄 Refreshing session...');
      }
      
      // Refresh the session
      final response = await _client!.auth.refreshSession();
      
      if (response.session != null) {
        if (AppConfig.debugMode) {
          print('✅ Session refreshed successfully');
        }
        return true;
      } else {
        if (AppConfig.debugMode) {
          print('⚠️ Session refresh returned null');
        }
        return false;
      }
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Session refresh failed: $e');
      }
      
      // If refresh fails, user needs to re-authenticate
      if (e.toString().contains('refresh_token_not_found') ||
          e.toString().contains('invalid_grant')) {
        await signOut();
      }
      
      return false;
    }
  }
  
  /// Check if session is valid and not expired
  static bool isSessionValid() {
    final session = _client?.auth.currentSession;
    if (session == null) return false;
    
    // Check if token is expired
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;
    
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final isExpired = now >= expiresAt;
    
    if (isExpired && AppConfig.debugMode) {
      print('⚠️ Session expired at ${DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000)}');
    }
    
    return !isExpired;
  }
  
  /// Check if user is authenticated
  static bool get isAuthenticated {
    return _client?.auth.currentSession != null && isSessionValid();
  }
  
  /// Get current user
  static User? get currentUser {
    return _client?.auth.currentUser;
  }
  
  /// Get current session
  static Session? get currentSession {
    return _client?.auth.currentSession;
  }
  
  /// Sign out
  static Future<void> signOut() async {
    _refreshTimer?.cancel();
    await _client?.auth.signOut();
  }
  
  /// Dispose resources
  static void dispose() {
    _refreshTimer?.cancel();
  }
}

