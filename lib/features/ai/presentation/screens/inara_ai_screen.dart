import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../core/theme/colors.dart';
import '../../data/models/chat_message_model.dart';
import '../providers/inara_provider.dart';
import '../widgets/markdown_text.dart';
import 'chat_history_screen.dart';

class InaraAIScreen extends ConsumerStatefulWidget {
  final VoidCallback? onBackPressed;
  final String? initialSessionId;

  const InaraAIScreen({
    super.key,
    this.onBackPressed,
    this.initialSessionId,
  });

  @override
  ConsumerState<InaraAIScreen> createState() => _InaraAIScreenState();
}

class _InaraAIScreenState extends ConsumerState<InaraAIScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showHistory = false;
  bool _hasText = false;
  
  // Speech to text
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    // Listen for text changes
    _messageController.addListener(_onTextChanged);
    
    // Initialize speech recognition
    _initSpeech();
    
    // Load existing session if provided, otherwise start fresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialSessionId != null) {
        ref.read(chatProvider.notifier).loadSession(widget.initialSessionId!);
      } else {
        ref.read(chatProvider.notifier).startNewChat();
      }
    });
  }

  /// Initialize speech recognition
  Future<void> _initSpeech() async {
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          debugPrint('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            if (mounted) {
              setState(() {
                _isListening = false;
              });
            }
          }
        },
        onError: (error) {
          debugPrint('Speech error: $error');
          if (mounted) {
            setState(() {
              _isListening = false;
            });
            _showErrorSnackBar('Speech recognition error: ${error.errorMsg}');
          }
        },
      );
      if (mounted) {
        setState(() {});
      }
      debugPrint('Speech available: $_speechAvailable');
    } catch (e) {
      debugPrint('Failed to initialize speech: $e');
      _speechAvailable = false;
    }
  }

  /// Start or stop listening
  Future<void> _toggleListening() async {
    if (!_speechAvailable) {
      _showErrorSnackBar('Speech recognition not available on this device');
      return;
    }

    if (_isListening) {
      await _stopListening();
    } else {
      await _startListening();
    }
  }

  /// Start listening for speech
  Future<void> _startListening() async {
    if (!_speechAvailable) return;

    setState(() {
      _isListening = true;
      _lastWords = '';
    });

    await _speech.listen(
      onResult: (result) {
        setState(() {
          _lastWords = result.recognizedWords;
          // Update the text field with recognized words
          _messageController.text = _lastWords;
          // Move cursor to end
          _messageController.selection = TextSelection.fromPosition(
            TextPosition(offset: _messageController.text.length),
          );
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      listenMode: stt.ListenMode.dictation,
    );
  }

  /// Stop listening
  Future<void> _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
    });
  }

  /// Track text changes for send button UI
  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _speech.stop();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text;
    _messageController.clear();

    // Send via provider
    ref.read(chatProvider.notifier).sendMessage(message);

    // Scroll to bottom after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
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
        // Read image as bytes (works on both web and mobile)
        final bytes = await image.readAsBytes();
        final fileName = image.name;
        
        // Send image with a default message
        ref.read(chatProvider.notifier).sendMessageWithImage(
              'Please analyze this image.',
              bytes,
              fileName,
            );

        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showErrorSnackBar('Failed to pick image');
    }
  }

  Future<void> _pickDocument() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
      );

      if (result != null && result.files.single.path != null) {
        // For now, show a message that documents are not yet supported
        _showErrorSnackBar(
          'Document upload coming soon. Please use images for now.',
        );
      }
    } catch (e) {
      debugPrint('Error picking document: $e');
      _showErrorSnackBar('Failed to pick document');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _openChatHistory() {
    setState(() {
      _showHistory = true;
    });
  }

  void _closeChatHistory() {
    setState(() {
      _showHistory = false;
    });
  }

  void _onSessionSelected(String sessionId) {
    ref.read(chatProvider.notifier).loadSession(sessionId);
    setState(() {
      _showHistory = false;
    });
  }

  void _startNewChat() {
    ref.read(chatProvider.notifier).startNewChat();
    setState(() {
      _showHistory = false;
    });
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
              title: const Text(
                'Take Photo',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primary,
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(color: AppColors.textPrimary),
              ),
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
    // Show chat history screen if toggled
    if (_showHistory) {
      return ChatHistoryScreen(
        onSessionSelected: _onSessionSelected,
        onNewChat: _startNewChat,
        onBackPressed: _closeChatHistory,
      );
    }

    final chatState = ref.watch(chatProvider);

    // Listen for errors and show snackbar
    ref.listen<ChatState>(chatProvider, (previous, next) {
      if (next.errorMessage != null && next.errorMessage != previous?.errorMessage) {
        _showErrorSnackBar(next.errorMessage!);
        ref.read(chatProvider.notifier).clearError();
      }
      // Scroll to bottom when new messages arrive
      if (next.messages.length != (previous?.messages.length ?? 0)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });

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
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 18,
              ),
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
                    Text(
                      chatState.isTyping ? 'Typing...' : 'Online',
                      style: const TextStyle(
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
        actions: [
          // Chat history button
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.textSecondary),
            onPressed: _openChatHistory,
            tooltip: 'Chat History',
          ),
          // New chat button
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: _startNewChat,
            tooltip: 'New Chat',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Chat Area
            Expanded(
              child: chatState.messages.isEmpty
                  ? _buildWelcomeMessage()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      itemCount: chatState.messages.length + (chatState.isTyping ? 1 : 0),
                      itemBuilder: (context, index) {
                        // Show typing indicator
                        if (index == chatState.messages.length && chatState.isTyping) {
                          return _buildTypingIndicator();
                        }
                        final msg = chatState.messages[index];
                        return _buildMessageBubbleFromModel(msg);
                      },
                    ),
            ),

            // Gemini-style Input Area
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).padding.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
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
                  // Listening indicator
                  if (_isListening) ...[
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Listening...',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Text Area
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
                      enabled: chatState.status != ChatStatus.sending,
                      decoration: InputDecoration(
                        hintText: _isListening ? 'Speak now...' : 'Ask Inara...',
                        hintStyle: TextStyle(
                          color: _isListening ? AppColors.error : AppColors.textSecondary,
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
                        onTap: chatState.status != ChatStatus.sending
                            ? _showAttachmentOptions
                            : null,
                        child: Icon(
                          Icons.add,
                          size: 28,
                          color: chatState.status != ChatStatus.sending
                              ? AppColors.textSecondary
                              : AppColors.textSecondary.withOpacity(0.5),
                        ),
                      ),

                      const Spacer(),

                      // Mic Button
                      GestureDetector(
                        onTap: chatState.status != ChatStatus.sending
                            ? _toggleListening
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _isListening 
                                ? AppColors.error 
                                : AppColors.inputBackground,
                            shape: BoxShape.circle,
                            boxShadow: _isListening
                                ? [
                                    BoxShadow(
                                      color: AppColors.error.withOpacity(0.4),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none_rounded,
                            color: _isListening 
                                ? Colors.white 
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Send / AI Sparkle Button
                      GestureDetector(
                        onTap: chatState.status != ChatStatus.sending
                            ? _sendMessage
                            : null,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: chatState.status == ChatStatus.sending
                                ? AppColors.inputBackground.withOpacity(0.5)
                                : _hasText
                                    ? AppColors.primary
                                    : AppColors.inputBackground,
                            shape: BoxShape.circle,
                          ),
                          child: chatState.status == ChatStatus.sending
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : Icon(
                                  _hasText 
                                      ? Icons.arrow_forward_rounded 
                                      : Icons.auto_awesome,
                                  color: _hasText 
                                      ? AppColors.textInverse 
                                      : AppColors.textPrimary,
                                  size: 20,
                                ),
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

  Widget _buildWelcomeMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
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
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Hello! I\'m Inara',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your AI Clinical Assistant',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'I can help you with research, diagnosis support,\nand administrative tasks.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF2A2A35), Color(0xFF1F1F25)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 4),
            _buildDot(1),
            const SizedBox(width: 4),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withOpacity(0.3 + (value * 0.5)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildMessageBubbleFromModel(ChatMessageModel msg) {
    final isUser = msg.role == MessageRole.user;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surfaceLight,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          gradient: isUser
              ? null
              : const LinearGradient(
                  colors: [Color(0xFF2A2A35), Color(0xFF1F1F25)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: _buildBubbleContentFromModel(msg, isUser),
      ),
    );
  }

  Widget _buildBubbleContentFromModel(ChatMessageModel msg, bool isUser) {
    switch (msg.type) {
      case MessageType.image:
        // Display image from bytes (web compatible)
        if (msg.imageBytes != null) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  msg.imageBytes!,
                  fit: BoxFit.cover,
                  width: 200,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildImagePlaceholder();
                  },
                ),
              ),
              if (msg.fileName != null) ...[
                const SizedBox(height: 4),
                Text(
                  msg.fileName!,
                  style: TextStyle(
                    color: isUser ? AppColors.textInverse : AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          );
        }
        // Fallback: show placeholder for images from history
        return _buildImagePlaceholder();

      case MessageType.document:
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
                    msg.fileName ?? 'Document',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isUser
                          ? AppColors.textInverse
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Document',
                    style: TextStyle(
                      color:
                          (isUser ? AppColors.textInverse : AppColors.textPrimary)
                              .withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      case MessageType.text:
        return isUser
            ? Text(
                msg.content,
                style: const TextStyle(
                  color: AppColors.textInverse,
                  fontSize: 16,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownText(
                    text: msg.content,
                    textColor: AppColors.textPrimary,
                    baseStyle: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.thumb_up_alt_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 12),
                      Icon(
                        Icons.copy_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              );
    }
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 150,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            color: AppColors.textSecondary,
            size: 32,
          ),
          SizedBox(height: 4),
          Text(
            'Image',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
