import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart' as pdfLib;
import 'dart:html' as html;
import '../../api/api_service.dart';
import '../../models/qnx_admin/loan_enquiry_model.dart';

class LoanEnquiryScreen extends StatefulWidget {
  const LoanEnquiryScreen({super.key});

  @override
  State<LoanEnquiryScreen> createState() => _LoanEnquiryScreenState();
}

class _LoanEnquiryScreenState extends State<LoanEnquiryScreen> {
  final LoanEnquiryService _service = LoanEnquiryService();

  // Data
  List<LoanEnquiry> allEnquiries = [];
  List<LoanEnquiry> filteredEnquiries = [];
  List<LoanEnquiry> paginatedEnquiries = [];

  bool isLoading = true;

  // Filter Controllers
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String filterType = 'Name';

  // Status Filter
  String? selectedStatus;
  String? selectedLoanType;

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

  // Column Widths
  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(50),   // SR No
    1: FixedColumnWidth(140),  // Name
    2: FixedColumnWidth(120),  // Mobile
    3: FixedColumnWidth(120),  // Email
    4: FixedColumnWidth(120),  // Loan Type
    5: FixedColumnWidth(100),  // Loan Amount
    6: FixedColumnWidth(80),   // Tenure
    7: FixedColumnWidth(100),  // Monthly Income
    8: FixedColumnWidth(100),  // City
    9: FixedColumnWidth(100),  // State
    10: FixedColumnWidth(80),  // Pincode
    11: FixedColumnWidth(100), // Status
    12: FixedColumnWidth(100), // Created
    13: FixedColumnWidth(70),  // Actions
  };

  final List<String> headerLabels = [
    "SR No", "Name", "Mobile", "Email", "Loan Type", "Loan Amount",
    "Tenure", "Monthly Income", "City", "State", "Pincode", "Status",
    "Created", "Actions"
  ];

  // Colors
  static const Color _primaryColor = Color(0xFF5A67F2);
  static const Color _secondaryColor = Color(0xFFC64DB5);

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();
    loadEnquiries();
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

  Future<void> loadEnquiries() async {
    setState(() => isLoading = true);
    try {
      final response = await _service.getLoanEnquiries(
        page: currentPage,
        limit: itemsPerPage,
        search: searchQuery,
        status: selectedStatus,
        loanType: selectedLoanType,
      );
      if (mounted) {
        setState(() {
          allEnquiries = response.data;
          // Sort by createdAt descending (newest first)
          allEnquiries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          filteredEnquiries = List.from(allEnquiries);
          applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load loan enquiries: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void applyFilters() {
    // Apply search filter
    if (searchQuery.isEmpty) {
      filteredEnquiries = List.from(allEnquiries);
    } else {
      final query = searchQuery.toLowerCase();
      filteredEnquiries = allEnquiries.where((e) {
        switch (filterType) {
          case 'Name':
            return e.name.toLowerCase().contains(query);
          case 'Mobile':
            return e.mobile.contains(query);
          case 'Email':
            return e.email.toLowerCase().contains(query);
          case 'City':
            return e.city.toLowerCase().contains(query);
          case 'State':
            return e.state.toLowerCase().contains(query);
          default:
            return false;
        }
      }).toList();
    }

    // Apply status filter
    if (selectedStatus != null && selectedStatus!.isNotEmpty) {
      filteredEnquiries = filteredEnquiries
          .where((e) => e.status == selectedStatus)
          .toList();
    }

    // Apply loan type filter
    if (selectedLoanType != null && selectedLoanType!.isNotEmpty) {
      filteredEnquiries = filteredEnquiries
          .where((e) => e.loanType == selectedLoanType)
          .toList();
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
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    if (end > filteredEnquiries.length) end = filteredEnquiries.length;
    paginatedEnquiries = filteredEnquiries.sublist(start, end);
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
      selectedStatus = null;
      selectedLoanType = null;
      _searchController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  void showEnquiryDetails(LoanEnquiry enquiry) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
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
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFF8F9FA)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.3),
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
                            Color(0xFF7C4DDF),
                            Color(0xFFC64DB5),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.assignment_ind,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  enquiry.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
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
                                        enquiry.id.toString(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white70,
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
                                        color: enquiry.statusColor.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        enquiry.statusDisplay,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: enquiry.statusColor,
                                          fontWeight: FontWeight.bold,
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
                            _buildDetailSection(
                              title: "Personal Information",
                              icon: Icons.person,
                              children: [
                                _infoRow("Name", enquiry.name),
                                _infoRow("Mobile", enquiry.mobile),
                                _infoRow("Email", enquiry.email),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildDetailSection(
                              title: "Loan Details",
                              icon: Icons.credit_card,
                              children: [
                                _infoRow("Loan Type", enquiry.loanTypeDisplay),
                                _infoRow("Loan Amount", enquiry.formattedLoanAmount),
                                _infoRow("Tenure", "${enquiry.tenureYears} years"),
                                _infoRow("Monthly Income", enquiry.formattedMonthlyIncome),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildDetailSection(
                              title: "Location Details",
                              icon: Icons.location_on,
                              children: [
                                _infoRow("City", enquiry.city),
                                _infoRow("State", enquiry.state),
                                _infoRow("Pincode", enquiry.pincode),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (enquiry.remarks.isNotEmpty)
                              _buildDetailSection(
                                title: "Remarks",
                                icon: Icons.comment,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Text(
                                      enquiry.remarks,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Created At",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Text(
                                    enquiry.formattedCreatedAt,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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

  Widget _buildDetailSection({
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
                  colors: [
                    Color(0xFF5A67F2),
                    Color(0xFF7C4DDF),
                    Color(0xFFC64DB5),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7B4DDB).withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A67F2),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EAFD)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['Loan Enquiries'];
    sheet.appendRow([
      "SR No", "Name", "Mobile", "Email", "Loan Type", "Loan Amount",
      "Tenure", "Monthly Income", "City", "State", "Pincode", "Status", "Created At"
    ]);

    int srNo = filteredEnquiries.length;
    for (var e in filteredEnquiries) {
      sheet.appendRow([
        srNo--,
        e.name,
        e.mobile,
        e.email,
        e.loanTypeDisplay,
        e.formattedLoanAmount,
        e.tenureYears,
        e.formattedMonthlyIncome,
        e.city,
        e.state,
        e.pincode,
        e.statusDisplay,
        e.formattedCreatedAt,
      ]);
    }

    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "loan_enquiries.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> exportPDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: pdfLib.PdfPageFormat.a4.landscape,
          build: (pw.Context context) {
            return pw.Table.fromTextArray(
              headers: [
                "SR No", "Name", "Mobile", "Email", "Loan Type",
                "Loan Amount", "Tenure", "Monthly Income", "Status"
              ],
              data: List.generate(filteredEnquiries.length, (index) {
                final enquiry = filteredEnquiries[index];
                final srNo = filteredEnquiries.length - index;
                return [
                  srNo.toString(),
                  enquiry.name,
                  enquiry.mobile,
                  enquiry.email,
                  enquiry.loanTypeDisplay,
                  enquiry.formattedLoanAmount,
                  enquiry.tenureYears.toString(),
                  enquiry.formattedMonthlyIncome,
                  enquiry.statusDisplay,
                ];
              }),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: pw.TextStyle(fontSize: 9),
              cellAlignment: pw.Alignment.centerLeft,
              headerDecoration: const pw.BoxDecoration(
                color: pdfLib.PdfColors.grey300,
              ),
            );
          },
        ),
      );
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: 'loan_enquiries.pdf',
      );
    } catch (e) {
      print('PDF Export Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF Export Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildExportIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min, // Prevents overflow in Row
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
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.table_chart,
                  color: Colors.green,
                  size: 20,
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
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.red,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSection(bool isMobile) {
    // Status and Loan Type options
    final statusOptions = [
      {'value': '', 'label': 'All Status'},
      {'value': 'new', 'label': 'New'},
      {'value': 'in_progress', 'label': 'In Progress'},
      {'value': 'approved', 'label': 'Approved'},
      {'value': 'rejected', 'label': 'Rejected'},
      {'value': 'completed', 'label': 'Completed'},
    ];

    final loanTypeOptions = [
      {'value': '', 'label': 'All Types'},
      {'value': 'home_loan', 'label': 'Home Loan'},
      {'value': 'car_loan', 'label': 'Car Loan'},
      {'value': 'personal_loan', 'label': 'Personal Loan'},
      {'value': 'business_loan', 'label': 'Business Loan'},
      {'value': 'education_loan', 'label': 'Education Loan'},
    ];

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
      child: isMobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
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
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF6366F1),
                      ),
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 13,
                      ),
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        setState(() {
                          filterType = newValue!;
                          currentPage = 1;
                          applyFilters();
                        });
                      },
                      items: ['Name', 'Mobile', 'Email', 'City', 'State']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Icon(
                                value == 'Name'
                                    ? Icons.person
                                    : value == 'Mobile'
                                    ? Icons.phone
                                    : value == 'Email'
                                    ? Icons.email
                                    : value == 'City'
                                    ? Icons.location_city
                                    : Icons.map,
                                size: 14,
                                color: const Color(0xFF6366F1),
                              ),
                              const SizedBox(width: 8),
                              Text(value),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
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
                      hintText: "Search...",
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 16,
                        color: Color(0xFF6366F1),
                      ),
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
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedStatus ?? '',
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF6366F1),
                      ),
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 13,
                      ),
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedStatus = newValue!.isEmpty ? null : newValue;
                          currentPage = 1;
                          applyFilters();
                        });
                      },
                      items: statusOptions
                          .map<DropdownMenuItem<String>>((option) {
                        return DropdownMenuItem<String>(
                          value: option['value'],
                          child: Text(option['label']!),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedLoanType ?? '',
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF6366F1),
                      ),
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 13,
                      ),
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedLoanType = newValue!.isEmpty ? null : newValue;
                          currentPage = 1;
                          applyFilters();
                        });
                      },
                      items: loanTypeOptions
                          .map<DropdownMenuItem<String>>((option) {
                        return DropdownMenuItem<String>(
                          value: option['value'],
                          child: Text(option['label']!),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildExportIcons(),
              const SizedBox(width: 4),
              IconButton(
                onPressed: resetFilters,
                icon: const Icon(Icons.refresh),
                color: Colors.red,
                tooltip: "Reset",
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total: ${filteredEnquiries.length}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      )
          : Column(
        children: [
          // FIXED: Wrapped with SingleChildScrollView to prevent Right Overflow
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
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
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF6366F1),
                      ),
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 13,
                      ),
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        setState(() {
                          filterType = newValue!;
                          currentPage = 1;
                          applyFilters();
                        });
                      },
                      items: ['Name', 'Mobile', 'Email', 'City', 'State']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Icon(
                                value == 'Name'
                                    ? Icons.person
                                    : value == 'Mobile'
                                    ? Icons.phone
                                    : value == 'Email'
                                    ? Icons.email
                                    : value == 'City'
                                    ? Icons.location_city
                                    : Icons.map,
                                size: 14,
                                color: const Color(0xFF6366F1),
                              ),
                              const SizedBox(width: 8),
                              Text(value),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Using SizedBox width for Search bar to avoid infinite width inside scrollview
                SizedBox(
                  width: 250,
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search...",
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 16,
                          color: Color(0xFF6366F1),
                        ),
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
                      value: selectedStatus ?? '',
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF6366F1),
                      ),
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 13,
                      ),
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedStatus = newValue!.isEmpty ? null : newValue;
                          currentPage = 1;
                          applyFilters();
                        });
                      },
                      items: statusOptions
                          .map<DropdownMenuItem<String>>((option) {
                        return DropdownMenuItem<String>(
                          value: option['value'],
                          child: Text(option['label']!),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                      value: selectedLoanType ?? '',
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Color(0xFF6366F1),
                      ),
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 13,
                      ),
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        setState(() {
                          selectedLoanType = newValue!.isEmpty ? null : newValue;
                          currentPage = 1;
                          applyFilters();
                        });
                      },
                      items: loanTypeOptions
                          .map<DropdownMenuItem<String>>((option) {
                        return DropdownMenuItem<String>(
                          value: option['value'],
                          child: Text(option['label']!),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildExportIcons(),
                const SizedBox(width: 8),
                Text(
                  "Total: ${filteredEnquiries.length}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: resetFilters,
                  icon: const Icon(Icons.refresh),
                  color: Colors.red,
                  tooltip: "Reset",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    if (filteredEnquiries.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(minHeight: 40),
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
                            .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.toString()),
                        ))
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
                            .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.toString()),
                        ))
                            .toList(),
                        onChanged: changeItemsPerPage,
                      ),
                    ),
                    const Text(" entries", style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 8),
                    Text(
                      "Showing ${(currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filteredEnquiries.length ? filteredEnquiries.length : currentPage * itemsPerPage} of ${filteredEnquiries.length}",
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
                      ...List.generate(4, (index) =>
                          _compactPageNumber(totalPages - 3 + index)),
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

  Widget _compactPageButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
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
      ),
    );
  }

  Widget _tableCell(String text, {VoidCallback? onTap, bool isBold = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
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

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'new':
        color = Colors.orange;
        break;
      case 'in_progress':
        color = Colors.blue;
        break;
      case 'approved':
        color = Colors.green;
        break;
      case 'rejected':
        color = Colors.red;
        break;
      case 'completed':
        color = Colors.purple;
        break;
      default:
        color = Colors.grey;
    }

    String label;
    switch (status) {
      case 'new':
        label = 'New';
        break;
      case 'in_progress':
        label = 'In Progress';
        break;
      case 'approved':
        label = 'Approved';
        break;
      case 'rejected':
        label = 'Rejected';
        break;
      case 'completed':
        label = 'Completed';
        break;
      default:
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

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
          "Loan Enquiries",
          style: TextStyle(fontWeight: FontWeight.w600),
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
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SingleChildScrollView(
                      controller: _headerHorizontalController,
                      scrollDirection: Axis.horizontal,
                      child: Table(
                        border: TableBorder(
                          horizontalInside: BorderSide(
                              color: Colors.grey.shade300),
                          verticalInside:
                          BorderSide(color: Colors.grey.shade300),
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
                  Expanded(
                    child: filteredEnquiries.isEmpty
                        ? const Center(
                        child: Text("No loan enquiries found"))
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
                          children: List.generate(
                              paginatedEnquiries.length,
                                  (rowIndex) {
                                final e = paginatedEnquiries[rowIndex];
                                final isEven = rowIndex % 2 == 0;

                                final int srNo = filteredEnquiries
                                    .length -
                                    ((currentPage - 1) *
                                        itemsPerPage +
                                        rowIndex);

                                return TableRow(
                                  decoration: BoxDecoration(
                                    color: isEven
                                        ? Colors.white
                                        : const Color(0xFFF8FAFC),
                                  ),
                                  children: [
                                    _tableCell(srNo.toString()),
                                    _tableCell(
                                      e.name,
                                      onTap: () => showEnquiryDetails(e),
                                      isBold: true,
                                    ),
                                    _tableCell(e.mobile),
                                    _tableCell(e.email),
                                    _tableCell(e.loanTypeDisplay),
                                    _tableCell(e.formattedLoanAmount),
                                    _tableCell("${e.tenureYears} yrs"),
                                    _tableCell(e.formattedMonthlyIncome),
                                    _tableCell(e.city),
                                    _tableCell(e.state),
                                    _tableCell(e.pincode),
                                    Container(
                                      height: 42,
                                      padding: const EdgeInsets.all(2),
                                      child: Center(
                                        child: _buildStatusChip(e.status),
                                      ),
                                    ),
                                    _tableCell(e.formattedCreatedAt),
                                    Container(
                                      height: 42,
                                      padding: const EdgeInsets.all(2),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.visibility,
                                          color: Color(0xFF5A67F2),
                                          size: 18,
                                        ),
                                        onPressed: () =>
                                            showEnquiryDetails(e),
                                        tooltip: 'View Details',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                            minWidth: 28, minHeight: 28),
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
            ),
            const SizedBox(height: 8),
            _buildPagination(),
          ],
        ),
      ),
    );
  }
}