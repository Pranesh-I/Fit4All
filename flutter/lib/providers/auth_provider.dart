// lib/providers/auth_provider.dart
// SAI Sports Talent Assessment - Auth State Management

import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isAuthenticated = false;
  bool _isLoading = false;
  UserModel? _currentUser;
  String? _error;

  // ── Pending registration data (stored between steps) ──────────
  String? _regFullName;
  DateTime? _regDob;
  String? _regGender;
  String? _regMobile;
  String? _regPassword;
  String? _regState;
  String? _regDistrict;
  String? _regSport;
  double? _regHeight;
  double? _regWeight;
  String? otpSessionId;

  void setOtpSessionId(String id) {
    otpSessionId = id;
    notifyListeners();
  }

  // ── Getters ───────────────────────────────────────────────────
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  UserModel? get currentUser => _currentUser;
  String? get error => _error;

  // ── Auth State Check ──────────────────────────────────────────
  Future<void> checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();
    try {
      final isLoggedIn = await _authService.isLoggedIn();
      if (isLoggedIn) {
        _currentUser = await _authService.getProfile();
        _isAuthenticated = true;
      }
    } catch (_) {
      _isAuthenticated = false;
      await _authService.clearSession();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── OTP ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> sendOTP({
    required String mobileNumber,
    required String purpose,
  }) async {
    return _authService.sendOTP(mobileNumber: mobileNumber, purpose: purpose);
  }

  Future<Map<String, dynamic>> verifyOTP({
    required String mobileNumber,
    required String firebaseIdToken,
    required String otpSessionId,
  }) async {
    return _authService.verifyOTP(
      mobileNumber: mobileNumber,
      firebaseIdToken: firebaseIdToken,
      otpSessionId: otpSessionId,
    );
  }

  // ── Registration data staging ─────────────────────────────────
  void setRegistrationData({
    required String fullName,
    required DateTime dateOfBirth,
    required String gender,
    required String mobileNumber,
    required String password,
    required String state,
    required String district,
    required String sportInterest,
    required double heightCm,
    required double weightKg,
  }) {
    _regFullName = fullName;
    _regDob = dateOfBirth;
    _regGender = gender;
    _regMobile = mobileNumber;
    _regPassword = password;
    _regState = state;
    _regDistrict = district;
    _regSport = sportInterest;
    _regHeight = heightCm;
    _regWeight = weightKg;
  }

  // ── Registration ──────────────────────────────────────────────
  Future<void> register({required List<double> faceEmbedding}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // STEP 5 — Prevent empty session submission
      if (otpSessionId == null || otpSessionId!.isEmpty) {
        throw Exception("OTP session missing. Verify OTP again.");
      }

      print("Using OTP session ID: $otpSessionId");

      await _authService.register(
        fullName: _regFullName!,
        dateOfBirth: _regDob!.toIso8601String().split('T')[0],
        gender: _regGender!,
        mobileNumber: _regMobile!,
        password: _regPassword!,
        state: _regState!,
        district: _regDistrict!,
        sportInterest: _regSport!,
        heightCm: _regHeight!,
        weightKg: _regWeight!,
        faceEmbedding: faceEmbedding,
        otpSessionId: otpSessionId!,
      );
      _currentUser = await _authService.getProfile();
      _isAuthenticated = true;
      _clearRegistrationData();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Login Step 1 ──────────────────────────────────────────────
  Future<String> loginPasswordCheck({
    required String mobileNumber,
    required String password,
  }) async {
    return _authService.loginPasswordCheck(
        mobileNumber: mobileNumber, password: password);
  }

  // ── Login Step 2 ──────────────────────────────────────────────
  Future<void> loginFaceVerify({
    required String tempToken,
    required List<double> faceEmbedding,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authService.loginFaceVerify(
          tempToken: tempToken, faceEmbedding: faceEmbedding);
      _currentUser = await _authService.getProfile();
      _isAuthenticated = true;
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Logout ────────────────────────────────────────────────────
  Future<void> logout() async {
    await _authService.clearSession();
    _isAuthenticated = false;
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  void _clearRegistrationData() {
    _regFullName = null; _regDob = null; _regGender = null;
    _regMobile = null; _regPassword = null; _regState = null;
    _regDistrict = null; _regSport = null; _regHeight = null;
    _regWeight = null;
  }
}
