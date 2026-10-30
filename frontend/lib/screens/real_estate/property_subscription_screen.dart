import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;

import '../../api/realestate_service.dart';
import '../../models/real_estate/property_subscription_model.dart';

class PropertySubscriptionScreen extends StatefulWidget {
  const PropertySubscriptionScreen({super.key});

  @override
  State<PropertySubscriptionScreen> createState() =>
      _PropertySubscriptionScreenState();
}

class _PropertySubscriptionScreenState extends State<PropertySubscriptionScreen>
    with TickerProviderStateMixin {
  final PropertySubscriptionService _service = PropertySubscriptionService();

  List<PropertySubscriptionData> allPlans = [];
  List<PropertySubscriptionData> filteredPlans = [];
  List<PropertySubscriptionData> paginatedPlans = [];

  bool isLoading = true;

  // Search & Filter
  // Search & Filter
  final TextEditingController _planNameController = TextEditingController();
  String planNameQuery = '';
  String filterType = 'All'; // All / Active / Inactive / Days / Price

  // Pagination
  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  // Scroll Controllers
  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  // Hover / Border Animation
  late AnimationController _borderAnimationController;
  late Animation<Color?> _borderColorAnimation;
  bool _isCreateButtonHovered = false;

  // Premium Colors
  static const Color _premiumPrimary = Color(0xFF4158D0);
  static const Color _premiumSecondary = Color(0xFFC850C0);

  // Column Widths (ID column removed)
  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(60),   // SR No
    1: FixedColumnWidth(200),  // Name
    2: FixedColumnWidth(100),  // Days
    3: FixedColumnWidth(120),  // Price
    4: FixedColumnWidth(100),  // Status
    5: FixedColumnWidth(150),  // Created
    6: FixedColumnWidth(150),  // Updated
    7: FixedColumnWidth(100),  // Action
  };

  final List<String> headerLabels = [
    "SR No", "Plan Name", "Days", "Price", "Status",
    "Created", "Updated", "Action"
  ];

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();

    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _borderColorAnimation = ColorTween(
      begin: _premiumPrimary,
      end: _premiumSecondary,
    ).animate(_borderAnimationController);

    loadPlans();
  }

  @override
  void dispose() {
    _planNameController.dispose();
    _headerHorizontalController.dispose();
    _rowsHorizontalController.dispose();
    _verticalController.dispose();
    _borderAnimationController.dispose();
    _service.dispose();
    super.dispose();
  }
  Future<void> loadPlans() async {
    setState(() => isLoading = true);
    try {
      final response = await _service.getPlans();
      if (mounted) {
        setState(() {
          allPlans = response.data;
          allPlans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load plans: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void applyFilters() {
    // ---- First filter by Search (plan name) ----
    List<PropertySubscriptionData> base = allPlans;
    if (planNameQuery.isNotEmpty) {
      base = base
          .where((p) =>
          p.name.toLowerCase().contains(planNameQuery.toLowerCase()))
          .toList();
    }

    // ---- Then apply dropdown filter ----
    if (filterType == 'All') {
      filteredPlans = base;
    } else if (filterType == 'Active') {
      filteredPlans = base.where((p) => p.isActive == true).toList();
    } else if (filterType == 'Inactive') {
      filteredPlans = base.where((p) => p.isActive == false).toList();
    } else if (filterType == 'Days') {
      // Sort by days ascending
      filteredPlans = List.from(base)
        ..sort((a, b) => a.days.compareTo(b.days));
    } else if (filterType == 'Price') {
      // Sort by price ascending
      filteredPlans = List.from(base)
        ..sort((a, b) => a.price.compareTo(b.price));
    } else {
      filteredPlans = base;
    }

    applyPagination();
  }

  void applyPagination() {
    if (filteredPlans.isEmpty) {
      paginatedPlans = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }

    totalPages = (filteredPlans.length / itemsPerPage).ceil();
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;

    int startIndex = (currentPage - 1) * itemsPerPage;
    int endIndex = startIndex + itemsPerPage;
    if (endIndex > filteredPlans.length) {
      endIndex = filteredPlans.length;
    }
    paginatedPlans = filteredPlans.sublist(startIndex, endIndex);
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
      planNameQuery = '';
      filterType = 'All';
      _planNameController.clear();
      currentPage = 1;
      applyFilters();
    });
  }
  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String formatPrice(double price) {
    final formatter = NumberFormat('#,##,##0.00', 'en_IN');
    return '₹${formatter.format(price)}';
  }

  // ==================== CREATE PLAN FORM ====================
  void _showCreateForm() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final daysController = TextEditingController();
    final priceController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 500,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
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
                      colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_circle_outline,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Create Subscription Plan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormField(
                            label: 'Plan Name',
                            controller: nameController,
                            icon: Icons.card_membership,
                            hint: 'e.g., 30 Days Plan',
                            validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Please enter plan name'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildFormField(
                            label: 'Days',
                            controller: daysController,
                            icon: Icons.calendar_today,
                            hint: 'e.g., 30',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter days';
                              }
                              if (int.tryParse(v) == null) {
                                return 'Enter a valid number';
                              }
                              if (int.parse(v) <= 0) {
                                return 'Days must be greater than 0';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildFormField(
                            label: 'Price (₹)',
                            controller: priceController,
                            icon: Icons.currency_rupee,
                            hint: 'e.g., 999.00',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter price';
                              }
                              if (double.tryParse(v) == null) {
                                return 'Enter a valid price';
                              }
                              if (double.parse(v) < 0) {
                                return 'Price cannot be negative';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                            if (!formKey.currentState!.validate()) return;
                            setDialogState(() => isSubmitting = true);
                            try {
                              final request =
                              PropertySubscriptionCreateRequest(
                                name: nameController.text.trim(),
                                days: int.parse(daysController.text.trim()),
                                price:
                                double.parse(priceController.text.trim()),
                              );
                              final response =
                              await _service.createPlan(request);

                              if (!mounted) return;
                              Navigator.pop(context);

                              if (response.success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(response.message),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                // ✅ Add new plan to local list immediately
                                if (response.data != null) {
                                  allPlans.insert(0, response.data!);
                                  allPlans.sort((a, b) => b.createdAt.compareTo(a.createdAt));
                                }

                                setState(() => applyFilters());
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(response.message),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;
                              setDialogState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: isSubmitting
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(Icons.check_circle, size: 18),
                          label: Text(
                            isSubmitting ? 'Creating...' : 'Create Plan',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _premiumPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor:
                            _premiumPrimary.withOpacity(0.5),
                          ),
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
  // ==================== EXPORT FUNCTIONS ====================
  void exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['Subscription Plans'];
    sheet.appendRow([
      "SR No", "Plan Name", "Days", "Price", "Status",
      "Created At", "Updated At"
    ]);

    int srNo = filteredPlans.length;
    for (var p in filteredPlans) {
      sheet.appendRow([
        srNo--,
        p.name,
        p.days,
        p.price,
        p.isActive ? 'Active' : 'Inactive',
        formatDate(p.createdAt),
        formatDate(p.updatedAt),
      ]);
    }

    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "subscription_plans.xlsx")
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
            headers: [
              "SR No", "Plan Name", "Days", "Price", "Status",
              "Created", "Updated"
            ],
            data: List.generate(filteredPlans.length, (index) {
              final p = filteredPlans[index];
              final srNo = filteredPlans.length - index;
              return [
                srNo.toString(),
                p.name,
                p.days.toString(),
                formatPrice(p.price),
                p.isActive ? 'Active' : 'Inactive',
                formatDate(p.createdAt),
                formatDate(p.updatedAt),
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
    content.writeln("Property Subscription Plans\n");
    content.writeln("=" * 50);

    int srNo = filteredPlans.length;
    for (var p in filteredPlans) {
      content.writeln("SR No: ${srNo--}");
      content.writeln("Plan Name: ${p.name}");
      content.writeln("Days: ${p.days}");
      content.writeln("Price: ${formatPrice(p.price)}");
      content.writeln("Status: ${p.isActive ? 'Active' : 'Inactive'}");
      content.writeln("Created: ${formatDate(p.createdAt)}");
      content.writeln("Updated: ${formatDate(p.updatedAt)}");
      content.writeln("-" * 30);
    }

    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "subscription_plans.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ==================== UPDATE PLAN FORM ====================
  void _showUpdateForm(PropertySubscriptionData plan) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: plan.name);
    final daysController = TextEditingController(text: plan.days.toString());
    final priceController = TextEditingController(text: plan.price.toString());
    bool isActive = plan.isActive;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 500,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
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
                      colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.edit,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Update Subscription Plan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                          padding: const EdgeInsets.all(8),
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                ),

                // Body
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFormField(
                            label: 'Plan Name',
                            controller: nameController,
                            icon: Icons.card_membership,
                            hint: 'e.g., 30 Days Plan',
                            validator: (v) =>
                            (v == null || v.trim().isEmpty)
                                ? 'Please enter plan name'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildFormField(
                            label: 'Days',
                            controller: daysController,
                            icon: Icons.calendar_today,
                            hint: 'e.g., 30',
                            keyboardType: TextInputType.number,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter days';
                              }
                              if (int.tryParse(v) == null) {
                                return 'Enter a valid number';
                              }
                              if (int.parse(v) <= 0) {
                                return 'Days must be greater than 0';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildFormField(
                            label: 'Price (₹)',
                            controller: priceController,
                            icon: Icons.currency_rupee,
                            hint: 'e.g., 999.00',
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Please enter price';
                              }
                              if (double.tryParse(v) == null) {
                                return 'Enter a valid price';
                              }
                              if (double.parse(v) < 0) {
                                return 'Price cannot be negative';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Active toggle
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isActive
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: isActive
                                      ? Colors.green
                                      : Colors.grey,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: isActive,
                                  activeColor: _premiumPrimary,
                                  onChanged: (v) =>
                                      setDialogState(() => isActive = v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                            if (!formKey.currentState!.validate()) return;
                            setDialogState(() => isSubmitting = true);
                            try {
                              final request =
                              PropertySubscriptionUpdateRequest(
                                id: plan.id,
                                name: nameController.text.trim(),
                                days: int.parse(daysController.text.trim()),
                                price:
                                double.parse(priceController.text.trim()),
                                isActive: isActive,
                              );
                              final response =
                              await _service.updatePlan(request);

                              if (!mounted) return;
                              Navigator.pop(context);

                              if (response.success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(response.message),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                // ✅ Update existing plan in local lists — DO NOT reload,
                                //    DO NOT touch filter, so plan stays visible in the table
                                if (response.data != null) {
                                  final updated = response.data!;

                                  // Update in allPlans
                                  final aIdx = allPlans.indexWhere((p) => p.id == updated.id);
                                  if (aIdx != -1) {
                                    allPlans[aIdx] = updated;
                                  }

                                  // Update in filteredPlans
                                  final fIdx = filteredPlans.indexWhere((p) => p.id == updated.id);
                                  if (fIdx != -1) {
                                    filteredPlans[fIdx] = updated;
                                  }

                                  // Update in paginatedPlans
                                  final pIdx = paginatedPlans.indexWhere((p) => p.id == updated.id);
                                  if (pIdx != -1) {
                                    paginatedPlans[pIdx] = updated;
                                  }
                                }

                                // Rebuild UI so status badge updates
                                setState(() {});
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(response.message),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;
                              setDialogState(() => isSubmitting = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: isSubmitting
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Icon(Icons.save, size: 18),
                          label: Text(
                            isSubmitting ? 'Updating...' : 'Update Plan',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _premiumPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor:
                            _premiumPrimary.withOpacity(0.5),
                          ),
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

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: _premiumPrimary),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
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
              borderSide: const BorderSide(color: _premiumPrimary, width: 1.5),
            ),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
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
              child: Image.asset(
                "assets/icon/xls.png",
                height: 20,
                width: 20,
              ),
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
              child: Image.asset(
                "assets/icon/pdf.png",
                height: 20,
                width: 20,
              ),
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
              child: Image.asset(
                "assets/icon/doc.png",
                height: 20,
                width: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== DETAILS POPUP (ID removed) ====================
  void showDetailsPopup(PropertySubscriptionData plan) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.transparent,
        child: Container(
          width: 520,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
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
                    colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
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
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.card_membership,
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: plan.isActive
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  plan.isActive
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  size: 12,
                                  color: plan.isActive
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  plan.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: plan.isActive
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                              ],
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

              // Body
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoSection(
                        'Plan Details',
                        Icons.info_outline,
                        [
                          _infoRow('Plan Name', plan.name),
                          _infoRow('Days', '${plan.days} days'),
                          _infoRow('Price', formatPrice(plan.price)),
                          _infoRow(
                              'Status', plan.isActive ? 'Active' : 'Inactive'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoSection(
                        'Timestamps',
                        Icons.calendar_today,
                        [
                          _infoRow('Created At', formatDate(plan.createdAt)),
                          _infoRow('Updated At', formatDate(plan.updatedAt)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Footer with Update Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Close'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showUpdateForm(plan);
                        },
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text(
                          'Update Plan',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _premiumPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
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

  Widget _infoRow(String label, String value) {
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
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== CREATE BUTTON with Running Outline + Hover ====================
  Widget _buildAnimatedCreateButton() {
    return MouseRegion(
      onEnter: (_) => setState(() => _isCreateButtonHovered = true),
      onExit: (_) => setState(() => _isCreateButtonHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedBuilder(
        animation: _borderAnimationController,
        builder: (context, child) {
          final animatedColor =
              _borderColorAnimation.value ?? _premiumPrimary;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            transform: Matrix4.translationValues(
              0,
              _isCreateButtonHovered ? -2 : 0,
              0,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: animatedColor,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: animatedColor.withOpacity(
                    _isCreateButtonHovered ? 0.6 : 0.4,
                  ),
                  blurRadius: _isCreateButtonHovered ? 12 : 8,
                  spreadRadius: _isCreateButtonHovered ? 2 : 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _showCreateForm,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Create Plan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== FILTER SECTION ====================
  // ==================== FILTER SECTION ====================
  // ==================== FILTER SECTION ====================
  // ==================== FILTER SECTION ====================
  Widget _buildFilterSection(bool isMobile) {
    // Dropdown options — All, Active, Inactive, Days, Price
    final List<Map<String, dynamic>> dropdownOptions = [
      {'value': 'All', 'label': 'All', 'icon': Icons.list},
      {'value': 'Active', 'label': 'Active', 'icon': Icons.check_circle},
      {'value': 'Inactive', 'label': 'Inactive', 'icon': Icons.cancel},
      {'value': 'Days', 'label': 'Days', 'icon': Icons.calendar_today},
      {'value': 'Price', 'label': 'Price', 'icon': Icons.currency_rupee},
    ];

    // ============ Reusable Search Field ============
    Widget searchField({double? width}) => Container(
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _planNameController,
        decoration: InputDecoration(
          hintText: 'Search by plan name...',
          prefixIcon: const Icon(Icons.search,
              size: 16, color: Color(0xFF6366F1)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: planNameQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, size: 16),
            onPressed: () {
              _planNameController.clear();
              setState(() {
                planNameQuery = '';
                currentPage = 1;
                applyFilters();
              });
            },
          )
              : null,
        ),
        onChanged: (value) {
          setState(() {
            planNameQuery = value;
            currentPage = 1;
            applyFilters();
          });
        },
      ),
    );

    // ============ Reusable Dropdown ============
    Widget dropdownField({double? width}) => Container(
      width: width,
      height: 42,
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
          items: dropdownOptions.map<DropdownMenuItem<String>>((opt) {
            return DropdownMenuItem<String>(
              value: opt['value'] as String,
              child: Row(
                children: [
                  Icon(
                    opt['icon'] as IconData,
                    size: 14,
                    color: const Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 8),
                  Text(opt['label'] as String),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );

    // ============ Total + Reset ============
    Widget totalAndReset() => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Total: ${filteredPlans.length}",
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: resetFilters,
          icon: const Icon(Icons.refresh),
          color: Colors.red,
          tooltip: "Reset",
          padding: EdgeInsets.zero,
          constraints:
          const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );

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
      child: isMobile
          ? Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Dropdown + Search
          Row(
            children: [
              dropdownField(width: 120),
              const SizedBox(width: 8),
              Expanded(child: searchField()),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Export + Total + Reset
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildExportIcons(),
              totalAndReset(),
            ],
          ),
        ],
      )
          : Row(
        children: [
          // 1. Dropdown
          dropdownField(width: 150),
          const SizedBox(width: 12),

          // 2. Search bar (expanded)
          Expanded(
            flex: 3,
            child: searchField(),
          ),
          const SizedBox(width: 12),

          // 3. Export buttons
          _buildExportIcons(),
          const SizedBox(width: 12),

          // 4. Total + Reset
          totalAndReset(),
        ],
      ),
    );
  }

  // ==================== TABLE ====================
  Widget _buildTable() {
    return Container(
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
          // Header
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(12)),
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
            child: filteredPlans.isEmpty
                ? const Center(child: Text("No subscription plans found"))
                : SingleChildScrollView(
              controller: _verticalController,
              child: SingleChildScrollView(
                controller: _rowsHorizontalController,
                scrollDirection: Axis.horizontal,
                child: Table(
                  border: TableBorder.all(
                      color: Colors.grey.shade300, width: 1),
                  columnWidths: columnWidths,
                  children: List.generate(paginatedPlans.length, (rowIndex) {
                    final plan = paginatedPlans[rowIndex];
                    final isEven = rowIndex % 2 == 0;
                    final srNo = filteredPlans.length -
                        ((currentPage - 1) * itemsPerPage + rowIndex);

                    return TableRow(
                      decoration: BoxDecoration(
                        color: isEven
                            ? Colors.white
                            : const Color(0xFFF8FAFC),
                      ),
                      children: [
                        // SR No
                        _tableCell(srNo.toString(),
                            onTap: () => showDetailsPopup(plan)),

                        // Plan Name
                        _tableCell(plan.name,
                            onTap: () => showDetailsPopup(plan),
                            maxLines: 2),

                        // Days
                        Container(
                          height: 42,
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${plan.days} days',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Price
                        Container(
                          height: 42,
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                formatPrice(plan.price),
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Status
                        Container(
                          height: 42,
                          padding: const EdgeInsets.all(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: plan.isActive
                                  ? Colors.green.withOpacity(0.15)
                                  : Colors.grey.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                plan.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: plan.isActive
                                      ? Colors.green[700]
                                      : Colors.grey[700],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Created
                        _tableCell(formatDate(plan.createdAt),
                            onTap: () => showDetailsPopup(plan)),

                        // Updated
                        _tableCell(formatDate(plan.updatedAt),
                            onTap: () => showDetailsPopup(plan)),

                        // Action
                        Container(
                          height: 42,
                          padding: const EdgeInsets.all(2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.visibility,
                                    color: Color(0xFF4158D0), size: 18),
                                onPressed: () => showDetailsPopup(plan),
                                tooltip: 'View Details',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 28, minHeight: 28),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.orange, size: 18),
                                onPressed: () => _showUpdateForm(plan),
                                tooltip: 'Update Plan',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 28, minHeight: 28),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _tableCell(String text, {VoidCallback? onTap, int maxLines = 2}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10),
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // ==================== PAGINATION ====================
  Widget _buildPagination() {
    if (filteredPlans.isEmpty) return const SizedBox.shrink();

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
                      .map((e) =>
                      DropdownMenuItem(value: e, child: Text(e.toString())))
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
                    "${currentPage * itemsPerPage > filteredPlans.length ? filteredPlans.length : currentPage * itemsPerPage} "
                    "of ${filteredPlans.length}",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          );

          final pageButtons = [
            _compactPageButton(
                icon: Icons.chevron_left,
                onTap: currentPage > 1 ? previousPage : null),
            if (totalPages <= 5)
              ...List.generate(
                  totalPages, (index) => _compactPageNumber(index + 1))
            else if (currentPage <= 3) ...[
              ...List.generate(4, (index) => _compactPageNumber(index + 1)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...",
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              _compactPageNumber(totalPages),
            ] else if (currentPage >= totalPages - 2) ...[
              _compactPageNumber(1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...",
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              ...List.generate(
                  4, (index) => _compactPageNumber(totalPages - 3 + index)),
            ] else ...[
              _compactPageNumber(1),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Text("...",
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
              _compactPageNumber(currentPage - 1),
              _compactPageNumber(currentPage),
              _compactPageNumber(currentPage + 1),
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

  Widget _compactPageButton(
      {required IconData icon, required VoidCallback? onTap}) {
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

  // ==================== MAIN BUILD ====================
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Text(
              "Property Subscription Plans",
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const Spacer(),
            if (!isMobile) _buildAnimatedCreateButton(),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (isMobile) ...[
              Align(
                alignment: Alignment.centerRight,
                child: _buildAnimatedCreateButton(),
              ),
              const SizedBox(height: 8),
            ],
            _buildFilterSection(isMobile),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _buildTable()),
                  const SizedBox(height: 8),
                  _buildPagination(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}