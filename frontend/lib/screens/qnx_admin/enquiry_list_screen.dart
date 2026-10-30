import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html;
import '../../models/qnx_admin/enquiry_list_model.dart';
import '../../api/api_service.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class EnquiryListScreen extends StatefulWidget {
  const EnquiryListScreen({super.key});

  @override
  State<EnquiryListScreen> createState() => _EnquiryListScreenState();
}

class _EnquiryListScreenState extends State<EnquiryListScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<EnquiryListModel> allEnquiries = [];
  List<EnquiryListModel> filteredEnquiries = [];
  List<EnquiryListModel> paginatedEnquiries = [];

  bool isLoading = true;
  int? _companyId;
  // Pagination
  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  // Filter variables
  String searchQuery = '';
  String filterType = 'Person Name';

  // Scroll controllers for linked horizontal scrolling
  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  // Premium gradient colors (matching dashboard)
  static const Color _premiumPrimary = Color(0xFF4158D0);
  static const Color _premiumSecondary = Color(0xFFC850C0);

  // Column widths (SR No added as first column, ID removed)
  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(60),   // SR No
    1: FixedColumnWidth(120),  // Company Name
    2: FixedColumnWidth(120),  // Shop Name
    3: FixedColumnWidth(120),  // Person Name
    4: FixedColumnWidth(100),  // User Type
    5: FixedColumnWidth(100),  // Demo Type
    6: FixedColumnWidth(150),  // Contact
    7: FixedColumnWidth(180),  // Email
    8: FixedColumnWidth(200),  // Address
    9: FixedColumnWidth(70),   // Pincode
    10: FixedColumnWidth(80),  // Demo Required
    11: FixedColumnWidth(100), // Date
    12: FixedColumnWidth(70),  // Action
  };

  final List<String> headerLabels = [
    "SR No", "Company Name", "Shop Name", "Person Name", "User Type", "Demo Type",
    "Contact", "Email", "Address", "Pincode", "Demo Req", "Date", "Action"
  ];

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();
    fetchEnquiryList();
    _loadCompanyId();
  }

  Future<void> _loadCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _companyId = prefs.getInt('companyId');
      if (_companyId == 0) _companyId = null;
    });
    fetchEnquiryList();
  }

  Future<void> fetchEnquiryList() async {
    try {
      final data = await EnquiryListService.fetchEnquiries();
      if (mounted) {
        setState(() {
          // Sort by id in descending order (most recent first) - with null safety
          allEnquiries = data..sort((a, b) {
            // Handle null values - treat null as 0 or put them at the end
            int idA = a.id ?? 0;
            int idB = b.id ?? 0;
            return idB.compareTo(idA); // Descending order
          });
          applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load enquiries")),
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
        if (filterType == 'Person Name') {
          return (enquiry.personName ?? '').toLowerCase().contains(query);
        } else if (filterType == 'Company') {
          return (enquiry.companyName ?? '').toLowerCase().contains(query);
        } else if (filterType == 'Shop Name') {
          return (enquiry.shopName ?? '').toLowerCase().contains(query);
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
      filterType = 'Person Name';
      _searchController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  String formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '-';
    try {
      DateTime dt = DateTime.parse(dateTimeStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (e) {
      return dateTimeStr;
    }
  }

  // ---------- Premium Details Popup ----------
  void _showDetailsPopup(EnquiryListModel enquiry) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
                  // Premium Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
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
                          child: const Icon(Icons.info_outline, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                enquiry.personName ?? 'Enquiry',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                enquiry.companyName ?? 'Company',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
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
                            onPressed: () => Navigator.pop(ctx),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
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
                          // Status Row - Demo Required
                          Row(
                            children: [
                              _premiumStatusChip(
                                enquiry.demoRequired ?? 'No',
                                enquiry.demoRequired == 'Yes' ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              _premiumStatusChip(
                                enquiry.userType ?? 'User',
                                _premiumPrimary,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Company Details Section
                          _buildPremiumSection(
                            title: "Company Details",
                            icon: Icons.business_outlined,
                            children: [
                              _infoRow("Company Name", enquiry.companyName ?? "-"),
                              _infoRow("Shop Name", enquiry.shopName ?? "-"),
                              _infoRow("Person Name", enquiry.personName ?? "-"),
                              _infoRow("User Type", enquiry.userType ?? "-"),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Contact Details Section
                          _buildPremiumSection(
                            title: "Contact Details",
                            icon: Icons.contact_phone_outlined,
                            children: [
                              _infoRow("Contacts", enquiry.contacts?.join(", ") ?? "-", isLong: true),
                              _infoRow("Emails", enquiry.emails?.join(", ") ?? "-", isLong: true),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Demo Information Section
                          _buildPremiumSection(
                            title: "Demo Information",
                            icon: Icons.mobile_screen_share_outlined,
                            children: [
                              _infoRow("Demo Type", enquiry.demoType ?? "-"),
                              _infoRow("Demo Required", enquiry.demoRequired ?? "-"),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Address Section
                          _buildPremiumSection(
                            title: "Address",
                            icon: Icons.location_on_outlined,
                            children: [
                              _infoRow("Address", enquiry.address ?? "-", isLong: true),
                              _infoRow("Pincode", enquiry.pincode ?? "-"),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Created At Section
                          _buildPremiumSection(
                            title: "Created At",
                            icon: Icons.calendar_today_outlined,
                            children: [
                              _infoRow("Date", formatDateTime(enquiry.createdAt)),
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
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
            width: 140,
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

  // ---------- Export functions (with SR No instead of ID) ----------
  void exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['Enquiries'];

    sheet.appendRow(["SR No", "Company Name", "Shop Name", "Person Name", "User Type", "Demo Type",
      "Contact", "Email", "Address", "Pincode", "Demo Req", "Date"]);

    int srNo = 1;
    for (var e in filteredEnquiries) {
      sheet.appendRow([
        srNo++,
        e.companyName ?? '-',
        e.shopName ?? '-',
        e.personName ?? '-',
        e.userType ?? '-',
        e.demoType ?? '-',
        e.contacts?.join(", ") ?? '-',
        e.emails?.join(", ") ?? '-',
        e.address ?? '-',
        e.pincode ?? '-',
        e.demoRequired ?? '-',
        formatDateTime(e.createdAt),
      ]);
    }

    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "enquiries.xlsx")
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
            headers: ["SR No", "Company Name", "Shop Name", "Person Name", "User Type", "Demo Type",
              "Contact", "Email", "Address", "Pincode", "Demo Req", "Date"],
            data: filteredEnquiries.asMap().entries.map((entry) {
              final e = entry.value;
              final srNo = entry.key + 1;
              return [
                srNo.toString(),
                e.companyName ?? '-',
                e.shopName ?? '-',
                e.personName ?? '-',
                e.userType ?? '-',
                e.demoType ?? '-',
                e.contacts?.join(", ") ?? '-',
                e.emails?.join(", ") ?? '-',
                e.address ?? '-',
                e.pincode ?? '-',
                e.demoRequired ?? '-',
                formatDateTime(e.createdAt),
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

    content.writeln("Enquiry List\n");
    content.writeln("=" * 50);

    int srNo = 1;
    for (var e in filteredEnquiries) {
      content.writeln("SR No: ${srNo++}");
      content.writeln("Company: ${e.companyName ?? '-'}");
      content.writeln("Shop: ${e.shopName ?? '-'}");
      content.writeln("Person: ${e.personName ?? '-'}");
      content.writeln("User Type: ${e.userType ?? '-'}");
      content.writeln("Demo Type: ${e.demoType ?? '-'}");
      content.writeln("Contacts: ${e.contacts?.join(", ") ?? '-'}");
      content.writeln("Emails: ${e.emails?.join(", ") ?? '-'}");
      content.writeln("Address: ${e.address ?? '-'}");
      content.writeln("Pincode: ${e.pincode ?? '-'}");
      content.writeln("Demo Required: ${e.demoRequired ?? '-'}");
      content.writeln("Date: ${formatDateTime(e.createdAt)}");
      content.writeln("-" * 30);
    }

    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "enquiries.doc")
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dropdown
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: Container(
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
                            value: 'Person Name',
                            child: Text('Person Name'),
                          ),
                          DropdownMenuItem(
                            value: 'Company',
                            child: Text('Company'),
                          ),
                          DropdownMenuItem(
                            value: 'Shop Name',
                            child: Text('Shop Name'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Search
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: filterType == 'Person Name'
                            ? "Search by person name..."
                            : filterType == 'Company'
                            ? "Search by company..."
                            : "Search by shop name...",
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

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: _buildExportIcons()),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Total: ${filteredEnquiries.length}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
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
            );
          }

          // Desktop Layout
          return Row(
            children: [
              Container(
                width: 160,
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
                        value: 'Person Name',
                        child: Text('Person Name'),
                      ),
                      DropdownMenuItem(
                        value: 'Company',
                        child: Text('Company'),
                      ),
                      DropdownMenuItem(
                        value: 'Shop Name',
                        child: Text('Shop Name'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),

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
                      hintText: filterType == 'Person Name'
                          ? "Search by person name..."
                          : filterType == 'Company'
                          ? "Search by company..."
                          : "Search by shop name...",
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 16,
                        color: Color(0xFF6366F1),
                      ),
                      border: InputBorder.none,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
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

              _buildExportIcons(),

              const SizedBox(width: 12),

              Text(
                "Total: ${filteredEnquiries.length}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),

              IconButton(
                onPressed: resetFilters,
                icon: const Icon(Icons.refresh),
                color: Colors.red,
              ),
            ],
          );
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
          // Scrollable rows (both horizontal and vertical)
          Expanded(
            child: filteredEnquiries.isEmpty
                ? const Center(child: Text("No enquiries found"))
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
                        // SR No
                        GestureDetector(
                          onTap: () => _showDetailsPopup(enquiry),
                          child: _tableCell(srNo.toString()),
                        ),
                        // Company Name
                        GestureDetector(
                          onTap: () => _showDetailsPopup(enquiry),
                          child: _tableCell(enquiry.companyName ?? "-"),
                        ),
                        // Shop Name
                        GestureDetector(
                          onTap: () => _showDetailsPopup(enquiry),
                          child: _tableCell(enquiry.shopName ?? "-"),
                        ),
                        // Person Name
                        GestureDetector(
                          onTap: () => _showDetailsPopup(enquiry),
                          child: _tableCell(enquiry.personName ?? "-"),
                        ),
                        // User Type
                        GestureDetector(
                          onTap: () => _showDetailsPopup(enquiry),
                          child: _tableCell(enquiry.userType ?? "-"),
                        ),
                        // Demo Type
                        GestureDetector(
                          onTap: () => _showDetailsPopup(enquiry),
                          child: _tableCell(enquiry.demoType ?? "-"),
                        ),
                        // Contact
                        GestureDetector(
                          onTap: () => _showDetailsPopup(enquiry),
                          child: _tableCell(enquiry.contacts?.join(", ") ?? "-"),
                        ),
                        // Email
                        GestureDetector(
                          onTap: () => _showDetailsPopup(enquiry),
                          child: _tableCell(enquiry.emails?.join(", ") ?? "-"),
                        ),
                        // Address
                        GestureDetector(
                          onTap: () => _showDetailsPopup(enquiry),
                          child: _tableCell(enquiry.address ?? "-"),
                        ),
                        // Pincode
                        GestureDetector(
                          onTap: () => _showDetailsPopup(enquiry),
                          child: _tableCell(enquiry.pincode ?? "-"),
                        ),
                        // Demo Required
                        GestureDetector(
                          onTap: () => _showDetailsPopup(enquiry),
                          child: Container(
                            height: 42,
                            padding: const EdgeInsets.all(2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: enquiry.demoRequired == 'Yes'
                                    ? Colors.green.withOpacity(0.2)
                                    : Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  enquiry.demoRequired ?? "-",
                                  style: TextStyle(
                                    color: enquiry.demoRequired == 'Yes'
                                        ? Colors.green[800]
                                        : Colors.grey[800],
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Date
                        GestureDetector(
                          onTap: () => _showDetailsPopup(enquiry),
                          child: _tableCell(formatDateTime(enquiry.createdAt)),
                        ),
                        // Action - View Icon
                        Container(
                          height: 42,
                          padding: const EdgeInsets.all(2),
                          child: IconButton(
                            icon: const Icon(Icons.visibility, color: Color(0xFF4158D0), size: 18),
                            onPressed: () => _showDetailsPopup(enquiry),
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
          const SizedBox(height: 16),
          // Pagination
          if (filteredEnquiries.isNotEmpty) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 40,
      ),
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
                // Left: Show entries
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
          "Enquiry List",
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
import '../models/enquiry_list_model.dart';
import '../api/api_service.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class EnquiryListScreen extends StatefulWidget {
  const EnquiryListScreen({super.key});

  @override
  State<EnquiryListScreen> createState() => _EnquiryListScreenState();
}

class _EnquiryListScreenState extends State<EnquiryListScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<EnquiryListModel> allEnquiries = [];
  List<EnquiryListModel> filteredEnquiries = [];
  List<EnquiryListModel> paginatedEnquiries = [];

  bool isLoading = true;

  // Pagination
  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  // Filter variables
  String searchQuery = '';
  String filterType = 'Person Name';

  // Scroll controllers for linked horizontal scrolling
  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  // Column widths (ID added as first column)
  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(60),   // ID
    1: FixedColumnWidth(120),  // Company Name
    2: FixedColumnWidth(120),  // Shop Name
    3: FixedColumnWidth(120),  // Person Name
    4: FixedColumnWidth(100),  // User Type
    5: FixedColumnWidth(100),  // Demo Type
    6: FixedColumnWidth(150),  // Contact
    7: FixedColumnWidth(180),  // Email
    8: FixedColumnWidth(200),  // Address
    9: FixedColumnWidth(70),   // Pincode
    10: FixedColumnWidth(80),  // Demo Required
    11: FixedColumnWidth(100), // Date
  };

  final List<String> headerLabels = [
    "ID", "Company Name", "Shop Name", "Person Name", "User Type", "Demo Type",
    "Contact", "Email", "Address", "Pincode", "Demo Req", "Date"
  ];

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();
    fetchEnquiryList();
  }

  Future<void> fetchEnquiryList() async {
    try {
      final data = await EnquiryListService.fetchEnquiries();
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
          const SnackBar(content: Text("Failed to load enquiries")),
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
        if (filterType == 'Person Name') {
          return (enquiry.personName ?? '').toLowerCase().contains(query);
        } else if (filterType == 'Company') {
          return (enquiry.companyName ?? '').toLowerCase().contains(query);
        } else if (filterType == 'Shop Name') {
          return (enquiry.shopName ?? '').toLowerCase().contains(query);
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
      filterType = 'Person Name';
      _searchController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  String formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '-';
    try {
      DateTime dt = DateTime.parse(dateTimeStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (e) {
      return dateTimeStr;
    }
  }

  // ---------- Export functions (with ID included) ----------
  void exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['Enquiries'];

    sheet.appendRow(headerLabels);

    for (var e in filteredEnquiries) {
      sheet.appendRow([
        e.id.toString(),
        e.companyName ?? '-',
        e.shopName ?? '-',
        e.personName ?? '-',
        e.userType ?? '-',
        e.demoType ?? '-',
        e.contacts?.join(", ") ?? '-',
        e.emails?.join(", ") ?? '-',
        e.address ?? '-',
        e.pincode ?? '-',
        e.demoRequired ?? '-',
        formatDateTime(e.createdAt),
      ]);
    }

    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "enquiries.xlsx")
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
              e.companyName ?? '-',
              e.shopName ?? '-',
              e.personName ?? '-',
              e.userType ?? '-',
              e.demoType ?? '-',
              e.contacts?.join(", ") ?? '-',
              e.emails?.join(", ") ?? '-',
              e.address ?? '-',
              e.pincode ?? '-',
              e.demoRequired ?? '-',
              formatDateTime(e.createdAt),
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

    content.writeln("Enquiry List\n");
    content.writeln("=" * 50);

    for (var e in filteredEnquiries) {
      content.writeln("ID: ${e.id}");
      content.writeln("Company: ${e.companyName ?? '-'}");
      content.writeln("Shop: ${e.shopName ?? '-'}");
      content.writeln("Person: ${e.personName ?? '-'}");
      content.writeln("User Type: ${e.userType ?? '-'}");
      content.writeln("Demo Type: ${e.demoType ?? '-'}");
      content.writeln("Contacts: ${e.contacts?.join(", ") ?? '-'}");
      content.writeln("Emails: ${e.emails?.join(", ") ?? '-'}");
      content.writeln("Address: ${e.address ?? '-'}");
      content.writeln("Pincode: ${e.pincode ?? '-'}");
      content.writeln("Demo Required: ${e.demoRequired ?? '-'}");
      content.writeln("Date: ${formatDateTime(e.createdAt)}");
      content.writeln("-" * 30);
    }

    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "enquiries.doc")
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
          // First row: filter type dropdown + search + export icons + reset + total count
          Row(
            children: [
              // Filter type dropdown
              Container(
                width: 160,
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
                      DropdownMenuItem(value: 'Person Name', child: Text('Person Name')),
                      DropdownMenuItem(value: 'Company', child: Text('Company')),
                      DropdownMenuItem(value: 'Shop Name', child: Text('Shop Name')),
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
                      hintText: filterType == 'Person Name'
                          ? "Search by person name..."
                          : filterType == 'Company'
                          ? "Search by company..."
                          : "Search by shop name...",
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

              // Reset + Total count
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
          // Fixed header (horizontally scrollable) - with dark background
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
          // Scrollable rows (both horizontal and vertical) - with zebra striping
          Expanded(
            child: filteredEnquiries.isEmpty
                ? const Center(child: Text("No enquiries found"))
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
                    // Zebra striping: even rows white, odd rows light gray
                    final isEven = rowIndex % 2 == 0;
                    return TableRow(
                      decoration: BoxDecoration(
                        color: isEven ? Colors.white : const Color(0xFFF5F5F5),
                      ),
                      children: [
                        _tableCell(enquiry.id.toString()),
                        _tableCell(enquiry.companyName ?? "-"),
                        _tableCell(enquiry.shopName ?? "-"),
                        _tableCell(enquiry.personName ?? "-"),
                        _tableCell(enquiry.userType ?? "-"),
                        _tableCell(enquiry.demoType ?? "-"),
                        _tableCell(enquiry.contacts?.join(", ") ?? "-"),
                        _tableCell(enquiry.emails?.join(", ") ?? "-"),
                        _tableCell(enquiry.address ?? "-"),
                        _tableCell(enquiry.pincode ?? "-"),
                        _tableCell(enquiry.demoRequired ?? "-"),
                        _tableCell(formatDateTime(enquiry.createdAt)),
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
                // Left: Show entries
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

  // Updated table header style: white text on dark background
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
          "Enquiry List",
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





/*import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;
import '../../models/enquiry_list_model.dart';
import '../../api/api_service.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class EnquiryListScreen extends StatefulWidget {
  const EnquiryListScreen({super.key});

  @override
  State<EnquiryListScreen> createState() => _EnquiryListScreenState();
}

class _EnquiryListScreenState extends State<EnquiryListScreen> {
  // Controllers for three filters
  final TextEditingController _personNameController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();

  List<EnquiryListModel> allEnquiries = [];
  List<EnquiryListModel> filteredEnquiries = [];
  List<EnquiryListModel> paginatedEnquiries = [];

  bool isLoading = true;

  // Pagination
  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  // Filter values
  String personNameFilter = '';
  String companyFilter = '';
  String shopNameFilter = '';

  // Scroll controllers
  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  // Column widths
  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(60),   // ID
    1: FixedColumnWidth(120),  // Company Name
    2: FixedColumnWidth(120),  // Shop Name
    3: FixedColumnWidth(120),  // Person Name
    4: FixedColumnWidth(100),  // User Type
    5: FixedColumnWidth(100),  // Demo Type
    6: FixedColumnWidth(150),  // Contact
    7: FixedColumnWidth(180),  // Email
    8: FixedColumnWidth(200),  // Address
    9: FixedColumnWidth(70),   // Pincode
    10: FixedColumnWidth(80),  // Demo Required
    11: FixedColumnWidth(100), // Date
  };

  final List<String> headerLabels = [
    "ID", "Company Name", "Shop Name", "Person Name", "User Type", "Demo Type",
    "Contact", "Email", "Address", "Pincode", "Demo Req", "Date"
  ];

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();
    fetchEnquiryList();
  }

  Future<void> fetchEnquiryList() async {
    try {
      final data = await EnquiryListService.fetchEnquiries();
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
          const SnackBar(content: Text("Failed to load enquiries")),
        );
      }
    }
  }

  void applyFilters() {
    filteredEnquiries = allEnquiries.where((enquiry) {
      bool matchesPerson = personNameFilter.isEmpty ||
          (enquiry.personName ?? '').toLowerCase().contains(personNameFilter.toLowerCase());
      bool matchesCompany = companyFilter.isEmpty ||
          (enquiry.companyName ?? '').toLowerCase().contains(companyFilter.toLowerCase());
      bool matchesShop = shopNameFilter.isEmpty ||
          (enquiry.shopName ?? '').toLowerCase().contains(shopNameFilter.toLowerCase());
      return matchesPerson && matchesCompany && matchesShop;
    }).toList();

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
      personNameFilter = '';
      companyFilter = '';
      shopNameFilter = '';
      _personNameController.clear();
      _companyController.clear();
      _shopNameController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  String formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '-';
    try {
      DateTime dt = DateTime.parse(dateTimeStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (e) {
      return dateTimeStr;
    }
  }

  // ---------- Export functions (unchanged) ----------
  void exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['Enquiries'];
    sheet.appendRow(headerLabels);
    for (var e in filteredEnquiries) {
      sheet.appendRow([
        e.id.toString(),
        e.companyName ?? '-',
        e.shopName ?? '-',
        e.personName ?? '-',
        e.userType ?? '-',
        e.demoType ?? '-',
        e.contacts?.join(", ") ?? '-',
        e.emails?.join(", ") ?? '-',
        e.address ?? '-',
        e.pincode ?? '-',
        e.demoRequired ?? '-',
        formatDateTime(e.createdAt),
      ]);
    }
    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "enquiries.xlsx")
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
              e.companyName ?? '-',
              e.shopName ?? '-',
              e.personName ?? '-',
              e.userType ?? '-',
              e.demoType ?? '-',
              e.contacts?.join(", ") ?? '-',
              e.emails?.join(", ") ?? '-',
              e.address ?? '-',
              e.pincode ?? '-',
              e.demoRequired ?? '-',
              formatDateTime(e.createdAt),
            ]).toList(),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void exportDOC() {
    final content = StringBuffer();
    content.writeln("Enquiry List\n");
    content.writeln("=" * 50);
    for (var e in filteredEnquiries) {
      content.writeln("ID: ${e.id}");
      content.writeln("Company: ${e.companyName ?? '-'}");
      content.writeln("Shop: ${e.shopName ?? '-'}");
      content.writeln("Person: ${e.personName ?? '-'}");
      content.writeln("User Type: ${e.userType ?? '-'}");
      content.writeln("Demo Type: ${e.demoType ?? '-'}");
      content.writeln("Contacts: ${e.contacts?.join(", ") ?? '-'}");
      content.writeln("Emails: ${e.emails?.join(", ") ?? '-'}");
      content.writeln("Address: ${e.address ?? '-'}");
      content.writeln("Pincode: ${e.pincode ?? '-'}");
      content.writeln("Demo Required: ${e.demoRequired ?? '-'}");
      content.writeln("Date: ${formatDateTime(e.createdAt)}");
      content.writeln("-" * 30);
    }
    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "enquiries.doc")
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
          // Three filter rows (responsive wrap)
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // Person Name filter
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _personNameController,
                  decoration: InputDecoration(
                    hintText: "Person Name...",
                    prefixIcon: const Icon(Icons.person, size: 16, color: Color(0xFF6366F1)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    suffixIcon: personNameFilter.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _personNameController.clear();
                        setState(() {
                          personNameFilter = '';
                          currentPage = 1;
                          applyFilters();
                        });
                      },
                    )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      personNameFilter = value;
                      currentPage = 1;
                      applyFilters();
                    });
                  },
                ),
              ),
              // Company filter
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _companyController,
                  decoration: InputDecoration(
                    hintText: "Company...",
                    prefixIcon: const Icon(Icons.business, size: 16, color: Color(0xFF6366F1)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    suffixIcon: companyFilter.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _companyController.clear();
                        setState(() {
                          companyFilter = '';
                          currentPage = 1;
                          applyFilters();
                        });
                      },
                    )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      companyFilter = value;
                      currentPage = 1;
                      applyFilters();
                    });
                  },
                ),
              ),
              // Shop Name filter
              SizedBox(
                width: 200,
                child: TextField(
                  controller: _shopNameController,
                  decoration: InputDecoration(
                    hintText: "Shop Name...",
                    prefixIcon: const Icon(Icons.store, size: 16, color: Color(0xFF6366F1)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    suffixIcon: shopNameFilter.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _shopNameController.clear();
                        setState(() {
                          shopNameFilter = '';
                          currentPage = 1;
                          applyFilters();
                        });
                      },
                    )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      shopNameFilter = value;
                      currentPage = 1;
                      applyFilters();
                    });
                  },
                ),
              ),
              // Export icons and reset button
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildExportIcons(),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: resetFilters,
                    icon: const Icon(Icons.refresh),
                    color: Colors.red,
                    tooltip: "Reset all filters",
                  ),
                ],
              ),
              // Total count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Text(
                    "Total: ${filteredEnquiries.length}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
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

  // _buildCustomTable, _buildPagination, _compactPageButton, _compactPageNumber,
  // _tableHeader, _tableCell remain exactly the same as original.
  // (I'll include them for completeness, but they are unchanged.)

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
          Expanded(
            child: filteredEnquiries.isEmpty
                ? const Center(child: Text("No enquiries found"))
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
                        color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                      ),
                      children: [
                        _tableCell(enquiry.id.toString()),
                        _tableCell(enquiry.companyName ?? "-"),
                        _tableCell(enquiry.shopName ?? "-"),
                        _tableCell(enquiry.personName ?? "-"),
                        _tableCell(enquiry.userType ?? "-"),
                        _tableCell(enquiry.demoType ?? "-"),
                        _tableCell(enquiry.contacts?.join(", ") ?? "-"),
                        _tableCell(enquiry.emails?.join(", ") ?? "-"),
                        _tableCell(enquiry.address ?? "-"),
                        _tableCell(enquiry.pincode ?? "-"),
                        _tableCell(enquiry.demoRequired ?? "-"),
                        _tableCell(formatDateTime(enquiry.createdAt)),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
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
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
          "Enquiry List",
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
    _personNameController.dispose();
    _companyController.dispose();
    _shopNameController.dispose();
    _headerHorizontalController.dispose();
    _rowsHorizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }
}*/