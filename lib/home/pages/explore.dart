import 'package:crab_maturity_ml_app/core/components/grab_gallery_shimmer.dart';
import 'package:crab_maturity_ml_app/core/models/crab_model.dart';
import 'package:crab_maturity_ml_app/home/controller/explore_controller.dart';
import 'package:crab_maturity_ml_app/home/pages/crab_detail_view.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class ExploreScreen extends GetView<CrabListController> {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Explore Crab', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(onPressed: () => Get.back(), icon: Icon(Icons.arrow_back_ios)),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 16),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ),
    );
  }
  

    Widget _buildSearchBar() {
      return TextField(
        onChanged: controller.updateSearch,
        decoration: InputDecoration(
          hintText: 'Search crabs...',
          prefixIcon: const Icon(Icons.search, color: Colors.orange),
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      );
    }

  Widget _buildContent() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const CrabGalleryShimmer();
      }

      if (controller.errorMessage.value != null) {
        return _ErrorState(
          message: controller.errorMessage.value!,
          onRetry: controller.loadCrabs,
        );
      }

      if (controller.crabs.isEmpty) {
        return const Center(child: Text('No crabs available'));
      }

      final crabsToShow = controller.filteredCrabs;

      return RefreshIndicator(
        onRefresh: controller.loadCrabs,
        color: const Color(0xFF182659),
        child: GridView.builder(
          itemCount: crabsToShow.length, // use filteredCrabs length
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 7,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (_, index) {
            final crab = crabsToShow[index]; // use same list
            return _CrabCard(crab: crab, controller: controller);
          },
        ),
      );
    });
  }
}

class _CrabCard extends StatelessWidget {
  final Crab crab;
  final CrabListController controller;

  _CrabCard({required this.crab, required this.controller, super.key});

  // Rx to track if this image finished loading
  final RxBool imageLoaded = false.obs;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        controller.selectCrab(crab);
        Get.to(() => CrabDetailView(crab: controller.selectedCrab.value!));
      },
      child: Hero(
        tag: 'crab_${crab.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Shimmer placeholder
              Obx(() => !imageLoaded.value
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    )
                  : const SizedBox.shrink()),

              // Actual image
             Image.network(
                crab.firstImage,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    // Image fully loaded → schedule state update after build
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      imageLoaded.value = true;
                    });
                    return child;
                  }
                  return const SizedBox.shrink(); // keep shimmer visible
                },
                errorBuilder: (context, error, stackTrace) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    imageLoaded.value = true;
                  });
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  );
                },
              ),

              // Bottom-left overlay name
              Positioned(
                left: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    crab.commonName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
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
}
