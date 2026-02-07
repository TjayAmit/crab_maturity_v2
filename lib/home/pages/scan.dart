import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

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

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
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

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _errorMessage != null
          ? _buildErrorView()
          : !_permissionGranted
          ? _buildPermissionRequestView()
          : !_isCameraInitialized
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
                      border: Border.all(color: Colors.orange, width: 3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),

                // 🔤 Instruction text
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Text(
                    'Align the crab inside the box to scan',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Text(
        _errorMessage!,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white70, fontSize: 16),
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
