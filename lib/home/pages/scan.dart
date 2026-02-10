// scan_screen.dart
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:crab_maturity_ml_app/home/controller/scan_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ScanScreen extends StatelessWidget {
  ScanScreen({super.key});

  final ScanController controller = Get.put(ScanController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        // Error state
        if (controller.errorMessage.value != null) {
          return _error(controller.errorMessage.value!);
        }

        // Permission state
        if (!controller.permissionGranted.value) {
          return _permission(controller);
        }

        // Loading state (camera/model)
        if (!controller.isCameraInitialized.value ||
            !controller.isModelLoaded.value) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.orange),
          );
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            // Background (white after capture)
            Obx(() {
              final hasImage = controller.capturedImage.value != null;
              final isClosed = controller.cameraClosed.value;

              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                color: hasImage
                    ? Colors.white
                    : (isClosed ? Colors.grey.shade900 : Colors.black),
              );
            }),

            // Camera preview
            if (controller.cameraController != null &&
                !controller.cameraClosed.value &&
                controller.isCameraInitialized.value &&
                controller.cameraController!.value.isInitialized)
              Builder(
                builder: (context) {
                  if (!controller.cameraController!.value.isInitialized) {
                    return const SizedBox();
                  }
                  return CameraPreview(controller.cameraController!);
                },
              ),

            // Scan box / captured avatar
            Center(
              child: Obx(() {
                final isProcessing = controller.scanPhase.value != ScanPhase.idle;
                final hasImage = controller.capturedImage.value != null;

                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                  child: Container(
                    key: ValueKey<bool>(hasImage), // helps AnimatedSwitcher
                    width: isProcessing ? 290 : 260,
                    height: isProcessing ? 290 : 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isProcessing ? Colors.orange : Colors.white.withOpacity(0.6),
                        width: isProcessing ? 6 : 3,
                      ),
                      boxShadow: isProcessing
                          ? [
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 6,
                              ),
                              BoxShadow(
                                color: Colors.orange.withOpacity(0.2),
                                blurRadius: 30,
                                spreadRadius: 12,
                              ),
                            ]
                          : null,
                      image: hasImage
                          ? DecorationImage(
                              image: FileImage(File(controller.capturedImage.value!.path)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: !hasImage && isProcessing
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.orange,
                              strokeWidth: 3,
                            ),
                          )
                        : null,
                  ),
                );
              }),
            ),
            // Top result
           Positioned(
            top: 60,
            right: 20,
            child: Obx(() {
              if (controller.predictedClass.value == null ||
                  controller.scanPhase.value != ScanPhase.idle) {
                return const SizedBox.shrink();
              }
              return _result(controller);
            }),
          ),

            // Loading label
            Positioned(
              bottom: 120,
              left: 40,
              right: 40,
              child: Obx(() {
                if (controller.scanPhase.value == ScanPhase.idle) {
                  return const SizedBox.shrink();
                }

                String text = '';
                switch (controller.scanPhase.value) {
                  case ScanPhase.scanning:
                    text = 'Capturing...';
                    break;
                  case ScanPhase.identifying:
                    text = 'Analyzing crab...';
                    break;
                  case ScanPhase.fetchingData:
                    text = 'Loading crab information...';
                    break;
                  default:
                    text = 'Processing...';
                }

                return _loadingLabel(text);
              }),
            ),

            // Scan button
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: controller.scanPhase.value != ScanPhase.idle
                      ? null
                      : controller.startScanAndSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: controller.isScanning
                        ? Colors.grey
                        : Colors.orange,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 56, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                  ),
                  child: Obx(() => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (controller.isScanning) ...[
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Scanning...',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold),
                            ),
                          ] else
                            const Text(
                              'Start Scan',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold),
                            ),
                        ],
                      )),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _loadingLabel(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _result(ScanController c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            c.predictedClass.value!,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Identified',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _error(String msg) => Center(
        child: Text(
          msg,
          style: const TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );

  Widget _permission(ScanController c) => Center(
        child: ElevatedButton(
          onPressed: c.checkPermission,
          child: const Text('Grant Camera Permission'),
        ),
      );
}
