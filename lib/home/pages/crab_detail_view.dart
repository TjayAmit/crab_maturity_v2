import 'dart:io';
import 'package:camera/camera.dart';
import 'package:crab_maturity_ml_app/core/models/crab_model.dart';
import 'package:crab_maturity_ml_app/home/pages/scan.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class CrabDetailView extends StatefulWidget {
  final Crab? crab;
  final String? model;
  final double? confidence;
  final XFile? imageFile;
  final String? capturedImageUrl;

  const CrabDetailView({
    super.key,
    this.crab,
    this.model,
    this.confidence,
    this.imageFile,
    this.capturedImageUrl,
  }) : assert(
          crab != null || model != null,
          'Either a Crab object or model must be provided',
        );

  @override
  State<CrabDetailView> createState() => _CrabDetailViewState();
}

class _CrabDetailViewState extends State<CrabDetailView> {
  late final PageController _pageController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_GalleryItem> _buildGalleryItems(Crab crab) {
    final List<_GalleryItem> items = [];

    // 1. User's captured photo (from Camera XFile or History URL)
    if (widget.imageFile != null) {
      items.add(_GalleryItem(
        isLocalFile: true,
        filePath: widget.imageFile!.path,
        label: 'Your Scanned Photo',
      ));
    } else if (widget.capturedImageUrl != null &&
        widget.capturedImageUrl!.isNotEmpty) {
      items.add(_GalleryItem(
        isLocalFile: false,
        url: widget.capturedImageUrl!,
        label: 'Your Scanned Photo',
      ));
    }

    // 2. Catalog reference photos
    for (int i = 0; i < crab.attachments.length; i++) {
      items.add(_GalleryItem(
        isLocalFile: false,
        url: crab.attachments[i],
        label: 'Reference Photo ${i + 1}',
      ));
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final crabData = widget.crab;

    if (crabData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF0F172A)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            'No crab information available',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
      );
    }

    final galleryItems = _buildGalleryItems(crabData);
    final hasUserPhoto =
        widget.imageFile != null || widget.capturedImageUrl != null;
    final isPoisonous = crabData.isPoisonous;
    final hasConfidence = widget.confidence != null && widget.confidence! > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Hero Image & App Bar ──────────────────────────────
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: const Color(0xFF0F172A),
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.45),
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              if (hasConfidence)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(widget.confidence!)
                            .withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.verified_rounded,
                              size: 14, color: Colors.white),
                          const SizedBox(width: 5),
                          Text(
                            '${widget.confidence!.toStringAsFixed(1)}% Match',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image PageView
                  if (galleryItems.isNotEmpty)
                    PageView.builder(
                      controller: _pageController,
                      itemCount: galleryItems.length,
                      onPageChanged: (idx) {
                        setState(() {
                          _currentImageIndex = idx;
                        });
                      },
                      itemBuilder: (context, index) {
                        final item = galleryItems[index];
                        return GestureDetector(
                          onTap: () =>
                              _openZoomDialog(item, crabData.commonName),
                          child: _buildGalleryImageView(item),
                        );
                      },
                    )
                  else
                    Container(
                      color: const Color(0xFF1E293B),
                      child: const Center(
                        child: Icon(
                          Icons.cruelty_free_rounded,
                          size: 64,
                          color: Color(0xFFF97316),
                        ),
                      ),
                    ),

                  // Bottom Gradient
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 90,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Image Category Badge (e.g. "Your Scan" vs "Reference")
                  if (galleryItems.isNotEmpty)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: galleryItems[_currentImageIndex].isLocalFile ||
                                  (hasUserPhoto && _currentImageIndex == 0)
                              ? const Color(0xFFF97316)
                              : Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              galleryItems[_currentImageIndex].isLocalFile ||
                                      (hasUserPhoto && _currentImageIndex == 0)
                                  ? Icons.camera_alt_rounded
                                  : Icons.photo_library_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              galleryItems[_currentImageIndex].label,
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Zoom Hint
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.zoom_in_rounded,
                              size: 13, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to Zoom',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Pagination Dots
                  if (galleryItems.length > 1)
                    Positioned(
                      bottom: 18,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          galleryItems.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: _currentImageIndex == index ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index
                                  ? const Color(0xFFF97316)
                                  : Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ─── Main Details Section ──────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Species Titles & Safety Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                crabData.commonName,
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                  height: 1.25,
                                ),
                              ),
                              if (crabData.scientificName.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  crabData.scientificName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Edibility / Poisonous Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isPoisonous
                                ? const Color(0xFFFEF2F2)
                                : const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isPoisonous
                                  ? const Color(0xFFFCA5A5)
                                  : const Color(0xFF6EE7B7),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPoisonous
                                    ? Icons.warning_rounded
                                    : Icons.check_circle_rounded,
                                size: 14,
                                color: isPoisonous
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF059669),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isPoisonous ? 'Poisonous' : 'Safe to Eat',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isPoisonous
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF059669),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ─── Key Characteristics Grid ────────────────
                    Row(
                      children: [
                        Expanded(
                          child: _buildTraitCard(
                            icon: Icons.timelapse_rounded,
                            iconColor: const Color(0xFF3B82F6),
                            iconBg: const Color(0xFFEFF6FF),
                            label: 'Maturity',
                            value: (crabData.maturity.isNotEmpty)
                                ? crabData.maturity
                                : 'Standard',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTraitCard(
                            icon: crabData.gender.toLowerCase() == 'male'
                                ? Icons.male_rounded
                                : (crabData.gender.toLowerCase() == 'female'
                                    ? Icons.female_rounded
                                    : Icons.transgender_rounded),
                            iconColor: const Color(0xFFEC4899),
                            iconBg: const Color(0xFFFDF2F8),
                            label: 'Gender',
                            value: (crabData.gender.isNotEmpty)
                                ? crabData.gender
                                : 'Unspecified',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildTraitCard(
                            icon: Icons.category_rounded,
                            iconColor: const Color(0xFFF97316),
                            iconBg: const Color(0xFFFFF7ED),
                            label: 'Category',
                            value: (crabData.speciesType.isNotEmpty)
                                ? crabData.speciesType
                                : 'Marine',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ─── ECOLOGICAL PROFILE (Habitat, Diet, Lifespan) ───────
                    _buildEcologicalProfileCard(crabData),

                    const SizedBox(height: 20),

                    // ─── MEATINESS & COMMERCIAL QUALITY ─────────────────────
                    _buildMeatinessCard(crabData),

                    const SizedBox(height: 20),

                    // ─── Species Description ─────────────────────
                    if (crabData.description.isNotEmpty) ...[
                      Text(
                        'About this Species',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        crabData.description,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          color: const Color(0xFF475569),
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ─── Gallery Thumbnails ──────────────────────
                    if (galleryItems.length > 1) ...[
                      Text(
                        'Photo Gallery',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 76,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          itemCount: galleryItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final item = galleryItems[index];
                            final isSelected = _currentImageIndex == index;

                            return GestureDetector(
                              onTap: () {
                                _pageController.animateToPage(
                                  index,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFFF97316)
                                        : const Color(0xFFE2E8F0),
                                    width: isSelected ? 2.5 : 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: _buildThumbnailImage(item),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],

                    // ─── Bottom Actions ──────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Get.to(() => ScanScreen());
                            },
                            icon: const Icon(Icons.camera_alt_rounded, size: 18),
                            label: Text(
                              'Scan Another Crab',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF97316),
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= ECOLOGICAL PROFILE CARD =================

  Widget _buildEcologicalProfileCard(Crab crab) {
    final hasHabitat = crab.habitat.isNotEmpty;
    final hasDiet = crab.diet.isNotEmpty;
    final hasLifespan = crab.lifespan.isNotEmpty;

    if (!hasHabitat && !hasDiet && !hasLifespan) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark navy slate container matching user design
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ECOLOGICAL PROFILE',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          if (hasHabitat) ...[
            _buildEcoItem(
              title: 'Habitat',
              value: crab.habitat,
            ),
            if (hasDiet || hasLifespan)
              const Divider(height: 24, color: Color(0xFF1E293B)),
          ],
          if (hasDiet) ...[
            _buildEcoItem(
              title: 'Diet',
              value: crab.diet,
            ),
            if (hasLifespan)
              const Divider(height: 24, color: Color(0xFF1E293B)),
          ],
          if (hasLifespan) ...[
            _buildEcoItem(
              title: 'Lifespan',
              value: crab.lifespan,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEcoItem({required String title, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF97316), // Orange label
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFFE2E8F0), // Light slate text
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // ================= MEATINESS & QUALITY CARD =================

  Widget _buildMeatinessCard(Crab crab) {
    if (crab.meatyInformation.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF423B33), // Warm brownish-taupe card matching user design
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF5C5248)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  size: 16,
                  color: Color(0xFFFBBF24),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Meatiness & Commercial Quality',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFDE047), // Golden yellow title
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            crab.meatyInformation,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFFEF08A), // Soft warm yellow text
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryImageView(_GalleryItem item) {
    if (item.isLocalFile && item.filePath != null) {
      return Image.file(
        File(item.filePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    if (item.url != null && item.url!.isNotEmpty) {
      return Image.network(
        item.url!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildThumbnailImage(_GalleryItem item) {
    if (item.isLocalFile && item.filePath != null) {
      return Image.file(
        File(item.filePath!),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    if (item.url != null && item.url!.isNotEmpty) {
      return Image.network(
        item.url!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: const Center(
        child: Icon(Icons.broken_image_rounded,
            size: 36, color: Color(0xFF94A3B8)),
      ),
    );
  }

  Widget _buildTraitCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _openZoomDialog(_GalleryItem item, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.black,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: item.isLocalFile && item.filePath != null
                        ? Image.file(
                            File(item.filePath!),
                            fit: BoxFit.contain,
                          )
                        : (item.url != null && item.url!.isNotEmpty
                            ? Image.network(
                                item.url!,
                                fit: BoxFit.contain,
                              )
                            : const SizedBox()),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.label,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 90) {
      return const Color(0xFF16A34A);
    } else if (confidence >= 75) {
      return const Color(0xFFEA580C);
    } else {
      return const Color(0xFFDC2626);
    }
  }
}

class _GalleryItem {
  final bool isLocalFile;
  final String? filePath;
  final String? url;
  final String label;

  _GalleryItem({
    required this.isLocalFile,
    this.filePath,
    this.url,
    required this.label,
  });
}
