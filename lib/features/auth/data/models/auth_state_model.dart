/// ============================================================================
/// AUTH STATE MODEL
/// ============================================================================
library;

import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthStateModel {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final bool isLoading;

  const AuthStateModel({
    required this.status,
    this.user,
    this.errorMessage,
    this.isLoading = false,
  });

  // Initial state
  factory AuthStateModel.initial() {
    return const AuthStateModel(status: AuthStatus.initial, isLoading: false);
  }

  // Loading state
  factory AuthStateModel.loading() {
    return const AuthStateModel(status: AuthStatus.loading, isLoading: true);
  }

  // Authenticated state
  factory AuthStateModel.authenticated(User user) {
    return AuthStateModel(
      status: AuthStatus.authenticated,
      user: user,
      isLoading: false,
    );
  }

  // Unauthenticated state
  factory AuthStateModel.unauthenticated() {
    return const AuthStateModel(
      status: AuthStatus.unauthenticated,
      isLoading: false,
    );
  }

  // Error state
  factory AuthStateModel.error(String message) {
    return AuthStateModel(
      status: AuthStatus.error,
      errorMessage: message,
      isLoading: false,
    );
  }

  // Copy with method
  AuthStateModel copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthStateModel(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
}

/// ============================================================================
/// OTP STATE MODEL
/// ============================================================================

enum OtpStatus { initial, sending, sent, verifying, verified, error }

class OtpStateModel {
  final OtpStatus status;
  final String? phoneNumber;
  final String? errorMessage;
  final bool canResend;
  final int remainingSeconds;
  final int attemptsLeft;

  const OtpStateModel({
    required this.status,
    this.phoneNumber,
    this.errorMessage,
    this.canResend = false,
    this.remainingSeconds = 0,
    this.attemptsLeft = 3,
  });

  // Initial state
  factory OtpStateModel.initial() {
    return const OtpStateModel(status: OtpStatus.initial, canResend: false);
  }

  // Sending state
  factory OtpStateModel.sending(String phoneNumber) {
    return OtpStateModel(
      status: OtpStatus.sending,
      phoneNumber: phoneNumber,
      canResend: false,
    );
  }

  // Sent state
  factory OtpStateModel.sent(String phoneNumber, {int cooldownSeconds = 30}) {
    return OtpStateModel(
      status: OtpStatus.sent,
      phoneNumber: phoneNumber,
      canResend: false,
      remainingSeconds: cooldownSeconds,
    );
  }

  // Verifying state
  factory OtpStateModel.verifying(String phoneNumber) {
    return OtpStateModel(
      status: OtpStatus.verifying,
      phoneNumber: phoneNumber,
      canResend: false,
    );
  }

  // Verified state
  factory OtpStateModel.verified(String phoneNumber) {
    return OtpStateModel(
      status: OtpStatus.verified,
      phoneNumber: phoneNumber,
      canResend: false,
    );
  }

  // Error state
  factory OtpStateModel.error(
    String message, {
    String? phoneNumber,
    int? attemptsLeft,
  }) {
    return OtpStateModel(
      status: OtpStatus.error,
      phoneNumber: phoneNumber,
      errorMessage: message,
      canResend: true,
      attemptsLeft: attemptsLeft ?? 3,
    );
  }

  // Copy with method
  OtpStateModel copyWith({
    OtpStatus? status,
    String? phoneNumber,
    String? errorMessage,
    bool? canResend,
    int? remainingSeconds,
    int? attemptsLeft,
  }) {
    return OtpStateModel(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      errorMessage: errorMessage ?? this.errorMessage,
      canResend: canResend ?? this.canResend,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      attemptsLeft: attemptsLeft ?? this.attemptsLeft,
    );
  }
}
