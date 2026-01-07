import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  static final List<Map<String, dynamic>> _mockChats = [
    {
      'id': '1',
      'name': 'Dr. Sarah Wilson', 
      'message': 'The patient\'s ECG looks stable now, but we should monitor for another hour.',
      'time': '10:42 AM',
      'unread': 2,
      'isVoice': false,
      'image': 'SW',
      'isOnline': true,
    },
    {
      'id': '2',
      'name': 'Dr. James Chen',
      'message': 'Voice Message (0:45)',
      'time': '09:15 AM',
      'unread': 1,
      'isVoice': true,
      'image': 'JC',
      'isOnline': false,
    },
    {
      'id': '3',
      'name': 'ER Team - Shift A',
      'message': 'Dr. House: Incoming trauma case, ETA 5 mins.',
      'time': 'Yesterday',
      'unread': 0,
      'isVoice': false,
      'image': 'ER',
      'isOnline': true,
    },
    {
      'id': '4',
      'name': 'Dr. Emily Davis',
      'message': 'Can you review the latest lab results when you have a moment?',
      'time': 'Yesterday',
      'unread': 0,
      'isVoice': false,
      'image': 'ED',
      'isOnline': false,
    },
    {
      'id': '5',
      'name': 'Neurology Dept',
      'message': 'Weekly rounds are rescheduled to Friday morning.',
      'time': 'Mon',
      'unread': 0,
      'isVoice': false,
      'image': 'ND',
      'isOnline': false,
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Messages',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '3 unread messages',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Icon(Icons.person, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const TextField(
                  style: TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    hintStyle: TextStyle(color: AppColors.textSecondary),
                    prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Chat List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 100), // Space for bottom nav
                itemCount: _mockChats.length,
                itemBuilder: (context, index) {
                  final chat = _mockChats[index];
                  return _buildChatTile(context, chat);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, Map<String, dynamic> chat) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          context.push(
            '/chat/${chat['id']}',
            extra: {'userName': chat['name']},
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      chat['image'],
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  if (chat['isOnline'])
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.background, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          chat['name'],
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          chat['time'],
                          style: TextStyle(
                            color: chat['unread'] > 0 ? AppColors.primary : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: chat['unread'] > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (chat['isVoice'])
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Icon(Icons.mic, size: 16, color: AppColors.textSecondary),
                                ),
                              Expanded(
                                child: Text(
                                  chat['message'],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: chat['unread'] > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                                    fontSize: 14,
                                    fontWeight: chat['unread'] > 0 ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (chat['unread'] > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              chat['unread'].toString(),
                              style: const TextStyle(
                                color: AppColors.textInverse,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
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
      ),
    );
  }
}
