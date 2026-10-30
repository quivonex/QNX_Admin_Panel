// lib/screens/qnx_admin/user_list_screen.dart
import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../models/qnx_admin/user_model.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final UserService _userService = UserService();

  final TextEditingController _searchController = TextEditingController();

  List<User> allUsers = [];
  List<User> filteredUsers = [];
  List<User> paginatedUsers = [];

  bool isLoading = true;

  int currentPage = 1;
  int itemsPerPage = 5;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  String searchQuery = '';
  String filterType = 'Name';

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      final response = await _userService.getUsers();
      if (mounted) {
        setState(() {
          // Sort by id in descending order (most recent first)
          allUsers = response.data..sort((a, b) {
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
          const SnackBar(content: Text("Failed to load users")),
        );
      }
    }
  }

  void applyFilters() {
    if (searchQuery.isEmpty) {
      filteredUsers = allUsers;
    } else {
      filteredUsers = allUsers.where((user) {
        switch (filterType) {
          case 'Name':
            return user.name.toLowerCase().contains(searchQuery.toLowerCase());
          case 'Username':
            return user.username.toLowerCase().contains(searchQuery.toLowerCase());
          case 'Email':
            return user.email.toLowerCase().contains(searchQuery.toLowerCase());
          case 'Role':
            return (user.role ?? '').toLowerCase().contains(searchQuery.toLowerCase());
          default:
            return false;
        }
      }).toList();
    }
    applyPagination();
  }

  void applyPagination() {
    if (filteredUsers.isEmpty) {
      paginatedUsers = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }

    totalPages = (filteredUsers.length / itemsPerPage).ceil();

    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;

    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;

    if (startIndex >= filteredUsers.length) {
      paginatedUsers = [];
    } else {
      endIndex = endIndex > filteredUsers.length ? filteredUsers.length : endIndex;
      paginatedUsers = filteredUsers.sublist(startIndex, endIndex);
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

  String _getCompanyNames(User user) {
    if (user.companies == null || user.companies!.isEmpty) return '-';
    return user.companies!.map((c) => c.name).join(', ');
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
          "User Management",
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFilterSection(),
            const SizedBox(height: 20),
            Expanded(child: _buildCustomTable()),
          ],
        ),
      ),
    );
  }

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
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 500;
              if (!isSmall) {
                return Row(
                  children: [
                    const Icon(Icons.filter_list, color: Color(0xFF6366F1), size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "Filter Users",
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
                        "${filteredUsers.length}",
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
                return Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.filter_list, color: Color(0xFF6366F1), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          "Filter Users",
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
                            "${filteredUsers.length}",
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
          items: <String>['Name', 'Username', 'Email', 'Role']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  Icon(
                    value == 'Name'
                        ? Icons.person
                        : value == 'Username'
                        ? Icons.account_circle
                        : value == 'Email'
                        ? Icons.email
                        : Icons.admin_panel_settings,
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
            : filterType == 'Username'
            ? "Search by username..."
            : filterType == 'Email'
            ? "Search by email..."
            : "Search by role...",
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
          // The table area – wrapped in Expanded so it takes remaining space
          Expanded(
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
                      child: filteredUsers.isEmpty
                          ? SizedBox(
                        height: 200,
                        width: 1200,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.info_outline, size: 40, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text(
                                "No users found",
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
                          1: const FixedColumnWidth(120),  // Username
                          2: const FixedColumnWidth(150),  // Name
                          3: const FixedColumnWidth(200),  // Email
                          4: const FixedColumnWidth(120),  // Phone
                          5: const FixedColumnWidth(180),  // Company Name
                          6: const FixedColumnWidth(100),  // Role
                          7: const FixedColumnWidth(90),   // Status
                        },
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                            ),
                            children: [
                              _tableHeader("SR No"),
                              _tableHeader("Username"),
                              _tableHeader("Name"),
                              _tableHeader("Email"),
                              _tableHeader("Phone"),
                              _tableHeader("Company Name"),
                              _tableHeader("Role"),
                              _tableHeader("Status"),
                            ],
                          ),
                          ...paginatedUsers.asMap().entries.map((entry) {
                            int index = entry.key;
                            User user = entry.value;
                            final int srNo = filteredUsers.length - ((currentPage - 1) * itemsPerPage + index);
                            return TableRow(
                              decoration: BoxDecoration(
                                color: index % 2 == 0
                                    ? Colors.white
                                    : const Color(0xFFF8FAFC),
                              ),
                              children: [
                                _tableCell(srNo.toString()),
                                _tableCell(user.username),
                                _tableCell(user.name),
                                _tableCell(user.email),
                                _tableCell(user.phoneNumber),
                                _tableCell(_getCompanyNames(user)),
                                _tableCell(user.role ?? "-"),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: user.isActive
                                            ? const Color(0xFFDCFCE7)
                                            : const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        user.isActive ? "Active" : "Inactive",
                                        style: TextStyle(
                                          color: user.isActive
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
          ),
          const SizedBox(height: 20),
          // Pagination section (no overflow because it's not being compressed)
          if (filteredUsers.isNotEmpty)
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 700) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Showing ${filteredUsers.isEmpty ? 0 : (currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filteredUsers.length ? filteredUsers.length : currentPage * itemsPerPage} of ${filteredUsers.length}",
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 4,
                          children: _buildMobilePagination(),
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
                          "Showing ${filteredUsers.isEmpty ? 0 : (currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filteredUsers.length ? filteredUsers.length : currentPage * itemsPerPage} of ${filteredUsers.length} entries",
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

  List<Widget> _buildMobilePagination() {
    List<Widget> widgets = [];

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
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ),
    );

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
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ),
      );
    }

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
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ),
    );

    return widgets;
  }

  List<Widget> _buildDesktopPagination() {
    List<Widget> widgets = [];

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
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ),
    );

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
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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