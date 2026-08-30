import 'dart:io';
import 'package:camera/camera.dart';
import 'package:crab_maturity_ml_app/home/controller/scan_controller.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class ScanScreen extends StatelessWidget {
  ScanScreen({super.key});

  final ScanController controller = Get.put(ScanController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Obx(() {
        // Permission state
        if (!controller.permissionGranted.value) {
          return _buildPermissionView(controller);
        }

        // Initial loading state
        if (!controller.isCameraInitialized.value) {
          if (controller.errorMessage.value != null) {
            return _buildErrorView(controller.errorMessage.value!, controller);
          }
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF97316)),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // Live Camera Preview
            if (controller.cameraController != null &&
                controller.cameraController!.value.isInitialized)
              CameraPreview(controller.cameraController!)
            else
              Container(color: Colors.black),

            // Captured Image Overlay (during processing)
            if (controller.capturedImage.value != null)
              Image.file(
                File(controller.capturedImage.value!.path),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),

            // Dark gradient overlay for readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  stops: const [0.0, 0.2, 0.7, 1.0],
                ),
              ),
            ),

            // Top Bar: Back button and Title
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => Get.back(),
                    ),
                  ),
                  Text(
                    'Scan Crab',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),

            // Center Framing Reticle
            Center(
              child: Obx(() {
                final isProcessing =
                    controller.scanPhase.value != ScanPhase.idle;

                return Container(
                  width: 270,
                  height: 270,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isProcessing
                          ? const Color(0xFFF97316)
                          : Colors.white.withValues(alpha: 0.8),
                      width: isProcessing ? 4 : 2.5,
                    ),
                    boxShadow: isProcessing
                        ? [
                            BoxShadow(
                              color: const Color(0xFFF97316).withValues(alpha: 0.4),
                              blurRadius: 24,
                              spreadRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),

            // Error Banner Overlay if error occurs
            if (controller.errorMessage.value != null &&
                controller.scanPhase.value == ScanPhase.idle)
              Positioned(
                top: MediaQuery.of(context).padding.top + 64,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          controller.errorMessage.value!,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 18),
                        onPressed: () => controller.resetScanState(),
                      ),
                    ],
                  ),
                ),
              ),

            // Instructional Subtitle / Progress Status
            Positioned(
              bottom: 124,
              left: 32,
              right: 32,
              child: Obx(() {
                if (controller.scanPhase.value != ScanPhase.idle) {
                  String label = 'Processing...';
                  switch (controller.scanPhase.value) {
                    case ScanPhase.scanning:
                      label = 'Capturing photo...';
                      break;
                    case ScanPhase.identifying:
                      label = 'Analyzing crab species...';
                      break;
                    case ScanPhase.fetchingData:
                      label = 'Retrieving crab information...';
                      break;
                    default:
                      label = 'Processing scan...';
                  }
                  return _buildProcessingLabel(label);
                }

                return Text(
                  'Align the crab inside the frame and tap Scan',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                );
              }),
            ),

            // Scan Action Button
            Positioned(
              bottom: 36,
              left: 0,
              right: 0,
              child: Center(
                child: Obx(() {
                  final isScanning = controller.isScanning;

                  return ElevatedButton(
                    onPressed: isScanning
                        ? null
                        : controller.startScanAndSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isScanning
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isScanning) ...[
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Scanning...',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ] else ...[
                          const Icon(Icons.camera_alt_rounded, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Scan Crab',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildProcessingLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFF97316),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String msg, ScanController c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 52,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Camera Initialization Error',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFFD1D5DB),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF6B7280)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Go Back',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => c.initCamera(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    'Retry',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionView(ScanController c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt_outlined,
              size: 56,
              color: Color(0xFFF97316),
            ),
            const SizedBox(height: 20),
            Text(
              'Camera Access Needed',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please allow camera permission so you can take photos of crabs for identification.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFFD1D5DB),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: c.checkPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Grant Camera Permission',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
