import 'package:crab_maturity_ml_app/onboarding/onboarding_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingPageOne extends StatelessWidget {
  final OnboardingData data;
  const OnboardingPageOne({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 🌊 Smooth wavy background
        Positioned.fill(
          child: Container(
            color: Colors.white,
            child: ClipPath(
              clipper: _SmoothWaveClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      Color(0xFFBBDEFB),
                      Color(0xFF2196F3),
                      Color(0x002196F3), // Transparent fade bottom
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.4, 0.6, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ),

        // 🦀 Foreground content (above the wave)
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 40),

                Column(
                  children: [
                    Text(
                      data.title,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Crab',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        Text(
                          'Watch',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF182659),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(
                  height: 280,
                  child: Center(
                    child: Transform.scale(
                      scale: 1.8,
                      child: SvgPicture.asset(
                        data.image,
                        height: 400,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    data.description,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// 🌊 Much smoother, natural wave path
class _SmoothWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Start at top-left
    path.moveTo(0, 0);

    // Top side
    path.lineTo(0, size.height * 0.4);

    // Smooth wave across center
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.55,
      size.width * 0.5,
      size.height * 0.45,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.35,
      size.width,
      size.height * 0.5,
    );

    // Continue down to bottom
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
