import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api_service.dart';
import '../../models/qnx_admin/unit_model.dart';

class UnitCreateScreen extends StatefulWidget {
  const UnitCreateScreen({super.key});

  @override
  State<UnitCreateScreen> createState() => _UnitCreateScreenState();
}

class _UnitCreateScreenState extends State<UnitCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _shortController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Filter Controllers
  final TextEditingController _filterUnitNameController = TextEditingController();

  bool _isLoading = false;

  final UnitService _unitService = UnitService();
  final UnitUpdateService _updateService = UnitUpdateService(); // kept for potential future use, but no edit now

  Unit? searchedUnit;
  List<Unit> allUnits = [];
  List<Unit> filteredUnits = [];
  List<Unit> paginatedUnits = [];
  int? _companyId;
  // Pagination Variables
  int currentPage = 1;
  int itemsPerPage = 5;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 50];

  // Filter Variables
  String filterUnitName = '';

  @override
  void initState() {
    super.initState();
    loadUnits();
  }


  Future<void> loadUnits() async {
    try {

      final data = await _unitService.getUnits();
      if (mounted) {
        setState(() {
          allUnits = data;
          applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load units")),
        );
      }
    }
  }

  void applyFilters() {
    filteredUnits = allUnits.where((unit) {
      bool matchesName = filterUnitName.isEmpty ||
          unit.name.toLowerCase().contains(filterUnitName.toLowerCase());
      return matchesName;
    }).toList();

    applyPagination();
  }

  void applyPagination() {
    if (filteredUnits.isEmpty) {
      paginatedUnits = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }

    totalPages = (filteredUnits.length / itemsPerPage).ceil();

    if (currentPage > totalPages) {
      currentPage = totalPages;
    }
    if (currentPage < 1) {
      currentPage = 1;
    }

    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;

    if (startIndex >= filteredUnits.length) {
      paginatedUnits = [];
    } else {
      if (endIndex > filteredUnits.length) {
        endIndex = filteredUnits.length;
      }
      paginatedUnits = filteredUnits.sublist(startIndex, endIndex);
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
      filterUnitName = '';
      _filterUnitNameController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  Future<void> searchUnit() async {
    if (_searchController.text.isEmpty) return;
    try {
      int id = int.parse(_searchController.text);
      final unit = allUnits.firstWhere((u) => u.id == id);
      setState(() {
        searchedUnit = unit;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Unit Found")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid ID or error searching")),
      );
    }
  }

  Future<void> _createUnit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    Unit unit = Unit(
      name: _nameController.text.trim(),
      shortName: _shortController.text.trim(),
    );

    try {
      final response = await _unitService.createUnit(unit);
      setState(() => _isLoading = false);

      if (response.unit != null) {
        _nameController.clear();
        _shortController.clear();
        loadUnits();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    } catch (e) {
      setState(() => _isLoading = false);
    }
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
          "Unit Management",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (searchedUnit != null) ...[
                  _buildSearchResult(),
                  const SizedBox(height: 16),
                ],

                _buildFilterSection(),
                const SizedBox(height: 16),

                if (constraints.maxWidth < 800) ...[
                  _buildFormCard(),
                  const SizedBox(height: 16),
                  _buildCustomTable(),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildFormCard()),
                      const SizedBox(width: 16),
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

  Widget _buildFilterSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 500;

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
              if (!isSmallScreen)
              // मोठी स्क्रीन – Row
                Row(
                  children: [
                    const Icon(Icons.filter_list, color: Color(0xFF6366F1), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "Filter Units",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    _buildRowsPerPageDropdown(),
                    const SizedBox(width: 12),
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
                        "${filteredUnits.length}",
                        style: const TextStyle(
                          color: Color(0xFF4338CA),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
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
                          "Filter Units",
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
                            "${filteredUnits.length}",
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
                ),
              const SizedBox(height: 16),
              TextField(
                controller: _filterUnitNameController,
                decoration: InputDecoration(
                  labelText: "Filter by Unit Name",
                  hintText: "Enter unit name...",
                  prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF6366F1)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  suffixIcon: filterUnitName.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _filterUnitNameController.clear();
                      setState(() {
                        filterUnitName = '';
                        currentPage = 1;
                        applyFilters();
                      });
                    },
                  )
                      : null,
                ),
                onChanged: (value) {
                  setState(() {
                    filterUnitName = value;
                    currentPage = 1;
                    applyFilters();
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRowsPerPageDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Show:", style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: itemsPerPage,
              icon: const Icon(Icons.arrow_drop_down, size: 18),
              style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
              onChanged: changeItemsPerPage,
              items: rowsPerPageOptions.map((int value) {
                return DropdownMenuItem<int>(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
            ),
          ),
          const Text("entries", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search, color: Color(0xFF6366F1), size: 20),
          ),
          const SizedBox(width: 12),
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
                  "${searchedUnit!.name}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        searchedUnit!.shortName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "ID: ${searchedUnit!.id}",
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF4338CA)),
            onPressed: () {
              setState(() {
                searchedUnit = null;
                _searchController.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Create New Unit",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 20),
            _buildTextField(_nameController, "Unit Name", Icons.straighten),
            const SizedBox(height: 16),
            _buildTextField(_shortController, "Short Name", Icons.short_text),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createUnit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
                    : const Text(
                  "Create Unit",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
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
          // Table Header (fixed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: const [
                Expanded(flex: 1, child: Text("ID", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 4, child: Text("Unit Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(flex: 3, child: Text("Short Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),

          // Scrollable rows – no extra space
          if (filteredUnits.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.info_outline, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text("No units found", style: TextStyle(color: Colors.grey)),
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
                itemCount: paginatedUnits.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final unit = paginatedUnits[index];
                  final backgroundColor = index % 2 == 0
                      ? const Color(0xFFF8FAFC)
                      : Colors.white;
                  return Container(
                    color: backgroundColor,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        Expanded(flex: 1, child: Text(unit.id.toString(), style: const TextStyle(fontSize: 12))),
                        Expanded(
                          flex: 4,
                          child: Text(
                            unit.name,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            unit.shortName,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),

          if (filteredUnits.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return _buildMobilePagination();
                } else {
                  return _buildDesktopPagination();
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMobilePagination() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            "Showing ${filteredUnits.isEmpty ? 0 : (currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filteredUnits.length ? filteredUnits.length : currentPage * itemsPerPage} of ${filteredUnits.length}",
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            children: [
              _buildPageButton(currentPage > 1 ? currentPage - 1 : 1, isPrevious: true),
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
                  return _buildPageButton(pageNum);
                },
              ),
              _buildPageButton(currentPage < totalPages ? currentPage + 1 : totalPages, isNext: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Showing ${filteredUnits.isEmpty ? 0 : (currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filteredUnits.length ? filteredUnits.length : currentPage * itemsPerPage} of ${filteredUnits.length} entries",
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Row(
            children: [
              _buildPageButton(currentPage > 1 ? currentPage - 1 : 1, isPrevious: true),
              if (totalPages <= 5)
                ...List.generate(totalPages, (index) => _buildPageButton(index + 1))
              else if (currentPage <= 3) ...[
                ...List.generate(4, (index) => _buildPageButton(index + 1)),
                _buildEllipsis(),
                _buildPageButton(totalPages),
              ] else if (currentPage >= totalPages - 2) ...[
                _buildPageButton(1),
                _buildEllipsis(),
                ...List.generate(4, (index) => _buildPageButton(totalPages - 3 + index)),
              ] else ...[
                _buildPageButton(1),
                _buildEllipsis(),
                _buildPageButton(currentPage - 1),
                _buildPageButton(currentPage),
                _buildPageButton(currentPage + 1),
                _buildEllipsis(),
                _buildPageButton(totalPages),
              ],
              _buildPageButton(currentPage < totalPages ? currentPage + 1 : totalPages, isNext: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton(int pageNum, {bool isPrevious = false, bool isNext = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: !isPrevious && !isNext && currentPage == pageNum ? const Color(0xFF6366F1) : Colors.transparent,
        border: isPrevious || isNext ? Border.all(color: Colors.grey.shade300) : null,
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        icon: isPrevious
            ? const Icon(Icons.chevron_left, size: 16)
            : isNext
            ? const Icon(Icons.chevron_right, size: 16)
            : Text(
          pageNum.toString(),
          style: TextStyle(
            color: currentPage == pageNum ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        onPressed: () {
          if (isPrevious && currentPage > 1) {
            previousPage();
          } else if (isNext && currentPage < totalPages) {
            nextPage();
          } else if (!isPrevious && !isNext) {
            goToPage(pageNum);
          }
        },
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
    );
  }

  Widget _buildEllipsis() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: const Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextFormField(
      controller: controller,
      validator: (v) => (v == null || v.isEmpty) ? "$label is required" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortController.dispose();
    _horizontalScrollController.dispose();
    _searchController.dispose();
    _filterUnitNameController.dispose();
    super.dispose();
  }
}