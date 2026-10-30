// lib/screens/qnx_admin/olx_communication_plan_screen.dart

import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import '../../models/olx/olx_communication_plan_model.dart';
import '../../api/olx_service.dart';

// ==================== PALETTE ====================
const Color _kBrand = Color(0xFF6366F1);
const Color _kInk = Color(0xFF1E293B);
const Color _kBody = Color(0xFF475569);
const Color _kMuted = Color(0xFF64748B);
const Color _kFaint = Color(0xFF94A3B8);
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kCanvas = Color(0xFFF8FAFC);
const Color _kSuccess = Color(0xFF10B981);
const Color _kDanger = Color(0xFFEF4444);
const Color _kWarning = Color(0xFFF59E0B);

class OlxCommunicationPlanScreen extends StatefulWidget {
  const OlxCommunicationPlanScreen({super.key});

  @override
  State<OlxCommunicationPlanScreen> createState() =>
      _OlxCommunicationPlanScreenState();
}

class _OlxCommunicationPlanScreenState extends State<OlxCommunicationPlanScreen>
    with TickerProviderStateMixin {
  final OlxCommunicationPlanService _service = OlxCommunicationPlanService();

  List<OlxCommunicationPlanData> _allPlans = [];
  List<OlxCommunicationPlanData> _filteredPlans = [];
  List<OlxCommunicationPlanData> _paginatedPlans = [];

  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'All';

  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalPages = 1;
  final List<int> _rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  late AnimationController _borderAnimationController;
  late Animation<Color?> _borderColorAnimation;

  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  // Column widths
  final Map<int, TableColumnWidth> _columnWidths = const {
    0: FixedColumnWidth(60),   // Sr No
    1: FixedColumnWidth(180),  // Name
    2: FixedColumnWidth(100),  // Price
    3: FixedColumnWidth(100),  // Duration
    4: FixedColumnWidth(140),  // Chat
    5: FixedColumnWidth(140),  // Enquiry
    6: FixedColumnWidth(100),  // Status
    7: FixedColumnWidth(100),  // Actions
  };

  final List<String> _headerLabels = [
    "Sr.No",
    "Name",
    "Price",
    "Duration",
    "Chat",
    "Enquiry",
    "Status",
    "Actions"
  ];

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();

    _fetchPlans();

    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _borderColorAnimation = ColorTween(
      begin: const Color(0xFF4158D0),
      end: const Color(0xFFC850C0),
    ).animate(_borderAnimationController);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _borderAnimationController.dispose();
    _headerHorizontalController.dispose();
    _rowsHorizontalController.dispose();
    _verticalController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _fetchPlans() async {
    setState(() => _isLoading = true);
    try {
      final response = await _service.getPlans(includeInactive: true);
      if (mounted) {
        setState(() {
          _allPlans = response.data..sort((a, b) => b.id.compareTo(a.id));
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar("Failed to load plans: $e", _kDanger);
      }
    }
  }

  void _applyFilters() {
    if (_filterType == 'All' && _searchQuery.isEmpty) {
      _filteredPlans = _allPlans;
    } else if (_filterType == 'Active') {
      _filteredPlans = _allPlans.where((p) => p.isActive).toList();
    } else if (_filterType == 'Inactive') {
      _filteredPlans = _allPlans.where((p) => !p.isActive).toList();
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredPlans = _allPlans.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.description.toLowerCase().contains(query);
      }).toList();
    }
    _applyPagination();
  }

  void _applyPagination() {
    if (_filteredPlans.isEmpty) {
      _paginatedPlans = [];
      _totalPages = 1;
      _currentPage = 1;
      setState(() {});
      return;
    }
    _totalPages = (_filteredPlans.length / _itemsPerPage).ceil();
    if (_currentPage > _totalPages) _currentPage = _totalPages;
    if (_currentPage < 1) _currentPage = 1;
    final start = (_currentPage - 1) * _itemsPerPage;
    int end = start + _itemsPerPage;
    if (end > _filteredPlans.length) end = _filteredPlans.length;
    _paginatedPlans = _filteredPlans.sublist(start, end);
    setState(() {});
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

  void _changeItemsPerPage(int? value) {
    if (value != null) {
      setState(() {
        _itemsPerPage = value;
        _currentPage = 1;
        _applyPagination();
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _filterType = 'All';
      _searchController.clear();
      _currentPage = 1;
      _applyFilters();
    });
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == _kSuccess ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _periodLabel(String period) {
    switch (period) {
      case 'daily':
        return 'Daily';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'subscription':
        return 'Subscription';
      default:
        return period;
    }
  }

  // ========== EXPORT FUNCTIONS ==========
  void _exportExcel() {
    try {
      final excelFile = excel.Excel.createExcel();
      final sheet = excelFile['Communication Plans'];
      sheet.appendRow([
        'ID', 'Name', 'Description', 'Price', 'Currency',
        'Duration', 'Chat Limit', 'Chat Period', 'Enquiry Limit',
        'Enquiry Period', 'Status'
      ]);
      for (var p in _filteredPlans) {
        sheet.appendRow([
          p.id.toString(),
          p.name,
          p.description,
          p.price,
          p.currency,
          p.durationDays.toString(),
          p.chatUnlimited ? 'Unlimited' : p.chatLimit.toString(),
          _periodLabel(p.chatLimitPeriod),
          p.enquiryUnlimited ? 'Unlimited' : p.enquiryLimit.toString(),
          _periodLabel(p.enquiryLimitPeriod),
          p.isActive ? 'Active' : 'Inactive',
        ]);
      }
      final bytes = excelFile.encode();
      if (bytes != null) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", "olx_communication_plans.xlsx")
          ..click();
        html.Url.revokeObjectUrl(url);
        _showSnackBar('Excel exported successfully!', _kSuccess);
      }
    } catch (e) {
      _showSnackBar('Error exporting Excel: $e', _kDanger);
    }
  }

  Future<void> _exportPDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Table.fromTextArray(
              headers: ['ID', 'Name', 'Price', 'Duration', 'Chat', 'Enquiry', 'Status'],
              data: _filteredPlans.map((p) => [
                p.id.toString(),
                p.name,
                '${p.currency} ${p.price}',
                '${p.durationDays} days',
                p.chatUnlimited ? 'Unlimited' : '${p.chatLimit}',
                p.enquiryUnlimited ? 'Unlimited' : '${p.enquiryLimit}',
                p.isActive ? 'Active' : 'Inactive',
              ]).toList(),
            );
          },
        ),
      );
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
      _showSnackBar('PDF exported successfully!', _kSuccess);
    } catch (e) {
      _showSnackBar('Error exporting PDF: $e', _kDanger);
    }
  }

  void _exportDOC() {
    try {
      final content = StringBuffer();
      content.writeln("OLX Communication Plans\n");
      content.writeln("=" * 80);
      for (var p in _filteredPlans) {
        content.writeln("ID: ${p.id}");
        content.writeln("Name: ${p.name}");
        content.writeln("Description: ${p.description}");
        content.writeln("Price: ${p.currency} ${p.price}");
        content.writeln("Duration: ${p.durationDays} days");
        content.writeln("Chat: ${p.chatUnlimited ? 'Unlimited' : p.chatLimit} (${_periodLabel(p.chatLimitPeriod)})");
        content.writeln("Enquiry: ${p.enquiryUnlimited ? 'Unlimited' : p.enquiryLimit} (${_periodLabel(p.enquiryLimitPeriod)})");
        content.writeln("Status: ${p.isActive ? 'Active' : 'Inactive'}");
        content.writeln("-" * 40);
      }
      final blob = html.Blob([content.toString()]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "olx_communication_plans.doc")
        ..click();
      html.Url.revokeObjectUrl(url);
      _showSnackBar('DOC exported successfully!', _kSuccess);
    } catch (e) {
      _showSnackBar('Error exporting DOC: $e', _kDanger);
    }
  }

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
              child: Image.asset(
                "assets/icon/xls.png",
                height: 20,
                width: 20,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.table_chart, color: Colors.green, size: 20),
              ),
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
              child: Image.asset(
                "assets/icon/pdf.png",
                height: 20,
                width: 20,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.picture_as_pdf, color: Colors.red, size: 20),
              ),
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
              child: Image.asset(
                "assets/icon/doc.png",
                height: 20,
                width: 20,
                errorBuilder: (_, __, ___) =>
                const Icon(Icons.description, color: Colors.blue, size: 20),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ========== CREATE BUTTON ==========
  Widget _buildCreateButton() {
    return AnimatedBuilder(
      animation: _borderColorAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _borderColorAnimation.value ?? const Color(0xFF4158D0),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _borderColorAnimation.value?.withOpacity(0.5) ??
                    Colors.transparent,
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _showCreateFormDialog,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Create Plan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        );
      },
    );
  }

  // ========== CREATE FORM DIALOG ==========
  void _showCreateFormDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: _buildCreateForm(),
      ),
    );
  }

  Widget _buildCreateForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: isMobile ? MediaQuery.of(context).size.width * 0.95 : 700,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _CreateCommunicationPlanFormContent(
          onSuccess: () {
            Navigator.pop(context);
            _fetchPlans();
          },
        ),
      ),
    );
  }

  // ========== UPDATE FORM DIALOG ==========
  void _showUpdateFormDialog(OlxCommunicationPlanData plan) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: _buildUpdateForm(plan),
      ),
    );
  }

  Widget _buildUpdateForm(OlxCommunicationPlanData plan) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: isMobile ? MediaQuery.of(context).size.width * 0.95 : 700,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: _UpdateCommunicationPlanFormContent(
          plan: plan,
          onSuccess: () {
            Navigator.pop(context);
            _fetchPlans();
          },
        ),
      ),
    );
  }

  // ========== VIEW DETAILS POPUP ==========
  void _showPlanPopup(OlxCommunicationPlanData plan) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                plan.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Plan #${plan.id}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          splashRadius: 24,
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailSection(
                            context,
                            title: 'Plan Info',
                            icon: Icons.card_membership,
                            child: Column(
                              children: [
                                _buildInfoChip("Price",
                                    "${plan.currency} ${plan.price}", context, isHighlight: true),
                                const SizedBox(height: 8),
                                _buildInfoChip("Duration",
                                    "${plan.durationDays} days", context),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailSection(
                            context,
                            title: 'Chat Settings',
                            icon: Icons.chat_bubble_outline,
                            child: Column(
                              children: [
                                _buildInfoChip(
                                    "Chat Limit",
                                    plan.chatUnlimited ? "Unlimited" : "${plan.chatLimit}",
                                    context,
                                    isHighlight: plan.chatUnlimited),
                                const SizedBox(height: 8),
                                _buildInfoChip("Period",
                                    _periodLabel(plan.chatLimitPeriod), context),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailSection(
                            context,
                            title: 'Enquiry Settings',
                            icon: Icons.question_answer_outlined,
                            child: Column(
                              children: [
                                _buildInfoChip(
                                    "Enquiry Limit",
                                    plan.enquiryUnlimited ? "Unlimited" : "${plan.enquiryLimit}",
                                    context,
                                    isHighlight: plan.enquiryUnlimited),
                                const SizedBox(height: 8),
                                _buildInfoChip("Period",
                                    _periodLabel(plan.enquiryLimitPeriod), context),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailSection(
                            context,
                            title: 'Description',
                            icon: Icons.description_outlined,
                            child: _buildInfoChip(
                                "Description",
                                plan.description.isEmpty ? 'No description' : plan.description,
                                context),
                          ),
                          const SizedBox(height: 16),
                          _buildDetailSection(
                            context,
                            title: 'Status',
                            icon: Icons.toggle_on,
                            child: _buildInfoChip(
                                "Active Status",
                                plan.isActive ? "Active" : "Inactive",
                                context,
                                isHighlight: plan.isActive),
                          ),
                          const SizedBox(height: 16),
                          if (plan.createdAt != null)
                            _buildDetailSection(
                              context,
                              title: 'Timestamps',
                              icon: Icons.access_time,
                              child: Column(
                                children: [
                                  _buildInfoChip("Created",
                                      _formatDate(plan.createdAt), context),
                                  const SizedBox(height: 8),
                                  _buildInfoChip("Updated",
                                      _formatDate(plan.updatedAt), context),
                                ],
                              ),
                            ),
                          const SizedBox(height: 20),
                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showUpdateFormDialog(plan);
                                  },
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Update'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showDeleteConfirm(plan);
                                  },
                                  icon: const Icon(Icons.delete, size: 18),
                                  label: const Text('Delete'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _kDanger,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildDetailSection(BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildInfoChip(String label, String value, BuildContext context,
      {bool isHighlight = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isHighlight
            ? (isDark
            ? const Color(0xFF4158D0).withOpacity(0.2)
            : const Color(0xFF4158D0).withOpacity(0.1))
            : (isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6)),
        borderRadius: BorderRadius.circular(12),
        border: isHighlight ? Border.all(color: const Color(0xFF4158D0)) : null,
      ),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: isHighlight
                  ? const Color(0xFF4158D0)
                  : (isDark ? Colors.grey[400] : Colors.grey[700]),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
                color: isHighlight
                    ? const Color(0xFF4158D0)
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ========== DELETE CONFIRM ==========
  Future<void> _showDeleteConfirm(OlxCommunicationPlanData plan) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Plan'),
        content: Text('Are you sure you want to delete "${plan.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Delete function not available yet', _kWarning);
            },
            style: TextButton.styleFrom(foregroundColor: _kDanger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ========== FILTER SECTION ==========
  Widget _buildFilterSection(bool isDark, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 120,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1A1A2E)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterType,
                    icon: const Icon(Icons.arrow_drop_down,
                        color: Color(0xFF4158D0)),
                    style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        fontSize: 13),
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      setState(() {
                        _filterType = newValue!;
                        _currentPage = 1;
                        _applyFilters();
                      });
                    },
                    items: ['All', 'Active', 'Inactive']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1A1A2E)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color:
                        isDark ? Colors.grey[700]! : Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style:
                    TextStyle(color: isDark ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: "Search plans...",
                      hintStyle: TextStyle(
                          color:
                          isDark ? Colors.grey[500] : Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search,
                          size: 16, color: Color(0xFF4158D0)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
              _buildExportIcons(),
              Row(
                children: [
                  Text(
                    "Total: ${_filteredPlans.length}",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey,
                    ),
                  ),
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
      )
          : Row(
        children: [
          Container(
            width: 140,
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _filterType,
                icon: const Icon(Icons.arrow_drop_down,
                    color: Color(0xFF4158D0)),
                style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    fontSize: 13),
                isExpanded: true,
                onChanged: (String? newValue) {
                  setState(() {
                    _filterType = newValue!;
                    _currentPage = 1;
                    _applyFilters();
                  });
                },
                items: ['All', 'Active', 'Inactive']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey.shade200),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(
                  hintText: "Search plans...",
                  hintStyle: TextStyle(
                      color: isDark ? Colors.grey[500] : Colors.grey[400]),
                  prefixIcon: const Icon(Icons.search,
                      size: 16, color: Color(0xFF4158D0)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
          _buildExportIcons(),
          const SizedBox(width: 12),
          Text(
            "Total: ${_filteredPlans.length}",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _resetFilters,
            icon: const Icon(Icons.refresh),
            color: Colors.red,
            tooltip: "Reset",
          ),
        ],
      ),
    );
  }

  // ========== TABLE CELLS ==========
  Widget _tableHeader(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: isDark ? Colors.white : const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _tableCell(String text,
      {VoidCallback? onTap, bool isBold = false, Color? textColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
            color: textColor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _statusCell(bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0xFFDCFCE7)
                : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? Icons.check_circle : Icons.cancel,
                size: 12,
                color: isActive
                    ? const Color(0xFF15803D)
                    : const Color(0xFFB91C1C),
              ),
              const SizedBox(width: 4),
              Text(
                isActive ? "Active" : "Inactive",
                style: TextStyle(
                  color: isActive
                      ? const Color(0xFF15803D)
                      : const Color(0xFFB91C1C),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== PAGINATION ==========
  Widget _buildPagination(bool isDark) {
    if (_filteredPlans.isEmpty) return const SizedBox.shrink();
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: isMobile
          ? Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text("Show ",
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 12)),
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16213E) : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color:
                    isDark ? Colors.grey[700]! : Colors.grey.shade300),
              ),
              child: DropdownButton<int>(
                value: _itemsPerPage,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, size: 18),
                style: TextStyle(
                    color: isDark ? Colors.white : Colors.black, fontSize: 12),
                items: _rowsPerPageOptions
                    .map((e) =>
                    DropdownMenuItem(value: e, child: Text(e.toString())))
                    .toList(),
                onChanged: _changeItemsPerPage,
                dropdownColor:
                isDark ? const Color(0xFF16213E) : Colors.white,
              ),
            ),
            Text(" entries",
                style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 12)),
          ]),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _compactPageButton(
                icon: Icons.chevron_left,
                onTap: _currentPage > 1 ? _previousPage : null,
                isDark: isDark),
            if (_totalPages <= 5)
              ...List.generate(
                  _totalPages, (i) => _compactPageNumber(i + 1, isDark))
            else if (_currentPage <= 3)
              ...[
                ...List.generate(
                    4, (i) => _compactPageNumber(i + 1, isDark)),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text("...",
                        style: TextStyle(
                            color: isDark
                                ? Colors.grey[400]
                                : Colors.grey))),
                _compactPageNumber(_totalPages, isDark),
              ]
            else if (_currentPage >= _totalPages - 2)
                ...[
                  _compactPageNumber(1, isDark),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text("...",
                          style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey))),
                  ...List.generate(4,
                          (i) => _compactPageNumber(_totalPages - 3 + i, isDark)),
                ]
              else
                ...[
                  _compactPageNumber(1, isDark),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text("...",
                          style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey))),
                  _compactPageNumber(_currentPage - 1, isDark),
                  _compactPageNumber(_currentPage, isDark),
                  _compactPageNumber(_currentPage + 1, isDark),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text("...",
                          style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey))),
                  _compactPageNumber(_totalPages, isDark),
                ],
            _compactPageButton(
                icon: Icons.chevron_right,
                onTap: _currentPage < _totalPages ? _nextPage : null,
                isDark: isDark),
          ]),
        ],
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text("Show ",
                  style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 12)),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF16213E) : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color:
                      isDark ? Colors.grey[700]! : Colors.grey.shade300),
                ),
                child: DropdownButton<int>(
                  value: _itemsPerPage,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 12),
                  items: _rowsPerPageOptions
                      .map((e) =>
                      DropdownMenuItem(value: e, child: Text(e.toString())))
                      .toList(),
                  onChanged: _changeItemsPerPage,
                  dropdownColor:
                  isDark ? const Color(0xFF16213E) : Colors.white,
                ),
              ),
              Text(" entries",
                  style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 12)),
              const SizedBox(width: 12),
              Text(
                "Showing ${(_currentPage - 1) * _itemsPerPage + 1} to ${_currentPage * _itemsPerPage > _filteredPlans.length ? _filteredPlans.length : _currentPage * _itemsPerPage} of ${_filteredPlans.length}",
                style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey),
              ),
            ],
          ),
          Row(
            children: [
              _compactPageButton(
                  icon: Icons.chevron_left,
                  onTap: _currentPage > 1 ? _previousPage : null,
                  isDark: isDark),
              if (_totalPages <= 5)
                ...List.generate(
                    _totalPages, (i) => _compactPageNumber(i + 1, isDark))
              else if (_currentPage <= 3)
                ...[
                  ...List.generate(
                      4, (i) => _compactPageNumber(i + 1, isDark)),
                  Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Text("...",
                          style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey))),
                  _compactPageNumber(_totalPages, isDark),
                ]
              else if (_currentPage >= _totalPages - 2)
                  ...[
                    _compactPageNumber(1, isDark),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text("...",
                            style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey))),
                    ...List.generate(
                        4, (i) => _compactPageNumber(_totalPages - 3 + i, isDark)),
                  ]
                else
                  ...[
                    _compactPageNumber(1, isDark),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text("...",
                            style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey))),
                    _compactPageNumber(_currentPage - 1, isDark),
                    _compactPageNumber(_currentPage, isDark),
                    _compactPageNumber(_currentPage + 1, isDark),
                    Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Text("...",
                            style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey))),
                    _compactPageNumber(_totalPages, isDark),
                  ],
              _compactPageButton(
                  icon: Icons.chevron_right,
                  onTap: _currentPage < _totalPages ? _nextPage : null,
                  isDark: isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactPageButton(
      {required IconData icon,
        required VoidCallback? onTap,
        required bool isDark}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: onTap,
        color: onTap != null
            ? const Color(0xFF4158D0)
            : (isDark ? Colors.grey[600] : Colors.grey),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
    );
  }

  Widget _compactPageNumber(int pageNum, bool isDark) {
    final isSelected = _currentPage == pageNum;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF4158D0) : Colors.transparent,
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
              color: isSelected
                  ? Colors.white
                  : (isDark ? Colors.white : const Color(0xFF1E293B)),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  // ========== MAIN BUILD ==========
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF16213E) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        title: const Text(
          "OLX Communication Plans",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _buildCreateButton(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildFilterSection(isDark, isMobile),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                children: [
                  // Fixed header
                  Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1A1A2E)
                          : const Color(0xFFE2E8F0),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                      border: Border.all(
                          color: isDark
                              ? Colors.grey[700]!
                              : Colors.grey.shade300),
                    ),
                    child: SingleChildScrollView(
                      controller: _headerHorizontalController,
                      scrollDirection: Axis.horizontal,
                      child: Table(
                        border: TableBorder(
                          horizontalInside: BorderSide(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey.shade300),
                          verticalInside: BorderSide(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey.shade300),
                          top: BorderSide(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey.shade300),
                          bottom: BorderSide(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey.shade300),
                        ),
                        columnWidths: _columnWidths,
                        children: [
                          TableRow(
                            children: _headerLabels
                                .map((label) => _tableHeader(label, isDark))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Scrollable rows
                  Expanded(
                    child: _filteredPlans.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.card_membership,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No communication plans found',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600]),
                          ),
                          if (_searchQuery.isNotEmpty)
                            TextButton(
                              onPressed: _resetFilters,
                              child: const Text('Clear Search'),
                            ),
                        ],
                      ),
                    )
                        : SingleChildScrollView(
                      controller: _verticalController,
                      child: SingleChildScrollView(
                        controller: _rowsHorizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          border: TableBorder.all(
                            color: isDark
                                ? Colors.grey[700]!
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                          columnWidths: _columnWidths,
                          children: List.generate(
                            _paginatedPlans.length,
                                (rowIndex) {
                              final plan = _paginatedPlans[rowIndex];
                              final isEven = rowIndex % 2 == 0;
                              final srNo = (_currentPage - 1) * _itemsPerPage +
                                  rowIndex +
                                  1;

                              return TableRow(
                                decoration: BoxDecoration(
                                  color: isEven
                                      ? (isDark
                                      ? const Color(0xFF1A1A2E)
                                      : Colors.white)
                                      : (isDark
                                      ? const Color(0xFF16213E)
                                      : const Color(0xFFF8FAFC)),
                                ),
                                children: [
                                  _tableCell(
                                    srNo.toString(),
                                    onTap: () => _showPlanPopup(plan),
                                    isBold: true,
                                    textColor: const Color(0xFF4158D0),
                                  ),
                                  _tableCell(
                                    plan.name,
                                    onTap: () => _showPlanPopup(plan),
                                    isBold: true,
                                  ),
                                  _tableCell(
                                    "${plan.currency} ${plan.price}",
                                    onTap: () => _showPlanPopup(plan),
                                    isBold: true,
                                    textColor: const Color(0xFF15803D),
                                  ),
                                  _tableCell(
                                    "${plan.durationDays} days",
                                    onTap: () => _showPlanPopup(plan),
                                  ),
                                  _tableCell(
                                    plan.chatUnlimited
                                        ? "Unlimited"
                                        : "${plan.chatLimit} / ${_periodLabel(plan.chatLimitPeriod)}",
                                    onTap: () => _showPlanPopup(plan),
                                    textColor: const Color(0xFF1E40AF),
                                  ),
                                  _tableCell(
                                    plan.enquiryUnlimited
                                        ? "Unlimited"
                                        : "${plan.enquiryLimit} / ${_periodLabel(plan.enquiryLimitPeriod)}",
                                    onTap: () => _showPlanPopup(plan),
                                    textColor: const Color(0xFF6B21A8),
                                  ),
                                  _statusCell(
                                      plan.isActive, () => _showPlanPopup(plan)),
                                  Container(
                                    height: 52,
                                    padding: const EdgeInsets.all(4),
                                    child: Center(
                                      child: IconButton(
                                        icon: const Icon(Icons.visibility,
                                            color: Color(0xFF4158D0),
                                            size: 18),
                                        onPressed: () => _showPlanPopup(plan),
                                        tooltip: 'View Details',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                            minWidth: 28, minHeight: 28),
                                      ),
                                    ),
                                  ),
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
            _buildPagination(isDark),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ==================== CREATE FORM CONTENT ===================================
// ============================================================================
class _CreateCommunicationPlanFormContent extends StatefulWidget {
  final VoidCallback onSuccess;

  const _CreateCommunicationPlanFormContent({
    Key? key,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<_CreateCommunicationPlanFormContent> createState() =>
      _CreateCommunicationPlanFormContentState();
}

class _CreateCommunicationPlanFormContentState
    extends State<_CreateCommunicationPlanFormContent> {
  final _formKey = GlobalKey<FormState>();
  final OlxCommunicationPlanService _service = OlxCommunicationPlanService();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _chatLimitController = TextEditingController();
  final _enquiryLimitController = TextEditingController();

  String _currency = 'INR';
  bool _chatUnlimited = false;
  String _chatLimitPeriod = 'daily';
  bool _enquiryUnlimited = false;
  String _enquiryLimitPeriod = 'daily';
  bool _isActive = true;
  bool _isLoading = false;

  static const List<String> _periodOptions = [
    'daily',
    'weekly',
    'monthly',
    'subscription'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _chatLimitController.dispose();
    _enquiryLimitController.dispose();
    super.dispose();
  }

  Future<void> _createPlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = OlxCommunicationPlanCreateRequest(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: _priceController.text.trim(),
        currency: _currency,
        durationDays: int.tryParse(_durationController.text.trim()) ?? 0,
        chatLimit: _chatUnlimited
            ? 0
            : (int.tryParse(_chatLimitController.text.trim()) ?? 0),
        chatUnlimited: _chatUnlimited,
        chatLimitPeriod: _chatLimitPeriod,
        enquiryLimit: _enquiryUnlimited
            ? 0
            : (int.tryParse(_enquiryLimitController.text.trim()) ?? 0),
        enquiryUnlimited: _enquiryUnlimited,
        enquiryLimitPeriod: _enquiryLimitPeriod,
        isActive: _isActive,
      );

      final response = await _service.createPlan(request);

      if (response.status) {
        _showSnackBar(
            response.message.isNotEmpty
                ? response.message
                : 'Plan created successfully',
            _kSuccess);
        widget.onSuccess();
      } else {
        _showSnackBar(response.message, _kDanger);
      }
    } catch (e) {
      _showSnackBar(e.toString(), _kDanger);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = true,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      validator: validator ??
          (isRequired
              ? (v) =>
          (v == null || v.trim().isEmpty) ? "$label is required" : null
              : null),
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        labelText: isRequired ? "$label *" : label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontSize: 12,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[500] : Colors.grey[400],
          fontSize: 12,
        ),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF4158D0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4158D0), width: 2),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8FAFC),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    required bool isDark,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontSize: 12,
        ),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF4158D0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4158D0), width: 2),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8FAFC),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: items
          .map((e) => DropdownMenuItem(
        value: e,
        child: Text(
          e[0].toUpperCase() + e.substring(1),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 13,
          ),
        ),
      ))
          .toList(),
      onChanged: onChanged,
      dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[500] : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: const Color(0xFF4158D0),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create Communication Plan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Set chat and enquiry allowances',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.red),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Info
                    _buildSectionTitle('Basic Information',
                        Icons.info_outline, isDark),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Plan Name',
                      hint: 'e.g., Silver Communication Plan',
                      icon: Icons.card_membership,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Brief description of the plan',
                      icon: Icons.description_outlined,
                      isDark: isDark,
                      maxLines: 2,
                      isRequired: false,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _priceController,
                            label: 'Price',
                            hint: 'e.g., 199.00',
                            icon: Icons.currency_rupee,
                            isDark: isDark,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            label: 'Currency',
                            value: _currency,
                            items: ['INR', 'USD', 'EUR'],
                            onChanged: (v) =>
                                setState(() => _currency = v ?? 'INR'),
                            icon: Icons.currency_exchange,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _durationController,
                      label: 'Duration (Days)',
                      hint: 'e.g., 30',
                      icon: Icons.calendar_today,
                      isDark: isDark,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 20),

                    // Chat Settings
                    _buildSectionTitle(
                        'Chat Settings', Icons.chat_bubble_outline, isDark),
                    const SizedBox(height: 12),
                    _buildSwitchTile(
                      title: 'Unlimited Chats',
                      subtitle: 'Enable unlimited chat allowance',
                      value: _chatUnlimited,
                      onChanged: (v) => setState(() => _chatUnlimited = v),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    if (!_chatUnlimited) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _chatLimitController,
                              label: 'Chat Limit',
                              hint: 'e.g., 100',
                              icon: Icons.chat,
                              isDark: isDark,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Chat Period',
                              value: _chatLimitPeriod,
                              items: _periodOptions,
                              onChanged: (v) => setState(
                                      () => _chatLimitPeriod = v ?? 'daily'),
                              icon: Icons.schedule,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 8),

                    // Enquiry Settings
                    _buildSectionTitle('Enquiry Settings',
                        Icons.question_answer_outlined, isDark),
                    const SizedBox(height: 12),
                    _buildSwitchTile(
                      title: 'Unlimited Enquiries',
                      subtitle: 'Enable unlimited enquiry allowance',
                      value: _enquiryUnlimited,
                      onChanged: (v) => setState(() => _enquiryUnlimited = v),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    if (!_enquiryUnlimited) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _enquiryLimitController,
                              label: 'Enquiry Limit',
                              hint: 'e.g., 25',
                              icon: Icons.question_answer,
                              isDark: isDark,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Enquiry Period',
                              value: _enquiryLimitPeriod,
                              items: _periodOptions,
                              onChanged: (v) => setState(
                                      () => _enquiryLimitPeriod = v ?? 'daily'),
                              icon: Icons.schedule,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 8),

                    // Status
                    _buildSectionTitle('Status', Icons.toggle_on, isDark),
                    const SizedBox(height: 12),
                    _buildSwitchTile(
                      title: 'Active Status',
                      subtitle: 'Enable or disable this plan',
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),

                    Center(
                      child: SizedBox(
                        width: 220,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createPlan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4158D0),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Create Plan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ==================== UPDATE FORM CONTENT ===================================
// ============================================================================
class _UpdateCommunicationPlanFormContent extends StatefulWidget {
  final OlxCommunicationPlanData plan;
  final VoidCallback onSuccess;

  const _UpdateCommunicationPlanFormContent({
    Key? key,
    required this.plan,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<_UpdateCommunicationPlanFormContent> createState() =>
      _UpdateCommunicationPlanFormContentState();
}

class _UpdateCommunicationPlanFormContentState
    extends State<_UpdateCommunicationPlanFormContent> {
  final _formKey = GlobalKey<FormState>();
  final OlxCommunicationPlanService _service = OlxCommunicationPlanService();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _chatLimitController = TextEditingController();
  final _enquiryLimitController = TextEditingController();

  String _currency = 'INR';
  bool _chatUnlimited = false;
  String _chatLimitPeriod = 'daily';
  bool _enquiryUnlimited = false;
  String _enquiryLimitPeriod = 'daily';
  bool _isActive = true;
  bool _isLoading = false;

  static const List<String> _periodOptions = [
    'daily',
    'weekly',
    'monthly',
    'subscription'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.plan;
    _nameController.text = p.name;
    _descriptionController.text = p.description;
    _priceController.text = p.price;
    _currency = p.currency;
    _durationController.text = p.durationDays.toString();
    _chatLimitController.text = p.chatLimit.toString();
    _chatUnlimited = p.chatUnlimited;
    _chatLimitPeriod = p.chatLimitPeriod;
    _enquiryLimitController.text = p.enquiryLimit.toString();
    _enquiryUnlimited = p.enquiryUnlimited;
    _enquiryLimitPeriod = p.enquiryLimitPeriod;
    _isActive = p.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _chatLimitController.dispose();
    _enquiryLimitController.dispose();
    super.dispose();
  }

  Future<void> _updatePlan() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = OlxCommunicationPlanUpdateRequest(
        planId: widget.plan.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: _priceController.text.trim(),
        currency: _currency,
        durationDays: int.tryParse(_durationController.text.trim()) ?? 0,
        chatLimit: _chatUnlimited
            ? 0
            : (int.tryParse(_chatLimitController.text.trim()) ?? 0),
        chatUnlimited: _chatUnlimited,
        chatLimitPeriod: _chatLimitPeriod,
        enquiryLimit: _enquiryUnlimited
            ? 0
            : (int.tryParse(_enquiryLimitController.text.trim()) ?? 0),
        enquiryUnlimited: _enquiryUnlimited,
        enquiryLimitPeriod: _enquiryLimitPeriod,
        isActive: _isActive,
      );

      final response = await _service.updatePlan(request);

      if (response.status) {
        _showSnackBar(
            response.message.isNotEmpty
                ? response.message
                : 'Plan updated successfully',
            _kSuccess);
        widget.onSuccess();
      } else {
        _showSnackBar(response.message, _kDanger);
      }
    } catch (e) {
      _showSnackBar(e.toString(), _kDanger);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: Colors.white),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool isRequired = true,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      validator: validator ??
          (isRequired
              ? (v) =>
          (v == null || v.trim().isEmpty) ? "$label is required" : null
              : null),
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        labelText: isRequired ? "$label *" : label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontSize: 12,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[500] : Colors.grey[400],
          fontSize: 12,
        ),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF4158D0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4158D0), width: 2),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8FAFC),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    required bool isDark,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          fontSize: 12,
        ),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF4158D0)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4158D0), width: 2),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8FAFC),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: items
          .map((e) => DropdownMenuItem(
        value: e,
        child: Text(
          e[0].toUpperCase() + e.substring(1),
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 13,
          ),
        ),
      ))
          .toList(),
      onChanged: onChanged,
      dropdownColor: isDark ? const Color(0xFF1A1A2E) : Colors.white,
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[500] : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: const Color(0xFF4158D0),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.edit_note,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Update Communication Plan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Updating: ${widget.plan.name}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.red),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info box - Plan ID
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF4158D0).withOpacity(0.15)
                            : const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF4158D0).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tag,
                              color: Color(0xFF4158D0), size: 18),
                          const SizedBox(width: 10),
                          Text(
                            'Plan ID: #${widget.plan.id}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4158D0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Basic Info
                    _buildSectionTitle('Basic Information',
                        Icons.info_outline, isDark),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Plan Name',
                      hint: 'e.g., Silver Communication Plan',
                      icon: Icons.card_membership,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Brief description of the plan',
                      icon: Icons.description_outlined,
                      isDark: isDark,
                      maxLines: 2,
                      isRequired: false,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _priceController,
                            label: 'Price',
                            hint: 'e.g., 199.00',
                            icon: Icons.currency_rupee,
                            isDark: isDark,
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            label: 'Currency',
                            value: _currency,
                            items: ['INR', 'USD', 'EUR'],
                            onChanged: (v) =>
                                setState(() => _currency = v ?? 'INR'),
                            icon: Icons.currency_exchange,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _durationController,
                      label: 'Duration (Days)',
                      hint: 'e.g., 30',
                      icon: Icons.calendar_today,
                      isDark: isDark,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 20),

                    // Chat Settings
                    _buildSectionTitle(
                        'Chat Settings', Icons.chat_bubble_outline, isDark),
                    const SizedBox(height: 12),
                    _buildSwitchTile(
                      title: 'Unlimited Chats',
                      subtitle: 'Enable unlimited chat allowance',
                      value: _chatUnlimited,
                      onChanged: (v) => setState(() => _chatUnlimited = v),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    if (!_chatUnlimited) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _chatLimitController,
                              label: 'Chat Limit',
                              hint: 'e.g., 100',
                              icon: Icons.chat,
                              isDark: isDark,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Chat Period',
                              value: _chatLimitPeriod,
                              items: _periodOptions,
                              onChanged: (v) => setState(
                                      () => _chatLimitPeriod = v ?? 'daily'),
                              icon: Icons.schedule,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 8),

                    // Enquiry Settings
                    _buildSectionTitle('Enquiry Settings',
                        Icons.question_answer_outlined, isDark),
                    const SizedBox(height: 12),
                    _buildSwitchTile(
                      title: 'Unlimited Enquiries',
                      subtitle: 'Enable unlimited enquiry allowance',
                      value: _enquiryUnlimited,
                      onChanged: (v) => setState(() => _enquiryUnlimited = v),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    if (!_enquiryUnlimited) ...[
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _enquiryLimitController,
                              label: 'Enquiry Limit',
                              hint: 'e.g., 25',
                              icon: Icons.question_answer,
                              isDark: isDark,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Enquiry Period',
                              value: _enquiryLimitPeriod,
                              items: _periodOptions,
                              onChanged: (v) => setState(
                                      () => _enquiryLimitPeriod = v ?? 'daily'),
                              icon: Icons.schedule,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 8),

                    // Status
                    _buildSectionTitle('Status', Icons.toggle_on, isDark),
                    const SizedBox(height: 12),
                    _buildSwitchTile(
                      title: 'Active Status',
                      subtitle: 'Enable or disable this plan',
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 20),

                    Center(
                      child: SizedBox(
                        width: 220,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updatePlan,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Update Plan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}