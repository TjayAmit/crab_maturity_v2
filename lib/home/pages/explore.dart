import 'package:flutter/material.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // List of image paths (add more if needed)
    final List<String> crabImages = [
      'assets/images/crab1.jpg',
      'assets/images/crab2.jpg',
      'assets/images/crab3.jpg',
      'assets/images/crab4.jpg',
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🦀 Explore Crab Gallery',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF182659),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'View different crab samples and learn more about their features.',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 20),

              // 🖼️ Responsive Grid View
              Expanded(
                child: GridView.builder(
                  itemCount: crabImages.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 columns on phone
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1, // square cards
                  ),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GestureDetector(
                        onTap: () {
                          // show full image preview when tapped
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _FullImageView(
                                imagePath: crabImages[index],
                              ),
                            ),
                          );
                        },
                        child: Hero(
                          tag: crabImages[index],
                          child: Image.asset(
                            crabImages[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🦀 Full image viewer (zoomable)
class _FullImageView extends StatelessWidget {
  final String imagePath;

  const _FullImageView({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Center(
          child: Hero(
            tag: imagePath,
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Image.asset(imagePath),
            ),
          ),
        ),
      ),
    );
  }
}
