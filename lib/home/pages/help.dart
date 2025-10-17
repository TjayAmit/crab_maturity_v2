import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🦀 How to Use CrabWatch',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF182659),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'CrabWatch helps you analyze crab maturity using machine learning (TFLite). '
              'Follow these steps to get started:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),

            // 🧭 Step 1
            _buildStep(
              step: '1',
              title: 'Open the Scan Crab Page',
              description:
                  'Tap on the "Scan" tab at the bottom navigation bar to open the scanner page.',
              icon: Icons.camera_alt_rounded,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 16),

            // 📸 Step 2
            _buildStep(
              step: '2',
              title: 'Capture or Upload a Crab Image',
              description:
                  'Use your camera to take a live picture or upload a saved image of a crab.',
              icon: Icons.image_rounded,
              color: Colors.green,
            ),
            const SizedBox(height: 16),

            // 🤖 Step 3
            _buildStep(
              step: '3',
              title: 'AI Analysis',
              description:
                  'CrabWatch uses a trained TensorFlow Lite (TFLite) model to detect the crab species and estimate its maturity level.',
              icon: Icons.auto_graph_rounded,
              color: Colors.orangeAccent,
            ),
            const SizedBox(height: 16),

            // 📊 Step 4
            _buildStep(
              step: '4',
              title: 'View Your Results',
              description:
                  'You’ll instantly see the crab maturity result and key details based on AI predictions.',
              icon: Icons.insights_rounded,
              color: Colors.purple,
            ),
            const SizedBox(height: 16),

            // 🧾 Step 5
            _buildStep(
              step: '5',
              title: 'Check History Anytime',
              description:
                  'All your previous scans are saved for easy access in the “History” section.',
              icon: Icons.history_rounded,
              color: Colors.teal,
            ),

            const SizedBox(height: 32),
            Center(
              child: Text(
                '“Simple • Smart • Sustainable”',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required String step,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step $step: $title',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF182659),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
