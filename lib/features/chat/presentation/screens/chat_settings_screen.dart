/// ============================================================================
/// CHAT SETTINGS SCREEN - Privacy, Block, Report
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../data/models/messaging_models.dart';
import '../providers/messaging_provider.dart';

class ChatSettingsScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String userName;
  final String? otherUserId;

  const ChatSettingsScreen({
    super.key,
    required this.chatId,
    this.userName = 'User',
    this.otherUserId,
  });

  @override
  ConsumerState<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends ConsumerState<ChatSettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Load messaging preferences
    Future.microtask(() {
      ref.read(messagingPrefsProvider.notifier).loadPreferences();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final conversation = chatState.conversation;
    final prefsState = ref.watch(messagingPrefsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
        title: const Text(
          'Chat Settings',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header
          _buildProfileHeader(conversation),

          const SizedBox(height: 24),

          // Chat Settings Section
          _buildSectionHeader('CHAT SETTINGS'),
          const SizedBox(height: 8),
          _buildSettingsCard([
            _buildDropdownTile(
              icon: Icons.timer_outlined,
              title: 'Delete chats after',
              value: _getDisappearingText(conversation?.disappearingHours),
              options: const ['Never', '1 Hour', '24 Hours', '1 Week'],
              onChanged: (value) => _updateDisappearing(value, conversation),
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Get notified for new messages',
              value: conversation?.isMuted == false,
              onChanged: (value) {
                if (conversation != null) {
                  ref.read(conversationsProvider.notifier).updateSettings(
                    conversationId: conversation.conversationId,
                    muted: !value,
                  );
                }
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Privacy Section (Your preferences)
          _buildSectionHeader('YOUR MESSAGE PRIVACY'),
          const SizedBox(height: 8),
          _buildSettingsCard([
            _buildSwitchTile(
              icon: Icons.save_outlined,
              title: 'Allow saving audio messages',
              subtitle: 'Others can save your voice messages in chat',
              value: prefsState.preferences?.allowAudioSave ?? false,
              onChanged: (value) {
                ref.read(messagingPrefsProvider.notifier).setAllowAudioSave(value);
              },
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: Icons.done_all,
              title: 'Read receipts',
              subtitle: 'Show when you\'ve read messages',
              value: prefsState.preferences?.readReceiptsEnabled ?? true,
              onChanged: (value) {
                ref.read(messagingPrefsProvider.notifier).setReadReceipts(value);
              },
            ),
          ]),

          const SizedBox(height: 24),

          // Other User's Settings (info only)
          if (conversation != null) ...[
            _buildSectionHeader('${widget.userName.toUpperCase()}\'S SETTINGS'),
            const SizedBox(height: 8),
            _buildSettingsCard([
              _buildInfoTile(
                icon: Icons.save_outlined,
                title: 'Save audio messages',
                value: conversation.otherAllowsAudioSave ? 'Allowed' : 'Not allowed',
                valueColor: conversation.otherAllowsAudioSave
                    ? AppColors.success
                    : AppColors.textSecondary,
              ),
            ]),
            const SizedBox(height: 24),
          ],

          // Actions Section
          _buildSectionHeader('ACTIONS'),
          const SizedBox(height: 8),
          _buildSettingsCard([
            _buildActionTile(
              icon: Icons.share_outlined,
              title: 'Share Profile',
              onTap: () => _shareProfile(conversation),
            ),
            _buildDivider(),
            _buildActionTile(
              icon: Icons.block,
              title: conversation?.isBlocked == true ? 'Unblock User' : 'Block User',
              titleColor: AppColors.error,
              onTap: () => _handleBlock(conversation),
            ),
            _buildDivider(),
            _buildActionTile(
              icon: Icons.flag_outlined,
              title: 'Report',
              titleColor: AppColors.error,
              onTap: () => _showReportDialog(conversation),
            ),
          ]),

          const SizedBox(height: 24),

          // Delete Conversation
          _buildSettingsCard([
            _buildActionTile(
              icon: Icons.delete_outline,
              title: 'Delete Conversation',
              titleColor: AppColors.error,
              onTap: () => _confirmDeleteConversation(conversation),
            ),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(ConversationModel? conversation) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: conversation?.avatarUrl != null
                ? ClipOval(
                    child: Image.network(
                      conversation!.avatarUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Text(
                          conversation.initials,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 28,
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      (conversation?.otherUserName ?? widget.userName).isNotEmpty
                          ? (conversation?.otherUserName ?? widget.userName)
                              .split(' ')
                              .map((e) => e.isNotEmpty ? e[0] : '')
                              .take(2)
                              .join()
                              .toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            conversation?.otherUserName ?? widget.userName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          if (conversation?.specialization != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                conversation!.specialization!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(height: 16),
          // View Profile Button
          OutlinedButton(
            onPressed: () {
              final userId = conversation?.otherUserId ?? widget.otherUserId;
              if (userId != null) {
                context.push('/contact/$userId');
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const Text('View Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppColors.surfaceLight,
      indent: 56,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      subtitle: subtitle != null
          ? Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      trailing: GestureDetector(
        onTap: () => _showDropdownPicker(options, value, onChanged),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
      trailing: Text(
        value,
        style: TextStyle(
          color: valueColor ?? AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: titleColor ?? AppColors.textSecondary),
      title: Text(title, style: TextStyle(color: titleColor ?? AppColors.textPrimary)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
    );
  }

  String _getDisappearingText(int? hours) {
    if (hours == null) return 'Never';
    if (hours == 1) return '1 Hour';
    if (hours == 24) return '24 Hours';
    if (hours == 168) return '1 Week';
    return '$hours Hours';
  }

  int? _parseDisappearingHours(String text) {
    switch (text) {
      case '1 Hour':
        return 1;
      case '24 Hours':
        return 24;
      case '1 Week':
        return 168;
      default:
        return null;
    }
  }

  void _showDropdownPicker(
    List<String> options,
    String currentValue,
    ValueChanged<String> onChanged,
  ) {
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
            ...options.map((option) => ListTile(
                  title: Text(option, style: const TextStyle(color: AppColors.textPrimary)),
                  trailing: option == currentValue
                      ? const Icon(Icons.check, color: AppColors.primary)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    onChanged(option);
                  },
                )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _updateDisappearing(String value, ConversationModel? conversation) {
    if (conversation == null) return;

    final hours = _parseDisappearingHours(value);
    ref.read(conversationsProvider.notifier).updateSettings(
      conversationId: conversation.conversationId,
      disappearingHours: hours,
    );
  }

  void _shareProfile(ConversationModel? conversation) {
    // Share profile - could open share sheet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share feature coming soon')),
    );
  }

  void _handleBlock(ConversationModel? conversation) {
    if (conversation == null) return;

    final isBlocked = conversation.isBlocked;
    final otherUserId = conversation.otherUserId;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          isBlocked ? 'Unblock User?' : 'Block User?',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          isBlocked
              ? 'Unblock ${widget.userName}? You will be able to send and receive messages again.'
              : 'Block ${widget.userName}? They won\'t be able to send you messages.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  final blockedProvider = ref.read(blockedUsersProvider.notifier);

                  bool success;
                  if (isBlocked) {
                    success = await blockedProvider.unblockUser(otherUserId);
                  } else {
                    success = await blockedProvider.blockUser(otherUserId);
                  }

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          success
                              ? (isBlocked ? 'User unblocked' : 'User blocked')
                              : 'Failed to ${isBlocked ? 'unblock' : 'block'} user',
                        ),
                        backgroundColor: success ? AppColors.success : AppColors.error,
                      ),
                    );

                    if (success && !isBlocked) {
                      context.pop(); // Go back to chat list
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isBlocked ? AppColors.primary : AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: Text(isBlocked ? 'Unblock' : 'Block'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showReportDialog(ConversationModel? conversation) {
    if (conversation == null) return;

    String? selectedReason;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Report User', style: TextStyle(color: AppColors.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Why are you reporting this user?',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ...['spam', 'harassment', 'inappropriate_content', 'impersonation', 'privacy_violation', 'other']
                  .map((reason) => RadioListTile<String>(
                        title: Text(
                          _formatReportReason(reason),
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                        value: reason,
                        groupValue: selectedReason,
                        activeColor: AppColors.primary,
                        onChanged: (value) => setState(() => selectedReason = value),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      )),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: selectedReason == null
                      ? null
                      : () async {
                          Navigator.pop(context);

                          final reportId = await ref
                              .read(blockedUsersProvider.notifier)
                              .reportUser(
                                userId: conversation.otherUserId,
                                reason: selectedReason!,
                              );

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  reportId != null
                                      ? 'Report submitted. Thank you.'
                                      : 'Failed to submit report',
                                ),
                                backgroundColor:
                                    reportId != null ? AppColors.success : AppColors.error,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Report'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatReportReason(String reason) {
    switch (reason) {
      case 'spam':
        return 'Spam';
      case 'harassment':
        return 'Harassment or bullying';
      case 'inappropriate_content':
        return 'Inappropriate content';
      case 'impersonation':
        return 'Impersonation';
      case 'privacy_violation':
        return 'Privacy violation';
      case 'other':
        return 'Other';
      default:
        return reason;
    }
  }

  void _confirmDeleteConversation(ConversationModel? conversation) {
    if (conversation == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Conversation?', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Delete your conversation with ${widget.userName}? This action cannot be undone.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);

                  final success = await ref
                      .read(conversationsProvider.notifier)
                      .deleteConversation(conversation.conversationId);

                  if (mounted) {
                    if (success) {
                      context.go('/home'); // Go back to home
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to delete conversation'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
