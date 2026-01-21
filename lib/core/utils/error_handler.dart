/// ============================================================================
/// ERROR HANDLER - Centralized error handling with token refresh support
/// ============================================================================
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../services/supabase_service.dart';

class ErrorHandler {
  /// Check if error is token-related
  static bool isTokenError(dynamic error) {
    if (error is AuthException) {
      final message = error.message.toLowerCase();
      return message.contains('jwt') ||
          message.contains('token') ||
          message.contains('expired') ||
          message.contains('invalid') ||
          error.statusCode == '401';
    }

    if (error is String) {
      final message = error.toLowerCase();
      return message.contains('token has expired') ||
          message.contains('invalid token') ||
          message.contains('jwt expired');
    }

    return false;
  }

  /// Get user-friendly error message
  static String getUserMessage(dynamic error) {
    if (error is AuthException) {
      // Check for specific error codes
      switch (error.statusCode) {
        case '400':
          if (error.message.toLowerCase().contains('invalid')) {
            return AppConfig.errorMessages['invalid_otp']!;
          }
          return AppConfig.errorMessages['invalid_phone']!;

        case '401':
          if (isTokenError(error)) {
            return AppConfig.errorMessages['session_expired']!;
          }
          return 'Authentication failed';

        case '429':
          return AppConfig.errorMessages['rate_limit']!;

        case '422':
          return AppConfig.errorMessages['otp_expired']!;

        default:
          if (error.message.toLowerCase().contains('network')) {
            return AppConfig.errorMessages['network_error']!;
          }
          return error.message;
      }
    }

    if (error is Exception) {
      final message = error.toString().replaceAll('Exception: ', '');

      // Check for token errors
      if (isTokenError(message)) {
        return AppConfig.errorMessages['session_expired']!;
      }

      return message;
    }

    return error.toString();
  }

  /// Handle error with automatic retry on token expiry
  static Future<T> handleError<T>(
    Future<T> Function() operation, {
    bool retryOnTokenError = true,
  }) async {
    try {
      return await operation();
    } catch (e) {
      if (retryOnTokenError && isTokenError(e)) {
        if (AppConfig.debugMode) {
          print('🔄 Token error detected, attempting to refresh and retry...');
        }

        // Try to refresh session
        final refreshed = await SupabaseService.refreshSession();

        if (refreshed) {
          // Retry operation after refresh
          try {
            return await operation();
          } catch (retryError) {
            throw Exception(getUserMessage(retryError));
          }
        } else {
          throw Exception(AppConfig.errorMessages['session_expired']!);
        }
      }

      throw Exception(getUserMessage(e));
    }
  }
}
