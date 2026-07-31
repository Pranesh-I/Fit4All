// lib/services/face_service.dart
// SAI Sports Talent Assessment - Face Embedding Service
// Uses MediaPipe Face Detection + FaceNet TFLite

import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceService {
  static const String _modelPath = 'assets/models/facenet.tflite';
  static const int _inputSize = 160;      // FaceNet input: 160x160
  static const int _embeddingSize = 512;  // FaceNet output: 512-d vector

  late final FaceDetector _faceDetector;
  Interpreter? _interpreter;

  FaceService() {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        enableClassification: true,
        enableLandmarks: true,
        minFaceSize: 0.15,
        performanceMode: FaceDetectorMode.accurate,
      ),
    );
  }

  // ── Initialization ────────────────────────────────────────────

  Future<void> initialize() async {
    print("Loading FaceNet model...");
    _interpreter = await Interpreter.fromAsset(_modelPath);
    print("FaceNet model loaded successfully!");
  }

  // ── Core: Generate 512-d Embedding from Camera Image ─────────

  /// Process a camera image file and return a 512-d FaceNet embedding.
  /// 
  /// Steps:
  /// 1. Detect face using MediaPipe
  /// 2. Crop and align face region
  /// 3. Run through FaceNet TFLite model
  /// 4. Return normalized 512-d embedding
  /// 
  /// Privacy: Only the embedding is returned; the image is never sent to backend.
  Future<List<double>> generateEmbedding(File imageFile) async {
    if (_interpreter == null) {
      throw Exception('FaceNet model not initialized. Call initialize() first.');
    }

    // 1. Detect faces using ML Kit
    final inputImage = InputImage.fromFile(imageFile);
    final faces = await _faceDetector.processImage(inputImage);

    if (faces.isEmpty) {
      throw FaceDetectionException(
        'No face detected. Please ensure your face is clearly visible, '
        'with adequate lighting and face the camera directly.',
      );
    }

    if (faces.length > 1) {
      throw FaceDetectionException(
        'Multiple faces detected. Please ensure only one face is visible.',
      );
    }

    final face = faces.first;

    // Validate face quality
    if (face.headEulerAngleY != null && face.headEulerAngleY!.abs() > 30) {
      throw FaceDetectionException(
        'Please face the camera directly. Avoid turning your head sideways.',
      );
    }

    // 2. Load and decode image
    final bytes = await imageFile.readAsBytes();
    final rawImage = img.decodeImage(bytes);
    if (rawImage == null) {
      throw Exception('Failed to decode image file.');
    }

    // 3. Crop face bounding box with padding
    final boundingBox = face.boundingBox;
    final padding = (boundingBox.width * 0.2).toInt();
    final x = math.max(0, boundingBox.left.toInt() - padding);
    final y = math.max(0, boundingBox.top.toInt() - padding);
    final w = math.min(
      rawImage.width - x,
      boundingBox.width.toInt() + padding * 2,
    );
    final h = math.min(
      rawImage.height - y,
      boundingBox.height.toInt() + padding * 2,
    );

    final croppedFace = img.copyCrop(rawImage, x: x, y: y, width: w, height: h);

    // 4. Resize to FaceNet input size (160x160)
    final resized = img.copyResize(
      croppedFace,
      width: _inputSize,
      height: _inputSize,
      interpolation: img.Interpolation.cubic,
    );

    // 5. Preprocess: normalize to [-1, 1]
    final input = _preprocessImage(resized);

    // 6. Run FaceNet inference
    final outputShape = [1, _embeddingSize];
    final output = List.generate(
      outputShape[0],
      (_) => List.filled(outputShape[1], 0.0),
    );

    _interpreter!.run(input, output);

    // 7. L2-normalize the embedding vector
    final rawEmbedding = output[0];
    return _l2Normalize(rawEmbedding);
  }

  // ── Preprocessing ─────────────────────────────────────────────

  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    final input = List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = image.getPixel(x, y);
            // Normalize RGB to [-1, 1] — FaceNet standard preprocessing
            return [
              (pixel.r.toDouble() - 127.5) / 128.0,
              (pixel.g.toDouble() - 127.5) / 128.0,
              (pixel.b.toDouble() - 127.5) / 128.0,
            ];
          },
        ),
      ),
    );
    return input;
  }

  // ── L2 Normalization ─────────────────────────────────────────

  List<double> _l2Normalize(List<double> vector) {
    double norm = 0.0;
    for (final v in vector) {
      norm += v * v;
    }
    norm = math.sqrt(norm);
    if (norm == 0) return vector;
    return vector.map((v) => v / norm).toList();
  }

  // ── Validation ────────────────────────────────────────────────

  bool validateEmbedding(List<double> embedding) {
    if (embedding.length != _embeddingSize) return false;
    if (embedding.every((v) => v == 0.0)) return false;
    if (embedding.any((v) => v.isNaN || v.isInfinite)) return false;
    return true;
  }

  // ── Cleanup ───────────────────────────────────────────────────

  void dispose() {
    _faceDetector.close();
    _interpreter?.close();
  }
}

// ── Custom Exceptions ─────────────────────────────────────────

class FaceDetectionException implements Exception {
  final String message;
  const FaceDetectionException(this.message);

  @override
  String toString() => message;
}
