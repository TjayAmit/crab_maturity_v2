import 'package:crab_maturity_ml_app/core/models/crab_model.dart';
import 'package:crab_maturity_ml_app/home/controller/explore_controller.dart';
import 'package:crab_maturity_ml_app/home/pages/crab_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class ExploreScreen extends GetView<CrabListController> {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered
    final CrabListController listController =
        Get.isRegistered<CrabListController>()
            ? Get.find<CrabListController>()
            : Get.put(CrabListController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(listController),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFF97316),
          onRefresh: listController.loadCrabs,
          child: Column(
            children: [
              // Search & Filter Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(listController),
                    const SizedBox(height: 12),
                    _buildFilterChips(listController),
                    const SizedBox(height: 10),
                    _buildSummaryBar(listController),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFE2E8F0)),

              // Main Species List / Grid
              Expanded(
                child: _buildContent(listController),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= APP BAR =================

  PreferredSizeWidget _buildAppBar(CrabListController controller) {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFF0F172A),
          size: 20,
        ),
        onPressed: () => Get.back(),
      ),
      title: Text(
        'Explore Species',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
      ),
      actions: [
        Obx(() {
          final isGrid = controller.viewMode.value == ExploreViewMode.grid;
          return IconButton(
            tooltip: isGrid ? 'List view' : 'Grid view',
            icon: Icon(
              isGrid ? Icons.view_agenda_outlined : Icons.grid_view_rounded,
              color: const Color(0xFF475569),
              size: 22,
            ),
            onPressed: controller.toggleViewMode,
          );
        }),
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFFF97316)),
          onPressed: controller.loadCrabs,
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFE2E8F0), height: 1),
      ),
    );
  }

  // ================= SEARCH & FILTERS =================

  Widget _buildSearchBar(CrabListController controller) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        onChanged: controller.updateSearch,
        style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'Search by species name, scientific, or habitat...',
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFFF97316),
            size: 20,
          ),
          suffixIcon: Obx(() {
            if (controller.searchQuery.value.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
              onPressed: () => controller.updateSearch(''),
            );
          }),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFilterChips(CrabListController controller) {
    return Obx(() {
      final current = controller.selectedFilter.value;

      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildFilterPill(
              label: 'All Species',
              count: controller.crabs.length,
              isSelected: current == ExploreFilter.all,
              activeColor: const Color(0xFFF97316),
              onTap: () => controller.setFilter(ExploreFilter.all),
            ),
            const SizedBox(width: 8),
            _buildFilterPill(
              label: 'Blue Crab (Alimasag)',
              count: controller.countBlue,
              isSelected: current == ExploreFilter.blue,
              activeColor: const Color(0xFF0284C7),
              onTap: () => controller.setFilter(ExploreFilter.blue),
            ),
            const SizedBox(width: 8),
            _buildFilterPill(
              label: 'Mud Crab (Alimango)',
              count: controller.countMud,
              isSelected: current == ExploreFilter.mud,
              activeColor: const Color(0xFFD97706),
              onTap: () => controller.setFilter(ExploreFilter.mud),
            ),
            const SizedBox(width: 8),
            _buildFilterPill(
              label: 'Safe to Eat',
              count: controller.countEdible,
              isSelected: current == ExploreFilter.edible,
              activeColor: const Color(0xFF16A34A),
              onTap: () => controller.setFilter(ExploreFilter.edible),
            ),
            const SizedBox(width: 8),
            _buildFilterPill(
              label: 'Poisonous',
              count: controller.countPoisonous,
              isSelected: current == ExploreFilter.poisonous,
              activeColor: const Color(0xFFDC2626),
              onTap: () => controller.setFilter(ExploreFilter.poisonous),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildFilterPill({
    required String label,
    required int count,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.28),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF475569),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar(CrabListController controller) {
    return Obx(() {
      final list = controller.filteredCrabs;

      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${list.length} ${list.length == 1 ? 'species' : 'species'} found',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          PopupMenuButton<ExploreSort>(
            tooltip: 'Sort list',
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: controller.setSort,
            itemBuilder: (context) => [
              _buildPopupSortItem(
                ExploreSort.nameAsc,
                'Name (A to Z)',
                Icons.sort_by_alpha_rounded,
                controller.selectedSort.value,
              ),
              _buildPopupSortItem(
                ExploreSort.nameDesc,
                'Name (Z to A)',
                Icons.sort_by_alpha_rounded,
                controller.selectedSort.value,
              ),
              _buildPopupSortItem(
                ExploreSort.category,
                'By Category',
                Icons.category_rounded,
                controller.selectedSort.value,
              ),
            ],
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sort_rounded, size: 16, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  _getSortLabel(controller.selectedSort.value),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF475569),
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 18, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ],
      );
    });
  }

  PopupMenuItem<ExploreSort> _buildPopupSortItem(
    ExploreSort value,
    String label,
    IconData icon,
    ExploreSort current,
  ) {
    final isSelected = value == current;
    return PopupMenuItem<ExploreSort>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? const Color(0xFFF97316) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? const Color(0xFFF97316) : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(ExploreSort sort) {
    switch (sort) {
      case ExploreSort.nameAsc:
        return 'A to Z';
      case ExploreSort.nameDesc:
        return 'Z to A';
      case ExploreSort.category:
        return 'Category';
    }
  }

  // ================= MAIN CONTENT =================

  Widget _buildContent(CrabListController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return _buildShimmerGrid();
      }

      if (controller.errorMessage.value != null) {
        return _buildErrorState(controller);
      }

      final crabsToShow = controller.filteredCrabs;

      if (crabsToShow.isEmpty) {
        return _buildEmptyState(controller);
      }

      if (controller.viewMode.value == ExploreViewMode.list) {
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          itemCount: crabsToShow.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            return _CrabListCard(crab: crabsToShow[index], controller: controller);
          },
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: crabsToShow.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 14,
          childAspectRatio: 0.68,
        ),
        itemBuilder: (context, index) {
          return _CrabGridCard(crab: crabsToShow[index], controller: controller);
        },
      );
    });
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 14,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xFFE2E8F0),
        highlightColor: const Color(0xFFF8FAFC),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(CrabListController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Species Found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No crabs match your search query or filter selection.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                controller.updateSearch('');
                controller.setFilter(ExploreFilter.all);
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Reset Filters',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF97316),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(CrabListController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to Load Species',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              controller.errorMessage.value ?? 'Unable to connect to species database.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: controller.loadCrabs,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= GRID CARD =================

class _CrabGridCard extends StatelessWidget {
  final Crab crab;
  final CrabListController controller;

  const _CrabGridCard({required this.crab, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isPoisonous = crab.isPoisonous;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: () {
          controller.selectCrab(crab);
          Get.to(() => CrabDetailView(crab: crab));
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo with badges
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(15)),
                      child: Image.network(
                        crab.firstImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFFFFF7ED),
                          child: const Center(
                            child: Icon(Icons.cruelty_free_rounded,
                                size: 36, color: Color(0xFFF97316)),
                          ),
                        ),
                      ),
                    ),

                    // Top Safety Badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isPoisonous
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isPoisonous
                                  ? Icons.warning_rounded
                                  : Icons.check_circle_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              isPoisonous ? 'Poisonous' : 'Edible',
                              style: GoogleFonts.poppins(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Gender tag (if available)
                    if (crab.gender.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            crab.gender,
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Crab Details
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crab.commonName,
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (crab.scientificName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        crab.scientificName,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFED7AA)),
                          ),
                          child: Text(
                            crab.speciesType.isNotEmpty
                                ? crab.speciesType
                                : 'Species',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFF97316),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: Color(0xFFF97316),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= LIST CARD =================

class _CrabListCard extends StatelessWidget {
  final Crab crab;
  final CrabListController controller;

  const _CrabListCard({required this.crab, required this.controller});

  @override
  Widget build(BuildContext context) {
    final isPoisonous = crab.isPoisonous;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: () {
          controller.selectCrab(crab);
          Get.to(() => CrabDetailView(crab: crab));
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Photo Thumbnail
              Stack(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFED7AA)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.network(
                        crab.firstImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.cruelty_free_rounded,
                              size: 32, color: Color(0xFFF97316)),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    left: 4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isPoisonous
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isPoisonous
                            ? Icons.warning_rounded
                            : Icons.check_rounded,
                        size: 9,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      crab.commonName,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (crab.scientificName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        crab.scientificName,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (crab.gender.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              crab.gender,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            crab.speciesType.isNotEmpty
                                ? crab.speciesType
                                : 'Species',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFF97316),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
