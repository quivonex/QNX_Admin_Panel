// lib/screens/marketing_partner/commission_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../api/marketing_service.dart';
import '../../models/marketing_partner/commission_model.dart';
import 'withdraw_screen.dart';

class CommissionScreen extends StatefulWidget {
  const CommissionScreen({super.key});

  @override
  State<CommissionScreen> createState() => _CommissionScreenState();
}

class _CommissionScreenState extends State<CommissionScreen> {
  final CommissionService _service = CommissionService();
  List<CommissionData> _commissions = [];
  List<CommissionData> _filteredCommissions = [];
  bool _isLoading = true;
  String? _error;

  double _totalCommission = 0.0;
  int _totalEnquiries = 0;

  // Search Control
  String _searchQuery = '';
  String _filterType = 'Name'; // Filter Dropdown: Name, Product, Email, Phone
  final TextEditingController _searchController = TextEditingController();

  // Pagination Controls
  int _currentPage = 1;
  int _itemsPerPage = 10;
  final List<int> _itemsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  @override
  void initState() {
    super.initState();
    _debugValues();
    _debugStoredValues();
    _loadData();
  }

  void _debugValues() async {
    final prefs = await SharedPreferences.getInstance();
    print('=== DEBUG ===');
    print('user_id: ${prefs.getString('user_id')}');
    print('marketing_partner_id: ${prefs.getString('marketing_partner_id')}');
    print('=============');
  }

  void _debugStoredValues() async {
    final prefs = await SharedPreferences.getInstance();
    print('=== 🔍 COMMISSION SCREEN DEBUG ===');
    print('user_id: ${prefs.getString('user_id')}');
    print('marketing_partner_id: ${prefs.getString('marketing_partner_id')}');
    print('partner_id: ${prefs.getString('partner_id')}');
    print('user_role: ${prefs.getString('user_role')}');
    print('access_token: ${prefs.getString('access_token')?.substring(0, 20)}...');
    print('==================================');
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _service.getCommission();

      if (mounted) {
        setState(() {
          _commissions = response.data;
          _applyFilters();
          _totalEnquiries = response.data.length;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Load Error: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _calculateTotalCommission() {
    double total = 0.0;
    for (var item in _filteredCommissions) {
      total += item.totalCommissionAmount;
    }
    _totalCommission = total;
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredCommissions = List.from(_commissions);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredCommissions = _commissions.where((item) {
        switch (_filterType) {
          case 'Name':
            return item.personName.toLowerCase().contains(query);
          case 'Product':
            return item.product.toLowerCase().contains(query);
          case 'Email':
            return item.email.toLowerCase().contains(query);
          case 'Phone':
            return item.contact.toLowerCase().contains(query);
          default:
            return false;
        }
      }).toList();
    }
    _calculateTotalCommission();
  }

  void _searchCommissions(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
      _applyFilters();
    });
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _filterType = 'Name';
      _searchController.clear();
      _currentPage = 1;
      _applyFilters();
    });
  }

  // Pagination logic
  List<CommissionData> _getPaginatedCommissions() {
    if (_filteredCommissions.isEmpty) return [];

    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage) > _filteredCommissions.length
        ? _filteredCommissions.length
        : start + _itemsPerPage;

    return _filteredCommissions.sublist(start, end);
  }

  int get _totalPages => _filteredCommissions.isEmpty
      ? 1
      : (_filteredCommissions.length / _itemsPerPage).ceil();

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
      });
    }
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
      });
    }
  }

  void _changeItemsPerPage(int? value) {
    if (value != null) {
      setState(() {
        _itemsPerPage = value;
        _currentPage = 1;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ==========================================
  // 🚀 EXPORT & PRINT WORKING FUNCTIONS
  // ==========================================

  // 1. PDF तयार करण्याचे कॉमन फंक्शन
  Future<pw.Document> _generatePdfDocument() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Commission Report',
                      style: pw.TextStyle(
                          fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Total: ₹${_totalCommission.toStringAsFixed(2)}',
                      style: pw.TextStyle(
                          fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Table.fromTextArray(
              headers: ['Sr. No', 'Name', 'Product', 'Email', 'Phone', 'Total Amount'],
              data: List.generate(_filteredCommissions.length, (index) {
                final item = _filteredCommissions[index];
                return [
                  '${index + 1}',
                  item.personName,
                  item.product,
                  item.email,
                  item.contact,
                  item.commissionDisplay,
                ];
              }),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerLeft,
                4: pw.Alignment.centerLeft,
                5: pw.Alignment.centerRight,
              },
            ),
          ];
        },
      ),
    );

    return pdf;
  }

  // 2. Export Excel / CSV Data Generator
  Future<void> _exportExcel() async {
    try {
      final pdf = await _generatePdfDocument();
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'commission_report.pdf',
      );
      _showSnackBar('Excel/Document exported successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to export document: $e', Colors.red);
    }
  }

  // 3. PDF Export (Save/Share)
  Future<void> _exportPdf() async {
    try {
      final pdf = await _generatePdfDocument();
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'commission_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      _showSnackBar('PDF generated successfully!', Colors.red);
    } catch (e) {
      _showSnackBar('PDF generation failed: $e', Colors.red);
    }
  }

  // 4. Direct Print
  Future<void> _printReport() async {
    try {
      final pdf = await _generatePdfDocument();
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Commission_Report',
      );
    } catch (e) {
      _showSnackBar('Printing failed: $e', Colors.red);
    }
  }

  // Details Popup Screen
  void _showDetailsPopup(BuildContext context, CommissionData item, int srNo, bool isDark) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          clipBehavior: Clip.antiAlias,
          backgroundColor: isDark ? const Color(0xFF16213E) : const Color(0xFFF4F6F9),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 700,
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Gradient Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF5B40E2), Color(0xFFC043C0), Color(0xFFE243A2)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.person, color: Color(0xFF5B40E2), size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.personName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Sr. No: #$srNo',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            _buildStatusBadge('approved', const Color(0xFFE8F5E9), const Color(0xFF4CAF50)),
                            _buildStatusBadge('Active', const Color(0xFFE3F2FD), const Color(0xFF2196F3)),
                            _buildStatusBadge('Franchise: NO', const Color(0xFFF5F5F5), const Color(0xFF757575), hasIcon: true),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildSectionTitle(Icons.info, 'Contact Details', const Color(0xFF5B40E2)),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1F2C4C) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            children: [
                              _buildDataRow('Sr. No', '#$srNo', isDark),
                              _buildDataRow('Product', item.product, isDark),
                              _buildDataRow('Email', item.email, isDark),
                              _buildDataRow('Phone', item.contact, isDark),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        _buildSectionTitle(Icons.category, 'Commission Details', const Color(0xFF5B40E2)),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1F2C4C) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...item.commission.map((comm) {
                                return _buildDataRow(
                                  _formatCommissionType(comm.commissionType),
                                  '(${comm.percentage}%): ₹${double.tryParse(comm.amount)?.toStringAsFixed(2) ?? '0.00'}',
                                  isDark,
                                  valueColor: _getCommissionColor(comm.commissionType),
                                );
                              }).toList(),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                              ),
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF5B40E2), Color(0xFFE243A2)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.account_balance_wallet, color: Colors.white, size: 18),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'Total Amount: ${item.commissionDisplay}',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
        );
      },
    );
  }

  Widget _buildStatusBadge(String text, Color bgColor, Color textColor, {bool hasIcon = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: textColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasIcon) ...[
            Icon(Icons.storefront, size: 14, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            text,
            style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title, Color color) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, size: 14, color: color),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDataRow(String label, String value, bool isDark, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(
                  color: isDark ? Colors.grey[400] : const Color(0xFF7F8C8D),
                  fontSize: 14,
                  fontWeight: FontWeight.w500
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.start,
              style: TextStyle(
                color: valueColor ?? (isDark ? Colors.white : const Color(0xFF2C3E50)),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _service.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final paginatedCommissions = _getPaginatedCommissions();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F5FA),
      appBar: AppBar(
        title: const Text('My Commission'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6342E7), Color(0xFFD946A3)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      clipBehavior: Clip.antiAlias,
                      backgroundColor: isDark ? const Color(0xFF16213E) : const Color(0xFFF0F4F8),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 500,
                          maxHeight: MediaQuery.of(context).size.height * 0.88,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: SingleChildScrollView(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      primaryColor: const Color(0xFF6342E7),
                                      colorScheme: ColorScheme.fromSeed(
                                        seedColor: const Color(0xFF6342E7),
                                        primary: const Color(0xFF6342E7),
                                      ),
                                    ),
                                    child: const ClipRect(
                                      child: SizedBox(
                                          height: 540,
                                          child: WithdrawScreen()
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              icon: const Icon(Icons.account_balance_wallet_outlined, size: 16, color: Color(0xFF6342E7)),
              label: const Text(
                'Withdraw',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6342E7)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error: $_error',
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : _commissions.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.money_off_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No commission records found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t earned any commission yet',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadData,
        child: Column(
          children: [
            // 🌟 Search & Filter Dropdown Bar
            _buildSearchBar(isDark, isMobile),

            // Table Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF16213E) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth: constraints.maxWidth,
                                  ),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      dividerColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                      dataTableTheme: DataTableThemeData(
                                        headingTextStyle: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: isDark ? Colors.grey[300] : const Color(0xFF5A6A85),
                                        ),
                                        dataTextStyle: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    child: DataTable(
                                      headingRowColor: WidgetStateProperty.all(
                                        isDark ? const Color(0xFF223157) : const Color(0xFFE8EEF4),
                                      ),
                                      headingRowHeight: 45,
                                      dataRowHeight: 65,
                                      horizontalMargin: 20,
                                      columnSpacing: 24,
                                      border: TableBorder(
                                        horizontalInside: BorderSide(
                                          color: isDark ? Colors.grey[800]! : const Color(0xFFEAEAEA),
                                          width: 1,
                                        ),
                                      ),
                                      columns: const [
                                        DataColumn(label: Text('Sr. No')),
                                        DataColumn(label: Text('Name')),
                                        DataColumn(label: Text('Product')),
                                        DataColumn(label: Text('Email')),
                                        DataColumn(label: Text('Phone')),
                                        DataColumn(label: Text('Commission Breakup')),
                                        DataColumn(label: Text('Total Amount')),
                                        DataColumn(label: Text('Actions')),
                                      ],
                                      rows: List.generate(paginatedCommissions.length, (index) {
                                        final item = paginatedCommissions[index];

                                        // Sr. No. Descending Order Formula
                                        final int globalIndex = (_currentPage - 1) * _itemsPerPage + index;
                                        final int srNo = _filteredCommissions.length - globalIndex;

                                        void triggerPopup() => _showDetailsPopup(context, item, srNo, isDark);

                                        return DataRow(
                                          cells: [
                                            DataCell(_clickableCellText('$srNo', triggerPopup)),
                                            DataCell(_clickableCellText(item.personName, triggerPopup, style: const TextStyle(fontWeight: FontWeight.w500))),
                                            DataCell(_clickableCellText(item.product, triggerPopup)),
                                            DataCell(_clickableCellText(item.email, triggerPopup)),
                                            DataCell(_clickableCellText(item.contact, triggerPopup)),
                                            DataCell(
                                              InkWell(
                                                onTap: triggerPopup,
                                                child: Container(
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  alignment: Alignment.centerLeft,
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: item.commission.map((comm) {
                                                      return Text(
                                                        '• ${_formatCommissionType(comm.commissionType)} (${comm.percentage}%): ₹${double.tryParse(comm.amount)?.toStringAsFixed(2) ?? '0.00'}',
                                                        style: TextStyle(fontSize: 11, color: _getCommissionColor(comm.commissionType), fontWeight: FontWeight.w500),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                                _clickableCellText(
                                                    item.commissionDisplay,
                                                    triggerPopup,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF39C12))
                                                )
                                            ),
                                            DataCell(
                                              IconButton(
                                                icon: const Icon(Icons.visibility, color: Colors.blue, size: 20),
                                                onPressed: triggerPopup,
                                              ),
                                            ),
                                          ],
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // 🌟 Pagination Widget
                    _buildPagination(isDark, isMobile),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Search & Filter Dropdown Bar Section
  Widget _buildSearchBar(bool isDarkMode, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: isMobile
          ? Column(
        children: [
          Row(
            children: [
              _buildFilterDropdown(isDarkMode),
              const SizedBox(width: 12),
              Expanded(child: _buildSearchTextField(isDarkMode)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildExportButtons(),
              Row(
                children: [
                  Text(
                    "Total: ${_filteredCommissions.length}",
                    style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  IconButton(onPressed: _resetFilters, icon: const Icon(Icons.refresh), color: Colors.red),
                ],
              ),
            ],
          ),
        ],
      )
          : Row(
        children: [
          _buildFilterDropdown(isDarkMode),
          const SizedBox(width: 12),
          Expanded(child: _buildSearchTextField(isDarkMode)),
          const SizedBox(width: 12),
          _buildExportButtons(),
          const SizedBox(width: 12),
          Text(
            "Total: ${_filteredCommissions.length}",
            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          IconButton(onPressed: _resetFilters, icon: const Icon(Icons.refresh), color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(bool isDarkMode) {
    return Container(
      width: 130,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterType,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6342E7)),
          style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF1E293B), fontSize: 13),
          isExpanded: true,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _filterType = newValue;
                _currentPage = 1;
                _applyFilters();
              });
            }
          },
          items: ['Name', 'Product', 'Email', 'Phone']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSearchTextField(bool isDarkMode) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.grey[800]! : Colors.grey.shade300),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 13),
        decoration: InputDecoration(
          hintText: "Search by $_filterType...",
          hintStyle: TextStyle(color: isDarkMode ? Colors.grey[500] : Colors.grey[600], fontSize: 13),
          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF6342E7)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, size: 16, color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            onPressed: () {
              _searchController.clear();
              _searchCommissions('');
            },
          )
              : null,
        ),
        onChanged: _searchCommissions,
      ),
    );
  }

  Widget _buildExportButtons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildExportIcon(
          icon: Icons.table_chart,
          color: Colors.green,
          tooltip: 'Export Excel',
          onTap: _exportExcel,
        ),
        const SizedBox(width: 8),
        _buildExportIcon(
          icon: Icons.picture_as_pdf,
          color: Colors.red,
          tooltip: 'Export PDF',
          onTap: _exportPdf,
        ),
        const SizedBox(width: 8),
        _buildExportIcon(
          icon: Icons.print,
          color: Colors.blue,
          tooltip: 'Print Report',
          onTap: _printReport,
        ),
      ],
    );
  }

  Widget _buildExportIcon({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 20),
        onPressed: onTap,
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
        padding: EdgeInsets.zero,
      ),
    );
  }

  // Pagination UI Component
  Widget _buildPagination(bool isDarkMode, bool isMobile) {
    if (_filteredCommissions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
        ),
      ),
      child: isMobile
          ? Column(
        children: [
          _buildPaginationControls(isDarkMode),
          const SizedBox(height: 8),
          _buildPaginationInfo(isDarkMode),
        ],
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPaginationInfo(isDarkMode),
          _buildPaginationControls(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildPaginationInfo(bool isDarkMode) {
    final start = _filteredCommissions.isEmpty
        ? 0
        : (_currentPage - 1) * _itemsPerPage + 1;
    final end = _filteredCommissions.isEmpty
        ? 0
        : (start + _itemsPerPage - 1) > _filteredCommissions.length
        ? _filteredCommissions.length
        : start + _itemsPerPage - 1;

    return Row(
      children: [
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF334155) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButton<int>(
            value: _itemsPerPage,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down,
                color: isDarkMode ? Colors.white70 : Colors.grey),
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
              fontSize: 12,
            ),
            items: _itemsPerPageOptions.map((e) {
              return DropdownMenuItem(value: e, child: Text(e.toString()));
            }).toList(),
            onChanged: _changeItemsPerPage,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Showing $start to $end of ${_filteredCommissions.length}',
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationControls(bool isDarkMode) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPageButton(
            icon: Icons.chevron_left,
            onTap: _currentPage > 1 ? _previousPage : null,
            isDarkMode: isDarkMode,
          ),
          ..._getPageNumbers().map((page) {
            if (page == -1) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '...',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              );
            }
            return _buildPageNumber(
              page: page,
              isSelected: page == _currentPage,
              isDarkMode: isDarkMode,
              onTap: () => _goToPage(page),
            );
          }),
          _buildPageButton(
            icon: Icons.chevron_right,
            onTap: _currentPage < _totalPages ? _nextPage : null,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );
  }

  List<int> _getPageNumbers() {
    if (_totalPages <= 7) {
      return List.generate(_totalPages, (i) => i + 1);
    }

    List<int> pages = [];
    if (_currentPage <= 4) {
      pages.addAll([1, 2, 3, 4, 5, -1, _totalPages]);
    } else if (_currentPage >= _totalPages - 3) {
      pages.addAll([1, -1, _totalPages - 4, _totalPages - 3, _totalPages - 2, _totalPages - 1, _totalPages]);
    } else {
      pages.addAll([1, -1, _currentPage - 1, _currentPage, _currentPage + 1, -1, _totalPages]);
    }
    return pages;
  }

  Widget _buildPageNumber({
    required int page,
    required bool isSelected,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6342E7) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          child: Text(
            page.toString(),
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isDarkMode ? Colors.grey[300] : Colors.black87),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(
          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18),
        onPressed: onTap,
        color: onTap != null
            ? (isDarkMode ? Colors.white : Colors.black87)
            : (isDarkMode ? Colors.grey[600] : Colors.grey[400]),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }

  // --- HELPER FUNCTIONS ---

  Widget _clickableCellText(String text, VoidCallback onTap, {TextStyle? style}) {
    return InkWell(
      onTap: onTap,
      hoverColor: Colors.transparent,
      splashColor: Colors.black12,
      child: Container(
        alignment: Alignment.centerLeft,
        width: double.infinity,
        height: double.infinity,
        child: Text(text, style: style),
      ),
    );
  }

  Color _getCommissionColor(String type) {
    switch (type.toLowerCase()) {
      case 'selling':
        return const Color(0xFF6342E7);
      case 'referral':
        return const Color(0xFF2ECC71);
      case 'bonus':
        return const Color(0xFFD946A3);
      default:
        return Colors.grey;
    }
  }

  String _formatCommissionType(String type) {
    switch (type.toLowerCase()) {
      case 'selling':
        return 'Selling';
      case 'referral':
        return 'Referral';
      case 'bonus':
        return 'Bonus';
      default:
        return type;
    }
  }
}