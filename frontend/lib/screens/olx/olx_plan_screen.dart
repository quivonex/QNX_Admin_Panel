// lib/screens/olx/olx_plans_pricing_screen.dart
//
// OLX Plans & Pricing — ONE screen that replaces the two separate tabs
// "OLX Plan" and "OLX Pricing".
//
// How it works (master → detail):
//   1. Pick a plan on the left (or create a new one).
//   2. On the right you see that plan and the price it has for every
//      OLX category:  "Priced"  vs  "Not priced yet".
//   3. Tap a not-priced category (or "Add Pricing") to set its price.
//
// Existing APIs / models are reused unchanged:
//   OlxPlanPricingService.getPlans / createPlan / getPricingByPlan / createPricing
//   OlxCategoryService.getCategories

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../api/olx_service.dart';
import '../../models/olx/olx_category_model.dart';
import '../../models/olx/olx_plan_model.dart';
import '../../models/olx/olx_pricing_model.dart';

// ---------------------------------------------------------------------------
// Palette — same colours as the other OLX / Plan screens.
// ---------------------------------------------------------------------------
const Color _kBrand = Color(0xFF6366F1);
const Color _kInk = Color(0xFF1E293B);
const Color _kBody = Color(0xFF475569);
const Color _kMuted = Color(0xFF64748B);
const Color _kFaint = Color(0xFF94A3B8);
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kCanvas = Color(0xFFF8FAFC);
const Color _kSuccess = Color(0xFF10B981);

const List<Color> _kAccents = [
  Color(0xFF10B981), // emerald
  Color(0xFF0EA5E9), // sky
  Color(0xFF1E3A5F), // deep navy
  Color(0xFF6366F1), // indigo
  Color(0xFF8B5CF6), // violet
  Color(0xFFF59E0B), // amber
];

Color _accentFor(OlxPlanData plan) => _kAccents[plan.id.abs() % _kAccents.length];

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// Tolerant readers (same approach as the old Plan screen) so the screen keeps
// working whatever int / String / nullable shape the model uses.
int _planDays(OlxPlanData plan) {
  final dynamic v = plan.durationDays;
  if (v is num) return v.toInt();
  return int.tryParse('${v ?? ''}') ?? 0;
}

String _planDescription(OlxPlanData plan) {
  final dynamic v = plan.description;
  return v == null ? '' : v.toString().trim();
}

String _validityLabel(int days) {
  if (days <= 0) return 'Validity not set';
  if (days % 365 == 0) {
    final y = days ~/ 365;
    return '$y ${y == 1 ? 'year' : 'years'}';
  }
  if (days % 30 == 0) {
    final m = days ~/ 30;
    return '$m ${m == 1 ? 'month' : 'months'}';
  }
  if (days % 7 == 0) {
    final w = days ~/ 7;
    return '$w ${w == 1 ? 'week' : 'weeks'}';
  }
  return '$days ${days == 1 ? 'day' : 'days'}';
}

String _formatPrice(String raw) {
  final value = double.tryParse(raw) ?? 0;
  return '₹${NumberFormat('#,##,##0.00', 'en_IN').format(value)}';
}

class OlxPlansPricingScreen extends StatefulWidget {
  const OlxPlansPricingScreen({super.key});

  @override
  State<OlxPlansPricingScreen> createState() => _OlxPlansPricingScreenState();
}

class _OlxPlansPricingScreenState extends State<OlxPlansPricingScreen> {
  final OlxPlanPricingService _service = OlxPlanPricingService();
  final OlxCategoryService _categoryService = OlxCategoryService();

  final TextEditingController _planSearchController = TextEditingController();
  final TextEditingController _pricingSearchController =
  TextEditingController();

  // ---- Data ----
  List<OlxPlanData> _plans = [];
  List<OlxCategory> _categories = [];
  List<OlxPricingData> _pricing = [];
  OlxPlanData? _selectedPlan;

  // ---- Loading / error flags ----
  bool _plansLoading = true;
  bool _plansError = false;
  bool _categoriesLoading = true;
  bool _categoriesError = false;
  bool _pricingLoading = false;
  String? _pricingError;
  int _pricingToken = 0; // ignores stale responses when plan changes quickly

  // ---- UI state ----
  String _planQuery = '';
  String _pricingQuery = '';
  int _tab = 0; // 0 = priced, 1 = not priced yet
  int _page = 1;
  static const int _perPage = 8;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _planSearchController.dispose();
    _pricingSearchController.dispose();
    _service.dispose();
    _categoryService.dispose();
    super.dispose();
  }

  // ======================================================================
  // DATA LOADING
  // ======================================================================
  Future<void> _loadAll() async {
    await Future.wait([_loadPlans(), _loadCategories()]);
  }

  Future<void> _loadPlans({int? selectPlanId}) async {
    setState(() {
      _plansLoading = true;
      _plansError = false;
    });
    try {
      final response = await _service.getPlans();
      if (!mounted) return;

      final list = [...response.data]..sort((a, b) {
        final byDays = a.durationDays.compareTo(b.durationDays);
        return byDays != 0 ? byDays : a.id.compareTo(b.id);
      });

      final failed = !response.success && list.isEmpty;

      OlxPlanData? next;
      if (list.isNotEmpty) {
        final wantedId = selectPlanId ?? _selectedPlan?.id;
        next = list.firstWhere(
              (p) => p.id == wantedId,
          orElse: () => list.first,
        );
      }

      setState(() {
        _plans = list;
        _plansLoading = false;
        _plansError = failed;
        _selectedPlan = next;
      });

      if (next != null) {
        await _loadPricing(next);
      } else {
        setState(() {
          _pricing = [];
          _pricingError = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _plansLoading = false;
        _plansError = true;
      });
      _showSnackBar('Failed to load plans', isError: true);
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _categoriesLoading = true;
      _categoriesError = false;
    });
    try {
      final response = await _categoryService.getCategories();
      if (!mounted) return;
      final list = [...response.data]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      setState(() {
        _categories = list;
        _categoriesLoading = false;
        _categoriesError = !response.success && list.isEmpty;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categoriesLoading = false;
        _categoriesError = true;
      });
    }
  }

  Future<void> _loadPricing(OlxPlanData plan) async {
    final token = ++_pricingToken;
    setState(() {
      _pricingLoading = true;
      _pricingError = null;
    });
    try {
      final response = await _service.getPricingByPlan(plan.id);
      if (!mounted || token != _pricingToken) return;

      final list = [...response.data]..sort((a, b) =>
          _categoryNameOf(a).toLowerCase().compareTo(
            _categoryNameOf(b).toLowerCase(),
          ));

      setState(() {
        _pricing = list;
        _pricingLoading = false;
        // Service returns a non-empty message only when the request failed.
        _pricingError =
        (!response.success && response.message.isNotEmpty && list.isEmpty)
            ? response.message
            : null;
      });
    } catch (e) {
      if (!mounted || token != _pricingToken) return;
      setState(() {
        _pricingLoading = false;
        _pricingError = 'Pricing could not be loaded.';
      });
    }
  }

  void _selectPlan(OlxPlanData plan) {
    if (_selectedPlan?.id == plan.id) return;
    setState(() {
      _selectedPlan = plan;
      _pricing = [];
      _tab = 0;
      _page = 1;
      _pricingQuery = '';
      _pricingSearchController.clear();
    });
    _loadPricing(plan);
  }

  // ======================================================================
  // DERIVED DATA
  // ======================================================================
  String _categoryNameOf(OlxPricingData p) {
    final name = (p.categoryName ?? '').trim();
    if (name.isNotEmpty) return name;
    for (final c in _categories) {
      if (c.id == p.categoryId) return c.name;
    }
    return 'Category #${p.categoryId}';
  }

  Set<int> get _pricedCategoryIds => _pricing.map((p) => p.categoryId).toSet();

  List<OlxCategory> get _unpricedCategories {
    final priced = _pricedCategoryIds;
    return _categories.where((c) => !priced.contains(c.id)).toList();
  }

  List<OlxPlanData> get _visiblePlans {
    final q = _planQuery.trim().toLowerCase();
    if (q.isEmpty) return _plans;
    return _plans
        .where((p) =>
    p.name.toLowerCase().contains(q) ||
        '${p.durationDays}'.contains(q) ||
        (p.description ?? '').toLowerCase().contains(q))
        .toList();
  }

  List<OlxPricingData> get _visiblePricing {
    final q = _pricingQuery.trim().toLowerCase();
    if (q.isEmpty) return _pricing;
    return _pricing
        .where((p) =>
    _categoryNameOf(p).toLowerCase().contains(q) ||
        '${p.price}'.contains(q))
        .toList();
  }

  // ======================================================================
  // SNACKBAR
  // ======================================================================
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

  // ======================================================================
  // CREATE PLAN DIALOG
  // ======================================================================
  Future<void> _openCreatePlanDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final daysController = TextEditingController();
    final descController = TextEditingController();
    bool isActive = true;
    bool submitting = false;
    String? formError;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setDialogState(() {
                submitting = true;
                formError = null;
              });
              final response = await _service.createPlan(
                OlxPlanRequest(
                  name: nameController.text.trim(),
                  durationDays: int.tryParse(daysController.text.trim()) ?? 0,
                  description: descController.text.trim(),
                  isActive: isActive,
                ),
              );
              if (!mounted) return;
              if (response.success) {
                Navigator.of(dialogContext).pop();
                _showSnackBar('Plan created successfully');
                await _loadPlans(selectPlanId: response.data?.id);
                // If the API did not return the new id, jump to the newest plan.
                if (response.data == null && _plans.isNotEmpty) {
                  final newest = _plans.reduce((a, b) => a.id > b.id ? a : b);
                  _selectPlan(newest);
                }
              } else {
                setDialogState(() {
                  submitting = false;
                  formError = response.message;
                });
              }
            }

            return _DialogShell(
              icon: Icons.post_add_rounded,
              title: 'Create Plan',
              subtitle: 'Add a new plan, then set its price per category',
              submitting: submitting,
              submitLabel: 'Create Plan',
              submittingLabel: 'Creating...',
              submitIcon: Icons.add_rounded,
              onSubmit: submit,
              onCancel: () => Navigator.of(dialogContext).pop(),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (formError != null) ...[
                      _ErrorBanner(message: formError!),
                      const SizedBox(height: 16),
                    ],
                    _LabeledField(
                      label: 'Plan Name',
                      required: true,
                      child: TextFormField(
                        controller: nameController,
                        enabled: !submitting,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(fontSize: 14, color: _kInk),
                        decoration: _inputDecoration(
                          hint: 'e.g. Premium',
                          icon: Icons.label_outline,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Plan Name is required'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LabeledField(
                      label: 'Duration (Days)',
                      required: true,
                      child: TextFormField(
                        controller: daysController,
                        enabled: !submitting,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        style: const TextStyle(fontSize: 14, color: _kInk),
                        decoration: _inputDecoration(
                          hint: 'e.g. 30',
                          icon: Icons.timer_outlined,
                        ),
                        validator: (v) {
                          final days = int.tryParse((v ?? '').trim());
                          if (days == null || days <= 0) {
                            return 'Enter a valid number of days';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _LabeledField(
                      label: 'Description',
                      required: false,
                      child: TextFormField(
                        controller: descController,
                        enabled: !submitting,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 14, color: _kInk),
                        decoration: _inputDecoration(
                          hint: 'What does this plan include?',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ActiveSwitchTile(
                      value: isActive,
                      enabled: !submitting,
                      onChanged: (v) => setDialogState(() => isActive = v),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    daysController.dispose();
    descController.dispose();
  }

  // ======================================================================
  // ADD PRICING DIALOG
  // ======================================================================
  Future<void> _openAddPricingDialog({OlxCategory? preselect}) async {
    final plan = _selectedPlan;
    if (plan == null) return;

    if (_categoriesLoading) {
      _showSnackBar('Categories are still loading, please wait a moment.');
      return;
    }
    final available = _unpricedCategories;
    if (_categories.isEmpty) {
      _showSnackBar(
        'No OLX categories found. Create a category first.',
        isError: true,
      );
      return;
    }
    if (available.isEmpty) {
      _showSnackBar('Every category already has a price for this plan.');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final priceController = TextEditingController();
    OlxCategory? category = (preselect != null && available.contains(preselect))
        ? preselect
        : null;
    bool isActive = true;
    bool submitting = false;
    String? formError;
    final accent = _accentFor(plan);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setDialogState(() {
                submitting = true;
                formError = null;
              });
              final response = await _service.createPricing(
                OlxPricingRequest(
                  categoryId: category!.id,
                  planId: plan.id,
                  price: num.tryParse(priceController.text.trim()) ?? 0,
                  isActive: isActive,
                ),
              );
              if (!mounted) return;
              if (response.success) {
                Navigator.of(dialogContext).pop();
                _showSnackBar('Pricing added for ${category!.name}');
                if (_selectedPlan?.id == plan.id) {
                  await _loadPricing(plan);
                }
              } else {
                setDialogState(() {
                  submitting = false;
                  formError = response.message;
                });
              }
            }

            return _DialogShell(
              icon: Icons.price_change_outlined,
              title: 'Add Pricing',
              subtitle: 'Set the price of a category for this plan',
              submitting: submitting,
              submitLabel: 'Save Pricing',
              submittingLabel: 'Saving...',
              submitIcon: Icons.check_rounded,
              onSubmit: submit,
              onCancel: () => Navigator.of(dialogContext).pop(),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (formError != null) ...[
                      _ErrorBanner(message: formError!),
                      const SizedBox(height: 16),
                    ],
                    // Plan (read-only)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accent.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.workspace_premium_outlined,
                                color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Plan',
                                  style:
                                  TextStyle(fontSize: 11.5, color: _kMuted),
                                ),
                                Text(
                                  '${plan.name}  •  ${_validityLabel(_planDays(plan))}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _kInk,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _LabeledField(
                      label: 'Category',
                      required: true,
                      child: DropdownButtonFormField<OlxCategory>(
                        value: category,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(12),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded,
                            color: _kMuted),
                        decoration: _inputDecoration(
                          hint: 'Choose a category',
                          icon: Icons.category_outlined,
                        ),
                        items: available
                            .map((c) => DropdownMenuItem<OlxCategory>(
                          value: c,
                          child: Text(c.name,
                              overflow: TextOverflow.ellipsis),
                        ))
                            .toList(),
                        onChanged: submitting
                            ? null
                            : (v) => setDialogState(() => category = v),
                        validator: (v) =>
                        v == null ? 'Please select a category' : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${available.length} of ${_categories.length} categories still need a price.',
                      style: const TextStyle(fontSize: 12, color: _kMuted),
                    ),
                    const SizedBox(height: 16),
                    _LabeledField(
                      label: 'Price (₹)',
                      required: true,
                      child: TextFormField(
                        controller: priceController,
                        enabled: !submitting,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                        ],
                        style: const TextStyle(fontSize: 14, color: _kInk),
                        decoration: _inputDecoration(
                          hint: 'e.g. 499',
                          icon: Icons.currency_rupee_rounded,
                        ),
                        validator: (v) {
                          final text = (v ?? '').trim();
                          if (text.isEmpty) return 'Price is required';
                          final price = double.tryParse(text);
                          if (price == null) return 'Enter a valid price';
                          if (price < 0) return 'Price cannot be negative';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ActiveSwitchTile(
                      value: isActive,
                      enabled: !submitting,
                      onChanged: (v) => setDialogState(() => isActive = v),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    priceController.dispose();
  }

  // ======================================================================
  // BUILD
  // ======================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCanvas,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isWide = width >= 960;
            final isMobile = width < 700;
            final pad = isMobile ? 16.0 : 28.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: pad,
                vertical: isMobile ? 18 : 26,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1360),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(isMobile),
                      const SizedBox(height: 22),
                      _buildBody(isWide),
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

  // ---------------------------------------------------------------- header
  Widget _buildHeader(bool isMobile) {
    final theme = Theme.of(context);

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OLX Plans & Pricing',
          style: theme.textTheme.headlineSmall?.copyWith(
            color: _kInk,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Create plans and set what each category pays — all in one place',
          style: theme.textTheme.bodyMedium?.copyWith(color: _kMuted),
        ),
      ],
    );

    final refresh = OutlinedButton.icon(
      onPressed: (_plansLoading || _pricingLoading) ? null : _loadAll,
      style: OutlinedButton.styleFrom(
        foregroundColor: _kBody,
        side: const BorderSide(color: _kBorder),
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.refresh_rounded, size: 18),
      label: const Text('Refresh'),
    );

    final create = FilledButton.icon(
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
      label: const Text('Create Plan'),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: refresh),
              const SizedBox(width: 10),
              Expanded(child: create),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: title),
        const SizedBox(width: 16),
        refresh,
        const SizedBox(width: 12),
        create,
      ],
    );
  }

  // ------------------------------------------------------------------ body
  Widget _buildBody(bool isWide) {
    if (_plansLoading && _plans.isEmpty) {
      return const _LoadingCard(label: 'Loading plans...');
    }

    if (_plansError && _plans.isEmpty) {
      return _StateCard(
        icon: Icons.cloud_off_outlined,
        iconColor: Theme.of(context).colorScheme.error,
        title: 'Could not load plans',
        message:
        'Check your connection and try again. If no plan exists yet, create your first one.',
        actions: [
          OutlinedButton.icon(
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
          ),
          FilledButton.icon(
            onPressed: _openCreatePlanDialog,
            style: FilledButton.styleFrom(backgroundColor: _kBrand),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create Plan'),
          ),
        ],
      );
    }

    if (_plans.isEmpty) {
      return _StateCard(
        icon: Icons.workspace_premium_outlined,
        iconColor: _kBrand,
        title: 'No plans yet',
        message:
        'Start by creating a plan (for example 30 days). After that you can set a price for every category.',
        actions: [
          FilledButton.icon(
            onPressed: _openCreatePlanDialog,
            style: FilledButton.styleFrom(backgroundColor: _kBrand),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Create your first plan'),
          ),
        ],
      );
    }

    final detail = _buildPlanDetail();

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 340, child: _buildPlanList()),
          const SizedBox(width: 24),
          Expanded(child: detail),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildPlanPickerCompact(),
        const SizedBox(height: 18),
        detail,
      ],
    );
  }

  // ------------------------------------------------- plan list (wide, left)
  Widget _buildPlanList() {
    final plans = _visiblePlans;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text(
                'Plans',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                ),
              ),
              const SizedBox(width: 8),
              _CountPill(count: _plans.length),
              const Spacer(),
              if (_plansLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _planSearchController,
            style: const TextStyle(fontSize: 14, color: _kInk),
            decoration: _inputDecoration(
              hint: 'Search plans',
              icon: Icons.search_rounded,
            ).copyWith(
              isDense: true,
              suffixIcon: _planQuery.isNotEmpty
                  ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  _planSearchController.clear();
                  setState(() => _planQuery = '');
                },
              )
                  : null,
            ),
            onChanged: (v) => setState(() => _planQuery = v),
          ),
          const SizedBox(height: 12),
          if (plans.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Center(
                child: Text(
                  'No plan matches your search',
                  style: TextStyle(color: _kMuted, fontSize: 13),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 620),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: plans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final plan = plans[i];
                  return _PlanTile(
                    plan: plan,
                    accent: _accentFor(plan),
                    selected: _selectedPlan?.id == plan.id,
                    onTap: () => _selectPlan(plan),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------- plan picker (mobile / tablet)
  Widget _buildPlanPickerCompact() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Text(
                  'Choose a plan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  ),
                ),
                const SizedBox(width: 8),
                _CountPill(count: _plans.length),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _plans.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final plan = _plans[i];
                final accent = _accentFor(plan);
                final selected = _selectedPlan?.id == plan.id;
                return ChoiceChip(
                  selected: selected,
                  showCheckmark: false,
                  onSelected: (_) => _selectPlan(plan),
                  selectedColor: accent,
                  backgroundColor: _kCanvas,
                  side: BorderSide(color: selected ? accent : _kBorder),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  label: Text(
                    '${plan.name} • ${_validityLabel(_planDays(plan))}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: selected ? Colors.white : _kBody,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------- plan detail
  Widget _buildPlanDetail() {
    final plan = _selectedPlan;
    if (plan == null) {
      return const _StateCard(
        icon: Icons.touch_app_outlined,
        iconColor: _kBrand,
        title: 'Select a plan',
        message: 'Pick a plan to see and manage its category prices.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHero(plan),
        const SizedBox(height: 18),
        _buildPricingPanel(plan),
      ],
    );
  }

  Widget _buildHero(OlxPlanData plan) {
    final accent = _accentFor(plan);
    final total = _categories.length;
    final priced = _categories
        .where((c) => _pricedCategoryIds.contains(c.id))
        .length;
    final progress = total == 0 ? 0.0 : priced / total;
    final desc = _planDescription(plan);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, Color.lerp(accent, Colors.black, 0.28)!],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final narrow = c.maxWidth < 560;

          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    plan.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  _HeroChip(
                    icon: Icons.schedule_rounded,
                    label: _validityLabel(_planDays(plan)),
                  ),
                  _HeroChip(
                    icon: Icons.tag_rounded,
                    label: '${_planDays(plan)} days',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                desc.isEmpty ? 'No description provided' : desc,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13.5,
                  height: 1.45,
                  fontStyle: desc.isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ],
          );

          final coverage = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _categoriesLoading
                          ? 'Checking categories...'
                          : '$priced of $total categories priced',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _categoriesLoading ? null : progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.25),
                  valueColor:
                  const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          );

          final addButton = FilledButton.icon(
            onPressed: _pricingLoading ? null : () => _openAddPricingDialog(),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: accent,
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Add Pricing'),
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                info,
                const SizedBox(height: 18),
                coverage,
                const SizedBox(height: 16),
                SizedBox(width: double.infinity, child: addButton),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: info),
                  const SizedBox(width: 16),
                  addButton,
                ],
              ),
              const SizedBox(height: 20),
              coverage,
            ],
          );
        },
      ),
    );
  }

  // ----------------------------------------------------- pricing panel
  Widget _buildPricingPanel(OlxPlanData plan) {
    final unpriced = _unpricedCategories;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.sell_outlined, color: _kBrand, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Category pricing',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kInk,
                ),
              ),
              const Spacer(),
              if (_pricingLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: _kBrand,
                selectedForegroundColor: Colors.white,
                foregroundColor: _kBody,
                side: const BorderSide(color: _kBorder),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              segments: [
                ButtonSegment<int>(
                  value: 0,
                  icon: const Icon(Icons.check_circle_outline_rounded,
                      size: 18),
                  label: Text('Priced (${_pricing.length})'),
                ),
                ButtonSegment<int>(
                  value: 1,
                  icon: const Icon(Icons.pending_outlined, size: 18),
                  label: Text(
                    _categoriesLoading
                        ? 'Not priced yet'
                        : 'Not priced yet (${unpriced.length})',
                  ),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (s) => setState(() {
                _tab = s.first;
                _page = 1;
              }),
            ),
          ),
          const SizedBox(height: 16),
          if (_pricingError != null)
            _InlineMessage(
              icon: Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              message: _pricingError!,
              actionLabel: 'Retry',
              onAction: () => _loadPricing(plan),
            )
          else if (_tab == 0)
            _buildPricedList(plan)
          else
            _buildUnpricedList(unpriced),
        ],
      ),
    );
  }

  Widget _buildPricedList(OlxPlanData plan) {
    if (_pricingLoading && _pricing.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: _kBrand)),
      );
    }

    if (_pricing.isEmpty) {
      return _InlineEmpty(
        icon: Icons.price_change_outlined,
        title: 'No prices set for this plan yet',
        message:
        'Add a price for each category so users know what this plan costs.',
        actionLabel: 'Add first price',
        onAction: () => _openAddPricingDialog(),
      );
    }

    final filtered = _visiblePricing;
    final totalPages =
    (filtered.length / _perPage).ceil().clamp(1, 9999).toInt();
    final page = _page.clamp(1, totalPages).toInt();
    final start = (page - 1) * _perPage;
    final end = (start + _perPage) > filtered.length
        ? filtered.length
        : start + _perPage;
    final pageItems = filtered.isEmpty
        ? <OlxPricingData>[]
        : filtered.sublist(start, end);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _pricingSearchController,
          style: const TextStyle(fontSize: 14, color: _kInk),
          decoration: _inputDecoration(
            hint: 'Search category or price',
            icon: Icons.search_rounded,
          ).copyWith(
            isDense: true,
            suffixIcon: _pricingQuery.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              onPressed: () {
                _pricingSearchController.clear();
                setState(() {
                  _pricingQuery = '';
                  _page = 1;
                });
              },
            )
                : null,
          ),
          onChanged: (v) => setState(() {
            _pricingQuery = v;
            _page = 1;
          }),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 28),
            child: Center(
              child: Text(
                'No category matches your search',
                style: TextStyle(color: _kMuted, fontSize: 13),
              ),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, c) {
              final twoCols = c.maxWidth >= 640;
              const gap = 12.0;
              final itemWidth =
              twoCols ? (c.maxWidth - gap) / 2 : c.maxWidth;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final p in pageItems)
                    SizedBox(
                      width: itemWidth,
                      child: _PricingTile(
                        name: _categoryNameOf(p),
                        slug: p.categorySlug,
                        price: _formatPrice('${p.price}'),
                        active: p.isActive,
                        accent: _accentFor(plan),
                      ),
                    ),
                ],
              );
            },
          ),
        if (filtered.length > _perPage) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Showing ${start + 1}–$end of ${filtered.length}',
                  style: const TextStyle(fontSize: 13, color: _kMuted),
                ),
              ),
              IconButton(
                tooltip: 'Previous page',
                onPressed: page > 1 ? () => setState(() => _page = page - 1) : null,
                icon: const Icon(Icons.chevron_left_rounded),
                color: _kBrand,
              ),
              Text(
                '$page / $totalPages',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _kInk,
                  fontSize: 13,
                ),
              ),
              IconButton(
                tooltip: 'Next page',
                onPressed: page < totalPages
                    ? () => setState(() => _page = page + 1)
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
                color: _kBrand,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildUnpricedList(List<OlxCategory> unpriced) {
    if (_categoriesLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: _kBrand)),
      );
    }

    if (_categoriesError) {
      return _InlineMessage(
        icon: Icons.error_outline,
        color: Theme.of(context).colorScheme.error,
        message: 'Categories could not be loaded.',
        actionLabel: 'Retry',
        onAction: _loadCategories,
      );
    }

    if (_categories.isEmpty) {
      return const _InlineEmpty(
        icon: Icons.category_outlined,
        title: 'No OLX categories yet',
        message: 'Create OLX categories first, then come back to set prices.',
      );
    }

    if (unpriced.isEmpty) {
      return const _InlineEmpty(
        icon: Icons.verified_outlined,
        iconColor: _kSuccess,
        title: 'All categories are priced',
        message: 'Every OLX category has a price for this plan.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tap a category to set its price',
          style: TextStyle(fontSize: 13, color: _kMuted),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final c in unpriced)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _openAddPricingDialog(preselect: c),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _kCanvas,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          c.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: _kInk,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.add_circle_outline_rounded,
                          size: 18, color: _kBrand),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ===========================================================================
// SHARED STYLE HELPERS
// ===========================================================================
BoxDecoration _cardDecoration() => BoxDecoration(
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
);

InputDecoration _inputDecoration({String? hint, IconData? icon}) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: _kFaint, fontSize: 13.5),
    prefixIcon: icon == null ? null : Icon(icon, color: _kMuted, size: 20),
    filled: true,
    fillColor: _kCanvas,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: border(_kBorder),
    enabledBorder: border(_kBorder),
    disabledBorder: border(_kBorder),
    focusedBorder: border(_kBrand, 1.6),
    errorBorder: border(Colors.red.shade400),
    focusedErrorBorder: border(Colors.red.shade400, 1.6),
  );
}

// ===========================================================================
// SMALL WIDGETS
// ===========================================================================
class _CountPill extends StatelessWidget {
  final int count;
  const _CountPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
      decoration: BoxDecoration(
        color: _kBrand.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Color(0xFF4338CA),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool active;
  const _StatusBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
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
            decoration: BoxDecoration(
              color: active ? _kSuccess : _kFaint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            active ? 'Active' : 'Inactive',
            style: TextStyle(
              color: active ? const Color(0xFF047857) : _kBody,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  final OlxPlanData plan;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  const _PlanTile({
    required this.plan,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final desc = _planDescription(plan);
    return Material(
      color: selected ? accent.withOpacity(0.08) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? accent : _kBorder,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                child: const Icon(Icons.workspace_premium_outlined,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: _kInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc.isEmpty
                          ? _validityLabel(_planDays(plan))
                          : '${_validityLabel(_planDays(plan))} • $desc',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12.5, color: _kMuted),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PricingTile extends StatelessWidget {
  final String name;
  final String? slug;
  final String price;
  final bool active;
  final Color accent;

  const _PricingTile({
    required this.name,
    required this.slug,
    required this.price,
    required this.active,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              initial,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _StatusBadge(active: active),
                    if ((slug ?? '').isNotEmpty)
                      Text(
                        slug!,
                        style: const TextStyle(fontSize: 11.5, color: _kFaint),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            price,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  final String label;
  const _LoadingCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 70),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          const CircularProgressIndicator(color: _kBrand),
          const SizedBox(height: 16),
          Text(label, style: const TextStyle(color: _kMuted, fontSize: 13.5)),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final List<Widget> actions;

  const _StateCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
      decoration: _cardDecoration(),
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
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 22),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InlineEmpty({
    required this.icon,
    this.iconColor = _kBrand,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: iconColor),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _kInk,
            ),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style:
              const TextStyle(color: _kMuted, fontSize: 13, height: 1.5),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: _kBrand,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _InlineMessage({
    required this.icon,
    required this.color,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: TextStyle(color: color, fontSize: 13, height: 1.4)),
          ),
          TextButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final bool required;
  final Widget child;

  const _LabeledField({
    required this.label,
    required this.required,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(text: label),
              if (required)
                TextSpan(text: ' *', style: TextStyle(color: errorColor))
              else
                const TextSpan(
                  text: '  (optional)',
                  style: TextStyle(color: _kFaint, fontWeight: FontWeight.w400),
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
        child,
      ],
    );
  }
}

class _ActiveSwitchTile extends StatelessWidget {
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ActiveSwitchTile({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _kCanvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          Icon(
            value
                ? Icons.check_circle_outline_rounded
                : Icons.pause_circle_outline_rounded,
            color: value ? _kSuccess : _kMuted,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active status',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _kInk,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value ? 'Will be saved as active' : 'Will be saved as inactive',
                  style: const TextStyle(color: _kMuted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeTrackColor: _kBrand,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

/// Common dialog frame (header / scrollable body / footer) used by both the
/// "Create Plan" and "Add Pricing" popups.
class _DialogShell extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool submitting;
  final String submitLabel;
  final String submittingLabel;
  final IconData submitIcon;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final Widget child;

  const _DialogShell({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.submitting,
    required this.submitLabel,
    required this.submittingLabel,
    required this.submitIcon,
    required this.onSubmit,
    required this.onCancel,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context).size;
    final isSmall = media.width < 640;
    final width = isSmall ? media.width : 540.0;

    final cancel = OutlinedButton(
      onPressed: submitting ? null : onCancel,
      style: OutlinedButton.styleFrom(
        foregroundColor: _kBody,
        side: const BorderSide(color: _kBorder),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text('Cancel'),
    );

    final submit = FilledButton.icon(
      onPressed: submitting ? null : onSubmit,
      style: FilledButton.styleFrom(
        backgroundColor: _kBrand,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _kBrand.withOpacity(0.6),
        disabledForegroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: submitting
          ? const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      )
          : Icon(submitIcon, size: 20),
      label: Text(
        submitting ? submittingLabel : submitLabel,
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
          maxWidth: width,
          maxHeight: media.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                    child: Icon(icon, color: _kBrand, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _kInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: _kMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: submitting ? null : onCancel,
                    icon: const Icon(Icons.close_rounded, color: _kMuted),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: child,
              ),
            ),
            const Divider(height: 1, color: _kBorder),
            Container(
              color: _kCanvas,
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 18),
              child: Row(
                children: isSmall
                    ? [
                  Expanded(child: cancel),
                  const SizedBox(width: 12),
                  Expanded(child: submit),
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
                      style:
                      const TextStyle(color: _kMuted, fontSize: 12.5),
                    ),
                  ),
                  cancel,
                  const SizedBox(width: 12),
                  submit,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}