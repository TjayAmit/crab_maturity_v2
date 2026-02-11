import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<CrabScanHistory> _scanHistory = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('https://crabwatch.online/api/transactions'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        // Adjust based on your actual API response structure
        // This assumes the response has a 'data' or 'transactions' field
        final List<dynamic> transactions =
            jsonData['data'] ?? jsonData['transactions'] ?? jsonData;

        setState(() {
          _scanHistory = transactions
              .map((json) => CrabScanHistory.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load history (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error connecting to server: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('History', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
        leading: IconButton(onPressed: () => Get.back(), icon: Icon(Icons.arrow_back_ios)),
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan History',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF171717),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLoading
                            ? 'Loading...'
                            : '${_scanHistory.length} scans recorded',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF525252),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    color: const Color(0xFFF97316),
                    onPressed: _fetchTransactions,
                  ),
                ],
              ),
            ),

            // History List
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFF97316)),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_scanHistory.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      color: const Color(0xFFF97316),
      onRefresh: _fetchTransactions,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _scanHistory.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          return _buildHistoryCard(_scanHistory[index], context);
        },
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
                child: scan.imageUrl != null
                    ? Image.network(
                        scan.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.cruelty_free_rounded,
                            size: 32,
                            color: Color(0xFFF97316),
                          );
                        },
                      )
                    : const Icon(
                        Icons.cruelty_free_rounded,
                        size: 32,
                        color: Color(0xFFF97316),
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
                  if (scan.scientificName != null)
                    Text(
                      scan.scientificName!,
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
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Color(0xFF737373),
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

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Oops! Something went wrong',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF737373),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchTransactions,
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: Text(
              'Try Again',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF97316),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
    return CrabScanHistory(
      id: json['id'] ?? 0,
      crabName: json['crabName'] ?? json['name'] ?? 'Unknown Crab',
      scientificName: json['scientificName'],
      confidence: (json['confidence'] ?? 0).toDouble() * 100,
      imageUrl: json['imageUrl'] ?? json['image'],
      scannedAt: _formatDateTime(json['created_at'] ?? json['scanned_at']),
    );
  }

  static String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'Unknown';

    try {
      final DateTime dt = DateTime.parse(dateTime);
      final Duration difference = DateTime.now().difference(dt);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
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
