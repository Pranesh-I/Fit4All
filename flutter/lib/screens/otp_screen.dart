// lib/screens/otp_screen.dart
// SAI Sports Talent Assessment - OTP Verification Screen

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:pin_code_fields/pin_code_fields.dart';
import '../utils/app_theme.dart';
import '../providers/auth_provider.dart';
import 'face_capture_screen.dart';

class OTPScreen extends StatefulWidget {
  final String mobileNumber;
  final String purpose;
  final String? otpSessionId;
  final String? tempLoginToken;

  const OTPScreen({
    super.key,
    required this.mobileNumber,
    required this.purpose,
    this.otpSessionId,
    this.tempLoginToken,
  });

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final _otpController = TextEditingController();
  String _otpCode = '';
  bool _isLoading = false;
  int _resendCountdown = 60;
  Timer? _resendTimer;
  String? _verificationId;

  @override
  void initState() {
    super.initState();
    _startFirebaseAuth();
    _startResendTimer();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _startFirebaseAuth() async {
    setState(() => _isLoading = true);
    await firebase_auth.FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: widget.mobileNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (cred) async => _verifyWithCredential(cred),
      verificationFailed: (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showError(e.message ?? 'Verification failed');
        }
      },
      codeSent: (verificationId, _) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
          });
        }
      },
      codeAutoRetrievalTimeout: (verificationId) {
        if (mounted) setState(() => _verificationId = verificationId);
      },
    );
  }

 Future<void> _verifyWithCredential(firebase_auth.PhoneAuthCredential credential) async {
    setState(() => _isLoading = true);
    try {
      final result = await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);
      final idToken = await result.user?.getIdToken();
      if (idToken == null) throw Exception('Token retrieval failed');
      await _completeBackendVerification(idToken);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString());
      }
    }
  }

  Future<void> _verifyManualOTP() async {
    if (_otpCode.length != 6) {
      _showError('Enter the complete 6-digit OTP');
      return;
    }
    if (_verificationId == null) {
      _showError('Session expired. Tap Resend OTP.');
      return;
    }
    final credential = firebase_auth.PhoneAuthProvider.credential(
      verificationId: _verificationId!,
      smsCode: _otpCode,
    );
    await _verifyWithCredential(credential);
  }

  Future<void> _completeBackendVerification(String firebaseIdToken) async {
    try {
      final authProvider = context.read<AuthProvider>();
      
      // STEP 3 & 5 — Use otp_session_id from provider and check for null/empty
      final otpSessionIdFromProvider = authProvider.otpSessionId;
      print("VERIFYING OTP WITH SESSION: $otpSessionIdFromProvider");

      if (otpSessionIdFromProvider == null || otpSessionIdFromProvider.isEmpty) {
        throw Exception("OTP session missing. Please request OTP again.");
      }
      
      final response = await authProvider.verifyOTP(
        mobileNumber: widget.mobileNumber,
        firebaseIdToken: firebaseIdToken,
        otpSessionId: otpSessionIdFromProvider,
      );

      final bool verified = response['verification_status'] ?? false;
      
      if (!verified) {
        _showError('Backend verification failed. Try again.');
        setState(() => _isLoading = false);
        return;
      }

      // STEP 2 — Save otp_session_id after OTP verification
      final otpSessionId = response['otp_session_id'];
      authProvider.setOtpSessionId(otpSessionId);
      print("Saved OTP session ID: $otpSessionId");

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FaceCaptureScreen(
            purpose: widget.purpose,
            otpSessionId: otpSessionId,
            tempLoginToken: widget.tempLoginToken,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError(e.toString());
      }
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendCountdown = 60);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendCountdown <= 0) {
        t.cancel();
      } else if (mounted) {
        setState(() => _resendCountdown--);
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppTheme.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppTheme.textPrimary, size: 18),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Step 2 of 3',
                          style: TextStyle(color: AppTheme.accent, fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const Spacer(flex: 1),
                FadeInDown(
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [AppTheme.accent, Color(0xFFE65C00)]),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.35),
                          blurRadius: 24, offset: const Offset(0, 8))],
                    ),
                    child: const Icon(Icons.sms_rounded, color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Verify Mobile Number',
                    style: TextStyle(color: AppTheme.textPrimary, fontSize: 26,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text(
                  'OTP sent to\n${widget.mobileNumber}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 40),
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  controller: _otpController,
                  onChanged: (v) => setState(() => _otpCode = v),
                  onCompleted: (_) => _verifyManualOTP(),
                  keyboardType: TextInputType.number,
                  animationType: AnimationType.scale,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(12),
                    fieldHeight: 56, fieldWidth: 46,
                    activeFillColor: AppTheme.surfaceLight,
                    selectedFillColor: AppTheme.surfaceLight,
                    inactiveFillColor: AppTheme.surfaceLight,
                    activeColor: AppTheme.accent,
                    selectedColor: AppTheme.accent,
                    inactiveColor: AppTheme.inputBorder,
                  ),
                  enableActiveFill: true,
                  textStyle: const TextStyle(color: AppTheme.textPrimary,
                      fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppTheme.accent, Color(0xFFE65C00)]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(color: AppTheme.accent.withOpacity(0.35),
                        blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyManualOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Verify OTP',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                                color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 20),
                _resendCountdown > 0
                    ? Text('Resend OTP in ${_resendCountdown}s',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13))
                    : TextButton(
                        onPressed: () {
                          _startFirebaseAuth();
                          _startResendTimer();
                        },
                        child: const Text('Resend OTP',
                            style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600)),
                      ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
