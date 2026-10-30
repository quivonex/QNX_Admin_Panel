import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:html' as html;
import '../../models/qnx_admin/offer_model.dart';
import '../../api/api_service.dart';

class OfferListScreen extends StatefulWidget {
  const OfferListScreen({super.key});

  @override
  State<OfferListScreen> createState() => _OfferListScreenState();
}

class _OfferListScreenState extends State<OfferListScreen> {
  // Services
  final OfferService _offerService = OfferService();
  final OfferUpdateService _updateService = OfferUpdateService();
  final SingleOfferService _singleService = SingleOfferService();
  final OfferDeleteService _deleteService = OfferDeleteService();

  // Filter Controller
  final TextEditingController _searchController = TextEditingController();

  List<OfferModel> allOffers = [];
  List<OfferModel> filteredOffers = [];
  List<OfferModel> paginatedOffers = [];

  bool isLoading = true;
  bool showForm = false;
  int? editingId;

  // Pagination Variables
  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [10, 15, 20, 25, 30, 50];
  int? _companyId;
  // Filter Variables
  String searchQuery = '';
  String filterType = 'Title'; // 'Title' or 'Type'

  // Form Controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final offerTypeController = TextEditingController();
  final discountController = TextEditingController();
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _formScrollController = ScrollController();

  // Premium gradient colors (matching dashboard)
  static const Color _premiumPrimary = Color(0xFF4158D0);
  static const Color _premiumSecondary = Color(0xFFC850C0);

  @override
  void initState() {
    super.initState();
    loadOffers();
    _loadCompanyId();
  }

  Future<void> _loadCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _companyId = prefs.getInt('companyId');
      if (_companyId == 0) _companyId = null;
    });
    loadOffers();
  }

  Future<void> loadOffers() async {
    try {
      final res = await _offerService.getOffers();
      if (mounted) {
        setState(() {
          allOffers = res.data;
          applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load offers")),
        );
      }
    }
  }

  void applyFilters() {
    if (searchQuery.isEmpty) {
      filteredOffers = allOffers;
    } else {
      final query = searchQuery.toLowerCase();
      filteredOffers = allOffers.where((offer) {
        if (filterType == 'Title') {
          return offer.title.toLowerCase().contains(query);
        } else {
          return (offer.offerType ?? '').toLowerCase().contains(query);
        }
      }).toList();
    }
    applyPagination();
  }

  void applyPagination() {
    if (filteredOffers.isEmpty) {
      paginatedOffers = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }

    totalPages = (filteredOffers.length / itemsPerPage).ceil();
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;

    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > filteredOffers.length) endIndex = filteredOffers.length;
    paginatedOffers = filteredOffers.sublist(startIndex, endIndex);

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
      filterType = 'Title';
      _searchController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  // ---------- Export functions ----------
  void exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['Offers'];

    sheet.appendRow([
      "SR No", "Company Name", "Branch Name", "Product Name", "Title",
      "Description", "Type", "Discount", "Start Date", "End Date", "Status"
    ]);

    int srNo = 1;
    for (var offer in filteredOffers) {
      sheet.appendRow([
        srNo++,
        _getCompanyNames(offer),
        _getBranchNames(offer),
        _getProductNames(offer),
        offer.title,
        offer.description,
        offer.offerType ?? '-',
        offer.discountValue ?? '-',
        offer.startDate ?? '-',
        offer.endDate ?? '-',
        offer.isActive ? 'Active' : 'Inactive'
      ]);
    }

    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "offers.xlsx")
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
            headers: [
              "SR No", "Title", "Type", "Discount", "Start Date", "End Date", "Status"
            ],
            data: filteredOffers.asMap().entries.map((entry) {
              final offer = entry.value;
              final srNo = entry.key + 1;
              return [
                srNo.toString(),
                offer.title,
                offer.offerType ?? '-',
                offer.discountValue ?? '-',
                offer.startDate ?? '-',
                offer.endDate ?? '-',
                offer.isActive ? 'Active' : 'Inactive'
              ];
            }).toList(),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }

  void exportDOC() {
    final content = StringBuffer();

    content.writeln("Offers List\n");
    content.writeln("=" * 50);

    int srNo = 1;
    for (var offer in filteredOffers) {
      content.writeln("SR No: ${srNo++}");
      content.writeln("Title: ${offer.title}");
      content.writeln("Description: ${offer.description}");
      content.writeln("Type: ${offer.offerType ?? '-'}");
      content.writeln("Discount: ${offer.discountValue ?? '-'}");
      content.writeln("Start Date: ${offer.startDate ?? '-'}");
      content.writeln("End Date: ${offer.endDate ?? '-'}");
      content.writeln("Status: ${offer.isActive ? 'Active' : 'Inactive'}");
      content.writeln("-" * 30);
    }

    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "offers.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ---------- Search ----------
  Future<void> searchOffer() async {
    if (_searchController.text.isEmpty) {
      resetFilters();
      return;
    }
    try {
      int id = int.parse(_searchController.text);
      final res = await _singleService.getSingleOffer(id);
      if (res.data != null) {
        final single = res.data!;
        final offer = OfferModel(
          id: single.id!,
          title: single.title ?? '',
          description: single.description ?? '',
          offerType: single.offerType,
          discountValue: single.discountValue?.toString(),
          startDate: single.startDate,
          endDate: single.endDate,
          isActive: single.isActive ?? false,
          createdAt: single.createdAt ?? '',
          productDetails: [],
          branchNames: null,
          companyId: null,
          products: [],
          branches: [],
        );
        setState(() {
          allOffers = [offer];
          applyFilters();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Offer Found")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Offer not found or invalid ID")),
      );
    }
  }

  // ---------- CRUD operations ----------
  Future<void> deleteOffer(int id) async {
    try {
      await _deleteService.deleteOffer(id);
      loadOffers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Offer deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: $e")),
      );
    }
  }

  void openEditForm(OfferModel offer) {
    setState(() {
      editingId = offer.id;
      titleController.text = offer.title;
      descriptionController.text = offer.description;
      offerTypeController.text = offer.offerType ?? '';
      discountController.text = offer.discountValue ?? '';
      startDateController.text = offer.startDate ?? '';
      endDateController.text = offer.endDate ?? '';
      showForm = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _formScrollController.animateTo(
        _formScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void closeForm() {
    setState(() {
      showForm = false;
      editingId = null;
    });
  }

  Future<void> updateOffer() async {
    if (editingId == null) return;
    try {
      OfferUpdateModel model = OfferUpdateModel(
        id: editingId!,
        title: titleController.text,
        description: descriptionController.text,
        offerType: offerTypeController.text,
        discountValue: int.tryParse(discountController.text) ?? 0,
        startDate: startDateController.text,
        endDate: endDateController.text,
      );
      await _updateService.updateOffer(model);
      await loadOffers();
      setState(() {
        showForm = false;
        editingId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Offer updated successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e")),
      );
    }
  }

  // ---------- Premium Details Popup ----------
  void showOfferDetails(OfferModel offer) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            double dialogWidth = constraints.maxWidth * 0.9;
            if (constraints.maxWidth > 600) dialogWidth = 600;
            if (constraints.maxWidth > 800) dialogWidth = 700;
            return Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    const Color(0xFFF8F9FA),
                  ],
                ),
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
                  // Premium Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_premiumPrimary, _premiumSecondary],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.local_offer, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                offer.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                offer.offerType ?? 'Offer',
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
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(ctx),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Row
                          Row(
                            children: [
                              _premiumStatusChip(
                                offer.isActive ? 'Active' : 'Inactive',
                                offer.isActive ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 12),
                              if (offer.offerType != null && offer.offerType!.isNotEmpty)
                                _premiumStatusChip(
                                  offer.offerType!,
                                  _premiumPrimary,
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Basic Information Section
                          _buildPremiumSection(
                            title: "Basic Information",
                            icon: Icons.info_outline,
                            children: [
                              _infoRow("Title", offer.title),
                              _infoRow("Description", offer.description),
                              _infoRow("Type", offer.offerType ?? '-'),
                              _infoRow("Discount Value", offer.discountValue ?? '-'),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Dates Section
                          _buildPremiumSection(
                            title: "Dates",
                            icon: Icons.calendar_today_outlined,
                            children: [
                              _infoRow("Start Date", offer.startDate ?? '-'),
                              _infoRow("End Date", offer.endDate ?? '-'),
                              _infoRow("Created At", offer.createdAt.isNotEmpty ? offer.createdAt.substring(0, 10) : '-'),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Products Section
                          if (offer.productDetails.isNotEmpty)
                            _buildPremiumSection(
                              title: "Products (${offer.productDetails.length})",
                              icon: Icons.shopping_bag_outlined,
                              children: offer.productDetails.map((p) =>
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _premiumPrimary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${p.productName} (${p.company})',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                              ).toList(),
                            ),

                          if (offer.productDetails.isNotEmpty)
                            const SizedBox(height: 20),

                          // Branches Section
                          if (offer.branchNames != null && offer.branchNames!.isNotEmpty)
                            _buildPremiumSection(
                              title: "Branches (${offer.branchNames!.length})",
                              icon: Icons.business_outlined,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: offer.branchNames!.map((b) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [_premiumPrimary.withOpacity(0.1), _premiumSecondary.withOpacity(0.1)],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: _premiumPrimary.withOpacity(0.2)),
                                    ),
                                    child: Text(
                                      b,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _premiumPrimary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  )).toList(),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  // Action Buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              openEditForm(offer);
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              deleteOffer(offer.id);
                            },
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    );
  }

  Widget _premiumStatusChip(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 14, color: color),
          if (icon != null) const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSection({
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
                gradient: const LinearGradient(colors: [_premiumPrimary, _premiumSecondary]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Color(0xFF1A1A2E),
              ),
              maxLines: isLong ? 3 : null,
              overflow: isLong ? TextOverflow.ellipsis : null,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Helper methods for display ----------
  String _getProductNames(OfferModel offer) {
    if (offer.productDetails.isEmpty) return '-';
    return offer.productDetails.map((p) => p.productName).join(', ');
  }

  String _getBranchNames(OfferModel offer) {
    if (offer.branchNames == null || offer.branchNames!.isEmpty) return '-';
    return offer.branchNames!.join(', ');
  }

  String _getCompanyNames(OfferModel offer) {
    if (offer.productDetails.isEmpty) return '-';
    final companies = offer.productDetails.map((p) => p.company).toSet();
    return companies.join(', ');
  }

  // ---------- UI Build ----------
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Offer Management",
          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        controller: _formScrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildFilterSection(isMobile),
            const SizedBox(height: 20),
            _buildCustomTable(isMobile),
            if (showForm) ...[
              const SizedBox(height: 20),
              _buildEditForm(isMobile),
            ],
          ],
        ),
      ),
    );
  }

  // ---------- Filter section ----------
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
          Row(
            children: [
              // Filter type dropdown
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
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
                    style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      setState(() {
                        filterType = newValue!;
                        currentPage = 1;
                        applyFilters();
                      });
                    },
                    items: ['Title', 'Type']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Row(
                          children: [
                            Icon(
                              value == 'Title' ? Icons.title : Icons.local_offer,
                              size: 14,
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
              ),
              const SizedBox(width: 12),

              // Search bar
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
                      hintText: filterType == 'Title'
                          ? "Search by title..."
                          : "Search by type...",
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
              ),

              const SizedBox(width: 12),

              // Export icons
              _buildExportIcons(),

              const SizedBox(width: 12),

              // Reset + Count
              Row(
                children: [
                  Text(
                    "Total: ${filteredOffers.length}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
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
              child: Image.asset(
                "assets/icon/xls.png",
                height: 20,
                width: 20,
              ),
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
              child: Image.asset(
                "assets/icon/pdf.png",
                height: 20,
                width: 20,
              ),
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
              child: Image.asset(
                "assets/icon/doc.png",
                height: 20,
                width: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Table ----------
  Widget _buildCustomTable(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with "Show entries" dropdown
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    const Text("All Offers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const SizedBox(height: 12),
                    _buildRowsPerPageDropdown(),
                  ],
                );
              } else {
                return Row(
                  children: [
                    const Text("All Offers", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                    const Spacer(),
                    _buildRowsPerPageDropdown(),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),

          // Horizontal scroll table
          Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1400),
                child: Scrollbar(
                  controller: _verticalController,
                  thumbVisibility: true,
                  child: SingleChildScrollView(
                    controller: _verticalController,
                    child: Table(
                      border: TableBorder.all(color: Colors.grey.shade300),
                      columnWidths: {
                        0: const FixedColumnWidth(60),   // SR No
                        1: const FixedColumnWidth(150),  // Company Name
                        2: const FixedColumnWidth(150),  // Branch Name
                        3: const FixedColumnWidth(180),  // Product Name
                        4: const FixedColumnWidth(180),  // Title
                        5: const FixedColumnWidth(180),  // Description
                        6: const FixedColumnWidth(100),  // Type
                        7: const FixedColumnWidth(100),  // Discount
                        8: const FixedColumnWidth(100),  // Start Date
                        9: const FixedColumnWidth(100),  // End Date
                        10: const FixedColumnWidth(70),  // Actions
                      },
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                          children: [
                            _tableHeader("SR No"),
                            _tableHeader("Company Name"),
                            _tableHeader("Branch Name"),
                            _tableHeader("Product Name"),
                            _tableHeader("Title"),
                            _tableHeader("Description"),
                            _tableHeader("Type"),
                            _tableHeader("Discount"),
                            _tableHeader("Start Date"),
                            _tableHeader("End Date"),
                            _tableHeader("Actions"),
                          ],
                        ),
                        if (paginatedOffers.isEmpty)
                          TableRow(
                            children: List.generate(11, (_) => _tableCell("")),
                          )
                        else
                          ...paginatedOffers.asMap().entries.map((entry) {
                            int index = entry.key;
                            OfferModel offer = entry.value;
                            final int srNo = (currentPage - 1) * itemsPerPage + index + 1;
                            return TableRow(
                              decoration: BoxDecoration(
                                color: index % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC),
                              ),
                              children: [
                                GestureDetector(
                                  onTap: () => showOfferDetails(offer),
                                  child: _tableCell(srNo.toString()),
                                ),
                                GestureDetector(
                                  onTap: () => showOfferDetails(offer),
                                  child: _tableCell(_getCompanyNames(offer)),
                                ),
                                GestureDetector(
                                  onTap: () => showOfferDetails(offer),
                                  child: _tableCell(_getBranchNames(offer)),
                                ),
                                GestureDetector(
                                  onTap: () => showOfferDetails(offer),
                                  child: _tableCell(_getProductNames(offer)),
                                ),
                                GestureDetector(
                                  onTap: () => showOfferDetails(offer),
                                  child: _tableCell(offer.title),
                                ),
                                GestureDetector(
                                  onTap: () => showOfferDetails(offer),
                                  child: _tableCell(offer.description),
                                ),
                                GestureDetector(
                                  onTap: () => showOfferDetails(offer),
                                  child: _tableCell(offer.offerType ?? '-'),
                                ),
                                GestureDetector(
                                  onTap: () => showOfferDetails(offer),
                                  child: _tableCell(offer.discountValue ?? '-'),
                                ),
                                GestureDetector(
                                  onTap: () => showOfferDetails(offer),
                                  child: _tableCell(offer.startDate ?? '-'),
                                ),
                                GestureDetector(
                                  onTap: () => showOfferDetails(offer),
                                  child: _tableCell(offer.endDate ?? '-'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 16),
                                          onPressed: () => openEditForm(offer),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 16),
                                          onPressed: () => deleteOffer(offer.id),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: _premiumPrimary.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: IconButton(
                                          icon: const Icon(Icons.visibility, color: _premiumPrimary, size: 16),
                                          onPressed: () => showOfferDetails(offer),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                        ),
                                      ),
                                    ],
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
          if (filteredOffers.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text("No offers found")),
            ),
          const SizedBox(height: 20),
          if (filteredOffers.isNotEmpty) _buildPagination(),
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
                return DropdownMenuItem<int>(value: value, child: Text(value.toString()));
              }).toList(),
            ),
          ),
          const Text("entries", style: TextStyle(fontSize: 13, color: Colors.grey)),
        ],
      ),
    );
  }

  // ---------- Pagination ----------
  Widget _buildPagination() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 700) {
          return _buildMobilePagination();
        } else {
          return _buildDesktopPagination();
        }
      },
    );
  }

  Widget _buildMobilePagination() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Show ", style: TextStyle(fontSize: 11)),
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButton<int>(
                  value: itemsPerPage,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, size: 16),
                  style: const TextStyle(fontSize: 11),
                  items: rowsPerPageOptions.map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
                  onChanged: (v) {
                    setState(() {
                      itemsPerPage = v!;
                      currentPage = 1;
                      applyPagination();
                    });
                  },
                ),
              ),
              const Text(" entries", style: TextStyle(fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            children: [
              _pageButton(icon: Icons.chevron_left, onTap: currentPage > 1 ? previousPage : null),
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
                  return _pageNumber(pageNum);
                },
              ),
              _pageButton(icon: Icons.chevron_right, onTap: currentPage < totalPages ? nextPage : null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "Showing ${filteredOffers.isEmpty ? 0 : (currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filteredOffers.length ? filteredOffers.length : currentPage * itemsPerPage} of ${filteredOffers.length} entries",
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          Row(
            children: [
              _pageButton(icon: Icons.chevron_left, onTap: currentPage > 1 ? previousPage : null),
              if (totalPages <= 5)
                ...List.generate(totalPages, (index) => _pageNumber(index + 1))
              else if (currentPage <= 3) ...[
                ...List.generate(4, (index) => _pageNumber(index + 1)),
                _buildEllipsis(),
                _pageNumber(totalPages),
              ] else if (currentPage >= totalPages - 2) ...[
                _pageNumber(1),
                _buildEllipsis(),
                ...List.generate(4, (index) => _pageNumber(totalPages - 3 + index)),
              ] else ...[
                _pageNumber(1),
                _buildEllipsis(),
                _pageNumber(currentPage - 1),
                _pageNumber(currentPage),
                _pageNumber(currentPage + 1),
                _buildEllipsis(),
                _pageNumber(totalPages),
              ],
              _pageButton(icon: Icons.chevron_right, onTap: currentPage < totalPages ? nextPage : null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pageButton({required IconData icon, required VoidCallback? onTap}) {
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

  Widget _pageNumber(int pageNum) {
    final isSelected = currentPage == pageNum;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(color: isSelected ? const Color(0xFF6366F1) : Colors.transparent, borderRadius: BorderRadius.circular(6)),
      child: InkWell(
        onTap: () => goToPage(pageNum),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: Text(
            pageNum.toString(),
            style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.w600, fontSize: 11),
          ),
        ),
      ),
    );
  }

  Widget _buildEllipsis() => const Padding(padding: EdgeInsets.symmetric(horizontal: 2), child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)));

  Widget _tableHeader(String text) => Padding(
    padding: const EdgeInsets.all(10),
    child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B))),
  );

  Widget _tableCell(String text) => Padding(
    padding: const EdgeInsets.all(8),
    child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563)), maxLines: 2, overflow: TextOverflow.ellipsis),
  );

  // ---------- Edit form ----------
  Widget _buildEditForm(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 4))],
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.edit, color: Color(0xFF6366F1), size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text("Edit Offer Details", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                ],
              ),
              IconButton(onPressed: closeForm, icon: const Icon(Icons.close, color: Colors.grey), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
            ],
          ),
          const SizedBox(height: 24),
          if (isMobile)
            Column(
              children: [
                _buildFormField("Offer Title", titleController, Icons.title),
                const SizedBox(height: 16),
                _buildFormField("Offer Type", offerTypeController, Icons.local_offer),
                const SizedBox(height: 16),
                _buildFormField("Discount Value", discountController, Icons.money_off, isNumber: true),
                const SizedBox(height: 16),
                _buildFormField("Start Date (YYYY-MM-DD)", startDateController, Icons.calendar_today),
                const SizedBox(height: 16),
                _buildFormField("End Date (YYYY-MM-DD)", endDateController, Icons.calendar_month),
                const SizedBox(height: 16),
                _buildFormField("Description", descriptionController, Icons.description, maxLines: 3),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildFormField("Offer Title", titleController, Icons.title),
                      const SizedBox(height: 16),
                      _buildFormField("Offer Type", offerTypeController, Icons.local_offer),
                      const SizedBox(height: 16),
                      _buildFormField("Discount Value", discountController, Icons.money_off, isNumber: true),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      _buildFormField("Start Date", startDateController, Icons.calendar_today),
                      const SizedBox(height: 16),
                      _buildFormField("End Date", endDateController, Icons.calendar_month),
                      const SizedBox(height: 16),
                      _buildFormField("Description", descriptionController, Icons.description, maxLines: 3),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: updateOffer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text("Update Offer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, IconData icon, {int maxLines = 1, bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalController.dispose();
    _verticalController.dispose();
    _formScrollController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    offerTypeController.dispose();
    discountController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    super.dispose();
  }
}