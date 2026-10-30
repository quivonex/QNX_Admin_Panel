// lib/screens/marketing_partner/my_referred_companies_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;
import '../../api/marketing_service.dart';
import '../../models/marketing_partner/my_referred_companies_model.dart';

class MyReferredCompaniesScreen extends StatefulWidget {
  const MyReferredCompaniesScreen({super.key});

  @override
  State<MyReferredCompaniesScreen> createState() => _MyReferredCompaniesScreenState();
}

class _MyReferredCompaniesScreenState extends State<MyReferredCompaniesScreen> {
  final MyReferredCompaniesService _service = MyReferredCompaniesService();
  late Future<MyReferredCompaniesResponse> _futureData;

  List<MyReferredCompany> allCompanies = [];
  List<MyReferredCompany> filteredCompanies = [];
  List<MyReferredCompany> paginatedCompanies = [];

  String searchQuery = '';
  String filterType = 'Company Name'; // Company Name, Owner, Email, Phone
  final TextEditingController _searchController = TextEditingController();

  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  // 1. "Sr. No." header labels च्या आधी ॲड केला
  final List<String> headerLabels = [
    "Sr. No.", "Logo", "Company Name", "Owner", "Email", "Phone", "State", "Created", "Actions"
  ];

  @override
  void initState() {
    super.initState();
    _futureData = _service.fetchMyCompanies().then((response) {
      if (mounted) {
        setState(() {
          allCompanies = response.data;
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
            return c.name.toLowerCase().contains(query);
          case 'Owner':
            return c.ownerName.toLowerCase().contains(query);
          case 'Email':
            return c.email.toLowerCase().contains(query);
          case 'Phone':
            return c.phoneNumber.contains(query);
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

  // Export functions
  void _exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['MyReferredCompanies'];
    sheet.appendRow([
      "Company ID", "Company Name", "Owner", "Email", "Phone", "State", "Created At",
    ]);
    for (var c in filteredCompanies) {
      sheet.appendRow([
        c.id,
        c.name,
        c.ownerName,
        c.email,
        c.phoneNumber,
        c.state ?? '',
        c.createdAt?.substring(0, 10) ?? '',
      ]);
    }
    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "my_referred_companies.xlsx")
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
            headers: ["ID", "Name", "Owner", "Email", "Phone", "State", "Created"],
            data: filteredCompanies.map((c) => [
              c.id.toString(),
              c.name,
              c.ownerName,
              c.email,
              c.phoneNumber,
              c.state ?? '',
              c.createdAt?.substring(0, 10) ?? ''
            ]).toList(),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void _exportDOC() {
    final content = StringBuffer();
    content.writeln("My Referred Companies\n");
    content.writeln("=" * 50);
    for (var c in filteredCompanies) {
      content.writeln("Company ID: ${c.id}");
      content.writeln("Company Name: ${c.name}");
      content.writeln("Owner: ${c.ownerName}");
      content.writeln("Email: ${c.email}");
      content.writeln("Phone: ${c.phoneNumber}");
      content.writeln("State: ${c.state ?? ''}");
      content.writeln("Created: ${c.createdAt?.substring(0, 10) ?? ''}");
      content.writeln("-" * 30);
    }
    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "my_referred_companies.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // UI Components
  Widget _buildFilterSection(bool isMobile, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: isMobile
          ? Column(
        children: [
          Row(
            children: [
              _buildFilterDropdown(isDarkMode),
              const SizedBox(width: 12),
              Expanded(child: _buildSearchField(isDarkMode)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildExportIcons(isDarkMode),
              Row(
                children: [
                  Text(
                    "Total: ${filteredCompanies.length}",
                    style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  IconButton(onPressed: _resetFilters, icon: const Icon(Icons.refresh), color: Colors.red),
                ],
              ),
            ],
          ),
        ],
      )
          : Row(
        children: [
          _buildFilterDropdown(isDarkMode),
          const SizedBox(width: 12),
          Expanded(child: _buildSearchField(isDarkMode)),
          const SizedBox(width: 12),
          _buildExportIcons(isDarkMode),
          const SizedBox(width: 12),
          Text(
            "Total: ${filteredCompanies.length}",
            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey),
          ),
          IconButton(onPressed: _resetFilters, icon: const Icon(Icons.refresh), color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(bool isDarkMode) {
    return Container(
      width: 150,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: filterType,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
          style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF1E293B), fontSize: 13),
          isExpanded: true,
          onChanged: (String? newValue) {
            setState(() {
              filterType = newValue!;
              currentPage = 1;
              _applyFilters();
            });
          },
          items: ['Company Name', 'Owner', 'Email', 'Phone']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSearchField(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: "Search by $filterType...",
          hintStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
          prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF6366F1)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, size: 16, color: isDarkMode ? Colors.white70 : Colors.grey),
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

  Widget _buildExportIcons(bool isDarkMode) {
    return Row(
      children: [
        Tooltip(
          message: "Export Excel",
          child: InkWell(
            onTap: _exportExcel,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.green[900]! : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset("assets/icon/xls.png", height: 20, width: 20,
                  errorBuilder: (_, __, ___) => Icon(Icons.table_chart, size: 20, color: isDarkMode ? Colors.green[300] : Colors.green)),
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
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.red[900]! : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset("assets/icon/pdf.png", height: 20, width: 20,
                  errorBuilder: (_, __, ___) => Icon(Icons.picture_as_pdf, size: 20, color: isDarkMode ? Colors.red[300] : Colors.red)),
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
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.blue[900]! : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset("assets/icon/doc.png", height: 20, width: 20,
                  errorBuilder: (_, __, ___) => Icon(Icons.description, size: 20, color: isDarkMode ? Colors.blue[300] : Colors.blue)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tableHeader(String text, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: isDarkMode ? Colors.grey[300] : const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _tableCell(String text, {bool isBold = false}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildLogo(String? url, bool isDarkMode) {
    if (url == null || url.isEmpty) {
      return Icon(Icons.business, size: 30, color: isDarkMode ? Colors.white70 : Colors.grey);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(width: 36, height: 36, color: Colors.grey.shade200),
        errorWidget: (_, __, ___) => Icon(Icons.broken_image, size: 30, color: isDarkMode ? Colors.white70 : Colors.grey),
      ),
    );
  }

  void _showCompanyDetailsPopup(MyReferredCompany company, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            double dialogWidth = constraints.maxWidth * 0.92;
            if (constraints.maxWidth > 700) dialogWidth = 680;
            if (constraints.maxWidth > 1000) dialogWidth = 750;

            return Container(
              width: dialogWidth,
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3F51B5), Color(0xFFB053C4)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: company.logo != null && company.logo!.isNotEmpty
                                ? CachedNetworkImage(imageUrl: company.logo!, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.business, color: Colors.grey, size: 28))
                                : const Icon(Icons.business, color: Colors.grey, size: 28),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(company.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(company.email, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12), overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildStatusBadge("approved", const Color(0xFFE8F5E9), const Color(0xFF2E7D32)),
                              const SizedBox(width: 10),
                              _buildStatusBadge("Active", const Color(0xFFE3F2FD), const Color(0xFF1565C0)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.tag, size: 16, color: Colors.grey),
                                const SizedBox(width: 6),
                                const Text("Referral: ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                                Expanded(
                                  child: SelectableText(
                                    "gAAAAABqUdFesUimvExK0pdTvN5LPYqjabotQYtCk8djyZsR4Q534BUTPi1ar4Zk_${company.id}_KAyQY",
                                    style: TextStyle(color: isDarkMode ? Colors.white.withOpacity(0.9) : Colors.black87, fontSize: 12),
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildSectionHeader("Personal Information", Icons.person, const Color(0xFF673AB7)),
                          const SizedBox(height: 10),
                          _buildDetailsCard(isDarkMode, [
                            _buildDataRow("ID", company.id.toString(), isDarkMode),
                            _buildDataRow("Owner / Name", company.ownerName, isDarkMode),
                            _buildDataRow("Mobile", company.phoneNumber, isDarkMode),
                            _buildDataRow("Email", company.email, isDarkMode),
                            _buildDataRow("Created At", company.createdAt?.substring(0, 10) ?? 'N/A', isDarkMode),
                          ]),
                          const SizedBox(height: 20),

                          _buildSectionHeader("Professional Details", Icons.business_center, const Color(0xFF9C27B0)),
                          const SizedBox(height: 10),
                          _buildDetailsCard(isDarkMode, [
                            _buildDataRow("Working Area", company.district ?? 'Satara Region', isDarkMode),
                            _buildDataRow("Profession", 'Sales Partner', isDarkMode),
                            _buildDataRow("Short Desc", company.shortDescription ?? 'N/A', isDarkMode),
                            _buildDataRow("Slogan", company.companySlogan ?? 'N/A', isDarkMode),
                          ]),
                          const SizedBox(height: 20),

                          _buildAddressDetails(isDarkMode, company),
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

  Widget _buildAddressDetails(bool isDarkMode, MyReferredCompany company) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Address Details", Icons.location_on, const Color(0xFFE91E63)),
        const SizedBox(height: 10),
        _buildDetailsCard(isDarkMode, [
          _buildDataRow("Address", company.address, isDarkMode),
          _buildDataRow("State", company.state ?? 'N/A', isDarkMode),
          _buildDataRow("Taluka", company.taluka ?? 'N/A', isDarkMode),
          _buildDataRow("Village", company.village ?? 'N/A', isDarkMode),
          _buildDataRow("Pincode", company.pincode ?? 'N/A', isDarkMode),
        ]),
        const SizedBox(height: 20),

        _buildSectionHeader("Registration Details", Icons.assignment, const Color(0xFF4158D0)),
        const SizedBox(height: 10),
        _buildDetailsCard(isDarkMode, [
          _buildDataRow("GST Number", company.gstNumber ?? 'N/A', isDarkMode),
          _buildDataRow("Registration No", company.registrationNo ?? 'N/A', isDarkMode),
          _buildDataRow("Company PAN", company.companyPanNo ?? 'N/A', isDarkMode),
        ]),
      ],
    );
  }

  Widget _buildStatusBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: textColor.withOpacity(0.3))),
      child: Text(text, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color.withOpacity(0.9)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(bool isDarkMode, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF334155) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200, width: 1.5),
      ),
      child: Column(children: rows),
    );
  }

  Widget _buildDataRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: isDarkMode ? Colors.white.withOpacity(0.9) : Colors.black87, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(bool isDarkMode) {
    if (filteredCompanies.isEmpty) return const SizedBox.shrink();
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Entries Section (Show 10 entries...)
    final entriesWidget = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Show ", style: TextStyle(fontSize: 11)),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF334155) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
          ),
          child: DropdownButton<int>(
            value: itemsPerPage,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white70 : Colors.grey),
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 11),
            items: rowsPerPageOptions.map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
            onChanged: _changeItemsPerPage,
          ),
        ),
        const Text(" entries", style: TextStyle(fontSize: 11)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            "Showing ${(currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filteredCompanies.length ? filteredCompanies.length : currentPage * itemsPerPage} of ${filteredCompanies.length}",
            style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.grey[400] : Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    // Number Buttons Section (< 1 2 3 >)
    final buttonsWidget = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _compactPageButton(icon: Icons.chevron_left, onTap: currentPage > 1 ? _previousPage : null, isDarkMode: isDarkMode),
          if (totalPages <= 5)
            ...List.generate(totalPages, (index) => _compactPageNumber(index + 1, isDarkMode))
          else if (currentPage <= 3) ...[
            ...List.generate(4, (index) => _compactPageNumber(index + 1, isDarkMode)),
            const Text("..."),
            _compactPageNumber(totalPages, isDarkMode),
          ] else if (currentPage >= totalPages - 2) ...[
            _compactPageNumber(1, isDarkMode),
            const Text("..."),
            ...List.generate(4, (index) => _compactPageNumber(totalPages - 3 + index, isDarkMode)),
          ] else ...[
            _compactPageNumber(1, isDarkMode),
            const Text("..."),
            _compactPageNumber(currentPage - 1, isDarkMode),
            _compactPageNumber(currentPage, isDarkMode),
            _compactPageNumber(currentPage + 1, isDarkMode),
            const Text("..."),
            _compactPageNumber(totalPages, isDarkMode),
          ],
          _compactPageButton(icon: Icons.chevron_right, onTap: currentPage < totalPages ? _nextPage : null, isDarkMode: isDarkMode),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: isMobile
          ? Column(
        children: [
          entriesWidget,
          const SizedBox(height: 10),
          buttonsWidget,
        ],
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          entriesWidget,
          buttonsWidget,
        ],
      ),
    );
  }

  Widget _compactPageButton({required IconData icon, required VoidCallback? onTap, required bool isDarkMode}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: onTap,
        color: onTap != null ? const Color(0xFF6366F1) : (isDarkMode ? Colors.grey[600] : Colors.grey),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
    );
  }

  Widget _compactPageNumber(int pageNum, bool isDarkMode) {
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
              color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : const Color(0xFF1E293B)),
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      color: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
      child: FutureBuilder<MyReferredCompaniesResponse>(
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
                        _futureData = _service.fetchMyCompanies();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || allCompanies.isEmpty) {
            return const Center(
              child: Text('No referred companies found.'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFilterSection(isMobile, isDarkMode),
                const SizedBox(height: 8),

                LayoutBuilder(
                  builder: (context, constraints) {
                    double assignableWidth = constraints.maxWidth;

                    if (assignableWidth < 950) {
                      assignableWidth = 950;
                    }

                    // 2. नवीन Sr. No. कॉलम विड्थ ॲड केली (0: 6%) आणि बाकीचे इंडेक्स शिफ्ट केले
                    final Map<int, TableColumnWidth> dynamicColumnWidths = {
                      0: FixedColumnWidth(assignableWidth * 0.06), // Sr. No. (6%)
                      1: FixedColumnWidth(assignableWidth * 0.07), // Logo (7%)
                      2: FixedColumnWidth(assignableWidth * 0.18), // Company Name (18%)
                      3: FixedColumnWidth(assignableWidth * 0.14), // Owner (14%)
                      4: FixedColumnWidth(assignableWidth * 0.21), // Email (21%)
                      5: FixedColumnWidth(assignableWidth * 0.12), // Phone (12%)
                      6: FixedColumnWidth(assignableWidth * 0.08), // State (8%)
                      7: FixedColumnWidth(assignableWidth * 0.08), // Created (8%)
                      8: FixedColumnWidth(assignableWidth * 0.06), // Actions (6%)
                    };

                    return Container(
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          columnWidths: dynamicColumnWidths,
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          border: TableBorder(
                            bottom: BorderSide(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
                            horizontalInside: BorderSide(color: isDarkMode ? Colors.grey[800]! : Colors.grey.shade200),
                          ),
                          children: [
                            TableRow(
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF16213E) : const Color(0xFFEEF2F6),
                              ),
                              children: headerLabels.map((l) => _tableHeader(l, isDarkMode)).toList(),
                            ),

                            ...paginatedCompanies.asMap().entries.map((entry) {
                              final index = entry.key;
                              final company = entry.value;
                              final bool isEven = index % 2 == 0;

                              // 3. Descending Order मध्ये मोजण्यासाठी फॉर्म्युला लावला
                              final int globalIndex = (currentPage - 1) * itemsPerPage + index;
                              final int srNo = filteredCompanies.length - globalIndex;

                              return TableRow(
                                decoration: BoxDecoration(
                                  color: isEven
                                      ? (isDarkMode ? const Color(0xFF16213E) : Colors.white)
                                      : (isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                ),
                                children: [
                                  // 4. Logo च्या आधी Sr. No. चा सेल ॲड केला
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company, isDarkMode),
                                    child: _tableCell(srNo.toString(), isBold: true),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company, isDarkMode),
                                    child: Container(
                                      height: 48,
                                      alignment: Alignment.center,
                                      child: _buildLogo(company.logo, isDarkMode),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company, isDarkMode),
                                    child: _tableCell(company.name, isBold: true),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company, isDarkMode),
                                    child: _tableCell(company.ownerName),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company, isDarkMode),
                                    child: _tableCell(company.email),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company, isDarkMode),
                                    child: _tableCell(company.phoneNumber),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company, isDarkMode),
                                    child: _tableCell(company.state ?? ''),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company, isDarkMode),
                                    child: _tableCell(company.createdAt?.substring(0, 10) ?? ''),
                                  ),
                                  Container(
                                    height: 48,
                                    alignment: Alignment.center,
                                    child: IconButton(
                                      icon: const Icon(Icons.visibility, size: 18, color: Color(0xFF4158D0)),
                                      onPressed: () => _showCompanyDetailsPopup(company, isDarkMode),
                                      tooltip: 'View Details',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                if (filteredCompanies.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: Text("No companies match your search")),
                  ),
                const SizedBox(height: 8),
                _buildPagination(isDarkMode),
              ],
            ),
          );
        },
      ),
    );
  }
}
