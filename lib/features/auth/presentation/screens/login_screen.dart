import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_provider.dart';
import '../../data/models/auth_state_model.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _countryCode = '+91';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onContinue() async {
    if (_formKey.currentState!.validate()) {
      final phoneNumber = _phoneController.text.trim();
      final fullNumber = _countryCode + phoneNumber;
      
      // Send OTP via Supabase + Twilio
      final success = await ref.read(otpStateProvider.notifier).sendOtp(fullNumber);
      
      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppConfig.successMessages['otp_sent']!),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        
        // Navigate to OTP screen
        context.push('/otp', extra: {'phone': fullNumber});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listen to OTP state for loading and errors
    final otpState = ref.watch(otpStateProvider);
    final isLoading = otpState.status == OtpStatus.sending;
    
    // Show error if present
    ref.listen<OtpStateModel>(otpStateProvider, (previous, next) {
      if (next.status == OtpStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(leading: BackButton(color: AppColors.textPrimary)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Gap(20),
                Text(
                  "What's your\nmobile number?",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0),

                const Gap(40),

                // Phone Input
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8, // reduced padding for picker
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      CountryCodePicker(
                        onChanged: (country) {
                          setState(() {
                            _countryCode = country.dialCode ?? '+91';
                          });
                        },
                        initialSelection: 'IN',
                        favorite: const ['+91', 'US'],
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: false,
                        alignLeft: false,
                        padding: EdgeInsets.zero,
                        flagWidth: 24,
                        textStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                        // Dialog Theme
                        dialogBackgroundColor: AppColors.surface,
                        barrierColor: Colors.black.withOpacity(0.5),
                        dialogTextStyle: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                        closeIcon: const Icon(Icons.close, color: AppColors.textPrimary),
                        searchStyle: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                        ),
                        searchDecoration: InputDecoration(
                          hintText: 'Search country',
                          hintStyle: const TextStyle(color: AppColors.textSecondary),
                          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                          filled: true,
                          fillColor: AppColors.inputBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                      Container(width: 1, height: 24, color: AppColors.divider),
                      const Gap(12),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                          decoration: const InputDecoration(
                            hintText: 'Mobile Number',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your phone number';
                            }
                            // Local validation (AppConfig handles full number validation internally now)
                            if (value.length < 7) { 
                              return AppConfig.errorMessages['invalid_phone'];
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),

                const Spacer(),

                // Disclaimer
                Center(
                  child: Text(
                    "We'll send you a verification code.",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const Gap(20),

                PrimaryButton(
                  text: isLoading ? 'Sending...' : 'Continue',
                  onPressed: isLoading ? null : _onContinue,
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.5, end: 0),

                const Gap(20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
