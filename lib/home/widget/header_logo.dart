import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HeaderLogo extends StatelessWidget {
  const HeaderLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      width: 300, // give enough width to fit crab + text
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(100)),
              ),
              child: Image.asset(
                'assets/logo/crab_logo.png',
                height: 80,
                width: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            left: 90, // horizontal distance from crab
            top: 12, // adjust to vertically align with crab if needed
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Crab',
                    style: GoogleFonts.poppins(
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepOrange,
                    ),
                  ),
                  TextSpan(
                    text: 'Watch',
                    style: GoogleFonts.poppins(
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
