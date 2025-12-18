import 'dart:async';
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/config/app_config.dart';

/// Service for audio recording with amplitude (waveform) data
class AudioRecordingService {
  final AudioRecorder _recorder = AudioRecorder();
  
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  final _amplitudeController = StreamController<double>.broadcast();
  
  String? _currentRecordingPath;
  bool _isRecording = false;
  DateTime? _recordingStartTime;
  
  /// Stream of amplitude values (0.0 to 1.0) for waveform visualization
  Stream<double> get amplitudeStream => _amplitudeController.stream;
  
  /// Whether currently recording
  bool get isRecording => _isRecording;
  
  /// Current recording path
  String? get currentRecordingPath => _currentRecordingPath;
  
  /// Recording duration
  Duration get recordingDuration {
    if (_recordingStartTime == null) return Duration.zero;
    return DateTime.now().difference(_recordingStartTime!);
  }

  /// Request microphone permission
  Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    if (AppConfig.debugMode) {
      print('🎤 Microphone permission: $status');
    }
    return status.isGranted;
  }

  /// Check if microphone permission is granted
  Future<bool> hasPermission() async {
    return await Permission.microphone.isGranted;
  }

  /// Start recording audio
  Future<bool> startRecording() async {
    try {
      // Check permission
      if (!await hasPermission()) {
        final granted = await requestPermission();
        if (!granted) {
          if (AppConfig.debugMode) {
            print('❌ Microphone permission denied');
          }
          return false;
        }
      }

      // Check if recorder is available
      if (!await _recorder.hasPermission()) {
        if (AppConfig.debugMode) {
          print('❌ Recorder has no permission');
        }
        return false;
      }

      // Generate unique file path
      final directory = await getApplicationDocumentsDirectory();
      final uuid = const Uuid().v4();
      _currentRecordingPath = '${directory.path}/voice_$uuid.m4a';

      // Configure recording
      const config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100,
        bitRate: 128000,
        numChannels: 1,
      );

      // Start recording
      await _recorder.start(config, path: _currentRecordingPath!);
      
      _isRecording = true;
      _recordingStartTime = DateTime.now();

      // Start amplitude monitoring for waveform
      _startAmplitudeMonitoring();

      if (AppConfig.debugMode) {
        print('🎙️ Recording started: $_currentRecordingPath');
      }

      return true;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Failed to start recording: $e');
      }
      return false;
    }
  }

  /// Stop recording and return the file path
  Future<String?> stopRecording() async {
    try {
      if (!_isRecording) return null;

      _stopAmplitudeMonitoring();
      
      final path = await _recorder.stop();
      _isRecording = false;
      
      final duration = recordingDuration;
      _recordingStartTime = null;

      if (AppConfig.debugMode) {
        print('⏹️ Recording stopped: $path (${duration.inSeconds}s)');
      }

      // Check if file exists and has content
      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          final size = await file.length();
          if (AppConfig.debugMode) {
            print('📁 Recording file size: ${(size / 1024).toStringAsFixed(2)} KB');
          }
          if (size > 0) {
            return path;
          }
        }
      }

      return null;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('❌ Failed to stop recording: $e');
      }
      _isRecording = false;
      return null;
    }
  }

  /// Cancel recording without saving
  Future<void> cancelRecording() async {
    try {
      _stopAmplitudeMonitoring();
      
      await _recorder.stop();
      _isRecording = false;
      _recordingStartTime = null;

      // Delete the file if it exists
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
          if (AppConfig.debugMode) {
            print('🗑️ Recording cancelled and deleted');
          }
        }
      }
      
      _currentRecordingPath = null;
    } catch (e) {
      if (AppConfig.debugMode) {
        print('⚠️ Error cancelling recording: $e');
      }
    }
  }

  void _startAmplitudeMonitoring() {
    _amplitudeSubscription = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 100))
        .listen((amplitude) {
      // Convert dB amplitude to 0-1 range
      // Typical range is -60dB (silence) to 0dB (max)
      final normalizedAmplitude = _normalizeAmplitude(amplitude.current);
      _amplitudeController.add(normalizedAmplitude);
    });
  }

  void _stopAmplitudeMonitoring() {
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
  }

  /// Normalize amplitude from dB to 0-1 range
  double _normalizeAmplitude(double dB) {
    // dB typically ranges from -60 (silent) to 0 (max)
    // We'll use -50 to 0 for better visualization
    const minDb = -50.0;
    const maxDb = 0.0;
    
    if (dB < minDb) return 0.0;
    if (dB > maxDb) return 1.0;
    
    return (dB - minDb) / (maxDb - minDb);
  }

  /// Delete a recording file
  Future<void> deleteRecording(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        if (AppConfig.debugMode) {
          print('🗑️ Deleted recording: $path');
        }
      }
    } catch (e) {
      if (AppConfig.debugMode) {
        print('⚠️ Error deleting recording: $e');
      }
    }
  }

  /// Dispose resources
  void dispose() {
    _stopAmplitudeMonitoring();
    _amplitudeController.close();
    _recorder.dispose();
  }
}

