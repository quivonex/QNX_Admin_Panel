// lib/screens/real_estate/my_properties_screen.dart

import 'package:flutter/material.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import '../../api/realestate_service.dart';
import '../../models/real_estate/my_properties_model.dart';
import 'property_update_screen.dart';

class MyPropertiesScreen extends StatefulWidget {
  const MyPropertiesScreen({super.key});

  @override
  State<MyPropertiesScreen> createState() => _MyPropertiesScreenState();
}

class _MyPropertiesScreenState extends State<MyPropertiesScreen> {
  final MyPropertiesService _service = MyPropertiesService();

  List<MyPropertyData> allProperties = [];
  List<MyPropertyData> filteredProperties = [];
  List<MyPropertyData> paginatedProperties = [];

  bool isLoading = true;
  String? errorMessage;

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String filterType = 'Title';
  String? statusFilter;
  String? propertyTypeFilter;

  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  // Premium colors
  static const Color _premiumPrimary = Color(0xFF5A67F2);
  static const Color _premiumSecondary = Color(0xFF7B4DDB);
  static const Color _premiumAccent = Color(0xFFC84DB5);
  static const Color _premiumBg = Color(0xFFF7F8FF);
  static const Color _premiumCard = Colors.white;

  // ✅ Column widths (Featured & Verified REMOVED)
  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(50),   // SR No
    1: FixedColumnWidth(55),   // Image
    2: FixedColumnWidth(160),  // Title
    3: FixedColumnWidth(90),   // Type
    4: FixedColumnWidth(90),   // Transaction
    5: FixedColumnWidth(90),   // City
    6: FixedColumnWidth(100),  // Area
    7: FixedColumnWidth(70),   // Status
    8: FixedColumnWidth(80),   // Total Area
    9: FixedColumnWidth(70),   // Floors
    10: FixedColumnWidth(70),  // Towers
    11: FixedColumnWidth(100), // RERA
    12: FixedColumnWidth(100), // Created
    13: FixedColumnWidth(120), // Actions
  };

  // ✅ Header labels (Featured & Verified REMOVED)
  final List<String> headerLabels = [
    "SR No", "Image", "Title", "Type", "Transaction", "City", "Area",
    "Status", "Total Area", "Floors", "Towers", "RERA",
    "Created", "Actions"
  ];

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();
    loadProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerHorizontalController.dispose();
    _rowsHorizontalController.dispose();
    _verticalController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> loadProperties() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final response = await _service.getMyProperties();

      if (mounted) {
        setState(() {
          allProperties = response.data;
          // Sort by created_at descending (newest first)
          allProperties.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load properties: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void applyFilters() {
    List<MyPropertyData> result = List.from(allProperties);

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((p) {
        switch (filterType) {
          case 'Title':
            return p.title.toLowerCase().contains(query);
          case 'City':
            return p.city.toLowerCase().contains(query);
          case 'Area':
            return p.area.toLowerCase().contains(query);
          case 'RERA':
            return (p.reraNumber ?? '').toLowerCase().contains(query);
          case 'Type':
            return p.propertyType.toLowerCase().contains(query);
          default:
            return true;
        }
      }).toList();
    }

    // Apply status filter
    if (statusFilter != null && statusFilter!.isNotEmpty) {
      result = result.where((p) => p.status == statusFilter).toList();
    }

    // Apply property type filter
    if (propertyTypeFilter != null && propertyTypeFilter!.isNotEmpty) {
      result = result.where((p) => p.propertyType == propertyTypeFilter).toList();
    }

    filteredProperties = result;
    applyPagination();
  }

  void applyPagination() {
    if (filteredProperties.isEmpty) {
      paginatedProperties = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }
    totalPages = (filteredProperties.length / itemsPerPage).ceil();
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    if (end > filteredProperties.length) end = filteredProperties.length;
    paginatedProperties = filteredProperties.sublist(start, end);
    setState(() {});
  }

  void nextPage() {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
        applyPagination();
      });
    }
  }

  void previousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
        applyPagination();
      });
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() {
        currentPage = page;
        applyPagination();
      });
    }
  }

  void resetFilters() {
    setState(() {
      searchQuery = '';
      filterType = 'Title';
      statusFilter = null;
      propertyTypeFilter = null;
      _searchController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  // ==================== UPDATE PROPERTY ====================
  Future<void> _openUpdateScreen(MyPropertyData property) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PropertyUpdateScreen(property: property),
      ),
    );

    if (result == true) {
      // Refresh the list after successful update
      loadProperties();
    }
  }

  // ==================== VIEW POPUP ====================
  void showPropertyPopup(MyPropertyData p) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.transparent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              double dialogWidth = constraints.maxWidth * 0.9;
              if (constraints.maxWidth > 600) dialogWidth = 640;
              if (constraints.maxWidth > 1000) dialogWidth = 760;

              return Container(
                width: dialogWidth,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: _premiumPrimary.withOpacity(0.3),
                      blurRadius: 40,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFF5A67F2),
                            Color(0xFF7B4DDB),
                            Color(0xFFC84DB5),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Property image or icon
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: p.images.isNotEmpty
                                  ? Image.network(
                                p.images.first.imageS3Key,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.home_work,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              )
                                  : const Icon(
                                Icons.home_work,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.title,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        p.propertyType.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        p.transactionType.toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status chips
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildStatusChip(
                                  p.status,
                                  _getStatusColor(p.status),
                                ),
                                _buildStatusChip(
                                  p.isFeatured ? 'Featured' : 'Not Featured',
                                  p.isFeatured ? Colors.orange : Colors.grey,
                                  icon: p.isFeatured ? Icons.star : Icons.star_border,
                                ),
                                _buildStatusChip(
                                  p.isVerified ? 'Verified' : 'Not Verified',
                                  p.isVerified ? Colors.blue : Colors.grey,
                                  icon: p.isVerified
                                      ? Icons.verified
                                      : Icons.verified_outlined,
                                ),
                                _buildStatusChip(
                                  p.isNegotiable ? 'Negotiable' : 'Fixed Price',
                                  p.isNegotiable ? Colors.green : Colors.grey,
                                  icon: p.isNegotiable
                                      ? Icons.handshake
                                      : Icons.money_off,
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Basic Info Section
                            _buildSection(
                              title: 'Basic Information',
                              icon: Icons.info_outline,
                              children: [
                                _infoRow('Description', p.description),
                                _infoRow('Property Type', p.propertyType),
                                _infoRow('Transaction Type', p.transactionType),
                                _infoRow('Status', p.status),
                                _infoRow('Condition', p.propertyCondition ?? 'N/A'),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Location Section
                            _buildSection(
                              title: 'Location Details',
                              icon: Icons.location_on,
                              children: [
                                _infoRow('City', p.city),
                                _infoRow('Area', p.area),
                                _infoRow('Address', p.address),
                                _infoRow('Landmark', p.landmark ?? 'N/A'),
                                _infoRow('Pincode', p.pincode ?? 'N/A'),
                                _infoRow('Latitude', p.latitude ?? 'N/A'),
                                _infoRow('Longitude', p.longitude ?? 'N/A'),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Property Details Section
                            _buildSection(
                              title: 'Property Details',
                              icon: Icons.home_work,
                              children: [
                                _infoRow('Total Area', p.totalArea ?? 'N/A'),
                                _infoRow('Plot Area', p.plotArea ?? 'N/A'),
                                _infoRow('Total Floors', p.totalFloors?.toString() ?? 'N/A'),
                                _infoRow('Total Towers', p.totalTowers?.toString() ?? 'N/A'),
                                _infoRow('Under Construction',
                                    p.isUnderConstruction ? 'Yes' : 'No'),
                                _infoRow('Ready to Move', p.readyToMove ? 'Yes' : 'No'),
                                _infoRow('Possession Date', p.possessionDate ?? 'N/A'),
                                _infoRow('Completion %',
                                    '${p.completionPercentage ?? 0}%'),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // RERA Section
                            if (p.reraNumber != null && p.reraNumber!.isNotEmpty)
                              _buildSection(
                                title: 'RERA Details',
                                icon: Icons.verified_user,
                                children: [
                                  _infoRow('RERA Number', p.reraNumber!),
                                  _infoRow('RERA Website', p.reraWebsite ?? 'N/A'),
                                  _infoRow('RERA QR Code', p.reraQrCode ?? 'N/A'),
                                  if (p.reraAdditionalUrls.isNotEmpty)
                                    _infoRow('Additional URLs',
                                        p.reraAdditionalUrls.join(', ')),
                                ],
                              ),

                            const SizedBox(height: 16),

                            // Amenities Section
                            if (p.amenityDetails.isNotEmpty)
                              _buildSection(
                                title: 'Amenities',
                                icon: Icons.pool,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: p.amenityDetails
                                        .map((a) => _buildChip(a.name))
                                        .toList(),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 16),

                            // Features Section
                            if (p.features.isNotEmpty)
                              _buildSection(
                                title: 'Features',
                                icon: Icons.tune,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: p.features.entries
                                        .map((e) => _buildChip(
                                        '${e.key}: ${e.value}'))
                                        .toList(),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 16),

                            // Images Section
                            if (p.images.isNotEmpty)
                              _buildSection(
                                title: 'Images (${p.images.length})',
                                icon: Icons.photo_library,
                                children: [
                                  SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: p.images.length,
                                      itemBuilder: (context, index) {
                                        return Container(
                                          width: 90,
                                          margin: const EdgeInsets.only(right: 12),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                            BorderRadius.circular(12),
                                            border: Border.all(
                                                color: Colors.grey.shade200),
                                          ),
                                          child: ClipRRect(
                                            borderRadius:
                                            BorderRadius.circular(11),
                                            child: Image.network(
                                              p.images[index].imageS3Key,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                    color: Colors.grey.shade100,
                                                    child: Icon(
                                                      Icons.broken_image,
                                                      color: Colors.grey.shade400,
                                                    ),
                                                  ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),

                            const SizedBox(height: 16),

                            // Statistics Section
                            _buildSection(
                              title: 'Statistics',
                              icon: Icons.analytics,
                              children: [
                                _infoRow('Views', p.viewsCount.toString()),
                                _infoRow('Enquiries', p.enquiryCount.toString()),
                                _infoRow('Favorites', p.favoriteCount.toString()),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Dates Section
                            _buildSection(
                              title: 'Dates',
                              icon: Icons.calendar_today,
                              children: [
                                _infoRow('Created At',
                                    p.createdAt.isNotEmpty
                                        ? p.createdAt.substring(0, 10)
                                        : 'N/A'),
                                _infoRow('Updated At',
                                    p.updatedAt.isNotEmpty
                                        ? p.updatedAt.substring(0, 10)
                                        : 'N/A'),
                                _infoRow('Published At',
                                    p.publishedAt ?? 'Not Published'),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Update Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _openUpdateScreen(p);
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text(
                                  'Update Property',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _premiumPrimary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
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
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'draft':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatusChip(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 14, color: color),
          if (icon != null) const SizedBox(width: 4),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF5A67F2),
                    Color(0xFF7B4DDB),
                    Color(0xFFC84DB5),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _premiumPrimary.withOpacity(0.25),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: _premiumPrimary,
        ),
      ),
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "My Properties",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadProperties,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: loadProperties,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildFilterSection(isMobile),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                children: [
                  // Table Header
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SingleChildScrollView(
                      controller: _headerHorizontalController,
                      scrollDirection: Axis.horizontal,
                      child: Table(
                        border: TableBorder(
                          horizontalInside: BorderSide(
                              color: Colors.grey.shade300),
                          verticalInside: BorderSide(
                              color: Colors.grey.shade300),
                          top: BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(
                              color: Colors.grey.shade300),
                        ),
                        columnWidths: columnWidths,
                        children: [
                          TableRow(
                            children: headerLabels
                                .map((label) => _tableHeader(label))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Table Body
                  Expanded(
                    child: filteredProperties.isEmpty
                        ? const Center(
                        child:
                        Text("No properties found"))
                        : SingleChildScrollView(
                      controller: _verticalController,
                      child: SingleChildScrollView(
                        controller:
                        _rowsHorizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          border: TableBorder.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                          columnWidths: columnWidths,
                          children: List.generate(
                            paginatedProperties.length,
                                (rowIndex) {
                              final p = paginatedProperties[
                              rowIndex];
                              final isEven = rowIndex % 2 == 0;
                              final srNo = paginatedProperties
                                  .length -
                                  rowIndex;

                              return TableRow(
                                decoration: BoxDecoration(
                                  color: isEven
                                      ? Colors.white
                                      : const Color(
                                      0xFFF8FAFC),
                                ),
                                children: [
                                  // SR No
                                  _tableCell(srNo.toString(),
                                      onTap: () =>
                                          showPropertyPopup(p)),
                                  // Image
                                  GestureDetector(
                                    onTap: () =>
                                        showPropertyPopup(p),
                                    child: Container(
                                      height: 50,
                                      padding:
                                      const EdgeInsets.all(
                                          4),
                                      child: p.images
                                          .isNotEmpty
                                          ? ClipRRect(
                                        borderRadius:
                                        BorderRadius
                                            .circular(
                                            6),
                                        child:
                                        Image.network(
                                          p.images.first
                                              .imageS3Key,
                                          fit: BoxFit
                                              .cover,
                                          errorBuilder: (_,
                                              __,
                                              ___) =>
                                              Container(
                                                color: Colors
                                                    .grey[200],
                                                child: const Icon(
                                                    Icons
                                                        .image,
                                                    size: 16,
                                                    color: Colors
                                                        .grey),
                                              ),
                                        ),
                                      )
                                          : Container(
                                        color: Colors
                                            .grey[200],
                                        child: const Icon(
                                            Icons.home_work,
                                            size: 16,
                                            color: Colors
                                                .grey),
                                      ),
                                    ),
                                  ),
                                  // Title
                                  _tableCell(p.title,
                                      onTap: () =>
                                          showPropertyPopup(p)),
                                  // Type
                                  _tableCell(p.propertyType),
                                  // Transaction
                                  _tableCell(
                                      p.transactionType),
                                  // City
                                  _tableCell(p.city),
                                  // Area
                                  _tableCell(p.area),
                                  // Status
                                  Container(
                                    height: 50,
                                    padding:
                                    const EdgeInsets.all(
                                        4),
                                    child: Container(
                                      padding: const EdgeInsets
                                          .symmetric(
                                          horizontal: 6,
                                          vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                            p.status)
                                            .withOpacity(0.15),
                                        borderRadius:
                                        BorderRadius
                                            .circular(12),
                                      ),
                                      child: Center(
                                        child: Text(
                                          p.status
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color:
                                            _getStatusColor(
                                                p.status),
                                            fontSize: 9,
                                            fontWeight:
                                            FontWeight.bold,
                                          ),
                                          textAlign:
                                          TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Total Area
                                  _tableCell(
                                      p.totalArea ?? '-'),
                                  // Floors
                                  _tableCell(p.totalFloors
                                      ?.toString() ??
                                      '-'),
                                  // Towers
                                  _tableCell(p.totalTowers
                                      ?.toString() ??
                                      '-'),
                                  // RERA
                                  _tableCell(
                                      p.reraNumber ?? '-'),
                                  // Created
                                  _tableCell(p.createdAt
                                      .isNotEmpty
                                      ? p.createdAt.substring(
                                      0, 10)
                                      : '-'),
                                  // Actions - View + Update
                                  Container(
                                    height: 50,
                                    padding:
                                    const EdgeInsets.all(
                                        2),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment
                                          .center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.visibility,
                                            color: Color(
                                                0xFF4158D0),
                                            size: 18,
                                          ),
                                          onPressed: () =>
                                              showPropertyPopup(
                                                  p),
                                          tooltip: 'View',
                                          padding:
                                          EdgeInsets.zero,
                                          constraints:
                                          const BoxConstraints(
                                              minWidth: 28,
                                              minHeight:
                                              28),
                                        ),
                                        const SizedBox(
                                            width: 4),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.edit,
                                            color: Colors
                                                .orange,
                                            size: 18,
                                          ),
                                          onPressed: () =>
                                              _openUpdateScreen(
                                                  p),
                                          tooltip: 'Update',
                                          padding:
                                          EdgeInsets.zero,
                                          constraints:
                                          const BoxConstraints(
                                              minWidth: 28,
                                              minHeight:
                                              28),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
              // Filter Type Dropdown
              Container(
                width: 130,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: filterType,
                    icon: const Icon(Icons.arrow_drop_down,
                        color: Color(0xFF6366F1)),
                    style: const TextStyle(
                        color: Color(0xFF1E293B), fontSize: 13),
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      setState(() {
                        filterType = newValue!;
                        currentPage = 1;
                        applyFilters();
                      });
                    },
                    items: ['Title', 'City', 'Area', 'Type', 'RERA']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Search Field
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search,
                          size: 16, color: Color(0xFF6366F1)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            searchQuery = '';
                            currentPage = 1;
                            applyFilters();
                          });
                        },
                      )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                        currentPage = 1;
                        applyFilters();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Status Filter
              Container(
                width: 120,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: statusFilter,
                    hint: const Text('Status', style: TextStyle(fontSize: 13)),
                    icon: const Icon(Icons.arrow_drop_down,
                        color: Color(0xFF6366F1)),
                    style: const TextStyle(
                        color: Color(0xFF1E293B), fontSize: 13),
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      setState(() {
                        statusFilter = newValue;
                        currentPage = 1;
                        applyFilters();
                      });
                    },
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All')),
                      const DropdownMenuItem(
                          value: 'draft', child: Text('Draft')),
                      const DropdownMenuItem(
                          value: 'pending', child: Text('Pending')),
                      const DropdownMenuItem(
                          value: 'approved', child: Text('Approved')),
                      const DropdownMenuItem(
                          value: 'rejected', child: Text('Rejected')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Reset Button
              IconButton(
                onPressed: resetFilters,
                icon: const Icon(Icons.refresh),
                color: Colors.red,
                tooltip: "Reset",
              ),
              // Total Count
              Text("Total: ${filteredProperties.length}",
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _tableCell(String text, {VoidCallback? onTap, bool isBold = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 10,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (filteredProperties.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final Widget showEntriesRow = Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text("Show ", style: TextStyle(fontSize: 12)),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButton<int>(
                  value: itemsPerPage,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  style: const TextStyle(fontSize: 12),
                  items: rowsPerPageOptions
                      .map((e) =>
                      DropdownMenuItem(value: e, child: Text(e.toString())))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      itemsPerPage = v!;
                      currentPage = 1;
                      applyPagination();
                    });
                  },
                ),
              ),
              const Text(" entries", style: TextStyle(fontSize: 12)),
              const SizedBox(width: 12),
              Text(
                "Showing ${(currentPage - 1) * itemsPerPage + 1} to "
                    "${currentPage * itemsPerPage > filteredProperties.length ? filteredProperties.length : currentPage * itemsPerPage} "
                    "of ${filteredProperties.length}",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          );

          final List<Widget> pageButtons = [
            _compactPageButton(
                icon: Icons.chevron_left,
                onTap: currentPage > 1 ? previousPage : null),
            if (totalPages <= 5)
              ...List.generate(
                  totalPages, (index) => _compactPageNumber(index + 1))
            else if (currentPage <= 3) ...[
              ...List.generate(4, (index) => _compactPageNumber(index + 1)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...",
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              _compactPageNumber(totalPages),
            ] else if (currentPage >= totalPages - 2) ...[
              _compactPageNumber(1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...",
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              ...List.generate(4,
                      (index) => _compactPageNumber(totalPages - 3 + index)),
            ] else ...[
              _compactPageNumber(1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...",
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              _compactPageNumber(currentPage - 1),
              _compactPageNumber(currentPage),
              _compactPageNumber(currentPage + 1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...",
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              _compactPageNumber(totalPages),
            ],
            _compactPageButton(
                icon: Icons.chevron_right,
                onTap: currentPage < totalPages ? nextPage : null),
          ];

          final Widget paginationRow = Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: pageButtons,
          );

          if (constraints.maxWidth < 700) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                showEntriesRow,
                const SizedBox(height: 8),
                paginationRow,
              ],
            );
          } else {
            return SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  showEntriesRow,
                  paginationRow,
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _compactPageButton(
      {required IconData icon, required VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: onTap,
        color: onTap != null ? const Color(0xFF6366F1) : Colors.grey,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
    );
  }

  Widget _compactPageNumber(int pageNum) {
    final isSelected = currentPage == pageNum;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: () => goToPage(pageNum),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: Text(
            pageNum.toString(),
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}