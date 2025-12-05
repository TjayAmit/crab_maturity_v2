import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

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
  bool _isProcessing = false;
  
  // Inference results
  String? _predictedClass;
  double? _confidence;
  Map<String, double>? _allPredictions;

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
      _interpreter = await Interpreter.fromAsset('assets/tflite/crab_classifier.tflite');
      print('✅ Model loaded successfully');
      
      // Load class names
      final classNamesData = await rootBundle.loadString('assets/tflite/class_names.txt');
      _classNames = classNamesData.split('\n').where((name) => name.isNotEmpty).toList();
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
          _errorMessage = 'Camera permission denied. Please enable it in settings.';
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
      
      // Start continuous inference
      _startContinuousInference();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  // Start taking pictures and running inference continuously
  void _startContinuousInference() {
    if (!_isModelLoaded || _cameraController == null) return;
    
    // Run inference every 500ms
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (!mounted || _cameraController == null || !_cameraController!.value.isInitialized) {
        return;
      }
      
      await _captureAndInfer();
      _startContinuousInference(); // Continue loop
    });
  }

  // Capture image and run inference
  Future<void> _captureAndInfer() async {
    if (_isProcessing || !_isModelLoaded) return;
    
    try {
      _isProcessing = true;
      
      final XFile imageFile = await _cameraController!.takePicture();
      final Uint8List imageBytes = await imageFile.readAsBytes();
      
      // Decode and preprocess image
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return;
      
      // Resize to 224x224 (matching your training size)
      img.Image resizedImage = img.copyResize(image, width: 224, height: 224);
      
      // Convert to Float32List with MobileNetV2 preprocessing
      // Values should be in [-1, 1] range
      var inputImage = _imageToByteListFloat32(resizedImage);
      
      // Reshape for model input: [1, 224, 224, 3]
      var input = inputImage.reshape([1, 224, 224, 3]);
      
      // Prepare output buffer
      var outputBuffer = List.filled(_classNames.length, 0.0).reshape([1, _classNames.length]);
      
      // Run inference
      _interpreter!.run(input, outputBuffer);
      
      // Process results
      List<double> probabilities = outputBuffer[0].cast<double>();
      
      // Get top prediction
      int maxIndex = 0;
      double maxProb = probabilities[0];
      Map<String, double> allPreds = {};
      
      for (int i = 0; i < probabilities.length; i++) {
        allPreds[_classNames[i]] = probabilities[i];
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }
      
      // Sort predictions by confidence
      var sortedPreds = allPreds.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      allPreds = Map.fromEntries(sortedPreds.take(3)); // Top 3
      
      setState(() {
        _predictedClass = _classNames[maxIndex];
        _confidence = maxProb;
        _allPredictions = allPreds;
      });
      
    } catch (e) {
      print('❌ Inference error: $e');
    } finally {
      _isProcessing = false;
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
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.amber),
                    )
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
                                color: _confidence != null && _confidence! > 0.7
                                    ? Colors.green
                                    : Colors.amberAccent,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),

                        // 📊 Results overlay
                        if (_predictedClass != null)
                          Positioned(
                            top: 60,
                            left: 20,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '🦀 $_predictedClass',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Confidence: ${(_confidence! * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      color: _confidence! > 0.7 
                                          ? Colors.greenAccent 
                                          : Colors.orangeAccent,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Top Predictions:',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ..._allPredictions!.entries.map((entry) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            entry.key,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            '${(entry.value * 100).toStringAsFixed(1)}%',
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ),

                        // 🔤 Instruction text
                        Positioned(
                          bottom: 60,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              _isProcessing 
                                  ? 'Processing...' 
                                  : 'Align the crab inside the box to scan',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                shadows: [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
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
          const Icon(Icons.camera_alt, color: Colors.amber, size: 60),
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
              backgroundColor: Colors.amber,
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