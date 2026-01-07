import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String userName;

  const ChatScreen({
    super.key,
    required this.chatId,
    this.userName = 'Chat',
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {'text': 'Hey! Did you see the patient in room 302?', 'isMe': false, 'time': '10:00 AM'},
    {'text': 'Yes, I just finished the rounds.', 'isMe': true, 'time': '10:01 AM'},
    {'text': 'Great. Her vitals are looking better.', 'isMe': false, 'time': '10:02 AM'},
  ];

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() {
      _messages.add({
        'text': _messageController.text,
        'isMe': true,
        'time': 'Now',
      });
      _messageController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: BackButton(color: AppColors.textPrimary),
        title: GestureDetector(
          onTap: () => context.push(
            '/chat-settings/${widget.chatId}',
            extra: {'userName': widget.userName},
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.surfaceLight,
                radius: 16,
                child: Text(
                  widget.userName.isNotEmpty ? widget.userName[0] : '?',
                  style: const TextStyle(
                    color: AppColors.primary, 
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.userName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 16),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.video_call_rounded, color: AppColors.textPrimary, size: 28),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call_rounded, color: AppColors.textPrimary, size: 24),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Disappearing messages notice (Snapchat style)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Chats disappear 24 hours after viewing",
              style: TextStyle(color: AppColors.textSecondary.withOpacity(0.5), fontSize: 12),
            ),
          ),
          
          // Messages List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message['isMe'] as bool;
                
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.primary : AppColors.surfaceLight,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
                        bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
                      ),
                      border: isMe ? null : Border.all(color: AppColors.primary.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message['text'],
                          style: TextStyle(
                            color: isMe ? AppColors.textInverse : AppColors.textPrimary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Input Area
          Container(
            padding: EdgeInsets.only(
              left: 16, 
              right: 16, 
              top: 10, 
              bottom: MediaQuery.of(context).padding.bottom + 10
            ),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(top: BorderSide(color: Colors.transparent)), // Fully seamless
            ),
            child: Row(
              children: [
                // Camera Button (Snapchat staple)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.textPrimary, size: 24),
                ),
                
                const SizedBox(width: 8),
                
                // Text Field (Blended)
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                    ),
                    onChanged: (val) {
                      setState(() {});
                    },
                    decoration: const InputDecoration(
                      hintText: 'Chat',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: false, 
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Mic / Send
                GestureDetector(
                  onTap: () {
                    if (_messageController.text.isNotEmpty) {
                      _sendMessage();
                    } else {
                      // Voice record logic
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      _messageController.text.isNotEmpty ? Icons.arrow_upward_rounded : Icons.mic_none_rounded,
                      color: AppColors.textPrimary,
                      size: 28,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
