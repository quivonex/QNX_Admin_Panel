import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;
import '../../api/api_service.dart';
import '../../models/qnx_admin/subcategory_model.dart';

class SubCategoryAllScreen extends StatefulWidget {
  const SubCategoryAllScreen({super.key});

  @override
  State<SubCategoryAllScreen> createState() => _SubCategoryAllScreenState();
}

class _SubCategoryAllScreenState extends State<SubCategoryAllScreen> {
  final SubCategoryService _service = SubCategoryService();

  // Filter Controller
  final TextEditingController _searchController = TextEditingController();

  List<SubCategoryModel> allSubcategories = [];
  List<SubCategoryModel> filteredSubcategories = [];
  List<SubCategoryModel> paginatedSubcategories = [];

  bool isLoading = true;

  // Pagination Variables
  int currentPage = 1;
  int itemsPerPage = 10; // ✅ Changed from 5 to 10
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];
  int? _companyId;

  // Filter Variables
  String searchQuery = '';
  String filterType = 'Name';

  // Category name map (ID -> Name)
  Map<int, String> categoryMap = {};

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadData();
    _loadCompanyId();
    _loadCategories();
  }

  Future<void> _loadCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _companyId = prefs.getInt('companyId');
      if (_companyId == 0) _companyId = null;
    });
    loadData();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryAllService().getCategories();
      setState(() {
        for (var c in categories) {
          categoryMap[c.id] = c.name;
        }
      });
    } catch (e) {
      print("Error loading categories: $e");
    }
  }

  Future<void> loadData() async {
    try {
      final response = await _service.getSubCategories();
      if (mounted) {
        setState(() {
          // Sort by id in descending order (most recent first)
          allSubcategories = response.data..sort((a, b) {
            // Use id for sorting (assuming higher id = newer)
            return b.id.compareTo(a.id);
          });
          applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load subcategories")),
        );
      }
    }
  }

  void applyFilters() {
    if (searchQuery.isEmpty) {
      filteredSubcategories = allSubcategories;
    } else {
      filteredSubcategories = allSubcategories.where((sub) {
        if (filterType == 'Name') {
          return sub.name.toLowerCase().contains(searchQuery.toLowerCase());
        } else {
          return sub.category != null &&
              sub.category.toString().toLowerCase().contains(searchQuery.toLowerCase());
        }
      }).toList();
    }
    applyPagination();
  }

  void applyPagination() {
    if (filteredSubcategories.isEmpty) {
      paginatedSubcategories = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }

    totalPages = (filteredSubcategories.length / itemsPerPage).ceil();

    if (currentPage > totalPages) {
      currentPage = totalPages;
    }
    if (currentPage < 1) {
      currentPage = 1;
    }

    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;

    if (startIndex >= filteredSubcategories.length) {
      paginatedSubcategories = [];
    } else {
      if (endIndex > filteredSubcategories.length) {
        endIndex = filteredSubcategories.length;
      }
      paginatedSubcategories = filteredSubcategories.sublist(startIndex, endIndex);
    }

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

  String getCategoryName(int? categoryId) {
    if (categoryId == null) return '-';
    return categoryMap[categoryId] ?? categoryId.toString();
  }

  // ===================== EXPORT FUNCTIONS =====================

  void _exportExcel() {
    if (filteredSubcategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final file = excel.Excel.createExcel();
    final sheet = file['Sub Categories'];

    sheet.appendRow([
      "SR No", "Name", "Description", "Category", "User", "Created At", "Status"
    ]);

    // Descending order: highest SR No first
    int srNo = filteredSubcategories.length;
    for (var sub in filteredSubcategories) {
      sheet.appendRow([
        srNo--,
        sub.name,
        sub.description.isEmpty ? "-" : sub.description,
        getCategoryName(sub.category),
        sub.user?.toString() ?? "-",
        sub.createdAt.length >= 10 ? sub.createdAt.substring(0, 10) : sub.createdAt,
        sub.isActive ? "Active" : "Inactive",
      ]);
    }

    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "subcategories.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> _exportPDF() async {
    if (filteredSubcategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Table.fromTextArray(
          headers: ["SR No", "Name", "Category", "User", "Status"],
          data: List.generate(filteredSubcategories.length, (index) {
            final sub = filteredSubcategories[index];
            final srNo = filteredSubcategories.length - index;
            return [
              srNo.toString(),
              sub.name,
              getCategoryName(sub.category),
              sub.user?.toString() ?? "-",
              sub.isActive ? "Active" : "Inactive",
            ];
          }),
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void _exportDOC() {
    if (filteredSubcategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final content = StringBuffer();
    content.writeln("Sub Categories List\n");
    content.writeln("=" * 50);

    int srNo = filteredSubcategories.length;
    for (var sub in filteredSubcategories) {
      content.writeln("SR No: ${srNo--}");
      content.writeln("Name: ${sub.name}");
      content.writeln("Description: ${sub.description.isEmpty ? "-" : sub.description}");
      content.writeln("Category: ${getCategoryName(sub.category)}");
      content.writeln("User: ${sub.user?.toString() ?? "-"}");
      content.writeln("Created At: ${sub.createdAt.length >= 10 ? sub.createdAt.substring(0, 10) : sub.createdAt}");
      content.writeln("Status: ${sub.isActive ? "Active" : "Inactive"}");
      content.writeln("-" * 30);
    }

    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "subcategories.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ===================== EXPORT ICONS =====================

  Widget _buildExportIcons() {
    return Row(
      children: [
        Tooltip(
          message: "Export Excel",
          child: InkWell(
            onTap: _exportExcel,
            borderRadius: BorderRadius.circular(10),
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
          message: "Export PDF",
          child: InkWell(
            onTap: _exportPDF,
            borderRadius: BorderRadius.circular(10),
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
          message: "Export DOC",
          child: InkWell(
            onTap: _exportDOC,
            borderRadius: BorderRadius.circular(10),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Sub Category List",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFilterSection(),
            const SizedBox(height: 20),
            _buildCustomTable(),
          ],
        ),
      ),
    );
  }

  // फिल्टर सेक्शन - रिस्पॉन्सिव्ह
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          // Header Row – responsive
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 500;

              if (!isSmall) {
                // मोठी स्क्रीन – Row
                return Row(
                  children: [
                    const Icon(Icons.filter_list, color: Color(0xFF6366F1), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "Filter Sub Categories",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    _buildExportIcons(),
                    const SizedBox(width: 16),
                    _buildRowsPerPageDropdown(),
                    TextButton.icon(
                      onPressed: resetFilters,
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text("Reset"),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${filteredSubcategories.length}",
                        style: const TextStyle(
                          color: Color(0xFF4338CA),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                // लहान स्क्रीन – हेडर Row वेगळा, बाकीचे खाली Wrap
                return Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.filter_list, color: Color(0xFF6366F1), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          "Filter Sub Categories",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildExportIcons(),
                        _buildRowsPerPageDropdown(),
                        TextButton.icon(
                          onPressed: resetFilters,
                          icon: const Icon(Icons.clear_all, size: 16),
                          label: const Text("Reset"),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${filteredSubcategories.length}",
                            style: const TextStyle(
                              color: Color(0xFF4338CA),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 16),

          // Search Row – आधीपासूनच LayoutBuilder आहे
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 500) {
                return Column(
                  children: [
                    _buildFilterTypeDropdown(),
                    const SizedBox(height: 12),
                    _buildSearchTextField(),
                  ],
                );
              } else {
                return Row(
                  children: [
                    _buildFilterTypeDropdown(),
                    const SizedBox(width: 12),
                    Expanded(child: _buildSearchTextField()),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRowsPerPageDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Show:", style: TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: itemsPerPage,
              icon: const Icon(Icons.arrow_drop_down, size: 20),
              style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B)),
              onChanged: changeItemsPerPage,
              items: rowsPerPageOptions.map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
            ),
          ),
          const Text("entries", style: TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFilterTypeDropdown() {
    return Container(
      width: 130,
      height: 50,
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
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
          isExpanded: true,
          onChanged: (String? newValue) {
            setState(() {
              filterType = newValue!;
              currentPage = 1;
              applyFilters();
            });
          },
          items: <String>['Name', 'Category']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  Icon(
                    value == 'Name' ? Icons.text_fields : Icons.category,
                    size: 16,
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
    );
  }

  Widget _buildSearchTextField() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: filterType == 'Name'
            ? "Search by name..."
            : "Search by category...",
        prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF6366F1)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        suffixIcon: searchQuery.isNotEmpty
            ? IconButton(
          icon: const Icon(Icons.clear, size: 18),
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
    );
  }

  // कस्टम टेबल - रिस्पॉन्सिव्ह
  Widget _buildCustomTable() {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const SizedBox(height: 16),

          // Horizontal Scroll for Table
          Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            trackVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1000),
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    child: filteredSubcategories.isEmpty
                        ? SizedBox(
                      height: 200,
                      width: 1000,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline, size: 40, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              "No subcategories found",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    )
                        : Table(
                      border: TableBorder.all(
                        color: Colors.grey.shade300,
                      ),
                      columnWidths: {
                        0: const FixedColumnWidth(60),   // SR No
                        1: const FixedColumnWidth(180),  // Name
                        2: const FixedColumnWidth(280),  // Description
                        3: const FixedColumnWidth(150),  // Category Name
                        4: const FixedColumnWidth(120),  // User
                        5: const FixedColumnWidth(150),  // Created At
                        6: const FixedColumnWidth(110),   // Is Active
                      },
                      children: [
                        // HEADER
                        TableRow(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                          ),
                          children: [
                            _tableHeader("SR No"),
                            _tableHeader("Name"),
                            _tableHeader("Description"),
                            _tableHeader("Category"),
                            _tableHeader("User"),
                            _tableHeader("Created"),
                            _tableHeader("Status"),
                          ],
                        ),

                        // DATA
                        ...paginatedSubcategories.asMap().entries.map((entry) {
                          int index = entry.key;
                          SubCategoryModel sub = entry.value;
                          // ✅ SR No in descending order
                          final int srNo = filteredSubcategories.length - ((currentPage - 1) * itemsPerPage + index);

                          return TableRow(
                            decoration: BoxDecoration(
                              color: index % 2 == 0
                                  ? Colors.white
                                  : const Color(0xFFF8FAFC),
                            ),
                            children: [
                              _tableCell(srNo.toString()),
                              _tableCell(sub.name),
                              _tableCell(sub.description.isEmpty ? "-" : sub.description),
                              _tableCell(getCategoryName(sub.category)),
                              _tableCell(sub.user?.toString() ?? "-"),
                              _tableCell(
                                  sub.createdAt.length >= 10
                                      ? sub.createdAt.substring(0, 10)
                                      : sub.createdAt
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: sub.isActive
                                          ? const Color(0xFFDCFCE7)
                                          : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      sub.isActive ? "Active" : "Inactive",
                                      style: TextStyle(
                                        color: sub.isActive
                                            ? const Color(0xFF15803D)
                                            : const Color(0xFFB91C1C),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Pagination Controls - Responsive
          if (filteredSubcategories.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 700) {
                  // Mobile pagination - vertical
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Showing entries info
                        Text(
                          "Showing ${filteredSubcategories.isEmpty ? 0 : (currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filteredSubcategories.length ? filteredSubcategories.length : currentPage * itemsPerPage} of ${filteredSubcategories.length}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        // Page controls
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 4,
                          children: _buildMobilePagination(),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Desktop pagination - horizontal
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Showing ${filteredSubcategories.isEmpty ? 0 : (currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filteredSubcategories.length ? filteredSubcategories.length : currentPage * itemsPerPage} of ${filteredSubcategories.length} entries",
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        Row(
                          children: _buildDesktopPagination(),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  // Mobile pagination widgets
  List<Widget> _buildMobilePagination() {
    List<Widget> widgets = [];

    // Previous Button
    widgets.add(
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: const Icon(Icons.chevron_left, size: 18),
          onPressed: currentPage > 1 ? previousPage : null,
          color: currentPage > 1 ? const Color(0xFF6366F1) : Colors.grey,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
      ),
    );

    // Page Numbers (max 3 for mobile)
    int startPage = currentPage > 2 ? currentPage - 1 : 1;
    int endPage = startPage + 2;
    if (endPage > totalPages) {
      endPage = totalPages;
      startPage = endPage - 2;
      if (startPage < 1) startPage = 1;
    }

    for (int i = startPage; i <= endPage; i++) {
      widgets.add(
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: currentPage == i ? const Color(0xFF6366F1) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            icon: Text(
              i.toString(),
              style: TextStyle(
                color: currentPage == i ? Colors.white : const Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            onPressed: () => goToPage(i),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ),
      );
    }

    // Next Button
    widgets.add(
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: const Icon(Icons.chevron_right, size: 18),
          onPressed: currentPage < totalPages ? nextPage : null,
          color: currentPage < totalPages ? const Color(0xFF6366F1) : Colors.grey,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 32,
            minHeight: 32,
          ),
        ),
      ),
    );

    return widgets;
  }

  // Desktop pagination widgets
  List<Widget> _buildDesktopPagination() {
    List<Widget> widgets = [];

    // Previous Button
    widgets.add(
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: const Icon(Icons.chevron_left, size: 20),
          onPressed: currentPage > 1 ? previousPage : null,
          color: currentPage > 1 ? const Color(0xFF6366F1) : Colors.grey,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
        ),
      ),
    );

    // Page Numbers
    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        widgets.add(_buildPageButton(i));
      }
    } else if (currentPage <= 3) {
      for (int i = 1; i <= 4; i++) {
        widgets.add(_buildPageButton(i));
      }
      widgets.add(_buildEllipsis());
      widgets.add(_buildPageButton(totalPages));
    } else if (currentPage >= totalPages - 2) {
      widgets.add(_buildPageButton(1));
      widgets.add(_buildEllipsis());
      for (int i = totalPages - 3; i <= totalPages; i++) {
        widgets.add(_buildPageButton(i));
      }
    } else {
      widgets.add(_buildPageButton(1));
      widgets.add(_buildEllipsis());
      widgets.add(_buildPageButton(currentPage - 1));
      widgets.add(_buildPageButton(currentPage));
      widgets.add(_buildPageButton(currentPage + 1));
      widgets.add(_buildEllipsis());
      widgets.add(_buildPageButton(totalPages));
    }

    // Next Button
    widgets.add(
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: IconButton(
          icon: const Icon(Icons.chevron_right, size: 20),
          onPressed: currentPage < totalPages ? nextPage : null,
          color: currentPage < totalPages ? const Color(0xFF6366F1) : Colors.grey,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
        ),
      ),
    );

    return widgets;
  }

  Widget _buildPageButton(int pageNum) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: currentPage == pageNum ? const Color(0xFF6366F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Text(
          pageNum.toString(),
          style: TextStyle(
            color: currentPage == pageNum ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        onPressed: () => goToPage(pageNum),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 36,
          minHeight: 36,
        ),
      ),
    );
  }

  Widget _buildEllipsis() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: const Text(
        "...",
        style: TextStyle(fontSize: 13, color: Colors.grey),
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF4B5563),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }
}



/*

import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/subcategory_model.dart';

class SubCategoryAllScreen extends StatefulWidget {
  const SubCategoryAllScreen({super.key});

  @override
  State<SubCategoryAllScreen> createState() => _SubCategoryAllScreenState();
}

class _SubCategoryAllScreenState extends State<SubCategoryAllScreen> {

  final SubCategoryService _service = SubCategoryService();

  List<SubCategoryModel> subcategories = [];

  bool isLoading = true;

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  int currentPage = 1;
  int rowsPerPage = 8;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {

    final response = await _service.getSubCategories();

    setState(() {
      subcategories = response.data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    int start = (currentPage - 1) * rowsPerPage;
    int end = start + rowsPerPage;

    List<SubCategoryModel> pageData =
    subcategories.sublist(start, end > subcategories.length ? subcategories.length : end);

    int totalPages = (subcategories.length / rowsPerPage).ceil();

    return Scaffold(

      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Sub Category List",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          children: [

            Expanded(

              child: Container(

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),

                child: Scrollbar(
                  controller: _horizontalController,
                  thumbVisibility: true,

                  child: SingleChildScrollView(

                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,

                    child: ConstrainedBox(

                      constraints: const BoxConstraints(minWidth: 1200),

                      child: Scrollbar(
                        controller: _verticalController,
                        thumbVisibility: true,

                        child: SingleChildScrollView(

                          controller: _verticalController,

                          child: Table(

                            border: TableBorder(
                              horizontalInside:
                              BorderSide(color: Colors.grey.shade300),
                            ),

                            columnWidths: const {

                              0: FixedColumnWidth(80),
                              1: FlexColumnWidth(),
                              2: FlexColumnWidth(),
                              3: FixedColumnWidth(120),
                              4: FixedColumnWidth(120),
                              5: FixedColumnWidth(150),
                              6: FixedColumnWidth(120),

                            },

                            children: [

                              /// HEADER
                              TableRow(

                                decoration: const BoxDecoration(
                                  color: Color(0xFF4B5563),
                                ),

                                children: [

                                  tableHeader("ID"),
                                  tableHeader("Name"),
                                  tableHeader("Description"),
                                  tableHeader("Category"),
                                  tableHeader("User"),
                                  tableHeader("Created At"),
                                  tableHeader("Status"),

                                ],
                              ),

                              /// DATA
                              ...pageData.asMap().entries.map((entry) {

                                int index = entry.key;
                                SubCategoryModel sub = entry.value;

                                return TableRow(

                                  decoration: BoxDecoration(
                                    color: index % 2 == 0
                                        ? Colors.white
                                        : const Color(0xFFF9FAFB),
                                  ),

                                  children: [

                                    tableCell(sub.id.toString()),
                                    tableCell(sub.name),
                                    tableCell(sub.description),
                                    tableCell(sub.category.toString()),
                                    tableCell(sub.user?.toString() ?? "-"),
                                    tableCell(sub.createdAt),

                                    Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: sub.isActive
                                              ? Colors.green.withOpacity(.15)
                                              : Colors.red.withOpacity(.15),
                                          borderRadius:
                                          BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          sub.isActive
                                              ? "Active"
                                              : "Inactive",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: sub.isActive
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),

                                  ],

                                );

                              }).toList(),

                            ],

                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            /// PAGINATION
            Row(

              mainAxisAlignment: MainAxisAlignment.center,

              children: [

                ElevatedButton(

                  onPressed: currentPage == 1
                      ? null
                      : () {
                    setState(() {
                      currentPage--;
                    });
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                  ),

                  child: const Text("Previous"),

                ),

                const SizedBox(width: 10),

                ...List.generate(totalPages, (index) {

                  int page = index + 1;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(

                      onTap: () {
                        setState(() {
                          currentPage = page;
                        });
                      },

                      child: Container(

                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),

                        decoration: BoxDecoration(

                          color: currentPage == page
                              ? Colors.black
                              : Colors.grey.shade200,

                          borderRadius: BorderRadius.circular(6),

                        ),

                        child: Text(
                          page.toString(),
                          style: TextStyle(
                            color: currentPage == page
                                ? Colors.white
                                : Colors.black,
                          ),
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(width: 10),

                ElevatedButton(

                  onPressed: currentPage == totalPages
                      ? null
                      : () {
                    setState(() {
                      currentPage++;
                    });
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade200,
                    foregroundColor: Colors.black,
                  ),

                  child: const Text("Next"),

                ),

              ],

            )

          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }
}

/// HEADER
Widget tableHeader(String text) {

  return Padding(
    padding: const EdgeInsets.all(12),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
      ),
    ),
  );
}

/// CELL
Widget tableCell(String text) {

  return Padding(
    padding: const EdgeInsets.all(12),
    child: Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
  );
}*/
