import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
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
      'type': 'text',
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
        'type': 'text',
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
            'type': 'text',
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

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      
      if (image != null) {
        setState(() {
          _messages.add({
            'role': 'user',
            'type': 'image',
            'content': image.path,
            'time': DateTime.now(),
          });
        });
        
        // Simulate AI analyzing image
        _scrollToBottom();
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _messages.add({
                'role': 'ai',
                'type': 'text',
                'content': 'I see the image you uploaded. It appears to be a medical scan. Would you like me to analyze it for specific markers?',
                'time': DateTime.now(),
              });
            });
            _scrollToBottom();
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null) {
        String? filePath = result.files.single.path;
        String fileName = result.files.single.name;
        
        if (filePath != null) {
          setState(() {
            _messages.add({
              'role': 'user',
              'type': 'document',
              'content': filePath,
              'fileName': fileName,
              'time': DateTime.now(),
            });
          });
          _scrollToBottom();
          
           // Simulate AI analyzing doc
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  _messages.add({
                    'role': 'ai',
                    'type': 'text',
                    'content': 'I have received the document "$fileName". I am processing its contents now.',
                    'time': DateTime.now(),
                  });
                });
                _scrollToBottom();
              }
            });
        }
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery', style: TextStyle(color: AppColors.textPrimary)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.image, color: AppColors.primary),
              ),
              title: const Text(
                'Upload Image',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _showImageSourceDialog();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.description, color: Colors.orange),
              ),
              title: const Text(
                'Upload Document',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickDocument();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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
                return _buildMessageBubble(msg, isUser);
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
                      onTap: _showAttachmentOptions,
                      child: const Icon(
                        Icons.add,
                        size: 28,
                        color: AppColors.textSecondary,
                      ),
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

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isUser) {
    final String content = msg['content'];
    final String type = msg['type'] ?? 'text';
    
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
        child: _buildBubbleContent(type, content, msg, isUser),
      ),
    );
  }

  Widget _buildBubbleContent(String type, String content, Map<String, dynamic> msg, bool isUser) {
    if (type == 'image') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(content),
              fit: BoxFit.cover,
            ),
          ),
        ],
      );
    } else if (type == 'document') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.description, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  msg['fileName'] ?? 'Document',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isUser ? AppColors.textInverse : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'PDF Document', // Could parse extension
                  style: TextStyle(
                    color: (isUser ? AppColors.textInverse : AppColors.textPrimary).withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    
    // Text Logic
    return isUser 
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
        );
  }
}

// Add this if AppColors.stateBlue doesn't exist
extension on Color {
  static const stateBlue = Color(0xFF007AFF); // iOS Blue
}
