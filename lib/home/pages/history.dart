import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  // Mock data - replace with actual data from your backend/database
  final List<CrabScanHistory> _scanHistory = const [
    CrabScanHistory(
      id: 1,
      crabName: 'Blue Swimming Crab',
      scientificName: 'Portunus pelagicus',
      confidence: 95.8,
      imageUrl: 'assets/crabs/blue_crab.jpg',
      scannedAt: '2 hours ago',
    ),
    CrabScanHistory(
      id: 2,
      crabName: 'Mud Crab',
      scientificName: 'Scylla serrata',
      confidence: 88.3,
      imageUrl: 'assets/crabs/mud_crab.jpg',
      scannedAt: '5 hours ago',
    ),
    CrabScanHistory(
      id: 3,
      crabName: 'King Crab',
      scientificName: 'Paralithodes camtschaticus',
      confidence: 92.1,
      imageUrl: 'assets/crabs/king_crab.jpg',
      scannedAt: '1 day ago',
    ),
    CrabScanHistory(
      id: 4,
      crabName: 'Dungeness Crab',
      scientificName: 'Metacarcinus magister',
      confidence: 76.5,
      imageUrl: 'assets/crabs/dungeness_crab.jpg',
      scannedAt: '2 days ago',
    ),
    CrabScanHistory(
      id: 5,
      crabName: 'Snow Crab',
      scientificName: 'Chionoecetes opilio',
      confidence: 84.2,
      imageUrl: 'assets/crabs/snow_crab.jpg',
      scannedAt: '3 days ago',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: const Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan History',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF171717),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_scanHistory.length} scans recorded',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF525252),
                  ),
                ),
              ],
            ),
          ),

          // History List
          Expanded(
            child: _scanHistory.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: _scanHistory.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _buildHistoryCard(_scanHistory[index], context);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(CrabScanHistory scan, BuildContext context) {
    final confidenceColor = _getConfidenceColor(scan.confidence);

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('View details for ${scan.crabName}')),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            // Crab Avatar/Image
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFED7AA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFB923C).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  scan.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback icon if image fails to load
                    return const Icon(
                      Icons.cruelty_free_rounded,
                      size: 32,
                      color: Color(0xFFF97316),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Crab Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scan.crabName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF171717),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scan.scientificName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF737373),
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: const Color(0xFF737373),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        scan.scannedAt,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF737373),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Confidence Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: confidenceColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: confidenceColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getConfidenceIcon(scan.confidence),
                    size: 14,
                    color: confidenceColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${scan.confidence.toStringAsFixed(1)}%',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: confidenceColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFED7AA).withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 64,
              color: Color(0xFFF97316),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Scan History Yet',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start scanning crabs to see\nyour history here',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF737373),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 90) {
      return const Color(0xFF16A34A); // Green
    } else if (confidence >= 75) {
      return const Color(0xFFF97316); // Orange
    } else {
      return const Color(0xFFEF4444); // Red
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

// Model class for scan history
class CrabScanHistory {
  final int id;
  final String crabName;
  final String scientificName;
  final double confidence;
  final String imageUrl;
  final String scannedAt;

  const CrabScanHistory({
    required this.id,
    required this.crabName,
    required this.scientificName,
    required this.confidence,
    required this.imageUrl,
    required this.scannedAt,
  });
}
