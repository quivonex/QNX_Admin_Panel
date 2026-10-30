// screens/real_estate/channel_partner_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../channel_partner/channel_partner_enquiry_screen.dart';
import '../qnx_admin/login_screen.dart';

class ChannelPartnerDashboardScreen extends StatefulWidget {
  const ChannelPartnerDashboardScreen({super.key});

  @override
  State<ChannelPartnerDashboardScreen> createState() =>
      _ChannelPartnerDashboardScreenState();
}

class _ChannelPartnerDashboardScreenState
    extends State<ChannelPartnerDashboardScreen>
    with TickerProviderStateMixin {
  // ==================== THEME COLORS ====================
  static const Color _primaryBlue = Color(0xFF4158D0);
  static const Color _primaryPurple = Color(0xFFC850C0);
  static const Color _bgLight = Color(0xFFF0F5FA);
  static const Color _bgDark = Color(0xFF1A1A2E);
  static const Color _cardDark = Color(0xFF16213E);

  bool _isDarkMode = false;
  bool _isSidebarExpanded = true;

  late AnimationController _borderAnimationController;
  late Animation<Color?> _borderColorAnimation;

  @override
  void initState() {
    super.initState();
    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _borderColorAnimation = ColorTween(
      begin: _primaryBlue,
      end: _primaryPurple,
    ).animate(_borderAnimationController);
  }

  @override
  void dispose() {
    _borderAnimationController.dispose();
    super.dispose();
  }

  // ==================== LOGOUT ====================
  void _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: Colors.red, size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Logout'),
          ],
        ),
        content: const Text(
          'Are you sure you want to logout from Channel Partner Dashboard?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  // ==================== NAVIGATION ====================
  void _openEnquiries() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChannelPartnerEnquiryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: isDark ? _bgDark : _bgLight,
      drawer: isMobile ? _buildDrawer(isDark) : null,
      body: Row(
        children: [
          if (!isMobile) _buildSidebar(isDark),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(isDark, isMobile),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeHeader(isDark, isMobile),
                        const SizedBox(height: 20),
                        _buildStatsGrid(isDark, isMobile),
                        const SizedBox(height: 20),
                        _buildSalesChart(isDark),
                        const SizedBox(height: 20),
                        _buildQuickActions(isDark, isMobile),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SIDEBAR ====================
  Widget _buildSidebar(bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: _isSidebarExpanded ? 240 : 70,
      decoration: BoxDecoration(
        color: isDark ? _cardDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo Header
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryBlue, _primaryPurple],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.home_work,
                      color: Colors.white, size: 22),
                ),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'CP Dashboard',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                IconButton(
                  icon: Icon(
                    _isSidebarExpanded
                        ? Icons.chevron_left
                        : Icons.chevron_right,
                    size: 18,
                    color: isDark ? Colors.white70 : Colors.grey[700],
                  ),
                  onPressed: () {
                    setState(() => _isSidebarExpanded = !_isSidebarExpanded);
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // ===== MENU ITEMS =====
          _buildSidebarItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            isSelected: true,
            onTap: () {},
            isDark: isDark,
          ),
          _buildSidebarItem(
            icon: Icons.question_answer,
            title: 'Enquiries',
            isSelected: false,
            onTap: _openEnquiries,
            isDark: isDark,
            badge: '2',
          ),
          _buildSidebarItem(
            icon: Icons.home_work,
            title: 'Properties',
            isSelected: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Properties - Coming Soon')),
              );
            },
            isDark: isDark,
          ),
          _buildSidebarItem(
            icon: Icons.people,
            title: 'My Leads',
            isSelected: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('My Leads - Coming Soon')),
              );
            },
            isDark: isDark,
          ),
          _buildSidebarItem(
            icon: Icons.calendar_today,
            title: 'Site Visits',
            isSelected: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Site Visits - Coming Soon')),
              );
            },
            isDark: isDark,
          ),
          _buildSidebarItem(
            icon: Icons.currency_rupee,
            title: 'Commission',
            isSelected: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Commission - Coming Soon')),
              );
            },
            isDark: isDark,
          ),

          const Spacer(),

          // ===== FOOTER =====
          const Divider(height: 1),
          _buildSidebarFooter(isDark),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
    String? badge,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                colors: [_primaryBlue, _primaryPurple],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
                  : null,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.grey[400] : Colors.grey[700]),
                ),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.grey[300] : Colors.grey[800]),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.3)
                            : _primaryPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : _primaryPurple,
                        ),
                      ),
                    ),
                ] else if (badge != null)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _primaryPurple,
                        shape: BoxShape.circle,
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

  Widget _buildSidebarFooter(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Dark Mode Toggle
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => _isDarkMode = !_isDarkMode),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Icon(
                      _isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      size: 20,
                      color: _isDarkMode ? Colors.yellow : Colors.grey[700],
                    ),
                    if (_isSidebarExpanded) ...[
                      const SizedBox(width: 12),
                      Text(
                        _isDarkMode ? 'Light Mode' : 'Dark Mode',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Logout Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _logout,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 20, color: Colors.red),
                    if (_isSidebarExpanded) ...[
                      const SizedBox(width: 12),
                      const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DRAWER (MOBILE) ====================
  Widget _buildDrawer(bool isDark) {
    return Drawer(
      child: Container(
        color: isDark ? _cardDark : Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryBlue, _primaryPurple],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.home_work,
                          color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'CP Dashboard',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildDrawerItem(
                icon: Icons.dashboard,
                title: 'Dashboard',
                onTap: () => Navigator.pop(context),
                isSelected: true,
              ),
              _buildDrawerItem(
                icon: Icons.question_answer,
                title: 'Enquiries',
                onTap: () {
                  Navigator.pop(context);
                  _openEnquiries();
                },
              ),
              _buildDrawerItem(
                icon: Icons.home_work,
                title: 'Properties',
                onTap: () => Navigator.pop(context),
              ),
              _buildDrawerItem(
                icon: Icons.people,
                title: 'My Leads',
                onTap: () => Navigator.pop(context),
              ),
              _buildDrawerItem(
                icon: Icons.calendar_today,
                title: 'Site Visits',
                onTap: () => Navigator.pop(context),
              ),
              _buildDrawerItem(
                icon: Icons.currency_rupee,
                title: 'Commission',
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _logout,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.logout, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? _primaryBlue : Colors.grey[700],
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? _primaryBlue : Colors.grey[800],
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        selected: isSelected,
        selectedTileColor: _primaryBlue.withOpacity(0.1),
      ),
    );
  }

  // ==================== TOP BAR ====================
  Widget _buildTopBar(bool isDark, bool isMobile) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? _cardDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isMobile)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          if (!isMobile)
            Text(
              'Channel Partner Dashboard',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          const Spacer(),
          // Notification
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_outlined,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B35), _primaryPurple],
                    ),
                    shape: BoxShape.circle,
                  ),
                  constraints:
                  const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          // Profile Avatar
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryBlue, _primaryPurple],
              ),
              shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              child: Text(
                'R',
                style: TextStyle(
                  color: _primaryBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== WELCOME HEADER ====================
  Widget _buildWelcomeHeader(bool isDark, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primaryBlue, _primaryPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome ,',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 15,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),


              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),

          ),
        ],
      ),
    );
  }

  // ==================== STATS GRID ====================
  Widget _buildStatsGrid(bool isDark, bool isMobile) {
    final stats = [
      {
        'title': 'Total Enquiries',
        'value': '2',
        'icon': Icons.question_answer,
        'color': _primaryBlue,
        'onTap': _openEnquiries,
      },
      {
        'title': 'Assigned',
        'value': '2',
        'icon': Icons.assignment_ind,
        'color': const Color(0xFF2ECC71),
        'onTap': _openEnquiries,
      },
      {
        'title': 'Properties',
        'value': '36',
        'icon': Icons.home_work,
        'color': const Color(0xFFF39C12),
        'onTap': null,
      },
      {
        'title': 'Commission',
        'value': '₹4.5L',
        'icon': Icons.currency_rupee,
        'color': _primaryPurple,
        'onTap': null,
      },
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: isMobile ? 2 : 4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: stats.map((stat) {
        return _buildStatCard(
          title: stat['title'] as String,
          value: stat['value'] as String,
          icon: stat['icon'] as IconData,
          color: stat['color'] as Color,
          isDark: isDark,
          onTap: stat['onTap'] as VoidCallback?,
        );
      }).toList(),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [color.withOpacity(0.15), color.withOpacity(0.05)]
                  : [color.withOpacity(0.1), Colors.white],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.2), width: 0.5),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 22, color: color),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                  ),
                ],
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[700],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== SALES CHART ====================
  Widget _buildSalesChart(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? _cardDark : Colors.white,
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
          const Text(
            'Enquiry Overview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                    strokeWidth: 0.5,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const months = [
                          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            months[value.toInt() % 12],
                            style: TextStyle(
                              fontSize: 10,
                              color:
                              isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: _primaryBlue,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _primaryBlue.withOpacity(0.3),
                          _primaryBlue.withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    spots: const [
                      FlSpot(0, 2),
                      FlSpot(1, 4),
                      FlSpot(2, 3),
                      FlSpot(3, 6),
                      FlSpot(4, 5),
                      FlSpot(5, 8),
                      FlSpot(6, 7),
                      FlSpot(7, 10),
                      FlSpot(8, 8),
                      FlSpot(9, 12),
                      FlSpot(10, 11),
                      FlSpot(11, 14),
                    ],
                  ),
                  LineChartBarData(
                    isCurved: true,
                    color: _primaryPurple,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    spots: const [
                      FlSpot(0, 1),
                      FlSpot(1, 3),
                      FlSpot(2, 2),
                      FlSpot(3, 4),
                      FlSpot(4, 4),
                      FlSpot(5, 6),
                      FlSpot(6, 5),
                      FlSpot(7, 7),
                      FlSpot(8, 7),
                      FlSpot(9, 9),
                      FlSpot(10, 9),
                      FlSpot(11, 11),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== QUICK ACTIONS ====================
  Widget _buildQuickActions(bool isDark, bool isMobile) {
    final actions = [
      {
        'icon': Icons.question_answer,
        'label': 'View Enquiries',
        'color': _primaryBlue,
        'onTap': _openEnquiries,
      },
      {
        'icon': Icons.add_home,
        'label': 'Add Property',
        'color': const Color(0xFF2ECC71),
        'onTap': () {},
      },
      {
        'icon': Icons.person_add,
        'label': 'Add Lead',
        'color': const Color(0xFFF39C12),
        'onTap': () {},
      },
      {
        'icon': Icons.currency_rupee,
        'label': 'Commission',
        'color': _primaryPurple,
        'onTap': () {},
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? _cardDark : Colors.white,
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
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: actions.map((action) {
              final color = action['color'] as Color;
              return SizedBox(
                width: isMobile
                    ? (MediaQuery.of(context).size.width - 68) / 2
                    : 170,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: action['onTap'] as VoidCallback,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.1),
                            color.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: color.withOpacity(0.25), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              action['icon'] as IconData,
                              color: color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              action['label'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}