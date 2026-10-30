// lib/screens/qnx_admin/ai_admin_screen.dart

import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/ai_admin_service.dart';
import '../../models/ai_admin/ai_admin_model.dart';

// ============================================================
// DESIGN TOKENS
// ============================================================
class _C {
  static const bg = Color(0xFFF4F6FB);
  static const surface = Colors.white;
  static const border = Color(0xFFE6EAF2);
  static const ink = Color(0xFF0F172A);
  static const ink2 = Color(0xFF334155);
  static const muted = Color(0xFF64748B);
  static const faint = Color(0xFF94A3B8);
  static const track = Color(0xFFEEF1F7);
  static const primary = Color(0xFF6366F1);
  static const primaryDark = Color(0xFF4338CA);
  static const primarySoft = Color(0xFFEEF0FF);
  static const green = Color(0xFF10B981);
  static const greenSoft = Color(0xFFDCFCE7);
  static const red = Color(0xFFEF4444);
  static const redSoft = Color(0xFFFEE2E2);
  static const amber = Color(0xFFF59E0B);
  static const blue = Color(0xFF3B82F6);
  static const violet = Color(0xFF8B5CF6);
  static const pink = Color(0xFFEC4899);
  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1B4B), Color(0xFF3730A3), Color(0xFF6366F1)],
  );
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
  );
}

Color _a(Color c, double opacity) => c.withAlpha((opacity * 255).round());

List<BoxShadow> get _softShadow => [
  BoxShadow(
    color: _a(const Color(0xFF1E293B), 0.06),
    blurRadius: 18,
    offset: const Offset(0, 6),
  ),
];

// ============================================================
// SHARED HELPERS
// ============================================================
String _formatNumber(num? v) {
  if (v == null) return '0';
  final s = v.toInt().toString();
  if (s.length <= 3) return s;
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final buf = <String>[];
  while (rest.length > 2) {
    buf.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) buf.insert(0, rest);
  return '${buf.join(',')},$last3';
}

String _compact(num? v) {
  if (v == null) return '0';
  final n = v.toDouble();
  if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(1)}Cr';
  if (n >= 100000) return '${(n / 100000).toStringAsFixed(1)}L';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return n.toInt().toString();
}

String _formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '—';
  try {
    final d = DateTime.parse(dateStr).toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final day = d.day.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$day ${months[d.month - 1]} ${d.year}, $hh:$mm';
  } catch (_) {
    return dateStr;
  }
}

String _timeAgo(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return '—';
  try {
    final d = DateTime.parse(dateStr).toLocal();
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return _formatDate(dateStr);
  } catch (_) {
    return dateStr;
  }
}

IconData _serviceIcon(String service) {
  switch (service) {
    case 'mart':
      return Icons.shopping_bag_rounded;
    case 'remart':
      return Icons.autorenew_rounded;
    case 'realestate':
      return Icons.apartment_rounded;
    default:
      return Icons.chat_bubble_rounded;
  }
}

String _serviceLabel(String service) {
  switch (service) {
    case 'mart':
      return 'QNX Mart';
    case 'remart':
      return 'QNX ReMart';
    case 'realestate':
      return 'Real Estate';
    default:
      return 'General';
  }
}

Color _serviceColor(String service) {
  switch (service) {
    case 'mart':
      return _C.blue;
    case 'remart':
      return _C.green;
    case 'realestate':
      return _C.amber;
    default:
      return _C.violet;
  }
}

// ============================================================
// SCREEN
// ============================================================
class AiAdminScreen extends StatefulWidget {
  const AiAdminScreen({super.key});

  @override
  State<AiAdminScreen> createState() => _AiAdminScreenState();
}

class _AiAdminScreenState extends State<AiAdminScreen>
    with SingleTickerProviderStateMixin {
  final AiAdminService _service = AiAdminService();

  String? _token;
  bool _authorized = true;

  late final TabController _tabController;

  // Dashboard
  AiDashboardData? _dashboard;
  bool _dashboardLoading = false;

  // Conversations
  List<AiConversationRow> _conversations = [];
  int _conversationsCount = 0;
  bool _conversationsLoading = false;
  bool _conversationsLoaded = false;
  int _conversationPage = 1;
  final int _conversationPageSize = 20;
  final TextEditingController _filterSearchController = TextEditingController();
  String _filterService = '';
  String _filterArchived = '';
  String _filterDeleted = 'false';

  // Analytics
  AiAnalyticsData? _analytics;
  bool _analyticsLoading = false;
  int _analyticsDays = 7;

  // Usage
  AiUsageData? _usage;
  bool _usageLoading = false;

  // Settings
  AiSettingsData? _settings;
  bool _settingsLoading = false;
  bool _settingsSaving = false;
  bool _settingsDirty = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _ensureLoaded(_tabController.index);
        setState(() {});
      }
    });
    _loadToken();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _filterSearchController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
    final ok = _token != null && _token!.isNotEmpty;
    if (!mounted) return;
    setState(() => _authorized = ok);
    if (!ok) {
      _showSnackBar('Please login to access AI Admin', isError: true);
      return;
    }
    _loadDashboard();
  }

  void _ensureLoaded(int i) {
    if (i == 0 && _dashboard == null && !_dashboardLoading) _loadDashboard();
    if (i == 1 && !_conversationsLoaded && !_conversationsLoading) {
      _loadConversations();
    }
    if (i == 2 && _analytics == null && !_analyticsLoading) _loadAnalytics();
    if (i == 3 && _usage == null && !_usageLoading) _loadUsage();
    if (i == 4 && _settings == null && !_settingsLoading) _loadSettings();
  }

  Future<void> _refreshCurrent() async {
    switch (_tabController.index) {
      case 0:
        return _loadDashboard();
      case 1:
        return _loadConversations();
      case 2:
        return _loadAnalytics();
      case 3:
        return _loadUsage();
      case 4:
        return _loadSettings();
    }
  }

  // ------------------------------------------------------------
  // LOADERS
  // ------------------------------------------------------------
  Future<void> _loadDashboard() async {
    setState(() => _dashboardLoading = true);
    final res = await _service.getDashboard(token: _token);
    if (!mounted) return;
    setState(() {
      _dashboard = res;
      _dashboardLoading = false;
    });
  }

  Future<void> _loadSettings() async {
    setState(() => _settingsLoading = true);
    final res = await _service.getSettings(token: _token);
    if (!mounted) return;
    setState(() {
      _settings = res;
      _settingsLoading = false;
      _settingsDirty = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;
    setState(() => _settingsSaving = true);
    final res = await _service.updateSettings(_settings!, token: _token);
    if (!mounted) return;
    setState(() {
      if (res != null) {
        _settings = res;
        _settingsDirty = false;
      }
      _settingsSaving = false;
    });
    _showSnackBar(
      res != null ? 'Settings updated successfully' : 'Failed to update settings',
      isError: res == null,
    );
  }

  void _editSettings(AiSettingsData next) {
    setState(() {
      _settings = next;
      _settingsDirty = true;
    });
  }

  Future<void> _loadConversations() async {
    setState(() => _conversationsLoading = true);
    final res = await _service.getConversations(
      search: _filterSearchController.text.trim(),
      service: _filterService,
      isArchived: _filterArchived.isEmpty ? null : _filterArchived == 'true',
      isDeleted: _filterDeleted.isEmpty ? null : _filterDeleted == 'true',
      page: _conversationPage,
      pageSize: _conversationPageSize,
      token: _token,
    );
    if (!mounted) return;
    setState(() {
      _conversations = res?.results ?? [];
      _conversationsCount = res?.count ?? 0;
      _conversationsLoading = false;
      _conversationsLoaded = true;
    });
  }

  Future<void> _loadAnalytics() async {
    setState(() => _analyticsLoading = true);
    final res = await _service.getAnalytics(days: _analyticsDays, token: _token);
    if (!mounted) return;
    setState(() {
      _analytics = res;
      _analyticsLoading = false;
    });
  }

  Future<void> _loadUsage() async {
    setState(() => _usageLoading = true);
    final res = await _service.getUsage(token: _token);
    if (!mounted) return;
    setState(() {
      _usage = res;
      _usageLoading = false;
    });
  }

  // ------------------------------------------------------------
  // DETAIL SHEET
  // ------------------------------------------------------------
  void _openDetail(AiConversationRow conv) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints(maxWidth: 760),
      builder: (_) => _ConversationSheet(
        service: _service,
        token: _token,
        conversation: conv,
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(msg)),
            ],
          ),
          backgroundColor: isError ? const Color(0xFFDC2626) : _C.primaryDark,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  // ------------------------------------------------------------
  // DERIVED
  // ------------------------------------------------------------
  int _successRate() {
    if (_dashboard == null) return 0;
    final total = _dashboard!.messages.successful + _dashboard!.messages.failed;
    if (total == 0) return 0;
    return ((_dashboard!.messages.successful / total) * 100).round();
  }

  int _feedbackRate(int likes, int dislikes) {
    final total = likes + dislikes;
    if (total == 0) return 0;
    return ((likes / total) * 100).round();
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    if (!_authorized) {
      return Scaffold(
        backgroundColor: _C.bg,
        body: _EmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Please login to access AI Admin',
        ),
      );
    }

    return Scaffold(
      backgroundColor: _C.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _refreshable(_buildDashboardTab()),
                _refreshable(_buildConversationsTab()),
                _refreshable(_buildAnalyticsTab()),
                _refreshable(_buildUsageTab()),
                _refreshable(_buildSettingsTab()),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _tabController.index == 4 && _settings != null
          ? _buildSettingsSaveBar()
          : null,
    );
  }

  Widget _refreshable(Widget child) => RefreshIndicator(
    color: _C.primary,
    onRefresh: _refreshCurrent,
    child: child,
  );

  // ------------------------------------------------------------
  // HEADER + TABS
  // ------------------------------------------------------------
  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: _C.headerGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  if (Navigator.of(context).canPop())
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white),
                    ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _a(Colors.white, 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Admin',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        Text(
                          'Monitor assistant activity & settings',
                          style: TextStyle(color: Color(0xFFC7D2FE), fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _refreshCurrent,
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _a(Colors.white, 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  splashBorderRadius: BorderRadius.circular(12),
                  labelColor: _C.primaryDark,
                  unselectedLabelColor: const Color(0xFFE0E7FF),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelStyle:
                  const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  tabs: const [
                    _AdminTab(Icons.grid_view_rounded, 'Dashboard'),
                    _AdminTab(Icons.forum_rounded, 'Conversations'),
                    _AdminTab(Icons.insights_rounded, 'Analytics'),
                    _AdminTab(Icons.memory_rounded, 'AI Usage'),
                    _AdminTab(Icons.tune_rounded, 'Settings'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TAB 1: DASHBOARD
  // ============================================================
  Widget _buildDashboardTab() {
    if (_dashboardLoading && _dashboard == null) return const _Loading();
    if (_dashboard == null) {
      return _scrollable(_EmptyState(
        icon: Icons.cloud_off_rounded,
        title: 'Unable to load dashboard',
        onRetry: _loadDashboard,
      ));
    }

    final d = _dashboard!;
    final success = _successRate();
    final fbRate = _feedbackRate(d.feedback.likes, d.feedback.dislikes);
    final totalService =
    d.serviceUsage.fold<int>(0, (sum, s) => sum + s.count);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _StatGrid(
          childAspectRatio: 1.45,
          cards: [
            _StatCard(
              icon: Icons.forum_rounded,
              color: _C.blue,
              label: 'Conversations',
              value: _formatNumber(d.totalConversations),
              sub: '${d.today.conversations} today',
            ),
            _StatCard(
              icon: Icons.mark_chat_read_rounded,
              color: _C.violet,
              label: 'Messages',
              value: _formatNumber(d.totalMessages),
              sub: '${d.today.messages} today',
            ),
            _StatCard(
              icon: Icons.groups_rounded,
              color: _C.amber,
              label: 'Users',
              value: _formatNumber(d.totalUsers),
              sub: 'Total users',
            ),
            _StatCard(
              icon: Icons.verified_rounded,
              color: _C.green,
              label: 'Success rate',
              value: '$success%',
              sub: '${_formatNumber(d.messages.successful)} successful',
            ),
          ],
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth > 700;
          final status = _Panel(
            title: 'Message health',
            icon: Icons.monitor_heart_outlined,
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 110,
                      height: 110,
                      child: CustomPaint(
                        painter: _DonutPainter(
                          segments: [
                            _Seg(d.messages.successful.toDouble(), _C.green),
                            _Seg(d.messages.failed.toDouble(), _C.red),
                          ],
                          emptyColor: _C.track,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$success%',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: _C.ink)),
                              const Text('success',
                                  style:
                                  TextStyle(fontSize: 10.5, color: _C.faint)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        children: [
                          _LegendRow(
                              label: 'Successful',
                              color: _C.green,
                              value: _formatNumber(d.messages.successful)),
                          const SizedBox(height: 12),
                          _LegendRow(
                              label: 'Failed',
                              color: _C.red,
                              value: _formatNumber(d.messages.failed)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          final feedback = _Panel(
            title: 'User feedback',
            icon: Icons.thumbs_up_down_rounded,
            child: _FeedbackSummary(
              likes: d.feedback.likes,
              dislikes: d.feedback.dislikes,
              rate: fbRate,
            ),
          );

          if (wide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: status),
                const SizedBox(width: 16),
                Expanded(child: feedback),
              ],
            );
          }
          return Column(children: [
            status,
            const SizedBox(height: 16),
            feedback,
          ]);
        }),
        const SizedBox(height: 16),
        _Panel(
          title: 'Service usage',
          icon: Icons.pie_chart_rounded,
          child: d.serviceUsage.isEmpty
              ? const _InlineEmpty('No service usage yet')
              : Column(
            children: d.serviceUsage.map((s) {
              final pct =
              totalService == 0 ? 0.0 : s.count / totalService;
              return _ServiceBar(
                service: s.service,
                count: s.count,
                fraction: pct,
                trailing: '${(pct * 100).round()}%',
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ============================================================
  // TAB 2: CONVERSATIONS
  // ============================================================
  Widget _buildConversationsTab() {
    final totalPages = (_conversationsCount / _conversationPageSize).ceil();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _buildFilterBar(),
        const SizedBox(height: 14),
        if (_conversationsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: _Loading(),
          )
        else if (_conversations.isEmpty)
          _EmptyState(
            icon: Icons.inbox_rounded,
            title: 'No conversations found',
            subtitle: 'Try adjusting your filters',
            onRetry: _loadConversations,
          )
        else ...[
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                '${_formatNumber(_conversationsCount)} conversation${_conversationsCount == 1 ? '' : 's'}',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: _C.muted),
              ),
            ),
            ..._conversations.map(_conversationCard),
            const SizedBox(height: 4),
            _buildPagination(totalPages),
          ],
        const SizedBox(height: 24),
      ],
    );
  }

  void _applyFilters() {
    FocusScope.of(context).unfocus();
    _conversationPage = 1;
    _loadConversations();
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          TextField(
            controller: _filterSearchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _applyFilters(),
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by title…',
              hintStyle: const TextStyle(color: _C.faint),
              prefixIcon:
              const Icon(Icons.search_rounded, size: 20, color: _C.faint),
              suffixIcon: _filterSearchController.text.isEmpty
                  ? null
                  : IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  _filterSearchController.clear();
                  setState(() {});
                },
              ),
              filled: true,
              fillColor: _C.bg,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, c) {
            final narrow = c.maxWidth < 520;
            final service = _DropdownBox<String>(
              icon: Icons.apps_rounded,
              value: _filterService,
              items: const [
                DropdownMenuItem(value: '', child: Text('All services')),
                DropdownMenuItem(value: 'mart', child: Text('QNX Mart')),
                DropdownMenuItem(value: 'remart', child: Text('QNX ReMart')),
                DropdownMenuItem(value: 'realestate', child: Text('Real Estate')),
                DropdownMenuItem(value: 'general', child: Text('General')),
              ],
              onChanged: (v) => setState(() => _filterService = v ?? ''),
            );
            final archived = _DropdownBox<String>(
              icon: Icons.archive_outlined,
              value: _filterArchived,
              items: const [
                DropdownMenuItem(value: '', child: Text('All chats')),
                DropdownMenuItem(value: 'false', child: Text('Active')),
                DropdownMenuItem(value: 'true', child: Text('Archived')),
              ],
              onChanged: (v) => setState(() => _filterArchived = v ?? ''),
            );
            final deleted = _DropdownBox<String>(
              icon: Icons.delete_outline_rounded,
              value: _filterDeleted,
              items: const [
                DropdownMenuItem(value: '', child: Text('Deleted: any')),
                DropdownMenuItem(value: 'false', child: Text('Not deleted')),
                DropdownMenuItem(value: 'true', child: Text('Deleted')),
              ],
              onChanged: (v) => setState(() => _filterDeleted = v ?? ''),
            );

            if (narrow) {
              return Column(children: [
                service,
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: archived),
                  const SizedBox(width: 8),
                  Expanded(child: deleted),
                ]),
              ]);
            }
            return Row(children: [
              Expanded(child: service),
              const SizedBox(width: 8),
              Expanded(child: archived),
              const SizedBox(width: 8),
              Expanded(child: deleted),
            ]);
          }),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _applyFilters,
                  icon: const Icon(Icons.filter_alt_rounded, size: 18),
                  label: const Text('Apply filters'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _C.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _filterSearchController.clear();
                    _filterService = '';
                    _filterArchived = '';
                    _filterDeleted = 'false';
                    _conversationPage = 1;
                  });
                  _loadConversations();
                },
                icon: const Icon(Icons.restart_alt_rounded, size: 18),
                label: const Text('Reset'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _C.muted,
                  side: const BorderSide(color: _C.border),
                  padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _conversationCard(AiConversationRow c) {
    final name = c.user.name.isEmpty ? 'Unknown user' : c.user.name;
    final color = _serviceColor(c.activeService);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _C.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDetail(c),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _C.border),
            ),
            child: Row(
              children: [
                _Avatar(name: name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: _C.ink),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _timeAgo(c.lastMessageAt),
                            style: const TextStyle(
                                fontSize: 11, color: _C.faint),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        c.title.isEmpty ? '(No title)' : c.title,
                        style: const TextStyle(fontSize: 12.5, color: _C.muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _Pill(
                            icon: _serviceIcon(c.activeService),
                            text: _serviceLabel(c.activeService),
                            fg: color,
                            bg: _a(color, 0.12),
                          ),
                          const SizedBox(width: 8),
                          _Pill(
                            icon: Icons.chat_bubble_outline_rounded,
                            text: '${c.messageCount} msgs',
                            fg: _C.primary,
                            bg: _C.primarySoft,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right_rounded, color: _C.faint),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    final hasPrev = _conversationPage > 1;
    final hasNext = _conversationPage < totalPages;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton.filledTonal(
            onPressed: hasPrev
                ? () {
              setState(() => _conversationPage--);
              _loadConversations();
            }
                : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Page $_conversationPage of ${totalPages == 0 ? 1 : totalPages}',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13, color: _C.ink),
              ),
              Text(
                'Showing ${_conversations.length} of ${_formatNumber(_conversationsCount)}',
                style: const TextStyle(fontSize: 11, color: _C.faint),
              ),
            ],
          ),
          IconButton.filledTonal(
            onPressed: hasNext
                ? () {
              setState(() => _conversationPage++);
              _loadConversations();
            }
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TAB 3: ANALYTICS
  // ============================================================
  Widget _buildAnalyticsTab() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _SegmentedRange(
          value: _analyticsDays,
          options: const {7: '7 days', 30: '30 days', 90: '90 days'},
          onChanged: (v) {
            setState(() => _analyticsDays = v);
            _loadAnalytics();
          },
        ),
        const SizedBox(height: 16),
        if (_analyticsLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: _Loading(),
          )
        else if (_analytics == null)
          _EmptyState(
            icon: Icons.insights_rounded,
            title: 'No analytics data',
            onRetry: _loadAnalytics,
          )
        else
          ..._analyticsContent(),
        const SizedBox(height: 24),
      ],
    );
  }

  List<Widget> _analyticsContent() {
    final a = _analytics!;
    final total = a.dailyMessages.fold<int>(0, (s, e) => s + e.count);
    final totalService = a.serviceUsage.fold<int>(0, (s, e) => s + e.count);
    final likes = a.feedback?.likes ?? 0;
    final dislikes = a.feedback?.dislikes ?? 0;

    return [
      _Panel(
        title: 'Daily messages',
        icon: Icons.show_chart_rounded,
        trailing: a.period != null
            ? Text('${a.period!.from} → ${a.period!.to}',
            style: const TextStyle(
                fontSize: 11, color: _C.faint, fontWeight: FontWeight.w600))
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatNumber(total),
                  style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _C.ink,
                      height: 1),
                ),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(bottom: 3),
                  child: Text('messages in period',
                      style: TextStyle(fontSize: 12, color: _C.muted)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _BarChart(data: a.dailyMessages),
          ],
        ),
      ),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth > 700;
        final servicePanel = _Panel(
          title: 'Service usage',
          icon: Icons.pie_chart_rounded,
          child: a.serviceUsage.isEmpty
              ? const _InlineEmpty('No service usage in this period')
              : Column(
            children: a.serviceUsage.map((s) {
              final f = totalService == 0 ? 0.0 : s.count / totalService;
              return _ServiceBar(
                service: s.service,
                count: s.count,
                fraction: f,
                trailing: '${(f * 100).round()}%',
              );
            }).toList(),
          ),
        );
        final feedbackPanel = _Panel(
          title: 'Feedback',
          icon: Icons.thumbs_up_down_rounded,
          child: _FeedbackSummary(
            likes: likes,
            dislikes: dislikes,
            rate: _feedbackRate(likes, dislikes),
          ),
        );
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: servicePanel),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: feedbackPanel),
            ],
          );
        }
        return Column(children: [
          servicePanel,
          const SizedBox(height: 16),
          feedbackPanel,
        ]);
      }),
    ];
  }

  // ============================================================
  // TAB 4: USAGE
  // ============================================================
  Widget _buildUsageTab() {
    if (_usageLoading && _usage == null) return const _Loading();
    if (_usage == null) {
      return _scrollable(_EmptyState(
        icon: Icons.memory_rounded,
        title: 'No usage data',
        onRetry: _loadUsage,
      ));
    }

    final u = _usage!;
    final totalTok = u.totalTokens == 0 ? 1 : u.totalTokens;
    final promptShare = u.promptTokens / totalTok;
    final maxReq = u.models.isEmpty
        ? 1
        : u.models.map((m) => m.requests).reduce(math.max);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _StatGrid(
          childAspectRatio: 1.55,
          cards: [
            _StatCard(
              icon: Icons.bolt_rounded,
              color: _C.pink,
              label: 'Requests',
              value: _compact(u.totalRequests),
              sub: _formatNumber(u.totalRequests),
            ),
            _StatCard(
              icon: Icons.north_east_rounded,
              color: _C.blue,
              label: 'Prompt tokens',
              value: _compact(u.promptTokens),
              sub: _formatNumber(u.promptTokens),
            ),
            _StatCard(
              icon: Icons.south_east_rounded,
              color: _C.amber,
              label: 'Completion',
              value: _compact(u.completionTokens),
              sub: _formatNumber(u.completionTokens),
            ),
            _StatCard(
              icon: Icons.layers_rounded,
              color: _C.violet,
              label: 'Total tokens',
              value: _compact(u.totalTokens),
              sub: _formatNumber(u.totalTokens),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Performance',
          icon: Icons.speed_rounded,
          child: Column(
            children: [
              LayoutBuilder(builder: (context, c) {
                final items = [
                  _PerfItem(
                    icon: Icons.timer_outlined,
                    label: 'Average latency',
                    value: '${u.averageLatencyMs.toStringAsFixed(0)} ms',
                  ),
                  _PerfItem(
                    icon: Icons.memory_rounded,
                    label: 'Models in use',
                    value: '${u.models.length}',
                  ),
                ];
                return Row(children: [
                  Expanded(child: items[0]),
                  const SizedBox(width: 12),
                  Expanded(child: items[1]),
                ]);
              }),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Token split',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _C.muted)),
                  const Spacer(),
                  Text(
                    '${(promptShare * 100).round()}% prompt · ${(100 - promptShare * 100).round()}% completion',
                    style: const TextStyle(fontSize: 11.5, color: _C.faint),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      Expanded(
                        flex: (promptShare * 1000).round().clamp(1, 999),
                        child: Container(color: _C.blue),
                      ),
                      Expanded(
                        flex: ((1 - promptShare) * 1000).round().clamp(1, 999),
                        child: Container(color: _C.amber),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (u.models.isNotEmpty)
          _Panel(
            title: 'Models',
            icon: Icons.memory_rounded,
            child: Column(
              children: u.models.map((m) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _C.bg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.memory_rounded,
                              size: 16, color: _C.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              m.llmModel,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: _C.ink),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text('${_formatNumber(m.requests)} req',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _C.primary)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: m.requests / maxReq,
                          minHeight: 6,
                          backgroundColor: _C.track,
                          valueColor: const AlwaysStoppedAnimation(_C.primary),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _MiniMetric(
                                label: 'Prompt',
                                value: _formatNumber(m.promptTokens)),
                          ),
                          Expanded(
                            child: _MiniMetric(
                                label: 'Completion',
                                value: _formatNumber(m.completionTokens)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ============================================================
  // TAB 5: SETTINGS
  // ============================================================
  Widget _buildSettingsTab() {
    if (_settingsLoading && _settings == null) return const _Loading();
    if (_settings == null) {
      return _scrollable(_EmptyState(
        icon: Icons.tune_rounded,
        title: 'Unable to load settings',
        onRetry: _loadSettings,
      ));
    }

    final s = _settings!;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Master switch
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: s.isEnabled
                ? const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF10B981)])
                : const LinearGradient(
                colors: [Color(0xFF475569), Color(0xFF64748B)]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: _softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: _a(Colors.white, 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  s.isEnabled
                      ? Icons.power_settings_new_rounded
                      : Icons.power_off_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.isEnabled ? 'AI Assistant is ON' : 'AI Assistant is OFF',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Turn the whole assistant on or off',
                      style: TextStyle(color: _a(Colors.white, 0.85), fontSize: 12),
                    ),
                  ],
                ),
              ),
              Switch(
                value: s.isEnabled,
                onChanged: (v) => _editSettings(s.copyWith(isEnabled: v)),
                activeTrackColor: _a(Colors.white, 0.45),
                activeThumbColor: Colors.white,
                inactiveTrackColor: _a(Colors.white, 0.25),
                inactiveThumbColor: Colors.white,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Enabled services',
          icon: Icons.storefront_rounded,
          child: Column(
            children: [
              _ServiceToggle(
                service: 'mart',
                subtitle: 'Products & orders',
                value: s.martEnabled,
                onChanged: (v) => _editSettings(s.copyWith(martEnabled: v)),
              ),
              _ServiceToggle(
                service: 'remart',
                subtitle: 'Pre-owned listings',
                value: s.remartEnabled,
                onChanged: (v) => _editSettings(s.copyWith(remartEnabled: v)),
              ),
              _ServiceToggle(
                service: 'realestate',
                subtitle: 'Properties',
                value: s.realestateEnabled,
                isLast: true,
                onChanged: (v) =>
                    _editSettings(s.copyWith(realestateEnabled: v)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Limits & memory',
          icon: Icons.tune_rounded,
          child: LayoutBuilder(builder: (context, c) {
            final fields = <Widget>[
              _NumberField(
                label: 'History window',
                helper: 'Recent messages sent to the LLM',
                icon: Icons.history_rounded,
                value: s.historyWindow,
                onChanged: (v) => _editSettings(s.copyWith(historyWindow: v)),
              ),
              _NumberField(
                label: 'Summary threshold',
                helper: 'Messages before re-summarizing',
                icon: Icons.compress_rounded,
                value: s.summaryThreshold,
                onChanged: (v) =>
                    _editSettings(s.copyWith(summaryThreshold: v)),
              ),
              _NumberField(
                label: 'Max results per query',
                helper: 'Items returned from a single search',
                icon: Icons.list_alt_rounded,
                value: s.maxResultsPerQuery,
                onChanged: (v) =>
                    _editSettings(s.copyWith(maxResultsPerQuery: v)),
              ),
              _NumberField(
                label: 'Max message length',
                helper: 'Characters allowed per user message',
                icon: Icons.text_fields_rounded,
                value: s.maxMessageLength,
                onChanged: (v) =>
                    _editSettings(s.copyWith(maxMessageLength: v)),
              ),
              _NumberField(
                label: 'Daily message limit',
                helper: 'Per user, per day',
                icon: Icons.speed_rounded,
                value: s.dailyMessageLimit,
                onChanged: (v) =>
                    _editSettings(s.copyWith(dailyMessageLimit: v)),
              ),
            ];
            if (c.maxWidth > 560) {
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: fields
                    .map((f) => SizedBox(width: (c.maxWidth - 14) / 2, child: f))
                    .toList(),
              );
            }
            return Column(
              children: fields
                  .map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 14), child: f))
                  .toList(),
            );
          }),
        ),
        if (s.updatedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(
              'Last updated ${_formatDate(s.updatedAt)}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11.5, color: _C.faint, fontWeight: FontWeight.w600),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSettingsSaveBar() {
    return SafeArea(
      top: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: _C.surface,
          border: const Border(top: BorderSide(color: _C.border)),
          boxShadow: [
            BoxShadow(
              color: _a(Colors.black, 0.05),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _settingsDirty ? _C.amber : _C.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _settingsDirty ? 'Unsaved changes' : 'All changes saved',
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: _C.muted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: _settingsSaving || !_settingsDirty ? null : _loadSettings,
              style: OutlinedButton.styleFrom(
                foregroundColor: _C.muted,
                side: const BorderSide(color: _C.border),
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Discard'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _settingsSaving || !_settingsDirty ? null : _saveSettings,
              icon: _settingsSaving
                  ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(_settingsSaving ? 'Saving…' : 'Save'),
              style: FilledButton.styleFrom(
                backgroundColor: _C.primary,
                padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Makes non-list content pull-to-refresh friendly.
  Widget _scrollable(Widget child) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(16),
    children: [child],
  );
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: _C.surface,
  borderRadius: BorderRadius.circular(18),
  border: Border.all(color: _C.border),
  boxShadow: _softShadow,
);

// ============================================================
// CONVERSATION DETAIL SHEET (self-loading)
// ============================================================
class _ConversationSheet extends StatefulWidget {
  final AiAdminService service;
  final String? token;
  final AiConversationRow conversation;

  const _ConversationSheet({
    required this.service,
    required this.token,
    required this.conversation,
  });

  @override
  State<_ConversationSheet> createState() => _ConversationSheetState();
}

class _ConversationSheetState extends State<_ConversationSheet> {
  bool _loading = true;
  AiConversationRow? _conversation;
  List<AiMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await widget.service
        .getConversationDetail(widget.conversation.id, token: widget.token);
    if (!mounted) return;
    setState(() {
      _conversation = res?.conversation;
      _messages = res?.messages ?? [];
      _loading = false;
    });
  }

  void _openMessage(AiMessage m) {
    showDialog(
      context: context,
      builder: (_) => _MessageDetailDialog(
        service: widget.service,
        token: widget.token,
        message: m,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conv = _conversation ?? widget.conversation;
    final title = conv.title.isEmpty ? '(No title)' : conv.title;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _C.bg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 10, 8, 16),
                decoration: const BoxDecoration(gradient: _C.headerGradient),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: _a(Colors.white, 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _a(Colors.white, 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.forum_rounded,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Conversation',
                                  style: TextStyle(
                                      color: Color(0xFFC7D2FE), fontSize: 11.5)),
                              Text(
                                title,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close_rounded,
                              color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const _Loading()
                    : _conversation == null
                    ? _EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Could not load conversation',
                  onRetry: _load,
                )
                    : _body(scrollController),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _body(ScrollController controller) {
    final c = _conversation!;
    final color = _serviceColor(c.activeService);

    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Row(
                children: [
                  _Avatar(name: c.user.name.isEmpty ? 'U' : c.user.name),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.user.name.isEmpty ? 'Unknown user' : c.user.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                              color: _C.ink),
                        ),
                        Text(
                          c.user.email,
                          style:
                          const TextStyle(fontSize: 12, color: _C.muted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _Pill(
                    icon: _serviceIcon(c.activeService),
                    text: _serviceLabel(c.activeService),
                    fg: color,
                    bg: _a(color, 0.12),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: _C.border),
              ),
              Row(
                children: [
                  Expanded(
                    child: _MiniMetric(
                        label: 'Messages', value: '${c.messageCount}'),
                  ),
                  Expanded(
                    child: _MiniMetric(
                        label: 'Created', value: _formatDate(c.createdAt)),
                  ),
                  Expanded(
                    child: _MiniMetric(
                        label: 'Last activity',
                        value: _formatDate(c.lastMessageAt)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              const Icon(Icons.chat_rounded, size: 16, color: _C.primary),
              const SizedBox(width: 6),
              Text(
                'Messages (${_messages.length})',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 13, color: _C.ink2),
              ),
              const Spacer(),
              const Text('Tap a message for raw detail',
                  style: TextStyle(fontSize: 11, color: _C.faint)),
            ],
          ),
        ),
        if (_messages.isEmpty)
          const _InlineEmpty('No messages in this conversation')
        else
          ..._messages.map(_messageBubble),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _messageBubble(AiMessage m) {
    final isUser = m.role == 'user';
    final accent = isUser ? _C.muted : _C.primary;
    final ok = m.status == 'success';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxWidth: math.min(MediaQuery.of(context).size.width * 0.88, 620)),
          child: Material(
            color: isUser ? _C.surface : _C.primarySoft,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            child: InkWell(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 16),
              ),
              onTap: () => _openMessage(m),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  border: Border.all(
                      color: isUser ? _C.border : _a(_C.primary, 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(isUser ? Icons.person_rounded : Icons.smart_toy_rounded,
                            size: 14, color: accent),
                        const SizedBox(width: 6),
                        Text(
                          isUser ? 'USER' : m.role.toUpperCase(),
                          style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                              color: accent),
                        ),
                        const Spacer(),
                        Text(_formatDate(m.createdAt),
                            style: const TextStyle(
                                fontSize: 10.5, color: _C.faint)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      m.content.isEmpty ? '(empty)' : m.content,
                      style: const TextStyle(
                          fontSize: 13.5, color: _C.ink, height: 1.45),
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (m.status.isNotEmpty)
                          _Pill(
                            text: m.status,
                            fg: ok ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                            bg: ok ? _C.greenSoft : _C.redSoft,
                          ),
                        if (m.llmModel != null)
                          _Pill(
                            icon: Icons.memory_rounded,
                            text: m.llmModel!,
                            fg: const Color(0xFF1E40AF),
                            bg: const Color(0xFFDBEAFE),
                          ),
                        if (m.latencyMs != null)
                          _Pill(
                            icon: Icons.timer_outlined,
                            text: '${m.latencyMs} ms',
                            fg: const Color(0xFF475569),
                            bg: const Color(0xFFF1F5F9),
                          ),
                        if (m.feedback == 1)
                          const _Pill(
                            icon: Icons.thumb_up_rounded,
                            text: 'Liked',
                            fg: Color(0xFF15803D),
                            bg: _C.greenSoft,
                          ),
                        if (m.feedback == -1)
                          const _Pill(
                            icon: Icons.thumb_down_rounded,
                            text: 'Disliked',
                            fg: Color(0xFFB91C1C),
                            bg: _C.redSoft,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// MESSAGE DETAIL DIALOG (self-loading)
// ============================================================
class _MessageDetailDialog extends StatefulWidget {
  final AiAdminService service;
  final String? token;
  final AiMessage message;

  const _MessageDetailDialog({
    required this.service,
    required this.token,
    required this.message,
  });

  @override
  State<_MessageDetailDialog> createState() => _MessageDetailDialogState();
}

class _MessageDetailDialogState extends State<_MessageDetailDialog> {
  bool _loading = true;
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res =
    await widget.service.getMessageDetail(widget.message.id, token: widget.token);
    if (!mounted) return;
    setState(() {
      _detail = res;
      _loading = false;
    });
  }

  String get _json => _detail == null
      ? ''
      : const JsonEncoder.withIndent('  ').convert(_detail);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 640),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: _C.surface,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                  decoration: const BoxDecoration(gradient: _C.headerGradient),
                  child: Row(
                    children: [
                      const Icon(Icons.data_object_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text('Message detail',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15)),
                      ),
                      IconButton(
                        tooltip: 'Copy JSON',
                        onPressed: _detail == null
                            ? null
                            : () {
                          Clipboard.setData(ClipboardData(text: _json));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('JSON copied'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded,
                            color: Colors.white, size: 20),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    color: const Color(0xFF0B1220),
                    padding: const EdgeInsets.all(16),
                    child: _loading
                        ? const Center(
                        child: CircularProgressIndicator(color: _C.primary))
                        : _detail == null
                        ? const Center(
                      child: Text('Could not load message detail',
                          style: TextStyle(color: Color(0xFFFCA5A5))),
                    )
                        : SingleChildScrollView(
                      child: SelectableText(
                        _json,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          color: Color(0xFFA5F3FC),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// REUSABLE WIDGETS
// ============================================================
class _AdminTab extends StatelessWidget {
  final IconData icon;
  final String label;
  const _AdminTab(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Tab(
      height: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: CircularProgressIndicator(color: _C.primary),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;

  const _EmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(
                color: _C.primarySoft, shape: BoxShape.circle),
            child: Icon(icon, size: 38, color: _C.primary),
          ),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15.5, color: _C.ink, fontWeight: FontWeight.w800)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: _C.muted)),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _C.primary,
                side: const BorderSide(color: _C.border),
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineEmpty extends StatelessWidget {
  final String text;
  const _InlineEmpty(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Center(
      child: Text(text,
          style: const TextStyle(color: _C.faint, fontSize: 13)),
    ),
  );
}

class _Panel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _Panel({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _C.primarySoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: _C.primary, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                        color: _C.ink)),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  final List<Widget> cards;
  final double childAspectRatio;
  const _StatGrid({required this.cards, required this.childAspectRatio});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cross = c.maxWidth < 700 ? 2 : 4;
      return GridView.count(
        crossAxisCount: cross,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
        children: cards,
      );
    });
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String sub;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_a(color, 0.75), color],
                  ),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: [
                    BoxShadow(
                      color: _a(color, 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 19),
              ),
              const Spacer(),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ],
          ),
          const Spacer(),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
                fontSize: 10,
                color: _C.faint,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: _C.ink,
                  height: 1.1),
            ),
          ),
          if (sub.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(sub,
                style: const TextStyle(fontSize: 11, color: _C.muted),
                overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final String label;
  final Color color;
  final String value;
  const _LegendRow(
      {required this.label, required this.color, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: _C.ink2, fontSize: 13)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: _C.ink, fontSize: 14)),
      ],
    );
  }
}

class _FeedbackSummary extends StatelessWidget {
  final int likes;
  final int dislikes;
  final int rate;
  const _FeedbackSummary(
      {required this.likes, required this.dislikes, required this.rate});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FeedbackBox(
                label: 'Likes',
                value: likes,
                icon: Icons.thumb_up_rounded,
                color: _C.green,
                bg: _C.greenSoft,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _FeedbackBox(
                label: 'Dislikes',
                value: dislikes,
                icon: Icons.thumb_down_rounded,
                color: const Color(0xFFDC2626),
                bg: _C.redSoft,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Approval rate',
                style: TextStyle(
                    color: _C.muted,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const Spacer(),
            Text('$rate%',
                style: const TextStyle(
                    color: _C.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: rate / 100,
            minHeight: 8,
            backgroundColor: _C.track,
            valueColor: const AlwaysStoppedAnimation(_C.primary),
          ),
        ),
      ],
    );
  }
}

class _FeedbackBox extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color bg;
  const _FeedbackBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(_formatNumber(value),
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: _C.ink)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: color)),
        ],
      ),
    );
  }
}

class _ServiceBar extends StatelessWidget {
  final String service;
  final int count;
  final double fraction;
  final String trailing;
  const _ServiceBar({
    required this.service,
    required this.count,
    required this.fraction,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final color = _serviceColor(service);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _a(color, 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(_serviceIcon(service), color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(_serviceLabel(service),
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: _C.ink)),
                    ),
                    Text(_formatNumber(count),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: _C.ink)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      child: Text(trailing,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              fontSize: 11.5,
                              color: _C.faint,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: fraction.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: _C.track,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final letter = (name.trim().isEmpty ? 'U' : name.trim()[0]).toUpperCase();
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        gradient: _C.primaryGradient,
        borderRadius: BorderRadius.circular(13),
      ),
      alignment: Alignment.center,
      child: Text(letter,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData? icon;
  final String text;
  final Color fg;
  final Color bg;
  const _Pill({this.icon, required this.text, required this.fg, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(text,
                style: TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.w800, color: fg),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  final String label;
  final String value;
  const _MiniMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: _C.faint)),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: _C.ink)),
      ],
    );
  }
}

class _PerfItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _PerfItem(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _C.surface,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: _C.primary, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: _C.faint),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _C.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DropdownBox<T> extends StatelessWidget {
  final IconData icon;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownBox({
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _C.bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _C.faint),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    color: _C.faint),
                borderRadius: BorderRadius.circular(14),
                style: const TextStyle(
                    fontSize: 13, color: _C.ink, fontWeight: FontWeight.w700),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedRange extends StatelessWidget {
  final int value;
  final Map<int, String> options;
  final ValueChanged<int> onChanged;
  const _SegmentedRange({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _C.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.border),
      ),
      child: Row(
        children: options.entries.map((e) {
          final active = e.key == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  gradient: active ? _C.primaryGradient : null,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: active ? Colors.white : _C.muted,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ServiceToggle extends StatelessWidget {
  final String service;
  final String subtitle;
  final bool value;
  final bool isLast;
  final ValueChanged<bool> onChanged;

  const _ServiceToggle({
    required this.service,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _serviceColor(service);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: _C.track)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _a(color, value ? 0.14 : 0.06),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(_serviceIcon(service),
                color: value ? color : _C.faint, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_serviceLabel(service),
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13.5,
                        color: _C.ink)),
                Text(subtitle,
                    style: const TextStyle(fontSize: 11.5, color: _C.faint)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: _C.primary,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

/// Number input that keeps its own controller so the cursor never jumps
/// while typing, and re-syncs when the value is changed from outside (Reset).
class _NumberField extends StatefulWidget {
  final String label;
  final String helper;
  final IconData icon;
  final int value;
  final ValueChanged<int> onChanged;

  const _NumberField({
    required this.label,
    required this.helper,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(covariant _NumberField old) {
    super.didUpdateWidget(old);
    if (!_focus.hasFocus && widget.value.toString() != _controller.text) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: c, width: w),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label.toUpperCase(),
            style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: _C.ink2)),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          focusNode: _focus,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
          onChanged: (v) {
            final parsed = int.tryParse(v);
            if (parsed != null) widget.onChanged(parsed);
          },
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: _C.bg,
            prefixIcon: Icon(widget.icon, size: 18, color: _C.faint),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: border(Colors.transparent),
            enabledBorder: border(Colors.transparent),
            focusedBorder: border(_C.primary, 2),
          ),
        ),
        if (widget.helper.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 5, left: 2),
            child: Text(widget.helper,
                style: const TextStyle(fontSize: 11, color: _C.faint)),
          ),
      ],
    );
  }
}

// ============================================================
// CHARTS
// ============================================================
class _BarChart extends StatelessWidget {
  final List<AiDailyMessage> data;
  const _BarChart({required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const _InlineEmpty('No data for this period');

    final maxCount = data.map((e) => e.count).reduce(math.max);
    const chartHeight = 150.0;

    return LayoutBuilder(builder: (context, c) {
      const gap = 8.0;
      const minBar = 22.0;
      final fit = (c.maxWidth - gap * data.length) / data.length;
      final barWidth = math.max(minBar, math.min(fit, 44.0));
      final contentWidth = (barWidth + gap) * data.length;

      final chart = Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: contentWidth < c.maxWidth
            ? MainAxisAlignment.spaceEvenly
            : MainAxisAlignment.start,
        children: data.map((d) {
          final h = maxCount == 0
              ? 4.0
              : math.max(4.0, (d.count / maxCount) * chartHeight);
          final label = d.date.length >= 10 ? d.date.substring(5, 10) : d.date;
          final isMax = d.count == maxCount && maxCount > 0;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: gap / 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${d.count}',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: isMax ? _C.primary : _C.muted)),
                const SizedBox(height: 4),
                Container(
                  width: barWidth,
                  height: chartHeight,
                  decoration: BoxDecoration(
                    color: _C.track,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.bottomCenter,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: h),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, __) => Container(
                      width: barWidth,
                      height: v,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isMax
                              ? const [Color(0xFF818CF8), Color(0xFF4338CA)]
                              : const [Color(0xFFC7D2FE), Color(0xFF818CF8)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(label,
                    style: const TextStyle(
                        fontSize: 9.5,
                        color: _C.faint,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }).toList(),
      );

      return SizedBox(
        height: chartHeight + 44,
        child: contentWidth < c.maxWidth
            ? chart
            : SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: chart,
        ),
      );
    });
  }
}

class _Seg {
  final double value;
  final Color color;
  const _Seg(this.value, this.color);
}

class _DonutPainter extends CustomPainter {
  final List<_Seg> segments;
  final Color emptyColor;
  _DonutPainter({required this.segments, required this.emptyColor});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 14.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final total = segments.fold<double>(0, (s, e) => s + e.value);

    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = emptyColor;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, base);
    if (total <= 0) return;

    var start = -math.pi / 2;
    const gapAngle = 0.06;
    final visible = segments.where((s) => s.value > 0).toList();
    for (final s in visible) {
      var sweep = (s.value / total) * math.pi * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = s.color;
      if (visible.length > 1) sweep = math.max(0.01, sweep - gapAngle);
      canvas.drawArc(arcRect, start, sweep, false, paint);
      start += (s.value / total) * math.pi * 2;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.segments != segments || old.emptyColor != emptyColor;
}



















