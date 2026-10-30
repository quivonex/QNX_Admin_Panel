import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../api/api_service.dart';
import '../../api/api_response.dart';

class ApprovedMarketingPartnersScreen extends StatefulWidget {
  const ApprovedMarketingPartnersScreen({super.key});

  @override
  State<ApprovedMarketingPartnersScreen> createState() =>
      _ApprovedMarketingPartnersScreenState();
}

class _ApprovedMarketingPartnersScreenState
    extends State<ApprovedMarketingPartnersScreen> {
  final ApprovedMarketingPartnerService _service =
  ApprovedMarketingPartnerService();

  List<ApprovedMarketingPartner> allPartners = [];
  List<ApprovedMarketingPartner> filteredPartners = [];
  List<ApprovedMarketingPartner> paginatedPartners = [];

  // Cache for bank details
  final Map<int, BankDetailResponse> _bankDetailsCache = {};

  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String filterType = 'Name';

  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  // Updated column widths with View column added
  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(45),   // View Icon
    1: FixedColumnWidth(50),   // SR No
    2: FixedColumnWidth(170),  // Full Name
    3: FixedColumnWidth(70),   // Profile Image
    4: FixedColumnWidth(180),  // Email
    5: FixedColumnWidth(100),  // Mobile
    6: FixedColumnWidth(140),  // Working Area
    7: FixedColumnWidth(70),   // Team Size
    8: FixedColumnWidth(80),   // Status
    9: FixedColumnWidth(120),  // Created At
    10: FixedColumnWidth(120),  // Application Type
    11: FixedColumnWidth(80),  // Payment/Upi
  };

  // Updated header labels with View column
  final List<String> headerLabels = [
    "View",
    "SR No",
    "Full Name",
    "Profile",
    "Email",
    "Mobile",
    "Working Area",
    "Team Size",
    "Status",
    "Created",
    "Type",
    "Payment"
  ];

  static const Color _primaryColor = Color(0xFF4158D0);
  static const Color _secondaryColor = Color(0xFFC850C0);
  static const Color _bgColor = Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();
    loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerHorizontalController.dispose();
    _rowsHorizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      final response = await _service.getList();
      if (mounted) {
        setState(() {
          allPartners = response.data;
          applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load data: $e")),
        );
      }
    }
  }

  // ====================== FETCH BANK DETAILS ======================

  Future<BankDetailResponse?> _fetchBankDetails(int partnerId) async {
    if (_bankDetailsCache.containsKey(partnerId)) {
      return _bankDetailsCache[partnerId];
    }

    try {
      final response = await BankDetailService.fetchBankDetails(partnerId);
      _bankDetailsCache[partnerId] = response;
      return response;
    } catch (e) {
      print('Failed to fetch bank details for partner $partnerId: $e');
      return null;
    }
  }

  String _getUpiId(BankDetailResponse? bankDetails) {
    if (bankDetails == null || bankDetails.data.isEmpty) {
      return '';
    }
    final bankDetail = bankDetails.data[0];
    if (bankDetail.upiId != null && bankDetail.upiId!.isNotEmpty) {
      return bankDetail.upiId!;
    }
    return '';
  }

  String _getBankAccountHolder(BankDetailResponse? bankDetails) {
    if (bankDetails == null || bankDetails.data.isEmpty) {
      return '';
    }
    return bankDetails.data[0].accountHolderName;
  }

  // ====================== POPUP WITH QR CODE ======================

  Future<void> _showPartnerPopup(ApprovedMarketingPartner partner) async {
    // Fetch bank details
    final bankDetails = await _fetchBankDetails(partner.id);
    final upiId = _getUpiId(bankDetails);
    final accountHolder = _getBankAccountHolder(bankDetails);

    // Generate UPI payment string from actual UPI ID
    String upiPaymentString = '';
    if (upiId.isNotEmpty) {
      upiPaymentString =
      "upi://pay?pa=$upiId&pn=${Uri.encodeComponent(partner.fullName)}&am=100&cu=INR";
    }

    // Show popup with QR code
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    _buildProfileImage(partner.profileImage, 50),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            partner.fullName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            partner.email,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
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
                      // Partner Information
                      _buildInfoSection("Personal Information", [
                        _buildInfoRow("Name", partner.fullName),
                        _buildInfoRow("Email", partner.email),
                        _buildInfoRow("Mobile", partner.mobile),
                        _buildInfoRow("Status", partner.status),
                        _buildInfoRow("Type", partner.applicationType),
                      ]),
                      const SizedBox(height: 16),

                      // Location Information
                      _buildInfoSection("Location Details", [
                        _buildInfoRow("State", partner.state),
                        _buildInfoRow("District", partner.district),
                        _buildInfoRow("Taluka", partner.taluka),
                        _buildInfoRow("Village", partner.village),
                        _buildInfoRow("Pincode", partner.pincode),
                        _buildInfoRow("Working Area", partner.workingArea),
                      ]),
                      const SizedBox(height: 16),

                      // Professional Information
                      _buildInfoSection("Professional Details", [
                        _buildInfoRow("Profession", partner.profession),
                        _buildInfoRow("Experience", partner.experience),
                        _buildInfoRow("Team Size", partner.teamSize.toString()),
                        _buildInfoRow(
                          "Promotion Platforms",
                          partner.promotionPlatforms.join(", "),
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // Referral Information
                      if (partner.referredByName != null)
                        _buildInfoSection("Referral Details", [
                          _buildInfoRow("Referred By", partner.referredByName!),
                          _buildInfoRow("Referral Code",
                              partner.referredByReferralCode ?? "N/A"),
                        ]),
                      const SizedBox(height: 16),

                      // Bank Details Section
                      _buildBankDetailsSection(bankDetails),

                      const SizedBox(height: 16),

                      // QR Code / UPI Payment Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple.shade50, Colors.blue.shade50],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.purple.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.payment, color: Colors.purple),
                                SizedBox(width: 8),
                                Text(
                                  "Payment / UPI",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            if (upiId.isNotEmpty) ...[
                              // QR Code
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: QrImageView(
                                      data: upiPaymentString,
                                      version: QrVersions.auto,
                                      size: 180,
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      errorCorrectionLevel: QrErrorCorrectLevel.H,
                                      eyeStyle: const QrEyeStyle(
                                        eyeShape: QrEyeShape.circle,
                                        color: Colors.purple,
                                      ),
                                      dataModuleStyle: const QrDataModuleStyle(
                                        dataModuleShape: QrDataModuleShape.circle,
                                        color: Colors.purple,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.qr_code_scanner,
                                          color: Colors.purple,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "UPI ID: $upiId",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.purple,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (accountHolder.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        "Account: $accountHolder",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.info_outline,
                                          color: Colors.grey,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          "Scan QR code to make payment",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Download QR Code Button
                              if (kIsWeb)
                                TextButton.icon(
                                  onPressed: () {
                                    _downloadQRCode(
                                        upiPaymentString, partner.fullName);
                                  },
                                  icon: const Icon(Icons.download, size: 18),
                                  label: const Text("Download QR Code"),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.purple,
                                  ),
                                ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                  Border.all(color: Colors.grey.shade300),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.orange,
                                      size: 40,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "No UPI ID found for this partner",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Please add bank details with UPI ID",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankDetailsSection(BankDetailResponse? bankDetails) {
    if (bankDetails == null || bankDetails.data.isEmpty) {
      return _buildInfoSection("Bank Details", [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              "No bank details available",
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ),
      ]);
    }

    final bank = bankDetails.data[0];
    return _buildInfoSection("Bank Details", [
      _buildInfoRow("Account Holder", bank.accountHolderName),
      _buildInfoRow("Bank Name", bank.bankName),
      _buildInfoRow("Branch", bank.branchName),
      _buildInfoRow("Account Number", bank.accountNumber),
      _buildInfoRow("IFSC Code", bank.ifscCode),
      _buildInfoRow("Account Type", bank.accountType.toUpperCase()),
      if (bank.upiId != null && bank.upiId!.isNotEmpty)
        _buildInfoRow("UPI ID", bank.upiId!),
    ]);
  }

  // Helper method to download QR code (Web only)
  void _downloadQRCode(String data, String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("QR Code for $name is ready to scan"),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4158D0),
            ),
          ),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? "N/A" : value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====================== REST OF THE CODE (Same as before) ======================

  void applyFilters() {
    if (searchQuery.isEmpty) {
      filteredPartners = List.from(allPartners);
    } else {
      final query = searchQuery.toLowerCase();
      filteredPartners = allPartners.where((p) {
        switch (filterType) {
          case 'Name':
            return p.fullName.toLowerCase().contains(query);
          case 'Email':
            return p.email.toLowerCase().contains(query);
          case 'Mobile':
            return p.mobile.contains(query);
          case 'Status':
            return p.status.toLowerCase().contains(query);
          default:
            return false;
        }
      }).toList();
    }
    applyPagination();
  }

  void applyPagination() {
    if (filteredPartners.isEmpty) {
      paginatedPartners = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }
    totalPages = (filteredPartners.length / itemsPerPage).ceil();
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    if (end > filteredPartners.length) end = filteredPartners.length;
    paginatedPartners = filteredPartners.sublist(start, end);
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

  // ====================== EXPORT FUNCTIONS ======================

  void exportExcel() {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Export is only available on web")),
      );
      return;
    }
    final file = excel.Excel.createExcel();
    final sheet = file['Marketing Partners'];
    sheet.appendRow([
      "SR No",
      "Full Name",
      "Email",
      "Mobile",
      "Working Area",
      "Team Size",
      "Status",
      "Type",
      "Created At"
    ]);
    int srNo = 1;
    for (var p in filteredPartners) {
      sheet.appendRow([
        srNo++,
        p.fullName,
        p.email,
        p.mobile,
        p.workingArea,
        p.teamSize,
        p.status,
        p.applicationType,
        p.createdAt.substring(0, 10),
      ]);
    }
    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "approved_marketing_partners.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> exportPDF() async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PDF export is only available on web")),
      );
      return;
    }
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: [
              "SR No",
              "Name",
              "Email",
              "Mobile",
              "Working Area",
              "Team Size",
              "Status",
              "Type",
              "Created"
            ],
            data: List.generate(filteredPartners.length, (index) {
              final p = filteredPartners[index];
              return [
                (index + 1).toString(),
                p.fullName,
                p.email,
                p.mobile,
                p.workingArea,
                p.teamSize.toString(),
                p.status,
                p.applicationType,
                p.createdAt.substring(0, 10),
              ];
            }),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void exportDOC() {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("DOC export is only available on web")),
      );
      return;
    }
    final content = StringBuffer();
    content.writeln("Approved Marketing Partners List\n");
    content.writeln("=" * 50);
    int srNo = 1;
    for (var p in filteredPartners) {
      content.writeln("SR No: ${srNo++}");
      content.writeln("Name: ${p.fullName}");
      content.writeln("Email: ${p.email}");
      content.writeln("Mobile: ${p.mobile}");
      content.writeln("Working Area: ${p.workingArea}");
      content.writeln("Team Size: ${p.teamSize}");
      content.writeln("Status: ${p.status}");
      content.writeln("Type: ${p.applicationType}");
      content.writeln("Created: ${p.createdAt.substring(0, 10)}");
      content.writeln("-" * 30);
    }
    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "approved_marketing_partners.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ====================== UI HELPERS ======================

  Widget _buildProfileImage(String? url, double size) {
    if (url == null || url.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person, size: size * 0.5, color: Colors.white70),
      );
    }
    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person, size: size * 0.5, color: Colors.white70),
        ),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: size,
            height: size,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }

  Widget _statusChip(String label) {
    Color color;
    if (label.toLowerCase() == 'approved') {
      color = Colors.green;
    } else if (label.toLowerCase() == 'rejected') {
      color = Colors.red;
    } else {
      color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ====================== FILTER SECTION ======================

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
          )
        ],
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
                  Text("Total: ${filteredPartners.length}"),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: resetFilters,
                    icon: const Icon(Icons.refresh),
                    color: Colors.red,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
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
          Text("Total: ${filteredPartners.length}"),
          IconButton(
            onPressed: resetFilters,
            icon: const Icon(Icons.refresh),
            color: Colors.red,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
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
          items: ['Name', 'Email', 'Mobile', 'Status']
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
          prefixIcon:
          const Icon(Icons.search, size: 16, color: Color(0xFF6366F1)),
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
              child: Image.asset(
                "assets/icon/xls.png",
                height: 20,
                width: 20,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.table_chart, size: 20, color: Colors.green),
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
              child: Image.asset(
                "assets/icon/pdf.png",
                height: 20,
                width: 20,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.picture_as_pdf, size: 20, color: Colors.red),
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
              child: Image.asset(
                "assets/icon/doc.png",
                height: 20,
                width: 20,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.description, size: 20, color: Colors.blue),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ====================== TABLE ======================

  Widget _tableHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  Widget _tableCell(String text, {VoidCallback? onTap, bool isBold = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 45,
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

  // ====================== PAGINATION ======================

  Widget _buildPagination() {
    if (filteredPartners.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text("Show "),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: itemsPerPage,
                    onChanged: changeItemsPerPage,
                    items: rowsPerPageOptions.map((opt) {
                      return DropdownMenuItem(
                        value: opt,
                        child: Text(opt.toString()),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Text(" rows per page"),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: currentPage > 1 ? previousPage : null,
                icon: const Icon(Icons.chevron_left, size: 20),
              ),
              ...List.generate(totalPages, (index) {
                final pageNum = index + 1;
                final isSelected = pageNum == currentPage;
                return _buildPageNumButton(pageNum, isSelected);
              }),
              IconButton(
                onPressed: currentPage < totalPages ? nextPage : null,
                icon: const Icon(Icons.chevron_right, size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageNumButton(int pageNum, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isSelected ? _primaryColor : Colors.transparent,
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

  // ====================== MAIN BUILD ======================

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Approved Marketing Partners",
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
                  // Fixed header
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
                          horizontalInside:
                          BorderSide(color: Colors.grey.shade300),
                          verticalInside:
                          BorderSide(color: Colors.grey.shade300),
                          top: BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                        columnWidths: columnWidths,
                        children: [
                          TableRow(
                            children: headerLabels
                                .map((l) => _tableHeader(l))
                                .toList(),
                          )
                        ],
                      ),
                    ),
                  ),
                  // Scrollable rows
                  Expanded(
                    child: filteredPartners.isEmpty
                        ? const Center(
                        child: Text("No marketing partners found"))
                        : SingleChildScrollView(
                      controller: _verticalController,
                      child: SingleChildScrollView(
                        controller: _rowsHorizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          border: TableBorder.all(
                              color: Colors.grey.shade300),
                          columnWidths: columnWidths,
                          children: List.generate(
                            paginatedPartners.length,
                                (rowIndex) {
                              final partner =
                              paginatedPartners[rowIndex];
                              final bool isEven =
                                  rowIndex % 2 == 0;
                              final int srNo =
                                  filteredPartners.length -
                                      ((currentPage - 1) *
                                          itemsPerPage +
                                          rowIndex);

                              // Create a single tap handler for the entire row
                              VoidCallback onRowTap =
                                  () => _showPartnerPopup(partner);

                              return TableRow(
                                decoration: BoxDecoration(
                                  color: isEven
                                      ? Colors.white
                                      : const Color(0xFFF8FAFC),
                                ),
                                children: [
                                  // VIEW ICON COLUMN
                                  GestureDetector(
                                    onTap: onRowTap,
                                    child: Container(
                                      height: 45,
                                      alignment: Alignment.center,
                                      child: Container(
                                        padding:
                                        const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: _primaryColor
                                              .withOpacity(0.1),
                                          borderRadius:
                                          BorderRadius.circular(
                                              8),
                                        ),
                                        child: const Icon(
                                          Icons.visibility,
                                          color: _primaryColor,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // SR NO - Clickable
                                  GestureDetector(
                                    onTap: onRowTap,
                                    child: _tableCell(
                                        srNo.toString()),
                                  ),
                                  // Full Name - Clickable
                                  GestureDetector(
                                    onTap: onRowTap,
                                    child: _tableCell(
                                        partner.fullName),
                                  ),
                                  // Profile Image - Clickable
                                  GestureDetector(
                                    onTap: onRowTap,
                                    child: Container(
                                      height: 40,
                                      width: 40,
                                      alignment: Alignment.center,
                                      child: _buildProfileImage(
                                          partner.profileImage, 35),
                                    ),
                                  ),
                                  // Email - Clickable
                                  GestureDetector(
                                    onTap: onRowTap,
                                    child:
                                    _tableCell(partner.email),
                                  ),
                                  // Mobile - Clickable
                                  GestureDetector(
                                    onTap: onRowTap,
                                    child:
                                    _tableCell(partner.mobile),
                                  ),
                                  // Working Area - Clickable
                                  GestureDetector(
                                    onTap: onRowTap,
                                    child: _tableCell(
                                        partner.workingArea),
                                  ),
                                  // Team Size - Clickable
                                  GestureDetector(
                                    onTap: onRowTap,
                                    child: _tableCell(partner
                                        .teamSize
                                        .toString()),
                                  ),
                                  // Status - Clickable
                                  GestureDetector(
                                    onTap: onRowTap,
                                    child: Container(
                                      padding:
                                      const EdgeInsets.all(4),
                                      child: _statusChip(
                                          partner.status),
                                    ),
                                  ),
                                  // Created At - Clickable
                                  GestureDetector(
                                    onTap: onRowTap,
                                    child: _tableCell(partner
                                        .createdAt
                                        .substring(0, 10)),
                                  ),
                                  // Application Type - Clickable
                                  GestureDetector(
                                    onTap: onRowTap,
                                    child: _tableCell(
                                        partner.applicationType),
                                  ),
                                  // Payment / UPI - Clickable with QR icon
                                  GestureDetector(
                                    onTap: onRowTap,
                                    child: Container(
                                      height: 45,
                                      alignment: Alignment.center,
                                      child: Container(
                                        padding:
                                        const EdgeInsets
                                            .symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.purple
                                              .withOpacity(0.1),
                                          borderRadius:
                                          BorderRadius.circular(
                                              12),
                                          border: Border.all(
                                            color: Colors.purple
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize:
                                          MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons
                                                  .qr_code_scanner,
                                              color: Colors.purple,
                                              size: 14,
                                            ),
                                            const SizedBox(
                                                width: 4),
                                            Text(
                                              "UPI",
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight:
                                                FontWeight.bold,
                                                color: Colors
                                                    .purple
                                                    .shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ).toList(),
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