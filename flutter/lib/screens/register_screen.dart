// lib/screens/register_screen.dart
// SAI Sports Talent Assessment - Athlete Registration Screen
// Full multi-field form with inline validation

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../utils/validators.dart';
import '../providers/auth_provider.dart';
import 'otp_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;

  // Controllers
  final _fullNameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _districtController = TextEditingController();

  // Form state
  DateTime? _dateOfBirth;
  String? _gender;
  String? _state;
  String? _sportInterest;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  static const List<String> _genders = ['Male', 'Female', 'Other'];

  static const List<String> _states = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya',
    'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim',
    'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand',
    'West Bengal', 'Delhi', 'Jammu and Kashmir', 'Ladakh',
    'Chandigarh', 'Puducherry', 'Lakshadweep',
  ];

  static const List<String> _sports = [
    'Athletics', 'Badminton', 'Basketball', 'Boxing', 'Cricket',
    'Cycling', 'Football', 'Golf', 'Gymnastics', 'Hockey',
    'Judo', 'Kabaddi', 'Kho Kho', 'Rowing', 'Shooting',
    'Swimming', 'Table Tennis', 'Tennis', 'Volleyball', 'Weightlifting',
    'Wrestling', 'Archery', 'Aquatics',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.subtract(const Duration(days: 365 * 18)),
      firstDate: now.subtract(const Duration(days: 365 * 50)),
      lastDate: now.subtract(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primary,
              surface: AppTheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _proceedToOTP() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      _showError('Please select your date of birth');
      return;
    }
    if (_gender == null) {
      _showError('Please select your gender');
      return;
    }
    if (_state == null) {
      _showError('Please select your state');
      return;
    }
    if (_sportInterest == null) {
      _showError('Please select your sport interest');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    final mobile = Validators.formatMobile(_mobileController.text.trim());

    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final otpResponse = await authProvider.sendOTP(
        mobileNumber: mobile,
        purpose: 'register',
      );

      if (!mounted) return;

      // Store registration data in provider for later use
      authProvider.setRegistrationData(
        fullName: _fullNameController.text.trim(),
        dateOfBirth: _dateOfBirth!,
        gender: _gender!.toLowerCase(),
        mobileNumber: mobile,
        password: _passwordController.text,
        state: _state!,
        district: _districtController.text.trim(),
        sportInterest: _sportInterest!,
        heightCm: double.parse(_heightController.text),
        weightKg: double.parse(_weightController.text),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OTPScreen(
            mobileNumber: mobile,
            purpose: 'register',
            otpSessionId: otpResponse['otp_session_id'] as String,
          ),
        ),
      );
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Stack(
          children: [
            Positioned(
              top: -80,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [
                    AppTheme.accent.withOpacity(0.08),
                    Colors.transparent,
                  ]),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // App bar
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: AppTheme.textPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Athlete Registration',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Sports Authority of India',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Step counter
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Step 1 of 3',
                            style: TextStyle(
                              color: AppTheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Progress bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: LinearProgressIndicator(
                      value: 0.33,
                      backgroundColor: AppTheme.divider,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.primary),
                      minHeight: 3,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),

                  // Form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(
                                'Personal Information', Icons.person_outline),
                            const SizedBox(height: 16),

                            // Full Name
                            FadeInLeft(
                              child: TextFormField(
                                controller: _fullNameController,
                                textCapitalization: TextCapitalization.words,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary),
                                decoration: AppTheme.inputDecoration(
                                  label: 'Full Name',
                                  hint: 'As per Aadhaar card',
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: Icon(Icons.badge_outlined,
                                        color: AppTheme.textSecondary,
                                        size: 20),
                                  ),
                                ),
                                validator: Validators.validateFullName,
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Date of Birth
                            FadeInLeft(
                              delay: const Duration(milliseconds: 50),
                              child: GestureDetector(
                                onTap: _pickDateOfBirth,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceLight,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                        color: AppTheme.inputBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        color: AppTheme.textSecondary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Text(
                                          _dateOfBirth != null
                                              ? DateFormat('dd MMM yyyy')
                                                  .format(_dateOfBirth!)
                                              : 'Date of Birth',
                                          style: TextStyle(
                                            color: _dateOfBirth != null
                                                ? AppTheme.textPrimary
                                                : AppTheme.textHint,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: AppTheme.textHint,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Gender
                            FadeInLeft(
                              delay: const Duration(milliseconds: 100),
                              child: DropdownButtonFormField<String>(
                                value: _gender,
                                dropdownColor: AppTheme.surface,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14),
                                decoration: AppTheme.inputDecoration(
                                  label: 'Gender',
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: Icon(Icons.wc_outlined,
                                        color: AppTheme.textSecondary,
                                        size: 20),
                                  ),
                                ),
                                items: _genders
                                    .map((g) => DropdownMenuItem(
                                          value: g,
                                          child: Text(g),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(() => _gender = v),
                                validator: (v) =>
                                    v == null ? 'Please select gender' : null,
                              ),
                            ),

                            const SizedBox(height: 24),
                            _buildSectionHeader(
                                'Contact & Security', Icons.shield_outlined),
                            const SizedBox(height: 16),

                            // Mobile
                            FadeInLeft(
                              delay: const Duration(milliseconds: 150),
                              child: TextFormField(
                                controller: _mobileController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                style: const TextStyle(
                                    color: AppTheme.textPrimary),
                                decoration: AppTheme.inputDecoration(
                                  label: 'Mobile Number',
                                  hint: '10-digit mobile number',
                                  prefixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(width: 14),
                                      const Text('🇮🇳 +91',
                                          style: TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 13)),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 1,
                                        height: 20,
                                        color: AppTheme.inputBorder,
                                      ),
                                      const SizedBox(width: 4),
                                    ],
                                  ),
                                ),
                                validator: Validators.validateMobile,
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Password
                            FadeInLeft(
                              delay: const Duration(milliseconds: 200),
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary),
                                decoration: AppTheme.inputDecoration(
                                  label: 'Password',
                                  hint: 'Min 8 chars, uppercase, digit, symbol',
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: Icon(Icons.lock_outline_rounded,
                                        color: AppTheme.textSecondary,
                                        size: 20),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppTheme.textSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword),
                                  ),
                                ),
                                validator: Validators.validatePassword,
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Confirm password
                            FadeInLeft(
                              delay: const Duration(milliseconds: 225),
                              child: TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirm,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary),
                                decoration: AppTheme.inputDecoration(
                                  label: 'Confirm Password',
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: Icon(Icons.lock_clock_outlined,
                                        color: AppTheme.textSecondary,
                                        size: 20),
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppTheme.textSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(
                                        () => _obscureConfirm =
                                            !_obscureConfirm),
                                  ),
                                ),
                                validator: (v) =>
                                    v == null || v.isEmpty
                                        ? 'Please confirm password'
                                        : null,
                              ),
                            ),

                            const SizedBox(height: 24),
                            _buildSectionHeader(
                                'Location & Sport', Icons.place_outlined),
                            const SizedBox(height: 16),

                            // State
                            FadeInLeft(
                              delay: const Duration(milliseconds: 250),
                              child: DropdownButtonFormField<String>(
                                value: _state,
                                dropdownColor: AppTheme.surface,
                                isExpanded: true,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14),
                                decoration: AppTheme.inputDecoration(
                                  label: 'State / UT',
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: Icon(Icons.map_outlined,
                                        color: AppTheme.textSecondary,
                                        size: 20),
                                  ),
                                ),
                                items: _states
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(() => _state = v),
                                validator: (v) =>
                                    v == null ? 'Please select state' : null,
                              ),
                            ),

                            const SizedBox(height: 14),

                            // District
                            FadeInLeft(
                              delay: const Duration(milliseconds: 275),
                              child: TextFormField(
                                controller: _districtController,
                                textCapitalization: TextCapitalization.words,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary),
                                decoration: AppTheme.inputDecoration(
                                  label: 'District',
                                  hint: 'Your district',
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: Icon(Icons.location_city_outlined,
                                        color: AppTheme.textSecondary,
                                        size: 20),
                                  ),
                                ),
                                validator: (v) => Validators.validateRequired(
                                    v, 'District'),
                              ),
                            ),

                            const SizedBox(height: 14),

                            // Sport
                            FadeInLeft(
                              delay: const Duration(milliseconds: 300),
                              child: DropdownButtonFormField<String>(
                                value: _sportInterest,
                                dropdownColor: AppTheme.surface,
                                isExpanded: true,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 14),
                                decoration: AppTheme.inputDecoration(
                                  label: 'Sport Interest',
                                  prefixIcon: const Padding(
                                    padding: EdgeInsets.all(14),
                                    child: Icon(Icons.sports_outlined,
                                        color: AppTheme.textSecondary,
                                        size: 20),
                                  ),
                                ),
                                items: _sports
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _sportInterest = v),
                                validator: (v) => v == null
                                    ? 'Please select a sport'
                                    : null,
                              ),
                            ),

                            const SizedBox(height: 24),
                            _buildSectionHeader(
                                'Physical Attributes',
                                Icons.fitness_center_outlined),
                            const SizedBox(height: 16),

                            // Height & Weight row
                            FadeInLeft(
                              delay: const Duration(milliseconds: 325),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _heightController,
                                      keyboardType: const TextInputType
                                          .numberWithOptions(decimal: true),
                                      style: const TextStyle(
                                          color: AppTheme.textPrimary),
                                      decoration: AppTheme.inputDecoration(
                                        label: 'Height (cm)',
                                        hint: '170.5',
                                        prefixIcon: const Padding(
                                          padding: EdgeInsets.all(14),
                                          child: Icon(Icons.height_rounded,
                                              color: AppTheme.textSecondary,
                                              size: 20),
                                        ),
                                      ),
                                      validator: Validators.validateHeight,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _weightController,
                                      keyboardType: const TextInputType
                                          .numberWithOptions(decimal: true),
                                      style: const TextStyle(
                                          color: AppTheme.textPrimary),
                                      decoration: AppTheme.inputDecoration(
                                        label: 'Weight (kg)',
                                        hint: '68.0',
                                        prefixIcon: const Padding(
                                          padding: EdgeInsets.all(14),
                                          child: Icon(
                                              Icons.monitor_weight_outlined,
                                              color: AppTheme.textSecondary,
                                              size: 20),
                                        ),
                                      ),
                                      validator: Validators.validateWeight,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 32),

                            // Submit button
                            FadeInUp(
                              delay: const Duration(milliseconds: 400),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.accent,
                                      Color(0xFFE65C00)
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accent.withOpacity(0.35),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _proceedToOTP,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    minimumSize:
                                        const Size(double.infinity, 54),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.sms_outlined,
                                                color: Colors.white, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'Send OTP & Continue',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Login link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Already registered? ',
                                  style:
                                      TextStyle(color: AppTheme.textSecondary),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pushReplacementNamed(
                                      context, '/login'),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                        color: AppTheme.primary,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primary, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: AppTheme.divider,
          ),
        ),
      ],
    );
  }
}
