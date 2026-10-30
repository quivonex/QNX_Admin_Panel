// lib/screens/shiprocket/return_orders_screen.dart

import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:qr_flutter/qr_flutter.dart'; // ✅ ADD for UPI QR
import '../../api/shiprocket_service.dart';
import '../../models/shiprocket/return_order_model.dart';

class ReturnOrdersScreen extends StatefulWidget {
  const ReturnOrdersScreen({super.key});

  @override
  State<ReturnOrdersScreen> createState() => _ReturnOrdersScreenState();
}

class _ReturnOrdersScreenState extends State<ReturnOrdersScreen> {
  final ReturnOrderService _service = ReturnOrderService();

  List<ReturnOrder> allReturns = [];
  List<ReturnOrder> filteredReturns = [];
  List<ReturnOrder> paginatedReturns = [];

  bool isLoading = true;
  bool isCreatingShipment = false;
  int? creatingReturnId;

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String filterType = 'Return Number';

  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  static const Color _premiumPrimary = Color(0xFF5A67F2);
  static const Color _premiumSecondary = Color(0xFF7B4DDB);
  static const Color _premiumAccent = Color(0xFFC84DB5);

  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(50),
    1: FixedColumnWidth(140),
    2: FixedColumnWidth(120),
    3: FixedColumnWidth(180),
    4: FixedColumnWidth(60),
    5: FixedColumnWidth(90),
    6: FixedColumnWidth(110),
    7: FixedColumnWidth(120),
    8: FixedColumnWidth(90),
    9: FixedColumnWidth(110),
  };

  final List<String> headerLabels = [
    "SR No", "Return No", "Order No", "Product", "Qty",
    "Refund", "Reason", "Status", "Created", "Actions"
  ];

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();
    loadReturnOrders();
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

  Future<void> loadReturnOrders() async {
    setState(() => isLoading = true);
    try {
      final response = await _service.getReturnOrders();
      if (mounted) {
        setState(() {
          allReturns = response.data;
          allReturns.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load return orders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void applyFilters() {
    if (searchQuery.isEmpty) {
      filteredReturns = List.from(allReturns);
    } else {
      final query = searchQuery.toLowerCase();
      filteredReturns = allReturns.where((r) {
        switch (filterType) {
          case 'Return Number':
            return r.returnNumber.toLowerCase().contains(query);
          case 'Order Number':
            return r.orderNumber.toLowerCase().contains(query);
          case 'Product':
            return r.product.toLowerCase().contains(query);
          case 'Status':
            return r.status.toLowerCase().contains(query);
          case 'Reason':
            return r.reason.toLowerCase().contains(query);
          default:
            return false;
        }
      }).toList();
    }
    applyPagination();
  }

  void applyPagination() {
    if (filteredReturns.isEmpty) {
      paginatedReturns = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }
    totalPages = (filteredReturns.length / itemsPerPage).ceil();
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    if (end > filteredReturns.length) end = filteredReturns.length;
    paginatedReturns = filteredReturns.sublist(start, end);
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

  void resetFilters() {
    setState(() {
      searchQuery = '';
      filterType = 'Return Number';
      _searchController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  String getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'REQUESTED':
        return '#F59E0B';
      case 'APPROVED':
        return '#3B82F6';
      case 'SHIPMENT_CREATED':
        return '#8B5CF6';
      case 'PICKUP_PENDING':
        return '#6366F1';
      case 'PICKED':
        return '#6366F1';
      case 'RECEIVED':
        return '#10B981';
      case 'REFUNDED':
        return '#10B981';
      case 'REJECTED':
        return '#EF4444';
      case 'CANCELLED':
        return '#EF4444';
      default:
        return '#6B7280';
    }
  }

  String getReasonColor(String reason) {
    switch (reason.toUpperCase()) {
      case 'DAMAGED':
        return '#EF4444';
      case 'WRONG_PRODUCT':
        return '#F59E0B';
      case 'SIZE_ISSUE':
        return '#3B82F6';
      case 'QUALITY_ISSUE':
        return '#8B5CF6';
      default:
        return '#6B7280';
    }
  }

  // ===================== EXPORT FUNCTIONS =====================

  void exportExcel() {
    if (filteredReturns.isEmpty) {
      _showSnack('No data to export', Colors.orange);
      return;
    }
    final file = excel.Excel.createExcel();
    final sheet = file['Return Orders'];
    sheet.appendRow([
      "SR No", "Return Number", "Order Number", "Product", "Quantity",
      "Refund Amount", "Reason", "Reason Note", "Status", "Order Status", "Created At"
    ]);
    int srNo = filteredReturns.length;
    for (var r in filteredReturns) {
      sheet.appendRow([
        srNo--,
        r.returnNumber,
        r.orderNumber,
        r.product,
        r.quantity,
        r.refundAmount,
        r.reason,
        r.reasonNote,
        r.status,
        r.orderStatus,
        _formatDate(r.createdAt),
      ]);
    }
    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "return_orders.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> exportPDF() async {
    if (filteredReturns.isEmpty) {
      _showSnack('No data to export', Colors.orange);
      return;
    }
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: ["SR No", "Return No", "Order No", "Product", "Refund", "Status"],
            data: List.generate(filteredReturns.length, (index) {
              final r = filteredReturns[index];
              final srNo = filteredReturns.length - index;
              return [
                srNo.toString(),
                r.returnNumber,
                r.orderNumber,
                r.product,
                "₹${r.refundAmount.toStringAsFixed(2)}",
                r.status,
              ];
            }),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void exportDOC() {
    if (filteredReturns.isEmpty) {
      _showSnack('No data to export', Colors.orange);
      return;
    }
    final content = StringBuffer();
    content.writeln("Return Orders List\n");
    content.writeln("=" * 50);
    int srNo = filteredReturns.length;
    for (var r in filteredReturns) {
      content.writeln("SR No: ${srNo--}");
      content.writeln("Return Number: ${r.returnNumber}");
      content.writeln("Order Number: ${r.orderNumber}");
      content.writeln("Product: ${r.product}");
      content.writeln("Quantity: ${r.quantity}");
      content.writeln("Refund Amount: ₹${r.refundAmount.toStringAsFixed(2)}");
      content.writeln("Reason: ${r.reason}");
      content.writeln("Status: ${r.status}");
      content.writeln("Created: ${_formatDate(r.createdAt)}");
      content.writeln("-" * 30);
    }
    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "return_orders.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ===================== VIEW RETURN ORDER POPUP =====================

  void _showViewReturnOrderPopup(ReturnOrder order) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isThisCreating =
                isCreatingShipment && creatingReturnId == order.returnId;
            final canCreateShipment = order.status.toUpperCase() == 'REQUESTED';

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              backgroundColor: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.55,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.88,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFF7F8FF)],
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
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color(0xFF5A67F2),
                            Color(0xFF7B4DDB),
                            Color(0xFFC84DB5),
                          ],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
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
                            child: const Icon(
                              Icons.assignment_return,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Return Order Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  order.returnNumber,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
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
                              onPressed: () => Navigator.pop(context),
                              padding: const EdgeInsets.all(8),
                              constraints: const BoxConstraints(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status chips
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildStatusChip(
                                  order.status,
                                  getStatusColor(order.status),
                                ),
                                const SizedBox(width: 12),
                                _buildStatusChip(
                                  'ORDER: ${order.orderStatus}',
                                  '#10B981',
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Return Info
                            _buildSection(
                              title: 'Return Information',
                              icon: Icons.info_outline,
                              children: [
                                _buildDetailRow('Return Number', order.returnNumber),
                                _buildDetailRow('Return ID', order.returnId.toString()),
                                _buildDetailRow('Order Number', order.orderNumber),
                                _buildDetailRow('Order ID', order.orderId.toString()),
                                _buildDetailRow('Created At', _formatDate(order.createdAt)),
                                _buildDetailRow('Updated At', _formatDate(order.updatedAt)),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Product Info
                            _buildSection(
                              title: 'Product Information',
                              icon: Icons.inventory_2,
                              children: [
                                _buildDetailRow('Product', order.product),
                                _buildDetailRow('Quantity', order.quantity.toString()),
                                _buildDetailRow(
                                  'Refund Amount',
                                  '₹${order.refundAmount.toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Reason
                            _buildSection(
                              title: 'Return Reason',
                              icon: Icons.report_problem,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Color(
                                          int.parse(
                                            '0xFF${getReasonColor(order.reason).substring(1)}',
                                          ),
                                        ).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        order.reason,
                                        style: TextStyle(
                                          color: Color(
                                            int.parse(
                                              '0xFF${getReasonColor(order.reason).substring(1)}',
                                            ),
                                          ),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (order.reasonNote.isNotEmpty)
                                  _buildDetailRow('Note', order.reasonNote),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ✅ UPI Scanner Section (only if UPI ID present)
                            if (order.upiId.isNotEmpty) ...[
                              _buildSection(
                                title: 'Refund UPI QR',
                                icon: Icons.qr_code_2,
                                children: [
                                  _buildDetailRow('UPI ID', order.upiId),
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _premiumPrimary.withOpacity(0.25),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _premiumPrimary.withOpacity(0.08),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: QrImageView(
                                        data: _buildUpiUri(order),
                                        version: QrVersions.auto,
                                        size: 200,
                                        backgroundColor: Colors.white,
                                        eyeStyle: const QrEyeStyle(
                                          eyeShape: QrEyeShape.square,
                                          color: Color(0xFF1E293B),
                                        ),
                                        dataModuleStyle: const QrDataModuleStyle(
                                          dataModuleShape: QrDataModuleShape.square,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Center(
                                    child: Text(
                                      'Scan to pay ₹${order.refundAmount.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF5A67F2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Create Shipment Button
                            if (canCreateShipment)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: isThisCreating
                                      ? null
                                      : () => _createShipment(order, setDialogState),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: _premiumPrimary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                  ),
                                  icon: isThisCreating
                                      ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                      : const Icon(Icons.local_shipping),
                                  label: Text(
                                    isThisCreating
                                        ? 'Creating Shipment...'
                                        : 'Create Return Shipment',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.green.withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Shipment already created for this return.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 12),

                            // Close Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: BorderSide(color: Colors.grey.shade400),
                                ),
                                child: const Text('Close'),
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
      },
    );
  }

  /// ✅ UPI URI builder — standard UPI deep link
  String _buildUpiUri(ReturnOrder order) {
    final upi = order.upiId.trim();
    final name = Uri.encodeComponent('QNX Return Refund');
    final note = Uri.encodeComponent('Refund ${order.returnNumber}');
    final amount = order.refundAmount.toStringAsFixed(2);
    final currency = order.currency.isEmpty ? 'INR' : order.currency;

    // Standard UPI format: upi://pay?pa=...&pn=...&am=...&cu=INR&tn=...
    return 'upi://pay?pa=$upi&pn=$name&am=$amount&cu=$currency&tn=$note';
  }

  // ===================== CREATE SHIPMENT =====================

  Future<void> _createShipment(
      ReturnOrder order,
      StateSetter setDialogState,
      ) async {
    setState(() {
      isCreatingShipment = true;
      creatingReturnId = order.returnId;
    });
    setDialogState(() {});

    try {
      final response = await _service.createReturnShipment(
        returnId: order.returnId,
      );

      if (!mounted) return;
      Navigator.pop(context);

      final payload = response.shiprocketResponse?.payload;
      final awbCode = payload?.awbCode ?? 'N/A';
      final courierName = payload?.courierName ?? 'N/A';
      final success = response.success;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(
                    success ? Icons.check_circle : Icons.error,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    success
                        ? '✅ Return Shipment Created!'
                        : '❌ Failed to Create Shipment',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              if (success) ...[
                const SizedBox(height: 4),
                Text(
                  'AWB: $awbCode',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                Text(
                  'Courier: $courierName',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ] else ...[
                const SizedBox(height: 4),
                Text(
                  response.message,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ],
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          duration: Duration(seconds: success ? 5 : 4),
        ),
      );

      if (success) {
        loadReturnOrders();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isCreatingShipment = false;
          creatingReturnId = null;
        });
      }
    }
  }

  // ===================== HELPERS =====================

  void _showSnack(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  String _formatDate(String dateTime) {
    try {
      final parts = dateTime.split('T');
      final date = parts[0];
      final time = parts[1].split('.')[0];
      return '$date $time';
    } catch (e) {
      return dateTime;
    }
  }

  Widget _buildStatusChip(String status, String colorHex) {
    final color = Color(int.parse('0xFF${colorHex.substring(1)}'));
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
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            status,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF5A67F2),
                    Color(0xFF7B4DDB),
                    Color(0xFFC84DB5),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF5A67F2),
                  Color(0xFF7B4DDB),
                  Color(0xFFC84DB5),
                ],
              ).createShader(bounds),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
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

  // ===================== TABLE WIDGETS =====================

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
      ),
    );
  }

  Widget _tableCell(String text, {VoidCallback? onTap, bool isBold = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildTableStatusChip(String status, String colorHex) {
    final color = Color(int.parse('0xFF${colorHex.substring(1)}'));
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildExportIcons() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: "Export Excel",
          child: InkWell(
            onTap: exportExcel,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset("assets/icon/xls.png", height: 18, width: 18),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: "Export PDF",
          child: InkWell(
            onTap: exportPDF,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset("assets/icon/pdf.png", height: 18, width: 18),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: "Export DOC",
          child: InkWell(
            onTap: exportDOC,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset("assets/icon/doc.png", height: 18, width: 18),
            ),
          ),
        ),
      ],
    );
  }

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
                Flexible(
                  flex: 1,
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: filterType,
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Color(0xFF6366F1), size: 20),
                        style: const TextStyle(
                            color: Color(0xFF1E293B), fontSize: 10),
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          setState(() {
                            filterType = newValue!;
                            currentPage = 1;
                            applyFilters();
                          });
                        },
                        items: const [
                          'Return Number',
                          'Order Number',
                          'Product',
                          'Status',
                          'Reason',
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontSize: 10)),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  flex: 2,
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 8),
                        const Icon(Icons.search, size: 14, color: Color(0xFF6366F1)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search...',
                              hintStyle: const TextStyle(fontSize: 10),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                              suffixIcon: searchQuery.isNotEmpty
                                  ? GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {
                                    searchQuery = '';
                                    currentPage = 1;
                                    applyFilters();
                                  });
                                },
                                child: const Icon(Icons.clear,
                                    size: 14, color: Colors.grey),
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildExportIcons(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Total: ${filteredReturns.length}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: resetFilters,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.refresh, size: 14, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  width: 160,
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
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Color(0xFF6366F1)),
                      style: const TextStyle(
                          color: Color(0xFF1E293B), fontSize: 13),
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        setState(() {
                          filterType = newValue!;
                          currentPage = 1;
                          applyFilters();
                        });
                      },
                      items: const [
                        'Return Number',
                        'Order Number',
                        'Product',
                        'Status',
                        'Reason',
                      ].map<DropdownMenuItem<String>>((String value) {
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
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: _getHintText(),
                        prefixIcon: const Icon(Icons.search,
                            size: 16, color: Color(0xFF6366F1)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                        isDense: true,
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
                _buildExportIcons(),
                const SizedBox(width: 12),
                Row(
                  children: [
                    Text(
                      "Total: ${filteredReturns.length}",
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.grey),
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
        ],
      ),
    );
  }

  String _getHintText() {
    switch (filterType) {
      case 'Return Number':
        return "Search by return number...";
      case 'Order Number':
        return "Search by order number...";
      case 'Product':
        return "Search by product...";
      case 'Status':
        return "Search by status...";
      case 'Reason':
        return "Search by reason...";
      default:
        return "Search...";
    }
  }

  Widget _buildPagination() {
    if (filteredReturns.isEmpty) return const SizedBox.shrink();
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
                      .map((e) => DropdownMenuItem(
                      value: e, child: Text(e.toString())))
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
                    "${currentPage * itemsPerPage > filteredReturns.length ? filteredReturns.length : currentPage * itemsPerPage} "
                    "of ${filteredReturns.length}",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          );

          final List<Widget> pageButtons = [
            _compactPageButton(
                icon: Icons.chevron_left,
                onTap: currentPage > 1 ? previousPage : null),
            if (totalPages <= 5)
              ...List.generate(totalPages, (i) => _compactPageNumber(i + 1))
            else ...[
              _compactPageNumber(1),
              if (currentPage > 3)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text("...",
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
              _compactPageNumber(currentPage.clamp(1, totalPages)),
              if (currentPage < totalPages - 2)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text("...",
                      style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
              _compactPageNumber(totalPages),
            ],
            _compactPageButton(
                icon: Icons.chevron_right,
                onTap: currentPage < totalPages ? nextPage : null),
          ];

          final paginationRow = Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: pageButtons,
          );

          if (constraints.maxWidth < 700) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [showEntriesRow, const SizedBox(height: 8), paginationRow],
            );
          }
          return SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [showEntriesRow, paginationRow],
            ),
          );
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

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Return Orders",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadReturnOrders,
            tooltip: 'Refresh',
          ),
        ],
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
                  // Header
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SingleChildScrollView(
                      controller: _headerHorizontalController,
                      scrollDirection: Axis.horizontal,
                      child: Table(
                        border: TableBorder(
                          horizontalInside:
                          BorderSide(color: Colors.grey.shade300),
                          verticalInside:
                          BorderSide(color: Colors.grey.shade300),
                          top: BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(color: Colors.grey.shade300),
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
                  // Body
                  Expanded(
                    child: filteredReturns.isEmpty
                        ? const Center(child: Text("No return orders found"))
                        : SingleChildScrollView(
                      controller: _verticalController,
                      child: SingleChildScrollView(
                        controller: _rowsHorizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          border: TableBorder.all(
                              color: Colors.grey.shade300, width: 1),
                          columnWidths: columnWidths,
                          children: List.generate(
                              paginatedReturns.length, (rowIndex) {
                            final returnOrder = paginatedReturns[rowIndex];
                            final isEven = rowIndex % 2 == 0;
                            final srNo = filteredReturns.length -
                                ((currentPage - 1) * itemsPerPage +
                                    rowIndex);
                            final canCreateShipment =
                                returnOrder.status.toUpperCase() ==
                                    'REQUESTED';
                            final isThisCreating =
                                isCreatingShipment &&
                                    creatingReturnId ==
                                        returnOrder.returnId;

                            return TableRow(
                              decoration: BoxDecoration(
                                color: isEven
                                    ? Colors.white
                                    : const Color(0xFFF8FAFC),
                              ),
                              children: [
                                _tableCell(
                                  srNo.toString(),
                                  onTap: () =>
                                      _showViewReturnOrderPopup(returnOrder),
                                ),
                                _tableCell(
                                  returnOrder.returnNumber,
                                  onTap: () =>
                                      _showViewReturnOrderPopup(returnOrder),
                                  isBold: true,
                                ),
                                _tableCell(
                                  returnOrder.orderNumber,
                                  onTap: () =>
                                      _showViewReturnOrderPopup(returnOrder),
                                ),
                                _tableCell(
                                  returnOrder.product,
                                  onTap: () =>
                                      _showViewReturnOrderPopup(returnOrder),
                                ),
                                _tableCell(
                                  returnOrder.quantity.toString(),
                                  onTap: () =>
                                      _showViewReturnOrderPopup(returnOrder),
                                ),
                                _tableCell(
                                  '₹${returnOrder.refundAmount.toStringAsFixed(2)}',
                                  onTap: () =>
                                      _showViewReturnOrderPopup(returnOrder),
                                  isBold: true,
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      _showViewReturnOrderPopup(returnOrder),
                                  child: Container(
                                    height: 42,
                                    padding: const EdgeInsets.all(2),
                                    alignment: Alignment.center,
                                    child: _buildTableStatusChip(
                                      returnOrder.reason,
                                      getReasonColor(returnOrder.reason),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      _showViewReturnOrderPopup(returnOrder),
                                  child: Container(
                                    height: 42,
                                    padding: const EdgeInsets.all(2),
                                    alignment: Alignment.center,
                                    child: _buildTableStatusChip(
                                      returnOrder.status,
                                      getStatusColor(returnOrder.status),
                                    ),
                                  ),
                                ),
                                _tableCell(
                                  _formatDate(returnOrder.createdAt)
                                      .substring(0, 10),
                                  onTap: () =>
                                      _showViewReturnOrderPopup(returnOrder),
                                ),
                                Container(
                                  height: 42,
                                  padding: const EdgeInsets.all(4),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.center,
                                    children: [
                                      Tooltip(
                                        message: 'View Details',
                                        child: InkWell(
                                          onTap: () =>
                                              _showViewReturnOrderPopup(
                                                  returnOrder),
                                          borderRadius:
                                          BorderRadius.circular(6),
                                          child: Container(
                                            padding:
                                            const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                  0xFF6366F1)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                              BorderRadius.circular(
                                                  6),
                                            ),
                                            child: const Icon(
                                              Icons.visibility,
                                              size: 14,
                                              color:
                                              Color(0xFF6366F1),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      if (canCreateShipment)
                                        Tooltip(
                                          message: 'Create Shipment',
                                          child: InkWell(
                                            onTap: isThisCreating
                                                ? null
                                                : () => _createShipment(
                                                returnOrder,
                                                setState),
                                            borderRadius:
                                            BorderRadius.circular(
                                                6),
                                            child: Container(
                                              padding:
                                              const EdgeInsets.all(
                                                  4),
                                              decoration: BoxDecoration(
                                                color: Colors.green
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                BorderRadius
                                                    .circular(6),
                                              ),
                                              child: isThisCreating
                                                  ? const SizedBox(
                                                width: 12,
                                                height: 12,
                                                child:
                                                CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                  AlwaysStoppedAnimation<
                                                      Color>(
                                                    Colors.green,
                                                  ),
                                                ),
                                              )
                                                  : const Icon(
                                                Icons
                                                    .local_shipping,
                                                size: 14,
                                                color:
                                                Colors.green,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
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
            ),
            const SizedBox(height: 8),
            _buildPagination(),
          ],
        ),
      ),
    );
  }
}