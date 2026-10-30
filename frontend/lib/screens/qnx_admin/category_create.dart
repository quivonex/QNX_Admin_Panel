import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/qnx_admin/category_model.dart';
import '../../api/api_service.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Filter Controllers
  final TextEditingController _filterCategoryNameController = TextEditingController();

  final ScrollController _horizontalScrollController = ScrollController();

  bool _isActive = true;
  bool _isLoading = false;
  bool _isEdit = false;
  int? _editId;

  final CategoryService _categoryService = CategoryService();
  final CategoryUpdateService _updateService = CategoryUpdateService();
  final CategoryDeleteService _deleteService = CategoryDeleteService();

  List<Category> allCategories = [];
  List<Category> filteredCategories = [];
  List<Category> paginatedCategories = [];
  int? _companyId;
  // Pagination Variables
  int currentPage = 1;
  int itemsPerPage = 5;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 50];

  // Filter Variables
  String filterCategoryName = '';

  Category? searchedCategory;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadCompanyId();
  }
  Future<void> _loadCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _companyId = prefs.getInt('companyId');
      if (_companyId == 0) _companyId = null;
    });
    _loadCategories();  // data load करा
  }
  Future<void> _loadCategories() async {
    try {
      final response = await _categoryService.getCategories();

      if (mounted) {
        setState(() {
          allCategories = response;
          applyFilters();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load categories")),
      );
    }
  }

  void applyFilters() {
    filteredCategories = allCategories.where((category) {
      bool matchesName = filterCategoryName.isEmpty ||
          category.name.toLowerCase().contains(filterCategoryName.toLowerCase());
      return matchesName;
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

    if (currentPage > totalPages) {
      currentPage = totalPages;
    }
    if (currentPage < 1) {
      currentPage = 1;
    }

    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;

    if (startIndex >= filteredCategories.length) {
      paginatedCategories = [];
    } else {
      if (endIndex > filteredCategories.length) {
        endIndex = filteredCategories.length;
      }
      paginatedCategories = filteredCategories.sublist(startIndex, endIndex);
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
      filterCategoryName = '';
      _filterCategoryNameController.clear();
      currentPage = 1;
      applyFilters();
    });
  }
// पेज नंबर बनविण्यासाठी हेल्पर
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

// पुढील / मागील बटणासाठी
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
  Future<void> _searchCategory() async {
    if (_searchController.text.isEmpty) return;

    try {
      int id = int.parse(_searchController.text);

      final cat = allCategories.firstWhere((c) => c.id == id);

      setState(() {
        searchedCategory = cat;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Category Found")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Category not found")),
      );
    }
  }

  Future<void> _createCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    Category category = Category(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      isActive: _isActive,
    );

    try {
      await _categoryService.createCategory(category);

      setState(() => _isLoading = false);

      _clearForm();

      _loadCategories();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Category created successfully")),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Future<void> _updateCategory() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    CategoryUpdateModel model = CategoryUpdateModel(
      id: _editId!,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
    );

    try {
      final response = await _updateService.updateCategory(model);

      setState(() {
        _isLoading = false;
        _isEdit = false;
      });

      _clearForm();
      _loadCategories();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e")),
      );
    }
  }

  Future<void> _deleteCategory(int id) async {
    try {
      CategoryDeleteModel model = CategoryDeleteModel(id: id);

      final response = await _deleteService.deleteCategory(model);

      if (response.status) {
        _loadCategories();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: $e")),
      );
    }
  }

  void _editCategory(Category cat) {
    setState(() {
      _isEdit = true;
      _editId = cat.id;
      _nameController.text = cat.name;
      _descriptionController.text = cat.description ?? "";
      _isActive = cat.isActive;
    });
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _isActive = true;
    _isEdit = false;
    _editId = null;
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
          "Category Management",
          style: TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
              fontSize: 22),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 900;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Search Header - Commented as per role screen
                // _buildSearchHeader(),
                // const SizedBox(height: 24),

                // Search Result Display
                if (searchedCategory != null) ...[
                  _buildSearchResult(),
                  const SizedBox(height: 24),
                ],

                // Filter Section
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
                ]
              ],
            ),
          );
        },
      ),
    );
  }

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
              // मोठी स्क्रीन – Row
                Row(
                  children: [
                    const Icon(Icons.filter_list, color: Color(0xFF6366F1), size: 20),
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
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              // लहान स्क्रीन – Column
                Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.filter_list, color: Color(0xFF6366F1), size: 20),
                        const SizedBox(width: 8),
                        const Text(
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
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              // फिल्टर टेक्स्ट फील्ड – स्मॉल स्क्रीनवर पूर्ण रुंदी
              SizedBox(
                width: isSmallScreen ? double.infinity : 300,
                child: TextField(
                  controller: _filterCategoryNameController,
                  decoration: InputDecoration(
                    labelText: "Filter by Category Name",
                    hintText: "Enter category name...",
                    prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF6366F1)),
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
                        _filterCategoryNameController.clear();
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

// या हेल्पर फंक्शनने ड्रॉपडाउन रिपीट न करता वेगळे केले
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
          const Text(
            "Show:",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
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
          const Text(
            "entries",
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResult() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC7D2FE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search,
              color: Color(0xFF6366F1),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Search Result",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF4338CA),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${searchedCategory!.name}",
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: searchedCategory!.isActive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        searchedCategory!.isActive ? "Active" : "Inactive",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: searchedCategory!.isActive
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "ID: ${searchedCategory!.id}",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(
                Icons.close,
                size: 18,
                color: Color(0xFF4338CA),
              ),
              onPressed: () {
                setState(() {
                  searchedCategory = null;
                  _searchController.clear();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Search Category by ID...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _searchCategory,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Search",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }

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
              offset: const Offset(0, 4))
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isEdit ? "Edit Category" : "Create New Category",
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 24),
            _buildTextField(_nameController, "Category Name", Icons.category),
            const SizedBox(height: 16),
            _buildTextField(
                _descriptionController, "Description", Icons.description,
                maxLines: 3),
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
                onPressed: _isLoading
                    ? null
                    : (_isEdit ? _updateCategory : _createCategory),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  _isEdit ? "Update Category" : "Create Category",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (_isEdit)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton(
                  onPressed: _clearForm,
                  child: const Center(
                    child: Text(
                      "Cancel Edit",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

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
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed Table Header with new color (E0E7FF - richer indigo)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFE0E7FF), // Changed to match search result gradient
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                _TableHeaderCell(label: "ID", flex: 1),
                _TableHeaderCell(label: "Name", flex: 2),
                _TableHeaderCell(label: "Description", flex: 3),
                _TableHeaderCell(label: "Status", flex: 2),
              ],
            ),
          ),

          // Scrollable Rows with Zebra Striping
          if (filteredCategories.isEmpty)
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
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 20, endIndent: 20),
                itemBuilder: (context, index) {
                  final cat = paginatedCategories[index];
                  // Zebra striping: slightly darker gray for even rows, white for odd
                  final backgroundColor = index % 2 == 0
                      ? const Color(0xFFF1F5F9)  // light gray
                      : Colors.white;
                  return Container(
                    color: backgroundColor,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        // ID Cell
                        Expanded(
                          flex: 1,
                          child: Text(
                            cat.id.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),

                        // Name Cell
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

                        // Description Cell
                        Expanded(
                          flex: 3,
                          child: Text(
                            cat.description ?? "-",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),

                        // Status Cell
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
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

          // Pagination Controls
          if (filteredCategories.isNotEmpty) _buildPagination(),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmall = constraints.maxWidth < 500; // ५०० पिक्सेलपेक्षा कमी असल्यास वेगळा लेआउट

        if (isSmall) {
          // लहान स्क्रीनसाठी Column + Wrap
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
          // मोठ्या स्क्रीनसाठी मूळ Row
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

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: (v) => (v == null || v.isEmpty) ? "$label is required" : null,
      decoration: InputDecoration(
        labelText: label,
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

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    _filterCategoryNameController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  final bool isLast;

  const _TableHeaderCell({
    required this.label,
    required this.flex,
    this.isLast = false,
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
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }
}