import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';
import '../../data/models/auth_state_model.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  const OtpScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  // Simple string to store OTP - no controller
  String _otpCode = '';
  bool _isProcessing = false;
  bool _hasNavigated = false;
  
  // Use nullable FocusNode to avoid disposal issues
  FocusNode? _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    // Auto-focus on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNode != null) {
        _focusNode!.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    // Set to null before dispose to prevent access during disposal
    final node = _focusNode;
    _focusNode = null;
    // Dispose in next microtask to avoid timing issues
    Future.microtask(() {
      try {
        node?.dispose();
      } catch (_) {
        // Ignore disposal errors
      }
    });
    super.dispose();
  }

  void _onOtpChanged(String value) {
    if (_hasNavigated) return;
    
    // Only allow digits and limit to OTP length
    final filtered = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (filtered.length <= AppConfig.otpLength) {
      setState(() {
        _otpCode = filtered;
      });
    }
  }

  Future<void> _verifyAndNavigate() async {
    if (_isProcessing || _hasNavigated) return;
    
    if (_otpCode.length != AppConfig.otpLength) {
      _showMessage('Please enter ${AppConfig.otpLength}-digit code', Colors.orange);
      return;
    }

    setState(() => _isProcessing = true);
    
    // Store the OTP code locally before any async operations
    final otpCodeToVerify = _otpCode;
    
    // Unfocus keyboard
    FocusScope.of(context).unfocus();

    // Verify OTP
    final success = await ref.read(otpStateProvider.notifier).verifyOtp(
      phoneNumber: widget.phoneNumber,
      otpCode: otpCodeToVerify,
    );

    // Check if we should continue
    if (!mounted || _hasNavigated) return;

    if (success) {
      // Mark as navigated IMMEDIATELY to prevent any further processing
      _hasNavigated = true;
      
      // Check profile status
      bool profileExists = false;
      try {
        profileExists = await ref.read(authStateProvider.notifier).hasCompletedProfile();
        if (AppConfig.debugMode) {
          print('📊 Profile check result: $profileExists');
        }
      } catch (e) {
        if (AppConfig.debugMode) {
          print('⚠️ Profile check error (assuming no profile): $e');
        }
        profileExists = false;
      }

      // Final mounted check before navigation
      if (!mounted) return;

      final destination = profileExists ? '/home' : '/create-profile';
      
      if (AppConfig.debugMode) {
        print('🚀 Navigating to: $destination');
      }

      // Navigate using WidgetsBinding to ensure it happens after this frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.go(destination);
        }
      });
    } else {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showMessage(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onResend() async {
    final success = await ref.read(otpStateProvider.notifier).resendOtp(widget.phoneNumber);
    if (success && mounted) {
      _showMessage(AppConfig.successMessages['otp_resent']!, Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpStateProvider);
    final isVerifying = otpState.status == OtpStatus.verifying || _isProcessing;
    final canResend = otpState.canResend && otpState.status != OtpStatus.sending;
    final remainingSeconds = otpState.remainingSeconds;

    // Listen for errors
    ref.listen<OtpStateModel>(otpStateProvider, (previous, next) {
      if (next.status == OtpStatus.error && next.errorMessage != null) {
        _showMessage(next.errorMessage!, Colors.red);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: BackButton(color: AppColors.textPrimary),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            if (_focusNode != null && mounted) {
              _focusNode!.requestFocus();
            }
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(20),
                
                Text(
                  'Enter Confirmation\nCode',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

                const Gap(10),

                RichText(
                  text: TextSpan(
                    text: 'Enter the code we sent to ',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                    children: [
                      TextSpan(
                        text: "+91 ${widget.phoneNumber}",
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const Gap(40),

                // OTP Input with visible boxes and hidden TextField
                _buildOtpInput(),

                const Gap(24),

                PrimaryButton(
                  text: isVerifying ? 'Verifying...' : 'Verify',
                  onPressed: isVerifying || _hasNavigated ? null : _verifyAndNavigate,
                ),

                const Spacer(),

                Center(
                  child: Column(
                    children: [
                      if (otpState.attemptsLeft < AppConfig.maxOtpAttempts)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Text(
                            'Attempts left: ${otpState.attemptsLeft}',
                            style: TextStyle(
                              color: otpState.attemptsLeft <= 1 
                                  ? Colors.red 
                                  : AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      
                      TextButton(
                        onPressed: canResend ? _onResend : null,
                        child: Text(
                          canResend 
                              ? "Resend Code" 
                              : "Resend in ${remainingSeconds}s",
                          style: TextStyle(
                            color: canResend 
                                ? AppColors.primary 
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const Gap(20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpInput() {
    return Stack(
      children: [
        // Visible OTP boxes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(AppConfig.otpLength, (index) {
            final hasValue = index < _otpCode.length;
            final isCurrentIndex = index == _otpCode.length;
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 48,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrentIndex
                      ? AppColors.primary
                      : (hasValue 
                          ? AppColors.primary.withOpacity(0.5) 
                          : AppColors.divider),
                  width: isCurrentIndex ? 2 : 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  hasValue ? _otpCode[index] : '',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
            );
          }),
        ),
        
        // Hidden TextField - completely transparent but captures input
        if (_focusNode != null)
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: EditableText(
                focusNode: _focusNode!,
                controller: _InternalTextController(
                  text: _otpCode,
                  onChanged: _onOtpChanged,
                ),
                cursorColor: Colors.transparent,
                backgroundCursorColor: Colors.transparent,
                style: const TextStyle(color: Colors.transparent),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(AppConfig.otpLength),
                ],
              ),
            ),
          ),
      ],
    ).animate().fadeIn(delay: 300.ms).scale();
  }
}

/// Custom controller that doesn't need disposal management
class _InternalTextController extends TextEditingController {
  final void Function(String) onChanged;
  
  _InternalTextController({
    required String text,
    required this.onChanged,
  }) : super(text: text);

  @override
  set value(TextEditingValue newValue) {
    final oldText = text;
    super.value = newValue;
    if (text != oldText) {
      onChanged(text);
    }
  }
}
