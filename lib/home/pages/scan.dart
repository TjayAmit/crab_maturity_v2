import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:crab_maturity_ml_app/home/pages/crab_detail_view.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _permissionGranted = false;
  String? _errorMessage;

  // TFLite variables
  Interpreter? _interpreter;
  List<String> _classNames = [];
  bool _isModelLoaded = false;
  bool _isScanning = false;

  // Inference results
  String? _predictedClass;
  double? _confidence;

  // Multi-attempt scanning
  int _currentAttempt = 0;
  final int _maxAttempts = 7;
  Map<String, double> _attemptResults = {}; // model_name -> highest confidence

  @override
  void initState() {
    super.initState();
    _loadModel();
    _checkAndRequestPermission();
  }

  // Load TFLite model and class names
  Future<void> _loadModel() async {
    try {
      // Load the TFLite model
      _interpreter = await Interpreter.fromAsset(
        'assets/tflite/crab_classifier.tflite',
      );
      print('✅ Model loaded successfully');

      // Load class names
      final classNamesData = await rootBundle.loadString(
        'assets/tflite/class_names.txt',
      );
      _classNames = classNamesData
          .split('\n')
          .where((name) => name.isNotEmpty)
          .toList();
      print('✅ Loaded ${_classNames.length} class names');

      setState(() => _isModelLoaded = true);
    } catch (e) {
      print('❌ Failed to load model: $e');
      setState(() {
        _errorMessage = 'Failed to load AI model: $e';
      });
    }
  }

  Future<void> _checkAndRequestPermission() async {
    final status = await Permission.camera.status;

    if (status.isGranted) {
      _permissionGranted = true;
      await _initializeCamera();
    } else {
      final result = await Permission.camera.request();
      if (result.isGranted) {
        _permissionGranted = true;
        await _initializeCamera();
      } else {
        setState(() {
          _errorMessage =
              'Camera permission denied. Please enable it in settings.';
        });
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      if (!mounted) return;

      setState(() => _isCameraInitialized = true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  // Start multi-attempt scanning
  Future<void> _startScanning() async {
    if (_isScanning || !_isModelLoaded || _cameraController == null) {
      print(
        'Cannot start scan: isScanning=$_isScanning, modelLoaded=$_isModelLoaded',
      );
      return;
    }

    setState(() {
      _isScanning = true;
      _currentAttempt = 0;
      _attemptResults.clear();
      _predictedClass = null;
      _confidence = null;
    });

    print('Starting scan with $_maxAttempts attempts');

    // Perform 7 attempts
    for (int i = 0; i < _maxAttempts; i++) {
      if (!mounted || !_isScanning) {
        print('Scan interrupted at attempt ${i + 1}');
        break;
      }

      setState(() => _currentAttempt = i + 1);
      print('Scan attempt ${i + 1}/$_maxAttempts');

      await _captureAndInfer();

      // Small delay between captures
      if (i < _maxAttempts - 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    print('Scan complete. Results: $_attemptResults');

    // Find the model with highest confidence across all attempts
    if (_attemptResults.isNotEmpty) {
      String bestModel = '';
      double bestConfidence = 0.0;

      _attemptResults.forEach((model, confidence) {
        if (confidence > bestConfidence) {
          bestConfidence = confidence;
          bestModel = model;
        }
      });

      print('Best result: $bestModel with $bestConfidence confidence');

      setState(() {
        _predictedClass = bestModel;
        _confidence = bestConfidence;
        _isScanning = false;
      });

      // Navigate to detail view with confidence
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CrabDetailView(model: bestModel, confidence: bestConfidence),
          ),
        ).then((_) {
          // Reset after returning
          setState(() {
            _predictedClass = null;
            _confidence = null;
            _attemptResults.clear();
          });
        });
      }
    } else {
      print('No results from scanning');
      setState(() => _isScanning = false);

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to detect crab. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Capture image and run inference
  Future<void> _captureAndInfer() async {
    if (!_isModelLoaded ||
        _cameraController == null ||
        !_cameraController!.value.isInitialized) {
      print(
        'Cannot capture: modelLoaded=$_isModelLoaded, cameraReady=${_cameraController?.value.isInitialized}',
      );
      return;
    }

    try {
      print('Taking picture...');
      final XFile imageFile = await _cameraController!.takePicture();
      print('Picture taken: ${imageFile.path}');

      final Uint8List imageBytes = await imageFile.readAsBytes();

      // Decode and preprocess image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        print('Failed to decode image');
        return;
      }

      print('Image decoded: ${image.width}x${image.height}');

      // Resize to 224x224 (matching your training size)
      img.Image resizedImage = img.copyResize(image, width: 224, height: 224);
      print('Image resized to 224x224');

      // Convert to Float32List with MobileNetV2 preprocessing
      var inputImage = _imageToByteListFloat32(resizedImage);
      print('Image preprocessed, size: ${inputImage.length}');

      // Reshape for model input: [1, 224, 224, 3]
      var input = inputImage.reshape([1, 224, 224, 3]);

      // Prepare output buffer
      var outputBuffer = List.filled(
        _classNames.length,
        0.0,
      ).reshape([1, _classNames.length]);

      // Run inference
      print('Running inference...');
      _interpreter!.run(input, outputBuffer);
      print('Inference complete');

      // Process results
      List<double> probabilities = outputBuffer[0].cast<double>();

      // Get top prediction
      int maxIndex = 0;
      double maxProb = probabilities[0];

      for (int i = 0; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }

      String predictedModel = _classNames[maxIndex];
      print('Predicted: $predictedModel with confidence $maxProb');

      // Store if this is the highest confidence for this model
      if (!_attemptResults.containsKey(predictedModel) ||
          maxProb > _attemptResults[predictedModel]!) {
        _attemptResults[predictedModel] = maxProb;
      }

      // Update current display
      if (mounted) {
        setState(() {
          _predictedClass = predictedModel;
          _confidence = maxProb;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Inference error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  // Convert image to Float32List with MobileNetV2 preprocessing
  Float32List _imageToByteListFloat32(img.Image image) {
    var convertedBytes = Float32List(1 * 224 * 224 * 3);
    int pixelIndex = 0;

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        var pixel = image.getPixel(x, y);

        // Extract RGB values
        double r = pixel.r.toDouble();
        double g = pixel.g.toDouble();
        double b = pixel.b.toDouble();

        // MobileNetV2 preprocessing: normalize to [-1, 1]
        convertedBytes[pixelIndex++] = (r / 127.5) - 1.0;
        convertedBytes[pixelIndex++] = (g / 127.5) - 1.0;
        convertedBytes[pixelIndex++] = (b / 127.5) - 1.0;
      }
    }

    return convertedBytes;
  }

  // Format model name: curacha_male -> Curacha Male
  String _formatModelName(String modelName) {
    return modelName
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _interpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _errorMessage != null
          ? _buildErrorView()
          : !_permissionGranted
          ? _buildPermissionRequestView()
          : !_isCameraInitialized || !_isModelLoaded
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : Stack(
              fit: StackFit.expand,
              children: [
                // 📸 Camera Preview
                CameraPreview(_cameraController!),

                // 🟩 Center bounding box
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _isScanning
                            ? Colors.orange
                            : Colors.white.withOpacity(0.5),
                        width: 3,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                // 📊 Top-right results overlay (minimal)
                if (_predictedClass != null && _confidence != null)
                  Positioned(
                    top: 60,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatModelName(_predictedClass!),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${(_confidence! * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: _confidence! > 0.7
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Scan progress indicator
                if (_isScanning)
                  Positioned(
                    top: 60,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Scanning $_currentAttempt/$_maxAttempts',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                // 🔘 Scan button at bottom
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          _isScanning
                              ? 'Scanning in progress...'
                              : 'Align the crab inside the box',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(color: Colors.black, blurRadius: 4),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _isScanning ? null : _startScanning,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isScanning
                                ? Colors.grey
                                : Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 8,
                            disabledBackgroundColor: Colors.grey,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isScanning
                                    ? Icons.hourglass_empty
                                    : Icons.center_focus_strong,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _isScanning ? 'Scanning...' : 'Start Scan',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          _errorMessage!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildPermissionRequestView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.camera_alt, color: Colors.orange, size: 60),
          const SizedBox(height: 20),
          const Text(
            'Camera permission required',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Please grant camera access to use the scanner.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _checkAndRequestPermission,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Grant Permission'),
          ),
        ],
      ),
    );
  }
}
