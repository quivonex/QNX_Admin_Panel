// lib/screens/marketing_head/referred_companies_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;
import '../../api/marketing_service.dart';
import '../../models/marketing_head/referred_companies_model.dart';

class ReferredCompaniesScreen extends StatefulWidget {
  const ReferredCompaniesScreen({super.key});

  @override
  State<ReferredCompaniesScreen> createState() => _ReferredCompaniesScreenState();
}

class _ReferredCompaniesScreenState extends State<ReferredCompaniesScreen> {
  final ReferredCompaniesService _service = ReferredCompaniesService();
  late Future<ReferredCompaniesResponse> _futureData;

  List<_CompanyWithPartner> allCompanies = [];
  List<_CompanyWithPartner> filteredCompanies = [];
  List<_CompanyWithPartner> paginatedCompanies = [];

  String searchQuery = '';
  String filterType = 'Company Name';
  final TextEditingController _searchController = TextEditingController();

  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(60),   // Logo
    1: FixedColumnWidth(180),  // Company Name
    2: FixedColumnWidth(150),  // Owner
    3: FixedColumnWidth(170),  // Email
    4: FixedColumnWidth(100),  // Phone
    5: FixedColumnWidth(100),  // State
    6: FixedColumnWidth(100),  // Created
    7: FixedColumnWidth(150),  // Partner
    8: FixedColumnWidth(70),   // Actions
  };

  final List<String> headerLabels = [
    "Logo", "Company Name", "Owner", "Email", "Phone", "State", "Created", "Partner", "Actions"
  ];

  @override
  void initState() {
    super.initState();
    _futureData = _service.fetchReferredCompanies().then((response) {
      if (mounted) {
        setState(() {
          allCompanies = [];
          for (var partner in response.data) {
            for (var company in partner.companies) {
              allCompanies.add(_CompanyWithPartner(
                company: company,
                partnerId: partner.partnerId,
                partnerName: partner.partnerName,
                partnerEmail: partner.partnerEmail,
                partnerMobile: partner.partnerMobile,
                partnerReferralCode: partner.partnerReferralCode,
              ));
            }
          }
          _applyFilters();
        });
      }
      return response;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    if (searchQuery.isEmpty) {
      filteredCompanies = List.from(allCompanies);
    } else {
      final query = searchQuery.toLowerCase();
      filteredCompanies = allCompanies.where((c) {
        switch (filterType) {
          case 'Company Name':
            return c.company.name.toLowerCase().contains(query);
          case 'Owner':
            return c.company.ownerName.toLowerCase().contains(query);
          case 'Email':
            return c.company.email.toLowerCase().contains(query);
          case 'Phone':
            return c.company.phoneNumber.contains(query);
          case 'Partner Name':
            return c.partnerName.toLowerCase().contains(query);
          default:
            return false;
        }
      }).toList();
    }
    _applyPagination();
  }

  void _applyPagination() {
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

  void _nextPage() {
    if (currentPage < totalPages) {
      setState(() { currentPage++; _applyPagination(); });
    }
  }

  void _previousPage() {
    if (currentPage > 1) {
      setState(() { currentPage--; _applyPagination(); });
    }
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() { currentPage = page; _applyPagination(); });
    }
  }

  void _changeItemsPerPage(int? value) {
    if (value != null) {
      setState(() {
        itemsPerPage = value;
        currentPage = 1;
        _applyPagination();
      });
    }
  }

  void _resetFilters() {
    setState(() {
      searchQuery = '';
      filterType = 'Company Name';
      _searchController.clear();
      currentPage = 1;
      _applyFilters();
    });
  }

  void _exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['ReferredCompanies'];
    sheet.appendRow([
      "Company ID", "Company Name", "Owner", "Email", "Phone", "State", "Created At",
      "Partner Name", "Partner Email", "Partner Mobile"
    ]);
    for (var c in filteredCompanies) {
      sheet.appendRow([
        c.company.id,
        c.company.name,
        c.company.ownerName,
        c.company.email,
        c.company.phoneNumber,
        c.company.state ?? '',
        c.company.createdAt?.substring(0, 10) ?? '',
        c.partnerName,
        c.partnerEmail,
        c.partnerMobile,
      ]);
    }
    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "referred_companies.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> _exportPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: ["ID", "Name", "Owner", "Email", "Phone", "State", "Created", "Partner"],
            data: filteredCompanies.map((c) => [
              c.company.id.toString(),
              c.company.name,
              c.company.ownerName,
              c.company.email,
              c.company.phoneNumber,
              c.company.state ?? '',
              c.company.createdAt?.substring(0, 10) ?? '',
              c.partnerName,
            ]).toList(),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void _exportDOC() {
    final content = StringBuffer();
    content.writeln("Referred Companies\n");
    content.writeln("=" * 50);
    for (var c in filteredCompanies) {
      content.writeln("Company ID: ${c.company.id}");
      content.writeln("Company Name: ${c.company.name}");
      content.writeln("Owner: ${c.company.ownerName}");
      content.writeln("Email: ${c.company.email}");
      content.writeln("Phone: ${c.company.phoneNumber}");
      content.writeln("State: ${c.company.state ?? ''}");
      content.writeln("Created: ${c.company.createdAt?.substring(0, 10) ?? ''}");
      content.writeln("Partner: ${c.partnerName} (${c.partnerEmail})");
      content.writeln("-" * 30);
    }
    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "referred_companies.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Widget _buildFilterSection(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 850;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: isCompact
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              Flexible(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        "Total Companies: ${filteredCompanies.length}",
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.refresh),
                      color: Colors.red,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
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
          Text("Total Companies: ${filteredCompanies.length}"),
          IconButton(onPressed: _resetFilters, icon: const Icon(Icons.refresh), color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      width: 150,
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
              _applyFilters();
            });
          },
          items: ['Company Name', 'Owner', 'Email', 'Phone', 'Partner Name']
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
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, size: 16),
            onPressed: () {
              _searchController.clear();
              setState(() {
                searchQuery = '';
                currentPage = 1;
                _applyFilters();
              });
            },
          )
              : null,
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
            currentPage = 1;
            _applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildExportIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: "Export Excel",
          child: InkWell(
            onTap: _exportExcel,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Image.asset("assets/icon/xls.png", height: 20, width: 20,
                  errorBuilder: (_, __, ___) => const Icon(Icons.table_chart, size: 20, color: Colors.green)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "Export PDF",
          child: InkWell(
            onTap: _exportPDF,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Image.asset("assets/icon/pdf.png", height: 20, width: 20,
                  errorBuilder: (_, __, ___) => const Icon(Icons.picture_as_pdf, size: 20, color: Colors.red)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "Export DOC",
          child: InkWell(
            onTap: _exportDOC,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Image.asset("assets/icon/doc.png", height: 20, width: 20,
                  errorBuilder: (_, __, ___) => const Icon(Icons.description, size: 20, color: Colors.blue)),
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

  Widget _tableCell(String text, {bool isBold = false}) {
    return Container(
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
    );
  }

  Widget _buildLogo(String? url) {
    if (url == null || url.isEmpty) {
      return const Icon(Icons.business, size: 30);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(width: 40, height: 40, color: Colors.grey.shade200),
        errorWidget: (_, __, ___) => const Icon(Icons.broken_image, size: 30),
      ),
    );
  }

  // --- 🆕 अपडेटेड मॉडर्न आणि क्लीन पॉपअप डिझाईन ---
  void _showCompanyDetailsPopup(_CompanyWithPartner data) {
    final company = data.company;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            double dialogWidth = constraints.maxWidth * 0.95;
            if (constraints.maxWidth > 600) dialogWidth = 550;
            if (constraints.maxWidth > 800) dialogWidth = 650;

            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- HEADER SECTION (Gradient Profile) ---
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFFEC4899)],
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
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: company.logo != null && company.logo!.isNotEmpty
                                ? CachedNetworkImage(
                              imageUrl: company.logo!,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => const Icon(Icons.business, color: Color(0xFF8B5CF6), size: 36),
                            )
                                : Container(
                              width: 52,
                              height: 52,
                              color: Colors.white,
                              alignment: Alignment.center,
                              child: Text(
                                company.name.substring(0, company.name.length >= 2 ? 2 : 1).toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6), fontSize: 20),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                company.name,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                company.ownerName,
                                style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.cancel, color: Colors.white70, size: 26),
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          splashColor: Colors.transparent,
                        ),
                      ],
                    ),
                  ),

                  // --- BODY SECTION (Scrollable Cards) ---
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Partner Information
                          _buildSectionCard(
                            title: "Referred By (Partner)",
                            icon: Icons.person_rounded,
                            context: context,
                            children: [
                              _buildGridRow("Partner Name", data.partnerName, context),
                              _buildGridRow("Partner Email", data.partnerEmail, context),
                              _buildGridRow("Partner Mobile", data.partnerMobile, context),
                              _buildGridRow("Referral Code", data.partnerReferralCode, context, isMono: true),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 2. Company Information
                          _buildSectionCard(
                            title: "Company Information",
                            icon: Icons.info_rounded,
                            context: context,
                            children: [
                              _buildGridRow("ID", company.id.toString(), context),
                              _buildGridRow("Name", company.name, context),
                              _buildGridRow("Owner", company.ownerName, context),
                              _buildGridRow("Slogan", company.companySlogan ?? 'N/A', context),
                              _buildGridRow("Short Desc", company.shortDescription ?? 'N/A', context, isLong: true),
                              _buildGridRow("Long Desc", company.longDescription ?? 'N/A', context, isLong: true),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 3. Contact Details
                          _buildSectionCard(
                            title: "Contact Details",
                            icon: Icons.call_rounded,
                            context: context,
                            children: [
                              _buildGridRow("Email", company.email, context),
                              _buildGridRow("Phone", company.phoneNumber, context),
                              _buildGridRow("WhatsApp", company.whatsappNo ?? 'N/A', context),
                              if (company.websiteUrl != null && company.websiteUrl!.isNotEmpty)
                                _buildLinkRow("Website", company.websiteUrl!, context),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 4. Address Details
                          _buildSectionCard(
                            title: "Address Details",
                            icon: Icons.location_on_rounded,
                            context: context,
                            children: [
                              _buildGridRow("Address", company.address, context, isLong: true),
                              _buildGridRow("State", company.state ?? 'N/A', context),
                              _buildGridRow("District", company.district ?? 'N/A', context),
                              _buildGridRow("Taluka", company.taluka ?? 'N/A', context),
                              _buildGridRow("Village", company.village ?? 'N/A', context),
                              _buildGridRow("Pincode", company.pincode ?? 'N/A', context),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 5. Social & Links Buttons
                          _buildSectionCard(
                            title: "Social & Links",
                            icon: Icons.public_rounded,
                            context: context,
                            children: [
                              if ((company.facebookUrl == null || company.facebookUrl!.isEmpty) &&
                                  (company.linkedinUrl == null || company.linkedinUrl!.isEmpty) &&
                                  (company.instagramUrl == null || company.instagramUrl!.isEmpty) &&
                                  (company.youtubeUrl == null || company.youtubeUrl!.isEmpty))
                                _buildGridRow("Links", "No Social Links Available", context)
                              else
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      if (company.facebookUrl != null && company.facebookUrl!.isNotEmpty)
                                        _buildSocialButton("Facebook", company.facebookUrl!, Colors.blue.shade700, Icons.facebook),
                                      if (company.linkedinUrl != null && company.linkedinUrl!.isNotEmpty)
                                        _buildSocialButton("LinkedIn", company.linkedinUrl!, Colors.blue.shade900, Icons.link),
                                      if (company.instagramUrl != null && company.instagramUrl!.isNotEmpty)
                                        _buildSocialButton("Instagram", company.instagramUrl!, Colors.pink.shade600, Icons.camera_alt),
                                      if (company.youtubeUrl != null && company.youtubeUrl!.isNotEmpty)
                                        _buildSocialButton("YouTube", company.youtubeUrl!, Colors.red.shade700, Icons.play_arrow),
                                    ],
                                  ),
                                )
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 6. Registration Details
                          _buildSectionCard(
                            title: "Registration Details",
                            icon: Icons.gavel_rounded,
                            context: context,
                            children: [
                              _buildGridRow("GST Number", company.gstNumber ?? 'N/A', context, isMono: true),
                              _buildGridRow("Registration No", company.registrationNo ?? 'N/A', context, isMono: true),
                              _buildGridRow("Company PAN", company.companyPanNo ?? 'N/A', context, isMono: true),
                              _buildGridRow("IAN No", company.iANNo ?? 'N/A', context, isMono: true),
                              _buildGridRow("Farm Reg Year", company.farmRegistrationYear?.toString() ?? 'N/A', context),
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

  // --- HELPERS FOR MODAL CARDS ---
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    required BuildContext context,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF8B5CF6)),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
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

  Widget _buildGridRow(String label, String value, BuildContext context, {bool isLong = false, bool isMono = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                fontFamily: isMono ? 'monospace' : null,
                height: 1.3,
              ),
              maxLines: isLong ? 5 : 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkRow(String label, String url, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _launchUrl(url),
              child: Text(
                url,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton(String name, String url, Color color, IconData icon) {
    return InkWell(
      onTap: () => _launchUrl(url),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              name,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (filteredCompanies.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 650;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
          child: isCompact
              ? Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text("Show ", style: TextStyle(fontSize: 11)),
                      Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: itemsPerPage,
                            style: const TextStyle(fontSize: 11, color: Colors.black),
                            items: rowsPerPageOptions.map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
                            onChanged: _changeItemsPerPage,
                          ),
                        ),
                      ),
                      const Text(" entries", style: TextStyle(fontSize: 11)),
                    ],
                  ),
                  Text(
                    "Total: ${filteredCompanies.length}",
                    style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _compactPageButton(icon: Icons.chevron_left, onTap: currentPage > 1 ? _previousPage : null),
                  ..._buildPageNumbers(),
                  _compactPageButton(icon: Icons.chevron_right, onTap: currentPage < totalPages ? _nextPage : null),
                ],
              ),
            ],
          )
              : Row(
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
                    child: DropdownButton<int>(
                      value: itemsPerPage,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.arrow_drop_down),
                      items: rowsPerPageOptions.map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
                      onChanged: _changeItemsPerPage,
                    ),
                  ),
                  const Text(" entries"),
                  const SizedBox(width: 16),
                  Text(
                    "Showing ${(currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filteredCompanies.length ? filteredCompanies.length : currentPage * itemsPerPage} of ${filteredCompanies.length}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              Row(
                children: [
                  _compactPageButton(icon: Icons.chevron_left, onTap: currentPage > 1 ? _previousPage : null),
                  ..._buildPageNumbers(),
                  _compactPageButton(icon: Icons.chevron_right, onTap: currentPage < totalPages ? _nextPage : null),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildPageNumbers() {
    if (totalPages <= 5) {
      return List.generate(totalPages, (index) => _compactPageNumber(index + 1));
    } else if (currentPage <= 3) {
      return [
        ...List.generate(4, (index) => _compactPageNumber(index + 1)),
        const Text("..."),
        _compactPageNumber(totalPages),
      ];
    } else if (currentPage >= totalPages - 2) {
      return [
        _compactPageNumber(1),
        const Text("..."),
        ...List.generate(4, (index) => _compactPageNumber(totalPages - 3 + index)),
      ];
    } else {
      return [
        _compactPageNumber(1),
        const Text("..."),
        _compactPageNumber(currentPage - 1),
        _compactPageNumber(currentPage),
        _compactPageNumber(currentPage + 1),
        const Text("..."),
        _compactPageNumber(totalPages),
      ];
    }
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
        onTap: () => _goToPage(pageNum),
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

  void _launchUrl(String url) {
    if (url.isNotEmpty && url != 'N/A') {
      html.window.open(url, '_blank');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FA),
      child: FutureBuilder<ReferredCompaniesResponse>(
        future: _futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _futureData = _service.fetchReferredCompanies();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || allCompanies.isEmpty) {
            return const Center(child: Text('No referred companies found.'));
          }

          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _buildFilterSection(context),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: 1050,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
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
                          Expanded(
                            child: filteredCompanies.isEmpty
                                ? const Center(child: Text("No companies match your search"))
                                : SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: Table(
                                border: TableBorder.all(color: Colors.grey.shade300),
                                columnWidths: columnWidths,
                                children: paginatedCompanies.map((companyWithPartner) {
                                  final company = companyWithPartner.company;
                                  final bool isEven = paginatedCompanies.indexOf(companyWithPartner) % 2 == 0;
                                  return TableRow(
                                    decoration: BoxDecoration(
                                      color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                                    ),
                                    children: [
                                      Container(
                                        height: 42,
                                        alignment: Alignment.center,
                                        child: _buildLogo(company.logo),
                                      ),
                                      InkWell(
                                        onTap: () => _showCompanyDetailsPopup(companyWithPartner),
                                        child: _tableCell(company.name, isBold: true),
                                      ),
                                      InkWell(
                                        onTap: () => _showCompanyDetailsPopup(companyWithPartner),
                                        child: _tableCell(company.ownerName),
                                      ),
                                      InkWell(
                                        onTap: () => _showCompanyDetailsPopup(companyWithPartner),
                                        child: _tableCell(company.email),
                                      ),
                                      InkWell(
                                        onTap: () => _showCompanyDetailsPopup(companyWithPartner),
                                        child: _tableCell(company.phoneNumber),
                                      ),
                                      InkWell(
                                        onTap: () => _showCompanyDetailsPopup(companyWithPartner),
                                        child: _tableCell(company.state ?? ''),
                                      ),
                                      InkWell(
                                        onTap: () => _showCompanyDetailsPopup(companyWithPartner),
                                        child: _tableCell(company.createdAt?.substring(0, 10) ?? ''),
                                      ),
                                      InkWell(
                                        onTap: () => _showCompanyDetailsPopup(companyWithPartner),
                                        child: _tableCell(companyWithPartner.partnerName),
                                      ),
                                      Container(
                                        alignment: Alignment.center,
                                        child: IconButton(
                                          icon: const Icon(Icons.visibility, size: 18, color: Color(0xFF4158D0)),
                                          onPressed: () => _showCompanyDetailsPopup(companyWithPartner),
                                          tooltip: 'View Details',
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildPagination(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CompanyWithPartner {
  final CompanyData company;
  final int partnerId;
  final String partnerName;
  final String partnerEmail;
  final String partnerMobile;
  final String partnerReferralCode;

  _CompanyWithPartner({
    required this.company,
    required this.partnerId,
    required this.partnerName,
    required this.partnerEmail,
    required this.partnerMobile,
    required this.partnerReferralCode,
  });
}