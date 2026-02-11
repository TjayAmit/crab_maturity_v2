import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:crab_maturity_ml_app/core/models/crab_model.dart';
import 'package:crab_maturity_ml_app/home/pages/crab_detail_view.dart';
import 'package:http_parser/http_parser.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:get/get.dart';

enum ScanPhase {
  idle,
  scanning,
  identifying,
  fetchingData,
}

class ScanController extends GetxController {
  CameraController? cameraController;
  final double confidenceThreshold = 0.30;

  final crab = Rxn<Crab>();
  final confidence = RxnDouble(); // 0–100 (backend)
  final confidenceLevel = RxnString();

  final scanPhase = ScanPhase.idle.obs;

  final isCameraInitialized = false.obs;
  final permissionGranted = false.obs;
  final errorMessage = RxnString();
  final capturedImage = Rxn<XFile>();
  final cameraClosed = false.obs;
  final isPreviewActive = true.obs;

  Interpreter? interpreter;
  final isModelLoaded = false.obs;

  final predictedClass = RxnString();

  final maxAttempts = 7;
  List<String> classNames = [];

  bool get isScanning => scanPhase.value != ScanPhase.idle;

  @override
  void onInit() {
    super.onInit();
    loadModel();
    checkPermission();
  }

  // ================= MODEL =================

  Future<void> loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset(
        'assets/tflite/crab_classifier.tflite',
      );

      final classNamesData =
          await rootBundle.loadString('assets/tflite/class_names.txt');

      classNames = classNamesData
          .split('\n')
          .where((e) => e.isNotEmpty)
          .toList();

      isModelLoaded.value = true;
    } catch (e) {
      errorMessage.value = 'Failed to load AI model';
    }
  }

  // ================= CAMERA =================

  Future<void> checkPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      permissionGranted.value = true;
      await initCamera();
    } else {
      final result = await Permission.camera.request();
      if (result.isGranted) {
        permissionGranted.value = true;
        await initCamera();
      } else {
        errorMessage.value =
            'Camera permission denied. Enable it in settings.';
      }
    }
  }

  Future<void> initCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera =
          cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);

      cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await cameraController!.initialize();
      isCameraInitialized.value = true;
      isPreviewActive.value = true;
    } catch (e) {
      errorMessage.value = 'Failed to initialize camera';
    }
  }

  // ================= SCAN FLOW =================
  Future<void> startScanAndSubmit() async {
    if (isScanning) return;

    scanPhase.value = ScanPhase.scanning;
    errorMessage.value = null;
    capturedImage.value = null;
    crab.value = null;
    predictedClass.value = null;
    cameraClosed.value = false;

    try {
      // ── 1. Capture photo ────────────────────────────────
      final XFile? imageFile = await _safeTakePicture();
      
      if (imageFile == null) {
        throw Exception('Failed to capture image');
      }

      // Show captured image immediately
      capturedImage.value = imageFile;  
      isPreviewActive.value = false;
      cameraClosed.value = true;

      // ── 2. Close camera right after capture ─────────────
      await cameraController?.pausePreview(); // optional, helps some devices
      await cameraController?.dispose();
      cameraController = null;

      await Future.delayed(const Duration(milliseconds: 80));

      scanPhase.value = ScanPhase.identifying;

      // ── 4. Send to backend ──────────────────────────────
      scanPhase.value = ScanPhase.fetchingData;
      final result =await submitScanResult(image: imageFile);

      // ── 5. Success ──────────────────────────────────────
      if (crab.value != null) {
        Get.off(() => CrabDetailView(
          crab: result['crab'] as Crab,
          confidence: result['confidence'] as double
        ));
      } else {
        errorMessage.value = 'No crab data received from server';
      }
    } catch (e) {
      errorMessage.value = 'Error: ${e.toString().split('\n').first}';
    } finally {
      scanPhase.value = ScanPhase.idle;
      // Optional: re-init camera if you want to allow immediate re-scan
      // if (errorMessage.value != null) await initCamera();
    }
  }

  Future<XFile?> _safeTakePicture() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return null;
    }
    try {
      return await cameraController!.takePicture();
    } catch (e) {
      return null;
    }
  }

  // ================= API =================
  Future<Map<String, dynamic>> submitScanResult({
    required XFile image,
  }) async {
    try {
      final uri = Uri.parse('https://crabwatch.online/api/crabs-by-image');

      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            image.path,
            filename: image.name,
            contentType: MediaType('image', 'jpeg'),
          ),
        )
        ..headers.addAll({
          'Accept': 'application/json',
          // ❌ REMOVE Content-Type when using MultipartRequest
        });

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to submit scan: ${response.statusCode}\n${response.body}',
        );
      }

      final decoded = jsonDecode(response.body);

      final crabController = Get.find<ScanController>();
      crabController.crab.value =
          Crab.fromJson(decoded['data']);
      crabController.confidence.value =
          (decoded['meta']['confidence'] as num).toDouble();
      crabController.confidenceLevel.value =
          decoded['meta']['confidence_level'] as String;

      /// ✅ Return Map (Correct Dart syntax)
      return {
        'crab': crabController.crab.value,
        'confidence': crabController.confidence.value,
        'confidenceLevel': crabController.confidenceLevel.value,
      };

    } catch (e) {
      throw Exception('Error submitting scan: $e');
    }
  }


  // ================= LOCAL ML =================
  Future<Map<String, dynamic>?> captureAndInfer() async {
    if (!isModelLoaded.value ||
        cameraController == null ||
        !cameraController!.value.isInitialized) {
      return null;
    }

    final imageFile = await cameraController!.takePicture();
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    final resized = img.copyResize(decoded, width: 224, height: 224);
    final input = _imageToFloat32(resized).reshape([1, 224, 224, 3]);

    final output = List.filled(classNames.length, 0.0)
        .reshape([1, classNames.length]);

    interpreter!.run(input, output);

    final probs = output[0].cast<double>();
    int maxIndex = 0;
    double maxProb = probs[0];

    for (int i = 1; i < probs.length; i++) {
      if (probs[i] > maxProb) {
        maxProb = probs[i];
        maxIndex = i;
      }
    }

    predictedClass.value = classNames[maxIndex];

    return {
      'confidence': maxProb,
      'image': imageFile,
    };
  }

  Float32List _imageToFloat32(img.Image image) {
    final buffer = Float32List(224 * 224 * 3);
    int i = 0;

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final p = image.getPixel(x, y);
        buffer[i++] = (p.r / 127.5) - 1;
        buffer[i++] = (p.g / 127.5) - 1;
        buffer[i++] = (p.b / 127.5) - 1;
      }
    }
    return buffer;
  }

  @override
  void onClose() {
    cameraController?.dispose();
    interpreter?.close();
    super.onClose();
  }
}
