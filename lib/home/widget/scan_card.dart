import 'package:flutter/material.dart';

class ScanCard extends StatelessWidget {
  final VoidCallback? onTap;

  const ScanCard({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 255, 255, 255),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 102, 118, 121).withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon inside a circular orange container
            Icon(
              Icons.qr_code_scanner_rounded,
              size: 40,
              color: Colors.black87,
            ),
            const SizedBox(height: 12),
            Text(
              'SCAN',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.orange.shade700,
                letterSpacing: 5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Discover the crab story',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
