// lib/screens/qnx_admin/shiprocket_screen.dart

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'dart:html' as html;
import '../../api/shiprocket_service.dart';
import '../../models/shiprocket/shiprocket_model.dart';
import '../../api/api_service.dart';
import '../../models/qnx_admin/packing_video_model.dart';

class ShiprocketScreen extends StatefulWidget {
  const ShiprocketScreen({super.key});

  @override
  State<ShiprocketScreen> createState() => _ShiprocketScreenState();
}

class _ShiprocketScreenState extends State<ShiprocketScreen> {
  final ShiprocketService _service = ShiprocketService();
  final PackingVideoService _packingVideoService = PackingVideoService();

  List<ShipOrder> allOrders = [];
  List<ShipOrder> filteredOrders = [];
  List<ShipOrder> paginatedOrders = [];

  bool isLoading = true;

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

  // Premium color palette
  static const Color _premiumPrimary = Color(0xFF5A67F2);
  static const Color _premiumSecondary = Color(0xFF7B4DDB);
  static const Color _premiumAccent = Color(0xFFC84DB5);

  // Column widths
  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(50),   // SR No
    1: FixedColumnWidth(110),  // Order Number
    2: FixedColumnWidth(170),  // Company
    3: FixedColumnWidth(190),  // Product
    4: FixedColumnWidth(80),   // Quantity
    5: FixedColumnWidth(80),   // Total Amount
    6: FixedColumnWidth(90),   // Payment Method
    7: FixedColumnWidth(90),   // Status
    8: FixedColumnWidth(90),   // Created
    9: FixedColumnWidth(130),  // Actions
  };

  final List<String> headerLabels = [
    "SR No", "Order Number", "Company", "Product", "Qty",
    "Total", "Payment", "Status", "Created", "Actions"
  ];

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();
    loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerHorizontalController.dispose();
    _rowsHorizontalController.dispose();
    _verticalController.dispose();
    _service.dispose();
    _packingVideoService.dispose();
    super.dispose();
  }

  Future<void> loadOrders() async {
    try {
      final response = await _service.getShipOrders();
      if (mounted) {
        setState(() {
          allOrders = response.data;
          allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load orders: $e'),
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
      final query = searchQuery.toLowerCase();
      filteredOrders = allOrders.where((order) {
        switch (filterType) {
          case 'Order Number':
            return order.orderNumber.toLowerCase().contains(query);
          case 'Company':
            return order.company.name.toLowerCase().contains(query);
          case 'Product':
            return order.product.name.toLowerCase().contains(query);
          case 'Status':
            return order.status.toLowerCase().contains(query);
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
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    if (end > filteredOrders.length) end = filteredOrders.length;
    paginatedOrders = filteredOrders.sublist(start, end);
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

  void changeItemsPerPage(int? value) {
    if (value != null) {
      setState(() {
        itemsPerPage = value;
        currentPage = 1;
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
      case 'PENDING':
        return '#F59E0B';
      case 'CONFIRMED':
        return '#3B82F6';
      case 'SHIPPED':
        return '#8B5CF6';
      case 'DELIVERED':
        return '#10B981';
      case 'CANCELLED':
        return '#EF4444';
      default:
        return '#6B7280';
    }
  }

  // ===================== EXPORT FUNCTIONS =====================

  void _exportExcel() {
    if (filteredOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final file = excel.Excel.createExcel();
    final sheet = file['ShipRocket Orders'];

    sheet.appendRow([
      "SR No", "Order Number", "Company", "Product", "Quantity",
      "Total Amount", "Payment Method", "Status", "Created"
    ]);

    int srNo = filteredOrders.length;
    for (var order in filteredOrders) {
      sheet.appendRow([
        srNo--,
        order.orderNumber,
        order.company.name,
        order.product.name,
        order.quantity,
        order.totalAmount,
        order.paymentMethod,
        order.status,
        order.createdAt.substring(0, 10),
      ]);
    }

    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "shiprocket_orders.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> _exportPDF() async {
    if (filteredOrders.isEmpty) {
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
        build: (context) => pw.Table.fromTextArray(
          headers: ["SR No", "Order Number", "Company", "Product", "Total", "Status"],
          data: List.generate(filteredOrders.length, (index) {
            final order = filteredOrders[index];
            final srNo = filteredOrders.length - index;
            return [
              srNo.toString(),
              order.orderNumber,
              order.company.name,
              order.product.name,
              "₹${order.totalAmount.toStringAsFixed(2)}",
              order.status,
            ];
          }),
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void _exportDOC() {
    if (filteredOrders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to export'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final content = StringBuffer();
    content.writeln("ShipRocket Orders List\n");
    content.writeln("=" * 50);

    int srNo = filteredOrders.length;
    for (var order in filteredOrders) {
      content.writeln("SR No: ${srNo--}");
      content.writeln("Order Number: ${order.orderNumber}");
      content.writeln("Company: ${order.company.name}");
      content.writeln("Product: ${order.product.name}");
      content.writeln("Quantity: ${order.quantity}");
      content.writeln("Total Amount: ₹${order.totalAmount.toStringAsFixed(2)}");
      content.writeln("Payment Method: ${order.paymentMethod}");
      content.writeln("Status: ${order.status}");
      content.writeln("Created: ${order.createdAt.substring(0, 10)}");
      content.writeln("-" * 30);
    }

    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "shiprocket_orders.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ===================== VIEW ORDER POPUP =====================

  void _showViewOrderPopup(ShipOrder order) {
    // Use a flag to prevent multiple loads
    bool _isVideoLoaded = false;
    bool _isLoadingVideo = false;
    PackingVideoResponse? _videoResponse;
    String? _videoError;
    bool _videoNotFound = false;

    Future<void> loadPackingVideo(Function setState) async {
      // Prevent multiple calls
      if (_isLoadingVideo || _isVideoLoaded) return;

      setState(() {
        _isLoadingVideo = true;
        _videoError = null;
        _videoNotFound = false;
      });

      try {
        final response = await _packingVideoService.retrievePackingVideo(order.orderId);
        setState(() {
          _isLoadingVideo = false;
          _videoResponse = response;
          if (response.success && response.data != null && response.data!.s3Video.isNotEmpty) {
            _isVideoLoaded = true;
            _videoNotFound = false;
          } else {
            // Video not found - set flag to show "No video" message
            _videoNotFound = true;
            _videoError = null; // Clear any error message
          }
        });
      } catch (e) {
        setState(() {
          _isLoadingVideo = false;
          // Check if it's a 404 error or "not found" message
          final errorMsg = e.toString().toLowerCase();
          if (errorMsg.contains('404') || errorMsg.contains('not found')) {
            _videoNotFound = true;
            _videoError = null; // No error message, just show "No video"
          } else {
            _videoError = e.toString();
            _videoNotFound = false;
          }
        });
      }
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Load video when popup opens - only once
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_isVideoLoaded && !_isLoadingVideo && !_videoNotFound) {
                loadPackingVideo(setState);
              }
            });

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              backgroundColor: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFFF7F8FF),
                      Colors.white,
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
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.receipt_long,
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
                                  'Order Details',
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Color(
                                        int.parse('0xFF${getStatusColor(order.status).substring(1)}')
                                    ).withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: Color(
                                              int.parse('0xFF${getStatusColor(order.status).substring(1)}')
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        order.status,
                                        style: TextStyle(
                                          color: Color(
                                              int.parse('0xFF${getStatusColor(order.status).substring(1)}')
                                          ),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildDetailSection(
                              title: "Order Information",
                              icon: Icons.info_outline,
                              children: [
                                _buildDetailRow("Order Number", order.orderNumber),
                                _buildDetailRow("Created At", order.createdAt.substring(0, 16).replaceAll('T', ' ')),
                                _buildDetailRow("Payment Method", order.paymentMethod),
                                _buildDetailRow("Payment Status", order.paymentStatus ? "Paid" : "Unpaid"),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildDetailSection(
                              title: "Company & Product",
                              icon: Icons.business,
                              children: [
                                _buildDetailRow("Company", order.company.name),
                                _buildDetailRow("Product", order.product.name),
                                _buildDetailRow("Quantity", order.quantity.toString()),
                                _buildDetailRow("Pincode", order.address.pincode),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildDetailSection(
                              title: "Pricing Details",
                              icon: Icons.attach_money,
                              children: [
                                _buildDetailRow("Price", "₹${order.price.toStringAsFixed(2)}"),
                                _buildDetailRow("Subtotal", "₹${order.subtotal.toStringAsFixed(2)}"),
                                _buildDetailRow("Shipping Charge", "₹${order.shippingCharge.toStringAsFixed(2)}"),
                                _buildDetailRow("Tax", "₹${order.tax.toStringAsFixed(2)}"),
                                _buildDetailRow("Discount", "₹${order.discount.toStringAsFixed(2)}"),
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF5A67F2),
                                        Color(0xFF7B4DDB),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Total Amount",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        "₹${order.totalAmount.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // ========== PACKING VIDEO SECTION ==========
                            _buildDetailSection(
                              title: "Packing Video",
                              icon: Icons.video_library,
                              children: [
                                if (_isLoadingVideo)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                else if (_videoNotFound || (_videoResponse != null && !_videoResponse!.success))
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        'No packing video available for this order',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  )
                                else if (_videoError != null)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.red.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red.shade600),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              _videoError!,
                                              style: TextStyle(
                                                color: Colors.red.shade800,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else if (_videoResponse != null && _videoResponse!.success && _videoResponse!.data != null && _videoResponse!.data!.s3Video.isNotEmpty)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Video Player
                                          Container(
                                            height: 200,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.black,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: _buildVideoPlayer(_videoResponse!.data!.s3Video),
                                          ),
                                          const SizedBox(height: 12),
                                          // Download Button
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton.icon(
                                                  onPressed: () {
                                                    if (_videoResponse!.data!.s3Video.isNotEmpty) {
                                                      // Download video - Open in new tab
                                                      html.window.open(_videoResponse!.data!.s3Video, '_blank');
                                                    }
                                                  },
                                                  icon: const Icon(Icons.download, size: 18),
                                                  label: const Text('Download Video'),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: _premiumPrimary,
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                onPressed: () {
                                                  // Refresh video
                                                  setState(() {
                                                    _isVideoLoaded = false;
                                                    _videoResponse = null;
                                                    _videoNotFound = false;
                                                    _videoError = null;
                                                  });
                                                  loadPackingVideo(setState);
                                                },
                                                icon: const Icon(Icons.refresh),
                                                color: _premiumPrimary,
                                                tooltip: 'Refresh',
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    else
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.grey.shade200),
                                        ),
                                        child: const Center(
                                          child: Text(
                                            'No packing video available for this order',
                                            style: TextStyle(color: Colors.grey),
                                          ),
                                        ),
                                      ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (order.notes != null && order.notes!.isNotEmpty)
                              _buildDetailSection(
                                title: "Notes",
                                icon: Icons.note,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Text(
                                      order.notes!,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: _premiumPrimary,
                                  foregroundColor: Colors.white,
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

  // ===================== VIDEO PLAYER WIDGET =====================

  Widget _buildVideoPlayer(String videoUrl) {
    if (videoUrl.isEmpty) {
      return const Center(
        child: Text(
          'No video available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // Create a video element directly in the DOM
    // ignore: undefined_prefixed_name
    final videoElement = html.VideoElement()
      ..src = videoUrl
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = '#000'
      ..style.objectFit = 'contain'
      ..controls = true
      ..autoplay = false
      ..setAttribute('playsinline', 'true');

    // Append to body and get the outer HTML
    // ignore: undefined_prefixed_name
    final container = html.DivElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.position = 'relative'
      ..append(videoElement);

    // Convert to string and use HtmlElementView
    // Since we can't use HtmlElementView directly, use a placeholder with a button
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_filled,
              color: Colors.white70,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              'Click to play video',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                html.window.open(videoUrl, '_blank');
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('Open in New Tab'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _premiumPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== CREATE ORDER POPUP =====================

  void _showCreateOrderPopup(ShipOrder order) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isCreating = false;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.5,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
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
                              Icons.local_shipping,
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
                                  'Create ShipRocket Order',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Order: ${order.orderNumber}',
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
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  _buildDetailRow('Order Number', order.orderNumber),
                                  _buildDetailRow('Company', order.company.name),
                                  _buildDetailRow('Product', order.product.name),
                                  _buildDetailRow('Quantity', order.quantity.toString()),
                                  _buildDetailRow('Total Amount', '₹${order.totalAmount.toStringAsFixed(2)}'),
                                  _buildDetailRow('Payment Method', order.paymentMethod),
                                  _buildDetailRow('Status', order.status),
                                  _buildDetailRow('Pincode', order.address.pincode),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.amber.shade700),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'This will create a ShipRocket order for this order. Please confirm the details before proceeding.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.amber.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      side: BorderSide(color: Colors.grey.shade400),
                                    ),
                                    child: const Text('Cancel'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: isCreating
                                        ? null
                                        : () async {
                                      setState(() => isCreating = true);
                                      try {
                                        final response = await _service.createShiprocketOrder(order.orderId);
                                        if (mounted) {
                                          Navigator.pop(context);

                                          // ✅ API message extract करा
                                          final apiMsg = response.message.trim();
                                          final lowerMsg = apiMsg.toLowerCase();

                                          // Warning check - "wrong", "error", "invalid", "please" असे शब्द असतील तर warning
                                          final isWarning = apiMsg.isNotEmpty &&
                                              (lowerMsg.contains('wrong') ||
                                                  lowerMsg.contains('error') ||
                                                  lowerMsg.contains('invalid') ||
                                                  lowerMsg.contains('please') ||
                                                  lowerMsg.contains('failed'));

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        response.success
                                                            ? (isWarning ? Icons.warning_amber_rounded : Icons.check_circle)
                                                            : Icons.error,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        response.success
                                                            ? (isWarning ? 'Order Created (Warning)' : 'Order Created Successfully')
                                                            : 'Order Creation Failed',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 14,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Order ID: ${response.shiprocketResponse?.orderId ?? 'N/A'}',
                                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                                  ),
                                                  // ✅ API message print करा (जर असेल तर)
                                                  if (apiMsg.isNotEmpty) ...[
                                                    const SizedBox(height: 6),
                                                    Container(
                                                      padding: const EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white.withOpacity(0.2),
                                                        borderRadius: BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        '⚠️ $apiMsg',
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              backgroundColor: response.success
                                                  ? (isWarning ? Colors.orange.shade700 : Colors.green)
                                                  : Colors.red,
                                              duration: Duration(seconds: isWarning ? 8 : 3),
                                            ),
                                          );
                                          loadOrders();
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      backgroundColor: _premiumPrimary,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: isCreating
                                        ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                        : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.send, size: 18),
                                        SizedBox(width: 8),
                                        Text('Create Order'),
                                      ],
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailSection({
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
              padding: const EdgeInsets.all(6),
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
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
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
            width: 100,
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
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
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

  Widget _buildStatusChip(String status) {
    final colorHex = getStatusColor(status);
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Color(int.parse('0xFF${colorHex.substring(1)}')).withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status,
          style: TextStyle(
            color: Color(int.parse('0xFF${colorHex.substring(1)}')),
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ===================== EXPORT ICONS =====================

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
              child: Image.asset("assets/icon/xls.png", height: 20, width: 20),
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
              child: Image.asset("assets/icon/pdf.png", height: 20, width: 20),
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
              child: Image.asset("assets/icon/doc.png", height: 20, width: 20),
            ),
          ),
        ),
      ],
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
                Container(
                  constraints: const BoxConstraints(
                    maxWidth: 100,
                    minWidth: 80,
                  ),
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: filterType,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1), size: 20),
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        setState(() {
                          filterType = newValue!;
                          currentPage = 1;
                          applyFilters();
                        });
                      },
                      items: ['Order Number', 'Company', 'Product', 'Status']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                value == 'Order Number' ? Icons.receipt_long
                                    : value == 'Company' ? Icons.business
                                    : value == 'Product' ? Icons.inventory
                                    : Icons.info_outline,
                                size: 12,
                                color: const Color(0xFF6366F1),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  value,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
                        hintText: filterType == 'Order Number' ? "Search by order..."
                            : filterType == 'Company' ? "Search by company..."
                            : filterType == 'Product' ? "Search by product..."
                            : "Search by status...",
                        hintStyle: const TextStyle(fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF6366F1)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                      "Total: ${filteredOrders.length}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: resetFilters,
                      icon: const Icon(Icons.refresh, size: 18),
                      color: Colors.red,
                      tooltip: "Reset",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    ),
                  ],
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Container(
                  constraints: const BoxConstraints(
                    maxWidth: 120,
                    minWidth: 80,
                  ),
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: filterType,
                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1), size: 20),
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        setState(() {
                          filterType = newValue!;
                          currentPage = 1;
                          applyFilters();
                        });
                      },
                      items: ['Order Number', 'Company', 'Product', 'Status']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                value == 'Order Number' ? Icons.receipt_long
                                    : value == 'Company' ? Icons.business
                                    : value == 'Product' ? Icons.inventory
                                    : Icons.info_outline,
                                size: 12,
                                color: const Color(0xFF6366F1),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  value,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
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
                        hintText: filterType == 'Order Number' ? "Search by order..."
                            : filterType == 'Company' ? "Search by company..."
                            : filterType == 'Product' ? "Search by product..."
                            : "Search by status...",
                        hintStyle: const TextStyle(fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF6366F1)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                      "Total: ${filteredOrders.length}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: resetFilters,
                      icon: const Icon(Icons.refresh, size: 18),
                      color: Colors.red,
                      tooltip: "Reset",
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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

  // ===================== PAGINATION =====================

  Widget _buildPagination() {
    if (filteredOrders.isEmpty) return const SizedBox.shrink();

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
                    "${currentPage * itemsPerPage > filteredOrders.length ? filteredOrders.length : currentPage * itemsPerPage} "
                    "of ${filteredOrders.length}",
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
          "ShipRocket Orders",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
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
                    child: filteredOrders.isEmpty
                        ? const Center(child: Text("No orders found"))
                        : SingleChildScrollView(
                      controller: _verticalController,
                      child: SingleChildScrollView(
                        controller: _rowsHorizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                          columnWidths: columnWidths,
                          children: List.generate(paginatedOrders.length, (rowIndex) {
                            final order = paginatedOrders[rowIndex];
                            final isEven = rowIndex % 2 == 0;
                            final srNo = filteredOrders.length - ((currentPage - 1) * itemsPerPage + rowIndex);

                            return TableRow(
                              decoration: BoxDecoration(
                                color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                              ),
                              children: [
                                // SR No - Clickable to view details
                                _tableCell(
                                  srNo.toString(),
                                  onTap: () => _showViewOrderPopup(order),
                                ),
                                // Order Number - Clickable to view details
                                _tableCell(
                                  order.orderNumber,
                                  onTap: () => _showViewOrderPopup(order),
                                ),
                                // Company - Clickable to view details
                                _tableCell(
                                  order.company.name,
                                  onTap: () => _showViewOrderPopup(order),
                                ),
                                // Product - Clickable to view details
                                _tableCell(
                                  order.product.name,
                                  onTap: () => _showViewOrderPopup(order),
                                ),
                                // Quantity - Clickable to view details
                                _tableCell(
                                  order.quantity.toString(),
                                  onTap: () => _showViewOrderPopup(order),
                                ),
                                // Total Amount - Clickable to view details
                                _tableCell(
                                  "₹${order.totalAmount.toStringAsFixed(2)}",
                                  onTap: () => _showViewOrderPopup(order),
                                  isBold: true,
                                ),
                                // Payment Method - Clickable to view details
                                _tableCell(
                                  order.paymentMethod,
                                  onTap: () => _showViewOrderPopup(order),
                                ),
                                // Status
                                GestureDetector(
                                  onTap: () => _showViewOrderPopup(order),
                                  child: Container(
                                    height: 42,
                                    padding: const EdgeInsets.all(4),
                                    alignment: Alignment.center,
                                    child: _buildStatusChip(order.status),
                                  ),
                                ),
                                // Created Date - Clickable to view details
                                _tableCell(
                                  order.createdAt.substring(0, 10),
                                  onTap: () => _showViewOrderPopup(order),
                                ),
                                // Actions - Create ShipRocket Order
                                Container(
                                  height: 42,
                                  padding: const EdgeInsets.all(4),
                                  alignment: Alignment.center,
                                  child: Tooltip(
                                    message: 'Create ShipRocket Order',
                                    child: InkWell(
                                      onTap: () => _showCreateOrderPopup(order),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF5A67F2),
                                              Color(0xFF7B4DDB),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.local_shipping,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Create',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
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
            const SizedBox(height: 8),
            _buildPagination(),
          ],
        ),
      ),
    );
  }
}