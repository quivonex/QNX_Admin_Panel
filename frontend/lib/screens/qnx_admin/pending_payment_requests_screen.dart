// lib/screens/qnx_admin/pending_payment_requests_screen.dart

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:html' as html;
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../api/api_service.dart';
import '../../models/qnx_admin/pending_withdraw_model.dart';
import '../../models/qnx_admin/payment_qr_model.dart';
import '../../models/qnx_admin/payment_withdraw_model.dart';

class PendingPaymentRequestsScreen extends StatefulWidget {
  const PendingPaymentRequestsScreen({super.key});

  @override
  State<PendingPaymentRequestsScreen> createState() =>
      _PendingPaymentRequestsScreenState();
}

class _PendingPaymentRequestsScreenState
    extends State<PendingPaymentRequestsScreen> {
  final PaymentRequestService _service = PaymentRequestService();

  // Data
  List<PendingWithdrawData> _allRequests = [];
  List<PendingWithdrawData> _filteredRequests = [];
  List<PendingWithdrawData> _paginatedRequests = [];

  // UI State
  bool _isLoading = true;
  String? _error;
  bool _isExporting = false;

  // Search & Filter
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'Partner Name';
  final List<String> _filterOptions = [
    'Partner Name',
    'Amount',
    'Status',
  ];

  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalPages = 1;
  final List<int> _rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  // Scroll Controllers
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  // Column Widths
  final Map<int, TableColumnWidth> _columnWidths = const {
    0: FixedColumnWidth(70),   // SR No
    1: FixedColumnWidth(200),  // Partner Name
    2: FixedColumnWidth(100),  // Amount
    3: FixedColumnWidth(120),  // Status
    4: FixedColumnWidth(150),  // Created At
    5: FixedColumnWidth(100),  // Actions
  };

  final List<String> _headerLabels = [
    "SR No",
    "Partner Name",
    "Amount (₹)",
    "Status",
    "Created At",
    "Actions",
  ];

  // Colors
  static const Color _primaryColor = Color(0xFF5A67F2);
  static const Color _bgColor = Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _service.getPendingWithdrawRequests();

      if (mounted) {
        setState(() {
          _allRequests = response.data;
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    final query = _searchQuery.toLowerCase().trim();

    if (query.isEmpty) {
      _filteredRequests = List.from(_allRequests);
    } else {
      _filteredRequests = _allRequests.where((req) {
        switch (_filterType) {
          case 'Partner Name':
            return req.marketingPartner.toLowerCase().contains(query);
          case 'Amount':
            return req.amount.contains(query);
          case 'Status':
            return req.status.toLowerCase().contains(query);
          default:
            return false;
        }
      }).toList();
    }

    _filteredRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _applyPagination();
  }

  void _applyPagination() {
    _totalPages = _filteredRequests.isEmpty
        ? 1
        : (_filteredRequests.length / _itemsPerPage).ceil();

    if (_currentPage > _totalPages) _currentPage = _totalPages;
    if (_currentPage < 1) _currentPage = 1;

    final int start = (_currentPage - 1) * _itemsPerPage;
    final int end = (start + _itemsPerPage > _filteredRequests.length)
        ? _filteredRequests.length
        : start + _itemsPerPage;

    _paginatedRequests = _filteredRequests.isEmpty
        ? []
        : _filteredRequests.sublist(start, end);

    setState(() {});
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      _currentPage = 1;
      _applyFilters();
    });
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _filterType = 'Partner Name';
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

  // ============================================================
  // EXPORT FUNCTIONS
  // ============================================================
  void _exportExcel() {
    if (_filteredRequests.isEmpty) {
      _showSnackBar("No data to export", isError: true);
      return;
    }

    setState(() => _isExporting = true);

    try {
      final file = excel.Excel.createExcel();
      final sheet = file['Payment Requests'];

      sheet.appendRow([
        "SR No",
        "Partner Name",
        "Amount (₹)",
        "Status",
        "Created At",
      ]);

      int srNo = _filteredRequests.length;
      for (var req in _filteredRequests) {
        sheet.appendRow([
          srNo--,
          req.marketingPartner,
          req.amount,
          req.status,
          _formatDate(req.createdAt),
        ]);
      }

      final bytes = file.encode();
      if (bytes != null) {
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute("download", "pending_payment_requests.xlsx")
          ..click();
        html.Url.revokeObjectUrl(url);
        _showSnackBar("Excel exported successfully");
      }
    } catch (e) {
      _showSnackBar("Export failed: $e", isError: true);
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportPDF() async {
    if (_filteredRequests.isEmpty) {
      _showSnackBar("No data to export", isError: true);
      return;
    }

    try {
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Table.fromTextArray(
              headers: [
                "SR No",
                "Partner Name",
                "Amount (₹)",
                "Status",
                "Created At"
              ],
              data: List.generate(_filteredRequests.length, (index) {
                final req = _filteredRequests[index];
                final srNo = _filteredRequests.length - index;
                return [
                  srNo.toString(),
                  req.marketingPartner,
                  req.amount,
                  req.status,
                  _formatDate(req.createdAt),
                ];
              }),
            );
          },
        ),
      );
      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
      _showSnackBar("PDF exported successfully");
    } catch (e) {
      _showSnackBar("PDF export failed: $e", isError: true);
    }
  }

  void _exportDOC() {
    if (_filteredRequests.isEmpty) {
      _showSnackBar("No data to export", isError: true);
      return;
    }

    try {
      final content = StringBuffer();
      content.writeln("Pending Payment Requests List\n");
      content.writeln("=" * 50);

      int srNo = _filteredRequests.length;
      for (var req in _filteredRequests) {
        content.writeln("SR No: ${srNo--}");
        content.writeln("Partner Name: ${req.marketingPartner}");
        content.writeln("Amount: ₹${req.amount}");
        content.writeln("Status: ${req.status}");
        content.writeln("Created At: ${_formatDate(req.createdAt)}");
        content.writeln("-" * 30);
      }

      final blob = html.Blob([content.toString()]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "pending_payment_requests.doc")
        ..click();
      html.Url.revokeObjectUrl(url);
      _showSnackBar("DOC exported successfully");
    } catch (e) {
      _showSnackBar("DOC export failed: $e", isError: true);
    }
  }

  // ============================================================
  // PAYMENT METHODS - WITH CHEQUE UPLOAD
  // ============================================================
  String _selectedPaymentMethod = 'upi';
  Uint8List? _chequeImage;
  String? _chequeImageName;
  bool _isUploadingCheque = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'value': 'upi', 'label': 'UPI', 'icon': Icons.qr_code_scanner},
    {'value': 'bank_transfer', 'label': 'Bank Transfer', 'icon': Icons.account_balance},
    {'value': 'cheque', 'label': 'Cheque', 'icon': Icons.description},
  ];

  Future<void> _showPaymentQRPopup(PendingWithdrawData request) async {
    _selectedPaymentMethod = 'upi';
    _chequeImage = null;
    _chequeImageName = null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final response = await _service.generatePaymentQR(
        marketingPartnerId: request.marketingPartnerId,
        amount: request.amountDouble,
        paymentMethod: _selectedPaymentMethod,
      );

      if (mounted) {
        Navigator.pop(context);
      }

      if (response.status) {
        if (mounted) {
          _showPaymentDialog(response, request);
        }
      } else {
        if (mounted) {
          _showSnackBar(response.message, isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Error: ${e.toString()}', isError: true);
      }
    }
  }

  // ============================================================
  // CHEQUE IMAGE PICKER
  // ============================================================
  Future<void> _pickChequeImage() async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _chequeImage = bytes;
          _chequeImageName = image.name;
        });
        _showSnackBar('Cheque image uploaded: ${image.name}');
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e', isError: true);
    }
  }

  Future<void> _captureChequeImage() async {
    final ImagePicker picker = ImagePicker();

    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _chequeImage = bytes;
          _chequeImageName = image.name;
        });
        _showSnackBar('Cheque photo captured successfully');
      }
    } catch (e) {
      _showSnackBar('Failed to capture image: $e', isError: true);
    }
  }

  void _removeChequeImage() {
    setState(() {
      _chequeImage = null;
      _chequeImageName = null;
    });
    _showSnackBar('Cheque image removed');
  }

  // ============================================================
  // PAYMENT DIALOG - UPDATED WITH CHEQUE UPLOAD
  // ============================================================
  void _showPaymentDialog(PaymentQRResponse response, PendingWithdrawData request) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header Icon
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getPaymentIcon(_selectedPaymentMethod),
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Text(
                      'Payment Details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Partner Name
                    Text(
                      response.marketingPartner,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Amount
                    Text(
                      'Amount: ₹${response.amount}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF4158D0),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // PAYMENT METHOD DROPDOWN
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPaymentMethod,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4158D0)),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                          onChanged: (String? newValue) async {
                            if (newValue != null) {
                              // Reset cheque image when switching away from cheque
                              if (newValue != 'cheque') {
                                setStateDialog(() {
                                  _chequeImage = null;
                                  _chequeImageName = null;
                                });
                              }

                              setStateDialog(() {
                                _selectedPaymentMethod = newValue;
                              });

                              // Show loading
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                              try {
                                final newResponse = await _service.generatePaymentQR(
                                  marketingPartnerId: request.marketingPartnerId,
                                  amount: request.amountDouble,
                                  paymentMethod: newValue,
                                );

                                if (mounted) {
                                  Navigator.pop(context); // Close loading
                                }

                                if (newResponse.status) {
                                  Navigator.pop(context); // Close current dialog
                                  _showPaymentDialog(newResponse, request);
                                } else {
                                  if (mounted) {
                                    _showSnackBar(newResponse.message, isError: true);
                                  }
                                }
                              } catch (e) {
                                if (mounted) {
                                  Navigator.pop(context); // Close loading
                                  _showSnackBar('Error: ${e.toString()}', isError: true);
                                }
                              }
                            }
                          },
                          items: _paymentMethods.map((method) {
                            return DropdownMenuItem<String>(
                              value: method['value'],
                              child: Row(
                                children: [
                                  Icon(
                                    method['icon'],
                                    size: 20,
                                    color: const Color(0xFF4158D0),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    method['label'],
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // DYNAMIC CONTENT BASED ON PAYMENT METHOD
                    if (_selectedPaymentMethod == 'upi') ...[
                      _buildUPIContent(response),
                    ] else if (_selectedPaymentMethod == 'bank_transfer') ...[
                      _buildBankTransferContent(response),
                    ] else if (_selectedPaymentMethod == 'cheque') ...[
                      _buildChequeContentWithUpload(response, setStateDialog),
                    ],

                    const SizedBox(height: 16),

                    // Mark as Paid Button - Disabled if cheque image not uploaded
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedPaymentMethod == 'cheque' && _chequeImage == null
                            ? null // Disable if cheque image not uploaded
                            : () {
                          _markAsPaid(
                            context,
                            request.requestId,
                            _selectedPaymentMethod,  // ✅ paymentMethod pass करा
                            _selectedPaymentMethod == 'cheque' && _chequeImage != null
                                ? 'Cheque uploaded and verified'  // ✅ remarks
                                : 'Amount transferred via $_selectedPaymentMethod',
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBackgroundColor: Colors.green.withOpacity(0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedPaymentMethod == 'cheque' && _chequeImage == null
                                  ? Icons.error_outline
                                  : Icons.check_circle,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedPaymentMethod == 'cheque' && _chequeImage == null
                                  ? 'Upload Cheque Photo First'
                                  : 'Mark as Paid',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Close Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          _chequeImage = null;
                          _chequeImageName = null;
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // CHEQUE CONTENT WITH UPLOAD - UPDATED
  // ============================================================
  Widget _buildChequeContentWithUpload(PaymentQRResponse response, StateSetter setStateDialog) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Icon
          const Icon(
            Icons.description,
            size: 48,
            color: Color(0xFF4158D0),
          ),
          const SizedBox(height: 12),

          // Title
          const Text(
            'Pay by Cheque',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Instruction
          Text(
            'Please issue a cheque and upload a clear photo of the cheque.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),

          // ============================================================
          // ✅ CHEQUE IMAGE UPLOAD AREA
          // ============================================================
          if (_chequeImage == null) ...[
            // Upload buttons when no image
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploadingCheque ? null : _pickChequeImage,
                    icon: const Icon(Icons.photo_library, size: 18),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4158D0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isUploadingCheque ? null : _captureChequeImage,
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4158D0),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isUploadingCheque) ...[
              const SizedBox(height: 8),
              const Center(
                child: SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF4158D0),
                  ),
                ),
              ),
            ],
          ] else ...[
            // Image preview when uploaded
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.green.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.green.shade50,
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Image preview
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _chequeImage!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 40,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // File name and actions
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '📄 ${_chequeImageName ?? 'cheque_image.jpg'}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${(_chequeImage!.length / 1024).toStringAsFixed(1)} KB',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setStateDialog(() {
                            _removeChequeImage();
                          });
                        },
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Remove image',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),

                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Cheque uploaded',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Note about marking as paid
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _chequeImage == null
                        ? 'Please upload cheque photo to proceed'
                        : 'Cheque photo uploaded successfully. Click "Mark as Paid" to complete.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OTHER PAYMENT METHOD WIDGETS
  // ============================================================
  Widget _buildUPIContent(PaymentQRResponse response) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: QrImageView(
            data: response.upiLink,
            version: QrVersions.auto,
            size: 200,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            errorCorrectionLevel: QrErrorCorrectLevel.H,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.circle,
              color: Color(0xFF4158D0),
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.circle,
              color: Color(0xFF4158D0),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.account_balance_wallet,
                size: 18,
                color: Color(0xFF4158D0),
              ),
              const SizedBox(width: 8),
              Text(
                'UPI: ${response.upiId ?? 'N/A'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBankTransferContent(PaymentQRResponse response) {
    final bank = response.bankDetails;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBankDetailRow(Icons.person, 'Account Holder', bank?.accountHolderName ?? 'N/A'),
          _buildBankDetailRow(Icons.business, 'Bank Name', bank?.bankName ?? 'N/A'),
          _buildBankDetailRow(Icons.location_city, 'Branch', bank?.branchName ?? 'N/A'),
          _buildBankDetailRow(Icons.account_balance, 'Account Number', bank?.accountNumber ?? 'N/A'),
          _buildBankDetailRow(Icons.code, 'IFSC Code', bank?.ifscCode ?? 'N/A'),
          _buildBankDetailRow(Icons.category, 'Account Type', bank?.accountType ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildBankDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF4158D0)),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method) {
      case 'upi':
        return Icons.qr_code_scanner;
      case 'bank_transfer':
        return Icons.account_balance;
      case 'cheque':
        return Icons.description;
      default:
        return Icons.payment;
    }
  }

  // ✅ UPDATED: _markAsPaid with paymentMethod and remarks
  Future<void> _markAsPaid(
      BuildContext context,
      int requestId,
      String paymentMethod,
      String remarks,
      ) async {
    // If cheque method, we have the image
    if (paymentMethod == 'cheque' && _chequeImage != null) {
      // Here you can upload cheque image to server if needed
      // For now, proceed with marking as paid
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final response = await _service.markPaymentAsPaid(
        requestId: requestId,
        paymentMethod: paymentMethod,  // ✅ नवीन parameter
        remarks: remarks,              // ✅ नवीन parameter
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        // Also close the payment dialog
        Navigator.pop(context);
        // Reset cheque image
        _chequeImage = null;
        _chequeImageName = null;
      }

      if (response.status && response.data != null) {
        _showSuccessDialog(context, response.data!);
        _loadRequests();
      } else {
        if (mounted) {
          _showSnackBar(response.message, isError: true);
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showSnackBar('Error: ${e.toString()}', isError: true);
      }
    }
  }

  // ✅ UPDATED: Success Dialog with new fields
  void _showSuccessDialog(BuildContext context, PaymentWithdrawData data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text('Payment Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment of ₹${data.paidAmount} has been successfully processed.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Partner', data.marketingPartner),
                  _buildDetailRow('Amount Paid', '₹${data.paidAmount}'),
                  _buildDetailRow('Remaining Balance', '₹${data.remainingBalance}'),
                  _buildDetailRow('Status', data.status.toUpperCase()),
                  _buildDetailRow('Payment Method', data.paymentMethod.toUpperCase()), // ✅ नवीन
                  if (data.paidByName != null && data.paidByName!.isNotEmpty)
                    _buildDetailRow('Paid By', data.paidByName!), // ✅ नवीन
                  if (data.paidBy != null)
                    _buildDetailRow('Paid By ID', data.paidBy!.id.toString()), // ✅ नवीन
                  if (_selectedPaymentMethod == 'cheque' && _chequeImage != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow('Cheque Photo', '✅ Uploaded'),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              _chequeImage = null;
              _chequeImageName = null;
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4158D0),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================
  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(String dateTime) {
    try {
      final DateTime date = DateTime.parse(dateTime);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return dateTime.substring(0, 10);
    }
  }

  // ============================================================
  // TABLE WIDGETS
  // ============================================================
  Widget _tableHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      alignment: Alignment.center,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: Color(0xFF1E293B),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _tableCell(String text, {VoidCallback? onTap, bool isBold = false, Color? textColor}) {
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
            color: textColor ?? Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    Color bgColor;

    switch (status.toLowerCase()) {
      case 'pending':
        color = const Color(0xFFF39C12);
        bgColor = const Color(0xFFF39C12).withOpacity(0.1);
        break;
      case 'approved':
        color = const Color(0xFF2ECC71);
        bgColor = const Color(0xFF2ECC71).withOpacity(0.1);
        break;
      case 'rejected':
        color = const Color(0xFFE74C3C);
        bgColor = const Color(0xFFE74C3C).withOpacity(0.1);
        break;
      default:
        color = Colors.grey;
        bgColor = Colors.grey.withOpacity(0.1);
    }

    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          status.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD - FILTER SECTION
  // ============================================================
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final bool isSmall = maxWidth < 700;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isSmall ? 120 : 140,
                      minWidth: isSmall ? 100 : 120,
                    ),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterType,
                          icon: const Icon(Icons.arrow_drop_down, color: _primaryColor),
                          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            setState(() {
                              _filterType = newValue!;
                              _currentPage = 1;
                              _applyFilters();
                            });
                          },
                          items: _filterOptions.map<DropdownMenuItem<String>>((value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Row(
                                children: [
                                  Icon(
                                    _getFilterIcon(value),
                                    size: 14,
                                    color: _primaryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      value,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    flex: 3,
                    child: Container(
                      height: 40,
                      constraints: BoxConstraints(
                        minWidth: isSmall ? 100 : 200,
                        maxWidth: isSmall ? 180 : 300,
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: "Search by ${_filterType.toLowerCase()}...",
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          prefixIcon: const Icon(Icons.search, size: 16, color: _primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: _primaryColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                          isDense: true,
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: _resetFilters,
                          )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  _buildExportIcons(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Total: ${_filteredRequests.length}",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: _resetFilters,
                        icon: const Icon(Icons.refresh),
                        color: Colors.red[400],
                        tooltip: "Reset",
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        iconSize: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'Partner Name':
        return Icons.person;
      case 'Amount':
        return Icons.currency_rupee;
      case 'Status':
        return Icons.circle;
      default:
        return Icons.search;
    }
  }

  Widget _buildExportIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: "Export Excel",
          child: InkWell(
            onTap: _isExporting ? null : _exportExcel,
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
        const SizedBox(width: 4),
        Tooltip(
          message: "Export PDF",
          child: InkWell(
            onTap: _isExporting ? null : _exportPDF,
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
        const SizedBox(width: 4),
        Tooltip(
          message: "Export DOC",
          child: InkWell(
            onTap: _isExporting ? null : _exportDOC,
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

  // ============================================================
  // BUILD - PAGINATION
  // ============================================================
  Widget _buildPagination() {
    if (_filteredRequests.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showEntriesRow = Row(
            mainAxisSize: MainAxisSize.min,
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
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                      .toList(),
                  onChanged: _changeItemsPerPage,
                ),
              ),
              const Text(" entries", style: TextStyle(fontSize: 12)),
              const SizedBox(width: 12),
              Text(
                "Showing ${(_currentPage - 1) * _itemsPerPage + 1} to "
                    "${_currentPage * _itemsPerPage > _filteredRequests.length ? _filteredRequests.length : _currentPage * _itemsPerPage} "
                    "of ${_filteredRequests.length}",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          );

          final pageButtons = [
            _compactPageButton(
              icon: Icons.chevron_left,
              onTap: _currentPage > 1 ? _previousPage : null,
            ),
            ..._buildPageNumbers(),
            _compactPageButton(
              icon: Icons.chevron_right,
              onTap: _currentPage < _totalPages ? _nextPage : null,
            ),
          ];

          final paginationRow = Row(
            mainAxisSize: MainAxisSize.min,
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
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                showEntriesRow,
                paginationRow,
              ],
            );
          }
        },
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    final List<Widget> pages = [];

    if (_totalPages <= 5) {
      for (int i = 1; i <= _totalPages; i++) {
        pages.add(_compactPageNumber(i));
      }
    } else if (_currentPage <= 3) {
      for (int i = 1; i <= 4; i++) pages.add(_compactPageNumber(i));
      pages.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
      ));
      pages.add(_compactPageNumber(_totalPages));
    } else if (_currentPage >= _totalPages - 2) {
      pages.add(_compactPageNumber(1));
      pages.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
      ));
      for (int i = _totalPages - 3; i <= _totalPages; i++) {
        pages.add(_compactPageNumber(i));
      }
    } else {
      pages.add(_compactPageNumber(1));
      pages.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
      ));
      pages.add(_compactPageNumber(_currentPage - 1));
      pages.add(_compactPageNumber(_currentPage));
      pages.add(_compactPageNumber(_currentPage + 1));
      pages.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 2),
        child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
      ));
      pages.add(_compactPageNumber(_totalPages));
    }

    return pages;
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
        color: onTap != null ? const Color(0xFF4158D0) : Colors.grey,
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
              color: isSelected ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD - TABLE
  // ============================================================
  Widget _buildDataTable() {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: Table(
              border: TableBorder(
                horizontalInside: BorderSide(color: Colors.grey.shade300),
                verticalInside: BorderSide(color: Colors.grey.shade300),
                top: BorderSide(color: Colors.grey.shade300),
                bottom: BorderSide(color: Colors.grey.shade300),
              ),
              columnWidths: _columnWidths,
              children: [
                TableRow(
                  children: _headerLabels.map((label) => _tableHeader(label)).toList(),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _verticalScrollController,
            child: SingleChildScrollView(
              controller: _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: Table(
                border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                columnWidths: _columnWidths,
                children: List.generate(_paginatedRequests.length, (rowIndex) {
                  final req = _paginatedRequests[rowIndex];
                  final isEven = rowIndex % 2 == 0;
                  final srNo = _paginatedRequests.length - rowIndex;

                  return TableRow(
                    decoration: BoxDecoration(
                      color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                    ),
                    children: [
                      _tableCell(
                        srNo.toString(),
                        onTap: () => _showPaymentQRPopup(req),
                      ),
                      _tableCell(
                        req.marketingPartner,
                        onTap: () => _showPaymentQRPopup(req),
                        isBold: true,
                      ),
                      _tableCell(
                        '₹${req.amount}',
                        onTap: () => _showPaymentQRPopup(req),
                        textColor: const Color(0xFFF39C12),
                        isBold: true,
                      ),
                      Container(
                        height: 42,
                        padding: const EdgeInsets.all(4),
                        alignment: Alignment.center,
                        child: _buildStatusChip(req.status),
                      ),
                      _tableCell(
                        _formatDate(req.createdAt),
                        onTap: () => _showPaymentQRPopup(req),
                      ),
                      Container(
                        height: 42,
                        padding: const EdgeInsets.all(4),
                        alignment: Alignment.center,
                        child: IconButton(
                          icon: const Icon(
                            Icons.qr_code_scanner,
                            color: Color(0xFF4158D0),
                            size: 20,
                          ),
                          onPressed: () => _showPaymentQRPopup(req),
                          tooltip: 'Generate Payment',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
    );
  }

  // ============================================================
  // BUILD - MAIN
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A2E) : _bgColor,
      appBar: AppBar(
        title: const Text('Pending Payment Requests'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _primaryColor,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: _primaryColor),
            onPressed: _loadRequests,
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
              onPressed: _loadRequests,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildFilterSection(isMobile),
            const SizedBox(height: 8),
            Expanded(
              child: _filteredRequests.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pending_actions_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No pending payment requests',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'All withdraw requests have been processed',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              )
                  : _buildDataTable(),
            ),
            const SizedBox(height: 8),
            _buildPagination(),
          ],
        ),
      ),
    );
  }
}