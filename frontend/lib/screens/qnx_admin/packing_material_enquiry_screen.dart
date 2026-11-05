import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api_service.dart';
import '../../models/qnx_admin/packing_material_enquiry_model.dart';

class PackingMaterialEnquiryScreen extends StatefulWidget {
  const PackingMaterialEnquiryScreen({super.key});

  @override
  State<PackingMaterialEnquiryScreen> createState() =>
      _PackingMaterialEnquiryScreenState();
}

class _PackingMaterialEnquiryScreenState
    extends State<PackingMaterialEnquiryScreen> {
  final PackingMaterialEnquiryService _service = PackingMaterialEnquiryService();

  List<PackingMaterialEnquiry> _enquiries = [];
  List<PackingMaterialEnquiry> _filtered = [];
  List<PackingMaterialEnquiry> _paginated = [];

  bool _isLoading = true;
  String _errorMessage = '';
  int? _userId;

  // Search / filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'All';

  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalPages = 1;
  final List<int> _rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetch();
  }

  Future<void> _loadUserIdAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    final userIdStr = prefs.getString('user_id');
    _userId = int.tryParse(userIdStr ?? '');
    await _fetchEnquiries();
  }

  Future<void> _fetchEnquiries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final response = await _service.fetchEnquiries(userId: _userId);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (response.success) {
        _enquiries = response.data;
        _applyFilters();
      } else {
        _errorMessage = response.message;
        _enquiries = [];
        _filtered = [];
        _paginated = [];
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _service.dispose();
    super.dispose();
  }

  // ==================== FILTER + PAGINATION ====================
  void _applyFilters() {
    final query = _searchQuery.trim().toLowerCase();
    _filtered = _enquiries.where((e) {
      final matchesStatus =
          _filterStatus == 'All' || e.status.toUpperCase() == _filterStatus.toUpperCase();

      final matchesSearch = query.isEmpty ||
          e.enquiryNumber.toLowerCase().contains(query) ||
          e.customerName.toLowerCase().contains(query) ||
          e.companyName.toLowerCase().contains(query) ||
          e.customerEmail.toLowerCase().contains(query) ||
          e.customerPhone.toLowerCase().contains(query);

      return matchesStatus && matchesSearch;
    }).toList();

    _applyPagination();
  }

  void _applyPagination() {
    if (_filtered.isEmpty) {
      _paginated = [];
      _totalPages = 1;
      _currentPage = 1;
      setState(() {});
      return;
    }
    _totalPages = (_filtered.length / _itemsPerPage).ceil();
    if (_currentPage > _totalPages) _currentPage = _totalPages;
    if (_currentPage < 1) _currentPage = 1;
    final start = (_currentPage - 1) * _itemsPerPage;
    final end =
    (start + _itemsPerPage) > _filtered.length ? _filtered.length : start + _itemsPerPage;
    _paginated = _filtered.sublist(start, end);
    setState(() {});
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _filterStatus = 'All';
      _searchController.clear();
      _currentPage = 1;
      _applyFilters();
    });
  }

  // ==================== COLORS / ICONS ====================
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFF39C12);
      case 'APPROVED':
        return const Color(0xFF2ECC71);
      case 'REJECTED':
        return const Color(0xFFE74C3C);
      case 'COMPLETED':
        return const Color(0xFF3498DB);
      default:
        return const Color(0xFF95A5A6);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Icons.pending_actions;
      case 'APPROVED':
        return Icons.check_circle;
      case 'REJECTED':
        return Icons.cancel;
      case 'COMPLETED':
        return Icons.done_all;
      default:
        return Icons.info_outline;
    }
  }

  // ==================== POPUP DIALOG (unchanged) ====================
  void _showEnquiryPopup(PackingMaterialEnquiry enquiry) {
    final statusColor = _getStatusColor(enquiry.status);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          insetPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 750),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ===== HEADER =====
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 12, 18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.inventory_2,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              enquiry.enquiryNumber,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              enquiry.formattedDate,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getStatusIcon(enquiry.status),
                                size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              enquiry.status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),

                // ===== BODY =====
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(
                            Icons.business_center, 'Company & Customer'),
                        const SizedBox(height: 10),
                        _buildDetailCard([
                          _buildDetailRow(Icons.business, 'Company',
                              enquiry.companyName),
                          _buildDetailRow(Icons.person_outline, 'Customer',
                              enquiry.customerName),
                          _buildDetailRow(Icons.email_outlined, 'Email',
                              enquiry.customerEmail),
                          _buildDetailRow(Icons.phone_outlined, 'Phone',
                              enquiry.customerPhone),
                        ]),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Icon(Icons.inventory_2,
                                size: 18, color: Color(0xFF4158D0)),
                            const SizedBox(width: 6),
                            const Text(
                              'Requested Items',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF4158D0)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${enquiry.totalItems}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4158D0),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...enquiry.items
                            .map((item) => _buildItemTile(item))
                            .toList(),
                        if (enquiry.description.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _buildSectionTitle(
                              Icons.description_outlined, 'Description'),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: const Color(0xFFE2E8F0)),
                            ),
                            child: Text(
                              enquiry.description,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ===== FOOTER =====
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.grey[200]!, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF4158D0)),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF4158D0)),
          const SizedBox(width: 10),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(PackingMaterialItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF4158D0),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.materialName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${item.quantityText} ${item.unit}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          if (item.size != null && item.size!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.straighten, size: 12, color: Colors.grey[500]),
                const SizedBox(width: 6),
                Text(
                  'Size: ${item.size}',
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                ),
              ],
            ),
          ],
          if (item.description != null && item.description!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.description!,
                style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ================== SCREEN BODY ==================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5FA),
      appBar: AppBar(
        title: const Text(
          'Packing Material Enquiries',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _fetchEnquiries,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF4158D0)),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: Color(0xFFE74C3C)),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchEnquiries,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4158D0),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // ✅ FILTER + SEARCH BAR
        _buildFilterSection(),
        const SizedBox(height: 8),
        // ✅ GRID
        Expanded(
          child: _filtered.isEmpty
              ? _buildEmptyState()
              : LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int crossAxisCount;
              double childAspectRatio;
              if (width >= 1600) {
                crossAxisCount = 5;
                childAspectRatio = 1.10;
              } else if (width >= 1280) {
                crossAxisCount = 4;
                childAspectRatio = 1.05;
              } else if (width >= 1024) {
                crossAxisCount = 3;
                childAspectRatio = 1.00;
              } else if (width >= 700) {
                crossAxisCount = 2;
                childAspectRatio = 1.05;
              } else {
                crossAxisCount = 1;
                childAspectRatio = 1.90;
              }
              return RefreshIndicator(
                onRefresh: _fetchEnquiries,
                color: const Color(0xFF4158D0),
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                  physics: const AlwaysScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemCount: _paginated.length,
                  itemBuilder: (context, index) {
                    return _buildEnquiryCard(_paginated[index], index);
                  },
                ),
              );
            },
          ),
        ),
        // ✅ PAGINATION
        _buildPagination(),
      ],
    );
  }

  // ================== FILTER / SEARCH ==================
  Widget _buildFilterSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 700;

          final filterDropdown = Container(
            height: 42,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterStatus,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: Color(0xFF4158D0)),
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF1E293B)),
                isExpanded: true,
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _filterStatus = v;
                    _currentPage = 1;
                    _applyFilters();
                  });
                },
                items: const ['All', 'PENDING', 'APPROVED', 'REJECTED', 'COMPLETED']
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e == 'All' ? 'All' : _statusLabel(e),
                    style: const TextStyle(fontSize: 13),
                  ),
                ))
                    .toList(),
              ),
            ),
          );

          final searchField = Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText:
                'Search by enquiry / customer / company / email / phone',
                hintStyle: TextStyle(
                    fontSize: 12.5, color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search,
                    size: 18, color: Color(0xFF4158D0)),
                border: InputBorder.none,
                contentPadding:
                const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 16),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                      _currentPage = 1;
                      _applyFilters();
                    });
                  },
                )
                    : null,
              ),
              onChanged: (v) {
                setState(() {
                  _searchQuery = v;
                  _currentPage = 1;
                  _applyFilters();
                });
              },
            ),
          );

          final resetButton = IconButton(
            tooltip: 'Reset filters',
            onPressed: _resetFilters,
            icon: const Icon(Icons.refresh, color: Colors.red, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          );

          final totalLabel = Text(
            'Total: ${_filtered.length}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
              color: Colors.grey[700],
            ),
          );

          if (isCompact) {
            return Column(
              children: [
                Row(
                  children: [
                    SizedBox(width: 130, child: filterDropdown),
                    const SizedBox(width: 10),
                    Expanded(child: searchField),
                    const SizedBox(width: 6),
                    resetButton,
                  ],
                ),
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: totalLabel),
              ],
            );
          }

          return Row(
            children: [
              SizedBox(width: 150, child: filterDropdown),
              const SizedBox(width: 10),
              Expanded(child: searchField),
              const SizedBox(width: 10),
              totalLabel,
              const SizedBox(width: 6),
              resetButton,
            ],
          );
        },
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return 'Pending';
      case 'APPROVED':
        return 'Approved';
      case 'REJECTED':
        return 'Rejected';
      case 'COMPLETED':
        return 'Completed';
      default:
        return status;
    }
  }

  // ================== PAGINATION ==================
  Widget _buildPagination() {
    if (_filtered.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 700;

          final perPage = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Show',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[700])),
              const SizedBox(width: 6),
              Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _itemsPerPage,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 16),
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF1E293B)),
                    items: _rowsPerPageOptions
                        .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text('$e'),
                    ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _itemsPerPage = v;
                        _currentPage = 1;
                        _applyPagination();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('entries',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[700])),
            ],
          );

          final pageNumbers = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _compactPageBtn(
                icon: Icons.chevron_left,
                onTap: _currentPage > 1
                    ? () {
                  setState(() {
                    _currentPage--;
                    _applyPagination();
                  });
                }
                    : null,
              ),
              if (_totalPages <= 5)
                ...List.generate(_totalPages, (i) => _pageNum(i + 1))
              else if (_currentPage <= 3) ...[
                ...List.generate(4, (i) => _pageNum(i + 1)),
                _ellipsis(),
                _pageNum(_totalPages),
              ] else if (_currentPage >= _totalPages - 2) ...[
                _pageNum(1),
                _ellipsis(),
                ...List.generate(
                    4, (i) => _pageNum(_totalPages - 3 + i)),
              ] else ...[
                _pageNum(1),
                _ellipsis(),
                _pageNum(_currentPage - 1),
                _pageNum(_currentPage),
                _pageNum(_currentPage + 1),
                _ellipsis(),
                _pageNum(_totalPages),
              ],
              _compactPageBtn(
                icon: Icons.chevron_right,
                onTap: _currentPage < _totalPages
                    ? () {
                  setState(() {
                    _currentPage++;
                    _applyPagination();
                  });
                }
                    : null,
              ),
            ],
          );

          final showingLabel = Text(
            'Showing ${(_currentPage - 1) * _itemsPerPage + 1}–'
                '${_currentPage * _itemsPerPage > _filtered.length ? _filtered.length : _currentPage * _itemsPerPage}'
                ' of ${_filtered.length}',
            style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
          );

          if (isCompact) {
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [perPage, showingLabel],
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: pageNumbers,
                ),
              ],
            );
          }

          return Row(
            children: [
              perPage,
              const SizedBox(width: 12),
              showingLabel,
              const Spacer(),
              pageNumbers,
            ],
          );
        },
      ),
    );
  }

  Widget _compactPageBtn({required IconData icon, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: onTap,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
        color: onTap != null ? const Color(0xFF4158D0) : Colors.grey[400],
      ),
    );
  }

  Widget _pageNum(int num) {
    final selected = _currentPage == num;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentPage = num;
          _applyPagination();
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF4158D0) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected ? const Color(0xFF4158D0) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          '$num',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }

  Widget _ellipsis() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Text('...',
          style: TextStyle(fontSize: 12, color: Colors.grey)),
    );
  }

  // ================== EMPTY STATE ==================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.inventory_2_outlined,
                size: 56, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Packing Material Enquiries',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            _searchQuery.isNotEmpty || _filterStatus != 'All'
                ? 'No results match your search or filter'
                : 'New enquiries will appear here',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (_searchQuery.isNotEmpty || _filterStatus != 'All') ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }

  // ================== CARD (Redesigned) ==================
  Widget _buildEnquiryCard(PackingMaterialEnquiry enquiry, int index) {
    final statusColor = _getStatusColor(enquiry.status);
    final initial = enquiry.customerName.isNotEmpty
        ? enquiry.customerName[0].toUpperCase()
        : '?';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showEnquiryPopup(enquiry),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: statusColor.withOpacity(0.10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== COLORED TOP BAR =====
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [statusColor, statusColor.withOpacity(0.5)],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ==== HEADER ROW ====
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4158D0),
                                    Color(0xFFC850C0)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    enquiry.enquiryNumber,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    enquiry.formattedDate,
                                    style: const TextStyle(
                                      fontSize: 9.5,
                                      color: Colors.grey,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Status chip
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_getStatusIcon(enquiry.status),
                                      size: 9, color: statusColor),
                                  const SizedBox(width: 3),
                                  Text(
                                    enquiry.status,
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // ==== DIVIDER ====
                        Container(
                          height: 1,
                          color: const Color(0xFFF1F5F9),
                        ),
                        const SizedBox(height: 8),
                        // ==== COMPANY ====
                        _iconRow(
                          icon: Icons.business,
                          text: enquiry.companyName,
                          color: const Color(0xFF0EA5E9),
                        ),
                        const SizedBox(height: 4),
                        // ==== CUSTOMER ====
                        _iconRow(
                          icon: Icons.person_outline,
                          text: enquiry.customerName,
                          color: const Color(0xFF8B5CF6),
                          bold: true,
                        ),
                        const SizedBox(height: 4),
                        // ==== PHONE ====
                        _iconRow(
                          icon: Icons.phone_outlined,
                          text: enquiry.customerPhone,
                          color: const Color(0xFF10B981),
                        ),
                        const Spacer(),
                        // ==== FOOTER: items ====
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.inventory_2_outlined,
                                  size: 12, color: Color(0xFF4158D0)),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  '${enquiry.totalItems} item${enquiry.totalItems > 1 ? "s" : ""}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4158D0),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios,
                                  size: 9, color: Colors.grey),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconRow({
    required IconData icon,
    required String text,
    required Color color,
    bool bold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text.isEmpty ? '-' : text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              color: const Color(0xFF334155),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}