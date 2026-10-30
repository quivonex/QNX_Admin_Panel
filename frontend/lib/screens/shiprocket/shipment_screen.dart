// lib/screens/qnx_admin/shipment_screen.dart

// lib/screens/qnx_admin/shipment_screen.dart
// lib/screens/qnx_admin/shipment_screen.dart

import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import '../../api/shiprocket_service.dart';
import '../../models/shiprocket/shipment_model.dart';

class ShipmentScreen extends StatefulWidget {
  const ShipmentScreen({super.key});

  @override
  State<ShipmentScreen> createState() => _ShipmentScreenState();
}

class _ShipmentScreenState extends State<ShipmentScreen> {
  final ShipmentService _service = ShipmentService();

  List<Shipment> allShipments = [];
  List<Shipment> filteredShipments = [];
  List<Shipment> paginatedShipments = [];

  bool isLoading = true;
  bool isAssigning = false;
  String? assigningShipmentId; // Track which shipment is being assigned

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String filterType = 'Order';

  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  // Column widths - Optimized
  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(60),   // SR No
    1: FixedColumnWidth(115),  // Order Number
    2: FixedColumnWidth(115),  // ShipRocket Order ID
    3: FixedColumnWidth(100),  // Shipment ID
    4: FixedColumnWidth(110),  // AWB Code
    5: FixedColumnWidth(130),  // Courier Company
    6: FixedColumnWidth(100),  // Status
    7: FixedColumnWidth(100),  // Pickup Status
    8: FixedColumnWidth(85),   // Created
    9: FixedColumnWidth(75),   // Actions
  };

  final List<String> headerLabels = [
    "SR No", "Order", "SR Order ID", "Shipment ID",
    "AWB Code", "Courier", "Status", "Pickup", "Created", "Actions"
  ];

  // Premium color palette
  static const Color _premiumPrimary = Color(0xFF5A67F2);
  static const Color _premiumSecondary = Color(0xFF7B4DDB);
  static const Color _premiumAccent = Color(0xFFC84DB5);
  static const Color _premiumGold = Color(0xFF5A67F2);
  static const Color _premiumLight = Color(0xFF7B4DDB);
  static const Color _premiumBg = Color(0xFFF7F8FF);
  static const Color _premiumCard = Colors.white;

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();
    loadShipments();
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

  Future<void> loadShipments() async {
    setState(() => isLoading = true);
    try {
      final response = await _service.getShipments();
      if (mounted) {
        setState(() {
          allShipments = response.data;
          // Sort by created_at descending (newest first)
          allShipments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load shipments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void applyFilters() {
    if (searchQuery.isEmpty) {
      filteredShipments = List.from(allShipments);
    } else {
      final query = searchQuery.toLowerCase();
      filteredShipments = allShipments.where((shipment) {
        switch (filterType) {
          case 'Order':
            return shipment.orderNumber.toLowerCase().contains(query);
          case 'SR Order ID':
            return shipment.shiprocketOrderId.toLowerCase().contains(query);
          case 'Shipment ID':
            return shipment.shipmentId.toLowerCase().contains(query);
          case 'AWB Code':
            return shipment.awbCode.toLowerCase().contains(query);
          case 'Courier':
            return shipment.courierCompany.toLowerCase().contains(query);
          case 'Status':
            return shipment.status.toLowerCase().contains(query);
          default:
            return false;
        }
      }).toList();
    }
    applyPagination();
  }

  void applyPagination() {
    if (filteredShipments.isEmpty) {
      paginatedShipments = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }
    totalPages = (filteredShipments.length / itemsPerPage).ceil();
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    if (end > filteredShipments.length) end = filteredShipments.length;
    paginatedShipments = filteredShipments.sublist(start, end);
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
      filterType = 'Order';
      _searchController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  String getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return '#3B82F6';
      case 'ORDER_CANCELLED':
        return '#EF4444';
      case 'PICKUP_REQUESTED':
        return '#F59E0B';
      case 'PICKUP_ASSIGNED':
        return '#8B5CF6';
      case 'SHIPPED':
        return '#10B981';
      case 'DELIVERED':
        return '#10B981';
      case 'RTO':
        return '#EF4444';
      default:
        return '#6B7280';
    }
  }

  String getPickupStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return '#F59E0B';
      case 'ASSIGNED':
        return '#3B82F6';
      case 'PICKED':
        return '#10B981';
      case 'FAILED':
        return '#EF4444';
      default:
        return '#6B7280';
    }
  }

  // ===================== EXPORT FUNCTIONS =====================

  void exportExcel() {
    if (filteredShipments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final file = excel.Excel.createExcel();
    final sheet = file['Shipments'];
    sheet.appendRow([
      "SR No", "Order Number", "ShipRocket Order ID", "Shipment ID",
      "AWB Code", "Courier Company", "Status", "Pickup Status", "Created At"
    ]);

    int srNo = filteredShipments.length;
    for (var s in filteredShipments) {
      sheet.appendRow([
        srNo--,
        s.orderNumber,
        s.shiprocketOrderId,
        s.shipmentId,
        s.awbCode.isEmpty ? "Not Assigned" : s.awbCode,
        s.courierCompany.isEmpty ? "Not Assigned" : s.courierCompany,
        s.status,
        s.pickupStatus,
        _formatDate(s.createdAt),
      ]);
    }

    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "shipments.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> exportPDF() async {
    if (filteredShipments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: ["SR No", "Order Number", "SR Order ID", "Shipment ID", "AWB Code", "Courier", "Status", "Pickup"],
            data: List.generate(filteredShipments.length, (index) {
              final s = filteredShipments[index];
              final srNo = filteredShipments.length - index;
              return [
                srNo.toString(),
                s.orderNumber,
                s.shiprocketOrderId,
                s.shipmentId,
                s.awbCode.isEmpty ? "Not Assigned" : s.awbCode,
                s.courierCompany.isEmpty ? "Not Assigned" : s.courierCompany,
                s.status,
                s.pickupStatus,
              ];
            }),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void exportDOC() {
    if (filteredShipments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final content = StringBuffer();
    content.writeln("ShipRocket Shipments List\n");
    content.writeln("=" * 50);

    int srNo = filteredShipments.length;
    for (var s in filteredShipments) {
      content.writeln("SR No: ${srNo--}");
      content.writeln("Order Number: ${s.orderNumber}");
      content.writeln("ShipRocket Order ID: ${s.shiprocketOrderId}");
      content.writeln("Shipment ID: ${s.shipmentId}");
      content.writeln("AWB Code: ${s.awbCode.isEmpty ? "Not Assigned" : s.awbCode}");
      content.writeln("Courier Company: ${s.courierCompany.isEmpty ? "Not Assigned" : s.courierCompany}");
      content.writeln("Status: ${s.status}");
      content.writeln("Pickup Status: ${s.pickupStatus}");
      content.writeln("Created: ${_formatDate(s.createdAt)}");
      content.writeln("-" * 30);
    }

    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "shipments.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ===================== VIEW SHIPMENT POPUP =====================

  void _showViewShipmentPopup(Shipment shipment) {
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
            width: MediaQuery.of(context).size.width * 0.6,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  _premiumBg,
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
                _buildPopupHeader(
                  title: 'Shipment Details',
                  subtitle: shipment.orderNumber,
                  icon: Icons.local_shipping,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Chips
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPremiumStatusChip(
                              shipment.status,
                              getStatusColor(shipment.status),
                            ),
                            const SizedBox(width: 12),
                            _buildPremiumStatusChip(
                              shipment.pickupStatus,
                              getPickupStatusColor(shipment.pickupStatus),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Shipment Information
                        _buildPremiumSection(
                          title: "Shipment Information",
                          icon: Icons.info_outline,
                          children: [
                            _buildDetailRow("Order Number", shipment.orderNumber),
                            _buildDetailRow("ShipRocket Order ID", shipment.shiprocketOrderId),
                            _buildDetailRow("Shipment ID", shipment.shipmentId),
                            _buildDetailRow("AWB Code", shipment.awbCode.isEmpty ? "Not Assigned" : shipment.awbCode),
                            _buildDetailRow("Courier Company", shipment.courierCompany.isEmpty ? "Not Assigned" : shipment.courierCompany),
                            _buildDetailRow("Created At", _formatDate(shipment.createdAt)),
                            _buildDetailRow("Updated At", _formatDate(shipment.updatedAt)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Shipping Details
                        _buildPremiumSection(
                          title: "Shipping Details",
                          icon: Icons.attach_money,
                          children: [
                            _buildDetailRow("Shipping Charge", "₹${shipment.shippingCharge}"),
                            _buildDetailRow("Pickup Status", shipment.pickupStatus),
                            _buildDetailRow("Pickup Request ID", shipment.pickupRequestId ?? "N/A"),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Assign AWB Button - Direct assign
                        if (shipment.awbCode.isEmpty || shipment.courierCompany.isEmpty)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: (isAssigning && assigningShipmentId == shipment.shipmentId)
                                  ? null
                                  : () => _assignAWB(shipment),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: _premiumPrimary,
                                foregroundColor: Colors.white,
                              ),
                              icon: (isAssigning && assigningShipmentId == shipment.shipmentId)
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                                  : const Icon(Icons.assignment_add),
                              label: (isAssigning && assigningShipmentId == shipment.shipmentId)
                                  ? const Text('Assigning...')
                                  : const Text('Assign AWB'),
                            ),
                          ),
                        const SizedBox(height: 12),
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
  }

  // ===================== DIRECT AWB ASSIGNMENT =====================
  /// Assign AWB to shipment using only shipment ID
  /// The backend automatically selects the best courier
  // ===================== DIRECT AWB ASSIGNMENT =====================
  /// Assign AWB to shipment using only shipment ID
  /// The backend automatically selects the best courier
// ===================== DIRECT AWB ASSIGNMENT =====================
  Future<void> _assignAWB(Shipment shipment) async {
    setState(() => isAssigning = true);

    try {
      // ✅ Correct - only sends shipmentId
      final assignResponse = await _service.assignAWB(
        shipmentId: shipment.shipmentId,
      );

      if (mounted) {
        Navigator.pop(context);  // Close popup

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              assignResponse.success
                  ? '✅ AWB assigned successfully!\nAWB: ${assignResponse.data?.response.data.awbCode ?? 'N/A'}\nCourier: ${assignResponse.data?.response.data.courierName ?? 'N/A'}'
                  : '❌ Failed to assign AWB: ${assignResponse.message}',
            ),
            backgroundColor: assignResponse.success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );

        setState(() => isAssigning = false);
        loadShipments();  // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error assigning AWB: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() => isAssigning = false);
      }
    }
  }

  // ===================== POPUP HELPERS =====================

  Widget _buildPopupHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
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
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
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
    );
  }

  Widget _buildPremiumStatusChip(String status, String colorHex) {
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
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
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
                  fontSize: 18,
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
            width: 110,
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
        height: 38,
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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

  // ===================== FILTER SECTION =====================

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
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1), size: 20),
                        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 10),
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          setState(() {
                            filterType = newValue!;
                            currentPage = 1;
                            applyFilters();
                          });
                        },
                        items: [
                          'Order',
                          'SR Order ID',
                          'Shipment ID',
                          'AWB Code',
                          'Courier',
                          'Status'
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Row(
                              children: [
                                Icon(
                                  value == 'Order' ? Icons.receipt_long
                                      : value == 'SR Order ID' ? Icons.local_shipping
                                      : value == 'Shipment ID' ? Icons.inventory
                                      : value == 'AWB Code' ? Icons.qr_code
                                      : value == 'Courier' ? Icons.business
                                      : Icons.info_outline,
                                  size: 12,
                                  color: const Color(0xFF6366F1),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    value,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(fontSize: 10),
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
                        Icon(Icons.search, size: 14, color: const Color(0xFF6366F1)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: _getHintText(),
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
                                child: const Icon(Icons.clear, size: 14, color: Colors.grey),
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
                        const SizedBox(width: 4),
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
                      "Total: ${filteredShipments.length}",
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 10),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: resetFilters,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.all(4),
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
                      items: [
                        'Order',
                        'SR Order ID',
                        'Shipment ID',
                        'AWB Code',
                        'Courier',
                        'Status'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Icon(
                                value == 'Order' ? Icons.receipt_long
                                    : value == 'SR Order ID' ? Icons.local_shipping
                                    : value == 'Shipment ID' ? Icons.inventory
                                    : value == 'AWB Code' ? Icons.qr_code
                                    : value == 'Courier' ? Icons.business
                                    : Icons.info_outline,
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
                        prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF6366F1)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
                      "Total: ${filteredShipments.length}",
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
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

  String _getHintText() {
    switch (filterType) {
      case 'Order':
        return "Search by order...";
      case 'SR Order ID':
        return "Search by SR order ID...";
      case 'Shipment ID':
        return "Search by shipment ID...";
      case 'AWB Code':
        return "Search by AWB code...";
      case 'Courier':
        return "Search by courier...";
      case 'Status':
        return "Search by status...";
      default:
        return "Search...";
    }
  }

  // ===================== PAGINATION =====================

  Widget _buildPagination() {
    if (filteredShipments.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final Widget showEntriesRow = Row(
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
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
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
                    "${currentPage * itemsPerPage > filteredShipments.length ? filteredShipments.length : currentPage * itemsPerPage} "
                    "of ${filteredShipments.length}",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          );

          final List<Widget> pageButtons = [
            _compactPageButton(icon: Icons.chevron_left, onTap: currentPage > 1 ? previousPage : null),
            if (totalPages <= 5)
              ...List.generate(totalPages, (index) => _compactPageNumber(index + 1))
            else if (currentPage <= 3) ...[
              ...List.generate(4, (index) => _compactPageNumber(index + 1)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              _compactPageNumber(totalPages),
            ] else if (currentPage >= totalPages - 2) ...[
              _compactPageNumber(1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              ...List.generate(4, (index) => _compactPageNumber(totalPages - 3 + index)),
            ] else ...[
              _compactPageNumber(1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              _compactPageNumber(currentPage - 1),
              _compactPageNumber(currentPage),
              _compactPageNumber(currentPage + 1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              _compactPageNumber(totalPages),
            ],
            _compactPageButton(icon: Icons.chevron_right, onTap: currentPage < totalPages ? nextPage : null),
          ];

          final Widget paginationRow = Row(
            mainAxisAlignment: MainAxisAlignment.end,
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
            return SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  showEntriesRow,
                  paginationRow,
                ],
              ),
            );
          }
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

  // ===================== MAIN BUILD =====================

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
          "ShipRocket Shipments",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadShipments,
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
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SingleChildScrollView(
                      controller: _headerHorizontalController,
                      scrollDirection: Axis.horizontal,
                      child: Table(
                        border: TableBorder(
                          horizontalInside: BorderSide(color: Colors.grey.shade300),
                          verticalInside: BorderSide(color: Colors.grey.shade300),
                          top: BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                        columnWidths: columnWidths,
                        children: [
                          TableRow(
                            children: headerLabels.map((label) => _tableHeader(label)).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: filteredShipments.isEmpty
                        ? const Center(child: Text("No shipments found"))
                        : SingleChildScrollView(
                      controller: _verticalController,
                      child: SingleChildScrollView(
                        controller: _rowsHorizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                          columnWidths: columnWidths,
                          children: List.generate(paginatedShipments.length, (rowIndex) {
                            final shipment = paginatedShipments[rowIndex];
                            final isEven = rowIndex % 2 == 0;
                            final srNo = filteredShipments.length - ((currentPage - 1) * itemsPerPage + rowIndex);
                            final hasAWB = shipment.awbCode.isNotEmpty && shipment.courierCompany.isNotEmpty;
                            final isThisAssigning = isAssigning && assigningShipmentId == shipment.shipmentId;

                            return TableRow(
                              decoration: BoxDecoration(
                                color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                              ),
                              children: [
                                // SR No
                                GestureDetector(
                                  onTap: () => _showViewShipmentPopup(shipment),
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        srNo.toString(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                ),
                                // Order Number
                                GestureDetector(
                                  onTap: () => _showViewShipmentPopup(shipment),
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        shipment.orderNumber,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 10),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                // ShipRocket Order ID
                                GestureDetector(
                                  onTap: () => _showViewShipmentPopup(shipment),
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        shipment.shiprocketOrderId,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 10),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                // Shipment ID
                                GestureDetector(
                                  onTap: () => _showViewShipmentPopup(shipment),
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        shipment.shipmentId,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 10),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                // AWB Code
                                GestureDetector(
                                  onTap: () => _showViewShipmentPopup(shipment),
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        shipment.awbCode.isEmpty ? 'N/A' : shipment.awbCode,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: shipment.awbCode.isEmpty ? Colors.grey : Colors.black,
                                          fontWeight: shipment.awbCode.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                // Courier Company
                                GestureDetector(
                                  onTap: () => _showViewShipmentPopup(shipment),
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        shipment.courierCompany.isEmpty ? 'N/A' : shipment.courierCompany,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: shipment.courierCompany.isEmpty ? Colors.grey : Colors.black,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                // Status
                                GestureDetector(
                                  onTap: () => _showViewShipmentPopup(shipment),
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.all(2),
                                    alignment: Alignment.center,
                                    child: _buildTableStatusChip(
                                      shipment.status,
                                      getStatusColor(shipment.status),
                                    ),
                                  ),
                                ),
                                // Pickup Status
                                GestureDetector(
                                  onTap: () => _showViewShipmentPopup(shipment),
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.all(2),
                                    alignment: Alignment.center,
                                    child: _buildTableStatusChip(
                                      shipment.pickupStatus,
                                      getPickupStatusColor(shipment.pickupStatus),
                                    ),
                                  ),
                                ),
                                // Created At
                                GestureDetector(
                                  onTap: () => _showViewShipmentPopup(shipment),
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _formatDate(shipment.createdAt).substring(0, 10),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                    ),
                                  ),
                                ),
                                // Actions
                                Container(
                                  height: 38,
                                  padding: const EdgeInsets.all(2),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // View Button
                                      Tooltip(
                                        message: 'View Details',
                                        child: InkWell(
                                          onTap: () => _showViewShipmentPopup(shipment),
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6366F1).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(
                                              Icons.visibility,
                                              size: 14,
                                              color: Color(0xFF6366F1),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      // Assign Button (only if no AWB assigned)
                                      if (!hasAWB)
                                        Tooltip(
                                          message: 'Assign AWB',
                                          child: InkWell(
                                            onTap: isThisAssigning ? null : () => _assignAWB(shipment),
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: isThisAssigning
                                                  ? const SizedBox(
                                                width: 12,
                                                height: 12,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                                ),
                                              )
                                                  : const Icon(
                                                Icons.assignment_add,
                                                size: 14,
                                                color: Colors.green,
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

/*
// lib/screens/qnx_admin/shipment_screen.dart

import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import '../../api/shiprocket_service.dart';
import '../../models/shiprocket/shipment_model.dart';
import '../../models/shiprocket/courier_rate_model.dart';

class ShipmentScreen extends StatefulWidget {
  const ShipmentScreen({super.key});

  @override
  State<ShipmentScreen> createState() => _ShipmentScreenState();
}

class _ShipmentScreenState extends State<ShipmentScreen> {
  final ShipmentService _service = ShipmentService();

  List<Shipment> allShipments = [];
  List<Shipment> filteredShipments = [];
  List<Shipment> paginatedShipments = [];

  bool isLoading = true;
  bool isAssigning = false;

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String filterType = 'Order Number';

  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  // Column widths - Optimized
  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(40),   // SR No
    1: FixedColumnWidth(105),  // Order Number
    2: FixedColumnWidth(95),   // ShipRocket Order ID
    3: FixedColumnWidth(85),   // Shipment ID
    4: FixedColumnWidth(95),   // AWB Code
    5: FixedColumnWidth(115),  // Courier Company
    6: FixedColumnWidth(80),   // Status
    7: FixedColumnWidth(80),   // Pickup Status
    8: FixedColumnWidth(85),   // Created
    9: FixedColumnWidth(65),   // Actions
  };

  final List<String> headerLabels = [
    "SR No", "Order", "SR Order ID", "Shipment ID",
    "AWB Code", "Courier", "Status", "Pickup", "Created", "Actions"
  ];

  // Premium color palette
  static const Color _premiumPrimary = Color(0xFF5A67F2);
  static const Color _premiumSecondary = Color(0xFF7B4DDB);
  static const Color _premiumAccent = Color(0xFFC84DB5);
  static const Color _premiumGold = Color(0xFF5A67F2);
  static const Color _premiumLight = Color(0xFF7B4DDB);
  static const Color _premiumBg = Color(0xFFF7F8FF);
  static const Color _premiumCard = Colors.white;

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();
    loadShipments();
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

  Future<void> loadShipments() async {
    setState(() => isLoading = true);
    try {
      final response = await _service.getShipments();
      if (mounted) {
        setState(() {
          allShipments = response.data;
          // Sort by created_at descending (newest first)
          allShipments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load shipments: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void applyFilters() {
    if (searchQuery.isEmpty) {
      filteredShipments = List.from(allShipments);
    } else {
      final query = searchQuery.toLowerCase();
      filteredShipments = allShipments.where((shipment) {
        switch (filterType) {
          case 'Order Number':
            return shipment.orderNumber.toLowerCase().contains(query);
          case 'ShipRocket Order ID':
            return shipment.shiprocketOrderId.toLowerCase().contains(query);
          case 'Shipment ID':
            return shipment.shipmentId.toLowerCase().contains(query);
          case 'AWB Code':
            return shipment.awbCode.toLowerCase().contains(query);
          case 'Courier Company':
            return shipment.courierCompany.toLowerCase().contains(query);
          case 'Status':
            return shipment.status.toLowerCase().contains(query);
          default:
            return false;
        }
      }).toList();
    }
    applyPagination();
  }

  void applyPagination() {
    if (filteredShipments.isEmpty) {
      paginatedShipments = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }
    totalPages = (filteredShipments.length / itemsPerPage).ceil();
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    if (end > filteredShipments.length) end = filteredShipments.length;
    paginatedShipments = filteredShipments.sublist(start, end);
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
      filterType = 'Order Number';
      _searchController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  String getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'NEW':
        return '#3B82F6';
      case 'ORDER_CANCELLED':
        return '#EF4444';
      case 'PICKUP_REQUESTED':
        return '#F59E0B';
      case 'PICKUP_ASSIGNED':
        return '#8B5CF6';
      case 'SHIPPED':
        return '#10B981';
      case 'DELIVERED':
        return '#10B981';
      case 'RTO':
        return '#EF4444';
      default:
        return '#6B7280';
    }
  }

  String getPickupStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return '#F59E0B';
      case 'ASSIGNED':
        return '#3B82F6';
      case 'PICKED':
        return '#10B981';
      case 'FAILED':
        return '#EF4444';
      default:
        return '#6B7280';
    }
  }

  // ===================== EXPORT FUNCTIONS =====================

  void exportExcel() {
    if (filteredShipments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final file = excel.Excel.createExcel();
    final sheet = file['Shipments'];
    sheet.appendRow([
      "SR No", "Order Number", "ShipRocket Order ID", "Shipment ID",
      "AWB Code", "Courier Company", "Status", "Pickup Status", "Created At"
    ]);

    int srNo = filteredShipments.length;
    for (var s in filteredShipments) {
      sheet.appendRow([
        srNo--,
        s.orderNumber,
        s.shiprocketOrderId,
        s.shipmentId,
        s.awbCode.isEmpty ? "Not Assigned" : s.awbCode,
        s.courierCompany.isEmpty ? "Not Assigned" : s.courierCompany,
        s.status,
        s.pickupStatus,
        _formatDate(s.createdAt),
      ]);
    }

    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "shipments.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> exportPDF() async {
    if (filteredShipments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: ["SR No", "Order Number", "SR Order ID", "Shipment ID", "AWB Code", "Courier", "Status", "Pickup"],
            data: List.generate(filteredShipments.length, (index) {
              final s = filteredShipments[index];
              final srNo = filteredShipments.length - index;
              return [
                srNo.toString(),
                s.orderNumber,
                s.shiprocketOrderId,
                s.shipmentId,
                s.awbCode.isEmpty ? "Not Assigned" : s.awbCode,
                s.courierCompany.isEmpty ? "Not Assigned" : s.courierCompany,
                s.status,
                s.pickupStatus,
              ];
            }),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void exportDOC() {
    if (filteredShipments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final content = StringBuffer();
    content.writeln("ShipRocket Shipments List\n");
    content.writeln("=" * 50);

    int srNo = filteredShipments.length;
    for (var s in filteredShipments) {
      content.writeln("SR No: ${srNo--}");
      content.writeln("Order Number: ${s.orderNumber}");
      content.writeln("ShipRocket Order ID: ${s.shiprocketOrderId}");
      content.writeln("Shipment ID: ${s.shipmentId}");
      content.writeln("AWB Code: ${s.awbCode.isEmpty ? "Not Assigned" : s.awbCode}");
      content.writeln("Courier Company: ${s.courierCompany.isEmpty ? "Not Assigned" : s.courierCompany}");
      content.writeln("Status: ${s.status}");
      content.writeln("Pickup Status: ${s.pickupStatus}");
      content.writeln("Created: ${_formatDate(s.createdAt)}");
      content.writeln("-" * 30);
    }

    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "shipments.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ===================== VIEW SHIPMENT POPUP =====================

  void _showViewShipmentPopup(Shipment shipment) {
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
            width: MediaQuery.of(context).size.width * 0.6,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  _premiumBg,
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
                _buildPopupHeader(
                  title: 'Shipment Details',
                  subtitle: shipment.orderNumber,
                  icon: Icons.local_shipping,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Chips
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildPremiumStatusChip(
                              shipment.status,
                              getStatusColor(shipment.status),
                            ),
                            const SizedBox(width: 12),
                            _buildPremiumStatusChip(
                              shipment.pickupStatus,
                              getPickupStatusColor(shipment.pickupStatus),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Shipment Information
                        _buildPremiumSection(
                          title: "Shipment Information",
                          icon: Icons.info_outline,
                          children: [
                            _buildDetailRow("Order Number", shipment.orderNumber),
                            _buildDetailRow("ShipRocket Order ID", shipment.shiprocketOrderId),
                            _buildDetailRow("Shipment ID", shipment.shipmentId),
                            _buildDetailRow("AWB Code", shipment.awbCode.isEmpty ? "Not Assigned" : shipment.awbCode),
                            _buildDetailRow("Courier Company", shipment.courierCompany.isEmpty ? "Not Assigned" : shipment.courierCompany),
                            _buildDetailRow("Created At", _formatDate(shipment.createdAt)),
                            _buildDetailRow("Updated At", _formatDate(shipment.updatedAt)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Shipping Details
                        _buildPremiumSection(
                          title: "Shipping Details",
                          icon: Icons.attach_money,
                          children: [
                            _buildDetailRow("Shipping Charge", "₹${shipment.shippingCharge}"),
                            _buildDetailRow("Pickup Status", shipment.pickupStatus),
                            _buildDetailRow("Pickup Request ID", shipment.pickupRequestId ?? "N/A"),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Assign AWB Button - Direct assignment
                        if (shipment.awbCode.isEmpty || shipment.courierCompany.isEmpty)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: isAssigning ? null : () => _assignAWB(shipment),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: _premiumPrimary,
                                foregroundColor: Colors.white,
                              ),
                              icon: isAssigning
                                  ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                                  : const Icon(Icons.assignment_add),
                              label: isAssigning
                                  ? const Text('Assigning...')
                                  : const Text('Assign AWB'),
                            ),
                          ),
                        const SizedBox(height: 12),
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
  }

  // ===================== DIRECT AWB ASSIGNMENT =====================
  Future<void> _assignAWB(Shipment shipment) async {
    setState(() => isAssigning = true);

    try {
      // Get courier rates for the order
      String orderId = shipment.order.toString();
      if (shipment.order == 0) {
        orderId = shipment.orderNumber.replaceAll(RegExp(r'[^0-9]'), '');
      }

      if (orderId.isEmpty || orderId == '0') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid order ID. Cannot assign AWB.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => isAssigning = false);
        return;
      }

      // Fetch courier rates
      final ratesResponse = await _service.getCourierRates(orderId);

      if (ratesResponse.data.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No couriers available for this order.'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => isAssigning = false);
        return;
      }

      // Get the first available courier ID
      int firstCourierId = ratesResponse.data.first.courierId;

      // Assign AWB with first courier
      final assignResponse = await _service.assignAWB(
        shipmentId: shipment.shipmentId,
        courierId: firstCourierId,
      );

      if (mounted) {
        // Close the view popup
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              assignResponse.success
                  ? 'AWB assigned successfully!\nAWB: ${assignResponse.data?.response.data.awbCode ?? 'N/A'}'
                  : 'Failed to assign AWB: ${assignResponse.message}',
            ),
            backgroundColor: assignResponse.success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );

        setState(() => isAssigning = false);
        loadShipments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error assigning AWB: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => isAssigning = false);
      }
    }
  }

  // ===================== POPUP HELPERS =====================

  Widget _buildPopupHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
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
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  subtitle,
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
    );
  }

  Widget _buildPremiumStatusChip(String status, String colorHex) {
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
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
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
                  fontSize: 18,
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
            width: 110,
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

  // ===================== TABLE WIDGETS =====================

  Widget _tableHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 9,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _tableCell(String text, {VoidCallback? onTap, bool isBold = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 9,
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: color,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ===================== FILTER SECTION =====================

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
            // Mobile layout - properly constrained
            Row(
              children: [
                // Dropdown - reduced flex
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
                        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1), size: 20),
                        style: const TextStyle(color: Color(0xFF1E293B), fontSize: 10),
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          setState(() {
                            filterType = newValue!;
                            currentPage = 1;
                            applyFilters();
                          });
                        },
                        items: [
                          'Order Number',
                          'SR Order ID',
                          'Shipment ID',
                          'AWB Code',
                          'Courier Company',
                          'Status'
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Row(
                              children: [
                                Icon(
                                  value == 'Order Number' ? Icons.receipt_long
                                      : value == 'SR Order ID' ? Icons.local_shipping
                                      : value == 'Shipment ID' ? Icons.inventory
                                      : value == 'AWB Code' ? Icons.qr_code
                                      : value == 'Courier Company' ? Icons.business
                                      : Icons.info_outline,
                                  size: 12,
                                  color: const Color(0xFF6366F1),
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    value,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(fontSize: 10),
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
                const SizedBox(width: 6),
                // Search field - more flex
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
                        Icon(Icons.search, size: 14, color: const Color(0xFF6366F1)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: _getHintText(),
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
                                child: const Icon(Icons.clear, size: 14, color: Colors.grey),
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
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Export and Total row - compact
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildExportIcons(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Total: ${filteredShipments.length}",
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 10),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: resetFilters,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.refresh, size: 14, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            // Desktop layout - unchanged
            Row(
              children: [
                Container(
                  width: 150,
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
                      items: [
                        'Order Number',
                        'SR Order ID',
                        'Shipment ID',
                        'AWB Code',
                        'Courier Company',
                        'Status'
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Icon(
                                value == 'Order Number' ? Icons.receipt_long
                                    : value == 'SR Order ID' ? Icons.local_shipping
                                    : value == 'Shipment ID' ? Icons.inventory
                                    : value == 'AWB Code' ? Icons.qr_code
                                    : value == 'Courier Company' ? Icons.business
                                    : Icons.info_outline,
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
                        prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF6366F1)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
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
                      "Total: ${filteredShipments.length}",
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
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

  String _getHintText() {
    switch (filterType) {
      case 'Order Number':
        return "Search by order...";
      case 'SR Order ID':
        return "Search by SR order ID...";
      case 'Shipment ID':
        return "Search by shipment ID...";
      case 'AWB Code':
        return "Search by AWB code...";
      case 'Courier Company':
        return "Search by courier...";
      case 'Status':
        return "Search by status...";
      default:
        return "Search...";
    }
  }

  // ===================== PAGINATION =====================

  Widget _buildPagination() {
    if (filteredShipments.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final Widget showEntriesRow = Row(
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
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
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
                    "${currentPage * itemsPerPage > filteredShipments.length ? filteredShipments.length : currentPage * itemsPerPage} "
                    "of ${filteredShipments.length}",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          );

          final List<Widget> pageButtons = [
            _compactPageButton(icon: Icons.chevron_left, onTap: currentPage > 1 ? previousPage : null),
            if (totalPages <= 5)
              ...List.generate(totalPages, (index) => _compactPageNumber(index + 1))
            else if (currentPage <= 3) ...[
              ...List.generate(4, (index) => _compactPageNumber(index + 1)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              _compactPageNumber(totalPages),
            ] else if (currentPage >= totalPages - 2) ...[
              _compactPageNumber(1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              ...List.generate(4, (index) => _compactPageNumber(totalPages - 3 + index)),
            ] else ...[
              _compactPageNumber(1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              _compactPageNumber(currentPage - 1),
              _compactPageNumber(currentPage),
              _compactPageNumber(currentPage + 1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              _compactPageNumber(totalPages),
            ],
            _compactPageButton(icon: Icons.chevron_right, onTap: currentPage < totalPages ? nextPage : null),
          ];

          final Widget paginationRow = Row(
            mainAxisAlignment: MainAxisAlignment.end,
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
            return SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  showEntriesRow,
                  paginationRow,
                ],
              ),
            );
          }
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

  // ===================== MAIN BUILD =====================

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
          "ShipRocket Shipments",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadShipments,
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
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SingleChildScrollView(
                      controller: _headerHorizontalController,
                      scrollDirection: Axis.horizontal,
                      child: Table(
                        border: TableBorder(
                          horizontalInside: BorderSide(color: Colors.grey.shade300),
                          verticalInside: BorderSide(color: Colors.grey.shade300),
                          top: BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                        columnWidths: columnWidths,
                        children: [
                          TableRow(
                            children: headerLabels.map((label) => _tableHeader(label)).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: filteredShipments.isEmpty
                        ? const Center(child: Text("No shipments found"))
                        : SingleChildScrollView(
                      controller: _verticalController,
                      child: SingleChildScrollView(
                        controller: _rowsHorizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                          columnWidths: columnWidths,
                          children: List.generate(paginatedShipments.length, (rowIndex) {
                            final shipment = paginatedShipments[rowIndex];
                            final isEven = rowIndex % 2 == 0;
                            final srNo = filteredShipments.length - ((currentPage - 1) * itemsPerPage + rowIndex);
                            final hasAWB = shipment.awbCode.isNotEmpty && shipment.courierCompany.isNotEmpty;

                            return TableRow(
                              decoration: BoxDecoration(
                                color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                              ),
                              children: [
                                // SR No
                                GestureDetector(
                                  onTap: () => _showViewShipmentPopup(shipment),
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        srNo.toString(),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 9),
                                      ),
                                    ),
                                  ),
                                ),
                                // Order Number
                                GestureDetector(
                                  onTap: () => _showViewShipmentPopup(shipment),
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        shipment.orderNumber,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 9),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                // ShipRocket Order ID
                                GestureDetector(
                                  onTap: () => _showViewShipmentPopup(shipment),
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        shipment.shiprocketOrderId,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 9),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                // Shipment ID
                                GestureDetector(
                                  onTap: () => _showViewShipmentPopup(shipment),
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        shipment.shipmentId,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 9),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                // AWB Code
                                GestureDetector(
                                  onTap: () => _showViewShipmentPopup(shipment),
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        shipment.awbCode.isEmpty ? 'N/A' : shipment.awbCode,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: shipment.awbCode.isEmpty ? Colors.grey : Colors.black,
                                          fontWeight: shipment.awbCode.isNotEmpty ? FontWeight.bold : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                // Courier Company
                                GestureDetector(
                                  onTap: () => _showViewShipmentPopup(shipment),
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        shipment.courierCompany.isEmpty ? 'N/A' : shipment.courierCompany,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: shipment.courierCompany.isEmpty ? Colors.grey : Colors.black,
                                        ),
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                // Status
                                GestureDetector(
                                  onTap: () => _showViewShipmentPopup(shipment),
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.all(2),
                                    alignment: Alignment.center,
                                    child: _buildTableStatusChip(
                                      shipment.status,
                                      getStatusColor(shipment.status),
                                    ),
                                  ),
                                ),
                                // Pickup Status
                                GestureDetector(
                                  onTap: () => _showViewShipmentPopup(shipment),
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.all(2),
                                    alignment: Alignment.center,
                                    child: _buildTableStatusChip(
                                      shipment.pickupStatus,
                                      getPickupStatusColor(shipment.pickupStatus),
                                    ),
                                  ),
                                ),
                                // Created At
                                GestureDetector(
                                  onTap: () => _showViewShipmentPopup(shipment),
                                  child: Container(
                                    height: 38,
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                    alignment: Alignment.center,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _formatDate(shipment.createdAt).substring(0, 10),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 9),
                                      ),
                                    ),
                                  ),
                                ),
                                // Actions
                                Container(
                                  height: 38,
                                  padding: const EdgeInsets.all(2),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // View Button
                                      Tooltip(
                                        message: 'View Details',
                                        child: InkWell(
                                          onTap: () => _showViewShipmentPopup(shipment),
                                          borderRadius: BorderRadius.circular(6),
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6366F1).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: const Icon(
                                              Icons.visibility,
                                              size: 14,
                                              color: Color(0xFF6366F1),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      // Assign Button (only if no AWB assigned)
                                      if (!hasAWB)
                                        Tooltip(
                                          message: 'Assign AWB',
                                          child: InkWell(
                                            onTap: () => _showViewShipmentPopup(shipment),
                                            borderRadius: BorderRadius.circular(6),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                Icons.assignment_add,
                                                size: 14,
                                                color: Colors.green,
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
*/