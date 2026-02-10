import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConfidenceCard extends StatelessWidget {
  const ConfidenceCard({super.key});

  Color _confidenceColor(int confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 50) return Colors.orange;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    final confidence = 0;

    final color = _confidenceColor(confidence);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Get.toNamed('/history'),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(0.12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            // Top-right history icon
            Positioned(
              top: 0,
              right: 0,
              child: Icon(
                Icons.history_rounded,
                size: 20,
                color: Colors.black.withOpacity(0.5),
              ),
            ),

            // Centered percentage and label
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Percentage
                Text(
                  '$confidence%',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 8),

                // Label below percentage
                const Text(
                  'Confidence',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.deepOrange,
                  ),
                ),
                const Text(
                  'AI Confidence Score',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
