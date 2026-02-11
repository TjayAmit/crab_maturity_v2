import 'package:crab_maturity_ml_app/core/models/crab_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CrabFullView extends StatefulWidget {
  final Crab crab;

  const CrabFullView({super.key, required this.crab});

  @override
  State<CrabFullView> createState() => _CrabFullViewState();
}

class _CrabFullViewState extends State<CrabFullView> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<String> images = widget.crab.attachments.isNotEmpty
        ? widget.crab.attachments
        : [widget.crab.firstImage];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: CustomScrollView(
        slivers: [
          /// 🖼️ Image Header
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF171717),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  PageView.builder(
                    itemCount: images.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return Image.network(
                        images[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Image.network(
                          widget.crab.firstImage,
                          fit: BoxFit.cover,
                        ),
                      );
                    },
                  ),

                  /// Page Indicator
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
                            margin:
                                const EdgeInsets.symmetric(horizontal: 4),
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

          /// 📖 Content
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
                        /// 🦀 Name
                        Text(
                          widget.crab.commonName,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF171717),
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),

                        /// Scientific Name
                        Text(
                          widget.crab.scientificName,
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF737373),
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                        const SizedBox(height: 12),

                        /// Species + Gender Badge
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildBadge(widget.crab.speciesType.toUpperCase()),
                            _buildBadge(widget.crab.gender.toUpperCase()),
                            _buildBadge(
                                "Maturity: ${widget.crab.maturity}"),
                          ],
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
                        /// 📜 Description
                        _buildSection(
                          title: "Description",
                          content: widget.crab.description,
                          icon: Icons.info_outline_rounded,
                        ),
                        const SizedBox(height: 24),

                        /// 🥩 Meaty Identification
                        _buildSection(
                          title: "Meaty Identification",
                          content: widget.crab.meatyInformation,
                          icon: Icons.search_rounded,
                        ),
                        const SizedBox(height: 24),

                        /// ☠️ Poison Info
                        _buildSection(
                          title: "Poisonous",
                          content: widget.crab.isPoisonous
                              ? "This species is poisonous."
                              : "This species is not poisonous.",
                          icon: Icons.warning_amber_rounded,
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

  /// 🏷 Badge
  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: const Color(0xFFF97316),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 📘 Section Builder
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
