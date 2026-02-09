import 'package:crab_maturity_ml_app/home/widget/about_card.dart';
import 'package:crab_maturity_ml_app/home/widget/confidence_card.dart';
import 'package:crab_maturity_ml_app/home/widget/explore_card.dart';
import 'package:crab_maturity_ml_app/home/widget/scan_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Hero Section
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
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF97316).withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  Text.rich(
                    TextSpan(
                      text: 'to',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(
                          text: ' Crab Watch',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The Coast, Explained — Just Point, Scan, and Discover!',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ✅ FIXED GRID
            GridView.count(
              shrinkWrap: true, // Important!
              physics: const NeverScrollableScrollPhysics(), // Important!
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              padding: const EdgeInsets.all(0),
              children: [
                const ExploreCard(),
                const ScanCard(),
                ConfidenceCard(),
                const AboutCard(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
