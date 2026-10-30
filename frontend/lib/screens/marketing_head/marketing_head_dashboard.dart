// lib/screens/marketing_head/marketing_head_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:html' as html;
import 'dart:math';

import '../../screens/qnx_admin/login_screen.dart';
import '../../screens/marketing_head/marketing_profile_screen.dart';
import '../../screens/marketing_head/my_team_screen.dart';
import '../../screens/marketing_head/referred_companies_screen.dart';
import '../../api/marketing_service.dart';
import '../../models/marketing_head/marketing_profile_model.dart';
import '../../models/marketing_head/my_team_model.dart';
import '../../models/marketing_head/referred_companies_model.dart';
import '../../screens/marketing_head/create_agreement_screen.dart';
import 'bank_detail_screen.dart';

class MarketingHeadDashboard extends StatefulWidget {
  const MarketingHeadDashboard({super.key});

  @override
  State<MarketingHeadDashboard> createState() => _MarketingHeadDashboardState();
}

class _MarketingHeadDashboardState extends State<MarketingHeadDashboard>
    with TickerProviderStateMixin {
  // Sidebar animation
  late AnimationController _sidebarController;
  late Animation<double> _sidebarAnimation;
  bool _isSidebarExpanded = true;

  // Border animation for Registration button and Referral Card
  late AnimationController _borderAnimationController;
  late Animation<Color?> _borderColorAnimation;

  // Dark mode
  bool _isDarkMode = false;

  // Search & selection (for partner table filtering)
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedMenuItem = 'Dashboard';

  // Notification count (static)
  int _notificationCount = 3;

  // Global key for mobile drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ---------------------- API Data ----------------------
  MarketingProfile? _profile;
  List<MyReferredPartner> _teamMembers = [];
  List<_PartnerWithCompanies> _partnersWithCompanies = [];
  bool _isLoading = true;
  String? _error;

  // Screenshot controller for QR code
  final ScreenshotController _qrScreenshotController = ScreenshotController();

  // Derived counts
  int get totalApprovedPartners => _teamMembers.where((p) => p.status == 'approved').length;
  int get pendingPartners => _teamMembers.where((p) => p.status == 'pending').length;

  // Static data for parts not yet available in API
  final double totalRevenue = 785200.0;
  final double monthlyGrowth = 12.5;

  // Revenue chart sample data (static)
  final List<FlSpot> currentYearSpots = const [
    FlSpot(0, 25), FlSpot(1, 32), FlSpot(2, 28), FlSpot(3, 45),
    FlSpot(4, 42), FlSpot(5, 58), FlSpot(6, 55), FlSpot(7, 70),
    FlSpot(8, 68), FlSpot(9, 85), FlSpot(10, 82), FlSpot(11, 95)
  ];
  final List<FlSpot> lastYearSpots = const [
    FlSpot(0, 18), FlSpot(1, 25), FlSpot(2, 22), FlSpot(3, 35),
    FlSpot(4, 32), FlSpot(5, 48), FlSpot(6, 45), FlSpot(7, 58),
    FlSpot(8, 55), FlSpot(9, 70), FlSpot(10, 68), FlSpot(11, 80)
  ];

  // Target progress – user editable
  double monthlyTarget = 1200000;
  double achievedRevenue = 840000;
  double get targetProgress => (achievedRevenue / monthlyTarget) * 100;

  // Recent activities (static)
  final List<Map<String, dynamic>> recentActivities = [
    {'text': 'Rajesh added a new company', 'time': '2 hours ago', 'icon': Icons.business, 'color': Colors.blue},
    {'text': 'Amit crossed monthly target', 'time': '5 hours ago', 'icon': Icons.emoji_events, 'color': Colors.orange},
    {'text': 'New partner joined (Priya Sharma)', 'time': '1 day ago', 'icon': Icons.person_add, 'color': Colors.green},
    {'text': 'Commission payout processed', 'time': '2 days ago', 'icon': Icons.payment, 'color': Colors.purple},
    {'text': 'Referral link shared 500+ times', 'time': '3 days ago', 'icon': Icons.share, 'color': Colors.teal},
  ];

  // Sidebar Menu Items (Bank Details is right below Agreement)
  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Dashboard', 'icon': Icons.dashboard, 'color': const Color(0xFF4158D0)},
    {'title': 'My Profile', 'icon': Icons.person, 'color': const Color(0xFF9B59B6)},
    {'title': 'My Team', 'icon': Icons.people, 'color': const Color(0xFF1ABC9C)},
    {'title': 'Referred Companies', 'icon': Icons.business, 'color': const Color(0xFFF39C12)},
    {'title': 'Agreement', 'icon': Icons.file_copy, 'color': const Color(0xFFE67E22)},
    {'title': 'Bank Details', 'icon': Icons.account_balance, 'color': Colors.blue},
    {'title': 'Orders', 'icon': Icons.shopping_bag, 'color': const Color(0xFFE67E22)},
    {'title': 'Enquiries', 'icon': Icons.question_answer, 'color': const Color(0xFFE74C3C)},
  ];

  @override
  void initState() {
    super.initState();
    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _sidebarAnimation = Tween<double>(begin: 260, end: 80).animate(
      CurvedAnimation(parent: _sidebarController, curve: Curves.easeInOut),
    );

    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _borderColorAnimation = ColorTween(
      begin: const Color(0xFF4158D0),
      end: const Color(0xFFC850C0),
    ).animate(_borderAnimationController);

    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final profileService = MarketingProfileService();
      final teamService = ReferralPartnerService();
      final companiesService = ReferredCompaniesService();

      final results = await Future.wait([
        profileService.getMyProfile(),
        teamService.getMyReferredPartners(),
        companiesService.fetchReferredCompanies(),
      ]);

      final profileResponse = results[0] as MarketingProfileResponse;
      final teamResponse = results[1] as MyReferredPartnerResponse;
      final companiesResponse = results[2] as ReferredCompaniesResponse;

      if (!profileResponse.status) throw Exception(profileResponse.message);
      if (!teamResponse.status) throw Exception('Failed to load team');
      if (!companiesResponse.status) throw Exception('Failed to load companies');

      final Map<int, int> partnerCompanyCount = {};
      for (var partnerData in companiesResponse.data) {
        partnerCompanyCount[partnerData.partnerId] = partnerData.companies.length;
      }

      final List<_PartnerWithCompanies> combined = teamResponse.data.map((partner) {
        return _PartnerWithCompanies(
          partner: partner,
          companiesCount: partnerCompanyCount[partner.id] ?? 0,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _profile = profileResponse.data;
          _teamMembers = teamResponse.data;
          _partnersWithCompanies = combined;
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

  @override
  void dispose() {
    _sidebarController.dispose();
    _borderAnimationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    if (!mounted) return;
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
      if (_isSidebarExpanded) {
        _sidebarController.forward();
      } else {
        _sidebarController.reverse();
      }
    });
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  void _onMenuItemTap(String title) {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (_scaffoldKey.currentState?.isDrawerOpen ?? false)) {
          Navigator.of(context).pop();
        }
      });
    }
    if (!mounted) return;
    setState(() {
      _selectedMenuItem = title;
    });
  }

  Widget _getCurrentScreen() {
    switch (_selectedMenuItem) {
      case 'Dashboard':
        return _buildDashboardContent();
      case 'My Profile':
        return const MarketingProfileScreen();
      case 'My Team':
        return const MyTeamScreen();
      case 'Referred Companies':
        return const ReferredCompaniesScreen();
      case 'Agreement':
        return const CreateAgreementScreen();
      case 'Bank Details':
        return const CreateBankDetailsScreen();
      case 'Orders':
        return _buildPlaceholderScreen('Orders');
      case 'Enquiries':
        return _buildPlaceholderScreen('Enquiries');
      default:
        return _buildDashboardContent();
    }
  }

  Widget _buildPlaceholderScreen(String title) {
    return Container(
      color: _isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF0F5FA),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '$title screen under construction',
              style: TextStyle(fontSize: 18, color: _isDarkMode ? Colors.white70 : Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------- Dashboard Content ----------------------
  Widget _buildDashboardContent() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Container(
      color: _isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF0F5FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ROW 1: KPI Cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 4),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildMarketingStatCard('Total Partners', totalApprovedPartners.toString(), Icons.people, const Color(0xFF9B59B6), growth: 8.2),
                _buildMarketingStatCard('Pending Partners', pendingPartners.toString(), Icons.pending_actions, const Color(0xFFF39C12), growth: -2.5),
                _buildMarketingStatCard('Total Revenue', '₹${totalRevenue.toStringAsFixed(0)}', Icons.currency_rupee, const Color(0xFF2ECC71), growth: 12.5),
                _buildMarketingStatCard('Monthly Growth', '$monthlyGrowth%', Icons.trending_up, const Color(0xFF4158D0), growth: monthlyGrowth),
              ],
            ),
            const SizedBox(height: 20),

            // ROW 2: Revenue Chart (left) + Target Progress with edit (right)
            if (isMobile)
              Column(
                children: [
                  _buildRevenueChart(),
                  const SizedBox(height: 16),
                  _buildTargetProgressCard(),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 6, child: _buildRevenueChart()),
                  const SizedBox(width: 16),
                  Expanded(flex: 4, child: _buildTargetProgressCard()),
                ],
              ),
            const SizedBox(height: 20),

            // ROW 3: Top Performing Partners (left) + Recent Activities (right)
            if (isMobile)
              Column(
                children: [
                  _buildTopPartnersTable(),
                  const SizedBox(height: 16),
                  _buildRecentActivities(),
                ],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 7, child: _buildTopPartnersTable()),
                  const SizedBox(width: 16),
                  Expanded(flex: 5, child: _buildRecentActivities()),
                ],
              ),
            const SizedBox(height: 20),

            _buildTopPartnersByCompanies(),
            const SizedBox(height: 20),

            _buildReferralCard(),
          ],
        ),
      ),
    );
  }

  // ---------------------- Reusable Stat Card ----------------------
  Widget _buildMarketingStatCard(String title, String value, IconData icon, Color color, {required double growth}) {
    final bool isPositive = growth >= 0;
    final String growthText = '${isPositive ? '+' : ''}${growth.toStringAsFixed(1)}%';
    final IconData growthIcon = isPositive ? Icons.trending_up : Icons.trending_down;

    return _HoverCard(
      onTap: () {},
      builder: (isHover) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isDarkMode
                  ? [color.withOpacity(0.15), color.withOpacity(0.05)]
                  : [color.withOpacity(0.1), Colors.white],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: (_isDarkMode ? Colors.black : color).withOpacity(isHover ? 0.2 : 0.05),
                blurRadius: isHover ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: _isDarkMode ? color.withOpacity(0.3) : color.withOpacity(0.2),
              width: 0.5,
            ),
          ),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 26, color: color),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(growthIcon, size: 12, color: isPositive ? Colors.green : Colors.red),
                          const SizedBox(width: 2),
                          Text(growthText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isPositive ? Colors.green : Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: isHover ? color : (_isDarkMode ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------- Revenue Chart ----------------------
  Widget _buildRevenueChart() {
    return Card(
      elevation: 2,
      color: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revenue Analytics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    _legendItem('Current Year', const Color(0xFF4158D0)),
                    _legendItem('Previous Year', Colors.grey),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (value) => FlLine(color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!)),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                          if (value.toInt() >= 0 && value.toInt() < months.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(months[value.toInt()], style: TextStyle(fontSize: 10, color: _isDarkMode ? Colors.grey[400] : Colors.grey)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(spots: currentYearSpots, isCurved: true, color: const Color(0xFF4158D0), barWidth: 3, dotData: const FlDotData(show: true)),
                    LineChartBarData(spots: lastYearSpots, isCurved: true, color: Colors.grey, barWidth: 2, dotData: const FlDotData(show: false)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: _isDarkMode ? Colors.grey[400] : Colors.grey)),
      ],
    );
  }

  // ---------------------- Target Progress Card ----------------------
  Widget _buildTargetProgressCard() {
    return Card(
      elevation: 2,
      color: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Monthly Revenue Target',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Color(0xFF4158D0)),
                  onPressed: () => _showEditTargetDialog(),
                  tooltip: 'Edit Target',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Target', style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600])),
                    Text('₹${(monthlyTarget / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF4158D0))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('Achieved', style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600])),
                    Text('₹${(achievedRevenue / 1000).toStringAsFixed(0)}k', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: targetProgress / 100,
              backgroundColor: _isDarkMode ? Colors.grey[700] : Colors.grey[300],
              color: const Color(0xFF4158D0),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '${targetProgress.toStringAsFixed(1)}% completed',
                    style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '₹${((monthlyTarget - achievedRevenue) / 1000).toStringAsFixed(0)}k remaining',
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.clip,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 90,
                    width: 90,
                    child: CircularProgressIndicator(
                      value: targetProgress / 100,
                      strokeWidth: 8,
                      backgroundColor: _isDarkMode ? Colors.grey[700] : Colors.grey[300],
                      color: const Color(0xFF4158D0),
                    ),
                  ),
                  Text('${targetProgress.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4158D0))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTargetDialog() {
    final TextEditingController controller = TextEditingController(text: monthlyTarget.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Monthly Revenue Target'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Target Amount (₹)',
            hintText: 'Enter amount in rupees',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTarget = double.tryParse(controller.text.trim());
              if (newTarget != null && newTarget > 0) {
                setState(() {
                  monthlyTarget = newTarget;
                });
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4158D0)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ---------------------- Top Performing Partners Table ----------------------
  Widget _buildTopPartnersTable() {
    final topPartners = List<_PartnerWithCompanies>.from(_partnersWithCompanies)
      ..sort((a, b) => b.companiesCount.compareTo(a.companiesCount));
    final displayList = topPartners.take(5).toList();

    return Card(
      elevation: 2,
      color: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Top Performing Partners', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 500;
                return isDesktop
                    ? _buildPartnerDataTable(displayList)
                    : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildPartnerDataTable(displayList),
                );
              },
            ),
            if (displayList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No partners found', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.black54))),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnerDataTable(List<_PartnerWithCompanies> partners) {
    return DataTable(
      columnSpacing: 16,
      headingRowHeight: 36,
      dataRowMaxHeight: 48,
      headingRowColor: WidgetStateProperty.all(_isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA)),
      headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.grey[300] : const Color(0xFF4158D0), fontSize: 11),
      columns: const [
        DataColumn(label: Text('Partner Name')),
        DataColumn(label: Text('Companies Referred')),
        DataColumn(label: Text('Revenue (₹)')),
        DataColumn(label: Text('Conversion %')),
        DataColumn(label: Text('Status')),
      ],
      rows: partners.map((item) {
        final mockRevenue = (item.companiesCount * 12500) + (item.partner.id * 1000);
        final mockConversion = (item.companiesCount * 3.2).clamp(0, 100).toDouble();
        Color statusColor = item.partner.status == 'approved'
            ? Colors.green
            : (item.partner.status == 'rejected' ? Colors.red : Colors.orange);
        return DataRow(cells: [
          DataCell(Text(item.partner.fullName, style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.white : Colors.black87))),
          DataCell(Text(item.companiesCount.toString(), style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.white : Colors.black87))),
          DataCell(Text('₹${mockRevenue.toStringAsFixed(0)}', style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.white : Colors.black87))),
          DataCell(Text('${mockConversion.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.white : Colors.black87))),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Text(item.partner.status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
        ]);
      }).toList(),
    );
  }

  // ---------------------- Recent Activities ----------------------
  Widget _buildRecentActivities() {
    return Card(
      elevation: 2,
      color: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Activities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: recentActivities.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final activity = recentActivities[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: (activity['color'] as Color).withOpacity(0.1),
                      child: Icon(activity['icon'], size: 18, color: activity['color']),
                    ),
                    title: Text(activity['text'], style: TextStyle(fontSize: 13, color: _isDarkMode ? Colors.white70 : Colors.black87)),
                    subtitle: Text(activity['time'], style: TextStyle(fontSize: 10, color: _isDarkMode ? Colors.grey[500] : Colors.grey[600])),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------- Top 5 Partners By Companies Referred (FIXED OVERFLOW) ----------------------
  Widget _buildTopPartnersByCompanies() {
    final topPartners = List<_PartnerWithCompanies>.from(_partnersWithCompanies)
      ..sort((a, b) => b.companiesCount.compareTo(a.companiesCount));
    final displayList = topPartners.take(5).toList();

    return Card(
      elevation: 2,
      color: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // 👈 Ensures dynamic sizing without blocking vertical space
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, size: 20, color: Color(0xFFF39C12)),
                const SizedBox(width: 8),
                Expanded( // 👈 Fixes horizontal header overflow on narrow devices
                  child: Text(
                    'Top 5 Partners by Companies Referred',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.white : Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...displayList.asMap().entries.map((entry) {
              final index = entry.key;
              final partner = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: _isDarkMode ? Colors.grey[800] : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), // 👈 Compact layout optimization
                    leading: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == 0 ? const Color(0xFFFFD700) : (index == 1 ? const Color(0xFFC0C0C0) : (index == 2 ? const Color(0xFFCD7F32) : Colors.grey.shade300)),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: index < 3 ? Colors.black : (_isDarkMode ? Colors.white : Colors.black87)),
                        ),
                      ),
                    ),
                    title: Text(
                      partner.partner.fullName,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _isDarkMode ? Colors.white : Colors.black87),
                      overflow: TextOverflow.ellipsis, // 👈 Handles long names smoothly
                    ),
                    subtitle: Text(
                      '${partner.companiesCount} companies referred',
                      style: TextStyle(fontSize: 12, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4158D0).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF4158D0).withOpacity(0.3)),
                      ),
                      child: Text(
                        '${partner.companiesCount}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4158D0)),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
            if (displayList.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(child: Text('No partners found', style: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.black54))),
              ),
          ],
        ),
      ),
    );
  }

  // ===================== REFERRAL CARD =====================
  Widget _buildReferralCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final referralLink = _profile?.referralLink ?? '';
    final referralCode = _profile?.referralCode ?? '';

    return AnimatedBuilder(
      animation: _borderAnimationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderColorAnimation.value ?? const Color(0xFF4158D0), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _borderColorAnimation.value?.withOpacity(0.4) ?? Colors.transparent,
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.all(16),
            child: isMobile
                ? Column(
              children: [
                _buildLeftColumn(referralCode, referralLink),
                const SizedBox(height: 20),
                _buildCompactQr(referralLink),
              ],
            )
                : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: _buildLeftColumn(referralCode, referralLink)),
                const SizedBox(width: 16),
                Expanded(flex: 3, child: _buildCompactQr(referralLink)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeftColumn(String code, String link) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Referral Program',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[800] : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Text('Code', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  code.isEmpty ? 'Loading...' : code,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: _isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (code.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.copy, size: 18, color: Color(0xFF4158D0)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Referral code copied!')),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[800] : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Text('Link', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  link.isEmpty ? 'Loading...' : link,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF4158D0), decoration: TextDecoration.underline),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (link.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.copy, size: 18, color: Color(0xFF4158D0)),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: link));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Referral link copied!')),
                    );
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: link.isEmpty
                ? null
                : () async {
              await Share.share(link, subject: 'Join me on QNX Mart');
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share Referral', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4158D0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactQr(String link) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[800] : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: link.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => _showQrPopup(link),
            child: Screenshot(
              controller: _qrScreenshotController,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: QrImageView(
                  data: link,
                  version: QrVersions.auto,
                  size: 130,
                  eyeStyle: const QrEyeStyle(color: Color(0xFF4158D0), eyeShape: QrEyeShape.square),
                  dataModuleStyle: const QrDataModuleStyle(color: Color(0xFF4158D0), dataModuleShape: QrDataModuleShape.square),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _saveQrImage(link),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.download, size: 16, color: Color(0xFF4158D0)),
                  const SizedBox(width: 4),
                  const Text('Save QR', style: TextStyle(fontSize: 10, color: Color(0xFF4158D0), fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showQrPopup(String link) {
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          width: min(MediaQuery.of(context).size.width * 0.85, 400),
          decoration: BoxDecoration(
            color: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Referral QR Code',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                        ),
                        padding: const EdgeInsets.all(16),
                        child: QrImageView(
                          data: link,
                          version: QrVersions.auto,
                          size: 240,
                          eyeStyle: const QrEyeStyle(color: Color(0xFF4158D0), eyeShape: QrEyeShape.square),
                          dataModuleStyle: const QrDataModuleStyle(color: Color(0xFF4158D0), dataModuleShape: QrDataModuleShape.square),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _saveQrImage(link);
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Save QR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4158D0),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(120, 40),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(Icons.close, color: _isDarkMode ? Colors.white70 : Colors.grey[700]),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveQrImage(String link) async {
    if (link.isEmpty) return;
    try {
      final Uint8List? imageBytes = await _qrScreenshotController.capture();
      if (imageBytes == null) throw Exception('Failed to capture QR code');

      if (kIsWeb) {
        final blob = html.Blob([imageBytes], 'image/png');
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', 'qrcode_referral.png')
          ..click();
        html.Url.revokeObjectUrl(url);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR code downloaded as PNG')),
          );
        }
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/qrcode_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(imageBytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('QR saved: ${file.path}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: ${e.toString()}')),
        );
      }
    }
  }

  // ---------------------- Main Build (Sidebar + TopBar) ----------------------
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return AnimatedTheme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      duration: const Duration(milliseconds: 300),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF0F5FA),
        drawer: isMobile ? _buildMobileDrawer() : null,
        body: Row(
          children: [
            if (!isMobile)
              SafeArea(
                child: AnimatedBuilder(
                  animation: _sidebarAnimation,
                  builder: (context, child) {
                    return SizedBox(
                      width: _isSidebarExpanded ? _sidebarAnimation.value : 70,
                      height: double.infinity,
                      child: _buildSidebar(),
                    );
                  },
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(isMobile),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (_isDarkMode ? Colors.black : Colors.grey).withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _getCurrentScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------- Top Bar ----------------------
  Widget _buildTopBar(bool isMobile) {
    return Container(
      height: isMobile ? 60 : 70,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: (_isDarkMode ? Colors.black : Colors.grey).withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: Icon(Icons.menu, color: _isDarkMode ? Colors.white : Colors.grey[800], size: 22),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                height: isMobile ? 36 : 40,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black, fontSize: isMobile ? 12 : 14),
                  decoration: InputDecoration(
                    hintText: isMobile ? 'Search...' : 'Search partners...',
                    hintStyle: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey, fontSize: isMobile ? 11 : 13),
                    prefixIcon: Icon(Icons.search, size: isMobile ? 16 : 18, color: const Color(0xFF4158D0)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, size: isMobile ? 14 : 16, color: _isDarkMode ? Colors.white : Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                        : null,
                    filled: true,
                    fillColor: _isDarkMode ? Colors.grey[800] : const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    isDense: true,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _buildIconButton(icon: Icons.notifications_outlined, count: _notificationCount, onTap: () {}, isMobile: isMobile),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, int? count, required VoidCallback onTap, required bool isMobile}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: isMobile ? 32 : 36,
          height: isMobile ? 32 : 36,
          decoration: BoxDecoration(color: _isDarkMode ? Colors.grey[800] : const Color(0xFFF5F7FA), shape: BoxShape.circle),
          child: IconButton(
            icon: Icon(icon, color: _isDarkMode ? Colors.white : Colors.grey[800], size: isMobile ? 16 : 18),
            onPressed: onTap,
            padding: EdgeInsets.zero,
            iconSize: isMobile ? 16 : 18,
          ),
        ),
        if (count != null && count > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              child: Text(count > 9 ? '9+' : count.toString(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }

  // ---------------------- Sidebar ----------------------
  Widget _buildSidebar() {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
        boxShadow: [BoxShadow(color: (_isDarkMode ? Colors.black : Colors.grey).withOpacity(0.1), spreadRadius: 1, blurRadius: 10, offset: const Offset(2, 0))],
      ),
      child: Column(
        children: [
          _buildSidebarHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (_isSidebarExpanded) _buildSidebarSection('MAIN'),
                ..._menuItems.map((item) => _buildSidebarMenuItem(item)),
              ],
            ),
          ),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    if (!_isSidebarExpanded) {
      return Container(
        height: 70,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: _toggleSidebar,
          child: Container(width: 30, height: 30, decoration: BoxDecoration(color: _isDarkMode ? Colors.grey[800] : Colors.grey[200], shape: BoxShape.circle),
              child: Icon(Icons.chevron_right, size: 18, color: _isDarkMode ? Colors.white70 : Colors.grey[700])),
        ),
      );
    }
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(child: Center(child: Image.asset('assets/images/img_2.png', height: 70, fit: BoxFit.contain))),
          GestureDetector(
            onTap: _toggleSidebar,
            child: Container(margin: const EdgeInsets.only(left: 8), width: 30, height: 30,
                decoration: BoxDecoration(color: _isDarkMode ? Colors.grey[800] : Colors.grey[200], shape: BoxShape.circle),
                child: Icon(Icons.chevron_left, size: 18, color: _isDarkMode ? Colors.white70 : Colors.grey[700])),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _isDarkMode ? Colors.grey[500] : Colors.grey[600], letterSpacing: 1.2)),
    );
  }

  Widget _buildSidebarMenuItem(Map<String, dynamic> item) {
    final bool isSelected = _selectedMenuItem == item['title'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onMenuItemTap(item['title']),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: isSelected
                  ? const LinearGradient(colors: [Color(0xFF4158D0), Color(0xFFC850C0)], begin: Alignment.centerLeft, end: Alignment.centerRight)
                  : null,
            ),
            child: Row(
              children: [
                Icon(item['icon'], size: 18, color: _getIconColor(item['icon'], isSelected)),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(item['title'], style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Colors.white : (_isDarkMode ? Colors.grey[300] : Colors.grey[800])), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getIconColor(IconData icon, bool isSelected) {
    if (isSelected) return Colors.white;
    final item = _menuItems.firstWhere((i) => i['icon'] == icon, orElse: () => {'color': Colors.grey});
    return item['color'] as Color;
  }

  Widget _buildSidebarFooter() {
    if (!_isSidebarExpanded) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        child: InkWell(
          onTap: _logout,
          borderRadius: BorderRadius.circular(8),
          child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.logout, size: 20, color: Colors.red[700])),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!))),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF4158D0), Color(0xFFC850C0)]), shape: BoxShape.circle),
                child: const CircleAvatar(radius: 14, backgroundColor: Colors.white,
                    child: Text('MH', style: TextStyle(color: Color(0xFF4158D0), fontWeight: FontWeight.bold, fontSize: 14))),
              ),
              Positioned(bottom: 0, right: 0,
                  child: Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)))),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Marketing Head', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                Text('head@qnxmart.com', style: TextStyle(fontSize: 9, color: _isDarkMode ? Colors.grey[500] : Colors.grey), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode, size: 16, color: _isDarkMode ? Colors.yellow : Colors.grey[600]),
            onPressed: () => setState(() => _isDarkMode = !_isDarkMode),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: _logout,
            borderRadius: BorderRadius.circular(8),
            child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.logout, size: 16, color: Colors.red[700])),
          ),
        ],
      ),
    );
  }

  // ---------------------- Mobile Drawer ----------------------
  Widget _buildMobileDrawer() {
    return Drawer(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              _buildDrawerHeader(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _buildDrawerSection('MAIN'),
                    ..._menuItems.map((item) => _buildDrawerItem(item)),
                  ],
                ),
              ),
              _buildDrawerFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(height: 120, decoration: const BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20))),
        child: Center(child: Image.asset('assets/images/img_2.png', height: 120, fit: BoxFit.contain)));
  }

  Widget _buildDrawerSection(String title) {
    return Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)));
  }

  Widget _buildDrawerItem(Map<String, dynamic> item) {
    final bool isSelected = _selectedMenuItem == item['title'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: isSelected ? const Color(0xFF4158D0).withOpacity(0.1) : null),
      child: ListTile(
        leading: Icon(item['icon'], color: isSelected ? const Color(0xFF4158D0) : item['color'], size: 20),
        title: Text(item['title'], style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? const Color(0xFF4158D0) : Colors.grey[800])),
        onTap: () => _onMenuItemTap(item['title']),
        dense: true,
      ),
    );
  }

  Widget _buildDrawerFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[200]!))),
      child: InkWell(
        onTap: _logout,
        borderRadius: BorderRadius.circular(8),
        child: Container(padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.red[50]),
            child: Row(children: [Icon(Icons.logout, color: Colors.red[700], size: 20), const SizedBox(width: 12),
              Text('Logout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red[700]))])),
      ),
    );
  }
}

class _PartnerWithCompanies {
  final MyReferredPartner partner;
  final int companiesCount;
  _PartnerWithCompanies({required this.partner, required this.companiesCount});
}

class _HoverCard extends StatefulWidget {
  final Widget Function(bool isHover) builder;
  final VoidCallback onTap;
  const _HoverCard({required this.builder, required this.onTap});
  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> {
  bool isHover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => isHover = true),
      onExit: (_) => setState(() => isHover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, isHover ? -5 : 0, 0),
          child: widget.builder(isHover),
        ),
      ),
    );
  }
}