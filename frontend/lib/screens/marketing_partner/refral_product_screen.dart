// lib/screens/marketing_partner/referral_product_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'dart:io' show File;
import 'dart:html' as html; // Web Direct Download साठी
import 'package:share_plus/share_plus.dart';

// PDF & Printing Packages
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../api/marketing_service.dart';
import '../../models/marketing_partner/product_refral_model.dart';

class ReferralProductScreen extends StatefulWidget {
  const ReferralProductScreen({super.key});

  @override
  State<ReferralProductScreen> createState() => _ReferralProductScreenState();
}

class _ReferralProductScreenState extends State<ReferralProductScreen> {
  final ProductReferralService _service = ProductReferralService();

  List<ApprovedProductModel> _products = [];
  List<ApprovedProductModel> _filteredProducts = [];
  List<ApprovedProductModel> _paginatedProducts = [];

  bool _isLoading = true;
  bool _isGenerating = false;
  String? _error;

  // Search & Filter state
  String _searchQuery = '';
  String _filterType = 'Product Name'; // Options: Product Name, Category, Brand, Company Name
  final TextEditingController _searchController = TextEditingController();

  // Pagination state
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalPages = 1;
  final List<int> _itemsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  // Partner Referral Code
  String? _partnerReferralCode;
  String? _userRole;
  bool _isMarketingPartner = false;

  // Referral Code Popup Controllers
  final TextEditingController _referralCodeController = TextEditingController();
  ApprovedProductModel? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _referralCodeController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      _partnerReferralCode = 'MP4Z1B57BI';
      _userRole = prefs.getString('user_role');

      if (_userRole != null) {
        _isMarketingPartner =
            _userRole!.toLowerCase().contains('marketing partner') ||
                _userRole!.toLowerCase().contains('marketing_partner');
      }

      if (_partnerReferralCode == null || _partnerReferralCode!.isEmpty) {
        setState(() {
          _error = 'Marketing Partner referral code not found. Please login again.';
          _isLoading = false;
        });
        return;
      }

      if (!_isMarketingPartner) {
        setState(() {
          _error = 'Only Marketing Partners can generate referral links.';
          _isLoading = false;
        });
        return;
      }

      final response = await _service.getApprovedProducts();

      setState(() {
        _products = response.data;
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

  // Filter Logic
  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredProducts = List.from(_products);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredProducts = _products.where((product) {
        switch (_filterType) {
          case 'Product Name':
            return product.name.toLowerCase().contains(query);
          case 'Category':
            return product.categoryName?.toLowerCase().contains(query) ?? false;
          case 'Brand':
            return product.brandName?.toLowerCase().contains(query) ?? false;
          case 'Company Name':
            return product.companyName?.toLowerCase().contains(query) ?? false;
          default:
            return false;
        }
      }).toList();
    }
    _applyPagination();
  }

  // Pagination Logic
  void _applyPagination() {
    if (_filteredProducts.isEmpty) {
      _paginatedProducts = [];
      _totalPages = 1;
      _currentPage = 1;
      setState(() {});
      return;
    }

    _totalPages = (_filteredProducts.length / _itemsPerPage).ceil();
    if (_currentPage > _totalPages) _currentPage = _totalPages;
    if (_currentPage < 1) _currentPage = 1;

    int start = (_currentPage - 1) * _itemsPerPage;
    int end = start + _itemsPerPage;
    if (end > _filteredProducts.length) end = _filteredProducts.length;

    _paginatedProducts = _filteredProducts.sublist(start, end);
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
      _filterType = 'Product Name';
      _searchController.clear();
      _currentPage = 1;
      _applyFilters();
    });
  }

  // Export Logic
  Future<void> _exportToExcel() async {
    if (_filteredProducts.isEmpty) {
      _showSnackBar('No products to export', Colors.orange);
      return;
    }

    try {
      final excelFile = excel.Excel.createExcel();
      final sheet = excelFile['Referral Products'];

      sheet.appendRow([
        'SR No', 'Product Name', 'Category', 'Brand',
        'Price', 'Referral Code', 'Referral Link', 'Status'
      ]);

      for (int i = 0; i < _filteredProducts.length; i++) {
        var product = _filteredProducts[i];
        sheet.appendRow([
          i + 1,
          product.name,
          product.categoryName ?? 'Electronics',
          product.brandName ?? 'Samsung Galaxy',
          double.tryParse(product.price) ?? 0.0,
          _partnerReferralCode ?? 'MP4Z1B57BI',
          'https://yourdomain.com/referral/${_partnerReferralCode ?? "MP4Z1B57BI"}',
          'Active',
        ]);
      }

      final fileBytes = excelFile.encode();
      if (fileBytes != null) {
        if (kIsWeb) {
          final blob = html.Blob([fileBytes], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', 'referral_products_${DateTime.now().millisecondsSinceEpoch}.xlsx')
            ..click();
          html.Url.revokeObjectUrl(url);
          _showSnackBar('Excel Downloaded Successfully!', Colors.green);
        } else {
          final dir = await getTemporaryDirectory();
          final filePath = '${dir.path}/referral_products_${DateTime.now().millisecondsSinceEpoch}.xlsx';
          final file = File(filePath);
          await file.writeAsBytes(fileBytes);

          await Share.shareXFiles(
            [XFile(filePath)],
            text: 'Referral Products Excel Export',
          );
        }
      }
    } catch (e) {
      _showSnackBar('Export failed: ${e.toString()}', Colors.red);
    }
  }

  Future<void> _exportToPdf() async {
    if (_filteredProducts.isEmpty) {
      _showSnackBar('No products to export', Colors.orange);
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
                    pw.Text('Product Referral List',
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}'),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.TableHelper.fromTextArray(
                headers: ['SR No', 'Name', 'Category', 'Brand', 'Price', 'Code'],
                data: List<List<String>>.generate(
                  _filteredProducts.length,
                      (index) {
                    final product = _filteredProducts[index];
                    return [
                      (index + 1).toString(),
                      product.name,
                      product.categoryName ?? 'Electronics',
                      product.brandName ?? 'Samsung Galaxy',
                      'Rs. ${product.price}',
                      _partnerReferralCode ?? 'MP4Z1B57BI',
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
          ..setAttribute('download', 'referral_products_${DateTime.now().millisecondsSinceEpoch}.pdf')
          ..click();
        html.Url.revokeObjectUrl(url);
        _showSnackBar('PDF Downloaded Successfully!', Colors.green);
      } else {
        final output = await getTemporaryDirectory();
        final file = File('${output.path}/referral_products_${DateTime.now().millisecondsSinceEpoch}.pdf');
        await file.writeAsBytes(bytes);

        await Share.shareXFiles([XFile(file.path)], text: 'Referral Products PDF');
      }
    } catch (e) {
      _showSnackBar('PDF export failed: ${e.toString()}', Colors.red);
    }
  }

  void _exportToDoc() {
    if (_filteredProducts.isEmpty) {
      _showSnackBar('No products to export', Colors.orange);
      return;
    }

    try {
      final content = StringBuffer();
      content.writeln("Referral Products List\n");
      content.writeln("=" * 50);

      for (int i = 0; i < _filteredProducts.length; i++) {
        var product = _filteredProducts[i];
        content.writeln("SR No: ${i + 1}");
        content.writeln("Product Name: ${product.name}");
        content.writeln("Category: ${product.categoryName ?? 'Electronics'}");
        content.writeln("Brand: ${product.brandName ?? 'Samsung Galaxy'}");
        content.writeln("Price: ₹${product.price}");
        content.writeln("Referral Code: ${_partnerReferralCode ?? 'MP4Z1B57BI'}");
        content.writeln("Referral Link: https://yourdomain.com/referral/${_partnerReferralCode ?? "MP4Z1B57BI"}");
        content.writeln("-" * 30);
      }

      if (kIsWeb) {
        final blob = html.Blob([content.toString()]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", "referral_products_${DateTime.now().millisecondsSinceEpoch}.doc")
          ..click();
        html.Url.revokeObjectUrl(url);
        _showSnackBar('DOC Downloaded Successfully!', Colors.green);
      } else {
        _showSnackBar('DOC Export is optimized for Web', Colors.blue);
      }
    } catch (e) {
      _showSnackBar('DOC export failed: ${e.toString()}', Colors.red);
    }
  }

  void _showReferralCodePopup(BuildContext context, ApprovedProductModel product) {
    if (!mounted) return;

    _selectedProduct = product;
    _referralCodeController.text = _partnerReferralCode ?? 'MP4Z1B57BI';

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
                  Icon(Icons.link, color: Colors.purple.shade700),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Generate Referral Link',
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
              Container(
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
                      'Product: ${product.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Price: ₹${product.price}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Enter Referral Code',
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
                      color: Colors.purple,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Note: This is your unique referral code. Each partner has a different code.',
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
              onPressed: () {
                Navigator.pop(dialogContext);
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _generateReferralLink(context, product);
                  }
                });
              },
              icon: const Icon(Icons.link, size: 16),
              label: const Text('Generate Link'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
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

  void _generateReferralLink(BuildContext context, ApprovedProductModel product) async {
    String referralCode = _referralCodeController.text.trim();

    if (referralCode.isEmpty) {
      _showSnackBar('Please enter a referral code', Colors.orange);
      return;
    }

    setState(() {
      _isGenerating = true;
    });

    try {
      final response = await _service.generateReferralLink(
        productId: product.id,
        referralCode: referralCode,
      );

      setState(() {
        _isGenerating = false;
      });

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showReferralResultDialog(context, response);
          }
        });
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
      });
      if (mounted) {
        _showSnackBar('Failed: ${e.toString()}', Colors.red);
      }
    }
  }

  void _showReferralResultDialog(BuildContext context, ProductReferralResponse response) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.link, color: Colors.green.shade700),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Referral Link Generated',
                overflow: TextOverflow.ellipsis,
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
              _buildInfoRow('Product', response.productName),
              const SizedBox(height: 4),
              _buildInfoRow('Referral Code', response.referralCode),
              const SizedBox(height: 12),
              const Text(
                'Referral Link',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        response.referralLink,
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
                      onPressed: () => _copyToClipboard(context, response.referralLink),
                      tooltip: 'Copy Link',
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
            onPressed: () {
              _copyToClipboard(context, response.referralLink);
            },
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterSection(isMobile, isDarkMode),
          const SizedBox(height: 12),
          if (_filteredProducts.isEmpty)
            _buildEmptyState()
          else ...[
            Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildProductTable(isDarkMode),
              ),
            ),
            const SizedBox(height: 12),
            _buildPagination(isDarkMode, isMobile),
          ],
        ],
      ),
    );
  }

  // Filter Section
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
                    "Total: ${_filteredProducts.length}",
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
          Expanded(child: _buildSearchField(isDarkMode)),
          const SizedBox(width: 12),
          _buildExportIcons(isDarkMode),
          const SizedBox(width: 12),
          Text(
            "Total: ${_filteredProducts.length}",
            style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          IconButton(onPressed: _resetFilters, icon: const Icon(Icons.refresh), color: Colors.red),
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
          items: ['Product Name', 'Category', 'Brand', 'Company Name']
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
          hintStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF6366F1)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, size: 16, color: isDarkMode ? Colors.white70 : Colors.grey),
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

  // Same Design Export Icons (Excel, PDF, DOC)
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
            onTap: _exportToDoc,
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

  Widget _buildProductTable(bool isDarkMode) {
    final borderSide = BorderSide(
      color: isDarkMode ? Colors.grey[700]! : const Color(0xFFCBD5E1),
      width: 1.0,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.grey[700]! : const Color(0xFFCBD5E1)),
      ),
      child: DataTable(
        columnSpacing: 28,
        horizontalMargin: 16,
        showBottomBorder: true,
        border: TableBorder(
          horizontalInside: borderSide,
          verticalInside: borderSide,
          bottom: borderSide,
          top: borderSide,
          right: borderSide,
          left: borderSide,
        ),
        headingRowColor: WidgetStateProperty.all(
          isDarkMode ? const Color(0xFF16213E) : const Color(0xFFEEF2F6),
        ),
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.grey[300] : const Color(0xFF334155),
          fontSize: 13,
        ),
        dataRowColor: WidgetStateProperty.all(
          isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        ),
        columns: const [
          DataColumn(label: Text('Sr. No.')),
          DataColumn(label: Text('Img')),
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Category')),
          DataColumn(label: Text('Brand')),
          DataColumn(label: Text('Price')),
          DataColumn(label: Text('Referral Code')),
          DataColumn(label: Text('Referral Link')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('View')),
        ],
        rows: _paginatedProducts.asMap().entries.map((entry) {
          int index = entry.key;
          var product = entry.value;

          // Sr. No. Descending Order Formula
          final int globalIndex = (_currentPage - 1) * _itemsPerPage + index;
          final int srNo = _filteredProducts.length - globalIndex;

          return DataRow(
            cells: [
              DataCell(
                InkWell(
                  onTap: () => _showReferralCodePopup(context, product),
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      srNo.toString(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : const Color(0xFF475569)),
                    ),
                  ),
                ),
              ),
              DataCell(
                InkWell(
                  onTap: () => _showReferralCodePopup(context, product),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: product.thumbnail != null && product.thumbnail!.isNotEmpty
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        product.thumbnail!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.image, size: 16, color: Colors.grey[400]),
                      ),
                    )
                        : Icon(Icons.image, size: 16, color: Colors.grey[400]),
                  ),
                ),
              ),
              DataCell(
                InkWell(
                  onTap: () => _showReferralCodePopup(context, product),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      product.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ),
              DataCell(
                InkWell(
                  onTap: () => _showReferralCodePopup(context, product),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      product.categoryName ?? 'Electronics',
                      style: TextStyle(color: isDarkMode ? Colors.grey[400] : const Color(0xFF475569)),
                    ),
                  ),
                ),
              ),
              DataCell(
                InkWell(
                  onTap: () => _showReferralCodePopup(context, product),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      product.brandName ?? 'Samsung Galaxy',
                      style: TextStyle(color: isDarkMode ? Colors.grey[400] : const Color(0xFF475569)),
                    ),
                  ),
                ),
              ),
              DataCell(
                InkWell(
                  onTap: () => _showReferralCodePopup(context, product),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '₹${product.price}',
                      style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF475569)),
                    ),
                  ),
                ),
              ),
              DataCell(
                InkWell(
                  onTap: () => _showReferralCodePopup(context, product),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _partnerReferralCode ?? 'MP4Z1B57BI',
                      style: TextStyle(color: isDarkMode ? Colors.grey[400] : const Color(0xFF475569)),
                    ),
                  ),
                ),
              ),
              DataCell(
                InkWell(
                  onTap: () => _showReferralCodePopup(context, product),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      'https://yourdomain.com/referral/${_partnerReferralCode ?? "MP4Z1B57BI"}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ),
              ),
              DataCell(
                InkWell(
                  onTap: () => _showReferralCodePopup(context, product),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF064E3B) : const Color(0xFFE6F4EA),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Active',
                      style: TextStyle(
                        color: isDarkMode ? const Color(0xFF34D399) : const Color(0xFF137333),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              DataCell(
                Center(
                  child: IconButton(
                    icon: const Icon(Icons.visibility, size: 18, color: Color(0xFF4158D0)),
                    onPressed: () => _showReferralCodePopup(context, product),
                    tooltip: 'Generate Referral Link',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // Pagination UI
  Widget _buildPagination(bool isDarkMode, bool isMobile) {
    if (_filteredProducts.isEmpty) return const SizedBox.shrink();

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
            items: _itemsPerPageOptions.map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
            onChanged: _changeItemsPerPage,
          ),
        ),
        const Text(" entries", style: TextStyle(fontSize: 11)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            "Showing ${(_currentPage - 1) * _itemsPerPage + 1} to ${_currentPage * _itemsPerPage > _filteredProducts.length ? _filteredProducts.length : _currentPage * _itemsPerPage} of ${_filteredProducts.length}",
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
          _compactPageButton(icon: Icons.chevron_left, onTap: _currentPage > 1 ? _previousPage : null, isDarkMode: isDarkMode),
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
          _compactPageButton(icon: Icons.chevron_right, onTap: _currentPage < _totalPages ? _nextPage : null, isDarkMode: isDarkMode),
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

  Widget _compactPageButton({required IconData icon, required VoidCallback? onTap, required bool isDarkMode}) {
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No products found'
                : 'No products match your search',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
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
}