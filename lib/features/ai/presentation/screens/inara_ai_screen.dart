import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/colors.dart';

class InaraAIScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackPressed;
  
  const InaraAIScreen({
    super.key,
    this.onBackPressed,
  });

  @override
  ConsumerState<InaraAIScreen> createState() => _InaraAIScreenState();
}

class _InaraAIScreenState extends ConsumerState<InaraAIScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Mock Messages
  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'ai',
      'content': 'Hello Dr. Tamiri, I am Inara. How can I assist you with your patients today?',
      'time': DateTime.now().subtract(const Duration(minutes: 1)),
    },
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text;
    setState(() {
      _messages.add({
        'role': 'user',
        'content': userMessage,
        'time': DateTime.now(),
      });
      _messageController.clear();
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Simulate AI typing and response
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'ai',
            'content': _getMockAIResponse(userMessage),
            'time': DateTime.now(),
          });
        });
        _scrollToBottom();
      }
    });
  }

  String _getMockAIResponse(String input) {
    input = input.toLowerCase();
    if (input.contains('schedule') || input.contains('appointment')) {
      return 'I can help check your schedule. You have a free slot at 2:00 PM today. Would you like to leverage that?';
    } else if (input.contains('patient') || input.contains('record')) {
      return 'Please specify the patient ID or name to pull up the relevant EMR records securely.';
    } else if (input.contains('diagnosis') || input.contains('symptoms')) {
      return 'Based on current clinical guidelines, those symptoms could suggest... (Disclaimer: I am an AI assistant, please verify with clinical protocols).';
    } else {
      return 'I understand. Could you elaborate more on that from a clinical perspective?';
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: widget.onBackPressed ?? () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            Container(
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.blue, Colors.teal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inara AI',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Online',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Chat Area
            Expanded(
              child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return _buildMessageBubble(msg['content'], isUser);
              },
            ),
          ),

          // Gemini-style Input Area
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
            decoration: const BoxDecoration(
              color: AppColors.surface, // Or a specific dark grey like Color(0xFF1E1E1E)
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text Area (Blended with background)
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 60,
                    maxHeight: 150,
                  ),
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      height: 1.5,
                    ),
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Ask Inara...',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 18,
                      ),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Bottom Tools Row
                Row(
                  children: [
                    // Plus Icon (for attachments options)
                    GestureDetector(
                      onTap: () {
                         // Attachments logic/popover
                      },
                      child: const Icon(
                        Icons.add,
                        size: 28,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(width: 24),
                    
                    // Filters Icon (as seen in image)
                    const Icon(
                      Icons.tune_rounded, 
                      size: 24, 
                      color: AppColors.textSecondary,
                    ),

                    const Spacer(),
                    
                    // Mic Button
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground, // Slightly lighter than bg
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic_none_rounded, color: AppColors.textPrimary),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Send / AI Sparkle Button
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.inputBackground, // Or Primary if we want emphasis
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.auto_awesome, color: AppColors.textPrimary, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surfaceLight, 
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          gradient: isUser ? null : const LinearGradient(
            colors: [Color(0xFF2A2A35), Color(0xFF1F1F25)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        ),
        child: isUser 
          ? Text(
              content,
              style: const TextStyle(
                color: AppColors.textInverse, // Black on Yellow
                fontSize: 16,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.thumb_up_alt_outlined, size: 14, color: AppColors.textSecondary),
                    SizedBox(width: 12),
                    Icon(Icons.copy_outlined, size: 14, color: AppColors.textSecondary),
                  ],
                )
              ],
            ),
      ),
    );
  }
}

// Add this if AppColors.stateBlue doesn't exist
extension on Color {
  static const stateBlue = Color(0xFF007AFF); // iOS Blue
}
