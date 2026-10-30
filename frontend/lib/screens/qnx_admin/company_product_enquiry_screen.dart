import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;
import '../../models/qnx_admin/company_product_enquiry_model.dart';
import '../../models/qnx_admin/approved_enquiry_model.dart';
import '../../api/api_service.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:intl/intl.dart';

// ==============================
// 1. Reusable Pending Enquiry Table (with send button)
// ==============================
class PendingEnquiryTable extends StatefulWidget {
  final List<PendingEnquiry> initialData;
  final Future<void> Function(PendingEnquiry enquiry) onSend;
  final bool showSendButton;

  const PendingEnquiryTable({
    super.key,
    required this.initialData,
    required this.onSend,

    this.showSendButton = true,
  });

  @override
  State<PendingEnquiryTable> createState() => _PendingEnquiryTableState();
}

class _PendingEnquiryTableState extends State<PendingEnquiryTable> {
  late List<PendingEnquiry> allEnquiries;
  late List<PendingEnquiry> filteredEnquiries;
  List<PendingEnquiry> paginatedEnquiries = [];

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

  // Premium gradient colors (matching dashboard)
  static const Color _premiumPrimary = Color(0xFF4158D0);
  static const Color _premiumSecondary = Color(0xFFC850C0);

  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(60),   // SR No
    1: FixedColumnWidth(80),   // Thumbnail
    2: FixedColumnWidth(130),  // Product Name
    3: FixedColumnWidth(120),  // Company Name
    4: FixedColumnWidth(120),  // Person Name
    5: FixedColumnWidth(140),  // Email
    6: FixedColumnWidth(100),  // Contact
    7: FixedColumnWidth(100),  // Color
    8: FixedColumnWidth(80),   // Size
    9: FixedColumnWidth(100),  // Variant
    10: FixedColumnWidth(80),  // Demo Required
    11: FixedColumnWidth(100), // Demo Type
    12: FixedColumnWidth(100), // Status
    13: FixedColumnWidth(100), // Sent to Company
    14: FixedColumnWidth(120), // Referral Code  // ✅ NEW
    15: FixedColumnWidth(150), // Address
    16: FixedColumnWidth(80),  // Pincode
    17: FixedColumnWidth(150), // Message
    18: FixedColumnWidth(140), // Created At
    19: FixedColumnWidth(70),  // Action
  };

  final List<String> headerLabels = const [
    "SR No", "Thumbnail", "Product Name", "Company Name", "Person Name",
    "Email", "Contact", "Color", "Size", "Variant", "Demo Req",
    "Demo Type", "Status", "Sent to Co.", "Referral Code", // ✅ NEW
    "Address", "Pincode", "Message", "Created At", "Action"
  ];

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();
    allEnquiries = List.from(widget.initialData);
    applyFilters();
  }
  @override
  void didUpdateWidget(PendingEnquiryTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Data बदलल्यास refresh करा
    if (oldWidget.initialData != widget.initialData) {
      setState(() {
        allEnquiries = List.from(widget.initialData);
        applyFilters();
      });
    }
  }
  void applyFilters() {
    if (searchQuery.isEmpty) {
      filteredEnquiries = List.from(allEnquiries);
    } else {
      final query = searchQuery.toLowerCase();
      filteredEnquiries = allEnquiries.where((e) {
        if (filterType == 'Product Name') return e.productName.toLowerCase().contains(query);
        if (filterType == 'Person Name') return (e.personName ?? '').toLowerCase().contains(query);
        return (e.email ?? '').toLowerCase().contains(query);
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
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    if (end > filteredEnquiries.length) end = filteredEnquiries.length;
    paginatedEnquiries = filteredEnquiries.sublist(start, end);
    setState(() {});
  }

  void nextPage() {
    if (currentPage < totalPages) {
      currentPage++;
      applyPagination();
    }
  }

  void previousPage() {
    if (currentPage > 1) {
      currentPage--;
      applyPagination();
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      currentPage = page;
      applyPagination();
    }
  }

  void changeItemsPerPage(int? v) {
    if (v != null) {
      itemsPerPage = v;
      currentPage = 1;
      applyPagination();
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

  String formatDateTime(String dt) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(dt));
    } catch (_) {
      return dt;
    }
  }

  // Premium styled details popup matching marketing heads screen
  void _showDetailsPopup(PendingEnquiry enquiry) {
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
                          child: const Icon(Icons.shopping_bag, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                enquiry.productName,
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
                                "Enquiry",
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
                              _premiumStatusChip(
                                enquiry.status,
                                enquiry.status == 'approved' ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 12),
                              _premiumStatusChip(
                                enquiry.isSentToCompany ? "Sent to Company" : "Not Sent",
                                enquiry.isSentToCompany ? Colors.blue : Colors.grey,
                                icon: enquiry.isSentToCompany ? Icons.check_circle : Icons.hourglass_empty,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Product Details Section
                          _buildPremiumSection(
                            title: "Product Details",
                            icon: Icons.shopping_bag_outlined,
                            children: [
                              _infoRow("Product Name", enquiry.productName),
                              _infoRow("Company", enquiry.companyName ?? "-"),
                              _infoRow("Color", enquiry.selectedColor ?? "-"),
                              _infoRow("Size", enquiry.selectedSize ?? "-"),
                              _infoRow("Variant", enquiry.selectedVariant ?? "-"),
                              _infoRow("Referral Code", enquiry.enquiryReferralCode ?? "-"),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Product Image Section
                          if (enquiry.productImage != null && enquiry.productImage!.isNotEmpty)
                            _buildPremiumSection(
                              title: "Product Image",
                              icon: Icons.image_outlined,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    enquiry.productImage!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
                                  ),
                                ),
                              ],
                            ),

                          if (enquiry.productImage != null && enquiry.productImage!.isNotEmpty)
                            const SizedBox(height: 20),

                          // Variants Section
                          if (enquiry.variants != null && enquiry.variants!.isNotEmpty)
                            _buildPremiumSection(
                              title: "Product Variants",
                              icon: Icons.list_alt,
                              children: enquiry.variants!.map((variant) => _buildVariantChip(variant)).toList(),
                            ),

                          if (enquiry.variants != null && enquiry.variants!.isNotEmpty)
                            const SizedBox(height: 20),

                          // Customer Details Section
                          _buildPremiumSection(
                            title: "Customer Details",
                            icon: Icons.person_outline,
                            children: [
                              _infoRow("Person Name", enquiry.personName ?? "-"),
                              _infoRow("Email", enquiry.email ?? "-"),
                              _infoRow("Contact", enquiry.contact ?? "-"),
                              _infoRow("Address", enquiry.address ?? "-"),
                              _infoRow("Pincode", enquiry.pincode ?? "-"),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Demo Information Section
                          _buildPremiumSection(
                            title: "Demo Information",
                            icon: Icons.mobile_screen_share_outlined,
                            children: [
                              _infoRow("Demo Required", enquiry.demoRequired ?? "-"),
                              _infoRow("Demo Type", enquiry.demoType ?? "-"),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Message Section
                          if (enquiry.message != null && enquiry.message!.isNotEmpty)
                            _buildPremiumSection(
                              title: "Message",
                              icon: Icons.message_outlined,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    enquiry.message!,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),

                          if (enquiry.message != null && enquiry.message!.isNotEmpty)
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
                  // Action buttons if send button is shown
                  if (widget.showSendButton)
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
                              onPressed: () {
                                Navigator.pop(ctx);
                                widget.onSend(enquiry);
                              },
                              icon: const Icon(Icons.send, size: 18),
                              label: const Text('Send to Company', style: TextStyle(fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _premiumPrimary,
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

  Widget _buildVariantChip(dynamic variant) {
    final attrs = variant['attributes'] as Map<String, dynamic>?;
    final price = variant['final_price'] ?? variant['price'];
    final stock = variant['stock_quantity'];
    final sku = variant['sku'];
    String attrStr = attrs?.entries.map((e) => "${e.key}: ${e.value}").join(", ") ?? "";
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        "$attrStr | ₹$price | Stock: $stock | SKU: $sku",
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  // ---------- Export ----------
  void exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['Enquiries'];
    sheet.appendRow(headerLabels.where((h) => h != "Action").toList());
    int srNo = 1;
    for (var e in filteredEnquiries) {
      sheet.appendRow([
        srNo++,
        e.productImage ?? '',
        e.productName,
        e.companyName ?? '-',
        e.personName ?? '-',
        e.email ?? '-',
        e.contact ?? '-',
        e.selectedColor ?? '-',
        e.selectedSize ?? '-',
        e.selectedVariant ?? '-',
        e.demoRequired ?? '-',
        e.demoType ?? '-',
        e.status,
        e.isSentToCompany ? 'Yes' : 'No',
        e.enquiryReferralCode ?? '-',
        e.address ?? '-',
        e.pincode ?? '-',
        e.message ?? '-',
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
    pdf.addPage(pw.Page(
        build: (_) => pw.Table.fromTextArray(
          headers: headerLabels.where((h) => h != "Action").toList(),
          data: filteredEnquiries.asMap().entries.map((entry) {
            final e = entry.value;
            final srNo = entry.key + 1;
            return [
              srNo,
              e.productImage ?? '',
              e.productName,
              e.companyName ?? '-',
              e.personName ?? '-',
              e.email ?? '-',
              e.contact ?? '-',
              e.selectedColor ?? '-',
              e.selectedSize ?? '-',
              e.selectedVariant ?? '-',
              e.demoRequired ?? '-',
              e.demoType ?? '-',
              e.status,
              e.isSentToCompany ? 'Yes' : 'No',
              e.enquiryReferralCode ?? '-',
              e.address ?? '-',
              e.pincode ?? '-',
              e.message ?? '-',
              formatDateTime(e.createdAt),
            ];
          }).toList(),
        )));
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  void exportDOC() {
    final content = StringBuffer();
    content.writeln("Enquiries List\n");
    content.writeln("=" * 50);
    int srNo = 1;
    for (var e in filteredEnquiries) {
      content.writeln("SR No: ${srNo++}");
      content.writeln("Product Image: ${e.productImage ?? '-'}");
      content.writeln("Product: ${e.productName}");
      content.writeln("Company: ${e.companyName ?? '-'}");
      content.writeln("Person: ${e.personName ?? '-'}");
      content.writeln("Email: ${e.email ?? '-'}");
      content.writeln("Contact: ${e.contact ?? '-'}");
      content.writeln("Color: ${e.selectedColor ?? '-'}");
      content.writeln("Size: ${e.selectedSize ?? '-'}");
      content.writeln("Variant: ${e.selectedVariant ?? '-'}");
      content.writeln("Demo Required: ${e.demoRequired ?? '-'}");
      content.writeln("Demo Type: ${e.demoType ?? '-'}");
      content.writeln("Status: ${e.status}");
      content.writeln("Sent to Company: ${e.isSentToCompany ? 'Yes' : 'No'}");
      content.writeln("Address: ${e.address ?? '-'}");
      content.writeln("Pincode: ${e.pincode ?? '-'}");
      content.writeln("Message: ${e.message ?? '-'}");
      content.writeln("Created At: ${formatDateTime(e.createdAt)}");
      content.writeln("-" * 30);
    }
    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "enquiries.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ---------- UI Filter, Pagination, etc. ----------
  Widget _buildFilterRow(bool isMobile) {
    const double dropdownWidth = 160;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
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
                border: Border.all(color: Colors.grey.shade200)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: filterType,
                icon: const Icon(Icons.arrow_drop_down,
                    color: Color(0xFF6366F1)),
                style: const TextStyle(
                    color: Color(0xFF1E293B), fontSize: 13),
                isExpanded: true,
                onChanged: (v) {
                  setState(() {
                    filterType = v!;
                    currentPage = 1;
                    applyFilters();
                  });
                },
                items: ['Product Name', 'Person Name', 'Email']
                    .map<DropdownMenuItem<String>>((v) {
                  return DropdownMenuItem(
                    value: v,
                    child: Row(
                      children: [
                        Icon(
                          v == 'Product Name'
                              ? Icons.shopping_bag
                              : v == 'Company Name'
                              ? Icons.business
                              : v == 'Person Name'
                              ? Icons.person
                              : Icons.email,
                          size: 14,
                          color: const Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 8),
                        Text(v),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200)),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search by $filterType...",
                  prefixIcon: const Icon(Icons.search, size: 16,
                      color: Color(0xFF6366F1)),
                  border: InputBorder.none,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 14),
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
        ]),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildExportIcons(),
            Row(
              children: [
                Text(
                  "Total: ${filteredEnquiries.length}",
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: resetFilters,
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
              border: Border.all(color: Colors.grey.shade200)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: filterType,
              icon:
              const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
              style:
              const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
              isExpanded: true,
              onChanged: (v) {
                setState(() {
                  filterType = v!;
                  currentPage = 1;
                  applyFilters();
                });
              },
              items: ['Product Name', 'Person Name', 'Email']
                  .map<DropdownMenuItem<String>>((v) {
                return DropdownMenuItem(
                  value: v,
                  child: Row(
                    children: [
                      Icon(
                        v == 'Product Name'
                            ? Icons.shopping_bag
                            : (v == 'Person Name'
                            ? Icons.person
                            : Icons.email),
                        size: 14,
                        color: const Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 8),
                      Text(v),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by $filterType...",
                prefixIcon: const Icon(Icons.search, size: 16,
                    color: Color(0xFF6366F1)),
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
        _buildExportIcons(),
        const SizedBox(width: 12),
        Row(
          children: [
            Text(
              "Total: ${filteredEnquiries.length}",
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: resetFilters,
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
            onTap: exportExcel,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Image.asset("assets/icon/xls.png", height: 20, width: 20),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "PDF",
          child: InkWell(
            onTap: exportPDF,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Image.asset("assets/icon/pdf.png", height: 20, width: 20),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "DOC",
          child: InkWell(
            onTap: exportDOC,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Image.asset("assets/icon/doc.png", height: 20, width: 20),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPaginationWidgets(bool isMobile) {
    if (filteredEnquiries.isEmpty) return [];
    final List<Widget> pageWidgets = [];

    final showEntriesRow = Row(
      mainAxisAlignment: isMobile ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        const Text("Show "),
        DropdownButton<int>(
          value: itemsPerPage,
          items: rowsPerPageOptions
              .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
              .toList(),
          onChanged: changeItemsPerPage,
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down),
        ),
        const Text(" entries"),
        const SizedBox(width: 12),
        Text(
          "Showing ${(currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filteredEnquiries.length ? filteredEnquiries.length : currentPage * itemsPerPage} of ${filteredEnquiries.length}",
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );

    final List<Widget> rightChildren = [];
    rightChildren.add(_pageButton(Icons.chevron_left, currentPage > 1 ? previousPage : null));
    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        rightChildren.add(_pageNumber(i));
      }
    } else if (currentPage <= 3) {
      for (int i = 1; i <= 4; i++) {
        rightChildren.add(_pageNumber(i));
      }
      rightChildren.add(const Text("..."));
      rightChildren.add(_pageNumber(totalPages));
    } else if (currentPage >= totalPages - 2) {
      rightChildren.add(_pageNumber(1));
      rightChildren.add(const Text("..."));
      for (int i = totalPages - 3; i <= totalPages; i++) {
        rightChildren.add(_pageNumber(i));
      }
    } else {
      rightChildren.add(_pageNumber(1));
      rightChildren.add(const Text("..."));
      rightChildren.add(_pageNumber(currentPage - 1));
      rightChildren.add(_pageNumber(currentPage));
      rightChildren.add(_pageNumber(currentPage + 1));
      rightChildren.add(const Text("..."));
      rightChildren.add(_pageNumber(totalPages));
    }
    rightChildren.add(_pageButton(Icons.chevron_right, currentPage < totalPages ? nextPage : null));
    final paginationRow = Row(
      mainAxisAlignment: isMobile ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: rightChildren,
    );

    if (isMobile) {
      pageWidgets.add(showEntriesRow);
      pageWidgets.add(const SizedBox(height: 8));
      pageWidgets.add(paginationRow);
    } else {
      pageWidgets.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [showEntriesRow, paginationRow],
      ));
    }
    return pageWidgets;
  }

  Widget _buildPagination() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final widgets = _buildPaginationWidgets(isMobile);
    if (widgets.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widgets,
        ),
      ),
    );
  }

  Widget _pageButton(IconData icon, VoidCallback? onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6)),
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: onTap,
        color: onTap != null ? const Color(0xFF6366F1) : Colors.grey,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
    );
  }

  Widget _pageNumber(int pageNum) {
    final isSelected = currentPage == pageNum;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6)),
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
                fontSize: 11),
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
    return Column(
      children: [
        _buildFilterRow(isMobile),
        const SizedBox(height: 8),
        Expanded(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    border: Border.all(color: Colors.grey.shade300)),
                child: SingleChildScrollView(
                  controller: _headerHorizontalController,
                  scrollDirection: Axis.horizontal,
                  child: Table(
                    border: TableBorder(
                      horizontalInside: BorderSide(color: Colors.grey.shade300),
                      verticalInside: BorderSide(color: Colors.grey.shade300),
                    ),
                    columnWidths: columnWidths,
                    children: [
                      TableRow(
                        children: headerLabels
                            .map((l) => Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 4),
                          child: Text(
                            l,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ))
                            .toList(),
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
                          color: Colors.grey.shade300, width: 1),
                      columnWidths: columnWidths,
                      children: List.generate(paginatedEnquiries.length, (i) {
                        final e = paginatedEnquiries[i];
                        final int srNo = filteredEnquiries.length - ((currentPage - 1) * itemsPerPage + i);
                        final List<Widget> children = [
                          GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(srNo.toString())),
                          GestureDetector(
                            onTap: () => _showDetailsPopup(e),
                            child: Container(
                              height: 42,
                              alignment: Alignment.center,
                              child: e.productImage != null && e.productImage!.isNotEmpty
                                  ? Image.network(e.productImage!, width: 36, height: 36, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image))
                                  : const Icon(Icons.image_not_supported),
                            ),
                          ),
                          GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.productName)),
                          GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.companyName ?? "-")),
                          GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.personName ?? "-")),
                          GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.email ?? "-")),
                          GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.contact ?? "-")),
                          GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.selectedColor ?? "-")),
                          GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.selectedSize ?? "-")),
                          GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.selectedVariant ?? "-")),
                          GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.demoRequired ?? "-")),
                          GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.demoType ?? "-")),
                          GestureDetector(
                            onTap: () => _showDetailsPopup(e),
                            child: Container(
                              height: 42,
                              padding: const EdgeInsets.all(2),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: e.status == 'pending'
                                      ? Colors.orange[50]
                                      : Colors.green[50],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    e.status,
                                    style: TextStyle(
                                      color: e.status == 'pending'
                                          ? Colors.orange[800]
                                          : Colors.green[800],
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.isSentToCompany ? "Yes" : "No")),
                          // ✅ Referral Code Column (NEW)
                          GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.enquiryReferralCode ?? "-")),
                          GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.address ?? "-")),
                          GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.pincode ?? "-")),
                          GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.message ?? "-")),
                          GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(formatDateTime(e.createdAt))),
                        ];
                        if (widget.showSendButton) {
                          children.add(Container(
                            height: 42,
                            padding: const EdgeInsets.all(2),
                            child: IconButton(
                              icon: const Icon(Icons.send,
                                  color: Color(0xFF4158D0), size: 18),
                              onPressed: () => _showDetailsPopup(e),
                              tooltip: 'Send to Company',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 28, minHeight: 28),
                            ),
                          ));
                        } else {
                          children.add(Container(
                            height: 42,
                            padding: const EdgeInsets.all(2),
                            child: const Icon(Icons.check_circle,
                                color: Colors.green, size: 18),
                          ));
                        }
                        return TableRow(
                          decoration: BoxDecoration(
                              color: i % 2 == 0
                                  ? Colors.white
                                  : const Color(0xFFF8FAFC)),
                          children: children,
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
    );
  }
}

// ==============================
// 2. Approved Enquiry Table (UPDATED with filters)
// ==============================
class ApprovedEnquiryTable extends StatefulWidget {
  final List<ApprovedEnquiry> initialData;

  const ApprovedEnquiryTable({super.key, required this.initialData});

  @override
  State<ApprovedEnquiryTable> createState() => _ApprovedEnquiryTableState();
}

class _ApprovedEnquiryTableState extends State<ApprovedEnquiryTable> {
  late List<ApprovedEnquiry> allEnquiries;
  late List<ApprovedEnquiry> filteredEnquiries;
  List<ApprovedEnquiry> paginatedEnquiries = [];

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String filterType = 'Product Name';

  // New filter for delivery status
  String selectedStatusFilter = 'All';
  DateTime? fromDate;
  DateTime? toDate;

  String? fromDateApi;
  String? toDateApi;
  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  // Premium gradient colors
  static const Color _premiumPrimary = Color(0xFF4158D0);
  static const Color _premiumSecondary = Color(0xFFC850C0);


  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(70),   // Action
    1: FixedColumnWidth(40),   // SR No
    2: FixedColumnWidth(100),  // Paid Status
    3: FixedColumnWidth(100),  // Status (Delivery)
    4: FixedColumnWidth(80),   // Thumbnail
    5: FixedColumnWidth(130),  // Product Name
    6: FixedColumnWidth(120),  // Company Name
    7: FixedColumnWidth(120),  // Person Name
    8: FixedColumnWidth(140),  // Email
    9: FixedColumnWidth(100),  // Contact
    10: FixedColumnWidth(80),  // Color
    11: FixedColumnWidth(60),  // Size
    12: FixedColumnWidth(80),  // Variant
    13: FixedColumnWidth(60),  // Demo Required
    14: FixedColumnWidth(80),  // Demo Type
    15: FixedColumnWidth(70),  // Sent to Company
    16: FixedColumnWidth(120), // Referral Code  // ✅ NEW
    17: FixedColumnWidth(150), // Address
    18: FixedColumnWidth(80),  // Pincode
    19: FixedColumnWidth(150), // Message
    20: FixedColumnWidth(140), // Created At
  };

  final List<String> headerLabels = const [
    "Action", "SR No", "Paid Status", "Status", "Thumbnail", "Product Name",
    "Company Name", "Person Name", "Email", "Contact", "Color", "Size", "Variant",
    "Demo Req", "Demo Type", "Sent to Co.", "Referral Code", // ✅ NEW
    "Address", "Pincode", "Message", "Created At"
  ];

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();
    allEnquiries = List.from(widget.initialData);
    // Sort by createdAt in descending order (most recent first)
    allEnquiries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    applyFilters();
  }
  String getDeliveryStatus(ApprovedEnquiry e) {
    // First check Complete
    if (e.isComplete) return 'Complete';
    // Then check Delivered
    if (e.isDelivered) return 'Delivered';
    // Then check Dispatched
    if (e.isDispatched) return 'Dispatched';
    // Default Pending
    return 'Pending';
  }
  Color getStatusColor(String status) {
    switch (status) {
      case 'Complete':
        return Colors.green;
      case 'Delivered':
        return Colors.blue;
      case 'Dispatched':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void applyFilters() {
    filteredEnquiries = List.from(allEnquiries);

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filteredEnquiries = filteredEnquiries.where((e) {
        if (filterType == 'Product Name') {
          return (e.productName ?? '').toLowerCase().contains(query);
        }else if (filterType == 'Company Name') {   // ✅ NEW
          return (e.companyName ?? '').toLowerCase().contains(query);
        }  else if (filterType == 'Person Name') {
          return (e.personName ?? '').toLowerCase().contains(query);
        } else {
          return (e.email ?? '').toLowerCase().contains(query);
        }
      }).toList();
    }

    // Apply status filter
    if (selectedStatusFilter != 'All') {
      filteredEnquiries = filteredEnquiries.where((e) {
        return getDeliveryStatus(e) == selectedStatusFilter;
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
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    if (end > filteredEnquiries.length) end = filteredEnquiries.length;
    paginatedEnquiries = filteredEnquiries.sublist(start, end);
    setState(() {});
  }

  void nextPage() {
    if (currentPage < totalPages) {
      currentPage++;
      applyPagination();
    }
  }

  void previousPage() {
    if (currentPage > 1) {
      currentPage--;
      applyPagination();
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      currentPage = page;
      applyPagination();
    }
  }

  void changeItemsPerPage(int? v) {
    if (v != null) {
      itemsPerPage = v;
      currentPage = 1;
      applyPagination();
    }
  }

  void resetFilters() {
    setState(() {
      searchQuery = '';
      filterType = 'Product Name';
      selectedStatusFilter = 'All';
      _searchController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  String formatDateTime(String dt) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(dt));
    } catch (_) {
      return dt;
    }
  }

  void _showDetailsPopup(ApprovedEnquiry enquiry) {
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
                          child: const Icon(Icons.check_circle, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                enquiry.productName ?? 'Product',
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
                                "Approved Enquiry",
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
                          // Status Row with Delivery Status
                          Row(
                            children: [
                              _premiumStatusChip(

                                enquiry.status,
                                Colors.green,

                              ),
                              const SizedBox(width: 12),
                              _premiumStatusChip(

                                getDeliveryStatus(enquiry),
                                getStatusColor(getDeliveryStatus(enquiry)),

                                icon: getDeliveryStatus(enquiry) == 'Complete'
                                    ? Icons.done_all
                                    : getDeliveryStatus(enquiry) == 'Delivered'
                                    ? Icons.local_shipping
                                    : getDeliveryStatus(enquiry) == 'Dispatched'
                                    ? Icons.send
                                    : Icons.hourglass_empty,
                              ),
                              const SizedBox(width: 12),
                              _premiumStatusChip(
                                enquiry.isPaid ? "Paid" : "Unpaid",
                                enquiry.isPaid ? Colors.green : Colors.red,
                                icon: enquiry.isPaid ? Icons.paid : Icons.currency_rupee,
                              ),
                              const SizedBox(width: 12),
                              _premiumStatusChip(
                                enquiry.isSentToCompany ? "Sent to Company" : "Not Sent",
                                enquiry.isSentToCompany ? Colors.blue : Colors.grey,
                                icon: enquiry.isSentToCompany ? Icons.check_circle : Icons.hourglass_empty,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Product Details Section
                          _buildPremiumSection(
                            title: "Product Details",
                            icon: Icons.shopping_bag_outlined,
                            children: [
                              _infoRow("Product Name", enquiry.productName ?? '-'),
                              _infoRow("Color", enquiry.selectedColor ?? "-"),
                              _infoRow("Company", enquiry.companyName ?? "-"),
                              _infoRow("Size", enquiry.selectedSize ?? "-"),
                              _infoRow("Variant", enquiry.selectedVariant ?? "-"),
                              _infoRow("Referral Code", enquiry.enquiryReferralCode ?? "-"),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Product Image Section
                          if (enquiry.productImage != null && enquiry.productImage!.isNotEmpty)
                            _buildPremiumSection(
                              title: "Product Image",
                              icon: Icons.image_outlined,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    enquiry.productImage!,
                                    height: 200,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
                                  ),
                                ),
                              ],
                            ),

                          if (enquiry.productImage != null && enquiry.productImage!.isNotEmpty)
                            const SizedBox(height: 20),

                          // Variants Section
                          if (enquiry.variants != null && enquiry.variants!.isNotEmpty)
                            _buildPremiumSection(
                              title: "Product Variants",
                              icon: Icons.list_alt,
                              children: enquiry.variants!.map((variant) => _buildVariantChip(variant)).toList(),
                            ),

                          if (enquiry.variants != null && enquiry.variants!.isNotEmpty)
                            const SizedBox(height: 20),

                          // Customer Details Section
                          _buildPremiumSection(
                            title: "Customer Details",
                            icon: Icons.person_outline,
                            children: [
                              _infoRow("Person Name", enquiry.personName ?? "-"),
                              _infoRow("Email", enquiry.email ?? "-"),
                              _infoRow("Contact", enquiry.contact ?? "-"),
                              _infoRow("Address", enquiry.address ?? "-"),
                              _infoRow("Pincode", enquiry.pincode ?? "-"),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Demo Information Section
                          _buildPremiumSection(
                            title: "Demo Information",
                            icon: Icons.mobile_screen_share_outlined,
                            children: [
                              _infoRow("Demo Required", enquiry.demoRequired ?? "-"),
                              _infoRow("Demo Type", enquiry.demoType ?? "-"),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Message Section
                          if (enquiry.message != null && enquiry.message!.isNotEmpty)
                            _buildPremiumSection(
                              title: "Message",
                              icon: Icons.message_outlined,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    enquiry.message!,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),

                          if (enquiry.message != null && enquiry.message!.isNotEmpty)
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

  Widget _buildVariantChip(dynamic variant) {
    final attrs = variant['attributes'] as Map<String, dynamic>?;
    final price = variant['final_price'] ?? variant['price'];
    final stock = variant['stock_quantity'];
    final sku = variant['sku'];
    String attrStr = attrs?.entries.map((e) => "${e.key}: ${e.value}").join(", ") ?? "";
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        "$attrStr | ₹$price | Stock: $stock | SKU: $sku",
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  // ---------- Export ----------
  void exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['ApprovedEnquiries'];
    sheet.appendRow(headerLabels);
    int srNo = 1;
    for (var e in filteredEnquiries) {
      sheet.appendRow([
        'View',
        srNo++,
        e.isPaid ? 'Paid' : 'Unpaid',
        getDeliveryStatus(e),
        e.productImage ?? '',
        e.productName,
        e.companyName ?? '-',
        e.personName ?? '-',
        e.email ?? '-',
        e.contact ?? '-',
        e.selectedColor ?? '-',
        e.selectedSize ?? '-',
        e.selectedVariant ?? '-',
        e.demoRequired ?? '-',
        e.demoType ?? '-',
        e.isSentToCompany ? 'Yes' : 'No',
        e.enquiryReferralCode ?? '-',
        e.address ?? '-',
        e.pincode ?? '-',
        e.message ?? '-',
        formatDateTime(e.createdAt),
      ]);
    }
    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "approved_enquiries.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> exportPDF() async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
        build: (_) => pw.Table.fromTextArray(
          headers: headerLabels,
          data: filteredEnquiries.asMap().entries.map((entry) {
            final e = entry.value;
            final srNo = entry.key + 1;
            return [
              'View',
              srNo,
              e.isPaid ? 'Paid' : 'Unpaid',
              getDeliveryStatus(e),
              e.productImage ?? '',
              e.productName,
              e.companyName ?? '-',
              e.personName ?? '-',
              e.email ?? '-',
              e.contact ?? '-',
              e.selectedColor ?? '-',
              e.selectedSize ?? '-',
              e.selectedVariant ?? '-',
              e.demoRequired ?? '-',
              e.demoType ?? '-',
              e.isSentToCompany ? 'Yes' : 'No',
              e.enquiryReferralCode ?? '-',
              e.address ?? '-',
              e.pincode ?? '-',
              e.message ?? '-',
              formatDateTime(e.createdAt),
            ];
          }).toList(),
        )));
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }

  void exportDOC() {
    final content = StringBuffer();
    content.writeln("Approved Enquiries List\n");
    content.writeln("=" * 50);
    int srNo = 1;
    for (var e in filteredEnquiries) {
      content.writeln("SR No: ${srNo++}");
      content.writeln("Paid Status: ${e.isPaid ? 'Paid' : 'Unpaid'}");
      content.writeln("Status: ${getDeliveryStatus(e)}");
      content.writeln("Product Image: ${e.productImage ?? '-'}");
      content.writeln("Product Name: ${e.productName}");
      content.writeln("Company: ${e.companyName ?? '-'}");
      content.writeln("Person: ${e.personName ?? '-'}");
      content.writeln("Email: ${e.email ?? '-'}");
      content.writeln("Contact: ${e.contact ?? '-'}");
      content.writeln("Color: ${e.selectedColor ?? '-'}");
      content.writeln("Size: ${e.selectedSize ?? '-'}");
      content.writeln("Variant: ${e.selectedVariant ?? '-'}");
      content.writeln("Demo Required: ${e.demoRequired ?? '-'}");
      content.writeln("Demo Type: ${e.demoType ?? '-'}");
      content.writeln("Sent to Company: ${e.isSentToCompany ? 'Yes' : 'No'}");
      content.writeln("Referral Code: ${e.enquiryReferralCode ?? '-'}");
      content.writeln("Address: ${e.address ?? '-'}");
      content.writeln("Pincode: ${e.pincode ?? '-'}");
      content.writeln("Message: ${e.message ?? '-'}");
      content.writeln("Created At: ${formatDateTime(e.createdAt)}");
      content.writeln("-" * 30);
    }
    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "approved_enquiries.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ---------- Updated Filter Row with Status Filter ----------
  Widget _buildFilterRow(bool isMobile) {
    const double dropdownWidth = 160;
    const double statusDropdownWidth = 140;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ]),
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
                border: Border.all(color: Colors.grey.shade200)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: filterType,
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
                isExpanded: true,
                onChanged: (v) {
                  setState(() {
                    filterType = v!;
                    currentPage = 1;
                    applyFilters();
                  });
                },
                items: ['Product Name', 'Person Name', 'Email']
                    .map<DropdownMenuItem<String>>((v) {
                  return DropdownMenuItem(
                    value: v,
                    child: Row(
                      children: [
                        Icon(
                          v == 'Product Name'
                              ? Icons.shopping_bag
                              : v == 'Company Name'   // ✅ NEW
                              ? Icons.business
                              : v == 'Person Name'
                              ? Icons.person
                              : Icons.email,
                          size: 14,
                          color: const Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 8),
                        Text(v),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200)),
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
            ),
          ),
        ]),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Status Filter Dropdown
            Container(
              width: statusDropdownWidth,
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedStatusFilter,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
                  style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
                  isExpanded: true,
                  onChanged: (v) {
                    setState(() {
                      selectedStatusFilter = v!;
                      currentPage = 1;
                      applyFilters();
                    });
                  },
                  items: ['All', 'Pending', 'Dispatched', 'Delivered', 'Complete']
                      .map<DropdownMenuItem<String>>((v) {
                    return DropdownMenuItem(
                      value: v,
                      child: Row(
                        children: [
                          Icon(
                            v == 'All'
                                ? Icons.filter_list
                                : v == 'Complete'
                                ? Icons.done_all
                                : v == 'Delivered'
                                ? Icons.local_shipping
                                : v == 'Dispatched'
                                ? Icons.send
                                : Icons.hourglass_empty,
                            size: 14,
                            color: v == 'All' ? Colors.grey : getStatusColor(v),
                          ),
                          const SizedBox(width: 8),
                          Text(v),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            Row(
              children: [
                _buildExportIcons(),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: resetFilters,
                  icon: const Icon(Icons.refresh),
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              "Total: ${filteredEnquiries.length}",
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
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
              border: Border.all(color: Colors.grey.shade200)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: filterType,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
              isExpanded: true,
              onChanged: (v) {
                setState(() {
                  filterType = v!;
                  currentPage = 1;
                  applyFilters();
                });
              },
              items: ['Product Name', 'Person Name', 'Email']
                  .map<DropdownMenuItem<String>>((v) {
                return DropdownMenuItem(
                  value: v,
                  child: Row(
                    children: [
                      Icon(
                        v == 'Product Name'
                            ? Icons.shopping_bag
                            : (v == 'Person Name' ? Icons.person : Icons.email),
                        size: 14,
                        color: const Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 8),
                      Text(v),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200)),
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
          ),
        ),
        const SizedBox(width: 12),
        // Status Filter Dropdown
        Container(
          width: statusDropdownWidth,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedStatusFilter,
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
              style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
              isExpanded: true,
              onChanged: (v) {
                setState(() {
                  selectedStatusFilter = v!;
                  currentPage = 1;
                  applyFilters();
                });
              },
              items: ['All', 'Pending', 'Dispatched', 'Delivered', 'Complete']
                  .map<DropdownMenuItem<String>>((v) {
                return DropdownMenuItem(
                  value: v,
                  child: Row(
                    children: [
                      Icon(
                        v == 'All'
                            ? Icons.filter_list
                            : v == 'Complete'
                            ? Icons.done_all
                            : v == 'Delivered'
                            ? Icons.local_shipping
                            : v == 'Dispatched'
                            ? Icons.send
                            : Icons.hourglass_empty,
                        size: 14,
                        color: v == 'All' ? Colors.grey : getStatusColor(v),
                      ),
                      const SizedBox(width: 8),
                      Text(v),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildExportIcons(),
        const SizedBox(width: 12),
        Text(
          "Total: ${filteredEnquiries.length}",
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: resetFilters,
          icon: const Icon(Icons.refresh),
          color: Colors.red,
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
            onTap: exportExcel,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Image.asset("assets/icon/xls.png", height: 20, width: 20),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "PDF",
          child: InkWell(
            onTap: exportPDF,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Image.asset("assets/icon/pdf.png", height: 20, width: 20),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "DOC",
          child: InkWell(
            onTap: exportDOC,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Image.asset("assets/icon/doc.png", height: 20, width: 20),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPaginationWidgets(bool isMobile) {
    if (filteredEnquiries.isEmpty) return [];
    final List<Widget> pageWidgets = [];

    final showEntriesRow = Row(
      mainAxisAlignment: isMobile ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        const Text("Show "),
        DropdownButton<int>(
          value: itemsPerPage,
          items: rowsPerPageOptions
              .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
              .toList(),
          onChanged: changeItemsPerPage,
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down),
        ),
        const Text(" entries"),
        const SizedBox(width: 12),
        Text(
          "Showing ${(currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filteredEnquiries.length ? filteredEnquiries.length : currentPage * itemsPerPage} of ${filteredEnquiries.length}",
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );

    final List<Widget> rightChildren = [];
    rightChildren.add(_pageButton(Icons.chevron_left, currentPage > 1 ? previousPage : null));
    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        rightChildren.add(_pageNumber(i));
      }
    } else if (currentPage <= 3) {
      for (int i = 1; i <= 4; i++) {
        rightChildren.add(_pageNumber(i));
      }
      rightChildren.add(const Text("..."));
      rightChildren.add(_pageNumber(totalPages));
    } else if (currentPage >= totalPages - 2) {
      rightChildren.add(_pageNumber(1));
      rightChildren.add(const Text("..."));
      for (int i = totalPages - 3; i <= totalPages; i++) {
        rightChildren.add(_pageNumber(i));
      }
    } else {
      rightChildren.add(_pageNumber(1));
      rightChildren.add(const Text("..."));
      rightChildren.add(_pageNumber(currentPage - 1));
      rightChildren.add(_pageNumber(currentPage));
      rightChildren.add(_pageNumber(currentPage + 1));
      rightChildren.add(const Text("..."));
      rightChildren.add(_pageNumber(totalPages));
    }
    rightChildren.add(_pageButton(Icons.chevron_right, currentPage < totalPages ? nextPage : null));
    final paginationRow = Row(
      mainAxisAlignment: isMobile ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: rightChildren,
    );

    if (isMobile) {
      pageWidgets.add(showEntriesRow);
      pageWidgets.add(const SizedBox(height: 8));
      pageWidgets.add(paginationRow);
    } else {
      pageWidgets.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [showEntriesRow, paginationRow],
      ));
    }
    return pageWidgets;
  }

  Widget _buildPagination() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final widgets = _buildPaginationWidgets(isMobile);
    if (widgets.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widgets,
        ),
      ),
    );
  }

  Widget _pageButton(IconData icon, VoidCallback? onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(6)),
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: onTap,
        color: onTap != null ? const Color(0xFF6366F1) : Colors.grey,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
    );
  }

  Widget _pageNumber(int pageNum) {
    final isSelected = currentPage == pageNum;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(6)),
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
                fontSize: 11),
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
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Column(
      children: [
        _buildFilterRow(isMobile),
        const SizedBox(height: 8),
        Expanded(
          child: Column(
            children: [
              // Header Table
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
                    columnWidths: columnWidths,
                    children: [
                      TableRow(
                        children: headerLabels
                            .map((l) => Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Text(
                            l,
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
              // Data Table
              Expanded(
                child: filteredEnquiries.isEmpty
                    ? const Center(child: Text("No approved enquiries found"))
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
                      children: List.generate(paginatedEnquiries.length, (i) {
                        final e = paginatedEnquiries[i];
                        final int srNo = filteredEnquiries.length - ((currentPage - 1) * itemsPerPage + i);
                        final status = getDeliveryStatus(e);
                        final statusColor = getStatusColor(status);

                        return TableRow(
                          decoration: BoxDecoration(
                            color: i % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC),
                          ),
                          children: [
                            // Action Column - View button
                            GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: Container(
                                height: 42,
                                alignment: Alignment.center,
                                child: IconButton(
                                  icon: const Icon(Icons.visibility, color: Color(0xFF4158D0), size: 18),
                                  onPressed: () => _showDetailsPopup(e),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                ),
                              ),
                            ),
                            // SR No
                            GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(srNo.toString()),
                            ),
                            // Paid Status
                            GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: Container(
                                height: 42,
                                padding: const EdgeInsets.all(2),
                                alignment: Alignment.center,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: e.isPaid ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: e.isPaid ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        e.isPaid ? Icons.paid : Icons.currency_rupee,
                                        size: 14,
                                        color: e.isPaid ? Colors.green : Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        e.isPaid ? "Paid" : "Unpaid",
                                        style: TextStyle(
                                          color: e.isPaid ? Colors.green : Colors.red,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Status Column (Delivery Status)
                            GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: Container(
                                height: 42,
                                padding: const EdgeInsets.all(2),
                                alignment: Alignment.center,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: statusColor.withOpacity(0.5)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        status == 'Complete'
                                            ? Icons.done_all
                                            : status == 'Delivered'
                                            ? Icons.local_shipping
                                            : status == 'Dispatched'
                                            ? Icons.send
                                            : Icons.hourglass_empty,
                                        size: 12,
                                        color: statusColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        status,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Thumbnail
                            GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: Container(
                                height: 42,
                                alignment: Alignment.center,
                                child: e.productImage != null && e.productImage!.isNotEmpty
                                    ? Image.network(
                                  e.productImage!,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                )
                                    : const Icon(Icons.image_not_supported),
                              ),
                            ),
                            // Product Name
                            GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.productName ?? ''),
                            ),
                            // Company Name
                            GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.companyName ?? "-"),
                            ),
                            // Person Name
                            GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.personName ?? "-"),
                            ),
                            // Email
                            GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.email ?? "-"),
                            ),
                            // Contact
                            GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.contact ?? "-"),
                            ),
                            // Color
                            GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.selectedColor ?? "-"),
                            ),
                            // Size
                            GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.selectedSize ?? "-"),
                            ),
                            // Variant
                            GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.selectedVariant ?? "-"),
                            ),
                            // Demo Required
                            GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.demoRequired ?? "-"),
                            ),
                            // Demo Type
                            GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.demoType ?? "-"),
                            ),
                            // Sent to Company
                            GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.isSentToCompany ? "Yes" : "No"),
                            ),
                            // ✅ Referral Code (NEW)
                            GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.enquiryReferralCode ?? "-"),
                            ),
                            // Address
                            GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.address ?? "-"),
                            ),
                            // Pincode
                            GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.pincode ?? "-"),
                            ),
                            // Message
                            GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(e.message ?? "-"),
                            ),
                            // Created At
                            GestureDetector(
                              onTap: () => _showDetailsPopup(e),
                              child: _cell(formatDateTime(e.createdAt)),
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
    );
  }
}


class EnquiryTabsScreen extends StatefulWidget {
  const EnquiryTabsScreen({super.key});

  @override
  State<EnquiryTabsScreen> createState() => _EnquiryTabsScreenState();
}

class _EnquiryTabsScreenState extends State<EnquiryTabsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime? fromDate;
  DateTime? toDate;

  String? fromDateApi;
  String? toDateApi;
  List<PendingEnquiry> allPending = [];
  List<PendingEnquiry> sentPending = [];
  List<ApprovedEnquiry> approved = [];

  bool isLoadingPending = true;
  bool isLoadingApproved = true;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    toDate = DateTime.now();

    fromDate = DateTime(
      toDate!.year,
      toDate!.month - 2,
      toDate!.day,
    );

    fromDateApi = DateFormat('yyyy-MM-dd').format(fromDate!);
    toDateApi = DateFormat('yyyy-MM-dd').format(toDate!);

    _loadPendingData();
    _loadApprovedData();
  }

  Future<void> _loadPendingData() async {
    try {
      final response = await PendingEnquiryService.fetchPendingEnquiries(
        fromDate: fromDateApi,
        toDate: toDateApi,
      );
      if (mounted) {
        setState(() {
          // सर्व pending enquiries स्टोर करा
          allPending = response.data;

          // sentPending मध्ये फक्त isSentToCompany == true असलेले ठेवा
          sentPending = response.data.where((e) => e.isSentToCompany == true).toList();

          // allPending मध्ये फक्त isSentToCompany == false असलेले ठेवा
          allPending = response.data.where((e) => e.isSentToCompany == false).toList();

          isLoadingPending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingPending = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to load pending enquiries")));
      }
    }
  }

  Future<void> pickFromDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        fromDate = picked;
        fromDateApi = DateFormat('yyyy-MM-dd').format(picked);
        isLoadingPending = true; // Loading state set करा
      });
      await _loadPendingData(); // Data reload करा
    }
  }

  Future<void> pickToDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        toDate = picked;
        toDateApi = DateFormat('yyyy-MM-dd').format(picked);
        isLoadingPending = true;
      });
      await _loadPendingData();
    }
  }

  Future<void> _loadApprovedData() async {
    try {
      final response = await ApprovedEnquiryService.fetchApprovedEnquiries();
      if (mounted) {
        setState(() {
          approved = response.data;
          isLoadingApproved = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingApproved = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to load approved enquiries")));
      }
    }
  }

  Future<void> _handleSend(PendingEnquiry enquiry) async {
    try {
      final response = await EnquiryListService.sendEnquiryToCompany(enquiry.id);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: Colors.green));

      setState(() {
        // allPending मधून remove करा (कारण ती आता sent झाली)
        allPending.removeWhere((e) => e.id == enquiry.id);

        // sentPending मध्ये add करा
        final sentEnquiry = enquiry.copyWith(isSentToCompany: true);
        sentPending.add(sentEnquiry);

        // दोन्ही lists sort करा
        allPending.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        sentPending.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  // ============ NEW: Date Filter Widget ============
  Widget _buildDateFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: pickFromDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Color(0xFF4158D0)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        fromDate != null
                            ? DateFormat('dd/MM/yyyy').format(fromDate!)
                            : 'From Date',
                        style: TextStyle(
                          color: fromDate != null ? Colors.black : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.arrow_forward, color: Color(0xFF4158D0), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: pickToDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Color(0xFF4158D0)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        toDate != null
                            ? DateFormat('dd/MM/yyyy').format(toDate!)
                            : 'To Date',
                        style: TextStyle(
                          color: toDate != null ? Colors.black : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () async {
              setState(() {
                toDate = DateTime.now();
                fromDate = DateTime(
                  toDate!.year,
                  toDate!.month - 2,
                  toDate!.day,
                );
                fromDateApi = DateFormat('yyyy-MM-dd').format(fromDate!);
                toDateApi = DateFormat('yyyy-MM-dd').format(toDate!);
                isLoadingPending = true;
              });
              await _loadPendingData();
            },
            icon: const Icon(Icons.refresh, color: Color(0xFF4158D0)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController, // हे error देईल कारण _tabController const नाही
          indicatorColor: const Color(0xFF4158D0),
          labelColor: const Color(0xFF4158D0),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "ALL Enquiry"),
            Tab(text: "Send Enquiry"),
            Tab(text: "Approved Enquiries"),
          ],
        ),
        title: const Text("Enquiry Management",
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // ============ DATE FILTER ============
          _buildDateFilter(),
          const Divider(
            height: 2,
            thickness: 2,
            color: Color(0xFF4158D0), // Premium color
            indent: 16,
            endIndent: 16,
          ),

          // ============ TAB BAR VIEW ============
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // ✅ ALL Enquiry Tab - Send Button दिसेल
                isLoadingPending
                    ? const Center(child: CircularProgressIndicator())
                    : PendingEnquiryTable(
                    initialData: allPending,
                    onSend: _handleSend,
                    showSendButton: true),  // ✅ true

                // ✅ Send Enquiry Tab - Send Button लपवा
                isLoadingPending
                    ? const Center(child: CircularProgressIndicator())
                    : PendingEnquiryTable(
                    initialData: sentPending,
                    onSend: _handleSend,
                    showSendButton: false), // ✅ false करा (हे बदला)

                // ✅ Approved Enquiries Tab
                isLoadingApproved
                    ? const Center(child: CircularProgressIndicator())
                    : ApprovedEnquiryTable(initialData: approved),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}