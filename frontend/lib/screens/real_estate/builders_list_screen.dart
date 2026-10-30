// lib/screens/real_estate/builders_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'dart:html' as html;
import '../../api/realestate_service.dart';
import '../../models/real_estate/builder_list_model.dart';

class BuildersListScreen extends StatefulWidget {
  const BuildersListScreen({super.key});

  @override
  State<BuildersListScreen> createState() => _BuildersListScreenState();
}

class _BuildersListScreenState extends State<BuildersListScreen> {
  final BuilderListService _service = BuilderListService();

  List<BuilderData> allBuilders = [];
  List<BuilderData> filteredBuilders = [];
  List<BuilderData> paginatedBuilders = [];

  bool isLoading = true;

  // Search & Filter
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String filterType = 'Name';

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

  // Column Widths - Added View Column
  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(60),   // SR No
    1: FixedColumnWidth(70),   // Logo  <-- NEW
    2: FixedColumnWidth(140),  // Name
    3: FixedColumnWidth(160),  // Short Info
    4: FixedColumnWidth(120),  // Email
    5: FixedColumnWidth(100),  // Phone
    6: FixedColumnWidth(100),  // Website
    7: FixedColumnWidth(80),   // Status
    8: FixedColumnWidth(100),  // Created
    9: FixedColumnWidth(70),   // View
  };

  final List<String> headerLabels = [
    "SR No", "Logo", "Name", "Short Info", "Email", "Phone", "Website", "Status", "Created", "View"
  ];

  static const Color _premiumPrimary = Color(0xFF4158D0);
  static const Color _premiumSecondary = Color(0xFFC850C0);

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();
    loadBuilders();
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

  Future<void> loadBuilders() async {
    try {
      final response = await _service.getBuilders();
      if (mounted) {
        setState(() {
          allBuilders = response.data;
          allBuilders.sort((a, b) => b.id.compareTo(a.id));
          applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load builders: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void applyFilters() {
    filteredBuilders = allBuilders.where((b) {
      bool matchesSearch = true;
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        switch (filterType) {
          case 'Name':
            matchesSearch = b.name.toLowerCase().contains(query);
            break;
          case 'Email':
            matchesSearch = (b.email ?? '').toLowerCase().contains(query);
            break;
          case 'Phone':
            matchesSearch = (b.phone ?? '').toLowerCase().contains(query);
            break;
          default:
            matchesSearch = b.name.toLowerCase().contains(query);
        }
      }
      return matchesSearch;
    }).toList();

    applyPagination();
  }

  void applyPagination() {
    if (filteredBuilders.isEmpty) {
      paginatedBuilders = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }

    totalPages = (filteredBuilders.length / itemsPerPage).ceil();
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;

    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > filteredBuilders.length) endIndex = filteredBuilders.length;
    paginatedBuilders = filteredBuilders.sublist(startIndex, endIndex);
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
      filterType = 'Name';
      _searchController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  String formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  // ==================== DETAILS POPUP ====================
  // Removed ID from popup header
  void showDetailsPopup(BuilderData builder) {
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
                  // Header - Removed ID
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
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: (builder.logo != null && builder.logo!.isNotEmpty)
                              ? Image.network(
                            builder.logo!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.business_center,
                              color: Colors.white,
                              size: 28,
                            ),
                          )
                              : const Icon(
                            Icons.business_center,
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
                                builder.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: builder.isActive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  builder.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: builder.isActive ? Colors.green : Colors.red,
                                  ),
                                ),
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

                          // Logo Preview Section
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.grey.shade300),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: (builder.logo != null && builder.logo!.isNotEmpty)
                                      ? Image.network(
                                    builder.logo!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => Icon(
                                      Icons.broken_image,
                                      size: 40,
                                      color: Colors.grey.shade400,
                                    ),
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return const Center(
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      );
                                    },
                                  )
                                      : Icon(
                                    Icons.business,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  builder.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1A1A2E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildInfoSection(
                            'Builder Information',
                            Icons.info_outline,
                            [
                              _infoRow('Name', builder.name),
                              _infoRow('Short Info', builder.shortInfo),
                              _infoRow('Email', builder.email ?? '-'),
                              _infoRow('Phone', builder.phone ?? '-'),
                              _infoRow('Website', builder.website ?? '-'),
                              _infoRow('Status', builder.isActive ? 'Active' : 'Inactive'),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildInfoSection(
                            'Location',
                            Icons.location_on,
                            [
                              _infoRow('Latitude', builder.latitude ?? '-'),
                              _infoRow('Longitude', builder.longitude ?? '-'),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildInfoSection(
                            'Timestamps',
                            Icons.calendar_today,
                            [
                              _infoRow('Created', formatDate(builder.createdAt)),
                              _infoRow('Updated', formatDate(builder.updatedAt)),
                            ],
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
      ),
    );
  }

  // ==================== UI HELPERS ====================
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
            width: 100,
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

  // ==================== EXPORT FUNCTIONS ====================
  void exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['Builders'];

    sheet.appendRow([
      "SR No", "Name", "Short Info", "Email", "Phone", "Website", "Status", "Created"
    ]);

    int srNo = filteredBuilders.length;
    for (var b in filteredBuilders) {
      sheet.appendRow([
        srNo--,
        b.name,
        b.shortInfo,
        b.email ?? '-',
        b.phone ?? '-',
        b.website ?? '-',
        b.isActive ? 'Active' : 'Inactive',
        formatDate(b.createdAt),
      ]);
    }

    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "builders.xlsx")
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
            headers: ["SR No", "Name", "Short Info", "Email", "Phone", "Status"],
            data: List.generate(filteredBuilders.length, (index) {
              final b = filteredBuilders[index];
              final srNo = filteredBuilders.length - index;
              return [
                srNo.toString(),
                b.name,
                b.shortInfo,
                b.email ?? '-',
                b.phone ?? '-',
                b.isActive ? 'Active' : 'Inactive',
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
    content.writeln("Builders List\n");
    content.writeln("=" * 50);

    int srNo = filteredBuilders.length;
    for (var b in filteredBuilders) {
      content.writeln("SR No: ${srNo--}");
      content.writeln("Name: ${b.name}");
      content.writeln("Short Info: ${b.shortInfo}");
      content.writeln("Email: ${b.email ?? '-'}");
      content.writeln("Phone: ${b.phone ?? '-'}");
      content.writeln("Website: ${b.website ?? '-'}");
      content.writeln("Status: ${b.isActive ? 'Active' : 'Inactive'}");
      content.writeln("Created: ${formatDate(b.createdAt)}");
      content.writeln("-" * 30);
    }

    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "builders.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ==================== FILTER SECTION ====================
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
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
                  onChanged: (String? newValue) {
                    setState(() {
                      filterType = newValue!;
                      currentPage = 1;
                      applyFilters();
                    });
                  },
                  items: ['Name', 'Email', 'Phone']
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
                  prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF6366F1)),
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildExportIcons(),
                Row(
                  children: [
                    Text(
                      "Total: ${filteredBuilders.length}",
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
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
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
                      onChanged: (String? newValue) {
                        setState(() {
                          filterType = newValue!;
                          currentPage = 1;
                          applyFilters();
                        });
                      },
                      items: ['Name', 'Email', 'Phone']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
                        prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF6366F1)),
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

                _buildExportIcons(),
                const SizedBox(width: 8),

                Text(
                  "Total: ${filteredBuilders.length}",
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
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
                    children: headerLabels.map((label) => _tableHeader(label)).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Body
          Expanded(
            child: filteredBuilders.isEmpty
                ? const Center(child: Text("No builders found"))
                : SingleChildScrollView(
              controller: _verticalController,
              child: SingleChildScrollView(
                controller: _rowsHorizontalController,
                scrollDirection: Axis.horizontal,
                child: Table(
                  border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                  columnWidths: columnWidths,
                  children: List.generate(paginatedBuilders.length, (rowIndex) {
                    final b = paginatedBuilders[rowIndex];
                    final isEven = rowIndex % 2 == 0;
                    final srNo = filteredBuilders.length - ((currentPage - 1) * itemsPerPage + rowIndex);

                    return TableRow(
                      decoration: BoxDecoration(
                        color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                      ),
                      children: [
                        _tableCell(srNo.toString(), onTap: () => showDetailsPopup(b)),

                        // 👇 LOGO CELL (NEW)
                        GestureDetector(
                          onTap: () => showDetailsPopup(b),
                          child: Container(
                            height: 42,
                            alignment: Alignment.center,
                            child: _buildLogoThumb(b.logo),
                          ),
                        ),

                        _tableCell(b.name, onTap: () => showDetailsPopup(b), maxLines: 2),
                        _tableCell(b.shortInfo, onTap: () => showDetailsPopup(b), maxLines: 2),
                        _tableCell(b.email ?? '-', onTap: () => showDetailsPopup(b)),
                        _tableCell(b.phone ?? '-', onTap: () => showDetailsPopup(b)),
                        _tableCell(b.website ?? '-', onTap: () => showDetailsPopup(b)),

                        // Status
                        Container(
                          height: 42,
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: b.isActive ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                b.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: b.isActive ? Colors.green[700] : Colors.red[700],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        _tableCell(formatDate(b.createdAt), onTap: () => showDetailsPopup(b)),

                        // View Column
                        Container(
                          height: 42,
                          padding: const EdgeInsets.all(2),
                          child: IconButton(
                            icon: const Icon(Icons.visibility, color: Color(0xFF4158D0), size: 18),
                            onPressed: () => showDetailsPopup(b),
                            tooltip: 'View Details',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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

  Widget _buildLogoThumb(String? logoUrl) {
    if (logoUrl == null || logoUrl.isEmpty) {
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(Icons.business, size: 18, color: Colors.grey.shade500),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(
        logoUrl,
        width: 32,
        height: 32,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(Icons.broken_image, size: 18, color: Colors.grey.shade500),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
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
    if (filteredBuilders.isEmpty) return const SizedBox.shrink();

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
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
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
                    "${currentPage * itemsPerPage > filteredBuilders.length ? filteredBuilders.length : currentPage * itemsPerPage} "
                    "of ${filteredBuilders.length}",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          );

          final pageButtons = [
            _compactPageButton(icon: Icons.chevron_left, onTap: currentPage > 1 ? previousPage : null),
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
            _compactPageButton(icon: Icons.chevron_right, onTap: currentPage < totalPages ? nextPage : null),
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
          "Builders",
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