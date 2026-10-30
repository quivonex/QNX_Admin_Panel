import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;
import '../../api/api_service.dart';
import '../../models/qnx_admin/user_enquiry_model.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class UserEnquiryScreen extends StatefulWidget {
  const UserEnquiryScreen({super.key});

  @override
  State<UserEnquiryScreen> createState() => _UserEnquiryScreenState();
}

class _UserEnquiryScreenState extends State<UserEnquiryScreen> {
  final UserEnquiryService _service = UserEnquiryService();

  // Filter Controller
  final TextEditingController _searchController = TextEditingController();

  List<UserEnquiry> allEnquiries = [];
  List<UserEnquiry> filteredEnquiries = [];
  List<UserEnquiry> paginatedEnquiries = [];

  bool isLoading = true;

  // Pagination
  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  // Filter Variables
  String searchQuery = '';
  String filterType = 'Name'; // 'Name', 'Email', 'Phone', 'Product'

  // Scroll controllers for linked horizontal scrolling
  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  // Column widths
  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(60),   // SR No
    1: FixedColumnWidth(120),  // Name
    2: FixedColumnWidth(180),  // Email
    3: FixedColumnWidth(120),  // Phone
    4: FixedColumnWidth(190),  // Product
    5: FixedColumnWidth(220),  // Address
    6: FixedColumnWidth(230),  // Message
    7: FixedColumnWidth(120),  // Date
  };

  final List<String> headerLabels = [
    "SR No", "Name", "Email", "Phone", "Product", "Address", "Message", "Date"
  ];

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final data = await _service.getEnquiries();
      if (mounted) {
        setState(() {
          // Sort by createdAt in descending order (most recent first)
          allEnquiries = data..sort((a, b) {
            // Handle null or empty dates
            String dateA = a.createdAt ?? '';
            String dateB = b.createdAt ?? '';
            return dateB.compareTo(dateA); // Descending order
          });
          applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load user enquiries")),
        );
      }
    }
  }

  void applyFilters() {
    if (searchQuery.isEmpty) {
      filteredEnquiries = allEnquiries;
    } else {
      filteredEnquiries = allEnquiries.where((enquiry) {
        final query = searchQuery.toLowerCase();
        if (filterType == 'Name') {
          return enquiry.name.toLowerCase().contains(query);
        } else if (filterType == 'Email') {
          return enquiry.email.toLowerCase().contains(query);
        } else if (filterType == 'Phone') {
          return enquiry.phone.contains(query);
        } else if (filterType == 'Product') {
          return enquiry.product.toLowerCase().contains(query);
        }
        return false;
      }).toList();
    }
    applyPagination();
  }

  void applyPagination() {
    if (filteredEnquiries.isEmpty) {
      paginatedEnquiries = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }

    totalPages = (filteredEnquiries.length / itemsPerPage).ceil();
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;

    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > filteredEnquiries.length) endIndex = filteredEnquiries.length;
    paginatedEnquiries = filteredEnquiries.sublist(startIndex, endIndex);

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

  // ---------- Export functions ----------
  void exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['User Enquiries'];

    sheet.appendRow(headerLabels);

    int srNo = 1;
    for (var e in filteredEnquiries) {
      sheet.appendRow([
        srNo++,
        e.name,
        e.email,
        e.phone,
        e.product,
        e.address,
        e.message,
        e.createdAt,
      ]);
    }

    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "user_enquiries.xlsx")
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
            headers: headerLabels,
            data: filteredEnquiries.asMap().entries.map((entry) {
              final e = entry.value;
              final srNo = entry.key + 1;
              return [
                srNo.toString(),
                e.name,
                e.email,
                e.phone,
                e.product,
                e.address,
                e.message,
                e.createdAt,
              ];
            }).toList(),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  void exportDOC() {
    final content = StringBuffer();

    content.writeln("User Enquiries List\n");
    content.writeln("=" * 50);

    int srNo = 1;
    for (var e in filteredEnquiries) {
      content.writeln("SR No: ${srNo++}");
      content.writeln("Name: ${e.name}");
      content.writeln("Email: ${e.email}");
      content.writeln("Phone: ${e.phone}");
      content.writeln("Product: ${e.product}");
      content.writeln("Address: ${e.address}");
      content.writeln("Message: ${e.message}");
      content.writeln("Date: ${e.createdAt}");
      content.writeln("-" * 30);
    }

    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "user_enquiries.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Widget _buildDateTimeCell(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return _tableCell('-');

    try {
      // Assuming the API returns ISO format like "2025-04-05T14:30:00"
      final dateTime = DateTime.parse(dateTimeStr);
      final dateFormatted = "${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year.toString().substring(2)}";
      final timeFormatted = "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              dateFormatted,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, color: Color(0xFF4B5563)),
            ),
            const SizedBox(height: 2),
            Text(
              timeFormatted,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ],
        ),
      );
    } catch (e) {
      return _tableCell(dateTimeStr);
    }
  }

  // ---------- UI Components ----------
  Widget _buildFilterSection() {
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
      child: Row(
        children: [
          // Filter Dropdown
          Container(
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
                isExpanded: true,
                icon: const Icon(
                  Icons.arrow_drop_down,
                  color: Color(0xFF6366F1),
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    filterType = newValue!;
                    currentPage = 1;
                    applyFilters();
                  });
                },
                items: const [
                  DropdownMenuItem(
                    value: 'Name',
                    child: Text('Name'),
                  ),
                  DropdownMenuItem(
                    value: 'Email',
                    child: Text('Email'),
                  ),
                  DropdownMenuItem(
                    value: 'Phone',
                    child: Text('Phone'),
                  ),
                  DropdownMenuItem(
                    value: 'Product',
                    child: Text('Product'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Search Box - Expanded to take remaining width
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
                  hintText: filterType == 'Name'
                      ? "Search by name..."
                      : filterType == 'Email'
                      ? "Search by email..."
                      : filterType == 'Phone'
                      ? "Search by phone..."
                      : "Search by product...",
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 16,
                    color: Color(0xFF6366F1),
                  ),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 12),
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

          // Export Icons
          _buildExportIcons(),

          const SizedBox(width: 12),

          // Total + Reset
          Row(
            children: [
              Text(
                "Total: ${filteredEnquiries.length}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
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
              child: Image.asset(
                "assets/icon/xls.png",
                height: 16,
                width: 16,
              ),
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
              child: Image.asset(
                "assets/icon/pdf.png",
                height: 20,
                width: 20,
              ),
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
              child: Image.asset(
                "assets/icon/doc.png",
                height: 20,
                width: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTable() {
    return Container(
      padding: const EdgeInsets.all(0),
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
          // Fixed header (horizontally scrollable)
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
          // Scrollable rows
          Expanded(
            child: filteredEnquiries.isEmpty
                ? const Center(child: Text("No user enquiries found"))
                : SingleChildScrollView(
              controller: _verticalController,
              child: SingleChildScrollView(
                controller: _rowsHorizontalController,
                scrollDirection: Axis.horizontal,
                child: Table(
                  border: TableBorder.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  columnWidths: columnWidths,
                  children: List.generate(paginatedEnquiries.length, (rowIndex) {
                    final enquiry = paginatedEnquiries[rowIndex];
                    final isEven = rowIndex % 2 == 0;
                    final int srNo = filteredEnquiries.length - ((currentPage - 1) * itemsPerPage + rowIndex);
                    return TableRow(
                      decoration: BoxDecoration(
                        color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                      ),
                      children: [
                        _tableCell(srNo.toString()),
                        _tableCell(enquiry.name),
                        _tableCell(enquiry.email),
                        _tableCell(enquiry.phone),
                        _tableCell(enquiry.product),
                        _tableCell(enquiry.address),
                        _tableCell(enquiry.message),
                        _buildDateTimeCell(enquiry.createdAt),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Pagination
          if (filteredEnquiries.isNotEmpty) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 700) {
            // Mobile layout
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Show ", style: TextStyle(fontSize: 11)),
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<int>(
                        value: itemsPerPage,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, size: 16),
                        style: const TextStyle(fontSize: 11),
                        items: rowsPerPageOptions
                            .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                            .toList(),
                        onChanged: changeItemsPerPage,
                      ),
                    ),
                    const Text(" entries", style: TextStyle(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _compactPageButton(
                      icon: Icons.chevron_left,
                      onTap: currentPage > 1 ? previousPage : null,
                    ),
                    ...List.generate(
                      totalPages > 3 ? 3 : totalPages,
                          (index) {
                        int pageNum;
                        if (totalPages <= 3) {
                          pageNum = index + 1;
                        } else if (currentPage == 1) {
                          pageNum = index + 1;
                        } else if (currentPage == totalPages) {
                          pageNum = totalPages - 2 + index;
                        } else {
                          pageNum = currentPage - 1 + index;
                        }
                        return _compactPageNumber(pageNum);
                      },
                    ),
                    _compactPageButton(
                      icon: Icons.chevron_right,
                      onTap: currentPage < totalPages ? nextPage : null,
                    ),
                  ],
                ),
              ],
            );
          } else {
            // Desktop layout
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Show entries + info
                Row(
                  children: [
                    const Text("Show ", style: TextStyle(fontSize: 11)),
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<int>(
                        value: itemsPerPage,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, size: 16),
                        style: const TextStyle(fontSize: 11),
                        items: rowsPerPageOptions
                            .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                            .toList(),
                        onChanged: changeItemsPerPage,
                      ),
                    ),
                    const Text(" entries", style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 8),
                    Text(
                      "Showing ${filteredEnquiries.isEmpty ? 0 : (currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filteredEnquiries.length ? filteredEnquiries.length : currentPage * itemsPerPage} of ${filteredEnquiries.length}",
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                // Right: Pagination controls
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

  Widget _tableCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF4B5563),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "User Enquiries",
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
            _buildFilterSection(),
            const SizedBox(height: 16),
            Expanded(child: _buildCustomTable()),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerHorizontalController.dispose();
    _rowsHorizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }
}

/*import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;
import '../api/api_service.dart';
import '../models/user_enquiry_model.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class UserEnquiryScreen extends StatefulWidget {
  const UserEnquiryScreen({super.key});

  @override
  State<UserEnquiryScreen> createState() => _UserEnquiryScreenState();
}

class _UserEnquiryScreenState extends State<UserEnquiryScreen> {
  final UserEnquiryService _service = UserEnquiryService();

  final TextEditingController _searchController = TextEditingController();

  List<UserEnquiry> allEnquiries = [];
  List<UserEnquiry> filteredEnquiries = [];
  List<UserEnquiry> paginatedEnquiries = [];

  bool isLoading = true;

  // Pagination
  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  // Filter Variables
  String searchQuery = '';
  String filterType = 'Name'; // 'Name', 'Email', 'Phone', 'Product'

  // Scroll controllers for linked horizontal scrolling
  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  // Column widths – increased date column for two lines
  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(60),   // ID
    1: FixedColumnWidth(120),  // Name
    2: FixedColumnWidth(180),  // Email
    3: FixedColumnWidth(100),  // Phone
    4: FixedColumnWidth(150),  // Product
    5: FixedColumnWidth(200),  // Address
    6: FixedColumnWidth(200),  // Message
    7: FixedColumnWidth(110),  // Date (now two lines)
  };

  final List<String> headerLabels = [
    "ID", "Name", "Email", "Phone", "Product", "Address", "Message", "Date"
  ];

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final data = await _service.getEnquiries();
      if (mounted) {
        setState(() {
          allEnquiries = data;
          applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load user enquiries")),
        );
      }
    }
  }

  // Format date to "dd/MM/yyyy\nHH:mm"
  String formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '-';
    try {
      DateTime dt = DateTime.parse(dateTimeStr);
      String datePart = DateFormat('dd/MM/yyyy').format(dt);
      String timePart = DateFormat('HH:mm').format(dt);
      return '$datePart\n$timePart';
    } catch (e) {
      return dateTimeStr;
    }
  }

  void applyFilters() {
    if (searchQuery.isEmpty) {
      filteredEnquiries = allEnquiries;
    } else {
      filteredEnquiries = allEnquiries.where((enquiry) {
        final query = searchQuery.toLowerCase();
        if (filterType == 'Name') {
          return enquiry.name.toLowerCase().contains(query);
        } else if (filterType == 'Email') {
          return enquiry.email.toLowerCase().contains(query);
        } else if (filterType == 'Phone') {
          return enquiry.phone.contains(query);
        } else if (filterType == 'Product') {
          return enquiry.product.toLowerCase().contains(query);
        }
        return false;
      }).toList();
    }
    applyPagination();
  }

  void applyPagination() {
    if (filteredEnquiries.isEmpty) {
      paginatedEnquiries = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }

    totalPages = (filteredEnquiries.length / itemsPerPage).ceil();
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;

    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > filteredEnquiries.length) endIndex = filteredEnquiries.length;
    paginatedEnquiries = filteredEnquiries.sublist(startIndex, endIndex);

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

  // ---------- Export functions ----------
  void exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['User Enquiries'];

    sheet.appendRow(headerLabels);

    for (var e in filteredEnquiries) {
      sheet.appendRow([
        e.id,
        e.name,
        e.email,
        e.phone,
        e.product,
        e.address,
        e.message,
        formatDateTime(e.createdAt).replaceAll('\n', ' '), // flatten for Excel
      ]);
    }

    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "user_enquiries.xlsx")
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
            headers: headerLabels,
            data: filteredEnquiries.map((e) => [
              e.id.toString(),
              e.name,
              e.email,
              e.phone,
              e.product,
              e.address,
              e.message,
              formatDateTime(e.createdAt).replaceAll('\n', ' '),
            ]).toList(),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  void exportDOC() {
    final content = StringBuffer();

    content.writeln("User Enquiries List\n");
    content.writeln("=" * 50);

    for (var e in filteredEnquiries) {
      content.writeln("ID: ${e.id}");
      content.writeln("Name: ${e.name}");
      content.writeln("Email: ${e.email}");
      content.writeln("Phone: ${e.phone}");
      content.writeln("Product: ${e.product}");
      content.writeln("Address: ${e.address}");
      content.writeln("Message: ${e.message}");
      content.writeln("Date: ${formatDateTime(e.createdAt)}");
      content.writeln("-" * 30);
    }

    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "user_enquiries.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ---------- UI Components ----------
  Widget _buildFilterSection() {
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
              // Filter type dropdown
              Container(
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
                    items: const [
                      DropdownMenuItem(value: 'Name', child: Text('Name')),
                      DropdownMenuItem(value: 'Email', child: Text('Email')),
                      DropdownMenuItem(value: 'Phone', child: Text('Phone')),
                      DropdownMenuItem(value: 'Product', child: Text('Product')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Search bar
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
                      hintText: filterType == 'Name'
                          ? "Search by name..."
                          : filterType == 'Email'
                          ? "Search by email..."
                          : filterType == 'Phone'
                          ? "Search by phone..."
                          : "Search by product...",
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
              ),
              const SizedBox(width: 12),

              // Export icons
              _buildExportIcons(),
              const SizedBox(width: 12),

              // Reset + total count
              Row(
                children: [
                  Text(
                    "Total: ${filteredEnquiries.length}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
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
              child: Image.asset(
                "assets/icon/xls.png",
                height: 20,
                width: 20,
              ),
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
              child: Image.asset(
                "assets/icon/pdf.png",
                height: 20,
                width: 20,
              ),
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
              child: Image.asset(
                "assets/icon/doc.png",
                height: 20,
                width: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTable() {
    return Container(
      padding: const EdgeInsets.all(0),
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
          // Fixed header (horizontally scrollable) – dark background
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2C3E50), // Dark header background
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
          // Scrollable rows (both horizontal and vertical) – zebra striping
          Expanded(
            child: filteredEnquiries.isEmpty
                ? const Center(child: Text("No user enquiries found"))
                : SingleChildScrollView(
              controller: _verticalController,
              child: SingleChildScrollView(
                controller: _rowsHorizontalController,
                scrollDirection: Axis.horizontal,
                child: Table(
                  border: TableBorder.all(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                  columnWidths: columnWidths,
                  children: List.generate(paginatedEnquiries.length, (rowIndex) {
                    final enquiry = paginatedEnquiries[rowIndex];
                    final isEven = rowIndex % 2 == 0;
                    return TableRow(
                      decoration: BoxDecoration(
                        color: isEven ? Colors.white : const Color(0xFFF5F5F5),
                      ),
                      children: [
                        _tableCell(enquiry.id.toString()),
                        _tableCell(enquiry.name),
                        _tableCell(enquiry.email),
                        _tableCell(enquiry.phone),
                        _tableCell(enquiry.product),
                        _tableCell(enquiry.address),
                        _tableCell(enquiry.message),
                        _tableCell(formatDateTime(enquiry.createdAt)), // formatted with newline
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Pagination
          if (filteredEnquiries.isNotEmpty) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 700) {
            // Mobile layout
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Show ", style: TextStyle(fontSize: 11)),
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<int>(
                        value: itemsPerPage,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, size: 16),
                        style: const TextStyle(fontSize: 11),
                        items: rowsPerPageOptions
                            .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                            .toList(),
                        onChanged: changeItemsPerPage,
                      ),
                    ),
                    const Text(" entries", style: TextStyle(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _compactPageButton(
                      icon: Icons.chevron_left,
                      onTap: currentPage > 1 ? previousPage : null,
                    ),
                    ...List.generate(
                      totalPages > 3 ? 3 : totalPages,
                          (index) {
                        int pageNum;
                        if (totalPages <= 3) {
                          pageNum = index + 1;
                        } else if (currentPage == 1) {
                          pageNum = index + 1;
                        } else if (currentPage == totalPages) {
                          pageNum = totalPages - 2 + index;
                        } else {
                          pageNum = currentPage - 1 + index;
                        }
                        return _compactPageNumber(pageNum);
                      },
                    ),
                    _compactPageButton(
                      icon: Icons.chevron_right,
                      onTap: currentPage < totalPages ? nextPage : null,
                    ),
                  ],
                ),
              ],
            );
          } else {
            // Desktop layout
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Show entries + info
                Row(
                  children: [
                    const Text("Show ", style: TextStyle(fontSize: 11)),
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<int>(
                        value: itemsPerPage,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, size: 16),
                        style: const TextStyle(fontSize: 11),
                        items: rowsPerPageOptions
                            .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                            .toList(),
                        onChanged: changeItemsPerPage,
                      ),
                    ),
                    const Text(" entries", style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 8),
                    Text(
                      "Showing ${filteredEnquiries.isEmpty ? 0 : (currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filteredEnquiries.length ? filteredEnquiries.length : currentPage * itemsPerPage} of ${filteredEnquiries.length}",
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                // Right: Pagination controls
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

  // Table header with white text on dark background
  Widget _tableHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: Colors.white, // white text for contrast
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _tableCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF4B5563),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "User Enquiries",
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
            _buildFilterSection(),
            const SizedBox(height: 16),
            Expanded(child: _buildCustomTable()),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerHorizontalController.dispose();
    _rowsHorizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }
}*/