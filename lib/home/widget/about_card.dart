import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class AboutCard extends StatelessWidget {
  const AboutCard({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Get.toNamed('/about'),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Colors.white, Colors.orange.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stacked avatars
            SizedBox(
              height: 40,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    child: _buildAvatar(Colors.blue.shade400),
                  ),
                  Positioned(
                    left: 24,
                    child: _buildAvatar(Colors.teal.shade400),
                  ),
                  Positioned(
                    left: 48,
                    child: _buildAvatar(Colors.amber.shade400),
                  ),
                ],
              ),
            ),

            // Text content
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meet the Team'
                      .toUpperCase(), // Uppercase adds a clean, labeled look
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Colors.orange, // Use a primary brand color here
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'About Us',
                  style: GoogleFonts.poppins(
                    fontSize: 16, // Increased size for a clear heading
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                // Added a small decorative underline or accent
                Container(
                  height: 3,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Color color) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 20),
    );
  }
}
