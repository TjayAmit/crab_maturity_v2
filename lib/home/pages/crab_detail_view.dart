import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CrabDetailView extends StatefulWidget {
  final int crabId;

  const CrabDetailView({super.key, required this.crabId});

  @override
  State<CrabDetailView> createState() => _CrabDetailViewState();
}

class _CrabDetailViewState extends State<CrabDetailView> {
  Map<String, dynamic>? crabData;
  bool isLoading = true;
  String? errorMessage;
  int currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCrabDetail();
  }

  Future<void> _loadCrabDetail() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      print('https://crabwatch.online/api/crabs/${widget.crabId}');

      final response = await http.get(
        Uri.parse('https://crabwatch.online/api/crabs/${widget.crabId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          crabData = data['data'];
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load crab details: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading data: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF182659),
        ),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCrabDetail,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF182659),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (crabData == null) {
      return const Center(
        child: Text('No data available'),
      );
    }

    final attachments = crabData!['attachments'] as List<dynamic>? ?? [];
    final commonName = crabData!['common_name'] ?? 'Unknown Crab';
    final scientificName = crabData!['scientific_name'] ?? '';
    final speciesType = crabData!['species_type'] ?? '';
    final gender = crabData!['gender'] ?? '';
    final description = crabData!['description'] ?? '';

    return CustomScrollView(
      slivers: [
        // App Bar with back button
        SliverAppBar(
          expandedHeight: 400,
          pinned: true,
          backgroundColor: const Color(0xFF182659),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: attachments.isEmpty
                ? Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.broken_image,
                      size: 64,
                      color: Colors.grey,
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image carousel
                      PageView.builder(
                        itemCount: attachments.length,
                        onPageChanged: (index) {
                          setState(() {
                            currentImageIndex = index;
                          });
                        },
                        itemBuilder: (context, index) {
                          return Hero(
                            tag: 'crab_${widget.crabId}',
                            child: Image.network(
                              attachments[index]['url'],
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[200],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      color: const Color(0xFF182659),
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                      
                      // Image indicator dots
                      if (attachments.length > 1)
                        Positioned(
                          bottom: 16,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              attachments.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: currentImageIndex == index
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      
                      // Gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name section
                Text(
                  commonName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF182659),
                  ),
                ),
                if (scientificName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    scientificName,
                    style: TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),

                // Info cards
                Row(
                  children: [
                    if (speciesType.isNotEmpty)
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.category,
                          label: 'Species',
                          value: speciesType,
                        ),
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
                          value: gender,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // Description
                if (description.isNotEmpty) ...[
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF182659),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.6,
                      color: Colors.grey[700],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Gallery section
                if (attachments.length > 1) ...[
                  const Text(
                    'Gallery',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF182659),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: attachments.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            // Could implement full-screen image viewer here
                            setState(() {
                              currentImageIndex = index;
                            });
                            // Scroll to top to show the image
                          },
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: currentImageIndex == index
                                    ? const Color(0xFF182659)
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                attachments[index]['url'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),
        ),
      ],
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
        color: const Color(0xFF182659).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF182659).withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF182659),
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF182659),
            ),
          ),
        ],
      ),
    );
  }
}