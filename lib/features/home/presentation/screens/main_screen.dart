import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../../../../features/contacts/presentation/screens/contacts_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../voice/presentation/widgets/voice_record_button.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _currentIndex = 0;
  bool _isCheckingProfile = true;
  bool _hasCheckedProfile = false;

  final List<Widget> _screens = [
    const ChatListScreen(),
    const ContactsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Check profile status after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileAndRedirect();
    });
  }

  Future<void> _checkProfileAndRedirect() async {
    if (_hasCheckedProfile) return;
    _hasCheckedProfile = true;

    try {
      final hasProfile = await ref.read(authStateProvider.notifier).hasCompletedProfile();
      
      if (AppConfig.debugMode) {
        print('🏠 MainScreen: Profile check result: $hasProfile');
      }

      if (!mounted) return;

      if (!hasProfile) {
        if (AppConfig.debugMode) {
          print('📝 MainScreen: No profile found, redirecting to create-profile');
        }
        context.go('/create-profile');
        return;
      }

      // Profile exists, show the home screen
      setState(() {
        _isCheckingProfile = false;
      });
    } catch (e) {
      if (AppConfig.debugMode) {
        print('⚠️ MainScreen: Error checking profile: $e');
      }
      // On error, redirect to create profile to be safe
      if (mounted) {
        context.go('/create-profile');
      }
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while checking profile
    if (_isCheckingProfile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Main Content
          IndexedStack(index: _currentIndex, children: _screens),

          // Custom Bottom Bar with Voice Recording
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 10,
                bottom: MediaQuery.of(context).padding.bottom + 10,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.95),
                    Colors.black.withOpacity(0.8),
                    Colors.black.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Voice Record Button (centered, with waveform)
                  const VoiceRecordButton(),
                  
                  const SizedBox(height: 16),
                  
                  // Navigation icons row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Chat / Home Icon
                      _buildNavItem(
                        icon: Icons.chat_bubble_rounded,
                        label: 'Chats',
                        isSelected: _currentIndex == 0,
                        onTap: () => _onTabTapped(0),
                      ),

                      // Spacer for center button
                      const SizedBox(width: 72),

                      // Contacts Icon
                      _buildNavItem(
                        icon: Icons.people_alt_rounded,
                        label: 'Contacts',
                        isSelected: _currentIndex == 1,
                        onTap: () => _onTabTapped(1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
