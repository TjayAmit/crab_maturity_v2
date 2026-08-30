import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';

import 'package:crab_maturity_ml_app/core/models/crab_model.dart';
import 'package:crab_maturity_ml_app/feature/crabs/services/crab_api_service.dart';
import 'package:crab_maturity_ml_app/home/pages/crab_detail_view.dart';
import 'package:crab_maturity_ml_app/home/pages/scan.dart';

enum HistoryFilter { all, highConfidence, mediumConfidence, lowConfidence }

enum HistorySort { newest, oldest, highestConfidence, lowestConfidence }

enum ViewMode { card, compact }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<CrabScanHistory> _allScans = [];
  List<Crab> _catalogCrabs = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Search & Filters
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  HistoryFilter _selectedFilter = HistoryFilter.all;
  HistorySort _selectedSort = HistorySort.newest;
  ViewMode _viewMode = ViewMode.card;

  @override
  void initState() {
    super.initState();
    _fetchTransactionsAndCatalog();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTransactionsAndCatalog() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transactionsFuture = http.get(
        Uri.parse('https://crabwatch.online/api/transactions'),
        headers: {'Accept': 'application/json'},
      );

      final catalogFuture =
          CrabApiService().fetchCrabs().catchError((_) => <Crab>[]);

      final results = await Future.wait([
        transactionsFuture,
        catalogFuture,
      ]);

      final http.Response response = results[0] as http.Response;
      final List<Crab> catalog = results[1] as List<Crab>;

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        final List<dynamic> transactions =
            jsonData['data'] ?? jsonData['transactions'] ?? jsonData;

        setState(() {
          _allScans = transactions
              .map((json) => CrabScanHistory.fromJson(json))
              .toList();
          _catalogCrabs = catalog;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load scan history (Status ${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            'Unable to connect to the server. Please check your internet connection.';
        _isLoading = false;
      });
    }
  }

  List<CrabScanHistory> get _filteredScans {
    List<CrabScanHistory> result = List.from(_allScans);

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      result = result.where((scan) {
        final nameMatches = scan.crabName.toLowerCase().contains(query);
        final sciMatches =
            scan.scientificName?.toLowerCase().contains(query) ?? false;
        final idMatches =
            '#${scan.id}'.contains(query) || scan.id.toString() == query;
        return nameMatches || sciMatches || idMatches;
      }).toList();
    }

    switch (_selectedFilter) {
      case HistoryFilter.highConfidence:
        result = result.where((scan) => scan.confidence >= 90.0).toList();
        break;
      case HistoryFilter.mediumConfidence:
        result = result
            .where((scan) => scan.confidence >= 75.0 && scan.confidence < 90.0)
            .toList();
        break;
      case HistoryFilter.lowConfidence:
        result = result.where((scan) => scan.confidence < 75.0).toList();
        break;
      case HistoryFilter.all:
        break;
    }

    switch (_selectedSort) {
      case HistorySort.newest:
        result.sort((a, b) => b.id.compareTo(a.id));
        break;
      case HistorySort.oldest:
        result.sort((a, b) => a.id.compareTo(b.id));
        break;
      case HistorySort.highestConfidence:
        result.sort((a, b) => b.confidence.compareTo(a.confidence));
        break;
      case HistorySort.lowestConfidence:
        result.sort((a, b) => a.confidence.compareTo(b.confidence));
        break;
    }

    return result;
  }

  double get _averageConfidence {
    if (_allScans.isEmpty) return 0.0;
    final total =
        _allScans.fold<double>(0.0, (sum, item) => sum + item.confidence);
    return total / _allScans.length;
  }

  int get _highConfidenceCount =>
      _allScans.where((scan) => scan.confidence >= 90.0).length;

  int get _mediumConfidenceCount => _allScans
      .where((scan) => scan.confidence >= 75.0 && scan.confidence < 90.0)
      .length;

  int get _lowConfidenceCount =>
      _allScans.where((scan) => scan.confidence < 75.0).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFF97316),
          onRefresh: _fetchTransactionsAndCatalog,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              // Summary Stats
              if (!_isLoading && _errorMessage == null && _allScans.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _buildSummaryStats(),
                  ),
                ),

              // Search & Filter controls
              if (!_isLoading && _errorMessage == null && _allScans.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: 12),
                        _buildFilterChipsRow(),
                      ],
                    ),
                  ),
                ),

              // Cards / List
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: _buildBodySliver(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= APP BAR =================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0F172A),
      centerTitle: false,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFF0F172A),
          size: 20,
        ),
      ),
      title: Text(
        'Scan History',
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0F172A),
        ),
      ),
      actions: [
        if (!_isLoading && _allScans.isNotEmpty) ...[
          IconButton(
            tooltip: _viewMode == ViewMode.card ? 'Compact list' : 'Card view',
            icon: Icon(
              _viewMode == ViewMode.card
                  ? Icons.view_agenda_outlined
                  : Icons.grid_view_rounded,
              color: const Color(0xFF475569),
              size: 22,
            ),
            onPressed: () {
              setState(() {
                _viewMode = _viewMode == ViewMode.card
                    ? ViewMode.compact
                    : ViewMode.card;
              });
            },
          ),
          PopupMenuButton<HistorySort>(
            tooltip: 'Sort list',
            icon: const Icon(Icons.sort_rounded, color: Color(0xFF475569)),
            initialValue: _selectedSort,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (HistorySort sort) {
              setState(() {
                _selectedSort = sort;
              });
            },
            itemBuilder: (context) => [
              _buildPopupMenuItem(HistorySort.newest, 'Newest First',
                  Icons.arrow_downward_rounded),
              _buildPopupMenuItem(HistorySort.oldest, 'Oldest First',
                  Icons.arrow_upward_rounded),
              _buildPopupMenuItem(HistorySort.highestConfidence,
                  'Highest Accuracy', Icons.verified_rounded),
              _buildPopupMenuItem(HistorySort.lowestConfidence,
                  'Lowest Accuracy', Icons.low_priority_rounded),
            ],
          ),
        ],
        IconButton(
          tooltip: 'Refresh',
          icon: const Icon(Icons.refresh_rounded, color: Color(0xFFF97316)),
          onPressed: _fetchTransactionsAndCatalog,
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          color: const Color(0xFFE2E8F0),
          height: 1,
        ),
      ),
    );
  }

  PopupMenuItem<HistorySort> _buildPopupMenuItem(
      HistorySort value, String text, IconData icon) {
    final isSelected = _selectedSort == value;
    return PopupMenuItem<HistorySort>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected
                ? const Color(0xFFF97316)
                : const Color(0xFF64748B),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected
                  ? const Color(0xFFF97316)
                  : const Color(0xFF0F172A),
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            const Icon(Icons.check, size: 16, color: Color(0xFFF97316)),
          ],
        ],
      ),
    );
  }

  // ================= SUMMARY OVERVIEW =================

  Widget _buildSummaryStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overview',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                '${_allScans.length} total ${_allScans.length == 1 ? 'record' : 'records'}',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.camera_alt_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  iconBg: const Color(0xFFEFF6FF),
                  title: 'Total Scans',
                  value: '${_allScans.length}',
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: const Color(0xFFF1F5F9),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.check_circle_rounded,
                  iconColor: const Color(0xFF10B981),
                  iconBg: const Color(0xFFECFDF5),
                  title: 'Avg. Accuracy',
                  value: '${_averageConfidence.toStringAsFixed(1)}%',
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: const Color(0xFFF1F5F9),
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.verified_rounded,
                  iconColor: const Color(0xFFF97316),
                  iconBg: const Color(0xFFFFF7ED),
                  title: 'High Match',
                  value: '$_highConfidenceCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 12, color: iconColor),
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // ================= SEARCH & FILTERS =================

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) {
          setState(() {
            _searchQuery = val;
          });
        },
        style:
            GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'Search scans...',
          hintStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFFF97316),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildFilterChipsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All Scans',
            count: _allScans.length,
            filter: HistoryFilter.all,
            activeColor: const Color(0xFFF97316),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'High Match (≥90%)',
            count: _highConfidenceCount,
            filter: HistoryFilter.highConfidence,
            activeColor: const Color(0xFF16A34A),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Medium (75–89%)',
            count: _mediumConfidenceCount,
            filter: HistoryFilter.mediumConfidence,
            activeColor: const Color(0xFFEA580C),
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Low (<75%)',
            count: _lowConfidenceCount,
            filter: HistoryFilter.lowConfidence,
            activeColor: const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required int count,
    required HistoryFilter filter,
    required Color activeColor,
  }) {
    final isSelected = _selectedFilter == filter;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
      },
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

  // ================= BODY =================

  Widget _buildBodySliver() {
    if (_isLoading) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildShimmerItem(),
          childCount: 5,
        ),
      );
    }

    if (_errorMessage != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildErrorState(),
      );
    }

    if (_allScans.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(),
      );
    }

    final displayList = _filteredScans;

    if (displayList.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildNoSearchResults(),
      );
    }

    if (_viewMode == ViewMode.compact) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final scan = displayList[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: _buildCompactHistoryCard(scan),
            );
          },
          childCount: displayList.length,
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final scan = displayList[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: _buildDetailedHistoryCard(scan),
          );
        },
        childCount: displayList.length,
      ),
    );
  }

  // ================= RESTORED CARD DESIGN =================

  Widget _buildDetailedHistoryCard(CrabScanHistory scan) {
    final confidenceColor = _getConfidenceColor(scan.confidence);
    final confidencePercent = (scan.confidence / 100).clamp(0.0, 1.0);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: () => _showScanDetailSheet(scan),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Photo Thumbnail
                  GestureDetector(
                    onTap: () {
                      if (scan.imageUrl != null) {
                        _showFullImageDialog(scan.imageUrl!, scan.crabName);
                      }
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFFED7AA),
                              width: 1,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: scan.imageUrl != null
                                ? Image.network(
                                    scan.imageUrl!,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, progress) {
                                      if (progress == null) return child;
                                      return Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation(
                                                    confidenceColor),
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (context, error, stack) =>
                                        _buildCrabPlaceholderIcon(),
                                  )
                                : _buildCrabPlaceholderIcon(),
                          ),
                        ),
                        if (scan.imageUrl != null)
                          Positioned(
                            bottom: 3,
                            right: 3,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.fullscreen_rounded,
                                size: 10,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Metadata & Species info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#${scan.id}',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            // Accuracy badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: confidenceColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: confidenceColor.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getConfidenceIcon(scan.confidence),
                                    size: 12,
                                    color: confidenceColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${scan.confidence.toStringAsFixed(1)}%',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: confidenceColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scan.crabName,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (scan.scientificName != null &&
                            scan.scientificName!.isNotEmpty) ...[
                          const SizedBox(height: 1),
                          Text(
                            scan.scientificName!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 10),

              // Bottom row: Time + Progress bar + CTA
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    scan.scannedAt,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Progress bar gauge
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: confidencePercent,
                        minHeight: 5,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation(confidenceColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Details',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF97316),
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: Color(0xFFF97316),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHistoryCard(CrabScanHistory scan) {
    final confidenceColor = _getConfidenceColor(scan.confidence);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 0,
      child: InkWell(
        onTap: () => _showScanDetailSheet(scan),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: scan.imageUrl != null
                      ? Image.network(
                          scan.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildCrabPlaceholderIcon(size: 20),
                        )
                      : _buildCrabPlaceholderIcon(size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scan.crabName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '#${scan.id} • ${scan.scannedAt}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: confidenceColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${scan.confidence.toStringAsFixed(0)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: confidenceColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCrabPlaceholderIcon({double size = 28}) {
    return Center(
      child: Icon(
        Icons.cruelty_free_rounded,
        size: size,
        color: const Color(0xFFF97316),
      ),
    );
  }

  // ================= MODAL DETAIL SHEET =================

  void _showScanDetailSheet(CrabScanHistory scan) {
    final confidenceColor = _getConfidenceColor(scan.confidence);
    final matchedCrab = _findMatchedCatalogCrab(scan.crabName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Scan #${scan.id}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          scan.scannedAt,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE2E8F0)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (scan.imageUrl != null) ...[
                        GestureDetector(
                          onTap: () {
                            _showFullImageDialog(scan.imageUrl!, scan.crabName);
                          },
                          child: Container(
                            height: 220,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(16),
                              border:
                                  Border.all(color: const Color(0xFFFED7AA)),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.network(
                                    scan.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Text(
                                        'Image preview unavailable',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: const Color(0xFF94A3B8),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.65),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.zoom_in_rounded,
                                            size: 14, color: Colors.white),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Tap to Zoom',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        scan.crabName,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      if (scan.scientificName != null &&
                          scan.scientificName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          scan.scientificName!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: confidenceColor.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: confidenceColor.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Confidence Rating',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              '${scan.confidence.toStringAsFixed(1)}%',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: confidenceColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMetadataRow(
                        icon: Icons.tag_rounded,
                        label: 'Transaction ID',
                        value: '#${scan.id}',
                      ),
                      _buildMetadataRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date Recorded',
                        value: scan.scannedAt,
                      ),
                      _buildMetadataRow(
                        icon: Icons.category_rounded,
                        label: 'Species Category',
                        value:
                            matchedCrab?.speciesType ?? 'Crab Classification',
                      ),
                      if (matchedCrab != null &&
                          (matchedCrab.habitat.isNotEmpty ||
                              matchedCrab.diet.isNotEmpty ||
                              matchedCrab.lifespan.isNotEmpty)) ...[
                        const SizedBox(height: 16),
                        _buildEcologicalProfileCard(matchedCrab),
                      ],
                      if (matchedCrab != null &&
                          matchedCrab.meatyInformation.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildMeatinessCard(matchedCrab),
                      ],
                      const SizedBox(height: 24),
                      if (matchedCrab != null) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              Get.to(() => CrabDetailView(
                                    crab: matchedCrab,
                                    confidence: scan.confidence,
                                    capturedImageUrl: scan.imageUrl,
                                  ));
                            },
                            icon: const Icon(Icons.menu_book_rounded, size: 18),
                            label: Text(
                              'View in Encyclopedia',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF97316),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Get.to(() => ScanScreen());
                          },
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: Text(
                            'Scan Another Crab',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0F172A),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetadataRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEcologicalProfileCard(Crab crab) {
    final hasHabitat = crab.habitat.isNotEmpty;
    final hasDiet = crab.diet.isNotEmpty;
    final hasLifespan = crab.lifespan.isNotEmpty;

    if (!hasHabitat && !hasDiet && !hasLifespan) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ECOLOGICAL PROFILE',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.1,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          if (hasHabitat) ...[
            _buildEcoItem('Habitat', crab.habitat),
            if (hasDiet || hasLifespan)
              const Divider(height: 20, color: Color(0xFF1E293B)),
          ],
          if (hasDiet) ...[
            _buildEcoItem('Diet', crab.diet),
            if (hasLifespan)
              const Divider(height: 20, color: Color(0xFF1E293B)),
          ],
          if (hasLifespan) ...[
            _buildEcoItem('Lifespan', crab.lifespan),
          ],
        ],
      ),
    );
  }

  Widget _buildEcoItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFF97316),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFFE2E8F0),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildMeatinessCard(Crab crab) {
    if (crab.meatyInformation.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF423B33),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5C5248)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.restaurant_rounded,
                  size: 14,
                  color: Color(0xFFFBBF24),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Meatiness & Commercial Quality',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFDE047),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            crab.meatyInformation,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFFFEF08A),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Crab? _findMatchedCatalogCrab(String crabName) {
    if (_catalogCrabs.isEmpty) return null;
    final lower = crabName.toLowerCase();
    for (final crab in _catalogCrabs) {
      if (crab.commonName.toLowerCase() == lower ||
          crab.scientificName.toLowerCase() == lower ||
          lower.contains(crab.commonName.toLowerCase()) ||
          crab.commonName.toLowerCase().contains(lower)) {
        return crab;
      }
    }
    return null;
  }

  void _showFullImageDialog(String imageUrl, String crabName) {
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
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
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
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                crabName,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= SHIMMER & STATES =================

  Widget _buildShimmerItem() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Shimmer.fromColors(
        baseColor: const Color(0xFFE2E8F0),
        highlightColor: const Color(0xFFF8FAFC),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFEDD5), width: 2),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 64,
                color: Color(0xFFF97316),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Scan History Yet',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your identified crabs and scan transactions will be listed here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Get.to(() => ScanScreen()),
              icon: const Icon(Icons.camera_alt_rounded, size: 18),
              label: Text(
                'Start Scanning',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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

  Widget _buildNoSearchResults() {
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
              'No Matching Scans',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No results found for current query or filter criteria.',
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
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = HistoryFilter.all;
                });
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Reset Filters',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF97316),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
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
              'Failed to Load History',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to load scan history.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchTransactionsAndCatalog,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Retry Connection',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

  // ================= HELPERS =================

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 90) {
      return const Color(0xFF16A34A);
    } else if (confidence >= 75) {
      return const Color(0xFFEA580C);
    } else {
      return const Color(0xFFEF4444);
    }
  }

  IconData _getConfidenceIcon(double confidence) {
    if (confidence >= 90) {
      return Icons.check_circle_rounded;
    } else if (confidence >= 75) {
      return Icons.info_rounded;
    } else {
      return Icons.warning_rounded;
    }
  }
}

// ================= MODEL =================

class CrabScanHistory {
  final int id;
  final String crabName;
  final String? scientificName;
  final double confidence;
  final String? imageUrl;
  final String scannedAt;

  CrabScanHistory({
    required this.id,
    required this.crabName,
    this.scientificName,
    required this.confidence,
    this.imageUrl,
    required this.scannedAt,
  });

  factory CrabScanHistory.fromJson(Map<String, dynamic> json) {
    final rawConf = (json['confidence'] ?? 0).toDouble();
    final double normalizedConf = rawConf <= 1.0 ? rawConf * 100.0 : rawConf;

    return CrabScanHistory(
      id: json['id'] ?? 0,
      crabName: json['crabName'] ?? json['name'] ?? 'Unknown Crab',
      scientificName: json['scientificName'] ?? json['scientific_name'],
      confidence: normalizedConf,
      imageUrl: json['imageUrl'] ?? json['image'],
      scannedAt: json['scannedAt'] ??
          json['scanned_at'] ??
          _formatDateTime(json['created_at']),
    );
  }

  static String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'Recently';

    try {
      final DateTime dt = DateTime.parse(dateTime);
      final Duration difference = DateTime.now().difference(dt);

      if (difference.inMinutes < 60) {
        final m = difference.inMinutes;
        return '$m ${m == 1 ? 'minute' : 'minutes'} ago';
      } else if (difference.inHours < 24) {
        final h = difference.inHours;
        return '$h ${h == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inDays < 7) {
        final d = difference.inDays;
        return '$d ${d == 1 ? 'day' : 'days'} ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
      } else {
        final months = (difference.inDays / 30).floor();
        return '$months ${months == 1 ? 'month' : 'months'} ago';
      }
    } catch (e) {
      return dateTime;
    }
  }
}
