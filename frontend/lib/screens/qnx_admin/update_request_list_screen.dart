// screens/qnx_admin/update_request_list_screen.dart
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel;
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import '../../api/api_service.dart';
import '../../api/api_url.dart';
import '../../models/qnx_admin/update_request_model.dart';
import '../../models/qnx_admin/unit_model.dart';
import '../../models/qnx_admin/brand_model.dart';
import '../../models/qnx_admin/category_model.dart';
import '../../models/qnx_admin/subcategory_model.dart';
import '../../models/qnx_admin/company_model.dart';

class UpdateRequestListScreen extends StatefulWidget {
  const UpdateRequestListScreen({super.key});

  @override
  State<UpdateRequestListScreen> createState() => _UpdateRequestListScreenState();
}

class _UpdateRequestListScreenState extends State<UpdateRequestListScreen> {
  final UpdateRequestService _service = UpdateRequestService();

  List<UpdateRequest> allRequests = [];
  List<UpdateRequest> filteredRequests = [];
  List<UpdateRequest> paginatedRequests = [];

  bool isLoading = true;
  bool _isProcessing = false;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String filterType = 'Product Name';

  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  // Map for master data (ID -> Name)
  Map<int, String> unitMap = {};
  Map<int, String> brandMap = {};
  Map<int, String> categoryMap = {};
  Map<int, String> subcategoryMap = {};
  Map<int, String> companyMap = {};

  // Premium gradient colors (matching dashboard)
  static const Color _premiumPrimary = Color(0xFF4158D0);
  static const Color _premiumSecondary = Color(0xFFC850C0);

  // More flexible column widths - SR No added, Req ID removed
  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(60),   // SR No
    1: FixedColumnWidth(100),  // Status
    2: FixedColumnWidth(140),  // Requested By
    3: FixedColumnWidth(80),   // Thumb
    4: FixedColumnWidth(200),  // Product Name
    5: FixedColumnWidth(90),   // Price
    6: FixedColumnWidth(100),  // Created
    7: FixedColumnWidth(70),   // Actions
  };

  final List<String> headerLabels = [
    "SR No", "Status", "Requested By", "Img", "Product Name", "Price", "Created", "Actions"
  ];

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();
    _loadMasterData();
  }

  @override
  void dispose() {
    _headerHorizontalController.dispose();
    _rowsHorizontalController.dispose();
    _verticalController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMasterData() async {
    try {
      await Future.wait([
        _loadUnits(),
        _loadBrands(),
        _loadCategories(),
        _loadSubCategories(),
        _loadCompanies(),
      ]);
      await loadAllRequests();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load master data: $e")),
        );
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadUnits() async {
    final units = await UnitService().getUnits();
    for (var u in units) {
      if (u.id != null) {
        unitMap[u.id!] = u.name;
      }
    }
  }

  Future<void> _loadBrands() async {
    try {
      final brandUrl = ApiUrls.brandList;
      if (brandUrl.isEmpty) {
        print("⚠️ ApiUrls.brandList not defined. Brand names will not be mapped.");
        return;
      }
      final response = await http.post(
        Uri.parse(brandUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'] ?? [];
        for (var item in list) {
          final id = item['id'] as int?;
          final name = item['name'] as String?;
          if (id != null && name != null && name.isNotEmpty) {
            brandMap[id] = name;
          }
        }
      }
    } catch (e) {
      print("Error loading brands: $e");
    }
  }

  Future<void> _loadCategories() async {
    final categories = await CategoryAllService().getCategories();
    for (var c in categories) {
      categoryMap[c.id] = c.name;
    }
  }

  Future<void> _loadSubCategories() async {
    final response = await SubCategoryService().getSubCategories();
    for (var sc in response.data) {
      subcategoryMap[sc.id] = sc.name;
    }
  }

  Future<void> _loadCompanies() async {
    final response = await CompanyAllService().getCompanies();
    for (var c in response.data) {
      companyMap[c.id] = c.name;
    }
  }

  // ==================== FIX: Load ALL requests from all pages ====================
  Future<void> loadAllRequests() async {
    try {
      setState(() => isLoading = true);

      List<UpdateRequest> allFetchedRequests = [];
      String? nextUrl = null;
      bool hasMore = true;

      // First request to get initial data
      final firstResponse = await _service.getUpdateRequests();

      // Check if the response has the correct structure
      if (firstResponse.results.isNotEmpty) {
        allFetchedRequests.addAll(firstResponse.results);
      }

      // Check if there are more pages
      // We need to manually fetch all pages since the service only returns one page
      // Let's use the API URL directly with pagination
      int page = 1;
      bool morePages = true;

      while (morePages) {
        page++;
        try {
          final response = await http.post(
            Uri.parse('${ApiUrls.updateRequestList}?page=$page'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({"full": true}),
          );

          if (response.statusCode == 200) {
            final jsonData = jsonDecode(response.body);
            final inner = jsonData['results'];
            if (inner is Map<String, dynamic>) {
              final resultsList = inner['results'];
              if (resultsList is List && resultsList.isNotEmpty) {
                for (var item in resultsList) {
                  allFetchedRequests.add(UpdateRequest.fromJson(item));
                }
              } else {
                morePages = false;
              }
            } else {
              morePages = false;
            }
          } else {
            morePages = false;
          }
        } catch (e) {
          print("Error fetching page $page: $e");
          morePages = false;
        }
      }

      if (mounted) {
        setState(() {
          // Sort by requestId in descending order (most recent first)
          allRequests = allFetchedRequests..sort((a, b) => b.requestId.compareTo(a.requestId));
          applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load update requests: $e")),
        );
      }
    }
  }

  void applyFilters() {
    if (searchQuery.isEmpty) {
      filteredRequests = List.from(allRequests);
    } else {
      final query = searchQuery.toLowerCase();
      filteredRequests = allRequests.where((r) {
        switch (filterType) {
          case 'Product Name':
            return r.product.name.toLowerCase().contains(query);
          case 'Requested By':
            return r.requestedBy.name.toLowerCase().contains(query);
          case 'Status':
            return r.status.toLowerCase().contains(query);
          default:
            return false;
        }
      }).toList();
    }
    applyPagination();
  }

  void applyPagination() {
    if (filteredRequests.isEmpty) {
      paginatedRequests = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }
    totalPages = (filteredRequests.length / itemsPerPage).ceil();
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    if (end > filteredRequests.length) end = filteredRequests.length;
    paginatedRequests = filteredRequests.sublist(start, end);
    setState(() {});
  }

  void nextPage() {
    if (currentPage < totalPages) {
      setState(() { currentPage++; applyPagination(); });
    }
  }

  void previousPage() {
    if (currentPage > 1) {
      setState(() { currentPage--; applyPagination(); });
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() { currentPage = page; applyPagination(); });
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
      filterType = 'Product Name';
      _searchController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  void exportExcel() {
    if (filteredRequests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export'), backgroundColor: Colors.orange),
      );
      return;
    }

    final file = excel.Excel.createExcel();
    final sheet = file['Update Requests'];
    sheet.appendRow(["SR No", "Status", "Requested By", "Product Name", "Price", "Created At"]);
    int srNo = 1;
    for (var r in filteredRequests) {
      sheet.appendRow([
        srNo++,
        r.status,
        r.requestedBy.name,
        r.product.name,
        r.product.price,
        r.createdAt,
      ]);
    }
    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "update_requests.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> exportPDF() async {
    if (filteredRequests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export'), backgroundColor: Colors.orange),
      );
      return;
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: ["SR No", "Status", "Requested By", "Product Name", "Price", "Created"],
            data: filteredRequests.asMap().entries.map((entry) {
              final r = entry.value;
              final srNo = entry.key + 1;
              return [
                srNo.toString(),
                r.status,
                r.requestedBy.name,
                r.product.name,
                r.product.price.toString(),
                r.createdAt
              ];
            }).toList(),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void exportDOC() {
    if (filteredRequests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No data to export'), backgroundColor: Colors.orange),
      );
      return;
    }

    final content = StringBuffer();
    content.writeln("Product Update Requests\n");
    content.writeln("=" * 50);
    int srNo = 1;
    for (var r in filteredRequests) {
      content.writeln("SR No: ${srNo++}");
      content.writeln("Status: ${r.status}");
      content.writeln("Requested By: ${r.requestedBy.name}");
      content.writeln("Product: ${r.product.name}");
      content.writeln("Price: ₹${r.product.price}");
      content.writeln("Created: ${r.createdAt}");
      content.writeln("-" * 30);
    }
    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "update_requests.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void approveRequest(int requestId) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final response = await _service.approveUpdate(requestId);
      if (response.status) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: Colors.green),
        );
        await loadAllRequests();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void rejectRequest(int requestId) {
    TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEF2F2), Color(0xFFFFE5E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.cancel, color: Colors.red, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Reject Update Request",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: reasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Enter rejection reason...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final reason = reasonController.text.trim();
                          if (reason.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please enter a reason")),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          if (_isProcessing) return;
                          setState(() => _isProcessing = true);
                          try {
                            final response = await _service.rejectUpdate(requestId, reason);
                            if (response.status) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(response.message), backgroundColor: Colors.orange),
                              );
                              await loadAllRequests();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(response.message), backgroundColor: Colors.red),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                            );
                          } finally {
                            if (mounted) setState(() => _isProcessing = false);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Reject"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- Helper Methods for Display ----------
  String _getValueName(String key, String? rawValue) {
    if (rawValue == null || rawValue.trim().isEmpty) return '-';
    final String trimmed = rawValue.trim();
    int? id = int.tryParse(trimmed);
    if (id == null) return trimmed;
    switch (key) {
      case 'unit':
        return unitMap[id] ?? trimmed;
      case 'brand':
        return brandMap[id] ?? trimmed;
      case 'category':
        return categoryMap[id] ?? trimmed;
      case 'subcategory':
        return subcategoryMap[id] ?? trimmed;
      case 'company':
        return companyMap[id] ?? trimmed;
      default:
        return trimmed;
    }
  }

  String _formatLabel(String key) {
    final labels = {
      'productName': 'Product Name',
      'category': 'Category',
      'subCategory': 'Sub Category',
      'brand': 'Brand',
      'unit': 'Unit',
      'price': 'Price',
      'company': 'Company',
      'description': 'Description',
      'thumbnail': 'New Thumbnail',
      'deleteImages': 'Delete Images',
      'deleteVideos': 'Delete Videos',
    };
    return labels[key] ?? key;
  }

  String _formatValue(String key, String value) {
    if (key == 'price') {
      return '₹$value';
    }
    return value;
  }

  // Helper to convert any value to readable string
  String _getReadableValue(dynamic value) {
    if (value == null) return '-';
    if (value is String) return value;
    if (value is int) return value.toString();
    if (value is double) return value.toString();
    if (value is List) {
      return value.map((e) => e.toString()).join(', ');
    }
    if (value is Map) {
      return value.entries.map((e) => "${e.key}: ${e.value}").join(', ');
    }
    return value.toString();
  }

  // ---------- Premium Popup (FIXED OVERFLOWS) ----------
  void showUpdatePopup(UpdateRequest request) {
    final bool isPending = request.status.toLowerCase() == 'pending';

    // Variants data
    List<VariantUpdate> variants = request.updatedData.variants;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.transparent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              double dialogWidth = constraints.maxWidth * 0.9;
              if (constraints.maxWidth > 600) dialogWidth = 600;
              if (constraints.maxWidth > 800) dialogWidth = 700;
              return Container(
                width: dialogWidth,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      const Color(0xFFF8F9FA),
                    ],
                  ),
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
                    // Premium Header (FIXED OVERFLOW)
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_premiumPrimary, _premiumSecondary],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_note, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Update Request",
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  request.product.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 20),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Scrollable Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status Row (FIXED OVERFLOW using Wrap)
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                _premiumStatusChip(
                                  request.status,
                                  request.status == 'approved'
                                      ? Colors.green
                                      : (request.status == 'rejected' ? Colors.red : Colors.orange),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Request Details Section
                            _buildPremiumSection(
                              title: "Request Details",
                              icon: Icons.info_outline,
                              children: [
                                _infoRow("Status", request.status),
                                _infoRow("Requested By", request.requestedBy.name),
                                _infoRow("Email", request.requestedBy.email),
                                _infoRow("Created At", request.createdAt),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Current Product Information Section
                            _buildPremiumSection(
                              title: "Current Product Information",
                              icon: Icons.shopping_bag_outlined,
                              children: [
                                _infoRow("Product Name", request.product.name),
                                _infoRow("Price", "₹${request.product.price}"),
                                if (request.product.thumbnail.isNotEmpty)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      const Text(
                                        "Current Thumbnail",
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF6B7280),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          request.product.thumbnail,
                                          height: 150,
                                          width: double.infinity,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Container(
                                            height: 150,
                                            color: Colors.grey.shade200,
                                            child: const Icon(Icons.broken_image, size: 50),
                                          ),
                                          loadingBuilder: (context, child, loadingProgress) {
                                            if (loadingProgress == null) return child;
                                            return Container(
                                              height: 150,
                                              color: Colors.grey.shade100,
                                              child: const Center(
                                                child: CircularProgressIndicator(strokeWidth: 2),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Thumbnail Update
                            if (request.updatedData.thumbnail != null)
                              _buildPremiumSection(
                                title: "New Thumbnail",
                                icon: Icons.image,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      request.updatedData.thumbnail!,
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 200,
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.broken_image, size: 50),
                                      ),
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          height: 200,
                                          color: Colors.grey.shade100,
                                          child: const Center(
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 20),

                            // Delete Images Section
                            if (request.updatedData.deleteImages.isNotEmpty)
                              _buildPremiumSection(
                                title: "Images to Delete (${request.updatedData.deleteImages.length})",
                                icon: Icons.delete_forever,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: request.updatedData.deleteImages.map((url) {
                                      return Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.red.shade300),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            url.toString(),
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => Container(
                                              color: Colors.red.shade50,
                                              child: Icon(Icons.broken_image, color: Colors.red.shade300),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 20),

                            // Delete Videos Section
                            if (request.updatedData.deleteVideos.isNotEmpty)
                              _buildPremiumSection(
                                title: "Videos to Delete (${request.updatedData.deleteVideos.length})",
                                icon: Icons.delete_forever,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: request.updatedData.deleteVideos.map((url) {
                                      return Container(
                                        width: 150,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.orange.shade300),
                                        ),
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                url.toString(),
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                                errorBuilder: (_, __, ___) => Container(
                                                  color: Colors.orange.shade50,
                                                  child: Icon(Icons.broken_image, color: Colors.orange.shade300),
                                                ),
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.5),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.play_arrow,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 20),

                            // Variants Section - Showing key-value pairs
                            if (variants.isNotEmpty)
                              _buildPremiumSection(
                                title: "Variants (${variants.length})",
                                icon: Icons.settings_input_component,
                                children: [
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: variants.length,
                                    itemBuilder: (context, index) {
                                      final v = variants[index];
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [_premiumPrimary.withOpacity(0.05), _premiumSecondary.withOpacity(0.05)],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: _premiumPrimary.withOpacity(0.1)),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // SKU and Stock in header
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    "SKU: ${v.sku}",
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 13,
                                                      color: _premiumPrimary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    "Stock: ${v.stockQuantity}",
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),

                                            // Price
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  "Price: ₹${v.price}",
                                                  style: const TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Color(0xFF1A1A2E),
                                                  ),
                                                ),
                                              ],
                                            ),

                                            // Attributes - Display as key-value pairs
                                            if (v.attributes.isNotEmpty) ...[
                                              const SizedBox(height: 8),
                                              const Divider(thickness: 0.5),
                                              const SizedBox(height: 8),
                                              Text(
                                                "Attributes",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: _premiumPrimary.withOpacity(0.7),
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade50,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Wrap(
                                                  spacing: 6,
                                                  runSpacing: 4,
                                                  children: v.attributes.entries.map((entry) {
                                                    return Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: _premiumPrimary.withOpacity(0.08),
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: Border.all(
                                                          color: _premiumPrimary.withOpacity(0.15),
                                                        ),
                                                      ),
                                                      child: Wrap(
                                                        crossAxisAlignment: WrapCrossAlignment.center,
                                                        spacing: 4,
                                                        runSpacing: 2,
                                                        children: [
                                                          Text(
                                                            "${entry.key}:",
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w600,
                                                              color: _premiumPrimary,
                                                            ),
                                                          ),
                                                          Text(
                                                            _getReadableValue(entry.value),
                                                            style: TextStyle(
                                                              fontSize: 11,
                                                              color: const Color(0xFF1A1A2E),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Action Buttons
                    if (isPending)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isProcessing ? null : () {
                                  Navigator.pop(context);
                                  approveRequest(request.requestId);
                                },
                                icon: const Icon(Icons.check_circle, size: 18),
                                label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isProcessing ? null : () {
                                  Navigator.pop(context);
                                  rejectRequest(request.requestId);
                                },
                                icon: const Icon(Icons.cancel, size: 18),
                                label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        );
      },
    );
  }

  Widget _premiumStatusChip(String label, Color color, {IconData? icon}) {
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
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_premiumPrimary, _premiumSecondary]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {bool isLong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Color(0xFF1A1A2E),
              ),
              maxLines: isLong ? 3 : null,
              overflow: isLong ? TextOverflow.ellipsis : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: isMobile
          ? Column(
        children: [
          Row(
            children: [
              _buildFilterDropdown(),
              const SizedBox(width: 12),
              Expanded(child: _buildSearchField()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildExportIcons(),
              Row(
                children: [
                  Text("Total: ${filteredRequests.length}"),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: resetFilters,
                    icon: const Icon(Icons.refresh),
                    color: Colors.red,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ],
              ),
            ],
          ),
        ],
      )
          : Row(
        children: [
          _buildFilterDropdown(),
          const SizedBox(width: 12),
          Expanded(child: _buildSearchField()),
          const SizedBox(width: 12),
          _buildExportIcons(),
          const SizedBox(width: 12),
          Text("Total: ${filteredRequests.length}"),
          IconButton(
            onPressed: resetFilters,
            icon: const Icon(Icons.refresh),
            color: Colors.red,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      width: 140,
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
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
          isExpanded: true,
          onChanged: (String? newValue) {
            setState(() {
              filterType = newValue!;
              currentPage = 1;
              applyFilters();
            });
          },
          items: ['Product Name', 'Requested By', 'Status']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search by $filterType...",
          prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF6366F1)),
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
    );
  }

  Widget _buildExportIcons() {
    return Row(
      children: [
        Tooltip(
          message: "Export Excel",
          child: InkWell(
            onTap: exportExcel,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SizedBox(
                width: 20,
                height: 20,
                child: Image.asset(
                  "assets/icon/xls.png",
                  errorBuilder: (_, __, ___) => const Icon(Icons.table_chart, size: 20),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "Export PDF",
          child: InkWell(
            onTap: exportPDF,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SizedBox(
                width: 20,
                height: 20,
                child: Image.asset(
                  "assets/icon/pdf.png",
                  errorBuilder: (_, __, ___) => const Icon(Icons.picture_as_pdf, size: 20),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "Export DOC",
          child: InkWell(
            onTap: exportDOC,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: SizedBox(
                width: 20,
                height: 20,
                child: Image.asset(
                  "assets/icon/doc.png",
                  errorBuilder: (_, __, ___) => const Icon(Icons.description, size: 20),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tableHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      constraints: const BoxConstraints(minHeight: 40),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _tableCell(String text, {VoidCallback? onTap, bool isBold = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 45, maxHeight: 60),
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
    if (filteredRequests.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(
        minHeight: 70,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {

          // Mobile
          if (constraints.maxWidth < 700) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Show "),
                      Container(
                        height: 30,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButton<int>(
                          value: itemsPerPage,
                          underline: const SizedBox(),
                          items: rowsPerPageOptions
                              .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.toString()),
                          ))
                              .toList(),
                          onChanged: changeItemsPerPage,
                        ),
                      ),
                      const Text(" entries"),
                    ],
                  ),

                  const SizedBox(height: 8),

                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _compactPageButton(
                          icon: Icons.chevron_left,
                          onTap: currentPage > 1 ? previousPage : null,
                        ),

                        if (totalPages <= 5)
                          ...List.generate(totalPages, (index) => _compactPageNumber(index + 1))
                        else if (currentPage <= 3) ...[
                          ...List.generate(4, (index) => _compactPageNumber(index + 1)),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ),
                          _compactPageNumber(totalPages),
                        ] else if (currentPage >= totalPages - 2) ...[
                          _compactPageNumber(1),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ),
                          ...List.generate(4, (index) => _compactPageNumber(totalPages - 3 + index)),
                        ] else ...[
                          _compactPageNumber(1),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ),
                          _compactPageNumber(currentPage - 1),
                          _compactPageNumber(currentPage),
                          _compactPageNumber(currentPage + 1),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 2),
                            child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
                          ),
                          _compactPageNumber(totalPages),
                        ],

                        _compactPageButton(
                          icon: Icons.chevron_right,
                          onTap: currentPage < totalPages ? nextPage : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 4),
                  Text(
                    "Showing ${(currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filteredRequests.length ? filteredRequests.length : currentPage * itemsPerPage} of ${filteredRequests.length}",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Desktop
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text("Show "),
                  Container(
                    height: 30,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border:
                      Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButton<int>(
                      value: itemsPerPage,
                      underline: const SizedBox(),
                      items: rowsPerPageOptions
                          .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(e.toString()),
                      ))
                          .toList(),
                      onChanged: changeItemsPerPage,
                    ),
                  ),
                  const Text(" entries"),
                  const SizedBox(width: 12),
                  Text(
                    "Showing ${(currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filteredRequests.length ? filteredRequests.length : currentPage * itemsPerPage} of ${filteredRequests.length}",
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),

              Row(
                children: [
                  _compactPageButton(
                    icon: Icons.chevron_left,
                    onTap: currentPage > 1 ? previousPage : null,
                  ),

                  if (totalPages <= 5)
                    ...List.generate(totalPages, (index) => _compactPageNumber(index + 1))
                  else if (currentPage <= 3) ...[
                    ...List.generate(4, (index) => _compactPageNumber(index + 1)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ),
                    _compactPageNumber(totalPages),
                  ] else if (currentPage >= totalPages - 2) ...[
                    _compactPageNumber(1),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ),
                    ...List.generate(4, (index) => _compactPageNumber(totalPages - 3 + index)),
                  ] else ...[
                    _compactPageNumber(1),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ),
                    _compactPageNumber(currentPage - 1),
                    _compactPageNumber(currentPage),
                    _compactPageNumber(currentPage + 1),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 2),
                      child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ),
                    _compactPageNumber(totalPages),
                  ],

                  _compactPageButton(
                    icon: Icons.chevron_right,
                    onTap: currentPage < totalPages ? nextPage : null,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _compactPageButton({required IconData icon, required VoidCallback? onTap}) {
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Product Update Requests",
          style: TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
                  // Table Header
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                            children: headerLabels.map((l) => _tableHeader(l)).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Table Body
                  Expanded(
                    child: filteredRequests.isEmpty
                        ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text(
                          "No update requests found",
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                        : SingleChildScrollView(
                      controller: _verticalController,
                      child: SingleChildScrollView(
                        controller: _rowsHorizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          border: TableBorder.all(color: Colors.grey.shade300),
                          columnWidths: columnWidths,
                          children: paginatedRequests.asMap().entries.map((entry) {
                            final index = entry.key;
                            final request = entry.value;
                            final bool isEven = index % 2 == 0;
                            final int srNo = filteredRequests.length - ((currentPage - 1) * itemsPerPage + index);
                            Color statusColor = request.status == 'approved'
                                ? Colors.green
                                : (request.status == 'rejected' ? Colors.red : Colors.orange);
                            return TableRow(
                              decoration: BoxDecoration(
                                color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                              ),
                              children: [
                                _tableCell(srNo.toString(), onTap: () => showUpdatePopup(request)),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      request.status,
                                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                _tableCell(request.requestedBy.name, onTap: () => showUpdatePopup(request)),
                                GestureDetector(
                                  onTap: () => showUpdatePopup(request),
                                  child: Container(
                                    height: 40,
                                    width: 40,
                                    margin: const EdgeInsets.all(2),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: Image.network(
                                        request.product.thumbnail,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.image_not_supported, size: 20),
                                        ),
                                        loadingBuilder: (_, child, progress) {
                                          if (progress == null) return child;
                                          return const Center(
                                            child: SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                                _tableCell(request.product.name, onTap: () => showUpdatePopup(request), isBold: true),
                                _tableCell("₹${request.product.price}", onTap: () => showUpdatePopup(request)),
                                _tableCell(request.createdAt.substring(0, 10), onTap: () => showUpdatePopup(request)),
                                Container(
                                  alignment: Alignment.center,
                                  child: IconButton(
                                    icon: const Icon(Icons.visibility, color: Color(0xFF4158D0), size: 18),
                                    onPressed: () => showUpdatePopup(request),
                                    tooltip: 'View Details',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
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
}