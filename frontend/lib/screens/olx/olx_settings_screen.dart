// lib/screens/qnx_admin/olx_settings_screen.dart

import 'dart:ui' as ui;
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import '../../models/olx/olx_settings_model.dart';
import '../../api/olx_service.dart';

class OlxSettingsScreen extends StatefulWidget {
  const OlxSettingsScreen({super.key});

  @override
  State<OlxSettingsScreen> createState() => _OlxSettingsScreenState();
}

class _OlxSettingsScreenState extends State<OlxSettingsScreen>
    with TickerProviderStateMixin {
  final OlxSettingsService _service = OlxSettingsService();

  List<OlxSettingsData> _allSettings = [];
  List<OlxSettingsData> _filteredSettings = [];
  List<OlxSettingsData> _paginatedSettings = [];

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

  // Scroll controllers
  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  // Column widths (Sr No instead of ID)
  final Map<int, TableColumnWidth> _columnWidths = const {
    0: FixedColumnWidth(70),   // Sr No
    1: FixedColumnWidth(140),  // First Free
    2: FixedColumnWidth(130),  // Free Days
    3: FixedColumnWidth(180),  // Payment After
    4: FixedColumnWidth(120),  // Active
    5: FixedColumnWidth(180),  // Updated At
    6: FixedColumnWidth(100),  // Actions
  };

  final List<String> _headerLabels = [
    "Sr.No", "First Free", "Free Days", "Payment After", "Active", "Updated At", "Actions"
  ];

  @override
  void initState() {
    super.initState();

    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();

    _fetchSettings();

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

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    try {
      final response = await _service.getSettings();
      if (mounted) {
        setState(() {
          _allSettings = response.data..sort((a, b) => b.id.compareTo(a.id));
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar("Failed to load settings: $e", Colors.red);
      }
    }
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty || _filterType == 'All') {
      // Filter only by active status if type is Active/Inactive
      if (_filterType == 'Active') {
        _filteredSettings = _allSettings.where((s) => s.isActive).toList();
      } else if (_filterType == 'Inactive') {
        _filteredSettings = _allSettings.where((s) => !s.isActive).toList();
      } else {
        _filteredSettings = _allSettings;
      }
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredSettings = _allSettings.where((s) {
        switch (_filterType) {
          case 'Free Days':
            return s.freeListingDays.toString().contains(query);
          case 'First Free':
            return s.firstListingFree.toString().toLowerCase().contains(query);
          case 'Payment After':
            return s.paymentRequiredAfterExpiry
                .toString()
                .toLowerCase()
                .contains(query);
          default:
            return false;
        }
      }).toList();
    }
    _applyPagination();
  }

  void _applyPagination() {
    if (_filteredSettings.isEmpty) {
      _paginatedSettings = [];
      _totalPages = 1;
      _currentPage = 1;
      setState(() {});
      return;
    }
    _totalPages = (_filteredSettings.length / _itemsPerPage).ceil();
    if (_currentPage > _totalPages) _currentPage = _totalPages;
    if (_currentPage < 1) _currentPage = 1;
    final start = (_currentPage - 1) * _itemsPerPage;
    int end = start + _itemsPerPage;
    if (end > _filteredSettings.length) end = _filteredSettings.length;
    _paginatedSettings = _filteredSettings.sublist(start, end);
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
              color == Colors.green ? Icons.check_circle : Icons.error_outline,
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

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  // ========== EXPORT FUNCTIONS ==========
  void _exportExcel() {
    try {
      final excelFile = excel.Excel.createExcel();
      final sheet = excelFile['OLX Settings'];
      final headers = _headerLabels.take(6).toList();
      sheet.appendRow(headers);
      for (var s in _filteredSettings) {
        sheet.appendRow([
          s.id.toString(),
          s.firstListingFree ? 'Yes' : 'No',
          s.freeListingDays.toString(),
          s.paymentRequiredAfterExpiry ? 'Yes' : 'No',
          s.isActive ? 'Active' : 'Inactive',
          _formatDate(s.updatedAt),
        ]);
      }
      final bytes = excelFile.encode();
      if (bytes != null) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", "olx_settings.xlsx")
          ..click();
        html.Url.revokeObjectUrl(url);
        _showSnackBar('Excel exported successfully!', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Error exporting Excel: $e', Colors.red);
    }
  }

  Future<void> _exportPDF() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Table.fromTextArray(
              headers: _headerLabels.take(6).toList(),
              data: _filteredSettings.map((s) => [
                s.id.toString(),
                s.firstListingFree ? 'Yes' : 'No',
                s.freeListingDays.toString(),
                s.paymentRequiredAfterExpiry ? 'Yes' : 'No',
                s.isActive ? 'Active' : 'Inactive',
                _formatDate(s.updatedAt),
              ]).toList(),
            );
          },
        ),
      );
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
      _showSnackBar('PDF exported successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error exporting PDF: $e', Colors.red);
    }
  }

  void _exportDOC() {
    try {
      final content = StringBuffer();
      content.writeln("OLX Settings List\n");
      content.writeln("=" * 80);
      for (var s in _filteredSettings) {
        content.writeln("ID: ${s.id}");
        content.writeln("First Listing Free: ${s.firstListingFree ? 'Yes' : 'No'}");
        content.writeln("Free Listing Days: ${s.freeListingDays}");
        content.writeln(
            "Payment Required After Expiry: ${s.paymentRequiredAfterExpiry ? 'Yes' : 'No'}");
        content.writeln("Active: ${s.isActive ? 'Active' : 'Inactive'}");
        content.writeln("Updated At: ${_formatDate(s.updatedAt)}");
        content.writeln("-" * 40);
      }
      final blob = html.Blob([content.toString()]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "olx_settings.doc")
        ..click();
      html.Url.revokeObjectUrl(url);
      _showSnackBar('DOC exported successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Error exporting DOC: $e', Colors.red);
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

  // ========== CREATE BUTTON WITH ANIMATION ==========
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
            label: const Text('Create Settings'),
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

  // ========== SHOW CREATE FORM AS DIALOG ==========
  void _showCreateFormDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Colors.transparent,
        child: _buildCreateForm(),
      ),
    );
  }

  Widget _buildCreateForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: isMobile ? MediaQuery.of(context).size.width * 0.95 : 600,
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
        child: _CreateSettingsFormContent(
          onSuccess: () {
            Navigator.pop(context);
            _fetchSettings();
          },
        ),
      ),
    );
  }

  // ========== SHOW UPDATE FORM AS DIALOG ==========
  void _showUpdateFormDialog(OlxSettingsData settings) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Colors.transparent,
        child: _buildUpdateForm(settings),
      ),
    );
  }

  Widget _buildUpdateForm(OlxSettingsData settings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      width: isMobile ? MediaQuery.of(context).size.width * 0.95 : 600,
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
        child: _UpdateSettingsFormContent(
          settings: settings,
          onSuccess: () {
            Navigator.pop(context);
            _fetchSettings();
          },
        ),
      ),
    );
  }

  // ========== DETAIL POPUP (VIEW DETAILS) ==========
  void _showSettingsPopup(OlxSettingsData settings) {
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.settings,
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Settings Details',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ID: #${settings.id}',
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
                            title: 'Listing Settings',
                            icon: Icons.card_giftcard,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoChip(
                                  "First Listing Free",
                                  settings.firstListingFree ? "Yes" : "No",
                                  context,
                                  isHighlight: settings.firstListingFree,
                                ),
                                const SizedBox(height: 8),
                                _buildInfoChip(
                                  "Free Listing Days",
                                  "${settings.freeListingDays} days",
                                  context,
                                  isHighlight: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildDetailSection(
                            context,
                            title: 'Payment Settings',
                            icon: Icons.payment,
                            child: _buildInfoChip(
                              "Payment Required After Expiry",
                              settings.paymentRequiredAfterExpiry ? "Yes" : "No",
                              context,
                              isHighlight: settings.paymentRequiredAfterExpiry,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildDetailSection(
                            context,
                            title: 'Status',
                            icon: Icons.toggle_on,
                            child: _buildInfoChip(
                              "Active Status",
                              settings.isActive ? "Active" : "Inactive",
                              context,
                              isHighlight: settings.isActive,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildDetailSection(
                            context,
                            title: 'Timestamps',
                            icon: Icons.access_time,
                            child: _buildInfoChip(
                              "Last Updated",
                              _formatDate(settings.updatedAt),
                              context,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Action Buttons - Update & Delete
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showUpdateFormDialog(settings);
                                  },
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text('Update'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _showDeleteConfirm(settings);
                                  },
                                  icon: const Icon(Icons.delete, size: 18),
                                  label: const Text('Delete'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding:
                                    const EdgeInsets.symmetric(vertical: 12),
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
                  fontSize: 14,
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
  Future<void> _showDeleteConfirm(OlxSettingsData settings) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Settings'),
        content: Text(
            'Are you sure you want to delete settings with ID #${settings.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteSettings(settings.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSettings(int id) async {
    // Note: If your API has a delete endpoint, use it here.
    // For now, since we don't have a delete endpoint in the spec,
    // we'll show a message.
    _showSnackBar('Delete function not available yet', Colors.orange);
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
                    items: ['All', 'Active', 'Inactive', 'Free Days']
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
                      hintText: "Search by ${_filterType.toLowerCase()}...",
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
                    "Total: ${_filteredSettings.length}",
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
                items: ['All', 'Active', 'Inactive', 'Free Days']
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
                  hintText: "Search by ${_filterType.toLowerCase()}...",
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
            "Total: ${_filteredSettings.length}",
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

  // ========== TABLE HEADER ==========
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

  // ========== TABLE CELL ==========
  Widget _tableCell(String text,
      {VoidCallback? onTap, bool isBold = false, Color? textColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: 10,
            color: textColor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // ========== BOOL CELL WITH CHIP ==========
  Widget _boolCell(bool value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: value ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                value ? Icons.check_circle : Icons.cancel,
                size: 12,
                color:
                value ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
              ),
              const SizedBox(width: 4),
              Text(
                value ? "Yes" : "No",
                style: TextStyle(
                  color: value
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
    if (_filteredSettings.isEmpty) return const SizedBox.shrink();
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
                "Showing ${(_currentPage - 1) * _itemsPerPage + 1} to ${_currentPage * _itemsPerPage > _filteredSettings.length ? _filteredSettings.length : _currentPage * _itemsPerPage} of ${_filteredSettings.length}",
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
          "OLX Bazaar Settings",
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
                    child: _filteredSettings.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.settings_outlined,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No settings found',
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
                            _paginatedSettings.length,
                                (rowIndex) {
                              final settings = _paginatedSettings[rowIndex];
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
                                  // Sr No
                                  _tableCell(
                                    srNo.toString(),
                                    onTap: () => _showSettingsPopup(settings),
                                    isBold: true,
                                    textColor: const Color(0xFF4158D0),
                                  ),
                                  // First Free
                                  _boolCell(
                                    settings.firstListingFree,
                                        () => _showSettingsPopup(settings),
                                  ),
                                  // Free Days
                                  _tableCell(
                                    "${settings.freeListingDays} days",
                                    onTap: () => _showSettingsPopup(settings),
                                    isBold: true,
                                    textColor: const Color(0xFF1E40AF),
                                  ),
                                  // Payment After
                                  _boolCell(
                                    settings.paymentRequiredAfterExpiry,
                                        () => _showSettingsPopup(settings),
                                  ),
                                  // Active
                                  _tableCell(
                                    settings.isActive ? "Active" : "Inactive",
                                    onTap: () => _showSettingsPopup(settings),
                                    isBold: true,
                                    textColor: settings.isActive
                                        ? const Color(0xFF15803D)
                                        : const Color(0xFFB91C1C),
                                  ),
                                  // Updated At
                                  _tableCell(
                                    _formatDate(settings.updatedAt),
                                    onTap: () => _showSettingsPopup(settings),
                                  ),
                                  // Actions - View Icon
                                  Container(
                                    height: 42,
                                    padding: const EdgeInsets.all(4),
                                    child: Center(
                                      child: IconButton(
                                        icon: const Icon(Icons.visibility,
                                            color: Color(0xFF4158D0),
                                            size: 18),
                                        onPressed: () =>
                                            _showSettingsPopup(settings),
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
class _CreateSettingsFormContent extends StatefulWidget {
  final VoidCallback onSuccess;

  const _CreateSettingsFormContent({Key? key, required this.onSuccess})
      : super(key: key);

  @override
  State<_CreateSettingsFormContent> createState() =>
      _CreateSettingsFormContentState();
}

class _CreateSettingsFormContentState
    extends State<_CreateSettingsFormContent> {
  final _formKey = GlobalKey<FormState>();
  final OlxSettingsService _service = OlxSettingsService();

  final _freeListingDaysController = TextEditingController();

  bool _firstListingFree = true;
  bool _paymentRequiredAfterExpiry = true;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _freeListingDaysController.dispose();
    super.dispose();
  }

  Future<void> _createSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = OlxSettingsCreateRequest(
        firstListingFree: _firstListingFree,
        freeListingDays:
        int.tryParse(_freeListingDaysController.text.trim()) ?? 0,
        paymentRequiredAfterExpiry: _paymentRequiredAfterExpiry,
        isActive: _isActive,
      );

      final response = await _service.createSettings(request);

      if (response.success) {
        _showSnackBar(
            response.message.isNotEmpty
                ? response.message
                : 'Settings created successfully',
            Colors.green);
        widget.onSuccess();
      } else {
        _showSnackBar(response.message, Colors.red);
      }
    } catch (e) {
      _showSnackBar(e.toString(), Colors.red);
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
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        labelText: label,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8FAFC),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
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
                      'Create New Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Fill in the details to create new OLX settings',
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
                    _buildSectionTitle(
                        'Listing Settings', Icons.card_giftcard, isDark),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _freeListingDaysController,
                      label: 'Free Listing Days *',
                      hint: 'e.g., 15',
                      icon: Icons.calendar_today,
                      isDark: isDark,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter free listing days';
                        }
                        final days = int.tryParse(value.trim());
                        if (days == null || days <= 0) {
                          return 'Enter a valid number of days';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildSectionTitle(
                        'Configuration', Icons.settings, isDark),
                    const SizedBox(height: 12),

                    _buildSwitchTile(
                      title: 'First Listing Free',
                      subtitle: 'Enable free first listing for users',
                      value: _firstListingFree,
                      onChanged: (v) =>
                          setState(() => _firstListingFree = v),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    _buildSwitchTile(
                      title: 'Payment Required After Expiry',
                      subtitle: 'Require payment after free listing expires',
                      value: _paymentRequiredAfterExpiry,
                      onChanged: (v) =>
                          setState(() => _paymentRequiredAfterExpiry = v),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    _buildSwitchTile(
                      title: 'Active Status',
                      subtitle: 'Enable or disable this settings',
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      isDark: isDark,
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createSettings,
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
                                'Create Settings',
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
class _UpdateSettingsFormContent extends StatefulWidget {
  final OlxSettingsData settings;
  final VoidCallback onSuccess;

  const _UpdateSettingsFormContent({
    Key? key,
    required this.settings,
    required this.onSuccess,
  }) : super(key: key);

  @override
  State<_UpdateSettingsFormContent> createState() =>
      _UpdateSettingsFormContentState();
}

class _UpdateSettingsFormContentState
    extends State<_UpdateSettingsFormContent> {
  final _formKey = GlobalKey<FormState>();
  final OlxSettingsService _service = OlxSettingsService();

  final _freeListingDaysController = TextEditingController();

  bool _firstListingFree = true;
  bool _paymentRequiredAfterExpiry = true;
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing data
    final s = widget.settings;
    _freeListingDaysController.text = s.freeListingDays.toString();
    _firstListingFree = s.firstListingFree;
    _paymentRequiredAfterExpiry = s.paymentRequiredAfterExpiry;
    _isActive = s.isActive;
  }

  @override
  void dispose() {
    _freeListingDaysController.dispose();
    super.dispose();
  }

  Future<void> _updateSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = OlxSettingsUpdateRequest(
        id: widget.settings.id,
        firstListingFree: _firstListingFree,
        freeListingDays:
        int.tryParse(_freeListingDaysController.text.trim()) ?? 0,
        paymentRequiredAfterExpiry: _paymentRequiredAfterExpiry,
        isActive: _isActive,
      );

      final response = await _service.updateSettings(request);

      if (response.success) {
        _showSnackBar(
            response.message.isNotEmpty
                ? response.message
                : 'Settings updated successfully',
            Colors.green);
        widget.onSuccess();
      } else {
        _showSnackBar(response.message, Colors.red);
      }
    } catch (e) {
      _showSnackBar(e.toString(), Colors.red);
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
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      inputFormatters: inputFormatters,
      validator: validator,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 13,
      ),
      decoration: InputDecoration(
        labelText: label,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF8FAFC),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
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
                      'Update Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      'Modify settings with ID #${widget.settings.id}',
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
                    // Show Settings ID (read-only info box)
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
                            'Settings ID: #${widget.settings.id}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4158D0),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildSectionTitle(
                        'Listing Settings', Icons.card_giftcard, isDark),
                    const SizedBox(height: 12),

                    _buildTextField(
                      controller: _freeListingDaysController,
                      label: 'Free Listing Days *',
                      hint: 'e.g., 15',
                      icon: Icons.calendar_today,
                      isDark: isDark,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter free listing days';
                        }
                        final days = int.tryParse(value.trim());
                        if (days == null || days <= 0) {
                          return 'Enter a valid number of days';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildSectionTitle(
                        'Configuration', Icons.settings, isDark),
                    const SizedBox(height: 12),

                    _buildSwitchTile(
                      title: 'First Listing Free',
                      subtitle: 'Enable free first listing for users',
                      value: _firstListingFree,
                      onChanged: (v) =>
                          setState(() => _firstListingFree = v),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    _buildSwitchTile(
                      title: 'Payment Required After Expiry',
                      subtitle: 'Require payment after free listing expires',
                      value: _paymentRequiredAfterExpiry,
                      onChanged: (v) =>
                          setState(() => _paymentRequiredAfterExpiry = v),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),

                    _buildSwitchTile(
                      title: 'Active Status',
                      subtitle: 'Enable or disable this settings',
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                      isDark: isDark,
                    ),

                    const SizedBox(height: 24),

                    Center(
                      child: SizedBox(
                        width: 200,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _updateSettings,
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
                              Icon(Icons.check_circle, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Update Settings',
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