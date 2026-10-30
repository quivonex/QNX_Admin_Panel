// lib/screens/real_estate/property_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'dart:html' as html;

import '../../api/realestate_service.dart';
import '../../models/real_estate/property_list_model.dart';

class PropertyListScreen extends StatefulWidget {
  const PropertyListScreen({super.key});

  @override
  State<PropertyListScreen> createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  final PropertyListService _service = PropertyListService();

  List<PropertyData> allProperties = [];
  List<PropertyData> filteredProperties = [];
  List<PropertyData> paginatedProperties = [];

  bool isLoading = true;
  bool _isApproving = false;

  // Search & Filter
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String filterType = 'Title';
  String filterStatus = 'All';

  // Pagination
  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  // Scroll Controllers
  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  // Column Widths - Updated with Images column
  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(50),   // SR No
    1: FixedColumnWidth(160),  // Title
    2: FixedColumnWidth(90),   // Type
    3: FixedColumnWidth(90),   // Transaction
    4: FixedColumnWidth(90),   // City
    5: FixedColumnWidth(90),   // Area
    6: FixedColumnWidth(150),  // Builder (NEW)
    7: FixedColumnWidth(100),  // RERA (NEW)
    8: FixedColumnWidth(70),   // Status
    9: FixedColumnWidth(70),   // Approved
    10: FixedColumnWidth(70),  // Verified
    11: FixedColumnWidth(70),  // Source (NEW)
    12: FixedColumnWidth(80),  // Images
    13: FixedColumnWidth(80),  // Videos
    14: FixedColumnWidth(80),  // Docs
    15: FixedColumnWidth(90),  // Created
    16: FixedColumnWidth(80),  // Action
  };
  final List<String> headerLabels = [
    "SR No", "Title", "Type", "Transaction", "City", "Area",
    "Builder", "RERA", "Status", "Approved", "Verified", "Source",
    "Images", "Videos", "Docs", "Created", "Action"
  ];
  // Premium Colors
  static const Color _premiumPrimary = Color(0xFF4158D0);
  static const Color _premiumSecondary = Color(0xFFC850C0);

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
      final response = await _service.getProperties();
      if (mounted) {
        setState(() {
          allProperties = response.data;
          allProperties.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load properties: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void applyFilters() {
    filteredProperties = allProperties.where((p) {
      bool matchesSearch = true;
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        switch (filterType) {
          case 'Title':
            matchesSearch = p.title.toLowerCase().contains(query);
            break;
          case 'City':
            matchesSearch = p.city.toLowerCase().contains(query);
            break;
          case 'Area':
            matchesSearch = p.area.toLowerCase().contains(query);
            break;
          case 'Type':
            matchesSearch = p.propertyType.toLowerCase().contains(query);
            break;
          default:
            matchesSearch = p.title.toLowerCase().contains(query);
        }
      }

      bool matchesStatus = true;
      if (filterStatus != 'All') {
        if (filterStatus == 'Approved') {
          matchesStatus = p.statusApproved == true;
        } else if (filterStatus == 'Pending') {
          matchesStatus = p.statusApproved == false;
        } else if (filterStatus == 'Active') {
          matchesStatus = p.status == 'active';
        } else if (filterStatus == 'Draft') {
          matchesStatus = p.status == 'draft';
        }
      }

      return matchesSearch && matchesStatus;
    }).toList();

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

    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > filteredProperties.length) {
      endIndex = filteredProperties.length;
    }
    paginatedProperties = filteredProperties.sublist(startIndex, endIndex);
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

  void changeItemsPerPage(int? value) {
    if (value != null) {
      setState(() {
        itemsPerPage = value;
        currentPage = 1;
        applyPagination();
      });
    }
  }

  void resetFilters() {
    setState(() {
      searchQuery = '';
      filterType = 'Title';
      filterStatus = 'All';
      _searchController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String getStatusLabel(PropertyData p) {
    if (p.statusApproved) return 'Approved';
    if (p.status == 'draft') return 'Draft';
    if (p.status == 'pending') return 'Pending';
    if (p.status == 'rejected') return 'Rejected';
    return 'Pending';
  }

  Color getStatusColor(PropertyData p) {
    if (p.statusApproved) return Colors.green;
    if (p.status == 'draft') return Colors.grey;
    if (p.status == 'rejected') return Colors.red;
    return Colors.orange;
  }

  IconData getStatusIcon(PropertyData p) {
    if (p.statusApproved) return Icons.check_circle;
    if (p.status == 'draft') return Icons.edit;
    if (p.status == 'rejected') return Icons.cancel;
    return Icons.pending;
  }

  // ==================== EXPORT FUNCTIONS ====================
  void exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['Properties'];

    sheet.appendRow([
      "SR No", "Title", "Type", "Transaction", "City", "Area",
      "Builder", "RERA", "Status", "Approved", "Verified", "Source",
      "Images", "Videos", "Documents",
      "Subscription Active", "Created"
    ]);

    int srNo = filteredProperties.length;
    for (var p in filteredProperties) {
      sheet.appendRow([
        srNo--,
        p.title,
        p.propertyType,
        p.transactionType,
        p.city,
        p.area,
        p.builder?.name ?? '-',        // NEW
        p.reraNumber ?? '-',           // NEW
        p.status,
        p.statusApproved ? 'Yes' : 'No',
        p.isVerified ? 'Yes' : 'No',
        p.source ?? '-',               // NEW
        p.images.length,
        p.videos.length,
        p.documents.length,
        p.subscriptionActive == true ? 'Yes' : 'No',  // NEW
        formatDate(p.createdAt),
      ]);
    }

    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "properties.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> exportPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: [
              "SR No", "Title", "Builder", "City", "RERA", "Status", "Source"
            ],
            data: List.generate(filteredProperties.length, (index) {
              final p = filteredProperties[index];
              final srNo = filteredProperties.length - index;
              return [
                srNo.toString(),
                p.title,
                p.builder?.name ?? '-',     // NEW
                p.city,
                p.reraNumber ?? '-',        // NEW
                p.status,
                p.source ?? '-',            // NEW
              ];
            }),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void exportDOC() {
    final content = StringBuffer();
    content.writeln("Properties List\n");
    content.writeln("=" * 50);

    int srNo = filteredProperties.length;
    for (var p in filteredProperties) {
      content.writeln("SR No: ${srNo--}");
      content.writeln("Title: ${p.title}");
      content.writeln("Type: ${p.propertyType}");
      content.writeln("Transaction: ${p.transactionType}");
      content.writeln("City: ${p.city}");
      content.writeln("Area: ${p.area}");
      content.writeln("Address: ${p.address}");
      content.writeln("Pincode: ${p.pincode ?? '-'}");
      content.writeln("Status: ${p.status}");
      content.writeln("Approved: ${p.statusApproved ? 'Yes' : 'No'}");
      content.writeln("Verified: ${p.isVerified ? 'Yes' : 'No'}");
      content.writeln("Images: ${p.images.length}");
      content.writeln("Videos: ${p.videos.length}");
      content.writeln("Documents: ${p.documents.length}");
      content.writeln("Builder: ${p.builder?.name ?? '-'}");
      content.writeln("RERA: ${p.reraNumber ?? '-'}");
      content.writeln("Source: ${p.source ?? '-'}");                        // NEW
      content.writeln("Free Days: ${p.freeDays ?? '-'}");                   // NEW
      content.writeln("Subscription Required: ${p.subscriptionRequired == true ? 'Yes' : 'No'}");  // NEW
      content.writeln("Subscription Active: ${p.subscriptionActive == true ? 'Yes' : 'No'}");      // NEW
      content.writeln("Created: ${formatDate(p.createdAt)}");
      content.writeln("-" * 30);
    }

    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "properties.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ==================== APPROVE FUNCTION ====================
  Future<void> _approveProperty(PropertyData property) async {
    if (_isApproving) return;

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Approve Property'),
        content: Text('Are you sure you want to approve "${property.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isApproving = true);

    try {
      final response = await _service.approveProperty(property.id);

      if (!mounted) return;

      if (response.status) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );
        await loadProperties();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isApproving = false);
      }
    }
  }

  // ==================== DETAILS POPUP ====================
  void showDetailsPopup(PropertyData property) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            double dialogWidth = constraints.maxWidth * 0.9;
            if (constraints.maxWidth > 600) dialogWidth = 640;
            if (constraints.maxWidth > 1000) dialogWidth = 760;

            final isPending = !property.statusApproved;

            return Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
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
                  // ==================== HEADER ====================
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.home_work,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(property)
                                          .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          getStatusIcon(property),
                                          size: 12,
                                          color: getStatusColor(property),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          getStatusLabel(property),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: getStatusColor(property),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: property.isVerified
                                          ? Colors.green.withOpacity(0.3)
                                          : Colors.grey.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      property.isVerified
                                          ? 'Verified'
                                          : 'Not Verified',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: property.isVerified
                                            ? Colors.green
                                            : Colors.grey,
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

                  // ==================== BODY ====================
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Chips
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _statusChip(
                                'Type: ${property.propertyType}',
                                Colors.blue,
                              ),
                              _statusChip(
                                'Transaction: ${property.transactionType}',
                                Colors.purple,
                              ),
                              _statusChip(
                                property.isFeatured
                                    ? 'Featured'
                                    : 'Not Featured',
                                property.isFeatured
                                    ? Colors.amber
                                    : Colors.grey,
                              ),
                              _statusChip(
                                property.isUnderConstruction == true
                                    ? 'Under Construction'
                                    : 'Ready',
                                property.isUnderConstruction == true
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                              _statusChip(
                                property.isNegotiable
                                    ? 'Negotiable'
                                    : 'Fixed Price',
                                property.isNegotiable
                                    ? Colors.teal
                                    : Colors.grey,
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ==================== BASIC INFO ====================
                          _buildInfoSection(
                            'Basic Information',
                            Icons.info_outline,
                            [
                              _infoRow('ID', property.id.toString()),
                              _infoRow('Title', property.title),
                              _infoRow('Slug', property.slug),
                              _infoRow('Description', property.description),
                              _infoRow('Type', property.propertyType),
                              _infoRow('Transaction', property.transactionType),
                              _infoRow('Status', property.status),
                              _infoRow('Approved',
                                  property.statusApproved ? 'Yes' : 'No'),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ==================== BUILDER DETAILS ====================
                          if (property.builder != null) ...[
                            _buildInfoSection(
                              'Builder Details',
                              Icons.business,
                              [
                                _infoRow('Name', property.builder!.name),
                                _infoRow('Short Info',
                                    property.builder!.shortInfo ?? '-'),
                                _infoRow('Email',
                                    property.builder!.email ?? '-'),
                                _infoRow('Phone',
                                    property.builder!.phone ?? '-'),
                                _infoRow('Website',
                                    property.builder!.website ?? '-'),
                                _infoRow('Active',
                                    property.builder!.isActive ? 'Yes' : 'No'),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ==================== LOCATION ====================
                          _buildInfoSection(
                            'Location',
                            Icons.location_on,
                            [
                              _infoRow('City', property.city),
                              _infoRow('Area', property.area),
                              _infoRow('Address', property.address),
                              _infoRow('Landmark', property.landmark ?? '-'),
                              _infoRow('Pincode', property.pincode ?? '-'),
                              if (property.latitude != null &&
                                  property.longitude != null)
                                _infoRow('Coordinates',
                                    '${property.latitude}, ${property.longitude}'),
                              if (property.googleLocationUrl != null &&
                                  property.googleLocationUrl!.isNotEmpty)
                                _linkRow('Google Maps', property.googleLocationUrl!),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ==================== PROPERTY DETAILS ====================
                          _buildInfoSection(
                            'Property Details',
                            Icons.architecture,
                            [
                              _infoRow(
                                  'Total Area',
                                  property.totalArea != null
                                      ? '${property.totalArea} sq ft'
                                      : '-'),
                              _infoRow(
                                  'Plot Area',
                                  property.plotArea != null
                                      ? '${property.plotArea} sq ft'
                                      : '-'),
                              _infoRow('Total Floors',
                                  property.totalFloors?.toString() ?? '-'),
                              _infoRow('Total Towers',
                                  property.totalTowers?.toString() ?? '-'),
                              _infoRow(
                                  'RERA Number', property.reraNumber ?? '-'),
                              if (property.reraWebsite != null && property.reraWebsite!.isNotEmpty)
                                _linkRow('RERA Website', property.reraWebsite!)
                              else
                                _infoRow('RERA Website', '-'),

                              if (property.propertyWebsiteUrl != null &&
                                  property.propertyWebsiteUrl!.isNotEmpty)
                                _linkRow('Property Website', property.propertyWebsiteUrl!)
                              else
                                _infoRow('Property Website', '-'),
                              _infoRow('Completion',
                                  '${property.completionPercentage ?? 0}%'),
                              _infoRow('Possession Date',
                                  property.possessionDate ?? '-'),
                              _infoRow(
                                  'Under Construction',
                                  property.isUnderConstruction == true
                                      ? 'Yes'
                                      : 'No'),
                              _infoRow('Negotiable',
                                  property.isNegotiable ? 'Yes' : 'No'),
                              _infoRow('Referral Code',
                                  property.referralCode ?? '-'),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // ==================== RERA DETAILS (NEW) ====================
                          _buildInfoSection(
                            'RERA Details',
                            Icons.verified_user,
                            [
                              _infoRow('RERA Number', property.reraNumber ?? '-'),
                              _infoRow('RERA QR Code', property.reraQrCode ?? '-'),
                              if (property.reraWebsite != null && property.reraWebsite!.isNotEmpty)
                                _linkRow('RERA Website', property.reraWebsite!),
                              if (property.reraAdditionalUrls.isNotEmpty)
                                _infoRow('Additional URLs',
                                    property.reraAdditionalUrls.join('\n')),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ==================== AMENITIES ====================
                          if (property.amenities.isNotEmpty) ...[
                            _buildInfoSection(
                              'Amenities (${property.amenities.length})',
                              Icons.star,
                              property.amenities
                                  .map((a) => _infoRow(
                                a.name,
                                a.isActive ? 'Available' : 'Inactive',
                              ))
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ==================== IMAGES (HORIZONTAL SCROLL) ====================
                          if (property.images.isNotEmpty) ...[
                            _buildInfoSection(
                              'Images (${property.images.length})',
                              Icons.image,
                              [
                                SizedBox(
                                  height: 130,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: property.images.length,
                                    separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      final img = property.images[index];
                                      return _buildImageThumb(
                                        img.imageS3Key,
                                        img.caption ?? 'Image ${img.id}',
                                        img.isPrimary,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ==================== VIDEOS (HORIZONTAL SCROLL) ====================
                          if (property.videos.isNotEmpty) ...[
                            _buildInfoSection(
                              'Videos (${property.videos.length})',
                              Icons.videocam,
                              [
                                SizedBox(
                                  height: 130,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: property.videos.length,
                                    separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                    itemBuilder: (context, index) {
                                      final vid = property.videos[index];
                                      return _buildVideoThumb(
                                        vid.videoS3Key,
                                        vid.title ?? 'Video ${vid.id}',
                                        vid.isFeatured,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ==================== DOCUMENTS ====================
                          if (property.documents.isNotEmpty) ...[
                            _buildInfoSection(
                              'Documents (${property.documents.length})',
                              Icons.description,
                              property.documents
                                  .map((doc) => _buildDocumentTile(
                                doc.documentS3Key ?? '',
                                doc.documentName ??
                                    'Document ${doc.id}',
                                doc.documentType ?? 'file',
                              ))
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ==================== FLAT TYPES ====================
                          if (property.flatTypes.isNotEmpty) ...[
                            _buildInfoSection(
                              'Flat Types (${property.flatTypes.length})',
                              Icons.apartment,
                              [
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columnSpacing: 16,
                                    headingRowHeight: 36,
                                    dataRowHeight: 40,
                                    columns: const [
                                      DataColumn(
                                          label: Text('Type',
                                              style: TextStyle(
                                                  fontSize: 11, fontWeight: FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Area',
                                              style: TextStyle(
                                                  fontSize: 11, fontWeight: FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Beds',
                                              style: TextStyle(
                                                  fontSize: 11, fontWeight: FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Bath',
                                              style: TextStyle(
                                                  fontSize: 11, fontWeight: FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Park',
                                              style: TextStyle(
                                                  fontSize: 11, fontWeight: FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Avail',
                                              style: TextStyle(
                                                  fontSize: 11, fontWeight: FontWeight.bold))),
                                    ],
                                    rows: property.flatTypes.map((ft) {
                                      return DataRow(cells: [
                                        DataCell(Text(ft.flatType,
                                            style: const TextStyle(fontSize: 11))),
                                        DataCell(Text(ft.areaSqft ?? '-',
                                            style: const TextStyle(fontSize: 11))),
                                        DataCell(Text('${ft.bedrooms}',
                                            style: const TextStyle(fontSize: 11))),
                                        DataCell(Text('${ft.bathrooms}',
                                            style: const TextStyle(fontSize: 11))),
                                        DataCell(Text('${ft.parkingCount}',
                                            style: const TextStyle(fontSize: 11))),
                                        DataCell(Icon(
                                          ft.isAvailable
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          size: 14,
                                          color: ft.isAvailable
                                              ? Colors.green
                                              : Colors.red,
                                        )),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ==================== FLOORS ====================
                          if (property.floors.isNotEmpty) ...[
                            _buildInfoSection(
                              'Floors (${property.floors.length})',
                              Icons.account_balance,
                              [
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                    columnSpacing: 16,
                                    headingRowHeight: 36,
                                    dataRowHeight: 40,
                                    columns: const [
                                      DataColumn(
                                          label: Text('Floor No',
                                              style: TextStyle(
                                                  fontSize: 11, fontWeight: FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Name',
                                              style: TextStyle(
                                                  fontSize: 11, fontWeight: FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Total',
                                              style: TextStyle(
                                                  fontSize: 11, fontWeight: FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Available',
                                              style: TextStyle(
                                                  fontSize: 11, fontWeight: FontWeight.bold))),
                                      DataColumn(
                                          label: Text('Exp. Date',
                                              style: TextStyle(
                                                  fontSize: 11, fontWeight: FontWeight.bold))),
                                    ],
                                    rows: property.floors.map((f) {
                                      return DataRow(cells: [
                                        DataCell(Text('${f.floorNumber}',
                                            style: const TextStyle(fontSize: 11))),
                                        DataCell(Text(f.floorName,
                                            style: const TextStyle(fontSize: 11))),
                                        DataCell(Text('${f.totalUnits}',
                                            style: const TextStyle(fontSize: 11))),
                                        DataCell(Text('${f.availableUnits}',
                                            style: const TextStyle(fontSize: 11))),
                                        DataCell(Text(
                                            f.expectedCompletionDate != null
                                                ? formatDate(f.expectedCompletionDate)
                                                : '-',
                                            style: const TextStyle(fontSize: 11))),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ==================== PRICING SLABS ====================
                          if (property.pricingSlabs.isNotEmpty) ...[
                            _buildInfoSection(
                              'Pricing Slabs (${property.pricingSlabs.length})',
                              Icons.attach_money,
                              property.pricingSlabs.map((ps) {
                                return _infoRow(
                                  'Floor ${ps.floor} - ${ps.flatType}',
                                  '₹${ps.basePrice}',
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ==================== FEATURES ====================
                          if (property.features != null &&
                              property.features!.isNotEmpty) ...[
                            _buildInfoSection(
                              'Features',
                              Icons.featured_play_list,
                              property.features!.entries
                                  .map((e) => _infoRow(
                                e.key,
                                e.value.toString(),
                              ))
                                  .toList(),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // ==================== SUBSCRIPTION INFO (NEW) ====================
                          _buildInfoSection(
                            'Subscription Info',
                            Icons.card_membership,
                            [
                              _infoRow('Source', property.source ?? '-'),
                              _infoRow('Free Days', property.freeDays?.toString() ?? '-'),
                              _infoRow(
                                  'Free Expiry',
                                  property.freeExpiryDate != null
                                      ? formatDate(property.freeExpiryDate)
                                      : '-'),
                              _infoRow('Subscription Required',
                                  property.subscriptionRequired == true ? 'Yes' : 'No'),
                              _infoRow('Subscription Active',
                                  property.subscriptionActive == true ? 'Yes' : 'No'),
                            ],
                          ),
                          const SizedBox(height: 16),


                          // ==================== OTHER LINKS (NEW) ====================
                          _buildInfoSection(
                            'Other Links',
                            Icons.link,
                            [
                              _infoRow('Referral Code', property.referralCode ?? '-'),
                              if (property.propertyWebsiteUrl != null &&
                                  property.propertyWebsiteUrl!.isNotEmpty)
                                _linkRow('Property Website', property.propertyWebsiteUrl!),
                              if (property.googleLocationUrl != null &&
                                  property.googleLocationUrl!.isNotEmpty)
                                _linkRow('Google Location', property.googleLocationUrl!),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ==================== TIMESTAMPS ====================
                          _buildInfoSection(
                            'Timestamps',
                            Icons.calendar_today,
                            [
                              _infoRow('Created',
                                  formatDate(property.createdAt)),
                              _infoRow('Updated',
                                  formatDate(property.updatedAt)),
                              if (property.publishedAt != null)
                                _infoRow('Published',
                                    formatDate(property.publishedAt)),
                              if (property.expiryDate != null)
                                _infoRow('Expiry',
                                    formatDate(property.expiryDate)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ==================== FOOTER ====================
                  if (isPending)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isApproving
                                  ? null
                                  : () {
                                Navigator.pop(context);
                                _approveProperty(property);
                              },
                              icon: _isApproving
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Icon(Icons.check_circle, size: 20),
                              label: Text(
                                _isApproving
                                    ? 'Approving...'
                                    : 'Approve Property',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                disabledBackgroundColor: Colors.green.shade300,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ==================== IMAGE THUMB (horizontal) ====================
  Widget _buildImageThumb(String url, String caption, bool isPrimary) {
    return GestureDetector(
      onTap: () => _openImagePopup(url, caption),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(9),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image,
                            color: Colors.grey),
                      ),
                    ),
                    if (isPrimary)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Primary',
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                caption,
                style: const TextStyle(fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== VIDEO THUMB (horizontal) ====================
  Widget _buildVideoThumb(String url, String title, bool isFeatured) {
    return GestureDetector(
      onTap: () => _openVideoPopup(url, title),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.black,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video element inside iframe (HTML)
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: HtmlElementView(
                viewType: 'video-${url.hashCode}',
                key: ValueKey('video-${url.hashCode}'),
              ),
            ),
            // Play overlay
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
            if (isFeatured)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.purple,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Featured',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(9),
                  ),
                ),
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 10, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DOCUMENT TILE ====================
  Widget _buildDocumentTile(String url, String name, String type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.insert_drive_file,
                color: Colors.blue, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  type.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new, size: 18, color: Colors.blue),
            onPressed: () {
              if (url.isNotEmpty) {
                html.window.open(url, '_blank');
              }
            },
            tooltip: 'Open Document',
          ),
        ],
      ),
    );
  }

  // ==================== IMAGE POPUP ====================
  void _openImagePopup(String url, String caption) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            // Image
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: InteractiveViewer(
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      padding: const EdgeInsets.all(40),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image,
                              size: 60, color: Colors.grey),
                          SizedBox(height: 10),
                          Text('Failed to load image'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            // Caption
            if (caption.isNotEmpty)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      caption,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== VIDEO POPUP ====================
  void _openVideoPopup(String url, String title) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Video Player
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: HtmlElementView(
                        viewType: 'video-popup-${url.hashCode}',
                        key: ValueKey('video-popup-${url.hashCode}'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      title,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            // Close button
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== UI HELPERS ====================
  Widget _statusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
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
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  Widget _linkRow(String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                if (url.isNotEmpty) {
                  html.window.open(url, '_blank');
                }
              },
              child: Text(
                url,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF4158D0),
                  decoration: TextDecoration.underline,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== FILTER SECTION ====================
  Widget _buildFilterSection(bool isMobile) {
    final statusOptions = ['All', 'Approved', 'Pending', 'Active', 'Draft'];

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
          if (isMobile) ...[
            Container(
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
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down,
                      color: Color(0xFF6366F1)),
                  onChanged: (String? newValue) {
                    setState(() {
                      filterType = newValue!;
                      currentPage = 1;
                      applyFilters();
                    });
                  },
                  items: ['Title', 'City', 'Area', 'Type']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by ${filterType.toLowerCase()}...',
                  prefixIcon: const Icon(Icons.search,
                      size: 16, color: Color(0xFF6366F1)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
            const SizedBox(height: 8),

            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: filterStatus,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down,
                      color: Color(0xFF6366F1)),
                  onChanged: (String? newValue) {
                    setState(() {
                      filterStatus = newValue!;
                      currentPage = 1;
                      applyFilters();
                    });
                  },
                  items: statusOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildExportIcons(),
                Row(
                  children: [
                    Text(
                      "Total: ${filteredProperties.length}",
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: resetFilters,
                      icon: const Icon(Icons.refresh),
                      color: Colors.red,
                      tooltip: "Reset",
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
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
                      value: filterType,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Color(0xFF6366F1)),
                      onChanged: (String? newValue) {
                        setState(() {
                          filterType = newValue!;
                          currentPage = 1;
                          applyFilters();
                        });
                      },
                      items: ['Title', 'City', 'Area', 'Type']
                          .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

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
                        hintText: 'Search by ${filterType.toLowerCase()}...',
                        prefixIcon: const Icon(Icons.search,
                            size: 16, color: Color(0xFF6366F1)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                const SizedBox(width: 8),

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
                      value: filterStatus,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Color(0xFF6366F1)),
                      onChanged: (String? newValue) {
                        setState(() {
                          filterStatus = newValue!;
                          currentPage = 1;
                          applyFilters();
                        });
                      },
                      items: statusOptions
                          .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                _buildExportIcons(),
                const SizedBox(width: 8),

                Text(
                  "Total: ${filteredProperties.length}",
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: resetFilters,
                  icon: const Icon(Icons.refresh),
                  color: Colors.red,
                  tooltip: "Reset",
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportIcons() {
    return Row(
      children: [
        Tooltip(
          message: "Export Excel",
          child: InkWell(
            onTap: exportExcel,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset("assets/icon/xls.png", height: 20, width: 20),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "Export PDF",
          child: InkWell(
            onTap: exportPDF,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset("assets/icon/pdf.png", height: 20, width: 20),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "Export DOC",
          child: InkWell(
            onTap: exportDOC,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset("assets/icon/doc.png", height: 20, width: 20),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== TABLE ====================
  Widget _buildTable() {
    return Container(
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
          // Header
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: SingleChildScrollView(
              controller: _headerHorizontalController,
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder(
                  horizontalInside: BorderSide(color: Colors.grey.shade300),
                  verticalInside: BorderSide(color: Colors.grey.shade300),
                  top: BorderSide(color: Colors.grey.shade300),
                  bottom: BorderSide(color: Colors.grey.shade300),
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

          // Body
          Expanded(
            child: filteredProperties.isEmpty
                ? const Center(child: Text("No properties found"))
                : SingleChildScrollView(
              controller: _verticalController,
              child: SingleChildScrollView(
                controller: _rowsHorizontalController,
                scrollDirection: Axis.horizontal,
                child: Table(
                  border:
                  TableBorder.all(color: Colors.grey.shade300, width: 1),
                  columnWidths: columnWidths,
                  children: List.generate(
                      paginatedProperties.length, (rowIndex) {
                    final p = paginatedProperties[rowIndex];
                    final isEven = rowIndex % 2 == 0;
                    final srNo = filteredProperties.length -
                        ((currentPage - 1) * itemsPerPage + rowIndex);

                    final isPending = !p.statusApproved;

                    return TableRow(
                      decoration: BoxDecoration(
                        color: isEven
                            ? Colors.white
                            : const Color(0xFFF8FAFC),
                      ),
                      children: [
                        // SR No
                        _tableCell(srNo.toString(),
                            onTap: () => showDetailsPopup(p)),

                        // Title
                        _tableCell(p.title,
                            onTap: () => showDetailsPopup(p),
                            maxLines: 2),

                        // Type
                        _tableCell(p.propertyType,
                            onTap: () => showDetailsPopup(p)),

                        // Transaction
                        _tableCell(p.transactionType,
                            onTap: () => showDetailsPopup(p)),

                        // City
                        _tableCell(p.city,
                            onTap: () => showDetailsPopup(p)),

                        // Area
                        _tableCell(p.area,
                            onTap: () => showDetailsPopup(p)),

                        // Builder (NEW)
                        _tableCell(p.builder?.name ?? '-',
                            onTap: () => showDetailsPopup(p),
                            maxLines: 1),

// RERA (NEW)
                        _tableCell(p.reraNumber ?? '-',
                            onTap: () => showDetailsPopup(p),
                            maxLines: 1),

// Status

                        // Status
                        Container(
                          height: 42,
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: getStatusColor(p).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                getStatusLabel(p),
                                style: TextStyle(
                                  color: getStatusColor(p),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Approved
                        Container(
                          height: 42,
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: p.statusApproved
                                  ? Colors.green.withOpacity(0.15)
                                  : Colors.orange.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                p.statusApproved ? 'Yes' : 'No',
                                style: TextStyle(
                                  color: p.statusApproved
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Verified
                        Container(
                          height: 42,
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: p.isVerified
                                  ? Colors.green.withOpacity(0.15)
                                  : Colors.grey.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                p.isVerified ? 'Yes' : 'No',
                                style: TextStyle(
                                  color: p.isVerified
                                      ? Colors.green[700]
                                      : Colors.grey[700],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Source (NEW)
                        Container(
                          height: 42,
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: p.source == 'admin'
                                  ? Colors.purple.withOpacity(0.15)
                                  : Colors.teal.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                p.source ?? '-',
                                style: TextStyle(
                                  color: p.source == 'admin'
                                      ? Colors.purple[700]
                                      : Colors.teal[700],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Images Count
                        GestureDetector(
                          onTap: p.images.isNotEmpty
                              ? () => _openImagePopup(
                            p.images.first.imageS3Key,
                            p.images.first.caption ?? 'Image',
                          )
                              : null,
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.all(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: p.images.isNotEmpty
                                    ? Colors.blue.withOpacity(0.15)
                                    : Colors.grey.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  p.images.length.toString(),
                                  style: TextStyle(
                                    color: p.images.isNotEmpty
                                        ? Colors.blue[700]
                                        : Colors.grey[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Videos Count
                        GestureDetector(
                          onTap: p.videos.isNotEmpty
                              ? () => _openVideoPopup(
                            p.videos.first.videoS3Key,
                            p.videos.first.title ?? 'Video',
                          )
                              : null,
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.all(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: p.videos.isNotEmpty
                                    ? Colors.red.withOpacity(0.15)
                                    : Colors.grey.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  p.videos.length.toString(),
                                  style: TextStyle(
                                    color: p.videos.isNotEmpty
                                        ? Colors.red[700]
                                        : Colors.grey[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Documents Count
                        Container(
                          height: 42,
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: p.documents.isNotEmpty
                                  ? Colors.green.withOpacity(0.15)
                                  : Colors.grey.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                p.documents.length.toString(),
                                style: TextStyle(
                                  color: p.documents.isNotEmpty
                                      ? Colors.green[700]
                                      : Colors.grey[700],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Created
                        _tableCell(formatDate(p.createdAt),
                            onTap: () => showDetailsPopup(p)),

                        // Action
                        // Action
                        Container(
                          height: 42,
                          padding: const EdgeInsets.all(2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility,
                                    color: Color(0xFF4158D0), size: 18),
                                onPressed: () => showDetailsPopup(p),
                                tooltip: 'View Details',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 28, minHeight: 28),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: Color(0xFF1E293B),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _tableCell(String text, {VoidCallback? onTap, int maxLines = 2}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // ==================== PAGINATION ====================
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
          final showEntriesRow = Row(
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

          final pageButtons = [
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
                child:
                Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              _compactPageNumber(totalPages),
            ] else if (currentPage >= totalPages - 2) ...[
              _compactPageNumber(1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child:
                Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              ...List.generate(
                  4, (index) => _compactPageNumber(totalPages - 3 + index)),
            ] else ...[
              _compactPageNumber(1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child:
                Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              _compactPageNumber(currentPage - 1),
              _compactPageNumber(currentPage),
              _compactPageNumber(currentPage + 1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child:
                Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              _compactPageNumber(totalPages),
            ],
            _compactPageButton(
                icon: Icons.chevron_right,
                onTap: currentPage < totalPages ? nextPage : null),
          ];

          final paginationRow = Row(
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

  // ==================== MAIN BUILD ====================
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Properties",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildFilterSection(isMobile),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _buildTable()),
                  const SizedBox(height: 8),
                  _buildPagination(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}