
import 'package:flutter/material.dart';
import '../../models/qnx_admin/role_model.dart';
import '../../api/api_service.dart';

class RoleCreateScreen extends StatefulWidget {
  const RoleCreateScreen({super.key});

  @override
  State<RoleCreateScreen> createState() => _RoleCreateScreenState();
}

class _RoleCreateScreenState extends State<RoleCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _roleNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Filter Controllers
  final TextEditingController _filterRoleNameController = TextEditingController();
  final TextEditingController _filterStatusController = TextEditingController();

  bool _isActive = true;
  bool _isLoading = false;
  bool _isEdit = false;
  int? _editId;

  final RoleService _roleService = RoleService();
  final RoleUpdateService _updateService = RoleUpdateService();
  final RoleDeleteService _deleteService = RoleDeleteService();
  final RoleDetailService _detailService = RoleDetailService();

  RoleDetailModel? searchedRole;
  List<Role> allRoles = [];
  List<Role> filteredRoles = [];
  List<Role> paginatedRoles = [];

  // Pagination Variables
  int currentPage = 1;
  int itemsPerPage = 5;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 50];

  // Filter Variables
  String filterRoleName = '';

  @override
  void initState() {
    super.initState();
    loadRoles();
  }

  Future<void> loadRoles() async {
    try {
      final data = await _roleService.getRoles();
      if (mounted) {
        setState(() {
          allRoles = data;
          applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load roles")),
        );
      }
    }
  }

  // फिल्टर अप्लाय करण्यासाठी मेथड
  void applyFilters() {
    // फक्त रोल नेम फिल्टर
    filteredRoles = allRoles.where((role) {
      bool matchesName = filterRoleName.isEmpty ||
          role.roleName.toLowerCase().contains(filterRoleName.toLowerCase());
      return matchesName;
    }).toList();

    // पॅजिनेशन अप्लाय करा
    applyPagination();
  }

  // पॅजिनेशन अप्लाय करण्यासाठी मेथड
  void applyPagination() {
    if (filteredRoles.isEmpty) {
      paginatedRoles = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }

    totalPages = (filteredRoles.length / itemsPerPage).ceil();

    // करंट पेज चेक करा
    if (currentPage > totalPages) {
      currentPage = totalPages;
    }
    if (currentPage < 1) {
      currentPage = 1;
    }

    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;

    if (startIndex >= filteredRoles.length) {
      paginatedRoles = [];
    } else {
      if (endIndex > filteredRoles.length) {
        endIndex = filteredRoles.length;
      }
      paginatedRoles = filteredRoles.sublist(startIndex, endIndex);
    }

    setState(() {});
  }

  // पुढील पेज
  void nextPage() {
    if (currentPage < totalPages) {
      setState(() {
        currentPage++;
        applyPagination();
      });
    }
  }

  // मागील पेज
  void previousPage() {
    if (currentPage > 1) {
      setState(() {
        currentPage--;
        applyPagination();
      });
    }
  }

  // पेज बदला
  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() {
        currentPage = page;
        applyPagination();
      });
    }
  }

  // रो प्रति पेज बदला
  void changeItemsPerPage(int? value) {
    if (value != null) {
      setState(() {
        itemsPerPage = value;
        currentPage = 1;
        applyPagination();
      });
    }
  }

  // रीसेट फिल्टर
  void resetFilters() {
    setState(() {
      filterRoleName = '';
      _filterRoleNameController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  Future<void> searchRole() async {
    if (_searchController.text.isEmpty) return;
    try {
      int id = int.parse(_searchController.text);
      final response = await _detailService.getRoleDetail(id);
      setState(() => searchedRole = response.role);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid ID or error searching")),
      );
    }
  }

  void _editRole(Role role) {
    setState(() {
      _isEdit = true;
      _editId = role.id;
      _roleNameController.text = role.roleName;
      _descriptionController.text = role.description;
      _isActive = role.isActive;
    });
  }

  Future<void> _createRole() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    Role role = Role(
      roleName: _roleNameController.text.trim(),
      description: _descriptionController.text.trim(),
      isActive: _isActive,
    );
    try {
      final response = await _roleService.createRole(role);
      setState(() => _isLoading = false);
      if (response.role != null) {
        clearForm();
        loadRoles();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateRole() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    RoleUpdateModel model = RoleUpdateModel(
      id: _editId!,
      roleName: _roleNameController.text.trim(),
      description: _descriptionController.text.trim(),
    );
    try {
      final response = await _updateService.updateRole(model);
      setState(() {
        _isLoading = false;
        _isEdit = false;
      });
      clearForm();
      loadRoles();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRole(int id) async {
    try {
      RoleDeleteModel model = RoleDeleteModel(id: id);
      final message = await _deleteService.deleteRole(model);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      loadRoles();
    } catch (e) {}
  }

  void clearForm() {
    _roleNameController.clear();
    _descriptionController.clear();
    _isActive = true;
    _isEdit = false;
    _editId = null;
  }

  @override
  Widget build(BuildContext context)  {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Role Management",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isMobile = constraints.maxWidth < 900;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Search Header - Commented as requested
                // _buildSearchHeader(isMobile),
                // const SizedBox(height: 24),

                // Search Result Display
                if (searchedRole != null) ...[
                  _buildSearchResult(),
                  const SizedBox(height: 24),
                ],

                // Filter Section
                _buildFilterSection(),
                const SizedBox(height: 24),

                if (isMobile) ...[
                  _buildFormCard(),
                  const SizedBox(height: 24),
                  _buildCustomTable(),
                ] else ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildFormCard()),
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

  // फिल्टर सेक्शन - फक्त रोल नेम फिल्टर आणि काउंट
  Widget _buildFilterSection() {
    return Container(
      width: double.infinity, // ✅ Full width
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

      child: Row(
        children: [

          // 🔍 Filter Input → FULL WIDTH
          Expanded(
            child: TextField(
              controller: _filterRoleNameController,
              decoration: InputDecoration(
                labelText: "Filter by Role Name",
                hintText: "Enter role name...",
                prefixIcon: const Icon(
                  Icons.search,
                  size: 18,
                  color: Color(0xFF6366F1),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),

                // ❌ clear button
                suffixIcon: filterRoleName.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _filterRoleNameController.clear();
                    setState(() {
                      filterRoleName = '';
                      currentPage = 1;
                      applyFilters();
                    });
                  },
                )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  filterRoleName = value;
                  currentPage = 1;
                  applyFilters();
                });
              },
            ),
          ),

          const SizedBox(width: 12),

          // 🔄 Reset Icon
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: resetFilters,
              icon: const Icon(Icons.refresh),
              color: Colors.red,
              tooltip: "Reset",
            ),
          ),

          const SizedBox(width: 12),

          // 📊 Count badge
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${filteredRoles.length}",
              style: const TextStyle(
                color: Color(0xFF4338CA),
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );}

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
                  "${searchedRole!.roleName}",
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
                        color: searchedRole!.isActive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        searchedRole!.isActive ? "Active" : "Inactive",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: searchedRole!.isActive
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "ID: ${searchedRole!.id}",
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
                  searchedRole = null;
                  _searchController.clear();
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(bool isMobile) {
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
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Search Role by ID...",
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6366F1)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: searchRole,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Search",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
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
            Text(
              _isEdit ? "Edit Role" : "Create New Role",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),
            _buildTextField(
              _roleNameController,
              "Role Name",
              Icons.badge_outlined,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              _descriptionController,
              "Description",
              Icons.description_outlined,
              maxLines: 3,
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
                onPressed: _isLoading
                    ? null
                    : (_isEdit ? _updateRole : _createRole),
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
                  _isEdit ? "Update Role" : "Create Role",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (_isEdit)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton(
                  onPressed: clearForm,
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

  // कस्टम टेबल
  Widget _buildCustomTable() {
    // कॉलम रुंदी (पिक्सेल)
    const double idWidth = 60;
    const double roleNameWidth = 150;
    const double descriptionWidth = 200;
    const double statusWidth = 100;
    const double actionsWidth = 120;
    final double totalWidth = idWidth + roleNameWidth + descriptionWidth + statusWidth + actionsWidth;

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
          // स्क्रोल करण्याजोगे टेबल
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalWidth,
              child: Table(
                columnWidths: {
                  0: FixedColumnWidth(idWidth),
                  1: FixedColumnWidth(roleNameWidth),
                  2: FixedColumnWidth(descriptionWidth),
                  3: FixedColumnWidth(statusWidth),
                  4: FixedColumnWidth(actionsWidth),
                },
                border: TableBorder(
                  horizontalInside: BorderSide(color: Colors.grey.shade300),
                ),
                children: [
                  // हेडर
                  TableRow(
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    children: [
                      _tableHeaderCell("ID"),
                      _tableHeaderCell("Role Name"),
                      _tableHeaderCell("Description"),
                      _tableHeaderCell("Status"),
                      _tableHeaderCell("Actions"),
                    ],
                  ),
                  // डेटा रोज
                  ...paginatedRoles.asMap().entries.map((entry) {
                    int index = entry.key;
                    Role role = entry.value;
                    return TableRow(
                      decoration: BoxDecoration(
                        color: index % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC),
                      ),
                      children: [
                        _tableCell(role.id.toString()),
                        _tableCell(role.roleName),
                        _tableCell(role.description),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: role.isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                role.isActive ? "Active" : "Inactive",
                                style: TextStyle(
                                  color: role.isActive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                              onPressed: () => _editRole(role),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => _deleteRole(role.id!),
                            ),
                          ],
                        ),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // पॅजिनेशन
          if (filteredRoles.isNotEmpty) _buildPagination(),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

// हेल्पर विजेट्स
  Widget _tableHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _tableCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: Color(0xFF4B5563)),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
  Widget _buildPagination() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxWidth < 600; // मोबाइलसाठी

        if (isSmall) {
          // लहान स्क्रीन - कॉलम लेआउट
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _buildShowEntriesDropdown(),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        _getShowingText(),
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 4,
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
          // मोठी स्क्रीन - रो लेआउट (buttons right side)
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // डावीकडे Show entries + showing text
                Row(
                  children: [
                    _buildShowEntriesDropdown(),
                    const SizedBox(width: 20),
                    Text(
                      _getShowingText(),
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
                // उजवीकडे पृष्ठ बटणे
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

// हेल्पर मेथड्स - Show entries ड्रॉपडाउन आणि Showing text
  Widget _buildShowEntriesDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Text("Show: "),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: itemsPerPage,
              onChanged: changeItemsPerPage,
              items: rowsPerPageOptions.map((value) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(value.toString()),
                );
              }).toList(),
            ),
          ),
          const Text(" entries"),
        ],
      ),
    );
  }

  String _getShowingText() {
    final start = filteredRoles.isEmpty ? 0 : (currentPage - 1) * itemsPerPage + 1;
    final end = currentPage * itemsPerPage > filteredRoles.length
        ? filteredRoles.length
        : currentPage * itemsPerPage;
    return "Showing $start to $end of ${filteredRoles.length} entries";
  }
// पेज नंबर बनविण्यासाठी सामान्य हेल्पर
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

// पुढील / मागील बटणासाठी हेल्पर
  Widget _buildPageButtonPrevNext({required bool prev}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton(
        icon: Icon(prev ? Icons.chevron_left : Icons.chevron_right, size: 18),
        onPressed: prev
            ? (currentPage > 1 ? previousPage : null)
            : (currentPage < totalPages ? nextPage : null),
        color: const Color(0xFF6366F1),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(
          minWidth: 32,
          minHeight: 32,
        ),
      ),
    );
  }

  Widget _buildPageButton(int pageNum) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor:
          currentPage == pageNum ? const Color(0xFF6366F1) : Colors.white,
          foregroundColor:
          currentPage == pageNum ? Colors.white : Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          minimumSize: const Size(32, 32), // 🔥 smaller button
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        onPressed: () => goToPage(pageNum),
        child: Text(pageNum.toString()),
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
      IconData icon, {
        int maxLines = 1,
      }) {
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
    _roleNameController.dispose();
    _descriptionController.dispose();
    _horizontalScrollController.dispose();
    _searchController.dispose();
    _filterRoleNameController.dispose();
    _filterStatusController.dispose();
    super.dispose();
  }
}

// टेबल हेडर सेल साठी widget
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