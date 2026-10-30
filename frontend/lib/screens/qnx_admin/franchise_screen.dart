// lib/screens/qnx_admin/franchise_list_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import '../../api/api_service.dart';
import '../../models/qnx_admin/franchise_model.dart';

class FranchiseListScreen extends StatefulWidget {
  const FranchiseListScreen({Key? key}) : super(key: key);

  @override
  State<FranchiseListScreen> createState() => _FranchiseListScreenState();
}

class _FranchiseListScreenState extends State<FranchiseListScreen> {
  final FranchiseService _franchiseService = FranchiseService();
  List<Franchise> _franchises = [];
  List<Franchise> _filteredFranchises = [];
  List<Franchise> _paginatedFranchises = [];

  bool _isLoading = true;
  String _errorMessage = '';
  String _searchQuery = '';
  String _filterType = 'Franchise Name';

  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalPages = 1;
  final List<int> _rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  // Controllers for linked scroll
  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  // Premium gradient colors (matching dashboard)
  static const Color _premiumPrimary = Color(0xFF4158D0);
  static const Color _premiumSecondary = Color(0xFFC850C0);

  // Column widths for table
  final Map<int, TableColumnWidth> _columnWidths = const {
    0: FixedColumnWidth(50),   // SR No
    1: FixedColumnWidth(150),  // Franchise Name (विस्तारित)
    2: FixedColumnWidth(120),  // Company Name
    3: FixedColumnWidth(120),  // Owner Name
    4: FixedColumnWidth(140),  // Email
    5: FixedColumnWidth(110),  // Mobile
    6: FixedColumnWidth(100),  // City
    7: FixedColumnWidth(100),  // State
    8: FixedColumnWidth(80),   // Pincode
    9: FixedColumnWidth(100),  // Commission
    10: FixedColumnWidth(100), // Joining Date
    11: FixedColumnWidth(80),  // Status
    12: FixedColumnWidth(130), // Franchise Code
    13: FixedColumnWidth(130), // Referral Code
  };

  // ✅ Updated Header Labels - "Code" ऐवजी "Franchise Code" आणि "Referral Code"
  final List<String> _headerLabels = const [
    "SR No",
    "Franchise Name",
    "Company",
    "Owner",
    "Email",
    "Mobile",
    "City",
    "State",
    "Pincode",
    "Commission",
    "Joining Date",
    "Status",
    "Franchise Code",
    "Referral Code"
  ];

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();
    _fetchFranchises();
  }

  @override
  void dispose() {
    _franchiseService.dispose();
    _headerHorizontalController.dispose();
    _rowsHorizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  Future<void> _fetchFranchises() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _franchiseService.getFranchises();
      setState(() {
        // Sort by id in descending order (most recent first)
        _franchises = response.data..sort((a, b) => b.id.compareTo(a.id));
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredFranchises = List.from(_franchises);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredFranchises = _franchises.where((f) {
        if (_filterType == 'Franchise Name') {
          return f.franchiseName.toLowerCase().contains(query);
        } else if (_filterType == 'Company Name') {
          return f.companyName.toLowerCase().contains(query);
        } else if (_filterType == 'Owner Name') {
          return f.ownerName.toLowerCase().contains(query);
        } else if (_filterType == 'Email') {
          return f.email.toLowerCase().contains(query);
        } else if (_filterType == 'City') {
          return f.city.toLowerCase().contains(query);
        } else if (_filterType == 'Franchise Code') {
          return f.franchiseCode.toLowerCase().contains(query);
        }
        return false;
      }).toList();
    }
    _applyPagination();
  }

  void _applyPagination() {
    if (_filteredFranchises.isEmpty) {
      _paginatedFranchises = [];
      _totalPages = 1;
      _currentPage = 1;
      setState(() {});
      return;
    }
    _totalPages = (_filteredFranchises.length / _itemsPerPage).ceil();
    if (_currentPage > _totalPages) _currentPage = _totalPages;
    if (_currentPage < 1) _currentPage = 1;
    int start = (_currentPage - 1) * _itemsPerPage;
    int end = start + _itemsPerPage;
    if (end > _filteredFranchises.length) end = _filteredFranchises.length;
    _paginatedFranchises = _filteredFranchises.sublist(start, end);
    setState(() {});
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
        _applyPagination();
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _applyPagination();
      });
    }
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
        _applyPagination();
      });
    }
  }

  void _changeItemsPerPage(int? value) {
    if (value != null) {
      setState(() {
        _itemsPerPage = value;
        _currentPage = 1;
        _applyPagination();
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _filterType = 'Franchise Name';
      _currentPage = 1;
      _applyFilters();
    });
  }

  String _formatDate(String date) {
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  // ==============================
  // DETAIL POPUP
  // ==============================
  void _showDetailsPopup(Franchise franchise) {
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
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF8F9FA)],
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
                          child: const Icon(Icons.storefront, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                franchise.franchiseName,
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
                                "Franchise Details",
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
                          // Status Row
                          Row(
                            children: [
                              _buildStatusChipPopup(franchise.isActive),
                              const SizedBox(width: 12),
                              _buildPremiumStatusChip(
                                "Code: ${franchise.franchiseCode}",
                                Colors.blue,
                                icon: Icons.code,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Basic Details Section
                          _buildPremiumSection(
                            title: "Basic Details",
                            icon: Icons.info_outline,
                            children: [
                              _infoRow("Franchise Name", franchise.franchiseName),
                              _infoRow("Franchise Code", franchise.franchiseCode),
                              _infoRow("Referral Code", franchise.franchiseReferralCode ?? 'N/A'),
                              _infoRow("Company", franchise.companyName),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Owner Details Section
                          _buildPremiumSection(
                            title: "Owner Details",
                            icon: Icons.person_outline,
                            children: [
                              _infoRow("Owner Name", franchise.ownerName),
                              _infoRow("Email", franchise.email),
                              _infoRow("Mobile", franchise.mobileNo),
                              if (franchise.alternateMobileNo != null && franchise.alternateMobileNo!.isNotEmpty)
                                _infoRow("Alternate Mobile", franchise.alternateMobileNo!),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Address Section
                          _buildPremiumSection(
                            title: "Address Details",
                            icon: Icons.location_on_outlined,
                            children: [
                              _infoRow("Address", franchise.address, isLong: true),
                              _infoRow("City", franchise.city),
                              _infoRow("State", franchise.state),
                              _infoRow("Pincode", franchise.pincode),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Tax Details Section
                          if (franchise.gstNo != null || franchise.panNo != null)
                            _buildPremiumSection(
                              title: "Tax Details",
                              icon: Icons.receipt_outlined,
                              children: [
                                if (franchise.gstNo != null && franchise.gstNo!.isNotEmpty)
                                  _infoRow("GST No", franchise.gstNo!),
                                if (franchise.panNo != null && franchise.panNo!.isNotEmpty)
                                  _infoRow("PAN No", franchise.panNo!),
                              ],
                            ),

                          if (franchise.gstNo != null || franchise.panNo != null)
                            const SizedBox(height: 20),

                          // Financial Details Section
                          _buildPremiumSection(
                            title: "Financial Details",
                            icon: Icons.attach_money_outlined,
                            children: [
                              _infoRow("Commission", "${franchise.commissionPercentage}%"),
                              _infoRow("Joining Date", _formatDate(franchise.joiningDate)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // System Details Section
                          _buildPremiumSection(
                            title: "System Details",
                            icon: Icons.settings_outlined,
                            children: [
                              _infoRow("Status", franchise.isActive ? "Active" : "Inactive"),
                              _infoRow("Company", franchise.companyName),
                              _infoRow("Created At", _formatDateTime(franchise.createdAt)),
                              _infoRow("Updated At", _formatDateTime(franchise.updatedAt)),
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

  String _formatDateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  Widget _buildPremiumStatusChip(String label, Color color, {IconData? icon}) {
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
            width: 120,
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

  Widget _buildStatusChipPopup(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: 14,
            color: isActive ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================
  // EXPORT FUNCTIONS
  // ==============================
  void _exportExcel() {
    final excelFile = excel.Excel.createExcel();
    final sheet = excelFile['Franchises'];
    sheet.appendRow(_headerLabels);
    int srNo = 1;
    for (var f in _filteredFranchises) {
      sheet.appendRow([
        srNo++,
        f.franchiseName,
        f.companyName,
        f.ownerName,
        f.email,
        f.mobileNo,
        f.city,
        f.state,
        f.pincode,
        f.commissionPercentage,
        _formatDate(f.joiningDate),
        f.isActive ? 'Active' : 'Inactive',
        f.franchiseCode,
        f.franchiseReferralCode ?? 'N/A',
      ]);
    }
    final bytes = excelFile.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "franchises.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> _exportPDF() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      build: (_) => pw.Table.fromTextArray(
        headers: _headerLabels,
        data: _filteredFranchises.asMap().entries.map((entry) {
          final f = entry.value;
          final srNo = entry.key + 1;
          return [
            srNo,
            f.franchiseName,
            f.companyName,
            f.ownerName,
            f.email,
            f.mobileNo,
            f.city,
            f.state,
            f.pincode,
            f.commissionPercentage,
            _formatDate(f.joiningDate),
            f.isActive ? 'Active' : 'Inactive',
            f.franchiseCode,
            f.franchiseReferralCode ?? 'N/A',
          ];
        }).toList(),
      ),
    ));
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  void _exportDOC() {
    final content = StringBuffer();
    content.writeln("Franchises List\n");
    content.writeln("=" * 60);
    int srNo = 1;
    for (var f in _filteredFranchises) {
      content.writeln("SR No: ${srNo++}");
      content.writeln("Franchise Name: ${f.franchiseName}");
      content.writeln("Franchise Code: ${f.franchiseCode}");
      content.writeln("Referral Code: ${f.franchiseReferralCode ?? 'N/A'}");
      content.writeln("Company: ${f.companyName}");
      content.writeln("Owner: ${f.ownerName}");
      content.writeln("Email: ${f.email}");
      content.writeln("Mobile: ${f.mobileNo}");
      if (f.alternateMobileNo != null && f.alternateMobileNo!.isNotEmpty) {
        content.writeln("Alternate Mobile: ${f.alternateMobileNo}");
      }
      content.writeln("Address: ${f.address}");
      content.writeln("City: ${f.city}");
      content.writeln("State: ${f.state}");
      content.writeln("Pincode: ${f.pincode}");
      if (f.gstNo != null && f.gstNo!.isNotEmpty) {
        content.writeln("GST No: ${f.gstNo}");
      }
      if (f.panNo != null && f.panNo!.isNotEmpty) {
        content.writeln("PAN No: ${f.panNo}");
      }
      content.writeln("Commission: ${f.commissionPercentage}%");
      content.writeln("Joining Date: ${_formatDate(f.joiningDate)}");
      content.writeln("Status: ${f.isActive ? 'Active' : 'Inactive'}");
      content.writeln("Created At: ${_formatDateTime(f.createdAt)}");
      content.writeln("-" * 40);
    }
    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "franchises.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ==============================
  // UI BUILDERS
  // ==============================
  Widget _buildFilterRow(bool isMobile) {
    const double dropdownWidth = 160;

    // ✅ Common dropdown items builder
    List<DropdownMenuItem<String>> getDropdownItems() {
      return [
        'Franchise Name',
        'Company Name',
        'Owner Name',
        'Email',
        'City',
        'Franchise Code'
      ].map<DropdownMenuItem<String>>((v) {
        return DropdownMenuItem(
          value: v,
          child: Row(
            children: [
              Icon(
                v == 'Franchise Name'
                    ? Icons.storefront
                    : v == 'Company Name'
                    ? Icons.business
                    : v == 'Owner Name'
                    ? Icons.person
                    : v == 'Email'
                    ? Icons.email
                    : v == 'City'
                    ? Icons.location_city
                    : Icons.code,
                size: 14,
                color: const Color(0xFF6366F1),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  v,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList();
    }

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
          )
        ],
      ),
      child: isMobile
          ? Column(children: [
        Row(children: [
          Container(
            width: dropdownWidth,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterType,
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
                isExpanded: true,
                onChanged: (value) {
                  setState(() {
                    _filterType = value!;
                    _currentPage = 1;
                    _applyFilters();
                  });
                },
                items: getDropdownItems(),
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
                decoration: InputDecoration(
                  hintText: "Search by $_filterType...",
                  prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF6366F1)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _currentPage = 1;
                        _applyFilters();
                      });
                    },
                  )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _currentPage = 1;
                    _applyFilters();
                  });
                },
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildExportIcons(),
            Row(
              children: [
                Text(
                  "Total: ${_filteredFranchises.length}",
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.refresh),
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ])
          : Row(children: [
        Container(
          width: dropdownWidth,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _filterType,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
              isExpanded: true,
              onChanged: (value) {
                setState(() {
                  _filterType = value!;
                  _currentPage = 1;
                  _applyFilters();
                });
              },
              items: getDropdownItems(),
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
              decoration: InputDecoration(
                hintText: "Search by $_filterType...",
                prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF6366F1)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _currentPage = 1;
                      _applyFilters();
                    });
                  },
                )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _currentPage = 1;
                  _applyFilters();
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildExportIcons(),
        const SizedBox(width: 12),
        Row(
          children: [
            Text(
              "Total: ${_filteredFranchises.length}",
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh),
              color: Colors.red,
            ),
          ],
        ),
      ]),
    );
  }

  Widget _buildExportIcons() {
    return Row(
      children: [
        Tooltip(
          message: "Excel",
          child: InkWell(
            onTap: _exportExcel,
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
          message: "PDF",
          child: InkWell(
            onTap: _exportPDF,
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
          message: "DOC",
          child: InkWell(
            onTap: _exportDOC,
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

  // ==============================
  // PAGINATION - Matching Pending Products Style
  // ==============================
  Widget _buildPagination() {
    if (_filteredFranchises.isEmpty) return const SizedBox.shrink();

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
                        value: _itemsPerPage,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, size: 16),
                        style: const TextStyle(fontSize: 11),
                        items: _rowsPerPageOptions
                            .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _itemsPerPage = v!;
                            _currentPage = 1;
                            _applyPagination();
                          });
                        },
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
                      onTap: _currentPage > 1 ? _previousPage : null,
                    ),
                    ...List.generate(
                      _totalPages > 3 ? 3 : _totalPages,
                          (index) {
                        int pageNum;
                        if (_totalPages <= 3) {
                          pageNum = index + 1;
                        } else if (_currentPage == 1) {
                          pageNum = index + 1;
                        } else if (_currentPage == _totalPages) {
                          pageNum = _totalPages - 2 + index;
                        } else {
                          pageNum = _currentPage - 1 + index;
                        }
                        return _compactPageNumber(pageNum);
                      },
                    ),
                    _compactPageButton(
                      icon: Icons.chevron_right,
                      onTap: _currentPage < _totalPages ? _nextPage : null,
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
                        value: _itemsPerPage,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, size: 16),
                        style: const TextStyle(fontSize: 11),
                        items: _rowsPerPageOptions
                            .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            _itemsPerPage = v!;
                            _currentPage = 1;
                            _applyPagination();
                          });
                        },
                      ),
                    ),
                    const Text(" entries", style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 8),
                    Text(
                      "Showing ${(_currentPage - 1) * _itemsPerPage + 1} to ${_currentPage * _itemsPerPage > _filteredFranchises.length ? _filteredFranchises.length : _currentPage * _itemsPerPage} of ${_filteredFranchises.length}",
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _compactPageButton(
                      icon: Icons.chevron_left,
                      onTap: _currentPage > 1 ? _previousPage : null,
                    ),
                    if (_totalPages <= 5)
                      ...List.generate(_totalPages, (index) => _compactPageNumber(index + 1))
                    else if (_currentPage <= 3) ...[
                      ...List.generate(4, (index) => _compactPageNumber(index + 1)),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                      _compactPageNumber(_totalPages),
                    ] else if (_currentPage >= _totalPages - 2) ...[
                      _compactPageNumber(1),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                      ...List.generate(4, (index) => _compactPageNumber(_totalPages - 3 + index)),
                    ] else ...[
                      _compactPageNumber(1),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                      _compactPageNumber(_currentPage - 1),
                      _compactPageNumber(_currentPage),
                      _compactPageNumber(_currentPage + 1),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 2),
                        child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                      _compactPageNumber(_totalPages),
                    ],
                    _compactPageButton(
                      icon: Icons.chevron_right,
                      onTap: _currentPage < _totalPages ? _nextPage : null,
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
    final isSelected = _currentPage == pageNum;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: () => _goToPage(pageNum),
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

  Widget _cell(String text) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Franchise Management',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchFranchises,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterRow(isMobile),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage.isNotEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading franchises',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchFranchises,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
                : _filteredFranchises.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.storefront_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No franchises found'
                        : 'No results found for "$_searchQuery"',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _searchQuery.isEmpty
                        ? 'Tap the + button to add one'
                        : 'Try a different search term',
                    style: TextStyle(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
                : Column(
              children: [
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
                      ),
                      columnWidths: _columnWidths,
                      children: [
                        TableRow(
                          children: _headerLabels
                              .map((label) => Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    child: SingleChildScrollView(
                      controller: _rowsHorizontalController,
                      scrollDirection: Axis.horizontal,
                      child: Table(
                        border: TableBorder.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        columnWidths: _columnWidths,
                        children: List.generate(_paginatedFranchises.length, (index) {
                          final franchise = _paginatedFranchises[index];
                          final srNo = _paginatedFranchises.length - index;

                          return TableRow(
                            decoration: BoxDecoration(
                              color: index % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC),
                            ),
                            children: [
                              // ✅ SR No
                              GestureDetector(
                                onTap: () => _showDetailsPopup(franchise),
                                child: _cell(srNo.toString()),
                              ),
                              // ✅ Franchise Name
                              GestureDetector(
                                onTap: () => _showDetailsPopup(franchise),
                                child: _cell(franchise.franchiseName),
                              ),
                              // ✅ Company Name
                              GestureDetector(
                                onTap: () => _showDetailsPopup(franchise),
                                child: _cell(franchise.companyName),
                              ),
                              // ✅ Owner Name
                              GestureDetector(
                                onTap: () => _showDetailsPopup(franchise),
                                child: _cell(franchise.ownerName),
                              ),
                              // ✅ Email
                              GestureDetector(
                                onTap: () => _showDetailsPopup(franchise),
                                child: _cell(franchise.email),
                              ),
                              // ✅ Mobile
                              GestureDetector(
                                onTap: () => _showDetailsPopup(franchise),
                                child: _cell(franchise.mobileNo),
                              ),
                              // ✅ City
                              GestureDetector(
                                onTap: () => _showDetailsPopup(franchise),
                                child: _cell(franchise.city),
                              ),
                              // ✅ State
                              GestureDetector(
                                onTap: () => _showDetailsPopup(franchise),
                                child: _cell(franchise.state),
                              ),
                              // ✅ Pincode
                              GestureDetector(
                                onTap: () => _showDetailsPopup(franchise),
                                child: _cell(franchise.pincode),
                              ),
                              // ✅ Commission
                              GestureDetector(
                                onTap: () => _showDetailsPopup(franchise),
                                child: _cell('${franchise.commissionPercentage}%'),
                              ),
                              // ✅ Joining Date
                              GestureDetector(
                                onTap: () => _showDetailsPopup(franchise),
                                child: _cell(_formatDate(franchise.joiningDate)),
                              ),
                              // ✅ Status
                              GestureDetector(
                                onTap: () => _showDetailsPopup(franchise),
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.all(2),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: franchise.isActive ? Colors.green[50] : Colors.red[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        franchise.isActive ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          color: franchise.isActive ? Colors.green[800] : Colors.red[800],
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // ✅ Franchise Code (पूर्वी "Code" होतं)
                              GestureDetector(
                                onTap: () => _showDetailsPopup(franchise),
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.all(2),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        franchise.franchiseCode,
                                        style: TextStyle(
                                          color: Colors.blue[800],
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // ✅ Referral Code
                              GestureDetector(
                                onTap: () => _showDetailsPopup(franchise),
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.all(2),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        franchise.franchiseReferralCode ?? 'N/A',
                                        style: TextStyle(
                                          color: Colors.purple[800],
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
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
    );
  }
}