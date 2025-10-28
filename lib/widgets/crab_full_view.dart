import 'package:flutter/material.dart';

class CrabFullView extends StatelessWidget {
  final Map<String, dynamic> crabData;

  const CrabFullView({super.key, required this.crabData});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> images = crabData['images'];
    final String crabName = crabData['name'];
    final String commonName = crabData['common_name'];
    final String scientificName = crabData['scientific_name'];
    final Map<String, dynamic> description =
        Map<String, dynamic>.from(crabData['description']);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // 🖼️ Top Image Header
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF182659),
            iconTheme: const IconThemeData(color: Color(0xFF182659)),
            elevation: 0.8,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              background: Hero(
                tag: images[0],
                child: PageView.builder(
                  itemCount: images.length,
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
            ),
          ),

          // 📖 Content Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🦀 Crab Name
                  Text(
                    crabName,
                    style: const TextStyle(
                      color: Color(0xFF182659),
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "$commonName • $scientificName",
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),

                  const Divider(height: 32, color: Colors.black12),

                  // 📜 Overview
                  _buildSection(
                    title: "Overview",
                    content: description['overview'] ?? '',
                  ),
                  const SizedBox(height: 24),

                  // 🌊 Habitat
                  _buildSection(
                    title: "Habitat",
                    content: description['habitat'] ?? '',
                  ),
                  const SizedBox(height: 24),

                  // 🍴 Diet
                  _buildSection(
                    title: "Diet",
                    content: description['diet'] ?? '',
                  ),
                  const SizedBox(height: 24),

                  // 🔍 Identification (optional)
                  if (description['identification'] != null)
                    _buildSection(
                      title: "Identification",
                      content: description['identification'] ?? '',
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📘 Helper widget for each content section
  Widget _buildSection({required String title, required String content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF182659),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
