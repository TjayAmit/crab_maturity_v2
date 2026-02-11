import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text('History', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(onPressed: () => Get.back(), icon: Icon(Icons.arrow_back_ios)),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              // Header with gradient background
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'About CrabWatch',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'CrabWatch is a mobile application designed to help monitor and assess crab species using advanced machine learning models.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: const Color(0xFF525252),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 24),

              _buildInfoCard(
                icon: Icons.track_changes_rounded,
                title: 'Project Objective',
                content:
                    'This project aims to assist fisheries and researchers by automatically identifying crab species and their characteristics. By simply taking or uploading an image, CrabWatch analyzes the crab using a trained TensorFlow Lite (TFLite) model to determine its species and provide detailed biological insights.',
              ),
              const SizedBox(height: 16),

              _buildInfoCard(
                icon: Icons.memory_rounded,
                title: 'Technology Used',
                content:
                    '• Flutter for cross-platform development\n• Laravel frameworks for server and website\n• TensorFlow Lite (TFLite) for on-device image recognition\n• Dart for app logic and ML integration\n• Google ML frameworks and camera plugins for real-time scanning',
              ),
              const SizedBox(height: 16),

              _buildInfoCard(
                icon: Icons.people_outline_rounded,
                title: 'Development Team',
                content:
                    'Developed by the CrabWatch Team:\n\n• Jaythoon Sahibul\n• Aim Convocar\n• Alfred Tan\n\nGuided by: Sir Sherard, Project Adviser',
              ),
              const SizedBox(height: 24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.format_quote_rounded,
                      size: 32,
                      color: Color(0xFFF97316),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Empowering coastal communities with intelligent marine monitoring',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF171717),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text(
                '© 2025 CrabWatch Research Team',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF737373),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFED7AA).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFFF97316)),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF171717),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF525252),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
