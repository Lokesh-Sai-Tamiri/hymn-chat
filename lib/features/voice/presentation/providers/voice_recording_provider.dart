import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/audio_recording_service.dart';
import '../../../../core/config/app_config.dart';

/// State for voice recording
class VoiceRecordingState {
  final bool isRecording;
  final bool hasPermission;
  final bool isPermissionPermanentlyDenied;
  final double currentAmplitude;
  final Duration recordingDuration;
  final String? recordingPath;
  final String? errorMessage;

  const VoiceRecordingState({
    this.isRecording = false,
    this.hasPermission = false,
    this.isPermissionPermanentlyDenied = false,
    this.currentAmplitude = 0.0,
    this.recordingDuration = Duration.zero,
    this.recordingPath,
    this.errorMessage,
  });

  VoiceRecordingState copyWith({
    bool? isRecording,
    bool? hasPermission,
    bool? isPermissionPermanentlyDenied,
    double? currentAmplitude,
    Duration? recordingDuration,
    String? recordingPath,
    String? errorMessage,
  }) {
    return VoiceRecordingState(
      isRecording: isRecording ?? this.isRecording,
      hasPermission: hasPermission ?? this.hasPermission,
      isPermissionPermanentlyDenied: isPermissionPermanentlyDenied ?? this.isPermissionPermanentlyDenied,
      currentAmplitude: currentAmplitude ?? this.currentAmplitude,
      recordingDuration: recordingDuration ?? this.recordingDuration,
      recordingPath: recordingPath,
      errorMessage: errorMessage,
    );
  }
}

/// Provider for audio recording service
final audioRecordingServiceProvider = Provider<AudioRecordingService>((ref) {
  final service = AudioRecordingService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider for voice recording state
final voiceRecordingProvider =
    NotifierProvider<VoiceRecordingNotifier, VoiceRecordingState>(
  VoiceRecordingNotifier.new,
);

class VoiceRecordingNotifier extends Notifier<VoiceRecordingState> {
  AudioRecordingService get _service => ref.read(audioRecordingServiceProvider);
  StreamSubscription<double>? _amplitudeSubscription;
  Timer? _durationTimer;

  @override
  VoiceRecordingState build() {
    // Set up amplitude listener
    _listenToAmplitude();
    
    // Check permission on build
    _checkPermission();
    
    // Cleanup on dispose
    ref.onDispose(() {
      _amplitudeSubscription?.cancel();
      _durationTimer?.cancel();
    });
    
    return const VoiceRecordingState();
  }

  Future<void> _checkPermission() async {
    final hasPermission = await _service.hasPermission();
    final isPermanentlyDenied = await _service.isPermissionPermanentlyDenied();
    state = state.copyWith(
      hasPermission: hasPermission,
      isPermissionPermanentlyDenied: isPermanentlyDenied,
    );
  }

  void _listenToAmplitude() {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = _service.amplitudeStream.listen((amplitude) {
      if (state.isRecording) {
        state = state.copyWith(currentAmplitude: amplitude);
      }
    });
  }

  /// Request microphone permission
  /// Returns true if granted, false otherwise
  /// Updates state with permanentlyDenied flag if applicable
  Future<bool> requestPermission() async {
    final result = await _service.requestPermission();
    
    switch (result) {
      case MicrophonePermissionResult.granted:
        state = state.copyWith(
          hasPermission: true,
          isPermissionPermanentlyDenied: false,
        );
        return true;
      case MicrophonePermissionResult.permanentlyDenied:
        state = state.copyWith(
          hasPermission: false,
          isPermissionPermanentlyDenied: true,
        );
        return false;
      case MicrophonePermissionResult.denied:
        state = state.copyWith(
          hasPermission: false,
          isPermissionPermanentlyDenied: false,
        );
        return false;
    }
  }
  
  /// Open app settings to enable microphone permission
  Future<bool> openSettings() async {
    return await _service.openSettings();
  }

  /// Start recording
  Future<bool> startRecording() async {
    try {
      // Request permission if not granted
      if (!state.hasPermission) {
        final granted = await requestPermission();
        if (!granted) {
          // Error message will be shown by UI based on isPermissionPermanentlyDenied flag
          return false;
        }
      }

      final success = await _service.startRecording();
      
      if (success) {
        state = state.copyWith(
          isRecording: true,
          currentAmplitude: 0.0,
          recordingDuration: Duration.zero,
          errorMessage: null,
        );
        
        // Start duration timer
        _startDurationTimer();
        
        if (AppConfig.debugMode) {
          print('🎙️ Recording started');
        }
      } else {
        state = state.copyWith(
          errorMessage: 'Failed to start recording',
        );
      }
      
      return success;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error starting recording: $e');
      }
      state = state.copyWith(errorMessage: 'Error: $e');
      return false;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    try {
      _stopDurationTimer();
      
      final path = await _service.stopRecording();
      
      state = state.copyWith(
        isRecording: false,
        currentAmplitude: 0.0,
        recordingPath: path,
      );
      
      if (AppConfig.debugMode) {
        print('⏹️ Recording stopped: $path');
      }
      
      return path;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Error stopping recording: $e');
      }
      state = state.copyWith(
        isRecording: false,
        errorMessage: 'Error stopping recording: $e',
      );
      return null;
    }
  }

  /// Cancel recording
  Future<void> cancelRecording() async {
    _stopDurationTimer();
    await _service.cancelRecording();
    
    state = state.copyWith(
      isRecording: false,
      currentAmplitude: 0.0,
      recordingDuration: Duration.zero,
    );
    
    if (AppConfig.debugMode) {
      print('🗑️ Recording cancelled');
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.isRecording) {
        state = state.copyWith(
          recordingDuration: Duration(seconds: timer.tick),
        );
      }
    });
  }

  void _stopDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }
}
