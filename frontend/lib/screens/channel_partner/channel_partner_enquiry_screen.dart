// lib/screens/channel_partner/channel_partner_enquiry_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import '../../models/channel_partner/channel_partner_enquiry_model.dart';
import '../../api/realestate_service.dart';
import '../../screens/real_estate/schedule_meeting_form.dart';   // ✅ ADDED

class ChannelPartnerEnquiryScreen extends StatefulWidget {
  const ChannelPartnerEnquiryScreen({super.key});

  @override
  State<ChannelPartnerEnquiryScreen> createState() =>
      _ChannelPartnerEnquiryScreenState();
}

class _ChannelPartnerEnquiryScreenState
    extends State<ChannelPartnerEnquiryScreen> {
  // ==================== STATE ====================
  final ChannelPartnerEnquiryService _service = ChannelPartnerEnquiryService();
  final TextEditingController _searchController = TextEditingController();

  List<ChannelPartnerEnquiry> _allEnquiries = [];
  List<ChannelPartnerEnquiry> _filteredEnquiries = [];
  List<ChannelPartnerEnquiry> _paginatedEnquiries = [];

  ChannelPartnerInfo? _channelPartnerInfo;

  bool _isLoading = true;
  String? _errorMessage;

  String _searchQuery = '';
  String _filterStatus = 'All';

  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalPages = 1;
  final List<int> _rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  // Scroll controllers
  final LinkedScrollControllerGroup _linkedControllers =
  LinkedScrollControllerGroup();
  late final ScrollController _headerHorizontalController;
  late final ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  // Theme Colors
  static const Color _primaryBlue = Color(0xFF4158D0);
  static const Color _primaryPurple = Color(0xFFC850C0);
  static const Color _bgLight = Color(0xFFF5F7FA);
  static const Color _cardWhite = Colors.white;

  // Column widths
  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(50), // SR No
    1: FixedColumnWidth(150), // Customer
    2: FixedColumnWidth(160), // Contact
    3: FixedColumnWidth(180), // Property
    4: FixedColumnWidth(90), // Type
    5: FixedColumnWidth(100), // City
    6: FixedColumnWidth(100), // Status
    7: FixedColumnWidth(90), // Date
    8: FixedColumnWidth(70), // Actions
  };

  // Header labels
  final List<String> headerLabels = [
    "SR No",
    "Customer",
    "Contact",
    "Property",
    "Type",
    "City",
    "Status",
    "Date",
    "Actions"
  ];

  @override
  void initState() {
    super.initState();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadEnquiries();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerHorizontalController.dispose();
    _rowsHorizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  // ==================== API CALL ====================
  Future<void> _loadEnquiries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ??
          prefs.getString('token') ??
          prefs.getString('auth_token');

      final request = ChannelPartnerEnquiryRequest(
        status: _filterStatus == 'All' ? null : _filterStatus,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      final response = await _service.fetchChannelPartnerEnquiries(
        request: request,
        authToken: token,
      );

      if (mounted) {
        setState(() {
          _allEnquiries = response.data;
          _channelPartnerInfo = response.channelPartner;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    }
  }

  // ==================== FILTER & PAGINATION ====================
  void _applyFilters() {
    if (_searchQuery.isEmpty && _filterStatus == 'All') {
      _filteredEnquiries = List.from(_allEnquiries);
    } else {
      _filteredEnquiries = _allEnquiries.where((e) {
        final matchesSearch = _searchQuery.isEmpty ||
            e.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            e.customerEmail.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            e.customerMobile.contains(_searchQuery) ||
            (e.propertyDetails?.title
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ??
                false) ||
            (e.propertyDetails?.city
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ??
                false);

        final matchesStatus =
            _filterStatus == 'All' || e.status == _filterStatus;

        return matchesSearch && matchesStatus;
      }).toList();
    }
    _applyPagination();
  }

  void _applyPagination() {
    if (_filteredEnquiries.isEmpty) {
      _paginatedEnquiries = [];
      _totalPages = 1;
      _currentPage = 1;
      if (mounted) setState(() {});
      return;
    }
    _totalPages = (_filteredEnquiries.length / _itemsPerPage).ceil();
    if (_currentPage > _totalPages) _currentPage = _totalPages;
    if (_currentPage < 1) _currentPage = 1;
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage > _filteredEnquiries.length
        ? _filteredEnquiries.length
        : start + _itemsPerPage;
    _paginatedEnquiries = _filteredEnquiries.sublist(start, end);
    if (mounted) setState(() {});
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
        _applyPagination();
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _applyPagination();
      });
    }
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
        _applyPagination();
      });
    }
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

  void _changeItemsPerPage(int? value) {
    if (value != null) {
      setState(() {
        _itemsPerPage = value;
        _currentPage = 1;
        _applyPagination();
      });
    }
  }

  // ==================== SCHEDULE MEETING POPUP ====================
  // ✅ NEW METHOD: Opens ScheduleMeetingForm inside a popup dialog
  void _showScheduleMeetingPopup(ChannelPartnerEnquiry enquiry) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 700,
            maxHeight: MediaQuery.of(context).size.height * 0.92,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryBlue, _primaryPurple],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
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
                        child: const Icon(Icons.calendar_month,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Schedule Meeting',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Enquiry ID: #${enquiry.id}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.85),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close,
                              color: Colors.white, size: 20),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 20,
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Body
                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ScheduleMeetingForm(
                      enquiryId: enquiry.id,
                      customerName: enquiry.customerName,
                      propertyTitle: enquiry.propertyDetails?.title,
                      isInsideDialog: true,   // ✅ pass this flag
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

  // ==================== POPUP DETAILS ====================
  void _showEnquiryDetails(ChannelPartnerEnquiry enquiry) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 700),
          decoration: BoxDecoration(
            color: _cardWhite,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryBlue, _primaryPurple],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
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
                      child: const Icon(Icons.support_agent,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Enquiry Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: #${enquiry.id}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [_buildStatusChip(enquiry.status)]),
                      const SizedBox(height: 20),

                      // Customer Information
                      _buildSection(
                        title: 'Customer Information',
                        icon: Icons.person,
                        children: [
                          _buildInfoRow('Name', enquiry.customerName),
                          _buildInfoRow('Email', enquiry.customerEmail),
                          _buildInfoRow('Mobile', enquiry.customerMobile),
                          _buildInfoRow('Created', enquiry.formattedDateTime),
                          if (enquiry.assignedAt != null)
                            _buildInfoRow('Assigned',
                                _formatDateTime(enquiry.assignedAt!)),
                        ],
                      ),

                      // Message
                      if (enquiry.message.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _buildSection(
                          title: 'Message',
                          icon: Icons.message,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                enquiry.message,
                                style: const TextStyle(fontSize: 13, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Property Details
                      if (enquiry.propertyDetails != null) ...[
                        const SizedBox(height: 16),
                        _buildSection(
                          title: 'Property Details',
                          icon: Icons.home_work,
                          children: [
                            if (enquiry
                                .propertyDetails!.primaryImage.isNotEmpty)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  enquiry.propertyDetails!.primaryImage,
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 180,
                                    color: Colors.grey[200],
                                    child: const Center(
                                        child: Icon(Icons.broken_image,
                                            size: 50)),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            _buildInfoRow('Title', enquiry.propertyDetails!.title),
                            _buildInfoRow('Type',
                                enquiry.propertyDetails!.propertyTypeDisplay),
                            _buildInfoRow('Transaction',
                                enquiry.propertyDetails!.transactionTypeDisplay),
                            _buildInfoRow('City', enquiry.propertyDetails!.city),
                            _buildInfoRow('Area', enquiry.propertyDetails!.area),
                            _buildInfoRow('Address',
                                enquiry.propertyDetails!.address),
                            _buildInfoRow('Landmark',
                                enquiry.propertyDetails!.landmark),
                            _buildInfoRow('Pincode',
                                enquiry.propertyDetails!.pincode),
                            if (enquiry.propertyDetails!.reraNumber != null &&
                                enquiry.propertyDetails!.reraNumber!.isNotEmpty)
                              _buildInfoRow('RERA',
                                  enquiry.propertyDetails!.reraNumber!),
                            _buildInfoRow('Completion',
                                '${enquiry.propertyDetails!.completionPercentage}%'),
                            _buildInfoRow('Under Construction',
                                enquiry.propertyDetails!.isUnderConstruction
                                    ? 'Yes'
                                    : 'No'),
                            if (enquiry.propertyDetails!.amenityDetails.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              const Text(
                                'Amenities:',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: enquiry
                                    .propertyDetails!.amenityDetails
                                    .map((a) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _primaryBlue.withOpacity(0.1),
                                    borderRadius:
                                    BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    a.name,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: _primaryBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ))
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ],

                      // ✅ SCHEDULE MEETING BUTTON
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_primaryBlue, _primaryPurple],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryBlue.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context); // close details popup
                            _showScheduleMeetingPopup(enquiry); // open form popup
                          },
                          icon: const Icon(Icons.calendar_month,
                              color: Colors.white, size: 20),
                          label: const Text(
                            'Schedule Meeting',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
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
    );
  }

  String _formatDateTime(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_primaryBlue, _primaryPurple]),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(title,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: children),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    switch (status.toLowerCase()) {
      case 'assigned':
        color = _primaryBlue;
        icon = Icons.assignment_ind;
        break;
      case 'contacted':
        color = const Color(0xFF9B59B6);
        icon = Icons.phone_in_talk;
        break;
      case 'pending':
        color = const Color(0xFFF39C12);
        icon = Icons.pending;
        break;
      case 'completed':
      case 'closed':
        color = const Color(0xFF2ECC71);
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = const Color(0xFFE74C3C);
        icon = Icons.cancel;
        break;
      default:
        color = _primaryPurple;
        icon = Icons.info;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            status.toUpperCase(),
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: _bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_primaryBlue, _primaryPurple]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.question_answer,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Channel Partner Enquiries',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                if (_channelPartnerInfo != null)
                  Text(
                    '${_channelPartnerInfo!.name} • ${_channelPartnerInfo!.cpCode}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _primaryBlue),
            onPressed: _loadEnquiries,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator(color: _primaryBlue))
          : _errorMessage != null
          ? _buildErrorWidget()
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildFilterSection(isMobile),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                children: [
                  // Table Header
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                      border:
                      Border.all(color: Colors.grey.shade300),
                    ),
                    child: SingleChildScrollView(
                      controller: _headerHorizontalController,
                      scrollDirection: Axis.horizontal,
                      child: Table(
                        border: TableBorder(
                          horizontalInside: BorderSide(
                              color: Colors.grey.shade300),
                          verticalInside: BorderSide(
                              color: Colors.grey.shade300),
                          top: BorderSide(
                              color: Colors.grey.shade300),
                          bottom: BorderSide(
                              color: Colors.grey.shade300),
                        ),
                        columnWidths: columnWidths,
                        children: [
                          TableRow(
                            children: headerLabels
                                .map((label) => _tableHeader(label))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Table Rows
                  Expanded(
                    child: _filteredEnquiries.isEmpty
                        ? _buildEmptyState()
                        : SingleChildScrollView(
                      controller: _verticalController,
                      child: SingleChildScrollView(
                        controller: _rowsHorizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          border: TableBorder.all(
                              color: Colors.grey.shade300,
                              width: 1),
                          columnWidths: columnWidths,
                          children: List.generate(
                            _paginatedEnquiries.length,
                                (rowIndex) {
                              final e =
                              _paginatedEnquiries[rowIndex];
                              final isEven = rowIndex % 2 == 0;
                              final srNo =
                                  (_currentPage - 1) *
                                      _itemsPerPage +
                                      rowIndex +
                                      1;

                              return TableRow(
                                decoration: BoxDecoration(
                                  color: isEven
                                      ? Colors.white
                                      : const Color(0xFFF8FAFC),
                                ),
                                children: [
                                  _tableCell(srNo.toString()),
                                  _tableCell(e.customerName,
                                      isBold: true),
                                  _buildContactCell(e),
                                  _tableCell(
                                      e.propertyDetails?.title ??
                                          '-'),
                                  _tableCell(e
                                      .propertyDetails
                                      ?.propertyTypeDisplay ??
                                      '-'),
                                  _tableCell(
                                      e.propertyDetails?.city ??
                                          '-'),
                                  _buildStatusCell(e.status),
                                  _tableCell(e.formattedDate),
                                  _buildActionCell(e),
                                ],
                              );
                            },
                          ),
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
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child:
              const Icon(Icons.error_outline, color: Colors.red, size: 50),
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load enquiries',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadEnquiries,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox, size: 50, color: _primaryBlue),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Enquiries Found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No channel partner enquiries available',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ==================== FILTER SECTION ====================
  Widget _buildFilterSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(12),
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
          if (isMobile) ...[
            Row(
              children: [
                Container(
                  width: 140,
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterStatus,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Color(0xFF6366F1)),
                      style: const TextStyle(
                          color: Color(0xFF1E293B), fontSize: 13),
                      isExpanded: true,
                      onChanged: (value) {
                        setState(() {
                          _filterStatus = value!;
                          _currentPage = 1;
                          _applyFilters();
                        });
                      },
                      items: [
                        'All',
                        'assigned',
                        'contacted',
                        'pending',
                        'completed',
                        'rejected'
                      ].map<DropdownMenuItem<String>>((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Icon(
                                _getStatusIcon(value),
                                size: 14,
                                color: const Color(0xFF6366F1),
                              ),
                              const SizedBox(width: 8),
                              Text(value == 'All'
                                  ? 'All Status'
                                  : value[0].toUpperCase() +
                                  value.substring(1)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search...",
                        prefixIcon: const Icon(Icons.search,
                            size: 16, color: Color(0xFF6366F1)),
                        border: InputBorder.none,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
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
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _currentPage = 1;
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text("Total: ${_filteredEnquiries.length}",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.refresh),
                      color: Colors.red,
                      tooltip: "Reset",
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Container(
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
                      value: _filterStatus,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Color(0xFF6366F1)),
                      style: const TextStyle(
                          color: Color(0xFF1E293B), fontSize: 13),
                      isExpanded: true,
                      onChanged: (value) {
                        setState(() {
                          _filterStatus = value!;
                          _currentPage = 1;
                          _applyFilters();
                        });
                      },
                      items: [
                        'All',
                        'assigned',
                        'contacted',
                        'pending',
                        'completed',
                        'rejected'
                      ].map<DropdownMenuItem<String>>((value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Icon(
                                _getStatusIcon(value),
                                size: 14,
                                color: const Color(0xFF6366F1),
                              ),
                              const SizedBox(width: 8),
                              Text(value == 'All'
                                  ? 'All Status'
                                  : value[0].toUpperCase() +
                                  value.substring(1)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText:
                        "Search by name, email, mobile, property...",
                        prefixIcon: const Icon(Icons.search,
                            size: 16, color: Color(0xFF6366F1)),
                        border: InputBorder.none,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
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
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                          _currentPage = 1;
                          _applyFilters();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    Text("Total: ${_filteredEnquiries.length}",
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.grey)),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: _resetFilters,
                      icon: const Icon(Icons.refresh),
                      color: Colors.red,
                      tooltip: "Reset",
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'all':
        return Icons.list;
      case 'assigned':
        return Icons.assignment_ind;
      case 'contacted':
        return Icons.phone_in_talk;
      case 'pending':
        return Icons.pending;
      case 'completed':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  // ==================== TABLE CELLS ====================
  Widget _tableHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            color: Color(0xFF1E293B)),
      ),
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
        style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 10),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildContactCell(ChannelPartnerEnquiry e) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.phone, size: 10, color: _primaryBlue),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  e.customerMobile,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.email, size: 10, color: _primaryPurple),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  e.customerEmail,
                  style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCell(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'assigned':
        color = _primaryBlue;
        break;
      case 'contacted':
        color = const Color(0xFF9B59B6);
        break;
      case 'pending':
        color = const Color(0xFFF39C12);
        break;
      case 'completed':
      case 'closed':
        color = const Color(0xFF2ECC71);
        break;
      case 'rejected':
        color = const Color(0xFFE74C3C);
        break;
      default:
        color = _primaryPurple;
    }
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildActionCell(ChannelPartnerEnquiry e) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(2),
      child: IconButton(
        icon: const Icon(Icons.visibility, color: _primaryBlue, size: 18),
        onPressed: () => _showEnquiryDetails(e),
        tooltip: 'View Details',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
    );
  }

  // ==================== PAGINATION ====================
  Widget _buildPagination() {
    if (_filteredEnquiries.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final Widget showEntriesRow = Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text("Show ", style: TextStyle(fontSize: 12)),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButton<int>(
                  value: _itemsPerPage,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  style: const TextStyle(fontSize: 12),
                  items: _rowsPerPageOptions
                      .map((e) => DropdownMenuItem(
                      value: e, child: Text(e.toString())))
                      .toList(),
                  onChanged: _changeItemsPerPage,
                ),
              ),
              const Text(" entries", style: TextStyle(fontSize: 12)),
              const SizedBox(width: 12),
              Text(
                "Showing ${(_currentPage - 1) * _itemsPerPage + 1} to "
                    "${_currentPage * _itemsPerPage > _filteredEnquiries.length ? _filteredEnquiries.length : _currentPage * _itemsPerPage} "
                    "of ${_filteredEnquiries.length}",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          );

          final List<Widget> pageButtons = [
            _compactPageButton(
                icon: Icons.chevron_left,
                onTap: _currentPage > 1 ? _previousPage : null),
            if (_totalPages <= 5)
              ...List.generate(
                  _totalPages, (index) => _compactPageNumber(index + 1))
            else if (_currentPage <= 3) ...[
              ...List.generate(4, (index) => _compactPageNumber(index + 1)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...",
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              _compactPageNumber(_totalPages),
            ] else if (_currentPage >= _totalPages - 2) ...[
              _compactPageNumber(1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...",
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              ...List.generate(4,
                      (index) => _compactPageNumber(_totalPages - 3 + index)),
            ] else ...[
              _compactPageNumber(1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...",
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              _compactPageNumber(_currentPage - 1),
              _compactPageNumber(_currentPage),
              _compactPageNumber(_currentPage + 1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...",
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              _compactPageNumber(_totalPages),
            ],
            _compactPageButton(
                icon: Icons.chevron_right,
                onTap: _currentPage < _totalPages ? _nextPage : null),
          ];

          final Widget paginationRow = Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: pageButtons,
          );

          if (constraints.maxWidth < 700) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                showEntriesRow,
                const SizedBox(height: 8),
                paginationRow,
              ],
            );
          } else {
            return SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [showEntriesRow, paginationRow],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _compactPageButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
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
    final isSelected = _currentPage == pageNum;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: () => _goToPage(pageNum),
        borderRadius: BorderRadius.circular(6),
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
}