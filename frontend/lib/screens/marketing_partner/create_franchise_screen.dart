// lib/screens/marketing_partner/create_franchise_screen.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'dart:html' as html;
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../api/api_service.dart';
import '../../api/marketing_service.dart';
import '../../models/marketing_partner/franchise_referral_model.dart';

// ============================================================
// CONSTANTS
// ============================================================
class FranchiseConstants {
  static const String defaultReferralCode = 'FRANCHISE2024';
  static const List<String> filterOptions = ['Franchise Name', 'Owner Name', 'Status'];
  static const List<int> itemsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];
}

// ============================================================
// MAIN WIDGET
// ============================================================
class CreateFranchiseScreen extends StatefulWidget {
  const CreateFranchiseScreen({super.key});

  @override
  State<CreateFranchiseScreen> createState() => _CreateFranchiseScreenState();
}

class _CreateFranchiseScreenState extends State<CreateFranchiseScreen> {
  final FranchiseReferralService _service = FranchiseReferralService();

  List<FranchiseListModel> _franchises = [];
  List<FranchiseListModel> _filteredFranchises = [];
  List<FranchiseListModel> _paginatedFranchises = [];

  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isExporting = false;
  String? _error;

  // Search & Filter
  String _searchQuery = '';
  String _filterType = 'Franchise Name';
  final TextEditingController _searchController = TextEditingController();

  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalPages = 1;

  // Referral Data
  String? _partnerReferralCode;
  String? _userRole;
  bool _isMarketingPartner = false;

  // Popup Controllers
  final TextEditingController _referralCodeController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  FranchiseListModel? _selectedFranchise;

  // ============================================================
  // LIFECYCLE
  // ============================================================
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _referralCodeController.dispose();
    _productNameController.dispose();
    _service.dispose();
    super.dispose();
  }

  // ============================================================
  // DATA LOADING
  // ============================================================
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      _partnerReferralCode = prefs.getString('referral_code') ??
          prefs.getString('partner_referral_code') ??
          FranchiseConstants.defaultReferralCode;

      _userRole = prefs.getString('user_role') ?? '';

      final List<String> validRoles = [
        'marketing partner',
        'marketing_partner',
        'marketingpartner',
        'Marketing Partner',
        'Marketing_Partner',
        'marketing-partner',
        'Marketing-Partner',
      ];

      _isMarketingPartner = validRoles.any((role) =>
          _userRole!.toLowerCase().contains(role.toLowerCase())
      );

      if (!_isMarketingPartner) {
        final isAdmin = _userRole!.toLowerCase().contains('admin') ||
            _userRole!.toLowerCase().contains('superuser');

        if (isAdmin) {
          _isMarketingPartner = true;
          print('✅ Admin user granted access to franchise feature');
        }
      }

      print('🔍 User Role: "$_userRole"');
      print('🔍 Is Marketing Partner: $_isMarketingPartner');

      if (!_isMarketingPartner) {
        setState(() {
          _error = 'Only Marketing Partners can generate franchise referral links.\nYour role: ${_userRole ?? "Not set"}';
          _isLoading = false;
        });
        return;
      }

      final franchises = await _service.getFranchisesForReferral();

      setState(() {
        _franchises = franchises;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception:', '');
        _isLoading = false;
      });
    }
  }

  // ============================================================
  // FILTER & PAGINATION
  // ============================================================
  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredFranchises = List.from(_franchises);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredFranchises = _franchises.where((franchise) {
        switch (_filterType) {
          case 'Franchise Name':
            return franchise.franchiseName.toLowerCase().contains(query);
          case 'Owner Name':
            return franchise.ownerName?.toLowerCase().contains(query) ?? false;
          case 'Status':
            return franchise.status?.toLowerCase().contains(query) ?? false;
          default:
            return false;
        }
      }).toList();
    }
    _applyPagination();
  }

  void _applyPagination() {
    if (_filteredFranchises.isEmpty) {
      _paginatedFranchises = [];
      _totalPages = 1;
      _currentPage = 1;
      setState(() {});
      return;
    }

    _totalPages = (_filteredFranchises.length / _itemsPerPage).ceil();
    if (_currentPage > _totalPages) _currentPage = _totalPages;
    if (_currentPage < 1) _currentPage = 1;

    int start = (_currentPage - 1) * _itemsPerPage;
    int end = start + _itemsPerPage;
    if (end > _filteredFranchises.length) end = _filteredFranchises.length;

    _paginatedFranchises = _filteredFranchises.sublist(start, end);
    setState(() {});
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _filterType = 'Franchise Name';
      _searchController.clear();
      _currentPage = 1;
      _applyFilters();
    });
  }

  // ============================================================
  // REFERRAL LINK GENERATION
  // ============================================================
  void _showReferralCodePopup(BuildContext context, FranchiseListModel franchise) {
    if (!mounted) return;

    _selectedFranchise = franchise;
    _referralCodeController.text = _partnerReferralCode ?? FranchiseConstants.defaultReferralCode;
    _productNameController.text = franchise.franchiseName;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.storefront, color: Color(0xFF7B2FBE)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Generate Franchise Referral',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () => Navigator.pop(dialogContext),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFranchiseInfoCard(franchise),
              const SizedBox(height: 16),
              _buildProductNameInput(),
              const SizedBox(height: 12),
              _buildReferralCodeInput(),
              const SizedBox(height: 8),
              Text(
                'Note: This generates a unique referral link for this franchise.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isGenerating
                  ? null
                  : () {
                Navigator.pop(dialogContext);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) _generateReferralLink(context);
                });
              },
              icon: _isGenerating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.link, size: 16),
              label: Text(_isGenerating ? 'Generating...' : 'Generate Link'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7B2FBE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildFranchiseInfoCard(FranchiseListModel franchise) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Franchise: ${franchise.franchiseName}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (franchise.ownerName != null)
            Text(
              'Owner: ${franchise.ownerName}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          if (franchise.status != null)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: franchise.status == 'active' ? Colors.green.shade100 : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                franchise.status ?? '',
                style: TextStyle(
                  fontSize: 10,
                  color: franchise.status == 'active' ? Colors.green.shade700 : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProductNameInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Name',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _productNameController,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Enter product name (e.g., galaxy-s-24)',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(
                Icons.shopping_bag,
                color: Color(0xFF7B2FBE),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReferralCodeInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Referral Code',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _referralCodeController,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Enter referral code',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(
                Icons.code,
                color: Color(0xFF7B2FBE),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generateReferralLink(BuildContext context) async {
    String productName = _productNameController.text.trim();
    String referralCode = _referralCodeController.text.trim();

    if (productName.isEmpty) {
      _showSnackBar('Please enter a product name', Colors.orange);
      return;
    }

    if (referralCode.isEmpty) {
      _showSnackBar('Please enter a referral code', Colors.orange);
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final response = await _service.generateReferralLink(
        product: productName,
        referralCode: referralCode,
      );

      print('🟣 Response Status: ${response.status}');
      print('🟣 Response Message: ${response.message}');

      if (mounted) {
        setState(() => _isGenerating = false);

        if (response.status == 'success') {
          _showReferralResultDialog(context, response);
        } else {
          _showSnackBar(response.message, Colors.orange);
        }
      }
    } catch (e) {
      print('🔴 Generate Referral Error: $e');
      if (mounted) {
        setState(() => _isGenerating = false);
        _showSnackBar('Failed: ${e.toString()}', Colors.red);
      }
    }
  }

  void _showReferralResultDialog(BuildContext context, FranchiseReferralResponse response) {
    if (!mounted || response.data == null) return;

    final data = response.data!;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '✅ Referral Link Generated!',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        response.message,
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildInfoRow('Product', data.product),
              const SizedBox(height: 4),
              _buildInfoRow('Referral Code', data.referralCode),
              const SizedBox(height: 12),
              const Text(
                '🔗 Referral Link',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        data.referralLink,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.blue, size: 20),
                      onPressed: () => _copyToClipboard(context, data.referralLink),
                      tooltip: 'Copy Link',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.green, size: 20),
                      onPressed: () => _shareLink(data.referralLink),
                      tooltip: 'Share Link',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () => _copyToClipboard(context, data.referralLink),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Link'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  void _shareLink(String link) async {
    try {
      await Share.share(
        'Check out this franchise referral link: $link',
        subject: 'Franchise Referral',
      );
    } catch (e) {
      _showSnackBar('Share failed: ${e.toString()}', Colors.red);
    }
  }

  // ============================================================
  // EXPORT FUNCTIONS
  // ============================================================
  Future<void> _exportToExcel() async {
    if (_filteredFranchises.isEmpty) {
      _showSnackBar('No franchises to export', Colors.orange);
      return;
    }

    setState(() => _isExporting = true);

    try {
      final excelFile = excel.Excel.createExcel();
      final sheet = excelFile['Franchises'];

      sheet.appendRow([
        'SR No',
        'Franchise Name',
        'Company',
        'Owner',
        'City',
        'State',
        'Status',
        'Referral Code'
      ]);

      for (int i = 0; i < _filteredFranchises.length; i++) {
        final franchise = _filteredFranchises[i];

        sheet.appendRow([
          (i + 1).toString(),
          franchise.franchiseName,
          franchise.companyName ?? '',
          franchise.ownerName ?? '',
          franchise.city ?? '',
          franchise.state ?? '',
          franchise.status ?? 'active',
          franchise.franchiseReferralCode ?? _partnerReferralCode ?? FranchiseConstants.defaultReferralCode,
        ]);
      }

      final fileBytes = excelFile.encode();
      if (fileBytes != null) {
        await _downloadFile(
          Uint8List.fromList(fileBytes),
          'franchises_${DateTime.now().millisecondsSinceEpoch}.xlsx',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          'Excel Downloaded Successfully!',
        );
      }
    } catch (e) {
      _showSnackBar('Export failed: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportToPdf() async {
    if (_filteredFranchises.isEmpty) {
      _showSnackBar('No franchises to export', Colors.orange);
      return;
    }

    setState(() => _isExporting = true);

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
                    pw.Text('Franchise List',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: ${_getFormattedDate()}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: ['SR No', 'Franchise Name', 'Owner', 'City', 'State', 'Status'],
                data: _filteredFranchises.asMap().entries.map((entry) {
                  final index = entry.key;
                  final franchise = entry.value;
                  return [
                    (index + 1).toString(),
                    franchise.franchiseName,
                    franchise.ownerName ?? '-',
                    franchise.city ?? '-',
                    franchise.state ?? '-',
                    franchise.status ?? 'active',
                  ];
                }).toList(),
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
      await _downloadFile(
        bytes,
        'franchises_${DateTime.now().millisecondsSinceEpoch}.pdf',
        'application/pdf',
        'PDF Downloaded Successfully!',
      );
    } catch (e) {
      _showSnackBar('PDF export failed: ${e.toString()}', Colors.red);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportToDoc() async {
    if (_filteredFranchises.isEmpty) {
      _showSnackBar('No franchises to export', Colors.orange);
      return;
    }

    try {
      final content = StringBuffer();
      content.writeln("Franchise List\n");
      content.writeln("=" * 50);
      for (int i = 0; i < _filteredFranchises.length; i++) {
        final f = _filteredFranchises[i];
        content.writeln("SR No: ${i + 1}");
        content.writeln("Franchise Name: ${f.franchiseName}");
        content.writeln("Company: ${f.companyName ?? '-'}");
        content.writeln("Owner: ${f.ownerName ?? '-'}");
        content.writeln("City: ${f.city ?? '-'}");
        content.writeln("State: ${f.state ?? '-'}");
        content.writeln("Status: ${f.status ?? 'active'}");
        content.writeln("Referral Code: ${f.franchiseReferralCode ?? _partnerReferralCode ?? FranchiseConstants.defaultReferralCode}");
        content.writeln("-" * 30);
      }

      final bytes = Uint8List.fromList(utf8.encode(content.toString()));
      await _downloadFile(
        bytes,
        'franchises_${DateTime.now().millisecondsSinceEpoch}.doc',
        'application/msword',
        'DOC Downloaded Successfully!',
      );
    } catch (e) {
      _showSnackBar('DOC export failed: ${e.toString()}', Colors.red);
    }
  }

  // ============================================================
  // HELPER FUNCTIONS
  // ============================================================
  String _getFormattedDate() {
    final now = DateTime.now();
    return '${now.day}/${now.month}/${now.year}';
  }

  Future<void> _downloadFile(
      Uint8List bytes,
      String fileName,
      String mimeType,
      String successMessage,
      ) async {
    if (kIsWeb) {
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
      _showSnackBar(successMessage, Colors.green);
    } else {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Franchise Export',
      );
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('Link copied to clipboard!', Colors.green);
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

  // ============================================================
  // UI BUILDERS
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorWidget()
          : _buildContent(isDarkMode, isMobile),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDarkMode, bool isMobile) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFilterSection(isMobile, isDarkMode),
          const SizedBox(height: 12),
          if (_filteredFranchises.isEmpty)
            Expanded(child: _buildEmptyState())
          else ...[
            Expanded(
              child: _buildFranchiseTable(isDarkMode),
            ),
            const SizedBox(height: 12),
            _buildPagination(isDarkMode, isMobile),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          const Icon(Icons.storefront_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No franchises found'
                : 'No franchises match your search',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms or filter',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Reset Search'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterSection(bool isMobile, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
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
              Expanded(child: _buildSearchField(isDarkMode)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildExportIcons(isDarkMode),
              Row(
                children: [
                  Text(
                    "Total: ${_filteredFranchises.length}",
                    style: TextStyle(
                      color: isDarkMode ? Colors.white70 : Colors.grey,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _resetFilters,
                    icon: const Icon(Icons.refresh),
                    color: Colors.red,
                    tooltip: 'Reset Filters',
                  ),
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
          Expanded(child: _buildSearchField(isDarkMode)),
          const SizedBox(width: 12),
          _buildExportIcons(isDarkMode),
          const SizedBox(width: 12),
          Text(
            "Total: ${_filteredFranchises.length}",
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: _resetFilters,
            icon: const Icon(Icons.refresh),
            color: Colors.red,
            tooltip: 'Reset Filters',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(bool isDarkMode) {
    return Container(
      width: 150,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterType,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
          style: TextStyle(
            color: isDarkMode ? Colors.white : const Color(0xFF1E293B),
            fontSize: 13,
          ),
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
          items: FranchiseConstants.filterOptions
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSearchField(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: "Search by $_filterType...",
          hintStyle: TextStyle(
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            fontSize: 13,
          ),
          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF6366F1)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(
              Icons.clear,
              size: 16,
              color: isDarkMode ? Colors.white70 : Colors.grey,
            ),
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
    );
  }

  Widget _buildExportIcons(bool isDarkMode) {
    return Row(
      children: [
        Tooltip(
          message: "Export Excel",
          child: InkWell(
            onTap: _isExporting ? null : _exportToExcel,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.green[900]! : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                "assets/icon/xls.png",
                height: 20,
                width: 20,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.table_chart,
                  size: 20,
                  color: isDarkMode ? Colors.green[300] : Colors.green,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "Export PDF",
          child: InkWell(
            onTap: _isExporting ? null : _exportToPdf,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.red[900]! : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                "assets/icon/pdf.png",
                height: 20,
                width: 20,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.picture_as_pdf,
                  size: 20,
                  color: isDarkMode ? Colors.red[300] : Colors.red,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "Export DOC",
          child: InkWell(
            onTap: _isExporting ? null : _exportToDoc,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.blue[900]! : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Image.asset(
                "assets/icon/doc.png",
                height: 20,
                width: 20,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.description,
                  size: 20,
                  color: isDarkMode ? Colors.blue[300] : Colors.blue,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFranchiseTable(bool isDarkMode) {
    final borderSide = BorderSide(
      color: isDarkMode ? Colors.grey[700]! : const Color(0xFFCBD5E1),
      width: 1.0,
    );

    final List<double> columnWidths = [
      60.0,  // Sr. No.
      180.0, // Franchise Name
      120.0, // Company
      120.0, // Owner
      120.0, // City
      120.0, // State
      100.0, // Status
      120.0, // Referral Code
      80.0,  // Action
    ];

    double totalTableWidth = columnWidths.reduce((a, b) => a + b);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.grey[700]! : const Color(0xFFCBD5E1)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double tableWidth = constraints.maxWidth > totalTableWidth
              ? constraints.maxWidth
              : totalTableWidth;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  // FIXED HEADER
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF16213E) : const Color(0xFFEEF2F6),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                      border: Border(bottom: borderSide),
                    ),
                    child: Table(
                      columnWidths: {
                        0: FixedColumnWidth(columnWidths[0]),
                        1: constraints.maxWidth > totalTableWidth ? const FlexColumnWidth() : FixedColumnWidth(columnWidths[1]),
                        2: FixedColumnWidth(columnWidths[2]),
                        3: FixedColumnWidth(columnWidths[3]),
                        4: FixedColumnWidth(columnWidths[4]),
                        5: FixedColumnWidth(columnWidths[5]),
                        6: FixedColumnWidth(columnWidths[6]),
                        7: FixedColumnWidth(columnWidths[7]),
                        8: FixedColumnWidth(columnWidths[8]),
                      },
                      border: TableBorder(
                        verticalInside: borderSide,
                      ),
                      children: [
                        TableRow(
                          children: [
                            _buildHeaderCell('Sr. No.', isDarkMode),
                            _buildHeaderCell('Franchise Name', isDarkMode),
                            _buildHeaderCell('Company', isDarkMode),
                            _buildHeaderCell('Owner', isDarkMode),
                            _buildHeaderCell('City', isDarkMode),
                            _buildHeaderCell('State', isDarkMode),
                            _buildHeaderCell('Status', isDarkMode),
                            _buildHeaderCell('Referral Code', isDarkMode),
                            _buildHeaderCell('Action', isDarkMode),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // SCROLLABLE DATA ROWS WITH CLICKABLE FEATURE
                  Expanded(
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Table(
                          columnWidths: {
                            0: FixedColumnWidth(columnWidths[0]),
                            1: constraints.maxWidth > totalTableWidth ? const FlexColumnWidth() : FixedColumnWidth(columnWidths[1]),
                            2: FixedColumnWidth(columnWidths[2]),
                            3: FixedColumnWidth(columnWidths[3]),
                            4: FixedColumnWidth(columnWidths[4]),
                            5: FixedColumnWidth(columnWidths[5]),
                            6: FixedColumnWidth(columnWidths[6]),
                            7: FixedColumnWidth(columnWidths[7]),
                            8: FixedColumnWidth(columnWidths[8]),
                          },
                          border: TableBorder(
                            horizontalInside: borderSide,
                            verticalInside: borderSide,
                          ),
                          children: _paginatedFranchises.asMap().entries.map((entry) {
                            int index = entry.key;
                            var franchise = entry.value;

                            final int globalIndex = (_currentPage - 1) * _itemsPerPage + index;
                            final int srNo = _filteredFranchises.length - globalIndex;

                            return TableRow(
                              decoration: BoxDecoration(
                                color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
                              ),
                              children: [
                                _buildClickableDataCell(
                                  Center(
                                    child: Text(
                                      srNo.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDarkMode ? Colors.white : const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                  franchise,
                                ),
                                _buildClickableDataCell(
                                  Text(
                                    franchise.franchiseName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: isDarkMode ? Colors.white : const Color(0xFF475569),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  franchise,
                                ),
                                _buildClickableDataCell(
                                  Text(
                                    franchise.companyName ?? '-',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.grey[400] : const Color(0xFF475569),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  franchise,
                                ),
                                _buildClickableDataCell(
                                  Text(
                                    franchise.ownerName ?? '-',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.grey[400] : const Color(0xFF475569),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  franchise,
                                ),
                                _buildClickableDataCell(
                                  Text(
                                    franchise.city ?? '-',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.grey[400] : const Color(0xFF475569),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  franchise,
                                ),
                                _buildClickableDataCell(
                                  Text(
                                    franchise.state ?? '-',
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.grey[400] : const Color(0xFF475569),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  franchise,
                                ),
                                _buildClickableDataCell(
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: franchise.status == 'active'
                                            ? (isDarkMode ? const Color(0xFF064E3B) : const Color(0xFFE6F4EA))
                                            : (isDarkMode ? Colors.grey[800] : Colors.grey[200]),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        franchise.status ?? 'active',
                                        style: TextStyle(
                                          color: franchise.status == 'active'
                                              ? (isDarkMode ? const Color(0xFF34D399) : const Color(0xFF137333))
                                              : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                  franchise,
                                ),
                                _buildClickableDataCell(
                                  Text(
                                    franchise.franchiseReferralCode ??
                                        _partnerReferralCode ??
                                        FranchiseConstants.defaultReferralCode,
                                    style: TextStyle(
                                      color: isDarkMode ? Colors.grey[400] : const Color(0xFF475569),
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  franchise,
                                ),
                                _buildClickableDataCell(
                                  Center(
                                    child: Icon(Icons.link, size: 18, color: const Color(0xFF4158D0)),
                                  ),
                                  franchise,
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
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

  Widget _buildHeaderCell(String label, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.grey[300] : const Color(0xFF334155),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildClickableDataCell(Widget child, FranchiseListModel franchise) {
    return InkWell(
      onTap: () => _showReferralCodePopup(context, franchise),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Container(
          alignment: Alignment.centerLeft,
          height: 24,
          child: child,
        ),
      ),
    );
  }

  Widget _buildPagination(bool isDarkMode, bool isMobile) {
    if (_filteredFranchises.isEmpty) return const SizedBox.shrink();

    final entriesWidget = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Show ", style: TextStyle(fontSize: 11)),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF334155) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
          ),
          child: DropdownButton<int>(
            value: _itemsPerPage,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white70 : Colors.grey),
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 11),
            items: FranchiseConstants.itemsPerPageOptions
                .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                .toList(),
            onChanged: (int? value) {
              if (value != null) {
                setState(() {
                  _itemsPerPage = value;
                  _currentPage = 1;
                  _applyPagination();
                });
              }
            },
          ),
        ),
        const Text(" entries", style: TextStyle(fontSize: 11)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            "Showing ${(_currentPage - 1) * _itemsPerPage + 1} to ${_currentPage * _itemsPerPage > _filteredFranchises.length ? _filteredFranchises.length : _currentPage * _itemsPerPage} of ${_filteredFranchises.length}",
            style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.grey[400] : Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final buttonsWidget = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _compactPageButton(
            icon: Icons.chevron_left,
            onTap: _currentPage > 1 ? _previousPage : null,
            isDarkMode: isDarkMode,
          ),
          if (_totalPages <= 5)
            ...List.generate(_totalPages, (index) => _compactPageNumber(index + 1, isDarkMode))
          else if (_currentPage <= 3) ...[
            ...List.generate(4, (index) => _compactPageNumber(index + 1, isDarkMode)),
            const Text("..."),
            _compactPageNumber(_totalPages, isDarkMode),
          ] else if (_currentPage >= _totalPages - 2) ...[
            _compactPageNumber(1, isDarkMode),
            const Text("..."),
            ...List.generate(4, (index) => _compactPageNumber(_totalPages - 3 + index, isDarkMode)),
          ] else ...[
            _compactPageNumber(1, isDarkMode),
            const Text("..."),
            _compactPageNumber(_currentPage - 1, isDarkMode),
            _compactPageNumber(_currentPage, isDarkMode),
            _compactPageNumber(_currentPage + 1, isDarkMode),
            const Text("..."),
            _compactPageNumber(_totalPages, isDarkMode),
          ],
          _compactPageButton(
            icon: Icons.chevron_right,
            onTap: _currentPage < _totalPages ? _nextPage : null,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: isMobile
          ? Column(
        children: [
          entriesWidget,
          const SizedBox(height: 10),
          buttonsWidget,
        ],
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          entriesWidget,
          buttonsWidget,
        ],
      ),
    );
  }

  Widget _compactPageButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: onTap,
        color: onTap != null ? const Color(0xFF6366F1) : (isDarkMode ? Colors.grey[600] : Colors.grey),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
    );
  }

  Widget _compactPageNumber(int pageNum, bool isDarkMode) {
    final isSelected = _currentPage == pageNum;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: () => _goToPage(pageNum),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: Text(
            pageNum.toString(),
            style: TextStyle(
              color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : const Color(0xFF1E293B)),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
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
}