import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';
import '../providers/voice_recording_provider.dart';
import 'audio_waveform.dart';

/// The main voice recording button with waveform visualization
class VoiceRecordButton extends ConsumerStatefulWidget {
  const VoiceRecordButton({super.key});

  @override
  ConsumerState<VoiceRecordButton> createState() => _VoiceRecordButtonState();
}

class _VoiceRecordButtonState extends ConsumerState<VoiceRecordButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onPressStart() async {
    setState(() => _isPressed = true);
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // Start pulse animation
    _pulseController.repeat(reverse: true);
    
    // Start recording
    await ref.read(voiceRecordingProvider.notifier).startRecording();
  }

  void _onPressEnd() async {
    if (!_isPressed) return;
    
    setState(() => _isPressed = false);
    
    // Stop pulse animation
    _pulseController.stop();
    _pulseController.reset();
    
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Stop recording and get the path
    final path = await ref.read(voiceRecordingProvider.notifier).stopRecording();
    
    if (path != null && mounted) {
      // Navigate to friend selection with the recording path
      _showSendToFriendsSheet(path);
    }
  }

  void _onPressCancel() async {
    if (!_isPressed) return;
    
    setState(() => _isPressed = false);
    
    // Stop pulse animation
    _pulseController.stop();
    _pulseController.reset();
    
    // Cancel recording
    await ref.read(voiceRecordingProvider.notifier).cancelRecording();
    
    // Show cancelled feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording cancelled'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSendToFriendsSheet(String recordingPath) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SendToFriendsSheet(
        recordingPath: recordingPath,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceRecordingProvider);
    final isRecording = voiceState.isRecording;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Waveform display (above the button)
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: isRecording ? 50 : 0,
          child: isRecording
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Recording duration
                      Text(
                        _formatDuration(voiceState.recordingDuration),
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Waveform
                      SizedBox(
                        height: 24,
                        child: AudioWaveform(
                          isRecording: isRecording,
                          amplitude: voiceState.currentAmplitude,
                          color: AppColors.error,
                          barCount: 25,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
        
        const SizedBox(height: 8),
        
        // Record button
        GestureDetector(
          onLongPressStart: (_) => _onPressStart(),
          onLongPressEnd: (_) => _onPressEnd(),
          onLongPressCancel: () => _onPressCancel(),
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isRecording ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isRecording ? AppColors.error : AppColors.textPrimary,
                      width: 4,
                    ),
                    boxShadow: isRecording
                        ? [
                            BoxShadow(
                              color: AppColors.error.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isRecording 
                          ? AppColors.error 
                          : AppColors.error.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isRecording ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Hint text
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isRecording ? 0.0 : 1.0,
          child: const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Hold to record',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Bottom sheet for selecting friends to send the voice to
class SendToFriendsSheet extends ConsumerStatefulWidget {
  final String recordingPath;

  const SendToFriendsSheet({
    super.key,
    required this.recordingPath,
  });

  @override
  ConsumerState<SendToFriendsSheet> createState() => _SendToFriendsSheetState();
}

class _SendToFriendsSheetState extends ConsumerState<SendToFriendsSheet> {
  final Set<String> _selectedFriends = {};
  bool _isSending = false;

  // TODO: Replace with actual friends from database
  final List<Map<String, String>> _mockFriends = [
    {'id': '1', 'name': 'Dr. Sarah Johnson', 'specialty': 'Cardiologist'},
    {'id': '2', 'name': 'Dr. Michael Chen', 'specialty': 'Neurologist'},
    {'id': '3', 'name': 'Dr. Emily Davis', 'specialty': 'Pediatrician'},
    {'id': '4', 'name': 'Dr. James Wilson', 'specialty': 'Orthopedic'},
    {'id': '5', 'name': 'Dr. Lisa Anderson', 'specialty': 'Dermatologist'},
  ];

  void _toggleFriend(String id) {
    setState(() {
      if (_selectedFriends.contains(id)) {
        _selectedFriends.remove(id);
      } else {
        _selectedFriends.add(id);
      }
    });
  }

  Future<void> _sendToFriends() async {
    if (_selectedFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one friend'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    // TODO: Implement actual sending logic
    // 1. Upload recording to Supabase Storage
    // 2. Create message entries in database
    // 3. Send notifications to selected friends

    await Future.delayed(const Duration(seconds: 1)); // Simulated delay

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Voice sent to ${_selectedFriends.length} friend(s)'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _deleteRecording() async {
    // Delete the recording file
    final service = ref.read(audioRecordingServiceProvider);
    await service.deleteRecording(widget.recordingPath);
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Delete button
                IconButton(
                  onPressed: _deleteRecording,
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                ),
                
                const Expanded(
                  child: Text(
                    'Send To',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                // Send button
                TextButton(
                  onPressed: _selectedFriends.isEmpty || _isSending 
                      ? null 
                      : _sendToFriends,
                  child: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : Text(
                          'Send (${_selectedFriends.length})',
                          style: TextStyle(
                            color: _selectedFriends.isEmpty 
                                ? AppColors.textSecondary 
                                : AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
          
          const Divider(color: AppColors.divider),
          
          // Friends list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _mockFriends.length,
              itemBuilder: (context, index) {
                final friend = _mockFriends[index];
                final isSelected = _selectedFriends.contains(friend['id']);
                
                return ListTile(
                  onTap: () => _toggleFriend(friend['id']!),
                  leading: CircleAvatar(
                    backgroundColor: isSelected 
                        ? AppColors.primary 
                        : AppColors.inputBackground,
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.black)
                        : Text(
                            friend['name']![0],
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  title: Text(
                    friend['name']!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    friend['specialty']!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle, color: AppColors.primary)
                      : Icon(
                          Icons.circle_outlined,
                          color: AppColors.textSecondary.withOpacity(0.5),
                        ),
                );
              },
            ),
          ),
          
          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

