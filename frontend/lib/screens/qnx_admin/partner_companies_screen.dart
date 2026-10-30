import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import '../../api/api_service.dart';
import '../../models/qnx_admin/partner_company_model.dart';

class PartnerCompaniesScreen extends StatefulWidget {
  final int partnerId;
  final String partnerName;

  const PartnerCompaniesScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
  });

  @override
  State<PartnerCompaniesScreen> createState() => _PartnerCompaniesScreenState();
}

class _PartnerCompaniesScreenState extends State<PartnerCompaniesScreen> {
  List<PartnerCompany> allCompanies = [];
  List<PartnerCompany> filteredCompanies = [];
  List<PartnerCompany> paginatedCompanies = [];

  bool isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String filterType = 'Company Name'; // Company Name, Owner Name, Email

  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(50),   // ID
    1: FixedColumnWidth(60),   // Logo
    2: FixedColumnWidth(180),  // Company Name
    3: FixedColumnWidth(150),  // Owner Name
    4: FixedColumnWidth(200),  // Email
    5: FixedColumnWidth(110),  // Phone
    6: FixedColumnWidth(200),  // Address
    7: FixedColumnWidth(80),   // Pincode
    8: FixedColumnWidth(100),  // Created At
    9: FixedColumnWidth(70),   // Actions
  };

  final List<String> headerLabels = [
    "ID", "Logo", "Company Name", "Owner Name", "Email", "Phone",
    "Address", "Pincode", "Created", "Actions"
  ];

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
      final response = await PartnerCompaniesService.fetchPartnerCompanies(widget.partnerId);
      if (mounted) {
        setState(() {
          allCompanies = response.data;
          applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load companies: $e")),
        );
      }
    }
  }

  void applyFilters() {
    if (searchQuery.isEmpty) {
      filteredCompanies = List.from(allCompanies);
    } else {
      final query = searchQuery.toLowerCase();
      filteredCompanies = allCompanies.where((c) {
        switch (filterType) {
          case 'Company Name':
            return c.name.toLowerCase().contains(query);
          case 'Owner Name':
            return c.ownerName.toLowerCase().contains(query);
          case 'Email':
            return c.email.toLowerCase().contains(query);
          default:
            return false;
        }
      }).toList();
    }
    applyPagination();
  }

  void applyPagination() {
    if (filteredCompanies.isEmpty) {
      paginatedCompanies = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }
    totalPages = (filteredCompanies.length / itemsPerPage).ceil();
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    if (end > filteredCompanies.length) end = filteredCompanies.length;
    paginatedCompanies = filteredCompanies.sublist(start, end);
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
      filterType = 'Company Name';
      _searchController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  String formatDateTime(String dateStr) {
    try {
      return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  // ---------- Export ----------
  void exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['Partner Companies'];
    sheet.appendRow(["ID", "Company Name", "Owner Name", "Email", "Phone", "Address", "Pincode", "Created At"]);
    for (var c in filteredCompanies) {
      sheet.appendRow([
        c.id,
        c.name,
        c.ownerName,
        c.email,
        c.phoneNumber,
        c.address,
        c.pincode,
        formatDateTime(c.createdAt),
      ]);
    }
    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "partner_companies_${widget.partnerId}.xlsx")
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
            headers: ["ID", "Company Name", "Owner Name", "Email", "Phone", "Address", "Pincode", "Created"],
            data: filteredCompanies.map((c) => [
              c.id.toString(),
              c.name,
              c.ownerName,
              c.email,
              c.phoneNumber,
              c.address,
              c.pincode,
              formatDateTime(c.createdAt),
            ]).toList(),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void exportDOC() {
    final content = StringBuffer();
    content.writeln("Partner Companies for ${widget.partnerName}\n");
    content.writeln("=" * 50);
    for (var c in filteredCompanies) {
      content.writeln("ID: ${c.id}");
      content.writeln("Company: ${c.name}");
      content.writeln("Owner: ${c.ownerName}");
      content.writeln("Email: ${c.email}");
      content.writeln("Phone: ${c.phoneNumber}");
      content.writeln("Address: ${c.address}");
      content.writeln("Pincode: ${c.pincode}");
      content.writeln("Created: ${formatDateTime(c.createdAt)}");
      content.writeln("-" * 30);
    }
    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "partner_companies_${widget.partnerId}.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ---------- Logo builder ----------
  Widget _buildLogo(String? url, double size) {
    if (url == null || url.isEmpty) {
      return Container(
        width: size,
        height: size,
        color: Colors.grey[200],
        child: const Icon(Icons.business, size: 20, color: Colors.grey),
      );
    }
    return GestureDetector(
      onTap: () => _showFullImageDialog(url),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, size: 20),
          ),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(width: size, height: size, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
          },
        ),
      ),
    );
  }

  void _showFullImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Company Logo", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Company Details Popup (Dark sections) ----------
  void showCompanyPopup(PartnerCompany company) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildLogo(company.logo, 40),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  company.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  company.ownerName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, color: Colors.white),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 24,
                          ),
                        ],
                      ),
                    ),
                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDarkSection(
                              context,
                              title: 'Basic Information',
                              icon: Icons.business_outlined,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildInfoChip("ID", company.id.toString(), context),
                                  _buildInfoChip("Status", company.isActive ? "Active" : "Inactive", context, isHighlight: true),
                                  _buildInfoChip("Payment Status", company.paymentStatus ?? "-", context),
                                  _buildInfoChip("Referral Code", company.referralCode ?? "-", context),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildDarkSection(
                              context,
                              title: 'Contact Details',
                              icon: Icons.contact_phone_outlined,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildInfoChip("Owner", company.ownerName, context),
                                  _buildInfoChip("Email", company.email, context),
                                  _buildInfoChip("Phone", company.phoneNumber, context),
                                  _buildInfoChip("WhatsApp", company.whatsappNo ?? "-", context),
                                  if (company.multipleEmailIds.isNotEmpty)
                                    _buildInfoChip("Additional Emails", company.multipleEmailIds.join(", "), context, isLong: true),
                                  if (company.contacts.isNotEmpty)
                                    _buildInfoChip("Additional Contacts", company.contacts.join(", "), context, isLong: true),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildDarkSection(
                              context,
                              title: 'Location',
                              icon: Icons.location_on_outlined,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildInfoChip("Address", company.address, context, isLong: true),
                                  _buildInfoChip("State", company.state, context),
                                  _buildInfoChip("District", company.district, context),
                                  _buildInfoChip("Taluka", company.taluka, context),
                                  _buildInfoChip("Village", company.village, context),
                                  _buildInfoChip("Pincode", company.pincode, context),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildDarkSection(
                              context,
                              title: 'Company Details',
                              icon: Icons.info_outline,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (company.gstNumber != null) _buildInfoChip("GST", company.gstNumber!, context),
                                  if (company.companyPanNo != null) _buildInfoChip("PAN", company.companyPanNo!, context),
                                  if (company.registrationNo != null) _buildInfoChip("Registration No", company.registrationNo!, context),
                                  if (company.websiteUrl != null) _buildInfoChip("Website", company.websiteUrl!, context, isLong: true),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildDarkSection(
                              context,
                              title: 'Social Media',
                              icon: Icons.share_outlined,
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (company.facebookUrl != null) _buildInfoChip("Facebook", company.facebookUrl!, context, isLong: true),
                                  if (company.linkedinUrl != null) _buildInfoChip("LinkedIn", company.linkedinUrl!, context, isLong: true),
                                  if (company.instagramUrl != null) _buildInfoChip("Instagram", company.instagramUrl!, context, isLong: true),
                                  if (company.youtubeUrl != null) _buildInfoChip("YouTube", company.youtubeUrl!, context, isLong: true),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildDarkSection(
                              context,
                              title: 'Description',
                              icon: Icons.description_outlined,
                              child: Column(
                                children: [
                                  if (company.shortDescription != null)
                                    Text(company.shortDescription!, style: const TextStyle(fontSize: 13)),
                                  if (company.longDescription != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(company.longDescription!, style: const TextStyle(fontSize: 13)),
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

  Widget _buildDarkSection(BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildInfoChip(String label, String value, BuildContext context, {bool isHighlight = false, bool isLong = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      constraints: isLong ? BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.6) : null,
      decoration: BoxDecoration(
        color: isHighlight
            ? (isDark ? primaryColor.withOpacity(0.3) : primaryColor.withOpacity(0.1))
            : (isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(30),
        border: isHighlight ? Border.all(color: isDark ? primaryColor : primaryColor) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: isHighlight
                  ? (isDark ? primaryColor : primaryColor)
                  : (isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: isHighlight
                    ? (isDark ? primaryColor : primaryColor)
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
              maxLines: isLong ? 3 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------- UI ----------------------
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
                  Text("Total: ${filteredCompanies.length}"),
                  const SizedBox(width: 8),
                  IconButton(onPressed: resetFilters, icon: const Icon(Icons.refresh), color: Colors.red),
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
          Text("Total: ${filteredCompanies.length}"),
          IconButton(onPressed: resetFilters, icon: const Icon(Icons.refresh), color: Colors.red),
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
          items: ['Company Name', 'Owner Name', 'Email']
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
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Image.asset("assets/icon/xls.png", height: 20, width: 20, errorBuilder: (_, __, ___) => const Icon(Icons.table_chart, size: 20)),
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
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Image.asset("assets/icon/pdf.png", height: 20, width: 20, errorBuilder: (_, __, ___) => const Icon(Icons.picture_as_pdf, size: 20)),
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
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Image.asset("assets/icon/doc.png", height: 20, width: 20, errorBuilder: (_, __, ___) => const Icon(Icons.description, size: 20)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tableHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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
          style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 10),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (filteredCompanies.isEmpty) return const SizedBox.shrink();

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
            // Mobile
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
                        onChanged: (v) {
                          setState(() {
                            itemsPerPage = v!;
                            currentPage = 1;
                            applyPagination();
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
            // Desktop
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
                        onChanged: (v) {
                          setState(() {
                            itemsPerPage = v!;
                            currentPage = 1;
                            applyPagination();
                          });
                        },
                      ),
                    ),
                    const Text(" entries", style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 8),
                    Text(
                      "Showing ${(currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filteredCompanies.length ? filteredCompanies.length : currentPage * itemsPerPage} of ${filteredCompanies.length}",
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
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
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
        title: Text("Companies referred by ${widget.partnerName}"),
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
                        children: [TableRow(children: headerLabels.map((l) => _tableHeader(l)).toList())],
                      ),
                    ),
                  ),
                  // Scrollable rows
                  Expanded(
                    child: filteredCompanies.isEmpty
                        ? const Center(child: Text("No companies found"))
                        : SingleChildScrollView(
                      controller: _verticalController,
                      child: SingleChildScrollView(
                        controller: _rowsHorizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          border: TableBorder.all(color: Colors.grey.shade300),
                          columnWidths: columnWidths,
                          children: paginatedCompanies.map((company) {
                            final bool isEven = paginatedCompanies.indexOf(company) % 2 == 0;
                            return TableRow(
                              decoration: BoxDecoration(color: isEven ? Colors.white : const Color(0xFFF8FAFC)),
                              children: [
                                _tableCell(company.id.toString(), onTap: () => showCompanyPopup(company)),
                                GestureDetector(
                                  onTap: () => _showFullImageDialog(company.logo ?? ''),
                                  child: Container(
                                    height: 40,
                                    width: 40,
                                    alignment: Alignment.center,
                                    child: _buildLogo(company.logo, 35),
                                  ),
                                ),
                                _tableCell(company.name, onTap: () => showCompanyPopup(company)),
                                _tableCell(company.ownerName, onTap: () => showCompanyPopup(company)),
                                _tableCell(company.email, onTap: () => showCompanyPopup(company)),
                                _tableCell(company.phoneNumber, onTap: () => showCompanyPopup(company)),
                                _tableCell(company.address, onTap: () => showCompanyPopup(company)),
                                _tableCell(company.pincode, onTap: () => showCompanyPopup(company)),
                                _tableCell(formatDateTime(company.createdAt), onTap: () => showCompanyPopup(company)),
                                IconButton(
                                  icon: const Icon(Icons.visibility, color: Color(0xFF4158D0), size: 18),
                                  onPressed: () => showCompanyPopup(company),
                                  tooltip: 'View Details',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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