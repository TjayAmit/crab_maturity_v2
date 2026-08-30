import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:crab_maturity_ml_app/core/models/crab_model.dart';
import 'package:crab_maturity_ml_app/home/pages/crab_detail_view.dart';
import 'package:flutter/material.dart';
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

class ScanController extends GetxController with WidgetsBindingObserver {
  CameraController? cameraController;
  final double confidenceThreshold = 0.30;

  final crab = Rxn<Crab>();
  final confidence = RxnDouble();
  final confidenceLevel = RxnString();

  final scanPhase = ScanPhase.idle.obs;

  final isCameraInitialized = false.obs;
  final permissionGranted = false.obs;
  final errorMessage = RxnString();
  final capturedImage = Rxn<XFile>();

  Interpreter? interpreter;
  final isModelLoaded = false.obs;

  final predictedClass = RxnString();

  final maxAttempts = 7;
  List<String> classNames = [];

  bool get isScanning => scanPhase.value != ScanPhase.idle;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    loadModel();
    checkPermission();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController?.dispose();
    cameraController = null;
    interpreter?.close();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      cameraController?.dispose();
      cameraController = null;
      isCameraInitialized.value = false;
    } else if (state == AppLifecycleState.resumed) {
      if (permissionGranted.value) {
        initCamera();
      }
    }
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
      // Model loading fallback - remote API is primary
      isModelLoaded.value = true;
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
            'Camera permission is required. Please enable it in system settings.';
      }
    }
  }

  Future<void> initCamera() async {
    try {
      isCameraInitialized.value = false;
      if (cameraController != null) {
        await cameraController!.dispose();
        cameraController = null;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        errorMessage.value = 'No camera found on this device.';
        return;
      }

      final backCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      cameraController = controller;
      isCameraInitialized.value = true;
      errorMessage.value = null;
    } catch (e) {
      errorMessage.value = 'Failed to initialize camera. Tap Retry.';
    }
  }

  void resetScanState() {
    capturedImage.value = null;
    scanPhase.value = ScanPhase.idle;
    errorMessage.value = null;
  }

  // ================= SCAN FLOW =================

  Future<void> startScanAndSubmit() async {
    if (isScanning) return;

    scanPhase.value = ScanPhase.scanning;
    errorMessage.value = null;
    capturedImage.value = null;
    crab.value = null;
    predictedClass.value = null;

    try {
      // ── 1. Capture photo ────────────────────────────────
      final XFile? imageFile = await _safeTakePicture();
      if (imageFile == null) {
        throw Exception('Failed to capture photo. Please try again.');
      }

      // Freeze frame via Flutter UI overlay without touching native Camera2 stream
      capturedImage.value = imageFile;

      scanPhase.value = ScanPhase.identifying;
      await Future.delayed(const Duration(milliseconds: 300));

      // ── 2. Send to backend ──────────────────────────────
      scanPhase.value = ScanPhase.fetchingData;
      await submitScanResult(image: imageFile);

      // ── 3. Success ──────────────────────────────────────
      if (crab.value != null) {
        await Get.to(() => CrabDetailView(
              crab: crab.value!,
              confidence: confidence.value ?? 0.0,
              imageFile: imageFile,
            ));
        // Reset image overlay when returning from detail page
        resetScanState();
      } else {
        errorMessage.value = 'No crab identified from image. Try another angle.';
      }
    } catch (e) {
      errorMessage.value =
          e.toString().replaceAll('Exception: ', '').split('\n').first;
    } finally {
      scanPhase.value = ScanPhase.idle;
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

  Future<void> submitScanResult({
    required XFile image,
  }) async {
    try {
      final uri = Uri.parse('https://crabwatch.online/api/crabs-by-image');

      // Create multipart request
      final request = http.MultipartRequest('POST', uri)
        ..files.add(
          await http.MultipartFile.fromPath(
            'file',
            image.path,
            filename: image.name.isNotEmpty ? image.name : 'crab_scan.jpg',
            contentType: MediaType('image', 'jpeg'),
          ),
        )
        ..headers.addAll({
          'Accept': 'application/json',
        });

      // Send the request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception(
              'Connection timed out. Please check your internet connection.');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        try {
          final errorJson = jsonDecode(response.body);
          final msg = errorJson['message'] ?? errorJson['error'];
          if (msg != null) throw Exception(msg);
        } catch (e) {
          if (e is Exception && !e.toString().contains('FormatException')) {
            rethrow;
          }
        }
        throw Exception('Server error (${response.statusCode})');
      }

      final decoded = jsonDecode(response.body);

      if (decoded['data'] == null) {
        throw Exception('No crab classification data returned');
      }

      crab.value = Crab.fromJson(decoded['data']);

      final rawConf = decoded['confidence'];
      if (rawConf != null) {
        final double parsedConf = (rawConf as num).toDouble();
        confidence.value = parsedConf <= 1.0 ? parsedConf * 100.0 : parsedConf;
      } else {
        confidence.value = 0.0;
      }

      confidenceLevel.value = decoded['confidence_level'];
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ================= LOCAL ML =================

  Future<Map<String, dynamic>?> captureAndInfer() async {
    if (!isModelLoaded.value ||
        cameraController == null ||
        !cameraController!.value.isInitialized) {
      return null;
    }

    try {
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
    } catch (e) {
      return null;
    }
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
}
