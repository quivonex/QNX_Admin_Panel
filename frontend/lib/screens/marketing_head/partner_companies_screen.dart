// lib/screens/marketing_head/partner_companies_screen.dart
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;
import '../../models/marketing_head/partner_company_model.dart';

// This is a view (no Scaffold) to be embedded inside MyTeamScreen
class PartnerCompaniesView extends StatefulWidget {
  final String partnerName;
  final List<PartnerCompany> companies;
  final VoidCallback onBack;

  const PartnerCompaniesView({
    super.key,
    required this.partnerName,
    required this.companies,
    required this.onBack,
  });

  @override
  State<PartnerCompaniesView> createState() => _PartnerCompaniesViewState();
}

class _PartnerCompaniesViewState extends State<PartnerCompaniesView> {
  List<PartnerCompany> filteredCompanies = [];
  List<PartnerCompany> paginatedCompanies = [];

  String searchQuery = '';
  String filterType = 'Name';

  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  final TextEditingController _searchController = TextEditingController();

  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(80),   // ID
    1: FixedColumnWidth(55),   // Logo
    2: FixedColumnWidth(150),  // Name
    3: FixedColumnWidth(150),  // Owner Name
    4: FixedColumnWidth(170),  // Email
    5: FixedColumnWidth(100),  // Phone
    6: FixedColumnWidth(120),  // State
    7: FixedColumnWidth(90),   // Created
  };

  final List<String> headerLabels = [
    "ID", "Logo", "Company Name", "Owner", "Email", "Phone", "State", "Created"
  ];

  @override
  void initState() {
    super.initState();
    filteredCompanies = List.from(widget.companies);
    _applyPagination();
  }

  void _applyFilters() {
    if (searchQuery.isEmpty) {
      filteredCompanies = List.from(widget.companies);
    } else {
      final query = searchQuery.toLowerCase();
      filteredCompanies = widget.companies.where((c) {
        switch (filterType) {
          case 'Name':
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
      filterType = 'Name';
      _searchController.clear();
      currentPage = 1;
      _applyFilters();
    });
  }

  void _exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['Companies'];
    sheet.appendRow(["ID", "Company Name", "Owner Name", "Email", "Phone", "State", "Created At"]);
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
        ..setAttribute("download", "companies_${widget.partnerName.replaceAll(' ', '_')}.xlsx")
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
    content.writeln("Companies referred by ${widget.partnerName}\n");
    content.writeln("=" * 50);
    for (var c in filteredCompanies) {
      content.writeln("ID: ${c.id}");
      content.writeln("Name: ${c.name}");
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
      ..setAttribute("download", "companies_${widget.partnerName.replaceAll(' ', '_')}.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Widget _buildLogo(String? url) {
    if (url == null || url.isEmpty) {
      return const Icon(Icons.business, size: 30);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 30),
      ),
    );
  }

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
                  IconButton(onPressed: _resetFilters, icon: const Icon(Icons.refresh), color: Colors.red),
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
          IconButton(onPressed: _resetFilters, icon: const Icon(Icons.refresh), color: Colors.red),
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
              _applyFilters();
            });
          },
          items: ['Name', 'Owner', 'Email', 'Phone']
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
      children: [
        Tooltip(
          message: "Export Excel",
          child: InkWell(
            onTap: _exportExcel,
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
            onTap: _exportPDF,
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
            onTap: _exportDOC,
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

  Widget _buildPagination() {
    if (filteredCompanies.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
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
              if (totalPages <= 5)
                ...List.generate(totalPages, (index) => _compactPageNumber(index + 1))
              else if (currentPage <= 3) ...[
                ...List.generate(4, (index) => _compactPageNumber(index + 1)),
                const Text("..."),
                _compactPageNumber(totalPages),
              ] else if (currentPage >= totalPages - 2) ...[
                _compactPageNumber(1),
                const Text("..."),
                ...List.generate(4, (index) => _compactPageNumber(totalPages - 3 + index)),
              ] else ...[
                _compactPageNumber(1),
                const Text("..."),
                _compactPageNumber(currentPage - 1),
                _compactPageNumber(currentPage),
                _compactPageNumber(currentPage + 1),
                const Text("..."),
                _compactPageNumber(totalPages),
              ],
              _compactPageButton(icon: Icons.chevron_right, onTap: currentPage < totalPages ? _nextPage : null),
            ],
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Column(
      children: [
        // Custom header with back button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF4158D0)),
                onPressed: widget.onBack,
                tooltip: 'Back to My Team',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Companies referred by ${widget.partnerName}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: Padding(
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
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: SingleChildScrollView(
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
                      Expanded(
                        child: filteredCompanies.isEmpty
                            ? const Center(child: Text("No companies found"))
                            : SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Table(
                              border: TableBorder.all(color: Colors.grey.shade300),
                              columnWidths: columnWidths,
                              children: paginatedCompanies.map((company) {
                                final bool isEven = paginatedCompanies.indexOf(company) % 2 == 0;
                                return TableRow(
                                  decoration: BoxDecoration(color: isEven ? Colors.white : const Color(0xFFF8FAFC)),
                                  children: [
                                    _tableCell(company.id.toString()),
                                    Container(
                                      height: 42,
                                      alignment: Alignment.center,
                                      child: _buildLogo(company.logo),
                                    ),
                                    _tableCell(company.name, isBold: true),
                                    _tableCell(company.ownerName),
                                    _tableCell(company.email),
                                    _tableCell(company.phoneNumber),
                                    _tableCell(company.state ?? ''),
                                    _tableCell(company.createdAt?.substring(0, 10) ?? ''),
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
        ),
      ],
    );
  }
}