import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'dart:html' as html;
import '../../models/qnx_admin/product_model.dart';
import '../../api/api_service.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../models/qnx_admin/company_model.dart';

class ApprovedProductListScreen extends StatefulWidget {
  const ApprovedProductListScreen({super.key});

  @override
  State<ApprovedProductListScreen> createState() =>
      _ApprovedProductListScreenState();
}

class _ApprovedProductListScreenState extends State<ApprovedProductListScreen> {
  final ProductApprovedService service = ProductApprovedService();

  List<ApprovedProductModel> allProducts = [];
  List<ApprovedProductModel> filteredProducts = [];
  List<ApprovedProductModel> paginatedProducts = [];

  bool isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String filterType = 'Name';

  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  final Map<String, VideoPlayerController> _videoControllers = {};
  final Map<String, ChewieController> _chewieControllers = {};

  // Column widths for table
  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(50),   // SR No
    1: FixedColumnWidth(55),   // Img
    2: FixedColumnWidth(140),  // Name
    3: FixedColumnWidth(120),  // Company Name
    4: FixedColumnWidth(90),   // Category
    5: FixedColumnWidth(90),   // Subcategory
    6: FixedColumnWidth(90),   // Brand
    7: FixedColumnWidth(45),   // Unit
    8: FixedColumnWidth(60),   // Price
    9: FixedColumnWidth(70),   // Disc Type
    10: FixedColumnWidth(60),  // Disc Val
    11: FixedColumnWidth(60),  // Final
    12: FixedColumnWidth(45),  // Stock
    13: FixedColumnWidth(70),  // HSN Code
    14: FixedColumnWidth(65),  // Variants
    15: FixedColumnWidth(90),  // Code
    16: FixedColumnWidth(80),  // Franchise Available
    17: FixedColumnWidth(60),  // Status
    18: FixedColumnWidth(100), // Created
    19: FixedColumnWidth(70),  // Actions
  };

  // Header labels
  final List<String> headerLabels = [
    "SR No", "Img", "Name", "Company Name", "Category", "Subcategory",
    "Brand", "Unit", "Price", "Disc Type", "Disc Val", "Final",
    "Stock", "HSN Code", "Variants", "Code", "Franchise", "Status", "Created", "Actions"
  ];

  // Premium color palette
  static const Color _premiumPrimary   = Color(0xFF5A67F2); // Blue
  static const Color _premiumSecondary = Color(0xFF7B4DDB); // Purple
  static const Color _premiumAccent    = Color(0xFFC84DB5); // Pink
  static const Color _premiumGold      = Color(0xFF5A67F2); // Blue
  static const Color _premiumLight     = Color(0xFF7B4DDB); // Purple
  static const Color _premiumBg        = Color(0xFFF7F8FF); // Light Background
  static const Color _premiumCard      = Colors.white;

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();
    loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerHorizontalController.dispose();
    _rowsHorizontalController.dispose();
    _verticalController.dispose();
    for (var controller in _videoControllers.values) {
      controller.dispose();
    }
    for (var controller in _chewieControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String _extractVideoUrl(dynamic videoData) {
    if (videoData == null) return '';
    try {
      if (videoData is String) {
        if (videoData.contains('{') && videoData.contains('video_s3_key')) {
          final match = RegExp(r'https?://[^\s}\]]+').firstMatch(videoData);
          if (match != null) return match.group(0)!;
        }
        return videoData;
      }
      if (videoData is Map) {
        return videoData['video_s3_key']?.toString() ??
            videoData['url']?.toString() ?? '';
      }
      return videoData.toString();
    } catch (e) {
      print("Error extracting video URL: $e");
      return '';
    }
  }

  Future<void> _initializeVideoPlayer(String url, String videoKey) async {
    if (url.isEmpty || !url.startsWith('http')) return;
    try {
      final Uri uri = Uri.parse(url);
      final controller = VideoPlayerController.networkUrl(uri);
      await controller.initialize();
      if (mounted) {
        setState(() {
          _videoControllers[videoKey] = controller;
          _chewieControllers[videoKey] = ChewieController(
            videoPlayerController: controller,
            autoPlay: false,
            looping: false,
            allowFullScreen: true,
            allowMuting: true,
          );
        });
      }
    } catch (e) {
      print("Error initializing video player: $e");
    }
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 300,
                    width: 300,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showCompanyDetailsPopup(int companyId, String companyName) async {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<CompanySingleRetrieveResponse>(
          future: CompanyAllService().getCompanyDetails(companyId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text('Failed to load company details: ${snapshot.error}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              );
            }
            final company = snapshot.data!.data;
            final companyProducts = allProducts.where((p) => p.company == companyId).toList();
            final screenWidth = MediaQuery.of(context).size.width;
            final dialogWidth = screenWidth < 600 ? screenWidth * 0.9 : (screenWidth < 900 ? 600.0 : 700.0);

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.transparent,
              child: Container(
                width: dialogWidth,
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF4F6EF7),
                            Color(0xFF6C5CE7),
                            Color(0xFFC445B2),
                          ],
                          stops: [0.0, 0.55, 1.0],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(24),
                          topRight: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.business,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  company.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.email_outlined,
                                      size: 15,
                                      color: Colors.white70,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        company.email,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(.12),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF5A67F2).withOpacity(.10),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.business_center,
                                    color: Color(0xFF5A67F2),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  "Company Information",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final crossAxisCount = constraints.maxWidth < 500 ? 1 : 2;
                                final fields = [
                                  {'label': 'Owner', 'value': company.ownerName},
                                  {'label': 'Phone', 'value': company.phoneNumber},
                                  {'label': 'Email', 'value': company.email},
                                  {'label': 'GST', 'value': company.gstNumber},
                                  {'label': 'Address', 'value': company.address},
                                  {'label': 'State', 'value': company.state},
                                  {'label': 'District', 'value': company.district},
                                  {'label': 'Taluka', 'value': company.taluka},
                                  {'label': 'Village', 'value': company.village},
                                  {'label': 'Pincode', 'value': company.pincode},
                                  {'label': 'Status', 'value': company.isActive ? 'Active' : 'Inactive'},
                                ];
                                return GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: 4.0,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: fields.length,
                                  itemBuilder: (context, index) {
                                    final field = fields[index];
                                    return Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: const Color(0xFFE8EAF6),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            field['label']!,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade600,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            (field['value'] ?? "").toString().isEmpty
                                                ? "-"
                                                : field['value'].toString(),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF2D3748),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const Text('Products under this company',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (companyProducts.isEmpty)
                              const Center(
                                  child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Text('No approved products found for this company.')))
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: companyProducts.length,
                                itemBuilder: (context, index) {
                                  final product = companyProducts[index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(color: Colors.grey.shade200),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(.05),
                                          blurRadius: 12,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(
                                              product.thumbnail,
                                              width: 65,
                                              height: 65,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                width: 65,
                                                height: 65,
                                                color: Colors.grey.shade200,
                                                child: const Icon(Icons.image),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.name,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  "₹${product.price}",
                                                  style: const TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF5A67F2),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: product.status == "approved"
                                                        ? Colors.green.shade100
                                                        : Colors.orange.shade100,
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Text(
                                                    product.status.toUpperCase(),
                                                    style: TextStyle(
                                                      color: product.status == "approved"
                                                          ? Colors.green.shade800
                                                          : Colors.orange.shade800,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
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

  Future<void> loadProducts() async {
    try {
      final response = await service.getApprovedProducts();
      print("API Status: ${response.status}");
      print("API Message: ${response.message}");
      print("Data length: ${response.data?.length}");
      if (response.data != null && response.data!.isNotEmpty) {
        print("First product: ${response.data![0].name}");
      }
      if (mounted) {
        setState(() {
          allProducts = response.data ?? [];
          allProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          applyFilters();
          isLoading = false;
        });
      }
    } catch (e, stack) {
      print("Error loading products: $e");
      print(stack);
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load approved products")),
        );
      }
    }
  }

  void applyFilters() {
    if (searchQuery.isEmpty) {
      filteredProducts = List.from(allProducts);
    } else {
      final query = searchQuery.toLowerCase();
      filteredProducts = allProducts.where((p) {
        switch (filterType) {
          case 'Name':
            return p.name.toLowerCase().contains(query);
          case 'Category':
            return p.categoryName.toLowerCase().contains(query);
          case 'Brand':
            return p.brandName.toLowerCase().contains(query);
          case 'Code':
            return p.productCode.toLowerCase().contains(query);
          case 'Company':
            return p.companyName.toLowerCase().contains(query);
          default:
            return false;
        }
      }).toList();
    }
    applyPagination();
  }

  void applyPagination() {
    if (filteredProducts.isEmpty) {
      paginatedProducts = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }
    totalPages = (filteredProducts.length / itemsPerPage).ceil();
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    if (end > filteredProducts.length) end = filteredProducts.length;
    paginatedProducts = filteredProducts.sublist(start, end);
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
      filterType = 'Name';
      _searchController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  void exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['Approved Products'];
    sheet.appendRow([
      "SR No", "Name", "Company", "Category", "Subcategory", "Brand", "Unit",
      "Price", "Discount Type", "Discount Value", "Final Price", "Stock",
      "HSN Code", "Variants", "Product Code", "Franchise Available", "Status", "Created At"
    ]);

    int srNo = filteredProducts.length;
    for (var p in filteredProducts) {
      sheet.appendRow([
        srNo--,
        p.name, p.companyName, p.categoryName, p.subcategoryName,
        p.brandName, p.unitName, p.price, p.discountType ?? "-",
        p.discountValue, p.finalPrice, p.stockQuantity, p.hsnCode,
        p.variants.length, p.productCode,
        (p.franchiseAvailable == true) ? "YES" : "NO",
        p.status, p.createdAt
      ]);
    }
    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "approved_products.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> exportPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: ["SR No", "Name", "Company", "Category", "Brand", "Price", "Final Price", "Stock", "Franchise", "Status"],
            data: List.generate(filteredProducts.length, (index) {
              final p = filteredProducts[index];
              final srNo = filteredProducts.length - index;
              return [
                srNo.toString(), p.name, p.companyName, p.categoryName,
                p.brandName, p.price, p.finalPrice, p.stockQuantity.toString(),
                (p.franchiseAvailable == true) ? "YES" : "NO",
                p.status
              ];
            }),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void exportDOC() {
    final content = StringBuffer();
    content.writeln("Approved Products List\n");
    content.writeln("=" * 50);

    int srNo = filteredProducts.length;
    for (var p in filteredProducts) {
      content.writeln("SR No: ${srNo--}");
      content.writeln("Name: ${p.name}");
      content.writeln("Company: ${p.companyName}");
      content.writeln("Category: ${p.categoryName}");
      content.writeln("Brand: ${p.brandName}");
      content.writeln("Price: ₹${p.price}");
      content.writeln("Final Price: ₹${p.finalPrice}");
      content.writeln("Stock: ${p.stockQuantity}");
      content.writeln("Franchise Available: ${(p.franchiseAvailable == true) ? "YES" : "NO"}");
      content.writeln("Status: ${p.status}");
      content.writeln("-" * 30);
    }
    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "approved_products.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // Premium Popup Design - FIXED OVERFLOWS
  void showProductPopup(ApprovedProductModel p) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Colors.transparent,
          child: LayoutBuilder(
            builder: (context, constraints) {
              double dialogWidth = constraints.maxWidth * 0.9;
              if (constraints.maxWidth > 600) dialogWidth = 640;
              if (constraints.maxWidth > 1000) dialogWidth = 760;

              return Container(
                width: dialogWidth,
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
                    // Premium Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
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
                          // Product Thumbnail
                          GestureDetector(
                            onTap: () => _showFullScreenImage(p.thumbnail),
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  p.thumbnail,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: _premiumGold.withOpacity(0.2),
                                    child: Icon(Icons.inventory_2, color: _premiumGold, size: 28),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Text Section - Expanded to prevent overflow
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        p.productCode,
                                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Close button
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 20),
                              onPressed: () => Navigator.pop(context),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Scrollable Body
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status Row - Used Wrap to prevent overflow
                            Wrap(
                              spacing: 12,
                              runSpacing: 8,
                              children: [
                                _premiumStatusChip(
                                  p.status,
                                  p.status == 'approved' ? Colors.green : Colors.orange,
                                ),
                                _premiumStatusChip(
                                  p.isActive ? "Active" : "Inactive",
                                  p.isActive ? Colors.blue : Colors.grey,
                                ),
                                if (p.isFeatured)
                                  _premiumStatusChip(
                                    "Featured",
                                    _premiumGold,
                                    icon: Icons.star,
                                  ),
                                _premiumStatusChip(
                                  (p.franchiseAvailable == true) ? "Franchise: YES" : "Franchise: NO",
                                  (p.franchiseAvailable == true) ? Colors.purple : Colors.grey,
                                  icon: (p.franchiseAvailable == true) ? Icons.storefront : Icons.storefront_outlined,
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Info Grid
                            _buildPremiumSection(
                              title: "Product Information",
                              icon: Icons.info_outline,
                              children: [
                                _infoRow("SKU", p.sku),
                                _infoRow("HSN Code", p.hsnCode.isEmpty ? "N/A" : p.hsnCode),
                                _infoRow("Franchise Available", (p.franchiseAvailable == true) ? "Yes" : "No"),
                                _infoRow("Created", p.createdAt.substring(0, 10)),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Categories & Company
                            _buildPremiumSection(
                              title: "Categories & Brand",
                              icon: Icons.category,
                              children: [
                                _infoRow("Category", p.categoryName),
                                _infoRow("Subcategory", p.subcategoryName),
                                _infoRow("Brand", p.brandName),
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  child: GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(p.company, p.companyName),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF5A67F2),
                                            Color(0xFF7B4DDB),
                                            Color(0xFFC84DB5),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _premiumGold.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.business, color: Colors.white, size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              p.companyName,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          const Icon(Icons.open_in_new, color: Colors.white70, size: 14),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Pricing & Stock
                            _buildPremiumSection(
                              title: "Pricing & Stock",
                              icon: Icons.attach_money,
                              children: [
                                _infoRow("Price", "₹${p.price}", isHighlight: false),
                                if (p.discountType != null && p.discountType!.isNotEmpty)
                                  _infoRow("Discount", "${p.discountType} ${p.discountValue}"),
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [_premiumGold.withOpacity(0.1), _premiumLight.withOpacity(0.05)],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: _premiumGold.withOpacity(0.3)),
                                  ),
                                  child: Wrap(
                                    alignment: WrapAlignment.spaceBetween,
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 10,
                                    runSpacing: 5,
                                    children: [
                                      const Text(
                                        "Final Price",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: _premiumGold,
                                        ),
                                      ),
                                      Text(
                                        "₹${p.finalPrice}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: _premiumGold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _infoRow("Stock", p.stockQuantity.toString()),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Images Section
                            if (p.images.isNotEmpty) ...[
                              _buildPremiumSection(
                                title: "Product Images (${p.images.length})",
                                icon: Icons.photo_library,
                                children: [
                                  SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: p.images.length,
                                      itemBuilder: (context, index) {
                                        final image = p.images[index];
                                        return GestureDetector(
                                          onTap: () => _showFullScreenImage(image.image),
                                          child: Container(
                                            width: 90,
                                            margin: const EdgeInsets.only(right: 12),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.grey.shade200),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(11),
                                              child: Image.network(
                                                image.image,
                                                height: 80,
                                                width: 90,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) => Container(
                                                  color: Colors.grey.shade100,
                                                  child: Icon(Icons.broken_image, color: Colors.grey.shade400),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Description
                            if (p.description.isNotEmpty) ...[
                              _buildPremiumSection(
                                title: "Description",
                                icon: Icons.description,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: _premiumCard,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      p.description,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.5,
                                        color: _premiumSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Attributes
                            if (p.attributes != null && p.attributes!.isNotEmpty) ...[
                              _buildPremiumSection(
                                title: "Attributes",
                                icon: Icons.tune,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: p.attributes!.entries.map((e) => _premiumChip(e.key, e.value.toString())).toList(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Specifications
                            if (p.specifications.isNotEmpty) ...[
                              _buildPremiumSection(
                                title: "Specifications",
                                icon: Icons.list_alt,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: p.specifications.map((spec) => _premiumChip(spec.key, spec.value)).toList(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Dimensions
                            if (p.weight.isNotEmpty ||
                                p.length.isNotEmpty ||
                                p.width.isNotEmpty ||
                                p.height.isNotEmpty) ...[
                              _buildPremiumSection(
                                title: "Dimensions",
                                icon: Icons.square_foot,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      if (p.weight.isNotEmpty) _premiumChip("Weight", p.weight),
                                      if (p.length.isNotEmpty) _premiumChip("Length", p.length),
                                      if (p.width.isNotEmpty) _premiumChip("Width", p.width),
                                      if (p.height.isNotEmpty) _premiumChip("Height", p.height),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Variants
                            if (p.variants.isNotEmpty) ...[
                              _buildPremiumSection(
                                title: "Variants (${p.variants.length})",
                                icon: Icons.swap_horiz,
                                children: [
                                  ...p.variants.map((variant) => _buildPremiumVariantCard(variant)),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Videos
                            if (p.videos.isNotEmpty) ...[
                              _buildPremiumSection(
                                title: "Videos (${p.videos.length})",
                                icon: Icons.video_library,
                                children: [
                                  ...p.videos.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final videoData = entry.value;
                                    final videoUrl = _extractVideoUrl(videoData);
                                    final videoKey = '${p.id}_video_$index';
                                    if (videoUrl.isNotEmpty &&
                                        videoUrl.startsWith('http') &&
                                        !_videoControllers.containsKey(videoKey)) {
                                      _initializeVideoPlayer(videoUrl, videoKey);
                                    }
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(13),
                                        child: videoUrl.isNotEmpty && videoUrl.startsWith('http')
                                            ? (_videoControllers.containsKey(videoKey) &&
                                            _videoControllers[videoKey]!.value.isInitialized
                                            ? AspectRatio(
                                          aspectRatio: _videoControllers[videoKey]!.value.aspectRatio,
                                          child: Chewie(controller: _chewieControllers[videoKey]!),
                                        )
                                            : AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: Container(
                                            color: _premiumPrimary,
                                            child: const Center(
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            ),
                                          ),
                                        ))
                                            : AspectRatio(
                                          aspectRatio: 16 / 9,
                                          child: Container(
                                            color: _premiumPrimary.withOpacity(0.1),
                                            child: const Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.error_outline, size: 36, color: Colors.grey),
                                                  SizedBox(height: 6),
                                                  Text("Video Unavailable", style: TextStyle(fontSize: 12)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _premiumStatusChip(String label, Color color, {IconData? icon}) {
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
          if (icon != null) Icon(icon, size: 14, color: color),
          if (icon != null) const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
              child: Icon(
                icon,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ShaderMask(
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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

  Widget _infoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
                color: isHighlight ? _premiumPrimary : Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF5A67F2).withOpacity(0.25),
        ),
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        runSpacing: 2,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color(0xFF5A67F2),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7B4DDB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumVariantCard(PendingProductVariant variant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_premiumCard, Colors.white],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _premiumGold.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: variant.attributes.entries.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [_premiumGold, _premiumLight]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${entry.key}: ${entry.value}",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _premiumChip("Price", "₹${variant.price}"),
              _premiumChip("Stock", variant.stockQuantity.toString()),
              _premiumChip("SKU", variant.sku),
            ],
          ),
          if (variant.image != null && variant.image!.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => _showFullScreenImage(variant.image!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  variant.image!,
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 60,
                    width: 60,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, size: 30, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Filter Section
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
                      items: ['Name', 'Category', 'Brand', 'Code', 'Company']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Icon(
                                value == 'Name' ? Icons.label
                                    : value == 'Category' ? Icons.category
                                    : value == 'Brand' ? Icons.branding_watermark
                                    : value == 'Code' ? Icons.qr_code
                                    : Icons.business,
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
                        hintText: filterType == 'Name' ? "Search by name..."
                            : filterType == 'Category' ? "Search by category..."
                            : filterType == 'Brand' ? "Search by brand..."
                            : filterType == 'Code' ? "Search by product code..."
                            : "Search by company...",
                        prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF6366F1)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                    Text("Total: ${filteredProducts.length}",
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
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
                      items: ['Name', 'Category', 'Brand', 'Code', 'Company']
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              Icon(
                                value == 'Name' ? Icons.label
                                    : value == 'Category' ? Icons.category
                                    : value == 'Brand' ? Icons.branding_watermark
                                    : value == 'Code' ? Icons.qr_code
                                    : Icons.business,
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
                        hintText: filterType == 'Name' ? "Search by name..."
                            : filterType == 'Category' ? "Search by category..."
                            : filterType == 'Brand' ? "Search by brand..."
                            : filterType == 'Code' ? "Search by product code..."
                            : "Search by company...",
                        prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF6366F1)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                    Text("Total: ${filteredProducts.length}",
                        style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
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
      children: [
        Tooltip(
          message: "Export Excel",
          child: InkWell(
            onTap: exportExcel,
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
            onTap: exportPDF,
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
            onTap: exportDOC,
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

  Widget _tableHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1E293B)),
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
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 10),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // Pagination
  Widget _buildPagination() {
    if (filteredProducts.isEmpty) return const SizedBox.shrink();

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
                    "${currentPage * itemsPerPage > filteredProducts.length ? filteredProducts.length : currentPage * itemsPerPage} "
                    "of ${filteredProducts.length}",
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
        title: const Text("Approved Products", style: TextStyle(fontWeight: FontWeight.w600)),
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
                    child: filteredProducts.isEmpty
                        ? const Center(child: Text("No approved products found"))
                        : SingleChildScrollView(
                      controller: _verticalController,
                      child: SingleChildScrollView(
                        controller: _rowsHorizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                          columnWidths: columnWidths,
                          children: List.generate(paginatedProducts.length, (rowIndex) {
                            final p = paginatedProducts[rowIndex];
                            final isEven = rowIndex % 2 == 0;
                            final srNo = paginatedProducts.length - rowIndex;
                            final franchiseText = (p.franchiseAvailable == true) ? "YES" : "NO";

                            return TableRow(
                              decoration: BoxDecoration(
                                color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                              ),
                              children: [
                                _tableCell(srNo.toString(), onTap: () => showProductPopup(p)),
                                GestureDetector(
                                  onTap: () => showProductPopup(p),
                                  child: Container(
                                    height: 42,
                                    padding: const EdgeInsets.all(2),
                                    child: Image.network(
                                      p.thumbnail,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image, size: 16, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                                _tableCell(p.name, onTap: () => showProductPopup(p)),
                                _tableCell(p.companyName),
                                _tableCell(p.categoryName),
                                _tableCell(p.subcategoryName),
                                _tableCell(p.brandName),
                                _tableCell(p.unitName),
                                _tableCell("₹${p.price}"),
                                _tableCell((p.discountType == null || p.discountType!.isEmpty) ? "-" : p.discountType!),
                                _tableCell(p.discountValue.isEmpty ? "-" : p.discountValue),
                                _tableCell("₹${p.finalPrice}", isBold: true),
                                _tableCell(p.stockQuantity.toString()),
                                _tableCell(p.hsnCode.isEmpty ? "-" : p.hsnCode),
                                _tableCell(p.variants.isEmpty ? "0" : "${p.variants.length} variants"),
                                _tableCell(p.productCode),
                                Container(
                                  height: 42,
                                  padding: const EdgeInsets.all(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (p.franchiseAvailable == true)
                                          ? Colors.green.withOpacity(0.15)
                                          : Colors.red.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        franchiseText,
                                        style: TextStyle(
                                          color: (p.franchiseAvailable == true) ? Colors.green[700] : Colors.red[700],
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 42,
                                  padding: const EdgeInsets.all(2),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        p.status,
                                        style: TextStyle(
                                          color: Colors.green[800],
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                                _tableCell(p.createdAt.substring(0, 10)),
                                Container(
                                  height: 42,
                                  padding: const EdgeInsets.all(2),
                                  child: IconButton(
                                    icon: const Icon(Icons.visibility, color: Color(0xFF4158D0), size: 18),
                                    onPressed: () => showProductPopup(p),
                                    tooltip: 'View Details',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
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