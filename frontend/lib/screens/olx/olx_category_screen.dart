// lib/screens/qnx_admin/olx_category_screen.dart

import 'package:flutter/material.dart';
import '../../models/olx/olx_category_model.dart';
import '../../api/olx_service.dart';

class OlxCategoryScreen extends StatefulWidget {
  const OlxCategoryScreen({super.key});

  @override
  State<OlxCategoryScreen> createState() => _OlxCategoryScreenState();
}

class _OlxCategoryScreenState extends State<OlxCategoryScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _slugController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _sortOrderController = TextEditingController();
  final TextEditingController _filterNameController = TextEditingController();

  bool _isActive = true;
  bool _isLoading = false;

  final OlxCategoryService _service = OlxCategoryService();

  List<OlxCategory> allCategories = [];
  List<OlxCategory> filteredCategories = [];
  List<OlxCategory> paginatedCategories = [];

  // Pagination
  int currentPage = 1;
  int itemsPerPage = 5;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 50];

  String filterCategoryName = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final response = await _service.getCategories();
      if (mounted) {
        setState(() {
          // ✅ Sort by ID descending - नवीन category (सर्वात मोठा ID) top ला
          allCategories = response.data
            ..sort((a, b) => b.id.compareTo(a.id));
          _isLoading = false;
          applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar("Failed to load categories", isError: true);
      }
    }
  }

  void applyFilters() {
    filteredCategories = allCategories.where((c) {
      return filterCategoryName.isEmpty ||
          c.name.toLowerCase().contains(filterCategoryName.toLowerCase());
    }).toList();
    applyPagination();
  }

  void applyPagination() {
    if (filteredCategories.isEmpty) {
      paginatedCategories = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }

    totalPages = (filteredCategories.length / itemsPerPage).ceil();
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;

    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > filteredCategories.length) {
      endIndex = filteredCategories.length;
    }

    paginatedCategories = filteredCategories.sublist(startIndex, endIndex);
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
      filterCategoryName = '';
      _filterNameController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  /// Generate slug from name
  String _generateSlug(String name) {
    return name
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-');
  }

  Future<void> _createCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = OlxCategoryRequest(
      name: _nameController.text.trim(),
      slug: _slugController.text.trim().isEmpty
          ? _generateSlug(_nameController.text.trim())
          : _slugController.text.trim(),
      description: _descriptionController.text.trim(),
      isActive: _isActive,
      sortOrder: int.tryParse(_sortOrderController.text.trim()) ?? 0,
    );

    try {
      final response = await _service.createCategory(request);
      setState(() => _isLoading = false);

      if (response.success) {
        _clearForm();
        // ✅ Reload - नवीन category top ला दिसेल (ID descending sort मुळे)
        await _loadCategories();
        _showSnackBar("Category created successfully");
      } else {
        _showSnackBar(response.message, isError: true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Error: $e", isError: true);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _slugController.clear();
    _descriptionController.clear();
    _sortOrderController.clear();
    _isActive = true;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    _sortOrderController.dispose();
    _filterNameController.dispose();
    _service.dispose();
    super.dispose();
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
          "OLX Category Management",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadCategories,
            icon: const Icon(Icons.refresh, color: Color(0xFF6366F1)),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 900;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildFilterSection(),
                const SizedBox(height: 24),
                if (isMobile) ...[
                  _buildForm(),
                  const SizedBox(height: 24),
                  _buildCustomTable(),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildForm()),
                      const SizedBox(width: 24),
                      Expanded(flex: 3, child: _buildCustomTable()),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // ==================== FILTER SECTION ====================
  Widget _buildFilterSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        return Container(
          padding: const EdgeInsets.all(20),
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
              if (!isSmallScreen)
                Row(
                  children: [
                    const Icon(Icons.filter_list,
                        color: Color(0xFF6366F1), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "Filter Categories",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    _buildRowsPerPageDropdown(),
                    TextButton.icon(
                      onPressed: resetFilters,
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text("Reset Filters"),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${filteredCategories.length}",
                        style: const TextStyle(
                          color: Color(0xFF4338CA),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.filter_list,
                            color: Color(0xFF6366F1), size: 20),
                        SizedBox(width: 8),
                        Text(
                          "Filter Categories",
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
                        _buildRowsPerPageDropdown(),
                        TextButton.icon(
                          onPressed: resetFilters,
                          icon: const Icon(Icons.clear_all, size: 16),
                          label: const Text("Reset Filters"),
                          style:
                          TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${filteredCategories.length}",
                            style: const TextStyle(
                              color: Color(0xFF4338CA),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              SizedBox(
                width: isSmallScreen ? double.infinity : 300,
                child: TextField(
                  controller: _filterNameController,
                  decoration: InputDecoration(
                    labelText: "Filter by Category Name",
                    hintText: "Enter category name...",
                    prefixIcon: const Icon(Icons.search,
                        size: 18, color: Color(0xFF6366F1)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    suffixIcon: filterCategoryName.isNotEmpty
                        ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _filterNameController.clear();
                        setState(() {
                          filterCategoryName = '';
                          currentPage = 1;
                          applyFilters();
                        });
                      },
                    )
                        : null,
                  ),
                  onChanged: (value) {
                    setState(() {
                      filterCategoryName = value;
                      currentPage = 1;
                      applyFilters();
                    });
                  },
                ),
              ),
            ],
          ),
        );
      },
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
          const Text("Show:",
              style: TextStyle(fontSize: 13, color: Colors.grey)),
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
          const Text("entries",
              style: TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  // ==================== FORM ====================
  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.category,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Create New OLX Category",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTextField(
              _nameController,
              "Category Name",
              Icons.label_outline,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _slugController,
              "Slug (auto-generated if empty)",
              Icons.link,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _descriptionController,
              "Description",
              Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _sortOrderController,
              "Sort Order",
              Icons.sort,
              keyboardType: TextInputType.number,
              isRequired: false,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Switch(
                  value: _isActive,
                  activeColor: const Color(0xFF6366F1),
                  onChanged: (v) => setState(() => _isActive = v),
                ),
                const Text(
                  "Active Status",
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createCategory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Text(
                  "Create Category",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
        bool isRequired = true,
      }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: isRequired
          ? (v) => (v == null || v.isEmpty) ? "$label is required" : null
          : null,
      decoration: InputDecoration(
        labelText: isRequired ? label : "$label (optional)",
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
        ),
      ),
    );
  }

  // ==================== TABLE ====================
  Widget _buildCustomTable() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
          // ✅ Table Header - ID च्या जागी Sr No
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                _HeaderCell(label: "Sr No", flex: 1),
                _HeaderCell(label: "Name", flex: 2),
                _HeaderCell(label: "Slug", flex: 2),
                _HeaderCell(label: "Sort", flex: 1),
                _HeaderCell(label: "Status", flex: 2),
              ],
            ),
          ),

          // Table Body
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
              ),
            )
          else if (filteredCategories.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text(
                      "No categories found",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: paginatedCategories.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 20, endIndent: 20),
                itemBuilder: (context, index) {
                  final cat = paginatedCategories[index];
                  final bgColor = index % 2 == 0
                      ? const Color(0xFFF8FAFC)
                      : Colors.white;

                  // ✅ Sr No calculation - Global position based on sorted list
                  // Sorted list मध्ये नवीन category top ला आहे, त्यामुळे
                  // Sr No 1 = सर्वात नवीन category
                  // Sr No N = सर्वात जुनी category
                  final globalIndex = (currentPage - 1) * itemsPerPage + index;
                  final srNo = globalIndex + 1;

                  return Container(
                    color: bgColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        // ✅ Sr No Column (ID च्या जागी)
                        Expanded(
                          flex: 1,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                srNo.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF6366F1),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            cat.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            cat.slug,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Text(
                            (cat.sortOrder ?? 0).toString(),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: cat.isActive
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  cat.isActive ? "Active" : "Inactive",
                                  style: TextStyle(
                                    color: cat.isActive
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFFB91C1C),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
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

          const SizedBox(height: 20),
          if (filteredCategories.isNotEmpty) _buildPagination(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ==================== PAGINATION ====================
  Widget _buildPagination() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 500;

        if (isSmall) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  "Showing ${filteredCategories.isEmpty ? 0 : (currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filteredCategories.length ? filteredCategories.length : currentPage * itemsPerPage} of ${filteredCategories.length} entries",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
                  runSpacing: 4,
                  children: [
                    _buildPageButtonPrevNext(prev: true),
                    ..._buildPageNumbers(),
                    _buildPageButtonPrevNext(prev: false),
                  ],
                ),
              ],
            ),
          );
        } else {
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
                  "Showing ${filteredCategories.isEmpty ? 0 : (currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filteredCategories.length ? filteredCategories.length : currentPage * itemsPerPage} of ${filteredCategories.length} entries",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                Row(
                  children: [
                    _buildPageButtonPrevNext(prev: true),
                    ..._buildPageNumbers(),
                    _buildPageButtonPrevNext(prev: false),
                  ],
                ),
              ],
            ),
          );
        }
      },
    );
  }

  List<Widget> _buildPageNumbers() {
    if (totalPages <= 5) {
      return List.generate(totalPages, (index) => _buildPageButton(index + 1));
    } else if (currentPage <= 3) {
      return [
        ...List.generate(4, (index) => _buildPageButton(index + 1)),
        _buildEllipsis(),
        _buildPageButton(totalPages),
      ];
    } else if (currentPage >= totalPages - 2) {
      return [
        _buildPageButton(1),
        _buildEllipsis(),
        ...List.generate(4, (index) => _buildPageButton(totalPages - 3 + index)),
      ];
    } else {
      return [
        _buildPageButton(1),
        _buildEllipsis(),
        _buildPageButton(currentPage - 1),
        _buildPageButton(currentPage),
        _buildPageButton(currentPage + 1),
        _buildEllipsis(),
        _buildPageButton(totalPages),
      ];
    }
  }

  Widget _buildPageButtonPrevNext({required bool prev}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(prev ? Icons.chevron_left : Icons.chevron_right, size: 20),
        onPressed: prev
            ? (currentPage > 1 ? previousPage : null)
            : (currentPage < totalPages ? nextPage : null),
        color: (prev && currentPage > 1) || (!prev && currentPage < totalPages)
            ? const Color(0xFF6366F1)
            : Colors.grey,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  Widget _buildPageButton(int pageNum) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: currentPage == pageNum
            ? const Color(0xFF6366F1)
            : Colors.transparent,
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
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
}

// ==================== HEADER CELL ====================
class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;

  const _HeaderCell({
    required this.label,
    required this.flex,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Colors.white,
        ),
      ),
    );
  }
}