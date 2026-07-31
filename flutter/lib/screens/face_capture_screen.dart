// lib/screens/face_capture_screen.dart
// SAI Sports Talent Assessment - Face Capture + Embedding Screen

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:animate_do/animate_do.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../services/face_service.dart';
import '../providers/auth_provider.dart';

class FaceCaptureScreen extends StatefulWidget {
  final String purpose;
  final String otpSessionId;
  final String? tempLoginToken;

  const FaceCaptureScreen({
    super.key,
    required this.purpose,
    required this.otpSessionId,
    this.tempLoginToken,
  });

  @override
  State<FaceCaptureScreen> createState() => _FaceCaptureScreenState();
}

class _FaceCaptureScreenState extends State<FaceCaptureScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  // final FaceService _faceService = FaceService();
  bool _isInitialized = false;
  bool _isCapturing = false;
  bool _isProcessing = false;
  File? _capturedImage;
  List<double>? _embedding;
  String _statusMessage = 'Position your face within the oval';
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late FaceService _faceService;
  bool _modelReady = false;

  @override
  void initState() {
    super.initState();

    _faceService = FaceService();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initCamera();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    await _faceService.initialize();

    print("Model initialized!");

    if (mounted) {
      setState(() {
        _modelReady = true;
      });
    }
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras == null || _cameras!.isEmpty) {
      _updateStatus('No camera available on this device');
      return;
    }
    // Prefer front camera
    final frontCamera = _cameras!.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => _cameras!.first,
    );
    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await _cameraController!.initialize();
    if (mounted) setState(() => _isInitialized = true);
  }

  void _updateStatus(String message) {
    if (mounted) setState(() => _statusMessage = message);
  }
  
  Future<void> _captureAndProcess() async {
    if (!_modelReady) {
      _updateStatus("Face model still loading...");
      return;
    }
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_isCapturing || _isProcessing) return;

    setState(() {
      _isCapturing = true;
      _statusMessage = 'Capturing...';
    });

    try {
      final xFile = await _cameraController!.takePicture();
      final imageFile = File(xFile.path);

      setState(() {
        _capturedImage = imageFile;
        _isCapturing = false;
        _isProcessing = true;
        _statusMessage = 'Detecting face and generating embedding...';
      });

      final embedding = await _faceService.generateEmbedding(imageFile);

      if (!_faceService.validateEmbedding(embedding)) {
        throw Exception('Invalid embedding generated. Please try again.');
      }

      setState(() {
        _embedding = embedding;
        _isProcessing = false;
        _statusMessage = 'Face captured successfully! ✓';
      });
    } on FaceDetectionException catch (e) {
      setState(() {
        _isCapturing = false;
        _isProcessing = false;
        _capturedImage = null;
        _statusMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _isCapturing = false;
        _isProcessing = false;
        _capturedImage = null;
        _statusMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _submitEmbedding() async {
    if (_embedding == null) {
      _showError('Please capture your face first');
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final authProvider = context.read<AuthProvider>();

      if (widget.purpose == 'register') {
        await authProvider.register(faceEmbedding: _embedding!);
      } else {
        await authProvider.loginFaceVerify(
          tempToken: widget.tempLoginToken!,
          faceEmbedding: _embedding!,
        );
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _showError(e.toString());
      }
    }
  }

  void _retake() {
    setState(() {
      _capturedImage = null;
      _embedding = null;
      _statusMessage = 'Position your face within the oval';
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
  void dispose() {
    _cameraController?.dispose();
    _faceService.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
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
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.purpose == 'register'
                                ? 'Face Registration'
                                : 'Face Verification',
                            style: const TextStyle(color: AppTheme.textPrimary,
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          const Text('Biometric authentication',
                              style: TextStyle(color: AppTheme.textSecondary,
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Step 3 of 3',
                          style: TextStyle(color: AppTheme.primary, fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),

              // Camera / Preview
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Face oval frame
                      Expanded(
                        child: Center(
                          child: AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _embedding != null ? 1.0 : _pulseAnimation.value,
                                child: child,
                              );
                            },
                            child: Container(
                              width: screenWidth * 0.72,
                              height: screenWidth * 0.90,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(screenWidth * 0.36),
                                border: Border.all(
                                  color: _embedding != null
                                      ? AppTheme.success
                                      : _isProcessing
                                          ? AppTheme.accent
                                          : AppTheme.primary,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (_embedding != null
                                            ? AppTheme.success
                                            : AppTheme.primary)
                                        .withOpacity(0.25),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(screenWidth * 0.35),
                                child: _capturedImage != null
                                    ? Image.file(_capturedImage!, fit: BoxFit.cover)
                                    : (_isInitialized && _cameraController != null
                                        ? CameraPreview(_cameraController!)
                                        : Container(
                                            color: AppTheme.surfaceLight,
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                  color: AppTheme.primary),
                                            ),
                                          )),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Status message
                      FadeIn(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _embedding != null
                                ? AppTheme.success.withOpacity(0.1)
                                : AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _embedding != null
                                  ? AppTheme.success.withOpacity(0.3)
                                  : AppTheme.divider,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _embedding != null
                                    ? Icons.check_circle_outline
                                    : Icons.info_outline,
                                size: 16,
                                color: _embedding != null
                                    ? AppTheme.success
                                    : AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _statusMessage,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _embedding != null
                                        ? AppTheme.success
                                        : AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Privacy notice
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined,
                              color: AppTheme.textHint, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Face image is processed locally. Only embedding is stored.',
                            style: TextStyle(color: AppTheme.textHint, fontSize: 11),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Action buttons
                      if (_embedding == null) ...[
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [AppTheme.primary, AppTheme.primaryDark]),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(
                                color: AppTheme.primary.withOpacity(0.35),
                                blurRadius: 20, offset: const Offset(0, 8))],
                          ),
                          child: ElevatedButton(
                            onPressed: (_isCapturing || _isProcessing)
                                ? null
                                : _captureAndProcess,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              minimumSize: const Size(double.infinity, 54),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                            child: (_isCapturing || _isProcessing)
                                ? const SizedBox(width: 22, height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.camera_alt_outlined,
                                          color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text('Capture Face',
                                          style: TextStyle(fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white)),
                                    ],
                                  ),
                          ),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _retake,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.textSecondary,
                                  side: const BorderSide(color: AppTheme.inputBorder),
                                  minimumSize: const Size(0, 54),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Text('Retake'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                      colors: [AppTheme.success, Color(0xFF16A34A)]),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [BoxShadow(
                                      color: AppTheme.success.withOpacity(0.35),
                                      blurRadius: 16, offset: const Offset(0, 6))],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isProcessing ? null : _submitEmbedding,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    minimumSize: const Size(0, 54),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14)),
                                  ),
                                  child: _isProcessing
                                      ? const SizedBox(width: 22, height: 22,
                                          child: CircularProgressIndicator(
                                              color: Colors.white, strokeWidth: 2))
                                      : Text(
                                          widget.purpose == 'register'
                                              ? 'Complete Registration'
                                              : 'Verify & Login',
                                          style: const TextStyle(fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 32),
                    ],
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
