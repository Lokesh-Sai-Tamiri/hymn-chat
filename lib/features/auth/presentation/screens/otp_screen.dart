import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
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
  TextEditingController? _otpController;
  String _otpCode = '';
  bool _isProcessing = false;
  bool _hasNavigated = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
    _otpController!.addListener(_onControllerChange);
  }

  void _onControllerChange() {
    if (_hasNavigated || _isDisposed) return;
    final controller = _otpController;
    if (controller == null) return;
    
    final newText = controller.text;
    if (newText != _otpCode && newText.length <= AppConfig.otpLength) {
      if (mounted) {
        setState(() {
          _otpCode = newText;
        });
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    final controller = _otpController;
    _otpController = null;
    
    // Dispose in next microtask to avoid timing issues
    if (controller != null) {
      Future.microtask(() {
        try {
          controller.removeListener(_onControllerChange);
          controller.dispose();
        } catch (_) {
          // Ignore disposal errors
        }
      });
    }
    super.dispose();
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

      // Navigate using a small delay to ensure UI is stable
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        context.go(destination);
      }
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
    if (success && mounted && !_isDisposed) {
      // Clear the OTP input
      _otpController?.clear();
      setState(() {
        _otpCode = '';
      });
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
          onTap: () => FocusScope.of(context).unfocus(),
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

                // OTP Input using PinCodeTextField
                if (_otpController != null)
                PinCodeTextField(
                  appContext: context,
                  length: AppConfig.otpLength,
                  controller: _otpController!,
                  autoFocus: true,
                  enabled: !isVerifying && !_hasNavigated,
                  keyboardType: TextInputType.number,
                  animationType: AnimationType.fade,
                  animationDuration: const Duration(milliseconds: 150),
                  enableActiveFill: true,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  textStyle: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(12),
                    fieldHeight: 56,
                    fieldWidth: 48,
                    activeFillColor: AppColors.inputBackground,
                    inactiveFillColor: AppColors.inputBackground,
                    selectedFillColor: AppColors.inputBackground,
                    activeColor: AppColors.primary,
                    inactiveColor: AppColors.divider,
                    selectedColor: AppColors.primary,
                    activeBorderWidth: 2,
                    inactiveBorderWidth: 1.5,
                    selectedBorderWidth: 2,
                  ),
                  cursorColor: AppColors.primary,
                  onChanged: (value) {
                    // Already handled by controller listener
                  },
                  onCompleted: (value) {
                    // Auto-verify when all digits entered
                    if (!_isProcessing && !_hasNavigated) {
                      _verifyAndNavigate();
                    }
                  },
                  beforeTextPaste: (text) {
                    // Allow pasting only digits
                    return text != null && RegExp(r'^\d+$').hasMatch(text);
                  },
                ).animate().fadeIn(delay: 300.ms).scale(),

                const Gap(24),

                PrimaryButton(
                  text: isVerifying ? 'Verifying...' : 'Verify',
                  onPressed: isVerifying || _hasNavigated || _otpCode.length != AppConfig.otpLength 
                      ? null 
                      : _verifyAndNavigate,
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
}
