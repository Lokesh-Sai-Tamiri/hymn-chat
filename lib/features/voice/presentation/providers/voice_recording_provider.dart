import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/audio_recording_service.dart';
import '../../../../core/config/app_config.dart';

/// State for voice recording
class VoiceRecordingState {
  final bool isRecording;
  final bool hasPermission;
  final double currentAmplitude;
  final Duration recordingDuration;
  final String? recordingPath;
  final String? errorMessage;

  const VoiceRecordingState({
    this.isRecording = false,
    this.hasPermission = false,
    this.currentAmplitude = 0.0,
    this.recordingDuration = Duration.zero,
    this.recordingPath,
    this.errorMessage,
  });

  VoiceRecordingState copyWith({
    bool? isRecording,
    bool? hasPermission,
    double? currentAmplitude,
    Duration? recordingDuration,
    String? recordingPath,
    String? errorMessage,
  }) {
    return VoiceRecordingState(
      isRecording: isRecording ?? this.isRecording,
      hasPermission: hasPermission ?? this.hasPermission,
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
    state = state.copyWith(hasPermission: hasPermission);
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
  Future<bool> requestPermission() async {
    final granted = await _service.requestPermission();
    state = state.copyWith(hasPermission: granted);
    return granted;
  }

  /// Start recording
  Future<bool> startRecording() async {
    try {
      // Request permission if not granted
      if (!state.hasPermission) {
        final granted = await requestPermission();
        if (!granted) {
          state = state.copyWith(
            errorMessage: 'Microphone permission is required to record voice messages',
          );
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
