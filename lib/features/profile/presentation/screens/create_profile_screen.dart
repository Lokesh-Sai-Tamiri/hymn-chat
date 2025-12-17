import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/colors.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../data/models/profile_model.dart';
import '../providers/profile_provider.dart';

class CreateProfileScreen extends ConsumerStatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  ConsumerState<CreateProfileScreen> createState() =>
      _CreateProfileScreenState();
}

class _CreateProfileScreenState extends ConsumerState<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _doctorIdController = TextEditingController();
  final _clinicNameController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  
  String? _selectedSpecialization;
  bool _isLoading = false;

  final List<String> _specializations = [
    'General Physician',
    'Cardiologist',
    'Neurologist',
    'Pediatrician',
    'Surgeon',
    'Dermatologist',
    'Psychiatrist',
    'Orthopedist',
    'Ophthalmologist',
    'Dentist',
    'Gynecologist',
    'ENT Specialist',
    'Other',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _doctorIdController.dispose();
    _clinicNameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = SupabaseService.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Create profile model
      final profile = ProfileModel(
        id: user.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        displayName: '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        email: _emailController.text.trim(),
        phone: user.phone,
        doctorId: _doctorIdController.text.trim().isEmpty 
            ? null 
            : _doctorIdController.text.trim(),
        specialization: _selectedSpecialization,
        clinicName: _clinicNameController.text.trim().isEmpty 
            ? null 
            : _clinicNameController.text.trim(),
        addressLine1: _addressLine1Controller.text.trim().isEmpty 
            ? null 
            : _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim().isEmpty 
            ? null 
            : _addressLine2Controller.text.trim(),
        city: _cityController.text.trim().isEmpty 
            ? null 
            : _cityController.text.trim(),
        state: _stateController.text.trim().isEmpty 
            ? null 
            : _stateController.text.trim(),
        postalCode: _postalCodeController.text.trim().isEmpty 
            ? null 
            : _postalCodeController.text.trim(),
        country: 'India',
        profileCompleted: true,
      );

      // Save profile
      final success = await ref.read(profileNotifierProvider.notifier).saveProfile(profile);

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppConfig.successMessages['profile_created']!),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );

        // Navigate to home after frame
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.go('/home');
          }
        });
      } else if (mounted) {
        throw Exception('Failed to save profile');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Tell us about yourself',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ).animate().fadeIn(),
                
                const Gap(8),
                
                Text(
                  'This information will be visible to your contacts',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const Gap(32),

                // === BASIC INFO SECTION ===
                _buildSectionTitle('Basic Information'),
                const Gap(16),

                // First Name
                _buildTextField(
                  controller: _firstNameController,
                  label: 'First Name',
                  icon: Icons.person_outline,
                  validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                  delay: 0,
                ),
                const Gap(16),

                // Last Name
                _buildTextField(
                  controller: _lastNameController,
                  label: 'Last Name',
                  icon: Icons.person_outline,
                  validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                  delay: 50,
                ),
                const Gap(16),

                // Email
                _buildTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v?.trim().isEmpty == true) return 'Required';
                    if (!v!.contains('@')) return 'Invalid email';
                    return null;
                  },
                  delay: 100,
                ),

                const Gap(32),

                // === PROFESSIONAL INFO SECTION ===
                _buildSectionTitle('Professional Details (Optional)'),
                const Gap(16),

                // Doctor ID
                _buildTextField(
                  controller: _doctorIdController,
                  label: 'Doctor/Medical ID',
                  icon: Icons.badge_outlined,
                  delay: 150,
                ),
                const Gap(16),

                // Specialization
                DropdownButtonFormField<String>(
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Specialization',
                    prefixIcon: const Icon(
                      Icons.local_hospital_outlined,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  items: _specializations.map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedSpecialization = v),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),
                const Gap(16),

                // Clinic Name
                _buildTextField(
                  controller: _clinicNameController,
                  label: 'Clinic/Hospital Name',
                  icon: Icons.local_hospital,
                  delay: 250,
                ),

                const Gap(32),

                // === ADDRESS SECTION ===
                _buildSectionTitle('Address (Optional)'),
                const Gap(16),

                // Address Line 1
                _buildTextField(
                  controller: _addressLine1Controller,
                  label: 'Address Line 1',
                  icon: Icons.home_outlined,
                  delay: 300,
                ),
                const Gap(16),

                // Address Line 2
                _buildTextField(
                  controller: _addressLine2Controller,
                  label: 'Address Line 2',
                  icon: Icons.home_outlined,
                  delay: 320,
                ),
                const Gap(16),

                // City & State Row
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _cityController,
                        label: 'City',
                        icon: Icons.location_city,
                        delay: 340,
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: _buildTextField(
                        controller: _stateController,
                        label: 'State',
                        icon: Icons.map_outlined,
                        delay: 360,
                      ),
                    ),
                  ],
                ),
                const Gap(16),

                // Postal Code
                _buildTextField(
                  controller: _postalCodeController,
                  label: 'Postal Code',
                  icon: Icons.pin_drop_outlined,
                  keyboardType: TextInputType.number,
                  delay: 380,
                ),

                const Gap(40),

                // Submit Button
                PrimaryButton(
                  text: _isLoading ? 'Saving...' : 'Complete Profile',
                  onPressed: _isLoading ? null : _onContinue,
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3, end: 0),

                const Gap(20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ).animate().fadeIn().slideX(begin: -0.1, end: 0);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int delay = 0,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
      validator: validator,
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideY(begin: 0.1, end: 0);
  }
}
