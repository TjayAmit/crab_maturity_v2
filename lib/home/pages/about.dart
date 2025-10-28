import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),
              Text(
                '🦀 About CrabWatch',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF182659),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'CrabWatch is a mobile application designed to help monitor and assess crab maturity using advanced machine learning models.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              _buildInfoCard(
                title: '🎯 Project Objective',
                content:
                    'This project aims to assist fisheries and researchers by automatically identifying crab maturity stages. By simply taking or uploading an image, CrabWatch analyzes the crab using a trained TensorFlow Lite (TFLite) model to determine its developmental stage and related biological insights.',
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: '🧠 Technology Used',
                content:
                    '• Flutter for cross-platform development\n• TensorFlow Lite (TFLite) for on-device image recognition\n• Dart for app logic and ML integration\n• Google ML frameworks and camera plugins for real-time scanning',
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                title: '👥 Development Team',
                content:
                    'Developed by the CrabWatch Team:\n\n• Jaythoon Sahibul \n• Aim Convocar\n• Pedro Reyes\n• Fred Tan\n\nGuided by: Sir Sherards, Project Adviser',
              ),
              const SizedBox(height: 20),
              Text(
                '“Empowering coastal communities with intelligent marine monitoring.”',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                '© 2025 CrabWatch Research Team',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({required String title, required String content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FF),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF182659),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
