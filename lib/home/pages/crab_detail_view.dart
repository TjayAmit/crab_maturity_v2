import 'package:camera/camera.dart';
import 'package:crab_maturity_ml_app/core/models/crab_model.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';

class CrabDetailView extends StatelessWidget {
  final Crab? crab;
  final String? model;
  final double? confidence;
  final XFile? imageFile;
  
  final currentImageIndex = 0.obs;

  CrabDetailView({
    super.key,
    this.crab,
    this.model,
    this.confidence,
    this.imageFile,
  }) : assert(
         crab != null || model != null,
         'Either a Crab object or model must be provided',
       );

  @override
  Widget build(BuildContext context) {
    final crabData = crab;

    if (crabData == null) {
      return const Scaffold(
        body: Center(child: Text('No data available')),
      );
    }

    final attachments = crabData.attachments; // List<String>
    final commonName = crabData.commonName;
    final scientificName = crabData.scientificName;
    final speciesType = crabData.speciesType;
    final gender = crabData.gender;
    final description = crabData.description;
    final isPoisonous = !crabData.isPoisonous;
    final maturity = crabData.maturity;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 10,
      ),
      body: Column(
        children: [
          // Top image gallery with back button
          SizedBox(
            height: 260,
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: attachments.isEmpty ? 1 : attachments.length,
                  onPageChanged: (index) {
                    currentImageIndex.value = index;
                  },
                  itemBuilder: (context, index) {
                    final imageUrl = attachments.isEmpty
                        ? '' // placeholder if no image
                        : attachments[index];
                    return Hero(
                      tag: 'crab_${crabData.id}', 
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                        ),
                        child: imageUrl.isEmpty
                            ? const Icon(Icons.broken_image, size: 64)
                            : Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                      ),
                    );
                  },
                ),

                // Back button
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                if (attachments.length > 1)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Obx(() => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        attachments.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: currentImageIndex.value == index ? 8 : 5,
                          height: currentImageIndex.value == index ? 8 : 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentImageIndex.value == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ),
                    )),
                  ),
              ],
            ),
          ),
          // Info & Description section
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  commonName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    height: 1.5,
                                  ),
                                ),
                                Text(
                                  scientificName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isPoisonous? Colors.red: Colors.green,
                                  borderRadius: BorderRadius.all(Radius.circular(25)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 2,
                                      offset: Offset(0, -2),
                                    ),
                                  ]
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0, top: 3.0, right: 8.0, bottom: 3.0),
                                  child: Row(
                                    children: [
                                      Text(isPoisonous? "Not Safe":'Safe to Eat', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),),
                                      const SizedBox(width: 4),
                                      Icon(isPoisonous? Icons.close_rounded :Icons.check_circle, color: Colors.white, size: 14,)
                                    ],
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (description.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Description',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                description,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Maturity',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  maturity,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Species Type',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  speciesType,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 50),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gender',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  gender,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            )
                          ]),
                      const SizedBox(height: 20),

                      // Gallery thumbnails
                      if (attachments.length > 1)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gallery',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 100,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: attachments.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      attachments[index],
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      // Species and Gender
                      Row(
                        children: [
                          if (speciesType.isNotEmpty)
                            Expanded(
                              child: _buildInfoCard(
                                  icon: Icons.category,
                                  label: 'Species',
                                  value: speciesType),
                            ),
                          if (speciesType.isNotEmpty && gender.isNotEmpty)
                            const SizedBox(width: 12),
                          if (gender.isNotEmpty)
                            Expanded(
                              child: _buildInfoCard(
                                  icon: gender.toLowerCase() == 'male'
                                      ? Icons.male
                                      : Icons.female,
                                  label: 'Gender',
                                  value: gender),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.orange, size: 28),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
