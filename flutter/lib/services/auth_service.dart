// lib/services/auth_service.dart
// SAI Sports Talent Assessment - API Integration Service

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/user_model.dart';

class AuthService {
  static const String _baseUrl = 'http://192.168.1.106:8000'; // Change for production
  static const String _tokenKey = 'sai_jwt_token';
  static const String _userIdKey = 'sai_user_id';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
  );

  late final Dio _dio;

  AuthService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add JWT interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // Log errors without exposing sensitive data
        return handler.next(error);
      },
    ));
  }

  // ── Token Management ──────────────────────────────────────────

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  Future<void> clearSession() async {
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ── Device ID ────────────────────────────────────────────────

  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id;
  }

  // ── OTP Flow ─────────────────────────────────────────────────

  /// Step 1a: Request OTP session from backend
  Future<Map<String, dynamic>> sendOTP({
    required String mobileNumber,
    required String purpose, // 'register' | 'login'
  }) async {
    try {
      final response = await _dio.post('/auth/send-otp', data: {
        'mobile_number': mobileNumber,
        'purpose': purpose,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Step 1b: Verify Firebase ID token with backend
  Future<Map<String, dynamic>> verifyOTP({
    required String mobileNumber,
    required String firebaseIdToken,
    required String otpSessionId,
  }) async {
    try {
      final response = await _dio.post('/auth/verify-otp', data: {
        'mobile_number': mobileNumber,
        'firebase_id_token': firebaseIdToken,
        'otp_session_id': otpSessionId,
      });
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Registration ─────────────────────────────────────────────

  /// Register new athlete with all required data + face embedding
  Future<String> register({
    required String fullName,
    required String dateOfBirth,    // 'YYYY-MM-DD'
    required String gender,
    required String mobileNumber,
    required String password,
    required String state,
    required String district,
    required String sportInterest,
    required double heightCm,
    required double weightKg,
    required List<double> faceEmbedding,
    required String otpSessionId,
  }) async {
    print("Embedding length: ${faceEmbedding.length}");
    try {
      final response = await _dio.post('/auth/register', data: {
        'full_name': fullName,
        'date_of_birth': dateOfBirth,
        'gender': gender,
        'mobile_number': mobileNumber,
        'password': password,
        'state': state,
        'district': district,
        'sport_interest': sportInterest,
        'height_cm': heightCm,
        'weight_kg': weightKg,
        'face_embedding': faceEmbedding,
        'otp_session_id': otpSessionId,
      });

      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String;
      await saveToken(token);
      return token;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Login ────────────────────────────────────────────────────

  /// Login Step 1: Password verification → temporary token
  Future<String> loginPasswordCheck({
    required String mobileNumber,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login-password-check', data: {
        'mobile_number': mobileNumber,
        'password': password,
      });
      final data = response.data as Map<String, dynamic>;
      return data['temporary_login_token'] as String;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Login Step 2: Face verification → full JWT
  Future<String> loginFaceVerify({
    required String tempToken,
    required List<double> faceEmbedding,
  }) async {
    print("Embedding length: ${faceEmbedding.length}");
    try {
      final deviceId = await getDeviceId();
      final response = await _dio.post('/auth/login-face-verify', data: {
        'temporary_login_token': tempToken,
        'face_embedding': faceEmbedding,
        'device_id': deviceId,
      });
      final data = response.data as Map<String, dynamic>;
      final token = data['access_token'] as String;
      await saveToken(token);
      return token;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Profile ──────────────────────────────────────────────────

  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get('/auth/profile');
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ── Error Handler ─────────────────────────────────────────────

  Exception _handleError(DioException e) {
    if (e.response != null) {
      final data = e.response!.data;
      String message = 'An error occurred. Please try again.';
      if (data is Map && data['detail'] != null) {
        message = data['detail'].toString();
      }
      return Exception(message);
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return Exception('Connection timed out. Check your internet connection.');
    }
    if (e.type == DioExceptionType.connectionError) {
      return Exception('Unable to connect to server. Check your network.');
    }
    return Exception('An unexpected error occurred.');
  }
}
