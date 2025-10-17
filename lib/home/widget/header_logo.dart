import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class HeaderLogo extends StatelessWidget {
  const HeaderLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Center( // ⬅️ centers the whole logo horizontally & vertically (if space allows)
      child: SizedBox(
        height: 120,
        width: 300, // give enough width to fit crab + text
        child: Stack(
          alignment: Alignment.centerLeft,
          clipBehavior: Clip.none,
          children: [
            // 🦀 Crab logo
            Positioned(
              left:-110,
              child: SvgPicture.asset(
                'assets/brand/mr_crab.svg',
                height: 230,
                width: 230,
              ),
            ),

            // 🩵 Text beside crab
            Positioned(
              left: 70, // horizontal distance from crab
              top: 40,  // adjust to vertically align with crab if needed
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Crab',
                      style: GoogleFonts.poppins(
                        fontSize: 29,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    TextSpan(
                      text: 'Watch',
                      style: GoogleFonts.poppins(
                        fontSize: 29,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF182659),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
