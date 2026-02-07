import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CrabFullView extends StatefulWidget {
  final Map<String, dynamic> crabData;

  const CrabFullView({super.key, required this.crabData});

  @override
  State<CrabFullView> createState() => _CrabFullViewState();
}

class _CrabFullViewState extends State<CrabFullView> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<dynamic> images = widget.crabData['images'];
    final String crabName = widget.crabData['name'];
    final String commonName = widget.crabData['common_name'];
    final String scientificName = widget.crabData['scientific_name'];
    final Map<String, dynamic> description = Map<String, dynamic>.from(
      widget.crabData['description'],
    );

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          // 🖼️ Top Image Header with Page Indicator
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF171717),
            iconTheme: const IconThemeData(color: Color(0xFF171717)),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              background: Stack(
                children: [
                  Hero(
                    tag: images[0],
                    child: PageView.builder(
                      itemCount: images.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final imagePath = images[index];
                        return Image.asset(
                          imagePath,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        );
                      },
                    ),
                  ),
                  // Page Indicator
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          images.length,
                          (index) => Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? const Color(0xFFF97316)
                                  : Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 📖 Content Section
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 🦀 Crab Name Header
                        Text(
                          crabName,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF171717),
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          scientificName,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF737373),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Common Name Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFED7AA)),
                          ),
                          child: Text(
                            commonName,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFFF97316),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFE5E7EB)),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 📜 Overview
                        _buildSection(
                          title: "About",
                          content: description['overview'] ?? '',
                          icon: Icons.info_outline_rounded,
                        ),
                        const SizedBox(height: 24),

                        // 🌊 Habitat
                        _buildSection(
                          title: "Habitat",
                          content: description['habitat'] ?? '',
                          icon: Icons.location_on_outlined,
                        ),
                        const SizedBox(height: 24),

                        // 🍴 Diet
                        _buildSection(
                          title: "Diet",
                          content: description['diet'] ?? '',
                          icon: Icons.restaurant_outlined,
                        ),
                        const SizedBox(height: 24),

                        // 🔍 Identification (optional)
                        if (description['identification'] != null)
                          _buildSection(
                            title: "Identification",
                            content: description['identification'] ?? '',
                            icon: Icons.search_rounded,
                          ),

                        const SizedBox(height: 20),
                      ],
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

  /// 📘 Helper widget for each content section
  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFED7AA).withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFFF97316)),
            ),
            const SizedBox(width: 10),
            Text(
              title.toUpperCase(),
              style: GoogleFonts.poppins(
                color: const Color(0xFF737373),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: GoogleFonts.poppins(
            color: const Color(0xFF525252),
            fontSize: 14,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
