import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Empty state for now
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hymn Chat'),
        actions: [
          IconButton(
            icon: const CircleAvatar(
              backgroundColor: AppColors.surfaceLight,
              child: Icon(Icons.person, color: AppColors.textPrimary),
            ),
            onPressed: () => context.push('/profile'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration placeholder
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 20),
            Text(
              "No doctors yet",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Add doctors to start sending\nsecure voice notes",
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
