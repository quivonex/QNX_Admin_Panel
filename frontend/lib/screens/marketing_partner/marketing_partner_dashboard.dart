// lib/screens/marketing_partner/marketing_partner_dashboard.dart

import 'dart:math'; // Fixed typo dart0:math to dart:math
import 'package:battery_regeneration_system/screens/marketing_partner/pending_commission_screen.dart';
import 'package:battery_regeneration_system/screens/marketing_partner/property_referral_screen.dart';
import 'package:battery_regeneration_system/screens/marketing_partner/refral_product_screen.dart';
import 'package:battery_regeneration_system/screens/marketing_partner/withdraw_screen.dart';
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
import 'dart:html' as html; // for web download
import '../real_estate/my_properties_screen.dart';
import '../../screens/qnx_admin/login_screen.dart';
import '../../screens/marketing_partner/marketing_partner_profile_screen.dart';
import '../../screens/marketing_partner/my_referred_companies_screen.dart';
import '../../api/marketing_service.dart';
import '../../models/marketing_head/marketing_profile_model.dart';
import '../../api/marketing_service.dart' as referred_service;
import '../../models/marketing_partner/my_referred_companies_model.dart';
import '../../screens/qnx_admin/agreement_screen.dart';
import '../../screens/marketing_partner/real_estate_properties_screen.dart';
import '../channel_partner/channel_partner_enquiry_screen.dart';
import '../real_estate/create_builder_screen.dart';
import '../real_estate/create_property_screen.dart';
import '../real_estate/create_builder_property_screen.dart';
import 'bank_details_screen.dart';
import 'commission_screen.dart';
import 'create_franchise_screen.dart';
import 'real_estate_properties_screen.dart';
import '../../screens/marketing_partner/marketing_agreement_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/notification_service.dart';
import '../../models/notification/notification_model.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../screens/real_estate/schedule_meeting_form.dart';




class MarketingPartnerDashboard extends StatefulWidget {
  const MarketingPartnerDashboard({super.key});

  @override
  State<MarketingPartnerDashboard> createState() => _MarketingPartnerDashboardState();
}

class _MarketingPartnerDashboardState extends State<MarketingPartnerDashboard>
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

  // Search & selection
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedMenuItem = 'Dashboard';

  // Notification count
  int _notificationCount = 0;
  List<NotificationModel> _notifications = [];
  bool _isLoadingNotifications = false;

  // Global key for mobile drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ---------------------- API Data ----------------------
  MarketingProfile? _profile;
  List<MyReferredCompany> _referredCompanies = [];
  bool _isLoading = true;
  String? _error;

  // Screenshot controller for QR code
  final ScreenshotController _qrScreenshotController = ScreenshotController();

  // Dynamic Counts from API
  int _totalProducts = 0;
  double _totalCommission = 0.0;
  int _pendingCommissionCount = 0;
  int _referredCompaniesCount = 0;

  // Derived counts
  int get totalReferredCompanies => _referredCompanies.length;
  int get activeCompanies => _referredCompanies.length;

  // Static sample data for commission and top companies
  final double totalCommissionEarned = 124560.0;
  final double pendingCommission = 23450.0;

  final Map<String, double> statGrowth = {
    'Total Referred Companies': 12.5,
    'Active Companies': 8.2,
    'Commission Amount': 10.5,
    'Total Commission Earned': 15.3,
    'Pending Commission': -5.0,
  };

  final List<Map<String, dynamic>> topCompanies = [
    {'name': 'Tech Solutions Pvt Ltd', 'revenue': 425000, 'commission': 21250, 'status': 'Active', 'growth': '+22%'},
    {'name': 'Gadget World', 'revenue': 312000, 'commission': 15600, 'status': 'Growing', 'growth': '+18%'},
    {'name': 'ElectroMart', 'revenue': 187500, 'commission': 9375, 'status': 'Active', 'growth': '+12%'},
    {'name': 'Digital Haven', 'revenue': 95000, 'commission': 4750, 'status': 'Inactive', 'growth': '-3%'},
    {'name': 'Prime Retail', 'revenue': 225000, 'commission': 11250, 'status': 'Growing', 'growth': '+25%'},
    {'name': 'Innovative Infotech', 'revenue': 540000, 'commission': 27000, 'status': 'Active', 'growth': '+32%'},
  ];

  final List<FlSpot> currentYearCommissionSpots = const [
    FlSpot(0, 5), FlSpot(1, 7), FlSpot(2, 6), FlSpot(3, 9),
    FlSpot(4, 12), FlSpot(5, 14), FlSpot(6, 16), FlSpot(7, 18),
    FlSpot(8, 20), FlSpot(9, 22), FlSpot(10, 25), FlSpot(11, 28),
  ];

  final List<FlSpot> lastYearCommissionSpots = const [
    FlSpot(0, 4), FlSpot(1, 5), FlSpot(2, 4), FlSpot(3, 7),
    FlSpot(4, 9), FlSpot(5, 11), FlSpot(6, 12), FlSpot(7, 14),
    FlSpot(8, 15), FlSpot(9, 16), FlSpot(10, 17), FlSpot(11, 20),
  ];

  final List<Map<String, dynamic>> _menuItems = [
    {'title': 'Dashboard', 'icon': Icons.dashboard, 'color': const Color(0xFF4158D0)},
    {'title': 'My Profile', 'icon': Icons.person, 'color': const Color(0xFF9B59B6)},
    {'title': 'My Referred Companies', 'icon': Icons.business, 'color': const Color(0xFFF39C12)},
    {'title': 'Referral Product', 'icon': Icons.link, 'color': const Color(0xFF9B59B6)},
    {'title': 'Property Referral', 'icon': Icons.home_work, 'color': const Color(0xFFE67E22)},
    {'title': 'Real Estate', 'icon': Icons.home_work, 'color': const Color(0xFFE67E22)},
    {'title': 'Create Franchise', 'icon': Icons.storefront, 'color': const Color(0xFF2ECC71)},
    /*{'title': 'My Commission', 'icon': Icons.currency_rupee, 'color': const Color(0xFFFF6584)},
    {'title': 'Pending Commission', 'icon': Icons.pending_actions, 'color': const Color(0xFFE74C3C)},*/
    {'title': 'Agreement', 'icon': Icons.file_copy, 'color': const Color(0xFFE67E22)},
    {'title': 'Bank Detail', 'icon': Icons.account_balance, 'color': const Color(0xFF34495E)},
    {'title': 'Create New Property', 'icon': Icons.add_box, 'color': const Color(0xFF2ECC71)},
    // In _menuItems list, add:
    {'title': 'Property Enquiry', 'icon': Icons.question_answer, 'color': const Color(0xFF3498DB)},
    {'title': 'My Properties', 'icon': Icons.home_work_outlined, 'color': const Color(0xFF3498DB)},
/*    {'title': 'Schedule Meeting', 'icon': Icons.calendar_month, 'color': const Color(0xFF9B59B6)},*/


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

    _loadSavedScreenState();
    _loadDashboardData();

    // ✅ NOTIFICATION SETUP
    _loadNotifications();
    _setupNotificationListener();
    _updateNotificationCount();
  }

  Future<void> _loadSavedScreenState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMenu = prefs.getString('last_selected_menu');
    if (savedMenu != null && savedMenu.isNotEmpty) {
      if (mounted) {
        setState(() {
          _selectedMenuItem = savedMenu;
        });
      }
    }
  }

  Future<void> _saveSelectedScreen(String title) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_selected_menu', title);
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No access token found. Please login again.');
      }

      // 1. Get Profile
      final profileService = MarketingProfileService();
      final profileResponse = await profileService.getMyProfile();

      if (!profileResponse.status || profileResponse.data == null) {
        throw Exception(profileResponse.message ?? 'Failed to load profile');
      }

      // 2. Get Referred Companies
      final companiesService = referred_service.MyReferredCompaniesService();
      final companiesResponse = await companiesService.fetchMyCompanies();

      if (!companiesResponse.status) {
        _referredCompanies = [];
      } else {
        _referredCompanies = companiesResponse.data;
      }
      _referredCompaniesCount = _referredCompanies.length;

      // 3. Get Products Count
      try {
        final productService = ProductReferralService();
        final productResponse = await productService.getApprovedProducts();
        _totalProducts = productResponse.data.length;
      } catch (e) {
        print('❌ Failed to load products: $e');
        _totalProducts = 0;
      }

      // 4. Get Commission Data
      try {
        final commissionService = CommissionService();
        final commissionResponse = await commissionService.getCommission();
        if (commissionResponse.status && commissionResponse.data.isNotEmpty) {
          _totalCommission = commissionResponse.data.fold(
            0.0,
                (sum, item) => sum + item.totalCommissionAmount,
          );
        } else {
          _totalCommission = 0.0;
        }
      } catch (e) {
        print('❌ Failed to load commission: $e');
        _totalCommission = 0.0;
      }

      // 5. Get Pending Commission Count
      try {
        final pendingService = PendingCommissionService();
        final pendingResponse = await pendingService.getPendingCommissions();
        if (pendingResponse.status) {
          _pendingCommissionCount = pendingResponse.data.length;
        } else {
          _pendingCommissionCount = 0;
        }
      } catch (e) {
        print('❌ Failed to load pending commission: $e');
        _pendingCommissionCount = 0;
      }

      if (mounted) {
        setState(() {
          _profile = profileResponse.data;
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
    // ✅ Remove notification listener
    NotificationService.onNotificationsChanged = null;
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

  // ============================================================
  // ✅ NOTIFICATION METHODS
  // ============================================================

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      await NotificationService.refresh();

      if (mounted) {
        setState(() {
          _notifications = NotificationService.getNotifications();
          _notificationCount = NotificationService.getUnreadCount();
          _isLoadingNotifications = false;
        });
      }

      print('✅ Loaded ${_notifications.length} notifications, $_notificationCount unread');
    } catch (e) {
      print('❌ Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoadingNotifications = false;
        });
      }
    }
  }

  void _updateNotificationCount() {
    if (!mounted) return;
    setState(() {
      _notificationCount = NotificationService.getUnreadCount();
    });
  }

  void _setupNotificationListener() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 New foreground notification: ${message.notification?.title}');

      final title = message.notification?.title ?? 'QNXmart Notification';
      final body = message.notification?.body ?? 'You have a new notification';
      final Map<String, dynamic> data = message.data;

      NotificationService.addNotification(
        title: title,
        body: body,
        route: data['route'],
        icon: data['icon'],
      );

      _showSnackbarAlert(title, body);

      if (mounted) {
        setState(() {
          _notificationCount = NotificationService.getUnreadCount();
        });
      }
    });

    // App opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 App opened from notification');
      _loadNotifications();
      _showNotificationsDialog();
    });

    // ✅ Notification service listener
    NotificationService.onNotificationsChanged = (notifications) {
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _notificationCount = NotificationService.getUnreadCount();
        });
      }
    };
  }

  void _showSnackbarAlert(String title, String body) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active,
                color: Color(0xFF4158D0),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    body,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF16213E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'VIEW',
          textColor: const Color(0xFF4158D0),
          onPressed: _showNotificationsDialog,
        ),
      ),
    );

    Fluttertoast.showToast(
      msg: '$title: $body',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: const Color(0xFF16213E),
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  IconData _getNotificationIcon(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('order') || lowerTitle.contains('purchase')) {
      return Icons.shopping_cart;
    } else if (lowerTitle.contains('payment') || lowerTitle.contains('amount') || lowerTitle.contains('₹')) {
      return Icons.payment;
    } else if (lowerTitle.contains('product') || lowerTitle.contains('stock')) {
      return Icons.inventory;
    } else if (lowerTitle.contains('user') || lowerTitle.contains('customer')) {
      return Icons.person;
    } else if (lowerTitle.contains('offer') || lowerTitle.contains('sale')) {
      return Icons.local_offer;
    } else if (lowerTitle.contains('enquiry') || lowerTitle.contains('query')) {
      return Icons.question_answer;
    } else if (lowerTitle.contains('commission')) {
      return Icons.currency_rupee;
    } else if (lowerTitle.contains('agreement')) {
      return Icons.description;
    } else if (lowerTitle.contains('welcome')) {
      return Icons.waving_hand;
    } else if (lowerTitle.contains('referral') || lowerTitle.contains('refer')) {
      return Icons.link;
    } else if (lowerTitle.contains('property') || lowerTitle.contains('real estate')) {
      return Icons.home_work;
    }
    return Icons.notifications;
  }

  Color _getNotificationColor(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('order')) return const Color(0xFF4158D0);
    if (lowerTitle.contains('payment') || lowerTitle.contains('commission')) return const Color(0xFF2ECC71);
    if (lowerTitle.contains('product')) return const Color(0xFFF39C12);
    if (lowerTitle.contains('user')) return const Color(0xFF9B59B6);
    if (lowerTitle.contains('offer')) return const Color(0xFFE74C3C);
    if (lowerTitle.contains('enquiry')) return const Color(0xFF1ABC9C);
    if (lowerTitle.contains('referral') || lowerTitle.contains('refer')) return const Color(0xFF9B59B6);
    if (lowerTitle.contains('property')) return const Color(0xFFE67E22);
    return const Color(0xFF4158D0);
  }

  String _getNotificationCategory(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('order')) return 'Order';
    if (lowerTitle.contains('payment') || lowerTitle.contains('commission')) return 'Payment';
    if (lowerTitle.contains('product')) return 'Product';
    if (lowerTitle.contains('user')) return 'User';
    if (lowerTitle.contains('offer')) return 'Offer';
    if (lowerTitle.contains('enquiry')) return 'Enquiry';
    if (lowerTitle.contains('agreement')) return 'Agreement';
    if (lowerTitle.contains('referral') || lowerTitle.contains('refer')) return 'Referral';
    if (lowerTitle.contains('property')) return 'Property';
    return 'General';
  }

  void _showNotificationsDialog() {
    print('🔔 Opening notification dialog');

    _loadNotifications();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF1A1A2E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _isDarkMode ? Colors.grey[600] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.notifications_active,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Notifications',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                '${_notifications.length} total • ${_notificationCount} unread',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isDarkMode
                          ? const Color(0xFF16213E)
                          : const Color(0xFFF8FAFC),
                      border: Border(
                        bottom: BorderSide(
                          color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildActionChip(
                          icon: Icons.done_all,
                          label: 'Mark All Read',
                          onTap: () {
                            NotificationService.markAllAsRead();
                            setState(() {
                              _notificationCount = 0;
                              _loadNotifications();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ All notifications marked as read'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          color: const Color(0xFF4158D0),
                        ),
                        const SizedBox(width: 8),
                        _buildActionChip(
                          icon: Icons.delete_sweep,
                          label: 'Clear All',
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Clear All Notifications?'),
                                content: const Text(
                                  'This action cannot be undone. All notifications will be permanently deleted.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      NotificationService.clearAll();
                                      setState(() {
                                        _notificationCount = 0;
                                        _notifications = [];
                                      });
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('🗑️ All notifications cleared'),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Clear All'),
                                  ),
                                ],
                              ),
                            );
                          },
                          color: Colors.red,
                        ),
                        const Spacer(),
                        if (_notificationCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFF6B35), Color(0xFFC850C0)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_notificationCount unread',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Notification List
                  Expanded(
                    child: _isLoadingNotifications
                        ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4158D0),
                      ),
                    )
                        : _notifications.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return _buildModernNotificationItem(
                          notification: notification,
                          onTap: () {
                            NotificationService.markAsRead(notification.id);
                            setState(() {
                              _notificationCount = NotificationService.getUnreadCount();
                            });
                            Navigator.pop(context);

                            if (notification.route != null && notification.route!.isNotEmpty) {
                              // ✅ Route match करा menu title शी
                              final matchingMenu = _menuItems.firstWhere(
                                    (item) => item['title'].toString().toLowerCase() ==
                                    notification.route!.toLowerCase(),
                                orElse: () => {'title': null},
                              );

                              if (matchingMenu['title'] != null) {
                                setState(() {
                                  _selectedMenuItem = matchingMenu['title'];
                                });
                                _saveSelectedScreen(matchingMenu['title']);
                              }
                            }
                          },
                          onDelete: () {
                            NotificationService.removeNotification(notification.id);
                            setState(() {
                              _notifications = NotificationService.getNotifications();
                              _notificationCount = NotificationService.getUnreadCount();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🗑️ ${notification.title} dismissed'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[800] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_outlined,
              size: 56,
              color: _isDarkMode ? Colors.grey[500] : Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up! 🎉',
            style: TextStyle(
              fontSize: 14,
              color: _isDarkMode ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernNotificationItem({
    required NotificationModel notification,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    final Color iconColor = _getNotificationColor(notification.title);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
      ),
      onDismissed: (direction) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.transparent
              : _isDarkMode
              ? const Color(0xFF4158D0).withOpacity(0.08)
              : const Color(0xFF4158D0).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isDarkMode ? Colors.grey[800]! : Colors.grey[100]!,
            width: 0.5,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 8, right: 8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                      ),
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(width: 16),

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [iconColor, iconColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.title),
                    size: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                                fontSize: 14,
                                color: _isDarkMode ? Colors.white : Colors.black,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            notification.time,
                            style: TextStyle(
                              fontSize: 10,
                              color: _isDarkMode ? Colors.grey[500] : Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 13,
                          color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _getNotificationCategory(notification.title),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: iconColor,
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
    _saveSelectedScreen(title);
  }

  void _navigateToScreen(Widget screen, [String? menuTitle]) {
    if (!mounted) return;
    if (menuTitle != null) {
      setState(() {
        _selectedMenuItem = menuTitle;
      });
      _saveSelectedScreen(menuTitle);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
    }
  }

  Widget _getCurrentScreen() {
    switch (_selectedMenuItem) {
      case 'Dashboard':
        return _buildDashboardContent();
      case 'My Profile':
        return const MarketingPartnerProfileScreen();
      case 'My Referred Companies':
        return const MyReferredCompaniesScreen();
      case 'Referral Product':
        return const ReferralProductScreen();
      case 'Property Referral':
        return const PropertyReferralScreen();
      case 'Create Franchise':
        return const CreateFranchiseScreen();
      case 'Agreement':
        return const MarketingAgreementScreen();
      case 'Bank Detail':
        return const CreateBankDetailsScreen();
     // case 'My Commission':
       // return const CommissionScreen();
     // case 'Pending Commission':
      //  return const PendingCommissionScreen();
      case 'Real Estate':
        return const RealEstatePropertiesScreen();

      case 'Property Enquiry':
        return const ChannelPartnerEnquiryScreen();

      case 'Create New Property':                        // ✏️ RENAME
        return const CreateBuilderPropertyScreen();
      case 'My Properties':
        return const MyPropertiesScreen();
      /*case 'Schedule Meeting':
        return const ScheduleMeetingForm();*/
      default:
        return _buildDashboardContent();
    }
  }

  // 🔴 Encryption Check Logic for Referral Code & Link
  bool _checkIsEncrypted(String code, String link) {
    if (code.isEmpty && link.isEmpty) return false;

    // Safe check for getter/field dynamically to avoid compilation error
    try {
      dynamic dynamicProfile = _profile;
      if (dynamicProfile != null && dynamicProfile.isAgreementSigned == false) {
        return true;
      }
    } catch (_) {}

    // Check if code/link contains encryption indicators (e.g. *, enc, encrypted format)
    bool codeEnc = code.contains('*') || code.contains('enc=') || code.length > 25;
    bool linkEnc = link.contains('*') || link.contains('enc=') || link.contains('encrypted');

    return codeEnc || linkEnc;
  }

  // ---------------------- DASHBOARD CONTENT ----------------------
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
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 5),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isMobile ? 0.85 : 1.2,
              children: [
                _buildMarketingStatCard(
                  title: 'Referred Companies',
                  value: _referredCompaniesCount.toString(),
                  icon: Icons.business_center,
                  color: const Color(0xFF4158D0),
                  growth: statGrowth['Total Referred Companies']!,
                  onTap: () => _navigateToScreen(const MyReferredCompaniesScreen(), 'My Referred Companies'),
                ),
                _buildMarketingStatCard(
                  title: 'Active Companies',
                  value: _referredCompaniesCount.toString(),
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF2ECC71),
                  growth: statGrowth['Active Companies']!,
                  onTap: () => _navigateToScreen(const MyReferredCompaniesScreen(), 'My Referred Companies'),
                ),
                _buildMarketingStatCard(
                  title: 'Total Products',
                  value: _totalProducts.toString(),
                  icon: Icons.shopping_bag,
                  color: const Color(0xFF9B59B6),
                  growth: 5.0,
                  onTap: () => _navigateToScreen(const ReferralProductScreen(), 'Referral Product'),
                ),
               /* _buildMarketingStatCard(
                  title: 'My Commission',
                  value: '₹${_totalCommission.toStringAsFixed(0)}',
                  icon: Icons.currency_rupee,
                  color: const Color(0xFFF39C12),
                  growth: 10.5,
                  onTap: () => _navigateToScreen(const CommissionScreen(), 'My Commission'),
                ),
                _buildMarketingStatCard(
                  title: 'Pending Commission',
                  value: _pendingCommissionCount.toString(),
                  icon: Icons.pending_actions,
                  color: const Color(0xFFE74C3C),
                  growth: 0.0,
                  onTap: () => _navigateToScreen(const PendingCommissionScreen(), 'Pending Commission'),
                ),*/
              ],
            ),
            const SizedBox(height: 24),
            _buildCommissionChart(),
            const SizedBox(height: 24),
            _buildTopCompaniesTable(),
            const SizedBox(height: 24),
            _buildReferralCard(),
          ],
        ),
      ),
    );
  }

  // ---------------------- STAT CARD ----------------------
  Widget _buildMarketingStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required double growth,
    VoidCallback? onTap,
  }) {
    final bool isPositive = growth >= 0;
    final String growthText = '${isPositive ? '+' : ''}${growth.toStringAsFixed(1)}%';
    final IconData growthIcon = isPositive ? Icons.trending_up : Icons.trending_down;

    return _HoverCard(
      onTap: onTap ?? () {},
      builder: (isHover) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isDarkMode
                  ? [color.withOpacity(0.2), color.withOpacity(0.05)]
                  : [color.withOpacity(0.1), Colors.white],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: (_isDarkMode ? Colors.black : color).withOpacity(isHover ? 0.2 : 0.05),
                blurRadius: isHover ? 10 : 4,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: _isDarkMode ? color.withOpacity(0.3) : color.withOpacity(0.2),
              width: 0.8,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, size: 20, color: color),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(growthIcon, size: 10, color: isPositive ? Colors.green : Colors.red),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                growthText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isPositive ? Colors.green : Colors.red,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                          color: isHover ? color : (_isDarkMode ? Colors.white : Colors.black87),
                        ),
                        maxLines: 1,
                      ),
                    ),
                  ),
                ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isDarkMode ? Colors.grey[400] : Colors.grey[700],
                    letterSpacing: 0.3,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------- COMMISSION CHART ----------------------
  Widget _buildCommissionChart() {
    return Card(
      elevation: 2,
      color: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    'Commission Revenue Overview',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _legendItem('Current Year', const Color(0xFF4158D0)),
                    _legendItem('Last Year', Colors.grey),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 240,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!,
                      strokeWidth: 0.5,
                    ),
                  ),
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
                              child: Text(
                                months[value.toInt()],
                                style: TextStyle(fontSize: 10, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '₹${value.toInt()}k',
                            style: TextStyle(fontSize: 10, color: _isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: currentYearCommissionSpots,
                      isCurved: true,
                      color: const Color(0xFF4158D0),
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF4158D0).withOpacity(0.1),
                      ),
                    ),
                    LineChartBarData(
                      spots: lastYearCommissionSpots,
                      isCurved: true,
                      color: Colors.grey,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  lineTouchData: LineTouchData(enabled: true),
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
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: _isDarkMode ? Colors.grey[400] : Colors.grey[700])),
      ],
    );
  }

  // ---------------------- TOP COMPANIES TABLE ----------------------
  Widget _buildTopCompaniesTable() {
    return Card(
      elevation: 2,
      color: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🏆 Top Performing Referred Companies',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 700;
                return isDesktop
                    ? _buildCompaniesDataTable()
                    : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildCompaniesDataTable(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompaniesDataTable() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        constraints: BoxConstraints(
          minWidth: isMobile ? 500 : 700,
        ),
        child: DataTable(
          columnSpacing: isMobile ? 8 : 16,
          headingRowHeight: isMobile ? 36 : 42,
          dataRowHeight: isMobile ? 42 : 52,
          headingRowColor: WidgetStateProperty.all(
            _isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
          ),
          headingTextStyle: TextStyle(
            fontWeight: FontWeight.bold,
            color: _isDarkMode ? Colors.grey[300] : const Color(0xFF4158D0),
            fontSize: isMobile ? 10 : 12,
          ),
          columns: [
            DataColumn(label: Text('Company', style: TextStyle(fontSize: isMobile ? 10 : 13))),
            DataColumn(label: Text('Revenue', style: TextStyle(fontSize: isMobile ? 10 : 13))),
            DataColumn(label: Text('Comm.', style: TextStyle(fontSize: isMobile ? 10 : 13))),
            DataColumn(label: Text('Status', style: TextStyle(fontSize: isMobile ? 10 : 13))),
            DataColumn(label: Text('Growth', style: TextStyle(fontSize: isMobile ? 10 : 13))),
          ],
          rows: topCompanies.map((company) {
            Color getStatusColor(String status) {
              switch (status) {
                case 'Active': return Colors.green;
                case 'Growing': return Colors.blue;
                default: return Colors.grey;
              }
            }
            bool isGrowthPositive = company['growth'].startsWith('+');
            Color growthColor = isGrowthPositive ? Colors.green : Colors.red;
            return DataRow(cells: [
              DataCell(Text(company['name'],
                  style: TextStyle(fontSize: isMobile ? 10 : 13, fontWeight: FontWeight.w500,
                      color: _isDarkMode ? Colors.white : Colors.black87),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              DataCell(Text('₹${company['revenue'].toStringAsFixed(0)}',
                  style: TextStyle(fontSize: isMobile ? 10 : 13,
                      color: _isDarkMode ? Colors.white70 : Colors.black87),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              DataCell(Text('₹${company['commission'].toStringAsFixed(0)}',
                  style: TextStyle(fontSize: isMobile ? 10 : 13, fontWeight: FontWeight.w600,
                      color: const Color(0xFFF39C12)),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: getStatusColor(company['status']).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    company['status'],
                    style: TextStyle(color: getStatusColor(company['status']),
                        fontSize: isMobile ? 9 : 11, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGrowthPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      size: isMobile ? 12 : 14,
                      color: growthColor,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      company['growth'],
                      style: TextStyle(color: growthColor,
                          fontSize: isMobile ? 10 : 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  // ===================== COMPACT REFERRAL CARD =====================
  Widget _buildReferralCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    final rawCode = _profile?.referralCode ?? '';
    final rawLink = _profile?.referralLink ?? '';

    // Encryption State Checking
    final bool isEncrypted = _checkIsEncrypted(rawCode, rawLink);

    // Dynamic Display values based on Encryption state
    final displayCode = isEncrypted ? "********" : (rawCode.isEmpty ? "Loading..." : rawCode);
    final displayLink = isEncrypted ? "https://qnxmartb2b.com/company_create?ref=********" : (rawLink.isEmpty ? "Loading..." : rawLink);

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isMobile
                    ? Column(
                  children: [
                    _buildLeftColumn(displayCode, displayLink, isEncrypted, rawLink),
                    const SizedBox(height: 20),
                    _buildCompactQr(displayLink),
                  ],
                )
                    : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 7, child: _buildLeftColumn(displayCode, displayLink, isEncrypted, rawLink)),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _buildCompactQr(displayLink)),
                  ],
                ),

                // 🟡 IF ENCRYPTED: Display Notice message
                // 🟢 IF DECRYPTED: Hide Notice message
                if (isEncrypted) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade700, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber.shade900, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Please create agreement first to active your referral code & link',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLeftColumn(String code, String link, bool isEncrypted, String actualLink) {
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
                  code,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: isEncrypted ? Colors.red : (_isDarkMode ? Colors.white : Colors.black87),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isEncrypted && code.isNotEmpty)
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
                  link,
                  style: TextStyle(
                    fontSize: 12,
                    color: isEncrypted ? Colors.red : const Color(0xFF4158D0),
                    decoration: isEncrypted ? TextDecoration.none : TextDecoration.underline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!isEncrypted && link.isNotEmpty)
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
            onPressed: (isEncrypted || actualLink.isEmpty)
                ? null
                : () async {
              await Share.share(actualLink, subject: 'Join me on QNX Mart');
            },
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Share Referral', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: isEncrypted ? Colors.grey : const Color(0xFF4158D0),
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
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _saveQrImage(link),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(4),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download, size: 16, color: Color(0xFF4158D0)),
                    SizedBox(width: 4),
                    Text('Save QR', style: TextStyle(fontSize: 10, color: Color(0xFF4158D0), fontWeight: FontWeight.w500)),
                  ],
                ),
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
          width: min(MediaQuery.of(context).size.width * 0.85, 400), // Resolved min() method from dart:math
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  // ---------------------- MAIN BUILD ----------------------
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return AnimatedTheme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      duration: const Duration(milliseconds: 300),
      child: Material(
        color: Colors.transparent,
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: _isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF0F5FA),
          drawer: isMobile ? _buildMobileDrawer() : null,
          body: SafeArea(
            child: Row(
              children: [
                if (!isMobile)
                  AnimatedBuilder(
                    animation: _sidebarAnimation,
                    builder: (context, child) {
                      return SizedBox(
                        width: _isSidebarExpanded ? _sidebarAnimation.value : 70,
                        height: double.infinity,
                        child: _buildSidebar(),
                      );
                    },
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
        ),
      ),
    );
  }

  // ---------------------- TOP BAR ----------------------
  Widget _buildTopBar(bool isMobile) {
    final bool isNotDashboard = _selectedMenuItem != 'Dashboard';

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
          if (isMobile) ...[
            IconButton(
              icon: Icon(Icons.menu, color: _isDarkMode ? Colors.white : Colors.grey[800], size: 22),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
          ],

          if (isNotDashboard) ...[
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: _isDarkMode ? Colors.white : Colors.black87, size: 20),
              tooltip: 'Back to Dashboard',
              onPressed: () {
                setState(() {
                  _selectedMenuItem = 'Dashboard';
                });
                _saveSelectedScreen('Dashboard');
              },
            ),
            const SizedBox(width: 4),
            Text(
              _selectedMenuItem,
              style: TextStyle(
                fontSize: isMobile ? 15 : 18,
                fontWeight: FontWeight.bold,
                color: _isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 12),
          ],

          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                height: isMobile ? 36 : 40,
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    if (mounted) {
                      setState(() {
                        _searchQuery = val;
                      });
                    }
                  },
                  style: TextStyle(color: _isDarkMode ? Colors.white : Colors.black, fontSize: isMobile ? 12 : 14),
                  decoration: InputDecoration(
                    hintText: isMobile ? 'Search...' : 'Search companies, referrals...',
                    hintStyle: TextStyle(color: _isDarkMode ? Colors.grey[400] : Colors.grey, fontSize: isMobile ? 11 : 13),
                    prefixIcon: Icon(Icons.search, size: isMobile ? 16 : 18, color: const Color(0xFF4158D0)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear, size: isMobile ? 14 : 16, color: _isDarkMode ? Colors.white : Colors.grey),
                      onPressed: () {
                        if (mounted) {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        }
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

          // ✅ Notification Button - click केल्यावर dialog उघडेल
          _buildNotificationButton(isMobile),

          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ✅ NEW: Notification button with live unread count
  Widget _buildNotificationButton(bool isMobile) {
    final unreadCount = NotificationService.getUnreadCount();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: isMobile ? 32 : 36,
          height: isMobile ? 32 : 36,
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[800] : const Color(0xFFF5F7FA),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              Icons.notifications_outlined,
              color: _isDarkMode ? Colors.white : Colors.grey[800],
              size: isMobile ? 16 : 18,
            ),
            onPressed: _showNotificationsDialog,
            padding: EdgeInsets.zero,
            iconSize: isMobile ? 16 : 18,
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              child: Text(
                unreadCount > 9 ? '9+' : unreadCount.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    int? count,
    required VoidCallback onTap,
    required bool isMobile,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: isMobile ? 32 : 36,
          height: isMobile ? 32 : 36,
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.grey[800] : const Color(0xFFF5F7FA),
            shape: BoxShape.circle,
          ),
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
              child: Text(
                count > 9 ? '9+' : count.toString(),
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------- SIDEBAR ----------------------
  Widget _buildSidebar() {
    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: (_isDarkMode ? Colors.black : Colors.grey).withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
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
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chevron_right, size: 18, color: _isDarkMode ? Colors.white70 : Colors.grey[700]),
          ),
        ),
      );
    }
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Image.asset('assets/images/img_2.png', height: 70, fit: BoxFit.contain),
            ),
          ),
          GestureDetector(
            onTap: _toggleSidebar,
            child: Container(
              margin: const EdgeInsets.only(left: 8),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: _isDarkMode ? Colors.grey[800] : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chevron_left, size: 18, color: _isDarkMode ? Colors.white70 : Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _isDarkMode ? Colors.grey[500] : Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
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
                  ? const LinearGradient(
                colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
                  : null,
            ),
            child: Row(
              children: [
                Icon(item['icon'], size: 18, color: _getIconColor(item['icon'], isSelected)),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item['title'],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : (_isDarkMode ? Colors.grey[300] : Colors.grey[800]),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _logout,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.logout, size: 20, color: Colors.red[700]),
            ),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [Color(0xFF4158D0), Color(0xFFC850C0)]),
                  shape: BoxShape.circle,
                ),
                child: const CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                    child: Text('MP',
                        style: TextStyle(
                            color: Color(0xFF4158D0), fontWeight: FontWeight.bold, fontSize: 14))),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5))),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Marketing Partner',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text('partner@qnxmart.com',
                    style: TextStyle(
                        fontSize: 9, color: _isDarkMode ? Colors.grey[500] : Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode,
                size: 16, color: _isDarkMode ? Colors.yellow : Colors.grey[600]),
            onPressed: () {
              if (mounted) {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _logout,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                child: Icon(Icons.logout, size: 16, color: Colors.red[700]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------- MOBILE DRAWER ----------------------
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
    return Container(
      height: 120,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
      ),
      child: Center(child: Image.asset('assets/images/img_2.png', height: 120, fit: BoxFit.contain)),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(title,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
    );
  }

  Widget _buildDrawerItem(Map<String, dynamic> item) {
    final bool isSelected = _selectedMenuItem == item['title'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? const Color(0xFF4158D0).withOpacity(0.1) : null,
      ),
      child: ListTile(
        leading: Icon(item['icon'],
            color: isSelected ? const Color(0xFF4158D0) : item['color'], size: 20),
        title: Text(item['title'],
            style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? const Color(0xFF4158D0) : Colors.grey[800]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        onTap: () => _onMenuItemTap(item['title']),
        dense: true,
      ),
    );
  }

  Widget _buildDrawerFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey[200]!))),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _logout,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.red[50]),
            child: Row(children: [
              Icon(Icons.logout, color: Colors.red[700], size: 20),
              const SizedBox(width: 12),
              Text('Logout',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red[700]))
            ]),
          ),
        ),
      ),
    );
  }
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
      onEnter: (_) {
        if (mounted) setState(() => isHover = true);
      },
      onExit: (_) {
        if (mounted) setState(() => isHover = false);
      },
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