// lib/screens/marketing_partner/pending_commission_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'dart:io' show File;
import 'dart:html' as html; // Flutter Web साठी Download Handling
import 'package:share_plus/share_plus.dart';

// PDF & Printing Packages
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../api/marketing_service.dart';
import '../../models/marketing_partner/pending_commission_model.dart';

class PendingCommissionScreen extends StatefulWidget {
  const PendingCommissionScreen({super.key});

  @override
  State<PendingCommissionScreen> createState() => _PendingCommissionScreenState();
}

class _PendingCommissionScreenState extends State<PendingCommissionScreen> {
  final PendingCommissionService _service = PendingCommissionService();
  List<PendingCommissionItem> _commissions = [];
  List<PendingCommissionItem> _filteredCommissions = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _filterType = 'Name'; // Filter Dropdown: Name, Product, Company, Phone
  int _currentPage = 1;
  int _itemsPerPage = 10;
  final TextEditingController _searchController = TextEditingController();
  PendingCommissionResponse? _response;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _service.getPendingCommissions();
      if (response.status) {
        setState(() {
          _response = response;
          _commissions = response.data;
          _applyFilters();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterData(String query) {
    setState(() {
      _searchQuery = query;
      _currentPage = 1;
      _applyFilters();
    });
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
            return item.productName.toLowerCase().contains(query);
          case 'Company':
            return item.companyName.toLowerCase().contains(query);
          case 'Phone':
            return item.companyPhoneNumber.contains(query);
          default:
            return false;
        }
      }).toList();
    }
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

  List<PendingCommissionItem> _getPaginatedData() {
    int start = (_currentPage - 1) * _itemsPerPage;
    int end = start + _itemsPerPage;
    if (start >= _filteredCommissions.length) {
      return [];
    }
    if (end > _filteredCommissions.length) {
      end = _filteredCommissions.length;
    }
    return _filteredCommissions.sublist(start, end);
  }

  int get _totalPages =>
      _filteredCommissions.isEmpty ? 0 :
      (_filteredCommissions.length / _itemsPerPage).ceil();

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

  // 🟢 1. Web & Mobile Supported EXCEL Export
  Future<void> _exportToExcel() async {
    if (_filteredCommissions.isEmpty) {
      _showSnackBar('No data to export', Colors.orange);
      return;
    }

    try {
      final excelFile = excel.Excel.createExcel();
      final sheet = excelFile['Pending Commissions'];

      // Add headers
      final headers = [
        'SR No', 'Person Name', 'Product Name',
        'Company Name', 'Phone', 'Company Amount',
        'Profit %', 'Commission'
      ];
      sheet.appendRow(headers);

      // Add data rows
      for (int i = 0; i < _filteredCommissions.length; i++) {
        var item = _filteredCommissions[i];
        sheet.appendRow([
          i + 1,
          item.personName,
          item.productName,
          item.companyName,
          item.companyPhoneNumber,
          double.tryParse(item.companyAmount) ?? 0.0,
          double.tryParse(item.profitSharePercentage) ?? 0.0,
          double.tryParse(item.commission) ?? 0.0,
        ]);
      }

      final fileBytes = excelFile.encode();
      if (fileBytes != null) {
        if (kIsWeb) {
          final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', 'pending_commissions_${DateTime.now().millisecondsSinceEpoch}.xlsx')
            ..click();
          html.Url.revokeObjectUrl(url);
          _showSnackBar('Excel File Downloaded!', Colors.green);
        } else {
          final dir = await getTemporaryDirectory();
          final filePath = '${dir.path}/pending_commissions_${DateTime.now().millisecondsSinceEpoch}.xlsx';
          final file = File(filePath);
          await file.writeAsBytes(fileBytes);

          await Share.shareXFiles(
            [XFile(filePath)],
            text: 'Pending Commissions Excel Export',
          );
        }
      }
    } catch (e) {
      _showSnackBar('Export failed: ${e.toString()}', Colors.red);
    }
  }

  // 🔴 2. Web & Mobile Supported PDF Export
  Future<void> _exportToPdf() async {
    if (_filteredCommissions.isEmpty) {
      _showSnackBar('No data to export', Colors.orange);
      return;
    }

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Pending Commissions Report',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: ['SR No', 'Person', 'Product', 'Company', 'Amount', 'Commission'],
                data: List<List<String>>.generate(
                  _filteredCommissions.length,
                      (index) {
                    final item = _filteredCommissions[index];
                    return [
                      (index + 1).toString(),
                      item.personName,
                      item.productName,
                      item.companyName,
                      'Rs. ${item.companyAmount}',
                      'Rs. ${item.commission}',
                    ];
                  },
                ),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.purple800),
                rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300))),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(6),
              ),
            ];
          },
        ),
      );

      final bytes = await pdf.save();

      if (kIsWeb) {
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'pending_commissions_${DateTime.now().millisecondsSinceEpoch}.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
        _showSnackBar('PDF File Downloaded!', Colors.green);
      } else {
        final output = await getTemporaryDirectory();
        final file = File('${output.path}/pending_commissions_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(bytes);

        await Share.shareXFiles([XFile(file.path)], text: 'Pending Commissions PDF');
      }
    } catch (e) {
      _showSnackBar('PDF export failed: ${e.toString()}', Colors.red);
    }
  }

  // 🔵 3. Web & Mobile Supported DOC Export
  void _exportDOC() {
    if (_filteredCommissions.isEmpty) {
      _showSnackBar('No data to export', Colors.orange);
      return;
    }

    try {
      final content = StringBuffer();
      content.writeln("Pending Commissions Report\n");
      content.writeln("=" * 50);
      for (int i = 0; i < _filteredCommissions.length; i++) {
        var item = _filteredCommissions[i];
        content.writeln("SR No: ${i + 1}");
        content.writeln("Person Name: ${item.personName}");
        content.writeln("Product Name: ${item.productName}");
        content.writeln("Company Name: ${item.companyName}");
        content.writeln("Phone: ${item.companyPhoneNumber}");
        content.writeln("Company Amount: Rs. ${item.companyAmount}");
        content.writeln("Profit Share %: ${item.profitSharePercentage}%");
        content.writeln("Commission: Rs. ${item.commission}");
        content.writeln("-" * 30);
      }
      final blob = html.Blob([content.toString()]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "pending_commissions_${DateTime.now().millisecondsSinceEpoch}.doc")
        ..click();
      html.Url.revokeObjectUrl(url);
      _showSnackBar('DOC File Downloaded!', Colors.green);
    } catch (e) {
      _showSnackBar('DOC export failed: ${e.toString()}', Colors.red);
    }
  }

  // 🎨 Updated Popup Window matching Image Design (SR No removed)
  void _showCommissionDetails(PendingCommissionItem item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          width: 480,
          color: const Color(0xFFF4F6FB), // Light greyish background
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Purple to Pink Gradient Header
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF8B2FC9),
                        Color(0xFFE52E71),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFF8B2FC9),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          item.personName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Pills (Tags)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildStatusPill(
                            label: 'Approved',
                            bgColor: const Color(0xFFE8F8EE),
                            textColor: const Color(0xFF2E7D32),
                            borderColor: const Color(0xFFA5D6A7),
                          ),
                          _buildStatusPill(
                            label: 'Active',
                            bgColor: const Color(0xFFE3F2FD),
                            textColor: const Color(0xFF1565C0),
                            borderColor: const Color(0xFF90CAF9),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 2. Contact Details Section (Card)
                      _buildSectionTitle(
                        icon: Icons.info_rounded,
                        title: 'Contact Details',
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildCardRow('Product', item.productName),
                            const Divider(height: 1, color: Color(0xFFF0F0F0)),
                            _buildCardRow('Company', item.companyName),
                            const Divider(height: 1, color: Color(0xFFF0F0F0)),
                            _buildCardRow('Phone', item.companyPhoneNumber),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 3. Commission Details Section (Card)
                      _buildSectionTitle(
                        icon: Icons.bubble_chart_rounded,
                        title: 'Commission Details',
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildCardRow('Company Amount', '₹${item.companyAmount}'),
                            const Divider(height: 1, color: Color(0xFFF0F0F0)),
                            _buildCardRow('Profit Share %', '${item.profitSharePercentage}%'),
                            const Divider(height: 1, color: Color(0xFFF0F0F0)),
                            _buildCardRow(
                              'Commission',
                              '₹${item.commission}',
                              valueColor: const Color(0xFF6B42F2),
                              isBold: true,
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
      ),
    );
  }

  // Helper Widget for Status Pills
  Widget _buildStatusPill({
    required String label,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Helper Widget for Section Titles with Icon
  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF6B42F2).withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 16,
            color: const Color(0xFF6B42F2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6B42F2),
          ),
        ),
      ],
    );
  }

  // Helper Widget for Inside Card Rows
  Widget _buildCardRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF757575),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: valueColor ?? const Color(0xFF212121),
                fontSize: 14,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportIcons(bool isDarkMode) {
    return Row(
      children: [
        Tooltip(
          message: "Export Excel",
          child: InkWell(
            onTap: _exportToExcel,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.green[900]! : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset("assets/icon/xls.png", height: 20, width: 20,
                  errorBuilder: (_, __, ___) => Icon(Icons.table_chart, size: 20, color: isDarkMode ? Colors.green[300] : Colors.green)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "Export PDF",
          child: InkWell(
            onTap: _exportToPdf,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.red[900]! : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset("assets/icon/pdf.png", height: 20, width: 20,
                  errorBuilder: (_, __, ___) => Icon(Icons.picture_as_pdf, size: 20, color: isDarkMode ? Colors.red[300] : Colors.red)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "Export DOC",
          child: InkWell(
            onTap: _exportDOC,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.blue[900]! : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset("assets/icon/doc.png", height: 20, width: 20,
                  errorBuilder: (_, __, ___) => Icon(Icons.description, size: 20, color: isDarkMode ? Colors.blue[300] : Colors.blue)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(bool isDarkMode) {
    return Container(
      width: 120,
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterType,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4158D0)),
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 13),
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
          items: ['Name', 'Product', 'Company', 'Phone']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final paginatedData = _getPaginatedData();

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF0F5FA),
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
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(left: 12, right: 12, top: 16, bottom: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF7F26CD),
                  Color(0xFFD12A81),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Pending Commission',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      onPressed: _loadData,
                      tooltip: 'Reload',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                )
              ],
            ),
          ),

          // Summary Section
          if (_response != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF16213E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                    'Total Pending',
                    _response?.totalPendingCommission ?? '0',
                    Icons.pending_actions,
                    Colors.orange,
                    isDarkMode,
                  ),
                  _buildSummaryItem(
                    'Total Enquiries',
                    _response?.totalPendingEnquiries?.toString() ?? '0',
                    Icons.assignment,
                    Colors.blue,
                    isDarkMode,
                  ),
                  _buildSummaryItem(
                    'Partner',
                    _response?.marketingPartnerName ?? 'N/A',
                    Icons.person,
                    Colors.green,
                    isDarkMode,
                  ),
                ],
              ),
            ),

          // Filter, Search, Export Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF16213E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth > 700;

                Widget searchInput = Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _filterData,
                    style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Search by $_filterType...',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF4158D0), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: Icon(Icons.clear, color: isDarkMode ? Colors.white : Colors.grey, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          _filterData('');
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                  ),
                );

                Widget actionAndTotalControls = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildExportIcons(isDarkMode),
                    const SizedBox(width: 12),
                    Text(
                      'Total: ${_filteredCommissions.length}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: _resetFilters,
                      child: const Icon(Icons.refresh, size: 18, color: Colors.red),
                    ),
                  ],
                );

                if (isWide) {
                  return Row(
                    children: [
                      _buildFilterDropdown(isDarkMode),
                      const SizedBox(width: 8),
                      Expanded(child: searchInput),
                      const SizedBox(width: 12),
                      actionAndTotalControls,
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Row(
                        children: [
                          _buildFilterDropdown(isDarkMode),
                          const SizedBox(width: 8),
                          Expanded(child: searchInput),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: actionAndTotalControls,
                      ),
                    ],
                  );
                }
              },
            ),
          ),

          // Data Table Container
          Expanded(
            child: paginatedData.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 64,
                    color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No pending commissions found',
                    style: TextStyle(
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
                : Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDarkMode ? Colors.grey[800]! : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
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
                        child: DataTable(
                          columnSpacing: 36,
                          headingRowHeight: 48,
                          dataRowHeight: 52,
                          horizontalMargin: 16,
                          headingRowColor: WidgetStateProperty.all(
                            isDarkMode ? const Color(0xFF16213E) : const Color(0xFFF8FAFC),
                          ),
                          border: TableBorder.all(
                            color: isDarkMode ? Colors.grey[800]! : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                          headingTextStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.grey[300] : const Color(0xFF334155),
                            fontSize: 13,
                          ),
                          columns: const [
                            DataColumn(label: Text('SR No')),
                            DataColumn(label: Text('Person')),
                            DataColumn(label: Text('Product')),
                            DataColumn(label: Text('Company')),
                            DataColumn(label: Text('Amount')),
                            DataColumn(label: Text('Commission')),
                            DataColumn(
                              label: SizedBox(
                                width: 60,
                                child: Text(
                                  'Action',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                          rows: paginatedData.asMap().entries.map((entry) {
                            int index = entry.key;
                            var item = entry.value;

                            int globalIndex = ((_currentPage - 1) * _itemsPerPage) + index;
                            int srNo = _filteredCommissions.length - globalIndex;

                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    srNo.toString(),
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  onTap: () => _showCommissionDetails(item),
                                ),
                                DataCell(
                                  Text(
                                    item.personName,
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  onTap: () => _showCommissionDetails(item),
                                ),
                                DataCell(
                                  Text(
                                    item.productName,
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  onTap: () => _showCommissionDetails(item),
                                ),
                                DataCell(
                                  Text(
                                    item.companyName,
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  onTap: () => _showCommissionDetails(item),
                                ),
                                DataCell(
                                  Text(
                                    '₹${item.companyAmount}',
                                    style: const TextStyle(
                                      color: Color(0xFFF39C12),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  onTap: () => _showCommissionDetails(item),
                                ),
                                DataCell(
                                  Text(
                                    '₹${item.commission}',
                                    style: const TextStyle(
                                      color: Color(0xFF2ECC71),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  onTap: () => _showCommissionDetails(item),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 60,
                                    child: Center(
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.visibility,
                                          color: Color(0xFF4158D0),
                                          size: 20,
                                        ),
                                        onPressed: () => _showCommissionDetails(item),
                                        tooltip: 'View Details',
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // 🟣 Complete Image Matching Pagination Section (Dropdown + Showing text + Buttons)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.only(left: 12, right: 12, bottom: 12, top: 4),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF16213E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isMobile = constraints.maxWidth < 600;

                // 1. Items Per Page Dropdown
                Widget itemsPerPageDropdown = Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _itemsPerPage,
                      icon: const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _itemsPerPage = newValue;
                            _currentPage = 1;
                          });
                        }
                      },
                      items: [5, 10, 25, 50, 100]
                          .map((int value) => DropdownMenuItem<int>(
                        value: value,
                        child: Text('$value'),
                      ))
                          .toList(),
                    ),
                  ),
                );

                // 2. Info Text (Showing X to Y of Z)
                int startItem = _filteredCommissions.isEmpty
                    ? 0
                    : ((_currentPage - 1) * _itemsPerPage) + 1;
                int endItem = (_currentPage * _itemsPerPage) > _filteredCommissions.length
                    ? _filteredCommissions.length
                    : (_currentPage * _itemsPerPage);

                Widget showingInfoText = Text(
                  'Showing $startItem to $endItem of ${_filteredCommissions.length}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                );

                // 3. Navigation Buttons (< 1 >)
                Widget paginationButtons = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Previous Button
                    InkWell(
                      onTap: _currentPage > 1
                          ? () {
                        setState(() {
                          _currentPage--;
                        });
                      }
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDarkMode ? Colors.grey[700]! : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.chevron_left,
                          size: 20,
                          color: _currentPage > 1
                              ? (isDarkMode ? Colors.white : Colors.grey[700])
                              : Colors.grey[300],
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Current Page Box
                    Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5333ED),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_currentPage',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(width: 6),

                    // Next Button
                    InkWell(
                      onTap: _currentPage < _totalPages
                          ? () {
                        setState(() {
                          _currentPage++;
                        });
                      }
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDarkMode ? Colors.grey[700]! : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: _currentPage < _totalPages
                              ? (isDarkMode ? Colors.white : Colors.grey[700])
                              : Colors.grey[300],
                        ),
                      ),
                    ),
                  ],
                );

                // Responsive Layout based on screen width
                if (isMobile) {
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          itemsPerPageDropdown,
                          paginationButtons,
                        ],
                      ),
                      const SizedBox(height: 8),
                      showingInfoText,
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      itemsPerPageDropdown,
                      const SizedBox(width: 16),
                      showingInfoText,
                      const Spacer(),
                      paginationButtons,
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
      String label,
      String value,
      IconData icon,
      Color color,
      bool isDarkMode,
      ) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}