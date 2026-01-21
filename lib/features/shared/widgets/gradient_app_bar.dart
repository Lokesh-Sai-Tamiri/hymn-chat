/// ============================================================================
/// GRADIENT APP BAR - Shared Navigation Header
/// ============================================================================
/// 
/// A consistent top navigation bar with gradient background used across
/// all main screens in the app.
/// ============================================================================
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';

class GradientAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool showProfileIcon;
  final VoidCallback? onProfileTap;

  const GradientAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.showProfileIcon = true,
    this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withOpacity(0.12),
            AppColors.background,
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Title section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Trailing widget (e.g., badges, buttons)
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: 8),
              ],
              
              // Profile icon
              if (showProfileIcon)
                GestureDetector(
                  onTap: onProfileTap ?? () => context.push('/profile'),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      color: AppColors.textInverse,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A scaffold wrapper that includes the gradient app bar
class GradientScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget body;
  final bool showProfileIcon;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  const GradientScaffold({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.body,
    this.showProfileIcon = true,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      body: Column(
        children: [
          GradientAppBar(
            title: title,
            subtitle: subtitle,
            trailing: trailing,
            showProfileIcon: showProfileIcon,
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
