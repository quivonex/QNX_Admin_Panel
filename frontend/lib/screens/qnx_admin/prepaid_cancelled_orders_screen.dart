// lib/screens/shiprocket/prepaid_cancelled_orders_screen.dart

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../api/shiprocket_service.dart';
import '../../models/shiprocket/prepaid_cancelled_order_model.dart';

class PrepaidCancelledOrdersScreen extends StatefulWidget {
  const PrepaidCancelledOrdersScreen({super.key});

  @override
  State<PrepaidCancelledOrdersScreen> createState() =>
      _PrepaidCancelledOrdersScreenState();
}

class _PrepaidCancelledOrdersScreenState
    extends State<PrepaidCancelledOrdersScreen> {
  final PrepaidCancelledOrdersService _service = PrepaidCancelledOrdersService();

  List<PrepaidCancelledOrder> allOrders = [];
  List<PrepaidCancelledOrder> filteredOrders = [];
  List<PrepaidCancelledOrder> paginatedOrders = [];

  bool isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String filterType = 'Order Number';

  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  static const Color _premiumPrimary = Color(0xFF5A67F2);

  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(50),  // SR
    1: FixedColumnWidth(130), // Order No
    2: FixedColumnWidth(180), // Product
    3: FixedColumnWidth(60),  // Qty
    4: FixedColumnWidth(90),  // Refund
    5: FixedColumnWidth(100), // UPI ID
    6: FixedColumnWidth(100), // Payment
    7: FixedColumnWidth(100), // Status
    8: FixedColumnWidth(90),  // Created
    9: FixedColumnWidth(80),  // Action
  };

  final List<String> headerLabels = [
    "SR", "Order No", "Product", "Qty", "Refund",
    "UPI ID", "Payment", "Status", "Created", "Action"
  ];

  @override
  void initState() {
    super.initState();
    loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> loadOrders() async {
    setState(() => isLoading = true);
    try {
      final response = await _service.getPrepaidCancelledOrders();
      if (mounted) {
        setState(() {
          allOrders = response.data;
          allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          isLoading = false;
          applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void applyFilters() {
    if (searchQuery.isEmpty) {
      filteredOrders = List.from(allOrders);
    } else {
      final q = searchQuery.toLowerCase();
      filteredOrders = allOrders.where((o) {
        switch (filterType) {
          case 'Order Number':
            return o.orderNumber.toLowerCase().contains(q);
          case 'Product':
            return o.product.toLowerCase().contains(q);
          case 'UPI ID':
            return o.upiId.toLowerCase().contains(q);
          case 'Status':
            return o.status.toLowerCase().contains(q);
          default:
            return false;
        }
      }).toList();
    }
    applyPagination();
  }

  void applyPagination() {
    if (filteredOrders.isEmpty) {
      paginatedOrders = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }
    totalPages = (filteredOrders.length / itemsPerPage).ceil();
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;
    final start = (currentPage - 1) * itemsPerPage;
    final end = (start + itemsPerPage).clamp(0, filteredOrders.length);
    paginatedOrders = filteredOrders.sublist(start, end);
    setState(() {});
  }

  void goToPage(int p) {
    if (p >= 1 && p <= totalPages) {
      setState(() {
        currentPage = p;
        applyPagination();
      });
    }
  }

  void resetFilters() {
    setState(() {
      searchQuery = '';
      filterType = 'Order Number';
      _searchController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  String _formatDate(String dt) {
    try {
      final parts = dt.split('T');
      return '${parts[0]} ${parts[1].split('.')[0]}';
    } catch (_) {
      return dt;
    }
  }

  // ==================== UPI URI ====================
  String _buildUpiUri(PrepaidCancelledOrder order) {
    final upi = order.upiId.trim();
    final name = Uri.encodeComponent('QNX Refund');
    final note = Uri.encodeComponent('Refund ${order.orderNumber}');
    final amount = order.refundAmount.toStringAsFixed(2);
    final currency = order.currency.isEmpty ? 'INR' : order.currency;
    return 'upi://pay?pa=$upi&pn=$name&am=$amount&cu=$currency&tn=$note';
  }

  // ==================== POPUP ====================
  void _showDetailsPopup(PrepaidCancelledOrder order) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
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
                          Icons.cancel_schedule_send,
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
                              'Prepaid Cancelled Order',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              order.orderNumber,
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
                            _chip(order.status, const Color(0xFFEF4444)),
                            const SizedBox(width: 12),
                            _chip(
                              order.paymentStatus
                                  ? 'PAYMENT: PAID'
                                  : 'PAYMENT: NOT RECEIVED',
                              order.paymentStatus
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        _section(
                          title: 'Order Information',
                          icon: Icons.info_outline,
                          children: [
                            _row('Order Number', order.orderNumber),
                            _row('Order ID', order.orderId.toString()),
                            _row('User ID', order.userId.toString()),
                            _row('Company ID', order.companyId.toString()),
                            _row('Source', order.source),
                            _row('Created At', _formatDate(order.createdAt)),
                            _row('Updated At', _formatDate(order.updatedAt)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        _section(
                          title: 'Product Information',
                          icon: Icons.inventory_2,
                          children: [
                            _row('Product', order.product),
                            _row('Product ID', order.productId.toString()),
                            _row('Quantity', order.quantity.toString()),
                            _row('Payment Method', order.paymentMethod),
                          ],
                        ),
                        const SizedBox(height: 20),

                        _section(
                          title: 'Amount Breakdown',
                          icon: Icons.receipt_long,
                          children: [
                            _row('Subtotal',
                                '₹${order.subtotal.toStringAsFixed(2)}'),
                            _row('Shipping Charge',
                                '₹${order.shippingCharge.toStringAsFixed(2)}'),
                            _row('Tax Amount',
                                '₹${order.taxAmount.toStringAsFixed(2)}'),
                            _row('Discount',
                                '₹${order.discountAmount.toStringAsFixed(2)}'),
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF5A67F2),
                                    Color(0xFFC84DB5)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Refund Amount',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    '₹${order.refundAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // UPI QR (only if upiId exists)
                        if (order.upiId.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _section(
                            title: 'Refund UPI QR',
                            icon: Icons.qr_code_2,
                            children: [
                              _row('UPI ID', order.upiId),
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
                                    dataModuleStyle:
                                    const QrDataModuleStyle(
                                      dataModuleShape:
                                      QrDataModuleShape.square,
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
                        ] else ...[
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.orange.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: Colors.orange, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'UPI ID not available for this order.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),
                        if (order.notes.isNotEmpty)
                          _section(
                            title: 'Notes',
                            icon: Icons.sticky_note_2,
                            children: [_row('Note', order.notes)],
                          ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding:
                              const EdgeInsets.symmetric(vertical: 12),
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
  }

  // ==================== HELPERS ====================
  Widget _chip(String text, Color color) {
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
            text,
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

  Widget _section({
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
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

  Widget _row(String label, String value) {
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

  Widget _tableCell(String text, {bool bold = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String status, Color color) {
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

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Prepaid Cancelled Orders",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadOrders,
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
            // ---- Filter bar ----
            Container(
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
              child: Row(
                children: [
                  Container(
                    width: 150,
                    height: 40,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border:
                      Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: filterType,
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Color(0xFF6366F1)),
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF1E293B)),
                        isExpanded: true,
                        onChanged: (v) {
                          setState(() {
                            filterType = v!;
                            currentPage = 1;
                            applyFilters();
                          });
                        },
                        items: const [
                          'Order Number',
                          'Product',
                          'UPI ID',
                          'Status',
                        ]
                            .map((v) => DropdownMenuItem(
                            value: v, child: Text(v)))
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border:
                        Border.all(color: Colors.grey.shade200),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by $filterType...',
                          prefixIcon: const Icon(Icons.search,
                              size: 16, color: Color(0xFF6366F1)),
                          border: InputBorder.none,
                          contentPadding:
                          const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          isDense: true,
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                            icon: const Icon(Icons.clear,
                                size: 16),
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
                        onChanged: (v) {
                          setState(() {
                            searchQuery = v;
                            currentPage = 1;
                            applyFilters();
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Total: ${filteredOrders.length}",
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: resetFilters,
                    icon: const Icon(Icons.refresh,
                        color: Colors.red, size: 18),
                    tooltip: 'Reset',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ---- Table ----
            Expanded(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12)),
                      border:
                      Border.all(color: Colors.grey.shade300),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Table(
                        border: TableBorder(
                          horizontalInside: BorderSide(
                              color: Colors.grey.shade300),
                          verticalInside: BorderSide(
                              color: Colors.grey.shade300),
                          top: BorderSide(
                              color: Colors.grey.shade300),
                          bottom: BorderSide(
                              color: Colors.grey.shade300),
                        ),
                        columnWidths: columnWidths,
                        children: [
                          TableRow(
                            children: headerLabels
                                .map(_tableHeader)
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: filteredOrders.isEmpty
                        ? const Center(
                        child: Text(
                            "No prepaid cancelled orders found"))
                        : SingleChildScrollView(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          border: TableBorder.all(
                              color: Colors.grey.shade300,
                              width: 1),
                          columnWidths: columnWidths,
                          children: List.generate(
                              paginatedOrders.length, (i) {
                            final o = paginatedOrders[i];
                            final even = i % 2 == 0;
                            final sr = filteredOrders.length -
                                ((currentPage - 1) *
                                    itemsPerPage +
                                    i);
                            return TableRow(
                              decoration: BoxDecoration(
                                color: even
                                    ? Colors.white
                                    : const Color(0xFFF8FAFC),
                              ),
                              children: [
                                _tableCell(sr.toString(),
                                    onTap: () =>
                                        _showDetailsPopup(o)),
                                _tableCell(o.orderNumber,
                                    bold: true,
                                    onTap: () =>
                                        _showDetailsPopup(o)),
                                _tableCell(o.product,
                                    onTap: () =>
                                        _showDetailsPopup(o)),
                                _tableCell(
                                    o.quantity.toString(),
                                    onTap: () =>
                                        _showDetailsPopup(o)),
                                _tableCell(
                                  '₹${o.refundAmount.toStringAsFixed(2)}',
                                  bold: true,
                                  onTap: () =>
                                      _showDetailsPopup(o),
                                ),
                                _tableCell(
                                  o.upiId.isEmpty
                                      ? '—'
                                      : o.upiId,
                                  onTap: () =>
                                      _showDetailsPopup(o),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      _showDetailsPopup(o),
                                  child: Container(
                                    height: 42,
                                    alignment:
                                    Alignment.center,
                                    padding:
                                    const EdgeInsets.all(
                                        2),
                                    child: _statusChip(
                                      o.paymentStatus
                                          ? 'PAID'
                                          : 'NOT PAID',
                                      o.paymentStatus
                                          ? const Color(
                                          0xFF10B981)
                                          : const Color(
                                          0xFFF59E0B),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      _showDetailsPopup(o),
                                  child: Container(
                                    height: 42,
                                    alignment:
                                    Alignment.center,
                                    padding:
                                    const EdgeInsets.all(
                                        2),
                                    child: _statusChip(
                                      o.status,
                                      const Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                                _tableCell(
                                  _formatDate(o.createdAt)
                                      .substring(0, 10),
                                  onTap: () =>
                                      _showDetailsPopup(o),
                                ),
                                Container(
                                  height: 42,
                                  alignment:
                                  Alignment.center,
                                  padding:
                                  const EdgeInsets.all(
                                      4),
                                  child: Tooltip(
                                    message: 'View Details',
                                    child: InkWell(
                                      onTap: () =>
                                          _showDetailsPopup(
                                              o),
                                      borderRadius:
                                      BorderRadius
                                          .circular(6),
                                      child: Container(
                                        padding:
                                        const EdgeInsets
                                            .all(4),
                                        decoration:
                                        BoxDecoration(
                                          color: const Color(
                                              0xFF6366F1)
                                              .withOpacity(
                                              0.1),
                                          borderRadius:
                                          BorderRadius
                                              .circular(
                                              6),
                                        ),
                                        child: const Icon(
                                          Icons.visibility,
                                          size: 14,
                                          color: Color(
                                              0xFF6366F1),
                                        ),
                                      ),
                                    ),
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

            // ---- Pagination ----
            if (filteredOrders.isNotEmpty) _buildPagination(),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final left = Row(
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
                  value: itemsPerPage,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  style: const TextStyle(fontSize: 12),
                  items: rowsPerPageOptions
                      .map((e) =>
                      DropdownMenuItem(value: e, child: Text('$e')))
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
                    "${currentPage * itemsPerPage > filteredOrders.length ? filteredOrders.length : currentPage * itemsPerPage} "
                    "of ${filteredOrders.length}",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          );

          final buttons = [
            _pageBtn(Icons.chevron_left, currentPage > 1
                ? () => goToPage(currentPage - 1)
                : null),
            ...List.generate(
              totalPages > 5 ? 5 : totalPages,
                  (i) => _pageNum(i + 1),
            ),
            _pageBtn(Icons.chevron_right, currentPage < totalPages
                ? () => goToPage(currentPage + 1)
                : null),
          ];

          if (constraints.maxWidth < 700) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                left,
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: buttons),
              ],
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              left,
              Row(children: buttons),
            ],
          );
        },
      ),
    );
  }

  Widget _pageBtn(IconData icon, VoidCallback? onTap) {
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

  Widget _pageNum(int p) {
    final sel = currentPage == p;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: sel ? const Color(0xFF6366F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: () => goToPage(p),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: Text(
            '$p',
            style: TextStyle(
              color: sel ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}