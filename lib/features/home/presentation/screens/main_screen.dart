import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../../../../features/contacts/presentation/screens/contacts_screen.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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

  void _onRecordPressed() {
    // Open Global Voice Recording Modal
    // This will be implemented later
    print("Record Pressed");
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

          // Custom Bottom Bar
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
                    Colors.black.withOpacity(0.9),
                    Colors.black.withOpacity(0.0),
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Chat / Home Icon
                  IconButton(
                    icon: Icon(
                      Icons.chat_bubble_rounded,
                      color: _currentIndex == 0
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      size: 28,
                    ),
                    onPressed: () => _onTabTapped(0),
                  ),

                  // Record Button (Big)
                  GestureDetector(
                    onTap: _onRecordPressed,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.textPrimary,
                          width: 4,
                        ),
                        color: Colors.transparent,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),

                  // Contacts Icon
                  IconButton(
                    icon: Icon(
                      Icons.people_alt_rounded,
                      color: _currentIndex == 1
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      size: 28,
                    ),
                    onPressed: () => _onTabTapped(1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
