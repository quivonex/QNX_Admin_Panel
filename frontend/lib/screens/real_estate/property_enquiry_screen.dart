// lib/screens/real_estate/property_enquiry_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'dart:html' as html;

import '../../api/realestate_service.dart';
import '../../models/real_estate/property_enquiry_model.dart';

import '../../models/real_estate/marketing_partner_model.dart';

class PropertyEnquiryScreen extends StatefulWidget {
  const PropertyEnquiryScreen({super.key});

  @override
  State<PropertyEnquiryScreen> createState() => _PropertyEnquiryScreenState();
}

class _PropertyEnquiryScreenState extends State<PropertyEnquiryScreen> {
  final PropertyEnquiryService _service = PropertyEnquiryService();


  List<PropertyEnquiryData> allEnquiries = [];
  List<PropertyEnquiryData> filteredEnquiries = [];
  List<PropertyEnquiryData> paginatedEnquiries = [];



  bool isLoading = true;
  bool _isAssigning = false;

  // Search & Filter
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String filterType = 'Customer Name';
  String filterStatus = 'All';

  // Pagination
  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  // Scroll Controllers
  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  // Column Widths - Added Assign column
  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(60),   // SR No
    1: FixedColumnWidth(120),  // Customer
    2: FixedColumnWidth(140),  // Email
    3: FixedColumnWidth(100),  // Mobile
    4: FixedColumnWidth(140),  // Property
    5: FixedColumnWidth(100),  // Status
    6: FixedColumnWidth(100),  // Created
    7: FixedColumnWidth(70),   // View
    8: FixedColumnWidth(80),   // Assign
  };

  final List<String> headerLabels = [
    "SR No", "Customer", "Email", "Mobile", "Property", "Status", "Created", "View", "Assign"
  ];

  static const Color _premiumPrimary = Color(0xFF4158D0);
  static const Color _premiumSecondary = Color(0xFFC850C0);

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();
    loadEnquiries();

  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerHorizontalController.dispose();
    _rowsHorizontalController.dispose();
    _verticalController.dispose();
    _service.dispose();

    super.dispose();
  }

  Future<void> loadEnquiries() async {
    try {
      final response = await _service.getEnquiries();
      if (mounted) {
        setState(() {
          allEnquiries = response.data;
          allEnquiries.sort((a, b) => b.id.compareTo(a.id));
          applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load enquiries: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }



  void applyFilters() {
    filteredEnquiries = allEnquiries.where((e) {
      // Search filter
      bool matchesSearch = true;
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        switch (filterType) {
          case 'Customer Name':
            matchesSearch = e.customerName.toLowerCase().contains(query);
            break;
          case 'Email':
            matchesSearch = e.customerEmail.toLowerCase().contains(query);
            break;
          case 'Mobile':
            matchesSearch = e.customerMobile.contains(query);
            break;
          case 'Property':
            matchesSearch = (e.propertyDetails?.title ?? '').toLowerCase().contains(query);
            break;
          default:
            matchesSearch = e.customerName.toLowerCase().contains(query);
        }
      }

      // Status filter
      bool matchesStatus = true;
      if (filterStatus != 'All') {
        matchesStatus = e.status.toLowerCase() == filterStatus.toLowerCase();
      }

      return matchesSearch && matchesStatus;
    }).toList();

    applyPagination();
  }

  void applyPagination() {
    if (filteredEnquiries.isEmpty) {
      paginatedEnquiries = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }

    totalPages = (filteredEnquiries.length / itemsPerPage).ceil();
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;

    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > filteredEnquiries.length) endIndex = filteredEnquiries.length;
    paginatedEnquiries = filteredEnquiries.sublist(startIndex, endIndex);
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
      filterType = 'Customer Name';
      filterStatus = 'All';
      _searchController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return Colors.blue;
      case 'assigned':
        return Colors.orange;
      case 'contacted':
        return Colors.purple;
      case 'interested':
        return Colors.green;
      case 'not_interested':
        return Colors.red;
      case 'followup':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String getStatusLabel(String status) {
    return status.toUpperCase();
  }

  // ==================== ASSIGN FUNCTION - FIXED OVERFLOW ====================
  // ==================== ASSIGN FUNCTION - MARKETING PARTNER ====================
  // ==================== ASSIGN FUNCTION - MULTI-SELECT WITH CHECKBOX ====================
  Future<void> _showAssignPopup(PropertyEnquiryData enquiry) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Fetch enquiry-wise marketing partners
    EnquiryWiseMarketingPartnersResponse? response;
    try {
      response = await _service.getEnquiryWiseMarketingPartners(enquiry.id);
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load partners: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.pop(context); // close loading

    if (response == null || response.data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No marketing partners available for this enquiry.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final partners = response.data;

    // ✅ Determine default partner (property owner)
    // Priority: API's default_partner_id → enquiry.assignedChannelPartner
    final int? defaultPartnerId =
        response.defaultPartnerId ?? enquiry.assignedChannelPartner;

    // ✅ Pre-select: default partner + already assigned partners
    final Set<int> selectedPartnerIds = {};

    if (defaultPartnerId != null && defaultPartnerId > 0) {
      // Check if default partner exists in list
      final defaultExists = partners.any((p) => p.id == defaultPartnerId);
      if (defaultExists) {
        selectedPartnerIds.add(defaultPartnerId);
      }
    }

    // Add already assigned partner if exists
    if (enquiry.assignedChannelPartner != null) {
      final assignedExists =
      partners.any((p) => p.id == enquiry.assignedChannelPartner);
      if (assignedExists) {
        selectedPartnerIds.add(enquiry.assignedChannelPartner!);
      }
    }

    bool isAssigning = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: Colors.transparent,
            child: Container(
              width: 520,
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.95,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _premiumPrimary.withOpacity(0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ==================== HEADER ====================
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.assignment_turned_in,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Assign Enquiry',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Select one or more marketing partners',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 18),
                            onPressed: () => Navigator.pop(context),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==================== BODY ====================
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enquiry Info Card
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: _premiumPrimary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.person_outline,
                                        size: 14,
                                        color: _premiumPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        enquiry.customerName,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1A1A2E),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: _premiumSecondary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.home_work,
                                        size: 14,
                                        color: _premiumSecondary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        enquiry.propertyDetails?.title ?? 'N/A',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF475569),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Partner selection header
                          Row(
                            children: [
                              const Text(
                                'Select Marketing Partners',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A2E),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _premiumPrimary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${selectedPartnerIds.length} selected',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _premiumPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // ✅ PARTNER CHECKBOX LIST
                          ...partners.map((partner) {
                            final isSelected =
                            selectedPartnerIds.contains(partner.id);
                            final isDefault = partner.id == defaultPartnerId;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _premiumPrimary.withOpacity(0.06)
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? _premiumPrimary.withOpacity(0.4)
                                      : Colors.grey.shade200,
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isSelected) {
                                      selectedPartnerIds.remove(partner.id);
                                    } else {
                                      selectedPartnerIds.add(partner.id);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      // ✅ Checkbox
                                      Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? _premiumPrimary
                                              : Colors.white,
                                          borderRadius:
                                          BorderRadius.circular(6),
                                          border: Border.all(
                                            color: isSelected
                                                ? _premiumPrimary
                                                : Colors.grey.shade400,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: isSelected
                                            ? const Icon(Icons.check,
                                            size: 14, color: Colors.white)
                                            : null,
                                      ),
                                      const SizedBox(width: 12),

                                      // Partner info
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    partner.displayName,
                                                    style: const TextStyle(
                                                      fontSize: 13,
                                                      fontWeight:
                                                      FontWeight.w600,
                                                      color:
                                                      Color(0xFF1A1A2E),
                                                    ),
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                  ),
                                                ),
                                                if (isDefault)
                                                  Container(
                                                    margin: const EdgeInsets
                                                        .only(left: 6),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green
                                                          .withOpacity(0.15),
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                          6),
                                                    ),
                                                    child: const Text(
                                                      'Owner',
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight:
                                                        FontWeight.w700,
                                                        color: Colors.green,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Ref: ${partner.displayReferralCode}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),

                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),

                  // ==================== ACTIONS ====================
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isAssigning
                              ? null
                              : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            minimumSize: const Size(0, 36),
                          ),
                          child: const Text('Cancel',
                              style: TextStyle(fontSize: 13)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed:
                          isAssigning || selectedPartnerIds.isEmpty
                              ? null
                              : () async {
                            setState(() => isAssigning = true);
                            try {
                              // ✅ Assign to ALL selected partners
                              final List<String> errors = [];
                              final List<String> successes = [];

                              for (final partnerId
                              in selectedPartnerIds) {
                                try {
                                  final res =
                                  await _service.assignEnquiry(
                                    enquiryId: enquiry.id,
                                    channelPartnerId: partnerId,
                                  );
                                  if (res.success) {
                                    successes.add(partnerId
                                        .toString());
                                  } else {
                                    errors.add(res.message);
                                  }
                                } catch (e) {
                                  errors.add(e.toString());
                                }
                              }

                              if (!context.mounted) return;

                              if (errors.isEmpty) {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Enquiry assigned to ${successes.length} partner(s) successfully'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                Navigator.pop(context);
                                await loadEnquiries();
                              } else if (successes.isNotEmpty) {
                                // Partial success
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Assigned to ${successes.length} partner(s), ${errors.length} failed'),
                                    backgroundColor:
                                    Colors.orange,
                                  ),
                                );
                                Navigator.pop(context);
                                await loadEnquiries();
                              } else {
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Failed: ${errors.first}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content:
                                  Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } finally {
                              if (mounted) {
                                setState(() => isAssigning = false);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _premiumPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            minimumSize: const Size(0, 36),
                          ),
                          child: isAssigning
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            'Assign (${selectedPartnerIds.length})',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== DETAILS POPUP - WITH ASSIGN BUTTON ====================
  void showDetailsPopup(PropertyEnquiryData enquiry) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            double dialogWidth = constraints.maxWidth * 0.9;
            if (constraints.maxWidth > 600) dialogWidth = 640;
            if (constraints.maxWidth > 1000) dialogWidth = 760;

            return Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: _premiumPrimary.withOpacity(0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.question_answer,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                enquiry.customerName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(enquiry.status).withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      getStatusLabel(enquiry.status),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: getStatusColor(enquiry.status),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'ID: ${enquiry.id}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
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
                          // Customer Details
                          _buildInfoSection(
                            'Customer Details',
                            Icons.person_outline,
                            [
                              _infoRow('Name', enquiry.customerName),
                              _infoRow('Email', enquiry.customerEmail),
                              _infoRow('Mobile', enquiry.customerMobile),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Property Details
                          if (enquiry.propertyDetails != null) ...[
                            _buildInfoSection(
                              'Property Details',
                              Icons.home_work,
                              [
                                _infoRow('Title', enquiry.propertyDetails!.title),
                                _infoRow('Type', enquiry.propertyDetails!.propertyType),
                                _infoRow('Transaction', enquiry.propertyDetails!.transactionType),
                                _infoRow('City', enquiry.propertyDetails!.city),
                                _infoRow('Area', enquiry.propertyDetails!.area),
                                _infoRow('Status', enquiry.propertyDetails!.status),
                                _infoRow('RERA No', enquiry.propertyDetails!.reraNumber ?? '-'),
                              ],
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Enquiry Details
                          _buildInfoSection(
                            'Enquiry Details',
                            Icons.info_outline,
                            [
                              _infoRow('Status', getStatusLabel(enquiry.status)),
                              _infoRow('Message', enquiry.message, isLong: true),
                              if (enquiry.assignedChannelPartner != null)
                                _infoRow('Assigned To', 'Partner #${enquiry.assignedChannelPartner}'),
                              if (enquiry.assignedAt != null)
                                _infoRow('Assigned At', formatDate(enquiry.assignedAt)),
                              if (enquiry.followupDate != null)
                                _infoRow('Follow-up Date', formatDate(enquiry.followupDate)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Timestamps
                          _buildInfoSection(
                            'Timestamps',
                            Icons.calendar_today,
                            [
                              _infoRow('Created', formatDate(enquiry.createdAt)),
                              _infoRow('Updated', formatDate(enquiry.updatedAt)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Footer with Assign Button
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(28),
                        bottomRight: Radius.circular(28),
                      ),
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Assign Button
                        // Assign Button
                        if (enquiry.status.toLowerCase() != 'assigned' &&
                            enquiry.status.toLowerCase() != 'contacted')
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showAssignPopup(enquiry);
                            },
                            icon: const Icon(Icons.assignment_turned_in, size: 18),
                            label: const Text('Assign Enquiry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _premiumPrimary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          )
                        else if (enquiry.status.toLowerCase() == 'contacted')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.phone_in_talk,
                                  color: Colors.purple.shade700,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Already Contacted',
                                  style: TextStyle(
                                    color: Colors.purple.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade700,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Already Assigned',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          ),
                          child: const Text('Close'),
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
    );
  }

  // ==================== UI HELPERS ====================
  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {bool isLong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              maxLines: isLong ? 5 : 2,
              overflow: isLong ? TextOverflow.ellipsis : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== EXPORT FUNCTIONS ====================
  void exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['Property Enquiries'];

    sheet.appendRow([
      "SR No", "Customer Name", "Email", "Mobile", "Property", "Status", "Created"
    ]);

    int srNo = filteredEnquiries.length;
    for (var e in filteredEnquiries) {
      sheet.appendRow([
        srNo--,
        e.customerName,
        e.customerEmail,
        e.customerMobile,
        e.propertyDetails?.title ?? 'N/A',
        e.status.toUpperCase(),
        formatDate(e.createdAt),
      ]);
    }

    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "property_enquiries.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> exportPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: ["SR No", "Customer", "Email", "Mobile", "Property", "Status"],
            data: List.generate(filteredEnquiries.length, (index) {
              final e = filteredEnquiries[index];
              final srNo = filteredEnquiries.length - index;
              return [
                srNo.toString(),
                e.customerName,
                e.customerEmail,
                e.customerMobile,
                e.propertyDetails?.title ?? 'N/A',
                e.status.toUpperCase(),
              ];
            }),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void exportDOC() {
    final content = StringBuffer();
    content.writeln("Property Enquiries List\n");
    content.writeln("=" * 50);

    int srNo = filteredEnquiries.length;
    for (var e in filteredEnquiries) {
      content.writeln("SR No: ${srNo--}");
      content.writeln("Customer: ${e.customerName}");
      content.writeln("Email: ${e.customerEmail}");
      content.writeln("Mobile: ${e.customerMobile}");
      content.writeln("Property: ${e.propertyDetails?.title ?? 'N/A'}");
      content.writeln("Status: ${e.status.toUpperCase()}");
      content.writeln("Created: ${formatDate(e.createdAt)}");
      content.writeln("-" * 30);
    }

    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "property_enquiries.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ==================== FILTER SECTION ====================
  Widget _buildFilterSection(bool isMobile) {
    final statusOptions = ['All', 'New', 'Assigned', 'Contacted', 'Interested', 'Not Interested', 'Followup'];

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
            Container(
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
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
                  onChanged: (String? newValue) {
                    setState(() {
                      filterType = newValue!;
                      currentPage = 1;
                      applyFilters();
                    });
                  },
                  items: ['Customer Name', 'Email', 'Mobile', 'Property']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by ${filterType.toLowerCase()}...',
                  prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF6366F1)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
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
              ),
            ),
            const SizedBox(height: 8),

            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: filterStatus,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
                  onChanged: (String? newValue) {
                    setState(() {
                      filterStatus = newValue!;
                      currentPage = 1;
                      applyFilters();
                    });
                  },
                  items: statusOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildExportIcons(),
                Row(
                  children: [
                    Text(
                      "Total: ${filteredEnquiries.length}",
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: resetFilters,
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
                      value: filterType,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
                      onChanged: (String? newValue) {
                        setState(() {
                          filterType = newValue!;
                          currentPage = 1;
                          applyFilters();
                        });
                      },
                      items: ['Customer Name', 'Email', 'Mobile', 'Property']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

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
                        hintText: 'Search by ${filterType.toLowerCase()}...',
                        prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF6366F1)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                          currentPage = 1;
                          applyFilters();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                Container(
                  width: 130,
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: filterStatus,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
                      onChanged: (String? newValue) {
                        setState(() {
                          filterStatus = newValue!;
                          currentPage = 1;
                          applyFilters();
                        });
                      },
                      items: statusOptions
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                _buildExportIcons(),
                const SizedBox(width: 8),

                Text(
                  "Total: ${filteredEnquiries.length}",
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: resetFilters,
                  icon: const Icon(Icons.refresh),
                  color: Colors.red,
                  tooltip: "Reset",
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExportIcons() {
    return Row(
      children: [
        Tooltip(
          message: "Export Excel",
          child: InkWell(
            onTap: exportExcel,
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
            onTap: exportPDF,
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
            onTap: exportDOC,
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

  // ==================== TABLE ====================
  Widget _buildTable() {
    return Container(
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
          // Header
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: SingleChildScrollView(
              controller: _headerHorizontalController,
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder(
                  horizontalInside: BorderSide(color: Colors.grey.shade300),
                  verticalInside: BorderSide(color: Colors.grey.shade300),
                  top: BorderSide(color: Colors.grey.shade300),
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
                columnWidths: columnWidths,
                children: [
                  TableRow(
                    children: headerLabels.map((label) => _tableHeader(label)).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Body
          Expanded(
            child: filteredEnquiries.isEmpty
                ? const Center(child: Text("No enquiries found"))
                : SingleChildScrollView(
              controller: _verticalController,
              child: SingleChildScrollView(
                controller: _rowsHorizontalController,
                scrollDirection: Axis.horizontal,
                child: Table(
                  border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                  columnWidths: columnWidths,
                  children: List.generate(paginatedEnquiries.length, (rowIndex) {
                    final e = paginatedEnquiries[rowIndex];
                    final isEven = rowIndex % 2 == 0;
                    final srNo = filteredEnquiries.length - ((currentPage - 1) * itemsPerPage + rowIndex);
                    final isAssigned = e.status.toLowerCase() == 'assigned';
                    final isContacted = e.status.toLowerCase() == 'contacted';

                    return TableRow(
                      decoration: BoxDecoration(
                        color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                      ),
                      children: [
                        _tableCell(srNo.toString(), onTap: () => showDetailsPopup(e)),
                        _tableCell(e.customerName, onTap: () => showDetailsPopup(e), maxLines: 1),
                        _tableCell(e.customerEmail, onTap: () => showDetailsPopup(e), maxLines: 1),
                        _tableCell(e.customerMobile, onTap: () => showDetailsPopup(e)),
                        _tableCell(e.propertyDetails?.title ?? 'N/A', onTap: () => showDetailsPopup(e), maxLines: 1),

                        // Status
                        Container(
                          height: 42,
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: getStatusColor(e.status).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                getStatusLabel(e.status),
                                style: TextStyle(
                                  color: getStatusColor(e.status),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        _tableCell(formatDate(e.createdAt), onTap: () => showDetailsPopup(e)),

                        // View Column
                        Container(
                          height: 42,
                          padding: const EdgeInsets.all(2),
                          child: IconButton(
                            icon: const Icon(Icons.visibility, color: Color(0xFF4158D0), size: 18),
                            onPressed: () => showDetailsPopup(e),
                            tooltip: 'View Details',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          ),
                        ),

                        // Assign Column
                        Container(
                          height: 42,
                          padding: const EdgeInsets.all(2),
                          child: isAssigned
                              ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Assigned',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                              : isContacted
                              ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                'Contacted',
                                style: TextStyle(
                                  color: Colors.purple[700],
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                              : IconButton(
                            icon: const Icon(Icons.assignment_turned_in, color: Colors.orange, size: 18),
                            onPressed: () => _showAssignPopup(e),
                            tooltip: 'Assign to Channel Partner',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: Color(0xFF1E293B),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _tableCell(String text, {VoidCallback? onTap, int maxLines = 2}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // ==================== PAGINATION ====================
  Widget _buildPagination() {
    if (filteredEnquiries.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showEntriesRow = Row(
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
                  value: itemsPerPage,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  style: const TextStyle(fontSize: 12),
                  items: rowsPerPageOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      itemsPerPage = v!;
                      currentPage = 1;
                      applyPagination();
                    });
                  },
                ),
              ),
              const Text(" entries", style: TextStyle(fontSize: 12)),
              const SizedBox(width: 12),
              Text(
                "Showing ${(currentPage - 1) * itemsPerPage + 1} to "
                    "${currentPage * itemsPerPage > filteredEnquiries.length ? filteredEnquiries.length : currentPage * itemsPerPage} "
                    "of ${filteredEnquiries.length}",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          );

          final pageButtons = [
            _compactPageButton(icon: Icons.chevron_left, onTap: currentPage > 1 ? previousPage : null),
            if (totalPages <= 5)
              ...List.generate(totalPages, (index) => _compactPageNumber(index + 1))
            else if (currentPage <= 3) ...[
              ...List.generate(4, (index) => _compactPageNumber(index + 1)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              _compactPageNumber(totalPages),
            ] else if (currentPage >= totalPages - 2) ...[
              _compactPageNumber(1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              ...List.generate(4, (index) => _compactPageNumber(totalPages - 3 + index)),
            ] else ...[
              _compactPageNumber(1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              _compactPageNumber(currentPage - 1),
              _compactPageNumber(currentPage),
              _compactPageNumber(currentPage + 1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              _compactPageNumber(totalPages),
            ],
            _compactPageButton(icon: Icons.chevron_right, onTap: currentPage < totalPages ? nextPage : null),
          ];

          final paginationRow = Row(
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
                children: [
                  showEntriesRow,
                  paginationRow,
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _compactPageButton({required IconData icon, required VoidCallback? onTap}) {
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
    final isSelected = currentPage == pageNum;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: () => goToPage(pageNum),
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

  // ==================== MAIN BUILD ====================
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Property Enquiries",
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
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildFilterSection(isMobile),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _buildTable()),
                  const SizedBox(height: 8),
                  _buildPagination(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}