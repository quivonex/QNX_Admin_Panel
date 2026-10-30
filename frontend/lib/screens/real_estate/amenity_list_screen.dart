// lib/screens/real_estate/amenity_management_screen.dart
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel;
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:html' as html;
import '../../api/realestate_service.dart';
import '../../models/real_estate/amenity_model.dart';

class AmenityManagementScreen extends StatefulWidget {
  const AmenityManagementScreen({super.key});

  @override
  State<AmenityManagementScreen> createState() => _AmenityManagementScreenState();
}

class _AmenityManagementScreenState extends State<AmenityManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  final _filterNameController = TextEditingController();

  bool _isActive = true;
  bool _isLoading = false;
  bool _isEdit = false;
  int? _editId;

  final RealEstateService _service = RealEstateService();

  List<Amenity> allAmenities = [];
  List<Amenity> filteredAmenities = [];
  List<Amenity> paginatedAmenities = [];

  // Pagination Variables
  int currentPage = 1;
  int itemsPerPage = 5;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 50];

  // Filter Variables
  String filterName = '';

  // Search Result
  Amenity? searchedAmenity;

  @override
  void initState() {
    super.initState();
    loadAmenities();
  }

  Future<void> loadAmenities() async {
    try {
      final response = await _service.getAmenities();
      if (mounted) {
        setState(() {
          allAmenities = response.data;
          // Sort by createdAt descending (newest first)
          allAmenities.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load amenities")),
        );
      }
    }
  }

  void applyFilters() {
    filteredAmenities = allAmenities.where((amenity) {
      bool matchesName = filterName.isEmpty ||
          amenity.name.toLowerCase().contains(filterName.toLowerCase());
      return matchesName;
    }).toList();

    applyPagination();
  }

  void applyPagination() {
    if (filteredAmenities.isEmpty) {
      paginatedAmenities = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }

    totalPages = (filteredAmenities.length / itemsPerPage).ceil();

    if (currentPage > totalPages) {
      currentPage = totalPages;
    }
    if (currentPage < 1) {
      currentPage = 1;
    }

    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;

    if (startIndex >= filteredAmenities.length) {
      paginatedAmenities = [];
    } else {
      if (endIndex > filteredAmenities.length) {
        endIndex = filteredAmenities.length;
      }
      paginatedAmenities = filteredAmenities.sublist(startIndex, endIndex);
    }

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
      filterName = '';
      _filterNameController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  void _editAmenity(Amenity amenity) {
    setState(() {
      _isEdit = true;
      _editId = amenity.id;
      _nameController.text = amenity.name;
      _isActive = amenity.isActive;
    });
  }

  Future<void> _createAmenity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amenity = Amenity(
        id: 0,
        name: _nameController.text.trim(),
        isActive: _isActive,
        createdAt: '',
      );

      final response = await _service.createAmenity(amenity);

      setState(() => _isLoading = false);

      if (response.data.id != 0) {
        clearForm();
        loadAmenities();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateAmenity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Note: Update API endpoint not provided, this is a placeholder
      // You'll need to implement update in your service
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Update functionality coming soon'),
          backgroundColor: Colors.orange,
        ),
      );

      setState(() {
        _isLoading = false;
        _isEdit = false;
      });
      clearForm();
      loadAmenities();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAmenity(int id) async {
    // Note: Delete API endpoint not provided, this is a placeholder
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Amenity'),
        content: const Text('Are you sure you want to delete this amenity?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delete functionality coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
              // Remove from list temporarily
              setState(() {
                allAmenities.removeWhere((a) => a.id == id);
                applyFilters();
              });
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void clearForm() {
    _nameController.clear();
    _isActive = true;
    _isEdit = false;
    _editId = null;
  }

  // Export Functions
  void _exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['Amenities'];

    sheet.appendRow([
      'SR No', 'Name', 'Active', 'Created At'
    ]);

    int srNo = filteredAmenities.length;
    for (var a in filteredAmenities) {
      sheet.appendRow([
        srNo--,
        a.name,
        a.isActive ? 'YES' : 'NO',
        a.createdAt,
      ]);
    }

    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'amenities.xlsx')
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> _exportPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Table.fromTextArray(
          headers: ['SR No', 'Name', 'Active', 'Created At'],
          data: List.generate(filteredAmenities.length, (index) {
            final a = filteredAmenities[index];
            final srNo = filteredAmenities.length - index;
            return [
              srNo.toString(),
              a.name,
              a.isActive ? 'YES' : 'NO',
              a.createdAt,
            ];
          }),
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void _exportDOC() {
    final content = StringBuffer();
    content.writeln('Amenities List\n');
    content.writeln('=' * 50);
    content.writeln();

    int srNo = filteredAmenities.length;
    for (var a in filteredAmenities) {
      content.writeln('SR No: ${srNo--}');
      content.writeln('Name: ${a.name}');
      content.writeln('Active: ${a.isActive ? 'YES' : 'NO'}');
      content.writeln('Created: ${a.createdAt}');
      content.writeln('-' * 30);
    }

    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'amenities.doc')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Amenity Management",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 900;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Search Result Display
                if (searchedAmenity != null) ...[
                  _buildSearchResult(),
                  const SizedBox(height: 24),
                ],

                // Filter Section
                _buildFilterSection(),
                const SizedBox(height: 24),

                if (isMobile) ...[
                  _buildFormCard(),
                  const SizedBox(height: 24),
                  _buildCustomTable(),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildFormCard()),
                      const SizedBox(width: 24),
                      Expanded(flex: 3, child: _buildCustomTable()),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // Filter Section
  Widget _buildFilterSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          // Search Input
          Expanded(
            child: TextField(
              controller: _filterNameController,
              decoration: InputDecoration(
                labelText: "Filter by Name",
                hintText: "Enter amenity name...",
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: Color(0xFF6366F1),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                suffixIcon: filterName.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _filterNameController.clear();
                    setState(() {
                      filterName = '';
                      currentPage = 1;
                      applyFilters();
                    });
                  },
                )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  filterName = value;
                  currentPage = 1;
                  applyFilters();
                });
              },
            ),
          ),

          const SizedBox(width: 12),

          // Reset Button
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: resetFilters,
              icon: const Icon(Icons.refresh),
              color: Colors.red,
              tooltip: "Reset",
            ),
          ),

          const SizedBox(width: 12),

          // Export Buttons
          _buildExportIcons(),

          const SizedBox(width: 12),

          // Count Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${filteredAmenities.length}",
              style: const TextStyle(
                color: Color(0xFF4338CA),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
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
            onTap: _exportExcel,
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
            onTap: _exportPDF,
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
            onTap: _exportDOC,
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

  // Search Result
  Widget _buildSearchResult() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search,
              color: Color(0xFF6366F1),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Search Result",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4338CA),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  searchedAmenity!.name,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: searchedAmenity!.isActive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        searchedAmenity!.isActive ? "Active" : "Inactive",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: searchedAmenity!.isActive
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "ID: ${searchedAmenity!.id}",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.close,
                size: 18,
                color: Color(0xFF4338CA),
              ),
              onPressed: () {
                setState(() {
                  searchedAmenity = null;
                  _searchController.clear();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // Form Card
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEdit ? "Edit Amenity" : "Create New Amenity",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),

            // Name Field
            _buildTextField(
              _nameController,
              "Amenity Name",
              Icons.label_outlined,
            ),
            const SizedBox(height: 16),

            // Active Status
            Row(
              children: [
                Switch(
                  value: _isActive,
                  activeColor: const Color(0xFF6366F1),
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                const Text(
                  "Active Status",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : (_isEdit ? _updateAmenity : _createAmenity),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  _isEdit ? "Update Amenity" : "Create Amenity",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            if (_isEdit)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton(
                  onPressed: clearForm,
                  child: const Center(
                    child: Text(
                      "Cancel Edit",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        int maxLines = 1,
      }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (v) => (v == null || v.isEmpty) ? "$label is required" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
      ),
    );
  }

  // Custom Table
  Widget _buildCustomTable() {
    const double idWidth = 60;
    const double nameWidth = 180;
    const double statusWidth = 100;
    const double actionsWidth = 120;
    final double totalWidth = idWidth + nameWidth + statusWidth + actionsWidth;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
          // Scrollable Table
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              child: Table(
                columnWidths: {
                  0: FixedColumnWidth(idWidth),
                  1: FixedColumnWidth(nameWidth),
                  2: FixedColumnWidth(statusWidth),
                  3: FixedColumnWidth(actionsWidth),
                },
                border: TableBorder(
                  horizontalInside: BorderSide(color: Colors.grey.shade300),
                ),
                children: [
                  // Header
                  TableRow(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    children: [
                      _tableHeaderCell("SR No"),
                      _tableHeaderCell("Name"),
                      _tableHeaderCell("Status"),
                      _tableHeaderCell("Actions"),
                    ],
                  ),
                  // Data Rows
                  ...paginatedAmenities.asMap().entries.map((entry) {
                    int index = entry.key;
                    Amenity amenity = entry.value;
                    int srNo = paginatedAmenities.length - index;
                    return TableRow(
                      decoration: BoxDecoration(
                        color: index % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC),
                      ),
                      children: [
                        _tableCell(srNo.toString()),
                        _tableCell(amenity.name),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: amenity.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                amenity.isActive ? "Active" : "Inactive",
                                style: TextStyle(
                                  color: amenity.isActive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                              onPressed: () => _editAmenity(amenity),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => _deleteAmenity(amenity.id),
                            ),
                          ],
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Pagination
          if (filteredAmenities.isNotEmpty) _buildPagination(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _tableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // Pagination
  Widget _buildPagination() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600;

        if (isSmall) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildShowEntriesDropdown(),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        _getShowingText(),
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  children: [
                    _buildPageButtonPrevNext(prev: true),
                    ..._buildPageNumbers(),
                    _buildPageButtonPrevNext(prev: false),
                  ],
                ),
              ],
            ),
          );
        } else {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildShowEntriesDropdown(),
                    const SizedBox(width: 20),
                    Text(
                      _getShowingText(),
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildPageButtonPrevNext(prev: true),
                    ..._buildPageNumbers(),
                    _buildPageButtonPrevNext(prev: false),
                  ],
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildShowEntriesDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Text("Show: "),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: itemsPerPage,
              onChanged: changeItemsPerPage,
              items: rowsPerPageOptions.map((value) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
            ),
          ),
          const Text(" entries"),
        ],
      ),
    );
  }

  String _getShowingText() {
    final start = filteredAmenities.isEmpty ? 0 : (currentPage - 1) * itemsPerPage + 1;
    final end = currentPage * itemsPerPage > filteredAmenities.length
        ? filteredAmenities.length
        : currentPage * itemsPerPage;
    return "Showing $start to $end of ${filteredAmenities.length} entries";
  }

  List<Widget> _buildPageNumbers() {
    if (totalPages <= 5) {
      return List.generate(totalPages, (index) => _buildPageButton(index + 1));
    } else if (currentPage <= 3) {
      return [
        ...List.generate(4, (index) => _buildPageButton(index + 1)),
        _buildEllipsis(),
        _buildPageButton(totalPages),
      ];
    } else if (currentPage >= totalPages - 2) {
      return [
        _buildPageButton(1),
        _buildEllipsis(),
        ...List.generate(4, (index) => _buildPageButton(totalPages - 3 + index)),
      ];
    } else {
      return [
        _buildPageButton(1),
        _buildEllipsis(),
        _buildPageButton(currentPage - 1),
        _buildPageButton(currentPage),
        _buildPageButton(currentPage + 1),
        _buildEllipsis(),
        _buildPageButton(totalPages),
      ];
    }
  }

  Widget _buildPageButtonPrevNext({required bool prev}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        icon: Icon(prev ? Icons.chevron_left : Icons.chevron_right, size: 18),
        onPressed: prev
            ? (currentPage > 1 ? previousPage : null)
            : (currentPage < totalPages ? nextPage : null),
        color: const Color(0xFF6366F1),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
      ),
    );
  }

  Widget _buildPageButton(int pageNum) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
          currentPage == pageNum ? const Color(0xFF6366F1) : Colors.white,
          foregroundColor:
          currentPage == pageNum ? Colors.white : Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          minimumSize: const Size(32, 32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        onPressed: () => goToPage(pageNum),
        child: Text(pageNum.toString()),
      ),
    );
  }

  Widget _buildEllipsis() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: const Text(
        "...",
        style: TextStyle(fontSize: 13, color: Colors.grey),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    _filterNameController.dispose();
    super.dispose();
  }
}