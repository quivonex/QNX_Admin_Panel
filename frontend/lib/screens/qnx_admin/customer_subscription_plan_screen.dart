// lib/screens/olx/customer_subscription_plan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/qnx_admin/customer_subscription_plan_model.dart';
import '../../api/api_service.dart';

// ---------------------------------------------------------------------------
// Screen palette — same as OLX Plan screen
// ---------------------------------------------------------------------------
const Color _kBrand = Color(0xFF6366F1);
const Color _kInk = Color(0xFF1E293B);
const Color _kBody = Color(0xFF475569);
const Color _kMuted = Color(0xFF64748B);
const Color _kFaint = Color(0xFF94A3B8);
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kCanvas = Color(0xFFF8FAFC);
const Color _kSuccess = Color(0xFF10B981);

class CustomerSubscriptionPlanScreen extends StatefulWidget {
  const CustomerSubscriptionPlanScreen({super.key});

  @override
  State<CustomerSubscriptionPlanScreen> createState() =>
      _CustomerSubscriptionPlanScreenState();
}

class _CustomerSubscriptionPlanScreenState
    extends State<CustomerSubscriptionPlanScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _enquiryLimitController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final TextEditingController _filterNameController = TextEditingController();

  // State
  bool _isLoading = false;
  bool _isCreating = false;
  String? _loadError;
  String? _formError;

  final CustomerSubscriptionPlanService _service =
  CustomerSubscriptionPlanService();

  List<CustomerSubscriptionPlanData> allPlans = [];
  List<CustomerSubscriptionPlanData> filteredPlans = [];
  List<CustomerSubscriptionPlanData> paginatedPlans = [];

  int currentPage = 1;
  int itemsPerPage = 9;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [3, 6, 9, 12, 15, 30];

  String filterName = '';
  String filterStatus = 'All';
  static const List<String> _statusOptions = ['All', 'Active', 'Inactive'];

  // Dialog handles
  StateSetter? _dialogSetState;
  BuildContext? _dialogContext;

  // Card accents
  static const List<Color> _cardAccents = [
    Color(0xFF10B981),
    Color(0xFF0EA5E9),
    Color(0xFF1E3A5F),
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
  ];

  static const List<IconData> _cardIcons = [
    Icons.workspace_premium_outlined,
    Icons.star_outline_rounded,
    Icons.rocket_launch_outlined,
    Icons.savings_outlined,
    Icons.handshake_outlined,
    Icons.assignment_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  // ==================== LOAD PLANS ====================
  Future<void> _loadPlans() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final response = await _service.getPlans();
      if (mounted) {
        setState(() {
          allPlans = response.data..sort((a, b) => b.id.compareTo(a.id));
          _isLoading = false;
          applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError =
          'Plans could not be loaded. Check your connection and try again.';
        });
        _showSnackBar("Failed to load plans", isError: true);
      }
    }
  }

  bool get _hasActiveFilters => filterName.isNotEmpty || filterStatus != 'All';

  void applyFilters() {
    final query = filterName.trim().toLowerCase();
    filteredPlans = allPlans.where((p) {
      final matchesSearch = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.price.toLowerCase().contains(query) ||
          '${p.durationDays}'.contains(query) ||
          '${p.enquiryLimit}'.contains(query);

      final matchesStatus = filterStatus == 'All' ||
          (filterStatus == 'Active' && p.isActive) ||
          (filterStatus == 'Inactive' && !p.isActive);

      return matchesSearch && matchesStatus;
    }).toList();
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
    if (endIndex > filteredPlans.length) endIndex = filteredPlans.length;

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
      filterName = '';
      filterStatus = 'All';
      _filterNameController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  // ==================== CREATE PLAN ====================
  void _refreshDialog(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
    _dialogSetState?.call(() {});
  }

  void _closeDialog() {
    final ctx = _dialogContext;
    if (ctx != null && Navigator.of(ctx).canPop()) {
      Navigator.of(ctx).pop();
    }
  }

  Future<void> _createPlan() async {
    if (!_formKey.currentState!.validate()) return;

    _refreshDialog(() {
      _isCreating = true;
      _formError = null;
    });

    final request = CustomerSubscriptionPlanRequest(
      name: _nameController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0.0,
      enquiryLimit: int.tryParse(_enquiryLimitController.text.trim()) ?? 0,
      durationDays: int.tryParse(_durationController.text.trim()) ?? 0,
    );

    try {
      final response = await _service.createPlan(request);
      if (!mounted) return;
      _refreshDialog(() => _isCreating = false);

      if (response.success) {
        _clearForm();
        _closeDialog();
        await _loadPlans();
        _showSnackBar("Plan created successfully");
      } else {
        _refreshDialog(() => _formError = response.message);
        _showSnackBar(response.message, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _refreshDialog(() {
        _isCreating = false;
        _formError = "Error: $e";
      });
      _showSnackBar("Error: $e", isError: true);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _priceController.clear();
    _enquiryLimitController.clear();
    _durationController.clear();
    _formError = null;
    _formKey.currentState?.reset();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : _kBrand,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ==================== CREATE DIALOG ====================
  Future<void> _openCreatePlanDialog() async {
    _clearForm();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        _dialogContext = dialogContext;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            _dialogSetState = setDialogState;
            return _buildCreateDialog(context, setDialogState);
          },
        );
      },
    );
    _dialogSetState = null;
    _dialogContext = null;
  }

  Widget _buildCreateDialog(BuildContext context, StateSetter setDialogState) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context).size;
    final isSmall = media.width < 640;
    final dialogWidth =
    isSmall ? media.width : (media.width < 1024 ? 560.0 : 640.0);

    final cancelButton = OutlinedButton(
      onPressed: _isCreating
          ? null
          : () {
        _clearForm();
        Navigator.of(context).pop();
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: _kBody,
        side: const BorderSide(color: _kBorder),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text("Cancel"),
    );

    final createButton = FilledButton.icon(
      onPressed: _isCreating ? null : _createPlan,
      style: FilledButton.styleFrom(
        backgroundColor: _kBrand,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _kBrand.withOpacity(0.6),
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: _isCreating
          ? const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : const Icon(Icons.add_rounded, size: 20),
      label: Text(
        _isCreating ? "Creating..." : "Create Plan",
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );

    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isSmall ? 12 : 24,
        vertical: 24,
      ),
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: media.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _kBrand.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.post_add_rounded,
                        color: _kBrand, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Create Subscription Plan",
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _kInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Configure a new customer subscription plan",
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _kMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: _isCreating
                        ? null
                        : () {
                      _clearForm();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close_rounded, color: _kMuted),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),

            // Scrollable form body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_formError != null) ...[
                        _buildFormErrorBanner(_formError!),
                        const SizedBox(height: 18),
                      ],
                      _buildSectionLabel("Plan details"),
                      const SizedBox(height: 14),
                      _buildTextField(
                        _nameController,
                        "Plan Name",
                        Icons.label_outline,
                        hint: "e.g. Premium",
                      ),
                      const SizedBox(height: 16),
                      if (isSmall) ...[
                        _buildTextField(
                          _priceController,
                          "Price (₹)",
                          Icons.currency_rupee,
                          keyboardType: TextInputType.number,
                          hint: "e.g. 99",
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          validator: (v) {
                            final text = (v ?? '').trim();
                            if (text.isEmpty) return "Price is required";
                            final price = double.tryParse(text);
                            if (price == null || price <= 0) {
                              return "Enter a valid price";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _enquiryLimitController,
                          "Enquiry Limit",
                          Icons.question_answer_outlined,
                          keyboardType: TextInputType.number,
                          hint: "e.g. 10",
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) {
                            final text = (v ?? '').trim();
                            if (text.isEmpty) return "Enquiry limit is required";
                            final limit = int.tryParse(text);
                            if (limit == null || limit <= 0) {
                              return "Enter a valid limit";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _durationController,
                          "Duration (Days)",
                          Icons.timer_outlined,
                          keyboardType: TextInputType.number,
                          hint: "e.g. 30",
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) {
                            final text = (v ?? '').trim();
                            if (text.isEmpty) return "Duration is required";
                            final days = int.tryParse(text);
                            if (days == null || days <= 0) {
                              return "Enter a valid number of days";
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTextField(
                                _priceController,
                                "Price (₹)",
                                Icons.currency_rupee,
                                keyboardType: TextInputType.number,
                                hint: "e.g. 99",
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}')),
                                ],
                                validator: (v) {
                                  final text = (v ?? '').trim();
                                  if (text.isEmpty) return "Price is required";
                                  final price = double.tryParse(text);
                                  if (price == null || price <= 0) {
                                    return "Enter a valid price";
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextField(
                                _enquiryLimitController,
                                "Enquiry Limit",
                                Icons.question_answer_outlined,
                                keyboardType: TextInputType.number,
                                hint: "e.g. 10",
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                                validator: (v) {
                                  final text = (v ?? '').trim();
                                  if (text.isEmpty) {
                                    return "Enquiry limit is required";
                                  }
                                  final limit = int.tryParse(text);
                                  if (limit == null || limit <= 0) {
                                    return "Enter a valid limit";
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildTextField(
                          _durationController,
                          "Duration (Days)",
                          Icons.timer_outlined,
                          keyboardType: TextInputType.number,
                          hint: "e.g. 30",
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          validator: (v) {
                            final text = (v ?? '').trim();
                            if (text.isEmpty) return "Duration is required";
                            final days = int.tryParse(text);
                            if (days == null || days <= 0) {
                              return "Enter a valid number of days";
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            const Divider(height: 1, color: _kBorder),

            // Footer actions
            Container(
              color: _kCanvas,
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
              child: Row(
                children: isSmall
                    ? [
                  Expanded(child: cancelButton),
                  const SizedBox(width: 12),
                  Expanded(child: createButton),
                ]
                    : [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '* ',
                            style: TextStyle(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const TextSpan(text: 'Required fields'),
                        ],
                      ),
                      style: const TextStyle(
                          color: _kMuted, fontSize: 12.5),
                    ),
                  ),
                  cancelButton,
                  const SizedBox(width: 12),
                  createButton,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _kInk,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(height: 1, color: _kBorder)),
      ],
    );
  }

  Widget _buildFormErrorBanner(String message) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: errorColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: errorColor.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: errorColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: errorColor, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        int maxLines = 1,
        TextInputType keyboardType = TextInputType.text,
        bool isRequired = true,
        String? hint,
        List<TextInputFormatter>? inputFormatters,
        String? Function(String?)? validator,
      }) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: label),
              if (isRequired)
                TextSpan(text: ' *', style: TextStyle(color: errorColor))
              else
                const TextSpan(
                  text: '  (optional)',
                  style: TextStyle(
                    color: _kFaint,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kInk,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          enabled: !_isCreating,
          style: const TextStyle(fontSize: 14, color: _kInk),
          validator: validator ??
              (isRequired
                  ? (v) => (v == null || v.trim().isEmpty)
                  ? "$label is required"
                  : null
                  : null),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _kFaint, fontSize: 13.5),
            prefixIcon: maxLines > 1
                ? null
                : Icon(icon, color: _kMuted, size: 20),
            filled: true,
            fillColor: _kCanvas,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBrand, width: 1.6),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: errorColor, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== PLAN DETAILS ====================
  Future<void> _showPlanDetails(
      CustomerSubscriptionPlanData plan, Color accent, IconData icon) {
    return showDialog<void>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isSmall = MediaQuery.of(ctx).size.width < 640;
        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: isSmall ? 12 : 24,
            vertical: 24,
          ),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 480,
              maxHeight: MediaQuery.of(ctx).size.height * 0.85,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 12, 16),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: _kInk,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Plan #${plan.id}",
                              style: const TextStyle(
                                  color: _kMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded, color: _kMuted),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: _kBorder),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _detailRow(
                          Icons.currency_rupee,
                          "Price",
                          value: plan.formattedPrice,
                        ),
                        _detailRow(
                          Icons.question_answer_outlined,
                          "Enquiry Limit",
                          value: "${plan.enquiryLimit} enquiries",
                        ),
                        _detailRow(
                          Icons.schedule_rounded,
                          "Duration",
                          value: _validityLabel(plan.durationDays),
                        ),
                        _detailRow(
                          Icons.toggle_on_outlined,
                          "Status",
                          valueWidget: _StatusBadge(active: plan.isActive),
                        ),
                        _detailRow(
                          Icons.calendar_today_outlined,
                          "Created At",
                          value: _formatDate(plan.createdAt),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1, color: _kBorder),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: _kBrand,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Close"),
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

  Widget _detailRow(IconData icon, String label,
      {String? value, Widget? valueWidget}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _kCanvas,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
            ),
            child: Icon(icon, size: 18, color: _kMuted),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _kMuted,
                  ),
                ),
                const SizedBox(height: 4),
                valueWidget ??
                    Text(
                      value ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        color: _kInk,
                        height: 1.45,
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _validityLabel(int days) {
    if (days <= 0) return 'Not configured';
    if (days % 365 == 0) {
      final y = days ~/ 365;
      return '$y ${y == 1 ? 'year' : 'years'} ($days days)';
    }
    if (days % 30 == 0) {
      final m = days ~/ 30;
      return '$m ${m == 1 ? 'month' : 'months'} ($days days)';
    }
    if (days % 7 == 0) {
      final w = days ~/ 7;
      return '$w ${w == 1 ? 'week' : 'weeks'} ($days days)';
    }
    return '$days ${days == 1 ? 'day' : 'days'}';
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCanvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 700;
            final horizontalPadding = isMobile ? 16.0 : 32.0;
            final contentWidth =
            (width - horizontalPadding * 2).clamp(0.0, 1280.0).toDouble();

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: isMobile ? 20 : 28,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPageHeader(contentWidth < 420),
                      const SizedBox(height: 22),
                      _buildFilterSection(contentWidth),
                      const SizedBox(height: 28),
                      _buildPlansSection(contentWidth),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  int _columnsFor(double width) {
    if (width >= 1080) return 3;
    if (width >= 700) return 2;
    return 1;
  }

  // ==================== PAGE HEADER ====================
  Widget _buildPageHeader(bool isCompact) {
    final theme = Theme.of(context);

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Customer Subscription Plans",
          style: theme.textTheme.headlineSmall?.copyWith(
            color: _kInk,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Manage and configure customer subscription plans",
          style: theme.textTheme.bodyMedium?.copyWith(color: _kMuted),
        ),
      ],
    );

    final createButton = FilledButton.icon(
      onPressed: _openCreatePlanDialog,
      style: FilledButton.styleFrom(
        backgroundColor: _kBrand,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: _kBrand.withOpacity(0.45),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      icon: const Icon(Icons.add_rounded, size: 20),
      label: const Text("Create Plan"),
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleBlock,
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: createButton),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 16),
        createButton,
      ],
    );
  }

  // ==================== FILTER SECTION ====================
  InputDecoration _filterDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      isDense: true,
      labelStyle: const TextStyle(color: _kMuted, fontSize: 13),
      hintStyle: const TextStyle(color: _kFaint, fontSize: 13.5),
      prefixIcon: Icon(icon, size: 18, color: _kMuted),
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      filled: true,
      fillColor: _kCanvas,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kBrand, width: 1.5),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return InputDecorator(
      decoration: _filterDecoration(label: label, icon: icon),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          borderRadius: BorderRadius.circular(12),
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 20, color: _kMuted),
          style: const TextStyle(fontSize: 14, color: _kInk),
          items: items
              .map((e) => DropdownMenuItem<T>(value: e, child: Text('$e')))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildFilterSection(double contentWidth) {
    final isWide = contentWidth >= 920;
    final isMobile = contentWidth < 600;

    final searchField = TextField(
      controller: _filterNameController,
      style: const TextStyle(fontSize: 14, color: _kInk),
      decoration: _filterDecoration(
        label: "Search plans",
        hint: "Name, price or duration",
        icon: Icons.search_rounded,
      ).copyWith(
        suffixIcon: filterName.isNotEmpty
            ? IconButton(
          tooltip: 'Clear search',
          icon: const Icon(Icons.close_rounded, size: 18),
          onPressed: () {
            _filterNameController.clear();
            setState(() {
              filterName = '';
              currentPage = 1;
              applyFilters();
            });
          },
        )
            : null,
      ),
      onChanged: (value) {
        setState(() {
          filterName = value;
          currentPage = 1;
          applyFilters();
        });
      },
    );

    final statusField = _buildDropdown<String>(
      label: "Status",
      icon: Icons.toggle_on_outlined,
      value: filterStatus,
      items: _statusOptions,
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          filterStatus = v;
          currentPage = 1;
          applyFilters();
        });
      },
    );

    final perPageField = _buildDropdown<int>(
      label: "Per page",
      icon: Icons.grid_view_rounded,
      value: itemsPerPage,
      items: rowsPerPageOptions,
      onChanged: changeItemsPerPage,
    );

    final clearButton = OutlinedButton.icon(
      onPressed: _hasActiveFilters ? resetFilters : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: _kBody,
        side: const BorderSide(color: _kBorder),
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
      label: const Text("Clear filters"),
    );

    Widget body;
    if (isWide) {
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: searchField),
          const SizedBox(width: 12),
          SizedBox(width: 190, child: statusField),
          const SizedBox(width: 12),
          SizedBox(width: 150, child: perPageField),
          const SizedBox(width: 12),
          clearButton,
        ],
      );
    } else if (isMobile) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: statusField),
              const SizedBox(width: 12),
              Expanded(child: perPageField),
            ],
          ),
          const SizedBox(height: 12),
          clearButton,
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          searchField,
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: statusField),
              const SizedBox(width: 12),
              Expanded(child: perPageField),
              const SizedBox(width: 12),
              clearButton,
            ],
          ),
        ],
      );
    }

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: body,
    );
  }

  // ==================== PLANS SECTION ====================
  Widget _buildPlansSection(double contentWidth) {
    final columns = _columnsFor(contentWidth);

    if (_isLoading) {
      return _PlanSkeletonRow(columns: columns);
    }

    if (_loadError != null && allPlans.isEmpty) {
      return _StateCard(
        icon: Icons.cloud_off_outlined,
        iconColor: Theme.of(context).colorScheme.error,
        title: "Unable to load plans",
        message: _loadError!,
        action: OutlinedButton.icon(
          onPressed: _loadPlans,
          style: OutlinedButton.styleFrom(
            foregroundColor: _kBrand,
            side: const BorderSide(color: _kBorder),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text("Try again"),
        ),
      );
    }

    if (filteredPlans.isEmpty) {
      final noData = allPlans.isEmpty;
      return _StateCard(
        icon: noData ? Icons.inventory_2_outlined : Icons.search_off_rounded,
        iconColor: _kBrand,
        title: "No plans found",
        message: noData
            ? "Create your first customer subscription plan to get started."
            : "No plans match your search or status filter. Change the filters or clear them to see all plans.",
        action: noData
            ? FilledButton.icon(
          onPressed: _openCreatePlanDialog,
          style: FilledButton.styleFrom(
            backgroundColor: _kBrand,
            foregroundColor: Colors.white,
            padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text("Create Plan"),
        )
            : OutlinedButton.icon(
          onPressed: resetFilters,
          style: OutlinedButton.styleFrom(
            foregroundColor: _kBody,
            side: const BorderSide(color: _kBorder),
            padding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
          label: const Text("Clear filters"),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildResultsBar(),
        const SizedBox(height: 18),
        _PlanCardsGrid(
          plans: paginatedPlans,
          columns: columns,
          accentColors: _cardAccents,
          icons: _cardIcons,
          onView: _showPlanDetails,
        ),
        const SizedBox(height: 28),
        _buildPagination(),
      ],
    );
  }

  Widget _buildResultsBar() {
    return Row(
      children: [
        Text(
          "All plans",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: _kInk,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: _kBrand.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "${filteredPlans.length}",
            style: const TextStyle(
              color: Color(0xFF4338CA),
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ),
        if (_hasActiveFilters) ...[
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              "filtered from ${allPlans.length}",
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _kMuted, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }

  // ==================== PAGINATION ====================
  Widget _buildPagination() {
    final total = filteredPlans.length;
    final start = total == 0 ? 0 : (currentPage - 1) * itemsPerPage + 1;
    final end = currentPage * itemsPerPage > total
        ? total
        : currentPage * itemsPerPage;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: "Showing "),
                TextSpan(
                  text: "$start–$end",
                  style: const TextStyle(
                      color: _kInk, fontWeight: FontWeight.w600),
                ),
                const TextSpan(text: " of "),
                TextSpan(
                  text: "$total",
                  style: const TextStyle(
                      color: _kInk, fontWeight: FontWeight.w600),
                ),
                TextSpan(text: total == 1 ? " plan" : " plans"),
              ],
            ),
            style: const TextStyle(fontSize: 13, color: _kMuted),
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildPageButtonPrevNext(prev: true),
              ..._buildPageNumbers(),
              _buildPageButtonPrevNext(prev: false),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    if (totalPages <= 5) {
      return List.generate(totalPages, (index) => _buildPageButton(index + 1));
    } else if (currentPage <= 3) {
      return [
        ...List.generate(4, (index) => _buildPageButton(index + 1)),
        _buildEllipsis(),
        _buildPageButton(totalPages),
      ];
    } else if (currentPage >= totalPages - 2) {
      return [
        _buildPageButton(1),
        _buildEllipsis(),
        ...List.generate(
            4, (index) => _buildPageButton(totalPages - 3 + index)),
      ];
    } else {
      return [
        _buildPageButton(1),
        _buildEllipsis(),
        _buildPageButton(currentPage - 1),
        _buildPageButton(currentPage),
        _buildPageButton(currentPage + 1),
        _buildEllipsis(),
        _buildPageButton(totalPages),
      ];
    }
  }

  Widget _buildPageButtonPrevNext({required bool prev}) {
    final enabled = prev ? currentPage > 1 : currentPage < totalPages;
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        tooltip: prev ? 'Previous page' : 'Next page',
        icon: Icon(
          prev ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
          size: 20,
        ),
        onPressed: enabled ? (prev ? previousPage : nextPage) : null,
        color: _kBrand,
        disabledColor: _kFaint,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          side: const BorderSide(color: _kBorder),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildPageButton(int pageNum) {
    final selected = currentPage == pageNum;
    final shape =
    RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
    return SizedBox(
      width: 36,
      height: 36,
      child: selected
          ? FilledButton(
        onPressed: () => goToPage(pageNum),
        style: FilledButton.styleFrom(
          backgroundColor: _kBrand,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          minimumSize: const Size(36, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: shape,
        ),
        child: Text(
          '$pageNum',
          style:
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      )
          : TextButton(
        onPressed: () => goToPage(pageNum),
        style: TextButton.styleFrom(
          foregroundColor: _kInk,
          padding: EdgeInsets.zero,
          minimumSize: const Size(36, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: shape,
        ),
        child: Text(
          '$pageNum',
          style:
          const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildEllipsis() {
    return const SizedBox(
      width: 20,
      height: 36,
      child: Center(
        child: Text(
          "...",
          style: TextStyle(fontSize: 13, color: _kMuted),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _enquiryLimitController.dispose();
    _durationController.dispose();
    _filterNameController.dispose();
    _service.dispose();
    super.dispose();
  }
}

// ==================== STATUS BADGE ====================
class _StatusBadge extends StatelessWidget {
  final bool active;

  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    final dot = active ? _kSuccess : _kFaint;
    final text = active ? const Color(0xFF047857) : _kBody;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (active ? _kSuccess : _kMuted).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            active ? "Active" : "Inactive",
            style: TextStyle(
              color: text,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== EMPTY / ERROR STATE CARD ====================
class _StateCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final Widget? action;

  const _StateCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: iconColor),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: _kInk,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style:
              const TextStyle(color: _kMuted, fontSize: 13.5, height: 1.5),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 22),
            action!,
          ],
        ],
      ),
    );
  }
}

// ==================== LOADING SKELETON ====================
class _PlanSkeletonRow extends StatefulWidget {
  final int columns;

  const _PlanSkeletonRow({required this.columns});

  @override
  State<_PlanSkeletonRow> createState() => _PlanSkeletonRowState();
}

class _PlanSkeletonRowState extends State<_PlanSkeletonRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  late final Animation<double> _opacity = Tween<double>(begin: 0.45, end: 1.0)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _bar({double? width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _kBorder,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _skeletonCard() {
    return Container(
      height: 380,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _kBorder),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(44),
          topRight: Radius.circular(6),
          bottomLeft: Radius.circular(6),
          bottomRight: Radius.circular(44),
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: _bar(width: 60, height: 20),
          ),
          const SizedBox(height: 16),
          _bar(width: 120, height: 38),
          const SizedBox(height: 10),
          _bar(width: 80, height: 10),
          const SizedBox(height: 28),
          _bar(height: 10),
          const SizedBox(height: 18),
          _bar(height: 10),
          const SizedBox(height: 18),
          _bar(height: 10),
          const Spacer(),
          Container(
            width: 56,
            height: 56,
            decoration:
            const BoxDecoration(color: _kBorder, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < widget.columns; i++) {
      if (i > 0) children.add(const SizedBox(width: 20));
      children.add(Expanded(child: _skeletonCard()));
    }
    return FadeTransition(
      opacity: _opacity,
      child: Row(children: children),
    );
  }
}

// ==================== PLAN CARDS GRID ====================
class _PlanCardsGrid extends StatelessWidget {
  final List<CustomerSubscriptionPlanData> plans;
  final int columns;
  final List<Color> accentColors;
  final List<IconData> icons;
  final void Function(
      CustomerSubscriptionPlanData plan, Color accent, IconData icon) onView;

  const _PlanCardsGrid({
    required this.plans,
    required this.columns,
    required this.accentColors,
    required this.icons,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    const spacing = 22.0;
    final rows = <Widget>[];

    for (var start = 0; start < plans.length; start += columns) {
      final rowChildren = <Widget>[];
      for (var c = 0; c < columns; c++) {
        if (c > 0) rowChildren.add(const SizedBox(width: spacing));
        final index = start + c;
        if (index < plans.length) {
          final plan = plans[index];
          final accentIndex = plan.id.abs() % accentColors.length;
          final accent = accentColors[accentIndex];
          final icon = icons[accentIndex % icons.length];
          rowChildren.add(
            Expanded(
              child: _PremiumPlanCard(
                plan: plan,
                accent: accent,
                icon: icon,
                onView: () => onView(plan, accent, icon),
              ),
            ),
          );
        } else {
          rowChildren.add(const Expanded(child: SizedBox.shrink()));
        }
      }
      if (rows.isNotEmpty) rows.add(const SizedBox(height: spacing));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rowChildren,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

// ==================== PREMIUM PLAN CARD ====================
class _PremiumPlanCard extends StatefulWidget {
  final CustomerSubscriptionPlanData plan;
  final Color accent;
  final IconData icon;
  final VoidCallback onView;

  const _PremiumPlanCard({
    required this.plan,
    required this.accent,
    required this.icon,
    required this.onView,
  });

  @override
  State<_PremiumPlanCard> createState() => _PremiumPlanCardState();
}

class _PremiumPlanCardState extends State<_PremiumPlanCard> {
  bool _hovering = false;

  static const BorderRadius _outerRadius = BorderRadius.only(
    topLeft: Radius.circular(44),
    topRight: Radius.circular(6),
    bottomLeft: Radius.circular(6),
    bottomRight: Radius.circular(44),
  );

  static const BorderRadius _innerRadius = BorderRadius.only(
    topLeft: Radius.circular(34),
    topRight: Radius.circular(4),
    bottomLeft: Radius.circular(4),
    bottomRight: Radius.circular(34),
  );

  Widget _featureLine(String text, {bool muted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(Icons.check_rounded, size: 16, color: widget.accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: muted ? _kFaint : _kBody,
                fontStyle: muted ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dashedDivider() {
    return const SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashedLinePainter(Color(0xFFCBD5E1))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final accent = widget.accent;
    final ring = Color.lerp(accent, Colors.black, 0.25)!;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovering ? -4 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: _outerRadius,
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(_hovering ? 0.30 : 0.16),
              blurRadius: _hovering ? 28 : 16,
              offset: Offset(0, _hovering ? 14 : 8),
            ),
          ],
        ),
        child: Material(
          color: accent,
          borderRadius: _outerRadius,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 4, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Inner white panel
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: _innerRadius,
                    ),
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: _StatusBadge(active: plan.isActive),
                        ),
                        const SizedBox(height: 10),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: plan.formattedPrice,
                                style: TextStyle(
                                  fontSize: 34,
                                  height: 1.0,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -1,
                                  color: accent,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Plan price",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: _kMuted),
                        ),
                        const SizedBox(height: 16),
                        _dashedDivider(),
                        _featureLine(_validityLabel(plan.durationDays)),
                        _dashedDivider(),
                        _featureLine("${plan.enquiryLimit} enquiries included"),
                        _dashedDivider(),
                        _featureLine("Reference ID #${plan.id}"),
                        _dashedDivider(),
                        const Spacer(),
                        const SizedBox(height: 20),
                        Center(
                          child: AnimatedScale(
                            scale: _hovering ? 1.06 : 1.0,
                            duration: const Duration(milliseconds: 180),
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                                border: Border.all(color: ring, width: 4),
                                boxShadow: [
                                  BoxShadow(
                                    color: accent.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(widget.icon,
                                  color: Colors.white, size: 26),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Footer: name tab + details action
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 26, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              plan.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Tooltip(
                        message: 'View plan details',
                        child: TextButton.icon(
                          onPressed: widget.onView,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          icon:
                          const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text(
                            "Details",
                            style: TextStyle(fontWeight: FontWeight.w600),
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

  String _validityLabel(int days) {
    if (days <= 0) return 'Validity not configured';
    if (days % 365 == 0) {
      final y = days ~/ 365;
      return 'Valid for $y ${y == 1 ? 'year' : 'years'} ($days days)';
    }
    if (days % 30 == 0) {
      final m = days ~/ 30;
      return 'Valid for $m ${m == 1 ? 'month' : 'months'} ($days days)';
    }
    if (days % 7 == 0) {
      final w = days ~/ 7;
      return 'Valid for $w ${w == 1 ? 'week' : 'weeks'} ($days days)';
    }
    return 'Valid for $days ${days == 1 ? 'day' : 'days'}';
  }
}

// ==================== DASHED DIVIDER PAINTER ====================
class _DashedLinePainter extends CustomPainter {
  final Color color;

  const _DashedLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dash = 4.0;
    const gap = 3.0;
    final y = size.height / 2;
    double x = 0;
    while (x < size.width) {
      final endX = (x + dash) > size.width ? size.width : x + dash;
      canvas.drawLine(Offset(x, y), Offset(endX, y), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}