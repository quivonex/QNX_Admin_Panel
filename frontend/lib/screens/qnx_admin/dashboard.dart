import '../../screens/qnx_admin/packing_material_enquiry_screen.dart';
import 'package:battery_regeneration_system/screens/qnx_admin/prepaid_cancelled_orders_screen.dart';

import '../../screens/qnx_admin/prepaid_cancelled_orders_screen.dart';
import 'package:battery_regeneration_system/screens/qnx_admin/return_shipment_screen.dart';

import '../../screens/qnx_admin/return_shipment_screen.dart';
import 'package:battery_regeneration_system/screens/qnx_admin/return_orders_screen.dart';

import '../../screens/qnx_admin/return_orders_screen.dart';
import 'package:battery_regeneration_system/screens/qnx_admin/pending_payment_requests_screen.dart';
import 'package:battery_regeneration_system/screens/qnx_admin/update_amount_screen.dart';
import 'package:battery_regeneration_system/screens/qnx_admin/user_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';
import 'dart:convert';
import '../../models/olx/olx_attribute_screen.dart';
import '../../services/notification_service.dart';
// Import your screens
import '../../api/api_response.dart';
import '../../api/api_service.dart';
import '../../models/notification/notification_model.dart';
import '../../models/qnx_admin/company_model.dart';
import '../../models/qnx_admin/company_product_enquiry_model.dart';
import '../../models/qnx_admin/enquiry_list_model.dart';
import '../../models/qnx_admin/product_model.dart';
import '../../screens/qnx_admin/unit_create.dart';
import '../../screens/qnx_admin/role_create.dart';
import '../../screens/qnx_admin/category_create.dart';
import '../../screens/qnx_admin/subcategory_screen.dart';
import '../../screens/qnx_admin/pending_product_list_screen.dart';
import '../../screens/qnx_admin/approve_product_list.dart';
import '../../screens/qnx_admin/company_all_screen.dart';
import '../../screens/qnx_admin/offer_screen.dart';
import '../../screens/qnx_admin/enquiry_list_screen.dart';
import '../../screens/qnx_admin/user_enquiry_screen.dart';
import '../../screens/qnx_admin/login_screen.dart';
import '../../screens/qnx_admin/agreement_screen.dart';
import '../../screens/qnx_admin/admin_create.dart';
import '../../screens/qnx_admin/update_request_list_screen.dart';
import '../../screens/qnx_admin/marketing_heads_screen.dart';
import '../../screens/qnx_admin/franchise_screen.dart';
import '../../screens/qnx_admin/banner_management_screen.dart';
import '../../api/api_url.dart';
import '../../screens/qnx_admin/marketing_partners_screen.dart';
import '../olx/olx_category_screen.dart';
import '../olx/olx_plan_screen.dart';
import '../olx/olx_pricing_screen.dart';
import '../olx/olx_subcategory_screen.dart';
import '../real_estate/channel_partner_screen.dart';
import '../real_estate/property_enquiry_screen.dart';
import '../shiprocket/shipment_screen.dart';
import '../support/support_dashboard.dart';
import 'approved_enquiries_screen.dart';
import 'approved_marketing_partners_screen.dart';
import 'bank_details_screen.dart';
import 'boosting_plan_screen.dart';
import 'company_product_enquiry_screen.dart';
import '../../screens/real_estate/property_list_screen.dart';
// ✅ NEW IMPORTS FOR PAID COMPANIES AND PENDING AMOUNT
import '../../models/qnx_admin/paid_company_model.dart';
import 'customer_subscription_plan_screen.dart';
import 'google_subscription_plan_screen.dart';
import 'loan_enquiry_screen.dart';
import 'marketing_partner_commission_list_screen.dart';
import '../../screens/real_estate/amenity_list_screen.dart';
import '../../screens/qnx_admin/banner_management_screen.dart';
import '../../screens/shiprocket/shiprocket_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../services/notification_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../screens/real_estate/builders_list_screen.dart';
import '../../screens/real_estate/property_subscription_screen.dart';
import '../olx/olx_settings_screen.dart';
import '../olx/olx_communication_plan_screen.dart';
import '../olx/olx_communication_settings_screen.dart';
import '../../screens/ai_admin/ai_admin_screen.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  // Tab Management
  late List<Map<String, dynamic>> _openTabs;
  late Map<String, Widget> _tabScreens;
  late String _activeTab;

  // Animation Controllers
  late AnimationController _sidebarController;
  late AnimationController _notificationController;
  late AnimationController _statsController;
  late Animation<double> _sidebarAnimation;
  late AnimationController _borderAnimationController;
  late Animation<Color?> _borderColorAnimation;

  // State variables
  bool _isRestoring = false;
  bool _isSidebarExpanded = true;
  bool _isDarkMode = false;
  int _notificationCount = 0;
  List<NotificationModel> _notifications = [];
  bool _isLoadingNotifications = false;
  String _selectedTimeRange = 'This Week';

  String _userRole = '';
  int? _companyId;
  bool _isAuthorized = false;
// For Pending Products
  int pendingProductsCount = 0;
  bool _isLoadingPendingProducts = true;

// For All Enquiries
  int allEnquiriesCount = 0;
  bool _isLoadingAllEnquiries = true;

// For Approved Enquiries
  int approvedEnquiriesCount = 0;
  bool _isLoadingApprovedEnquiries = true;

// For Payment Requests
  int paymentRequestsCount = 0;
  bool _isLoadingPaymentRequests = true;

  int pendingEnquiriesCount = 0;
  bool _isLoadingPendingEnquiries = true;


  // ✅ NEW: Complete Enquiries Count
  int completeEnquiriesCount = 0;
  bool _isLoadingCompleteEnquiries = true;

  // Search controller
  final TextEditingController _searchController = TextEditingController();

  // Global key for Scaffold state to open drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const String _kSavedTabsKey = 'dashboard_open_tabs';
  static const String _kActiveTabKey = 'dashboard_active_tab';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _checkUserRole();
    _fetchPendingEnquiriesCount();
    _fetchCompleteEnquiriesCount();

    // ✅ Initialize tabs first
    _initializeTabs();
    // ✅ Load notifications
    _loadNotifications();

    // ✅ Setup notification listener
    _setupNotificationListener();

    // Initialize animations
    _initializeAnimations();

    // Simulate real-time updates
    _simulateRealTimeUpdates();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTabsState();
    });

    // ✅ Update notification count on init
    _updateNotificationCount();
    // Initialize tabs
    _openTabs = [
      {'title': 'Dashboard', 'icon': Icons.dashboard, 'closable': false}
    ];
    _tabScreens = {
      'Dashboard': const DashboardHomeContent(),
    };
    _activeTab = 'Dashboard';

    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _borderColorAnimation = ColorTween(
      begin: const Color(0xFF4158D0),
      end: const Color(0xFFC850C0),
    ).animate(_borderAnimationController);

    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _sidebarAnimation = Tween<double>(begin: 280, end: 80).animate(
      CurvedAnimation(parent: _sidebarController, curve: Curves.easeInOut),
    );

    _notificationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _simulateRealTimeUpdates();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTabsState();
    });
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      setState(() {
        _notificationCount++;
      });
    });
  }
  // ✅ Separate method for tab initialization
  void _initializeTabs() {
    _openTabs = [
      {'title': 'Dashboard', 'icon': Icons.dashboard, 'closable': false}
    ];
    _tabScreens = {
      'Dashboard': const DashboardHomeContent(),
    };
    _activeTab = 'Dashboard';
  }

  // ✅ Separate method for animation initialization
  void _initializeAnimations() {
    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _borderColorAnimation = ColorTween(
      begin: const Color(0xFF4158D0),
      end: const Color(0xFFC850C0),
    ).animate(_borderAnimationController);

    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _sidebarAnimation = Tween<double>(begin: 280, end: 80).animate(
      CurvedAnimation(parent: _sidebarController, curve: Curves.easeInOut),
    );

    _notificationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
  }

  // ✅ CRITICAL: Setup notification service listener
  void _setupNotificationServiceListener() {
    // Listen to notification changes from service
    NotificationService.onNotificationsChanged = (notifications) {
      setState(() {
        _notifications = notifications;
        _notificationCount = NotificationService.getUnreadCount();
        print('🔄 Notifications updated: $_notificationCount unread');

        // ✅ Show toast/alert for new notifications
        if (_notifications.isNotEmpty) {
          final latest = _notifications.first;
          if (!latest.isRead) {
            _showNotificationAlert(latest);
          }
        }
      });
    };
  }


  void _showNotificationAlert(NotificationModel notification) {
    // Show snackbar with notification


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
              child: Icon(
                _getNotificationIcon(notification.title),
                color: const Color(0xFF4158D0),
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
                    notification.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    notification.body,
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
          onPressed: () {
            _showNotificationsDialog();
          },
        ),
      ),
    );

    Fluttertoast.showToast(
      msg: '${notification.title}: ${notification.body}',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: const Color(0xFF16213E),
      textColor: Colors.white,
      fontSize: 14.0,
    );

    // ✅ Also show a Flutter Toast if available, or just update counter
    setState(() {
      _notificationCount = NotificationService.getUnreadCount();
    });
  }

  // ✅ Update notification count
  void _updateNotificationCount() {
    setState(() {
      _notificationCount = NotificationService.getUnreadCount();
      print('🔔 Notification count updated: $_notificationCount');
    });
  }
  void _setupNotificationListener() {
    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📨 New foreground notification: ${message.notification?.title}');

      // Add to notification list
      final title = message.notification?.title ?? 'QNXmart Notification';
      final body = message.notification?.body ?? 'You have a new notification';
      final Map<String, dynamic> data = message.data;

      NotificationService.addNotification(
        title: title,
        body: body,
        route: data['route'],
        icon: data['icon'],
      );

      // Show snackbar alert
      _showSnackbarAlert(title, body);

      // Update UI
      setState(() {
        _notificationCount = NotificationService.getUnreadCount();
      });
    });

    // Listen when app is opened from notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📱 App opened from notification');
      _loadNotifications();
      // Show notification dialog
      _showNotificationsDialog();
    });
  }

  // ✅ Helper to show snackbar alert
  void _showSnackbarAlert(String title, String body) {
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
  }
  void _showUpdateAmountDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => const UpdateAmountScreen(),
    );
  }
  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role') ?? '';
      _companyId = prefs.getInt('companyId');
    });
    print("User Role: $_userRole, CompanyId: $_companyId");
  }
  // ✅ Override the _loadNotifications method
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      // Refresh notifications from service
      await NotificationService.refresh();

      setState(() {
        _notifications = NotificationService.getNotifications();
        _notificationCount = NotificationService.getUnreadCount();
        _isLoadingNotifications = false;
      });

      print('✅ Loaded ${_notifications.length} notifications, $_notificationCount unread');
    } catch (e) {
      print('❌ Error loading notifications: $e');
      setState(() {
        _isLoadingNotifications = false;
      });
    }
  }

  Future<void> _fetchPendingEnquiriesCount() async {
    try {
      final response = await ApprovedEnquiryService.fetchApprovedEnquiries();
      if (mounted) {
        // Count enquiries that are NOT Complete (Pending, Dispatched, Delivered)
        final pending = response.data.where((e) =>
        !e.isComplete
        ).toList();
        setState(() {
          pendingEnquiriesCount = pending.length;
          _isLoadingPendingEnquiries = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingPendingEnquiries = false);
      }
      print('Error fetching pending enquiries count: $e');
    }
  }
  /*Future<void> _loadNotifications() async {
    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      // Refresh notifications from service
      await NotificationService.refresh();

      setState(() {
        _notifications = NotificationService.getNotifications();
        _notificationCount = NotificationService.getUnreadCount();
        _isLoadingNotifications = false;
      });

      print('✅ Loaded ${_notifications.length} notifications, ${_notificationCount} unread');
    } catch (e) {
      print('❌ Error loading notifications: $e');
      setState(() {
        _isLoadingNotifications = false;
      });
    }
  }*/
/*  Future<void> _loadNotificationCount() async {
    setState(() {
      _isLoadingNotifications = true;
    });

    try {
      // Get FCM token (just for initialization)
      String? token = await FirebaseMessaging.instance.getToken();
      print('📱 FCM Token: $token');

      // You can fetch notification count from your backend here
      // For now, we'll use 0
      setState(() {
        _notificationCount = 0;
        _isLoadingNotifications = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _notificationCount = 0;
        _isLoadingNotifications = false;
      });
    }
  }*/

  // ✅ NEW: Fetch Complete Enquiries Count
  Future<void> _fetchCompleteEnquiriesCount() async {
    try {
      final response = await ApprovedEnquiryService.fetchApprovedEnquiries();
      if (mounted) {
        // Count enquiries that are Complete
        final complete = response.data.where((e) =>
        e.isComplete == true
        ).toList();
        setState(() {
          completeEnquiriesCount = complete.length;
          _isLoadingCompleteEnquiries = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCompleteEnquiries = false);
      }
      print('Error fetching complete enquiries count: $e');
    }
  }

  // ✅ Navigation to Approved Enquiries Screen
  void _navigateToApprovedEnquiries() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ApprovedEnquiriesScreen()),
    );
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? '';

    setState(() {
      _userRole = role.toLowerCase();
      _isAuthorized = _userRole.contains('admin') || _userRole.contains('qnx admin');
    });

    if (!_isAuthorized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Access Denied! You are not authorized as Admin.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SupportDashboard()),
        );
      });
    }
  }
  // In DashboardService class - Add these methods

// Get Pending Products Count
  Future<int> getPendingProductsCount() async {
    try {
      final response = await PendingProductService().getPendingProducts();
      return response.data.length;
    } catch (e) {
      print('Error fetching pending products: $e');
      return 0;
    }
  }

// Get All Enquiries Count
  Future<int> getAllEnquiriesCount() async {
    try {
      final pendingResponse = await PendingEnquiryService.fetchPendingEnquiries();
      final approvedResponse = await ApprovedEnquiryService.fetchApprovedEnquiries();
      return pendingResponse.data.length + approvedResponse.data.length;
    } catch (e) {
      print('Error fetching enquiries: $e');
      return 0;
    }
  }

// Get Approved Enquiries Count
  Future<int> getApprovedEnquiriesCount() async {
    try {
      final response = await ApprovedEnquiryService.fetchApprovedEnquiries();
      return response.data.length;
    } catch (e) {
      print('Error fetching approved enquiries: $e');
      return 0;
    }
  }

// Get Pending Payment Requests Count
  Future<int> getPendingPaymentRequestsCount() async {
    try {
      final response = await PaymentRequestService().getPendingWithdrawRequests();
      return response.data.length;
    } catch (e) {
      print('Error fetching payment requests: $e');
      return 0;
    }
  }

  Future<void> _saveTabsState() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> tabTitles = _openTabs
        .where((tab) => tab['title'] != 'Dashboard')
        .map((tab) => tab['title'] as String)
        .toList();
    await prefs.setString(_kSavedTabsKey, jsonEncode(tabTitles));
    await prefs.setString(_kActiveTabKey, _activeTab);
  }

  Future<void> _loadTabsState() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedTabsJson = prefs.getString(_kSavedTabsKey);
    final String? savedActiveTab = prefs.getString(_kActiveTabKey);
    if (savedTabsJson == null || savedActiveTab == null) return;

    final List<dynamic> decodedTabs = jsonDecode(savedTabsJson);
    final List<String> savedTitles = decodedTabs.map((e) => e.toString()).toList();

    for (final title in savedTitles) {
      final (screen, icon) = _getScreenInfoForTitle(title);
      _isRestoring = true;
      _openScreen(title, screen, icon: icon);
      _isRestoring = false;
    }

    if (_openTabs.any((tab) => tab['title'] == savedActiveTab)) {
      setState(() {
        _activeTab = savedActiveTab;
      });
    }
  }
// ✅ Add this method - Get icon based on notification title
  IconData _getNotificationIcon(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('order') || lowerTitle.contains('purchase')) {
      return Icons.shopping_cart;
    } else if (lowerTitle.contains('payment') || lowerTitle.contains('amount') || lowerTitle.contains('₹')) {
      return Icons.payment;
    } else if (lowerTitle.contains('product') || lowerTitle.contains('stock') || lowerTitle.contains('inventory')) {
      return Icons.inventory;
    } else if (lowerTitle.contains('user') || lowerTitle.contains('customer') || lowerTitle.contains('profile')) {
      return Icons.person;
    } else if (lowerTitle.contains('system') || lowerTitle.contains('update') || lowerTitle.contains('upgrade')) {
      return Icons.system_update;
    } else if (lowerTitle.contains('offer') || lowerTitle.contains('sale') || lowerTitle.contains('discount')) {
      return Icons.local_offer;
    } else if (lowerTitle.contains('enquiry') || lowerTitle.contains('query') || lowerTitle.contains('question')) {
      return Icons.question_answer;
    } else if (lowerTitle.contains('welcome') || lowerTitle.contains('hello') || lowerTitle.contains('hi')) {
      return Icons.waving_hand;
    } else if (lowerTitle.contains('error') || lowerTitle.contains('failed') || lowerTitle.contains('issue')) {
      return Icons.error_outline;
    } else if (lowerTitle.contains('success') || lowerTitle.contains('complete') || lowerTitle.contains('done')) {
      return Icons.check_circle_outline;
    } else {
      return Icons.notifications;
    }
  }

// ✅ Add this method - Get screen based on route
  Widget _getScreenForRoute(String route) {
    switch (route.toLowerCase()) {
      case 'dashboard':
        return const DashboardHomeContent();
      case 'orders':
      case 'shipments':
        return const ShipmentScreen();
      case 'products':
        return const ApprovedProductListScreen();
      case 'enquiries':
        return const EnquiryListScreen();
      case 'users':
        return const UserListScreen();
      case 'companies':
        return const CompanyAllScreen();
      case 'payments':
        return const PendingPaymentRequestsScreen();
      case 'banner':
        return const BannerManagementScreen();
      case 'return-orders':
        return const ReturnOrdersScreen();
      case 'return-shipments':
        return const ReturnShipmentScreen();


      default:
        return const DashboardHomeContent();
    }
  }
  void _simulateRealTimeUpdates() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _notificationCount += 3;
        });
        _simulateRealTimeUpdates();
      }
    });
  }

  void _closeAllTabs() {
    setState(() {
      _openTabs = _openTabs.where((tab) => tab['title'] == 'Dashboard').toList();
      _tabScreens.removeWhere((key, value) => key != 'Dashboard');
      _activeTab = 'Dashboard';
    });
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    _notificationController.dispose();
    _statsController.dispose();
    _searchController.dispose();
    _borderAnimationController.dispose();
    // ✅ Remove listener to prevent memory leaks
    NotificationService.onNotificationsChanged = null;
    super.dispose();
  }

  void _openScreen(String title, Widget screen, {IconData icon = Icons.tab}) {
    if (!_openTabs.any((tab) => tab['title'] == title)) {
      setState(() {
        if (!_isRestoring) _saveTabsState();
        _openTabs.add({'title': title, 'icon': icon, 'closable': true});
        _tabScreens[title] = screen;
        _activeTab = title;
      });
    } else {
      setState(() {
        _activeTab = title;
      });
    }
  }

  (Widget, IconData) _getScreenInfoForTitle(String title) {
    switch (title) {
      case 'Role':
        return (const RoleCreateScreen(), Icons.people);
      case 'Unit':
        return (const UnitCreateScreen(), Icons.straighten);
      case 'All Users':
        return (const UserListScreen(), Icons.people);
      case 'Category':
        return (const CategoryScreen(), Icons.category);
      case 'SubCategory':
        return (const SubCategoryAllScreen(), Icons.subtitles);
    // ✅ OLX Cases (keep these for tab restoration)
      case 'OLX Category':
        return (const OlxCategoryScreen(), Icons.storefront);
      case 'OLX Subcategory':
        return (const OlxSubcategoryScreen(), Icons.subtitles);
      case 'OLX Attribute':
        return (const OlxAttributeScreen(), Icons.list_alt);
      case 'OLX Plan':
        return (const OlxPlanScreen(), Icons.card_membership);
      case 'OLX Pricing':
        return (const OlxPricingScreen(), Icons.attach_money);
      case 'OLX Settings':
        return (const OlxSettingsScreen(), Icons.settings);
      case 'Real Estate Subscription':
        return (const PropertySubscriptionScreen(), Icons.card_membership);
      case 'Pending Product':
        return (const PendingProductListScreen(), Icons.pending_actions);
      case 'Approved Product':
        return (const ApprovedProductListScreen(), Icons.check_circle);
      case 'Update Requests':
        return (const UpdateRequestListScreen(), Icons.update);
      case 'All Company':
        return (const CompanyAllScreen(), Icons.business);
      case 'Agreement':
        return (AgreementScreen(), Icons.description);
      case 'Franchise':
        return (FranchiseListScreen(), Icons.storefront);
      case 'Offer List':
        return (const OfferListScreen(), Icons.local_offer);
      case 'Demo Enquiry':
        return (const EnquiryListScreen(), Icons.question_answer);
      case 'User Enquiry':
        return (const UserEnquiryScreen(), Icons.person);
      case 'Product Enquiry':
        return (EnquiryTabsScreen(), Icons.person);
      case 'Marketing Head':
        return (const MarketingHeadsScreen(), Icons.people_alt);
      case 'Marketing Partners':
        return (const MarketingPartnersScreen(), Icons.people_outline);
      case 'Admin Create':
        return (const AdminCreateScreen(), Icons.admin_panel_settings);
      case 'Bank Details':
        return (const BankDetailsScreen(), Icons.account_balance_wallet_rounded);
      case 'Approved Marketing Partners':
        return (const ApprovedMarketingPartnersScreen(), Icons.people_outline);
      case 'Payment Request':
        return (const PendingPaymentRequestsScreen(), Icons.payments_outlined);
      case 'Property Enquiries':
        return (const PropertyEnquiryScreen(), Icons.question_answer);
      case 'Properties':
        return (const PropertyListScreen(), Icons.house);
      case 'Builders':
        return (const BuildersListScreen(), Icons.business_center);
      case 'Banner Management':
        return (const BannerManagementScreen(), Icons.image);
      case 'ShipRocket':
        return (const ShiprocketScreen(), Icons.local_shipping);
      case 'Shipments':
        return (const ShipmentScreen(), Icons.local_shipping);
      case 'Loan Enquiries':
        return (const LoanEnquiryScreen(), Icons.assignment);
      case 'Customer Subscription Plans':
        return (const CustomerSubscriptionPlanScreen(), Icons.card_membership);
      case 'OLX Communication Plans':
        return (const OlxCommunicationPlanScreen(), Icons.forum);
      case 'OLX Communication Settings':
        return (const OlxCommunicationSettingsScreen(), Icons.forum_outlined);
      case 'AI Admin':
        return (const AiAdminScreen(), Icons.psychology);
      case 'Subscription Plans':
        return (const SubscriptionPlanScreen(), Icons.card_membership);
      case 'Return Orders':
        return (const ReturnOrdersScreen(), Icons.assignment_return);
      case 'Return Shipments':
        return (const ReturnShipmentScreen(), Icons.local_shipping);
      case 'Prepaid Cancelled Orders':
        return (const PrepaidCancelledOrdersScreen(), Icons.cancel_schedule_send);
      case 'Packing Material Enquiries':
        return (const PackingMaterialEnquiryScreen(), Icons.inventory_2);
      case 'Boosting Plans':
        return (const BoostingPlanScreen(), Icons.rocket_launch_outlined);
      default:
        return (const DashboardHomeContent(), Icons.dashboard);
    }
  }

  void _closeTab(String title) {
    if (title != 'Dashboard') {
      setState(() {
        _openTabs.removeWhere((tab) => tab['title'] == title);
        _tabScreens.remove(title);
        if (_activeTab == title) {
          _activeTab = _openTabs.isNotEmpty ? _openTabs.last['title'] : 'Dashboard';
        }
      });
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
      if (_isSidebarExpanded) {
        _sidebarController.forward();
      } else {
        _sidebarController.reverse();
      }
    });
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }



  void _showNotificationsDialog() {
    print('🔔 Opening notification dialog');

    // Reload notifications before showing
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
                  // ✅ Drag Handle
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _isDarkMode ? Colors.grey[600] : Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // ✅ Header with Gradient
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        // ✅ Icon with Circle Background
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
                              Text(
                                'Notifications',
                                style: const TextStyle(
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
                        // ✅ Close Button
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

                  // ✅ Action Buttons Row
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
                        // ✅ Mark All Read Button
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
                        // ✅ Clear All Button
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
                        // ✅ Unread Count Badge
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

                  // ✅ Notification List
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
                            // Mark as read
                            NotificationService.markAsRead(notification.id);
                            setState(() {
                              _notificationCount = NotificationService.getUnreadCount();
                            });
                            Navigator.pop(context);

                            // Navigate if route exists
                            if (notification.route != null && notification.route!.isNotEmpty) {
                              _openScreen(
                                notification.route!,
                                _getScreenForRoute(notification.route!),
                                icon: Icons.notifications,
                              );
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
              Icon(
                icon,
                size: 16,
                color: color,
              ),
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

// ✅ Empty State Widget
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
          const SizedBox(height: 4),
          Text(
            'New notifications will appear here',
            style: TextStyle(
              fontSize: 12,
              color: _isDarkMode ? Colors.grey[500] : Colors.grey[400],
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
                // ✅ Unread Indicator Dot
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 8, right: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                      ),
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const SizedBox(width: 16),

                // ✅ Notification Icon
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

                // ✅ Content
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
                          // ✅ Time
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
                      // ✅ Category Badge
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

  Color _getNotificationColor(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('order') || lowerTitle.contains('purchase')) {
      return const Color(0xFF4158D0); // Blue
    } else if (lowerTitle.contains('payment') || lowerTitle.contains('amount')) {
      return const Color(0xFF2ECC71); // Green
    } else if (lowerTitle.contains('product') || lowerTitle.contains('stock')) {
      return const Color(0xFFF39C12); // Orange
    } else if (lowerTitle.contains('user') || lowerTitle.contains('customer')) {
      return const Color(0xFF9B59B6); // Purple
    } else if (lowerTitle.contains('offer') || lowerTitle.contains('sale')) {
      return const Color(0xFFE74C3C); // Red
    } else if (lowerTitle.contains('enquiry') || lowerTitle.contains('query')) {
      return const Color(0xFF1ABC9C); // Teal
    } else if (lowerTitle.contains('welcome') || lowerTitle.contains('hello')) {
      return const Color(0xFF2ECC71); // Green
    } else if (lowerTitle.contains('error') || lowerTitle.contains('failed')) {
      return const Color(0xFFE74C3C); // Red
    } else if (lowerTitle.contains('success') || lowerTitle.contains('complete')) {
      return const Color(0xFF2ECC71); // Green
    } else {
      return const Color(0xFF4158D0); // Default Blue
    }
  }

// ✅ Get Notification Category
  String _getNotificationCategory(String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('order') || lowerTitle.contains('purchase')) {
      return 'Order';
    } else if (lowerTitle.contains('payment') || lowerTitle.contains('amount')) {
      return 'Payment';
    } else if (lowerTitle.contains('product') || lowerTitle.contains('stock')) {
      return 'Product';
    } else if (lowerTitle.contains('user') || lowerTitle.contains('customer')) {
      return 'User';
    } else if (lowerTitle.contains('offer') || lowerTitle.contains('sale')) {
      return 'Offer';
    } else if (lowerTitle.contains('enquiry') || lowerTitle.contains('query')) {
      return 'Enquiry';
    } else if (lowerTitle.contains('welcome') || lowerTitle.contains('hello')) {
      return 'Welcome';
    } else if (lowerTitle.contains('error') || lowerTitle.contains('failed')) {
      return 'Error';
    } else if (lowerTitle.contains('success') || lowerTitle.contains('complete')) {
      return 'Success';
    } else {
      return 'General';
    }
  }

// Add this helper method inside _DashboardScreenState
  Widget _buildNotificationItem({
    required String id,
    required String title,
    required String body,
    required String time,
    required bool isRead,
    required IconData icon,
    VoidCallback? onTap,
    VoidCallback? onDelete,
  }) {
    return Dismissible(
      key: Key(id),
      direction: DismissDirection.endToStart,
      background: Container(
        padding: const EdgeInsets.only(right: 16),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.8),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        if (onDelete != null) {
          onDelete();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notification dismissed: $title'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          margin: const EdgeInsets.only(bottom: 4),
          decoration: BoxDecoration(
            color: isRead
                ? (_isDarkMode ? const Color(0xFF1A1A2E) : Colors.transparent)
                : (_isDarkMode
                ? const Color(0xFF4158D0).withOpacity(0.15)
                : const Color(0xFF4158D0).withOpacity(0.05)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unread Indicator
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: isRead ? Colors.transparent : const Color(0xFF4158D0),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),

              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: isRead
                      ? null
                      : const LinearGradient(
                    colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                  ),
                  color: isRead
                      ? (_isDarkMode ? Colors.grey[800] : Colors.grey[200])
                      : null,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: isRead
                      ? (_isDarkMode ? Colors.grey[400] : Colors.grey[600])
                      : Colors.white,
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                        fontSize: 14,
                        color: isRead
                            ? (_isDarkMode ? Colors.grey[400] : Colors.grey[700])
                            : (_isDarkMode ? Colors.white : Colors.black),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 12,
                        color: _isDarkMode ? Colors.grey[500] : Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 10,
                          color: _isDarkMode ? Colors.grey[600] : Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 10,
                            color: _isDarkMode ? Colors.grey[600] : Colors.grey[400],
                          ),
                        ),
                      ],
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

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
                    return Container(
                      width: _isSidebarExpanded ? 230 : 50,
                      height: screenHeight,
                      child: _buildSidebar(),
                    );
                  },
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(isMobile, isTablet),
                  _buildTabsBar(),
                  Expanded(
                    child: _buildContentArea(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ====================== DRAWER ======================
  Widget _buildMobileDrawer() {
    return Drawer(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        decoration: BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: Column(
            children: [
              _buildDrawerHeader(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    _buildDrawerSection('MAIN'),
                    _buildDrawerItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Dashboard', const DashboardHomeContent(), icon: Icons.dashboard);
                      },
                      isSelected: _activeTab == 'Dashboard',
                    ),

                    // ==================== MASTER (Category/Subcategory/Role/Unit) ====================
                    ExpansionTile(
                      title: const Text(
                        'MASTER',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                      ),
                      leading: const Icon(Icons.folder_outlined, size: 20, color: Color(0xFF9B59B6)),
                      iconColor: const Color(0xFF9B59B6),
                      collapsedIconColor: const Color(0xFF9B59B6),
                      childrenPadding: EdgeInsets.zero,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                      initiallyExpanded: false,
                      children: [
                        _buildDrawerItem(
                          icon: Icons.people,
                          title: 'Role',
                          onTap: () {
                            Navigator.pop(context);
                            _openScreen('Role', const RoleCreateScreen(), icon: Icons.people);
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.straighten,
                          title: 'Unit',
                          onTap: () {
                            Navigator.pop(context);
                            _openScreen('Unit', const UnitCreateScreen(), icon: Icons.straighten);
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.people,
                          title: 'All Users',
                          onTap: () {
                            Navigator.pop(context);
                            _openScreen('All Users', const UserListScreen(), icon: Icons.people);
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.category,
                          title: 'Category',
                          onTap: () {
                            Navigator.pop(context);
                            _openScreen('Category', const CategoryScreen(), icon: Icons.category);
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.subtitles,
                          title: 'SubCategory',
                          onTap: () {
                            Navigator.pop(context);
                            _openScreen('SubCategory', const SubCategoryAllScreen(), icon: Icons.subtitles);
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.card_membership,
                          title: 'Real Estate Subscription',
                          onTap: () {
                            Navigator.pop(context);
                            _openScreen(
                              'Real Estate Subscription',
                              const PropertySubscriptionScreen(),
                              icon: Icons.card_membership,
                            );
                          },
                          isSelected: _activeTab == 'Real Estate Subscription',
                        ),
                      ],
                    ),

                    // ==================== ✅ OLX MASTER (NEW SECTION) ====================
                    ExpansionTile(
                      title: const Text(
                        'OLX MASTER',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                      ),
                      leading: const Icon(Icons.storefront, size: 20, color: Color(0xFF6366F1)),
                      iconColor: const Color(0xFF6366F1),
                      collapsedIconColor: const Color(0xFF6366F1),
                      childrenPadding: EdgeInsets.zero,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                      initiallyExpanded: false,
                      children: [
                        _buildDrawerItem(
                          icon: Icons.storefront,
                          title: 'OLX Category',
                          onTap: () {
                            Navigator.pop(context);
                            _openScreen('OLX Category', const OlxCategoryScreen(), icon: Icons.storefront);
                          },
                          isSelected: _activeTab == 'OLX Category',
                        ),
                        _buildDrawerItem(
                          icon: Icons.subtitles,
                          title: 'OLX Subcategory',
                          onTap: () {
                            Navigator.pop(context);
                            _openScreen('OLX Subcategory', const OlxSubcategoryScreen(), icon: Icons.subtitles);
                          },
                          isSelected: _activeTab == 'OLX Subcategory',
                        ),
                        _buildDrawerItem(
                          icon: Icons.list_alt,
                          title: 'OLX Attribute',
                          onTap: () {
                            Navigator.pop(context);
                            _openScreen('OLX Attribute', const OlxAttributeScreen(), icon: Icons.list_alt);
                          },
                          isSelected: _activeTab == 'OLX Attribute',
                        ),
                        _buildDrawerItem(
                          icon: Icons.card_membership,
                          title: 'OLX Plan',
                          onTap: () {
                            Navigator.pop(context);
                            _openScreen('OLX Plan', const OlxPlanScreen(), icon: Icons.card_membership);
                          },
                          isSelected: _activeTab == 'OLX Plan',
                        ),
                        _buildDrawerItem(
                          icon: Icons.attach_money,
                          title: 'OLX Pricing',
                          onTap: () {
                            Navigator.pop(context);
                            _openScreen('OLX Pricing', const OlxPricingScreen(), icon: Icons.attach_money);
                          },
                          isSelected: _activeTab == 'OLX Pricing',
                        ),
                        _buildDrawerItem(
                          icon: Icons.settings,
                          title: 'OLX Settings',
                          onTap: () {
                            Navigator.pop(context);
                            _openScreen('OLX Plan Settings', const OlxSettingsScreen(), icon: Icons.settings);
                          },
                          isSelected: _activeTab == 'OLX Settings',
                        ),

                        _buildDrawerItem(  // or _buildSidebarMenuItem
                          icon: Icons.forum,
                          title: 'OLX Communication Plans',
                          onTap: () {
                            Navigator.pop(context);  // only for drawer
                            _openScreen(
                              'OLX Communication Plans',
                              const OlxCommunicationPlanScreen(),
                              icon: Icons.forum,
                            );
                          },
                          isSelected: _activeTab == 'OLX Communication Plans',
                        ),


                        _buildDrawerItem(
                          icon: Icons.forum_outlined,
                          title: 'OLX Communication Settings',
                          onTap: () {
                            Navigator.pop(context);
                            _openScreen(
                              'OLX Communication Settings',
                              const OlxCommunicationSettingsScreen(),
                              icon: Icons.forum_outlined,
                            );
                          },
                          isSelected: _activeTab == 'OLX Communication Settings',
                        ),
                      ],
                    ),

                    _buildDrawerSection('PRODUCT'),
                    _buildDrawerItem(
                      icon: Icons.pending_actions,
                      title: 'Pending Product',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Pending Product', const PendingProductListScreen(), icon: Icons.pending_actions);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.check_circle,
                      title: 'Approved Product',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Approved Product', const ApprovedProductListScreen(), icon: Icons.check_circle);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.update,
                      title: 'Update Requests',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Update Requests', const UpdateRequestListScreen(), icon: Icons.update);
                      },
                    ),
                    _buildDrawerSection('COMPANY'),
                    _buildDrawerItem(
                      icon: Icons.business,
                      title: 'All Company',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('All Company', const CompanyAllScreen(), icon: Icons.business);
                      },
                    ),
                    _buildDrawerSection('AGREEMENT'),
                    _buildDrawerItem(
                      icon: Icons.description,
                      title: 'Agreement',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Agreement', AgreementScreen(), icon: Icons.description);
                      },
                    ),
                    _buildDrawerSection('FRANCHISE'),
                    _buildDrawerItem(
                      icon: Icons.storefront,
                      title: 'Franchise',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Franchise', FranchiseListScreen(), icon: Icons.storefront);
                      },
                    ),
                    _buildDrawerSection('OFFER'),
                    _buildDrawerItem(
                      icon: Icons.local_offer,
                      title: 'Offer List',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Offer List', const OfferListScreen(), icon: Icons.local_offer);
                      },
                    ),
                    _buildDrawerSection('ENQUIRY'),
                    _buildDrawerItem(
                      icon: Icons.question_answer,
                      title: 'Demo Enquiry',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Demo Enquiry', const EnquiryListScreen(), icon: Icons.question_answer);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.person,
                      title: 'User Enquiry',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('User Enquiry', const UserEnquiryScreen(), icon: Icons.person);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.person,
                      title: 'Product Enquiry',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Product Enquiry', EnquiryTabsScreen(), icon: Icons.person);
                      },
                    ),
                    _buildDrawerSection('MARKETING MASTER'),
                    _buildDrawerItem(
                      icon: Icons.people_outline,
                      title: 'Marketing Partners',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Marketing Partners', const MarketingPartnersScreen(), icon: Icons.people_outline);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.people_outline,
                      title: 'Approved Marketing Partners',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Approved Marketing Partners', const ApprovedMarketingPartnersScreen(), icon: Icons.people_outline);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Bank Details',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Bank Details', const BankDetailsScreen(), icon: Icons.account_balance_wallet_rounded);
                      },
                    ),
                    _buildDrawerSection('PROPERTIES'),
                    _buildDrawerItem(
                      icon: Icons.house,
                      title: 'Properties',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Properties', const PropertyListScreen(), icon: Icons.house);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.question_answer,
                      title: 'Property Enquiries',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Property Enquiries', const PropertyEnquiryScreen(), icon: Icons.question_answer);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.business_center,
                      title: 'Builders',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Builders', const BuildersListScreen(), icon: Icons.business_center);
                      },
                    ),
                    _buildDrawerSection('SHIPROCKET'),
                    _buildDrawerItem(
                      icon: Icons.local_shipping,
                      title: 'ShipRocket',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('ShipRocket', const ShiprocketScreen(), icon: Icons.local_shipping);
                      },
                      isSelected: _activeTab == 'ShipRocket',
                    ),
                    _buildDrawerItem(
                      icon: Icons.local_shipping,
                      title: 'Shipments',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Shipments', const ShipmentScreen(), icon: Icons.local_shipping);
                      },
                      isSelected: _activeTab == 'Shipments',
                    ),
                    _buildDrawerItem(
                      icon: Icons.assignment_return,
                      title: 'Return Orders',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen(
                          'Return Orders',
                          const ReturnOrdersScreen(),
                          icon: Icons.assignment_return,
                        );
                      },
                      isSelected: _activeTab == 'Return Orders',
                    ),
                    _buildDrawerItem(
                      icon: Icons.local_shipping,
                      title: 'Return Shipments',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen(
                          'Return Shipments',
                          const ReturnShipmentScreen(),
                          icon: Icons.local_shipping,
                        );
                      },
                      isSelected: _activeTab == 'Return Shipments',
                    ),
                    _buildDrawerItem(
                      icon: Icons.cancel_schedule_send,
                      title: 'Prepaid Cancelled Orders',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen(
                          'Prepaid Cancelled Orders',
                          const PrepaidCancelledOrdersScreen(),
                          icon: Icons.cancel_schedule_send,
                        );
                      },
                      isSelected: _activeTab == 'Prepaid Cancelled Orders',
                    ),
                    _buildDrawerItem(
                      icon: Icons.card_membership,
                      title: 'Customer Subscription Plans',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen(
                          'Customer Subscription Plans',
                          const CustomerSubscriptionPlanScreen(),
                          icon: Icons.card_membership,
                        );
                      },
                      isSelected: _activeTab == 'Customer Subscription Plans',
                    ),

                    _buildDrawerItem(
                      icon: Icons.rocket_launch_outlined,
                      title: 'Boosting Plans',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen(
                          'Boosting Plans',
                          const BoostingPlanScreen(),
                          icon: Icons.rocket_launch_outlined,
                        );
                      },
                      isSelected: _activeTab == 'Boosting Plans',
                    ),

                    _buildDrawerSection('SUBSCRIPTION'),
                    _buildDrawerItem(
                      icon: Icons.card_membership,
                      title: 'Subscription Plans',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen(
                          'Subscription Plans',
                          const SubscriptionPlanScreen(),
                          icon: Icons.card_membership,
                        );
                      },
                      isSelected: _activeTab == 'Subscription Plans',
                    ),
                    _buildDrawerSection('LOAN'),
                    _buildDrawerItem(
                      icon: Icons.assignment,
                      title: 'Loan Enquiries',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Loan Enquiries', const LoanEnquiryScreen(), icon: Icons.assignment);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.inventory_2,
                      title: 'Packing Material',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Packing Material Enquiries',
                            const PackingMaterialEnquiryScreen(),
                            icon: Icons.inventory_2);
                      },
                      isSelected: _activeTab == 'Packing Material Enquiries',
                    ),
                    _buildDrawerSection('AI & AUTOMATION'),
                    _buildDrawerItem(
                      icon: Icons.psychology,
                      title: 'AI Admin',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen(
                          'AI Admin',
                          const AiAdminScreen(),
                          icon: Icons.psychology,
                        );
                      },
                      isSelected: _activeTab == 'AI Admin',
                    ),
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

  Widget _buildDrawerFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
        ),
      ),
      child: InkWell(
        onTap: _logout,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.red[50],
          ),
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red[700], size: 20),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepPurple.withOpacity(0.05),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/images/img_2.png",
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
          letterSpacing: 1.2,
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
    final Color iconColor = _getIconColorForItem(icon, title, isSelected);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? const Color(0xFF4158D0).withOpacity(0.1) : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 20),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? const Color(0xFF4158D0)
                : (_isDarkMode ? Colors.grey[300] : Colors.grey[800]),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      ),
    );
  }

  Color _getIconColorForItem(IconData icon, String title, bool isSelected) {
    if (isSelected) return const Color(0xFF4158D0);

    switch (title) {
      case 'Marketing Head':
        return const Color(0xFF9B59B6);
      case 'Marketing Partners':
        return const Color(0xFFE67E22);
      case 'Update Requests':
        return const Color(0xFFF39C12);
      case 'Bank Details':
        return const Color(0xFFFF6584);
      case 'Franchise':
        return const Color(0xFF2ECC71);
      case 'Approved Marketing Partners':
        return const Color(0xFF4158D0);
     // case 'Amenities':  // ✅ Fixed
        return const Color(0xFF3498DB);

      case 'ShipRocket':      // ✅ नवीन केस
        return const Color(0xFF2196F3);  // Blue
      case 'Shipments':       // ✅ नवीन केस
        return const Color(0xFF00BCD4);// Cyan
      case 'Prepaid Cancelled Orders':
        return const Color(0xFFE53935); // Red
      case 'OLX Settings':
        return const Color(0xFF64748B);
      case 'Builders':
        return const Color(0xFF00796B); // Teal
      case 'Return Orders':
        return const Color(0xFFD32F2F); // Deep Orange/Red
      case 'AI Admin':
        return const Color(0xFF8B5CF6); // Purple
      case 'Packing Material':
        return const Color(0xFF8B5CF6);
      case 'Boosting Plans':
        return const Color(0xFFEF4444);

      default:
        return _getIconColor(icon, isSelected);
    }
  }

  Color _getIconColor(IconData icon, bool isSelected) {
    if (isSelected) return Colors.white;
    if (icon == Icons.dashboard) return const Color(0xFF4158D0);
    if (icon == Icons.people) return const Color(0xFF9B59B6);
    if (icon == Icons.straighten) return const Color(0xFF1ABC9C);
    if (icon == Icons.category) return const Color(0xFFF39C12);
    if (icon == Icons.subtitles) return const Color(0xFFE67E22);
    if (icon == Icons.pending_actions) return const Color(0xFFE74C3C);
    if (icon == Icons.check_circle) return const Color(0xFF2ECC71);
    if (icon == Icons.business) return const Color(0xFF3498DB);
    if (icon == Icons.description) return const Color(0xFF9B59B6);
    if (icon == Icons.local_offer) return const Color(0xFFF1C40F);
    if (icon == Icons.question_answer) return const Color(0xFFE67E22);
    if (icon == Icons.person) return const Color(0xFF1ABC9C);
    if (icon == Icons.account_balance_wallet_rounded) return const Color(0xFFFF6584);
    if (icon == Icons.people_outline) return const Color(0xFFE67E22);
    if (icon == Icons.storefront) return const Color(0xFF2ECC71);
    if (icon == Icons.apartment) return const Color(0xFF3498DB);
    if (icon == Icons.house) return const Color(0xFF2ECC71);
    if (icon == Icons.local_shipping) return const Color(0xFF2196F3);
    if (icon == Icons.assignment) return const Color(0xFF00BCD4); // Loan Enquiries color
    if (icon == Icons.card_membership) return const Color(0xFFE91E63);
    // ✅ OLX Icons
    if (icon == Icons.storefront) return const Color(0xFF6366F1);      // OLX Category
    if (icon == Icons.subtitles) return const Color(0xFF8B5CF6);       // OLX Subcategory
    if (icon == Icons.card_membership) return const Color(0xFFEC4899); // OLX Plan
    if (icon == Icons.attach_money) return const Color(0xFF10B981);    // OLX Pricing
    if (icon == Icons.settings) return const Color(0xFF64748B); // OLX Settings
    if (icon == Icons.forum) return const Color(0xFF0891B2); // OLX Communication Plans (Cyan)
    if (icon == Icons.forum_outlined) return const Color(0xFF0891B2);
    if (icon == Icons.business_center) return const Color(0xFF00796B); // Builders (Teal)
    if (icon == Icons.assignment_return) return const Color(0xFFD32F2F); // Return Orders (Deep Orange/Red)
    if (icon == Icons.psychology) return const Color(0xFF8B5CF6); // AI Admin (Purple)
// Cyan
    if (icon == Icons.cancel_schedule_send) return const Color(0xFFE53935); // ✅ नवीन line

    if (icon == Icons.rocket_launch_outlined) return const Color(0xFFEF4444); // Red
    return _isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;

    if (icon == Icons.list_alt) return const Color(0xFF0EA5E9); // OLX Attribute
    if (icon == Icons.psychology) return const Color(0xFF8B5CF6);


    if (icon == Icons.subtitles) return const Color(0xFF8B5CF6);

    if (icon == Icons.storefront) return const Color(0xFF6366F1);
  }

  // ====================== SIDEBAR ======================
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
              shrinkWrap: true,
              children: [
                _buildSidebarMenuItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  isSelected: _activeTab == 'Dashboard',
                  onTap: () => _openScreen('Dashboard', const DashboardHomeContent(), icon: Icons.dashboard),
                ),


                // ==================== MASTER (Category/Subcategory/Role/Unit) ====================
                if (_isSidebarExpanded)
                  ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    childrenPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.folder_outlined, size: 18, color: Color(0xFF9B59B6)),
                    title: const Text(
                      'MASTER',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    iconColor: const Color(0xFF9B59B6),
                    collapsedIconColor: const Color(0xFF9B59B6),
                    initiallyExpanded: false,
                    children: [
                      _buildSidebarMenuItem(
                        icon: Icons.people,
                        title: 'Role',
                        isSelected: _activeTab == 'Role',
                        onTap: () => _openScreen('Role', const RoleCreateScreen(), icon: Icons.people),
                      ),
                      _buildSidebarMenuItem(
                        icon: Icons.straighten,
                        title: 'Unit',
                        isSelected: _activeTab == 'Unit',
                        onTap: () => _openScreen('Unit', const UnitCreateScreen(), icon: Icons.straighten),
                      ),
                      _buildSidebarMenuItem(
                        icon: Icons.people,
                        title: 'All Users',
                        isSelected: _activeTab == 'All Users',
                        onTap: () => _openScreen('All Users', const UserListScreen(), icon: Icons.people),
                      ),
                      _buildSidebarMenuItem(
                        icon: Icons.category,
                        title: 'Category',
                        isSelected: _activeTab == 'Category',
                        onTap: () => _openScreen('Category', const CategoryScreen(), icon: Icons.category),
                      ),
                      _buildSidebarMenuItem(
                        icon: Icons.subtitles,
                        title: 'SubCategory',
                        isSelected: _activeTab == 'SubCategory',
                        onTap: () => _openScreen('SubCategory', const SubCategoryAllScreen(), icon: Icons.subtitles),
                      ),
                      _buildSidebarMenuItem(
                        icon: Icons.card_membership,
                        title: 'Real Estate Subscription',
                        isSelected: _activeTab == 'Real Estate Subscription',
                        onTap: () => _openScreen(
                          'Real Estate Subscription',
                          const PropertySubscriptionScreen(),
                          icon: Icons.card_membership,
                        ),
                      ),
                      _buildSidebarMenuItem(
                        icon: Icons.inventory_2,
                        title: 'Packing Material',
                        isSelected: _activeTab == 'Packing Material Enquiries',
                        onTap: () => _openScreen('Packing Material Enquiries',
                            const PackingMaterialEnquiryScreen(),
                            icon: Icons.inventory_2),
                      ),
                    ],
                  ),

                // ==================== ✅ OLX MASTER (NEW SECTION) ====================
                if (_isSidebarExpanded)
                  ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    childrenPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.storefront, size: 18, color: Color(0xFF6366F1)),
                    title: const Text(
                      'OLX MASTER',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    iconColor: const Color(0xFF6366F1),
                    collapsedIconColor: const Color(0xFF6366F1),
                    initiallyExpanded: false,
                    children: [
                      _buildSidebarMenuItem(
                        icon: Icons.storefront,
                        title: 'OLX Category',
                        isSelected: _activeTab == 'OLX Category',
                        onTap: () => _openScreen('OLX Category', const OlxCategoryScreen(), icon: Icons.storefront),
                      ),
                      _buildSidebarMenuItem(
                        icon: Icons.subtitles,
                        title: 'OLX Subcategory',
                        isSelected: _activeTab == 'OLX Subcategory',
                        onTap: () => _openScreen('OLX Subcategory', const OlxSubcategoryScreen(), icon: Icons.subtitles),
                      ),
                      _buildSidebarMenuItem(
                        icon: Icons.list_alt,
                        title: 'OLX Attribute',
                        isSelected: _activeTab == 'OLX Attribute',
                        onTap: () => _openScreen('OLX Attribute', const OlxAttributeScreen(), icon: Icons.list_alt),
                      ),
                      _buildSidebarMenuItem(
                        icon: Icons.card_membership,
                        title: 'OLX Plan',
                        isSelected: _activeTab == 'OLX Plan',
                        onTap: () => _openScreen('OLX Plan', const OlxPlanScreen(), icon: Icons.card_membership),
                      ),
                      _buildSidebarMenuItem(
                        icon: Icons.attach_money,
                        title: 'OLX Pricing',
                        isSelected: _activeTab == 'OLX Pricing',
                        onTap: () => _openScreen('OLX Pricing', const OlxPricingScreen(), icon: Icons.attach_money),
                      ),
                      _buildSidebarMenuItem(
                        icon: Icons.settings,
                        title: 'OLX Settings',
                        isSelected: _activeTab == 'OLX Settings',
                        onTap: () => _openScreen('OLX Settings', const OlxSettingsScreen(), icon: Icons.settings),
                      ),

                      _buildSidebarMenuItem(
                        icon: Icons.forum,
                        title: 'OLX Communication Plans',
                        isSelected: _activeTab == 'OLX Communication Plans',
                        onTap: () => _openScreen(
                          'OLX Communication Plans',
                          const OlxCommunicationPlanScreen(),
                          icon: Icons.forum,
                        ),
                      ),

                      _buildSidebarMenuItem(
                        icon: Icons.forum_outlined,
                        title: 'OLX Communication Settings',
                        isSelected: _activeTab == 'OLX Communication Settings',
                        onTap: () => _openScreen(
                          'OLX Communication Settings',
                          const OlxCommunicationSettingsScreen(),
                          icon: Icons.forum_outlined,
                        ),
                      ),
                    ],
                  ),

                if (_isSidebarExpanded) _buildSidebarSection('PRODUCT'),
                _buildSidebarMenuItem(
                  icon: Icons.pending_actions,
                  title: 'Pending Product',
                  isSelected: _activeTab == 'Pending Product',
                  onTap: () => _openScreen('Pending Product', const PendingProductListScreen(), icon: Icons.pending_actions),
                ),
                _buildSidebarMenuItem(
                  icon: Icons.check_circle,
                  title: 'Approved Product',
                  isSelected: _activeTab == 'Approved Product',
                  onTap: () => _openScreen('Approved Product', const ApprovedProductListScreen(), icon: Icons.check_circle),
                ),
                _buildSidebarMenuItem(
                  icon: Icons.update,
                  title: 'Update Requests',
                  isSelected: _activeTab == 'Update Requests',
                  onTap: () => _openScreen('Update Requests', const UpdateRequestListScreen(), icon: Icons.update),
                ),
                if (_isSidebarExpanded) _buildSidebarSection('COMPANY'),
                _buildSidebarMenuItem(
                  icon: Icons.business,
                  title: 'All Company',
                  isSelected: _activeTab == 'All Company',
                  onTap: () => _openScreen('All Company', const CompanyAllScreen(), icon: Icons.business),
                ),
                if (_isSidebarExpanded) _buildSidebarSection('AGREEMENT'),
                _buildSidebarMenuItem(
                  icon: Icons.description,
                  title: 'Agreement',
                  isSelected: _activeTab == 'Agreement',
                  onTap: () => _openScreen('Agreement', AgreementScreen(), icon: Icons.description),
                ),
                if (_isSidebarExpanded) _buildSidebarSection('FRANCHISE'),
                _buildSidebarMenuItem(
                  icon: Icons.storefront,
                  title: 'Franchise',
                  isSelected: _activeTab == 'Franchise',
                  onTap: () => _openScreen('Franchise', FranchiseListScreen(), icon: Icons.storefront),
                ),
                if (_isSidebarExpanded) _buildSidebarSection('OFFER'),
                _buildSidebarMenuItem(
                  icon: Icons.local_offer,
                  title: 'Offer List',
                  isSelected: _activeTab == 'Offer List',
                  onTap: () => _openScreen('Offer List', const OfferListScreen(), icon: Icons.local_offer),
                ),
                if (_isSidebarExpanded) _buildSidebarSection('ENQUIRY'),
                _buildSidebarMenuItem(
                  icon: Icons.question_answer,
                  title: 'Demo Enquiry',
                  isSelected: _activeTab == 'Demo Enquiry',
                  onTap: () => _openScreen('Demo Enquiry', const EnquiryListScreen(), icon: Icons.question_answer),
                ),
                _buildSidebarMenuItem(
                  icon: Icons.person,
                  title: 'User Enquiry',
                  isSelected: _activeTab == 'User Enquiry',
                  onTap: () => _openScreen('User Enquiry', const UserEnquiryScreen(), icon: Icons.person),
                ),
                _buildSidebarMenuItem(
                  icon: Icons.person,
                  title: 'Product Enquiry',
                  isSelected: _activeTab == 'Product Enquiry',
                  onTap: () => _openScreen('Product Enquiry', EnquiryTabsScreen(), icon: Icons.person),
                ),
                if (_isSidebarExpanded) _buildSidebarSection('MARKETING'),
                _buildSidebarMenuItem(
                  icon: Icons.people_outline,
                  title: 'Marketing Partners',
                  isSelected: _activeTab == 'Marketing Partners',
                  onTap: () => _openScreen('Marketing Partners', const MarketingPartnersScreen(), icon: Icons.people_outline),
                ),
                _buildSidebarMenuItem(
                  icon: Icons.people_outline,
                  title: 'Approved Marketing Partners',
                  isSelected: _activeTab == 'Approved Marketing Partners',
                  onTap: () => _openScreen('Approved Marketing Partners', const ApprovedMarketingPartnersScreen(), icon: Icons.people_outline),
                ),
                _buildSidebarMenuItem(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Bank Details',
                  isSelected: _activeTab == 'Bank Details',
                  onTap: () => _openScreen('Bank Details', const BankDetailsScreen(), icon: Icons.account_balance_wallet_rounded),
                ),
                if (_isSidebarExpanded) _buildSidebarSection('PROPERTIES'),
                _buildSidebarMenuItem(
                  icon: Icons.house,
                  title: 'Properties',
                  isSelected: _activeTab == 'Properties',
                  onTap: () => _openScreen('Properties', const PropertyListScreen(), icon: Icons.house),
                ),
                _buildSidebarMenuItem(
                  icon: Icons.question_answer,
                  title: 'Property Enquiries',
                  isSelected: _activeTab == 'Property Enquiries',
                  onTap: () => _openScreen('Property Enquiries', const PropertyEnquiryScreen(), icon: Icons.question_answer),
                ),
                _buildSidebarMenuItem(
                  icon: Icons.business_center,
                  title: 'Builders',
                  isSelected: _activeTab == 'Builders',
                  onTap: () => _openScreen('Builders', const BuildersListScreen(), icon: Icons.business_center),
                ),
                if (_isSidebarExpanded) _buildSidebarSection('SHIPROCKET'),
                _buildSidebarMenuItem(
                  icon: Icons.local_shipping,
                  title: 'ShipRocket',
                  isSelected: _activeTab == 'ShipRocket',
                  onTap: () => _openScreen('ShipRocket', const ShiprocketScreen(), icon: Icons.local_shipping),
                ),
                _buildSidebarMenuItem(
                  icon: Icons.local_shipping,
                  title: 'Shipments',
                  isSelected: _activeTab == 'Shipments',
                  onTap: () => _openScreen('Shipments', const ShipmentScreen(), icon: Icons.local_shipping),
                ),
                _buildSidebarMenuItem(
                  icon: Icons.assignment_return,
                  title: 'Return Orders',
                  isSelected: _activeTab == 'Return Orders',
                  onTap: () => _openScreen(
                    'Return Orders',
                    const ReturnOrdersScreen(),
                    icon: Icons.assignment_return,
                  ),
                ),
                _buildSidebarMenuItem(
                  icon: Icons.local_shipping,
                  title: 'Return Shipments',
                  isSelected: _activeTab == 'Return Shipments',
                  onTap: () => _openScreen(
                    'Return Shipments',
                    const ReturnShipmentScreen(),
                    icon: Icons.local_shipping,
                  ),
                ),
                _buildSidebarMenuItem(
                  icon: Icons.cancel_schedule_send,
                  title: 'Prepaid Cancelled Orders',
                  isSelected: _activeTab == 'Prepaid Cancelled Orders',
                  onTap: () => _openScreen(
                    'Prepaid Cancelled Orders',
                    const PrepaidCancelledOrdersScreen(),
                    icon: Icons.cancel_schedule_send,
                  ),
                ),
                _buildSidebarMenuItem(
                  icon: Icons.card_membership,
                  title: 'Customer Subscription Plans',
                  isSelected: _activeTab == 'Customer Subscription Plans',
                  onTap: () => _openScreen(
                    'Customer Subscription Plans',
                    const CustomerSubscriptionPlanScreen(),
                    icon: Icons.card_membership,
                  ),
                ),

                _buildSidebarMenuItem(
                  icon: Icons.rocket_launch_outlined,
                  title: 'Boosting Plans',
                  isSelected: _activeTab == 'Boosting Plans',
                  onTap: () => _openScreen(
                    'Boosting Plans',
                    const BoostingPlanScreen(),
                    icon: Icons.rocket_launch_outlined,
                  ),
                ),

                if (_isSidebarExpanded) _buildSidebarSection('SUBSCRIPTION'),
                _buildSidebarMenuItem(
                  icon: Icons.card_membership,
                  title: 'Subscription Plans',
                  isSelected: _activeTab == 'Subscription Plans',
                  onTap: () => _openScreen(
                    'Subscription Plans',
                    const SubscriptionPlanScreen(),
                    icon: Icons.card_membership,
                  ),
                ),
                if (_isSidebarExpanded) _buildSidebarSection('LOAN'),
                _buildSidebarMenuItem(
                  icon: Icons.assignment,
                  title: 'Loan Enquiries',
                  isSelected: _activeTab == 'Loan Enquiries',
                  onTap: () => _openScreen('Loan Enquiries', const LoanEnquiryScreen(), icon: Icons.assignment),
                ),

                if (_isSidebarExpanded) _buildSidebarSection('AI & AUTOMATION'),
                _buildSidebarMenuItem(
                  icon: Icons.psychology,
                  title: 'AI Admin',
                  isSelected: _activeTab == 'AI Admin',
                  onTap: () => _openScreen(
                    'AI Admin',
                    const AiAdminScreen(),
                    icon: Icons.psychology,
                  ),
                ),
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
            child: Icon(
              Icons.chevron_right,
              size: 18,
              color: _isDarkMode ? Colors.white70 : Colors.grey[700],
            ),
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
              child: Image.asset(
                "assets/images/img_2.png",
                height: 70,
                fit: BoxFit.contain,
              ),
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
              child: Icon(
                Icons.chevron_left,
                size: 18,
                color: _isDarkMode ? Colors.white70 : Colors.grey[700],
              ),
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

  Widget _buildSidebarMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    Color iconColor;
    if (isSelected) {
      iconColor = Colors.white;
    } else {
      switch (title) {
        case 'Marketing Head':
          iconColor = const Color(0xFF9B59B6);
          break;
        case 'Marketing Partners':
          iconColor = const Color(0xFFE67E22);
          break;
        case 'Update Requests':
          iconColor = const Color(0xFFF39C12);
          break;
        case 'Approved Marketing Partners':
          iconColor = const Color(0xFF4158D0);
          break;
        case 'ShipRocket':      // ✅ नवीन
          iconColor = const Color(0xFF2196F3);
          break;
        case 'Shipments':       // ✅ नवीन
          iconColor = const Color(0xFF00BCD4);
          break;
        case 'Prepaid Cancelled Orders':                    // ✅ नवीन case
          iconColor = const Color(0xFFE53935);              // Red
          break;
        default:
          iconColor = _getIconColor(icon, isSelected);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
                Icon(
                  icon,
                  size: 18,
                  color: iconColor,
                ),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : (_isDarkMode ? Colors.grey[300] : Colors.grey[800]),
                      ),
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

  Widget _buildSidebarFooter() {
    if (!_isSidebarExpanded) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        child: InkWell(
          onTap: _logout,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.logout,
              size: 20,
              color: Colors.red[700],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  child: Text(
                    "A",
                    style: TextStyle(
                      color: Color(0xFF4158D0),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
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
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Admin User",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "admin@qnxmart.com",
                  style: TextStyle(
                    fontSize: 9,
                    color: _isDarkMode ? Colors.grey[500] : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.light_mode : Icons.dark_mode,
              size: 16,
              color: _isDarkMode ? Colors.yellow : Colors.grey[600],
            ),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: _logout,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.logout,
                size: 16,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ====================== TOP BAR ======================
  Widget _buildTopBar(bool isMobile, bool isTablet) {
    return Container(
      height: isMobile ? 60 : 70,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: (_isDarkMode ? Colors.black : Colors.grey).withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isMobile)
            IconButton(
              icon: Icon(
                Icons.menu,
                color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
                size: 24,
              ),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                height: isMobile ? 38 : 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isDarkMode
                        ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                        : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: _isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : const Color(0xFF4158D0).withOpacity(0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4158D0).withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                        ).createShader(bounds),
                        child: Icon(
                          Icons.search_rounded,
                          size: isMobile ? 18 : 20,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: isMobile ? 'Search...' : 'Search products, orders...',
                          hintStyle: TextStyle(
                            color: _isDarkMode
                                ? Colors.grey[500]
                                : const Color(0xFF94A3B8),
                            fontSize: isMobile ? 12 : 13,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 0,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: isMobile ? 12 : 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.shortcut_rounded,
                          size: isMobile ? 12 : 14,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildPremiumIconButton(
            icon: Icons.notifications_outlined,
            count: _notificationCount,
            onTap: _showNotificationsDialog,  // ✅ हे method call होत आहे का?
            isMobile: isMobile,
          ),
          const SizedBox(width: 8),
          _buildBannerButton(isMobile),
          const SizedBox(width: 4),
          _buildPremiumRegistrationButton(isMobile),
          const SizedBox(width: 4),
          _buildUpdateAmountButton(isMobile),
        ],
      ),
    );
  }
  Widget _buildUpdateAmountButton(bool isMobile) {
    return AnimatedBuilder(
      animation: _borderAnimationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: _borderColorAnimation.value ?? const Color(0xFF11998E),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (_borderColorAnimation.value ?? const Color(0xFF11998E))
                    .withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showUpdateAmountDialog,
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 14,
                  vertical: isMobile ? 8 : 10,  // ✅ Reference height
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.currency_rupee_rounded,
                      size: isMobile ? 14 : 16,
                      color: Colors.white,
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: 6),
                      Text(
                        'Update Amount',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPremiumIconButton({
    required IconData icon,
    int? count,
    required VoidCallback onTap,
    required bool isMobile,
  }) {
    final unreadCount = NotificationService.getUnreadCount();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Notification Button
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: isMobile ? 38 : 42,
            height: isMobile ? 38 : 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _isDarkMode
                    ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                    : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF4158D0).withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4158D0).withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
              size: isMobile ? 18 : 20,
            ),
          ),
        ),
        // ✅ Badge - Shows correct count
        if (unreadCount > 0)
          Positioned(
            right: -2,
            top: -2,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFC850C0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF6B35).withOpacity(0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              constraints: BoxConstraints(
                minWidth: unreadCount > 9 ? 20 : 18,
                minHeight: 18,
              ),
              child: Center(
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }


  Widget _buildPremiumRegistrationButton(bool isMobile) {
    return AnimatedBuilder(
      animation: _borderAnimationController,
      builder: (context, child) {
        return Tooltip(  // ✅ Tooltip wrap केलं
          message: 'All User Registration',  // ✅ Tooltip message
          preferBelow: false,
          child: Container(
            margin: const EdgeInsets.only(left: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: _borderColorAnimation.value ?? const Color(0xFF4158D0),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_borderColorAnimation.value ?? const Color(0xFF4158D0))
                      .withOpacity(0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _openScreen(
                    'Admin Create',
                    const AdminCreateScreen(),
                    icon: Icons.admin_panel_settings,
                  );
                },
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 8 : 10,  // ✅ Update Amount सारखंच
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.person_add_alt_1,
                        size: isMobile ? 16 : 18,
                        color: Colors.white,
                      ),
                      if (!isMobile) ...[
                        const SizedBox(width: 6),
                        Text(
                          'Registration',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBannerButton(bool isMobile) {
    return AnimatedBuilder(
      animation: _borderAnimationController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: _borderColorAnimation.value ?? const Color(0xFF4158D0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (_borderColorAnimation.value ?? const Color(0xFF4158D0))
                    .withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _openScreen(
                  'Banner Management',
                  const BannerManagementScreen(),
                  icon: Icons.image,
                );
              },
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 10 : 14,
                  vertical: isMobile ? 8 : 10,  // ✅ Update Amount सारखंच
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.image,
                      size: isMobile ? 16 : 18,
                      color: Colors.white,
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: 6),
                      Text(
                        'Banner',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ====================== TABS BAR ======================
  Widget _buildTabsBar() {
    if (_openTabs.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      color: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: _openTabs.length,
              itemBuilder: (context, index) {
                final tab = _openTabs[index];
                final isSelected = _activeTab == tab['title'];

                return Container(
                  margin: const EdgeInsets.only(right: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _activeTab = tab['title'];
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                            colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                              : null,
                          color: isSelected ? null : (_isDarkMode ? Colors.grey[800] : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              tab['icon'],
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : (_isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tab['title'],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (_isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (tab['closable'] == true) ...[
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _closeTab(tab['title']),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withOpacity(0.2)
                                        : (_isDarkMode ? Colors.grey[600] : Colors.grey)?.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 10,
                                    color: isSelected
                                        ? Colors.white
                                        : (_isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_openTabs.length > 1)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _closeAllTabs,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.close, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Close All',
                          style: TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    return Container(
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
        child: _tabScreens[_activeTab] ?? const DashboardHomeContent(),
      ),
    );
  }
}

// ====================== DASHBOARD HOME CONTENT ======================
class DashboardHomeContent extends StatefulWidget {
  const DashboardHomeContent({super.key});

  @override
  State<DashboardHomeContent> createState() => _DashboardHomeContentState();
}

class _DashboardHomeContentState extends State<DashboardHomeContent> with TickerProviderStateMixin {
  late AnimationController _revenueController;
  late AnimationController _ordersController;
  late Animation<double> _revenueAnimation;
  late Animation<double> _ordersAnimation;
  final DashboardService dashboardService = DashboardService();

  // Dashboard Counts
  int totalCompanies = 0;
  int totalProducts = 0;
  int totalEnquiry = 0;
  bool _isLoadingCounts = true;

  // Marketing Partners
  final ApprovedMarketingPartnerService _partnerService = ApprovedMarketingPartnerService();
  int marketingPartnerCount = 0;
  bool _isLoadingPartnerCount = true;

  // ✅ NEW: Paid Companies
  int paidCompaniesCount = 0;
  bool _isLoadingPaidCompanies = true;

  // ✅ NEW: Pending Amount
  int pendingAmount = 0;
  bool _isLoadingPendingAmount = true;
  int paidEnquiriesCount = 0;
  bool _isLoadingPaidEnquiries = true;

  // ✅ NEW: Complete Enquiries (from new API)
  int completeEnquiriesCountApi = 0;
  bool _isLoadingCompleteEnquiriesApi = true;

  // ✅ NEW: Incomplete Enquiries (from new API)
  int incompleteEnquiriesCount = 0;
  bool _isLoadingIncompleteEnquiries = true;

  // ✅ NEW: Unpaid Enquiries
  int unpaidEnquiriesCount = 0;
  bool _isLoadingUnpaidEnquiries = true;
  // Latest Companies
  final LatestCompanyService _latestCompanyService = LatestCompanyService();
  List<LatestCompany> _latestCompanies = [];
  bool _isLoadingCompanies = true;

  final LatestEnquiryService _latestEnquiryService = LatestEnquiryService();
  List<LatestEnquiry> _latestEnquiries = [];
  bool _isLoadingEnquiries = true;

  final LatestProductService _latestProductService = LatestProductService();
  List<LatestProduct> _latestProducts = [];
  bool _isLoadingProducts = true;

  String _selectedPeriod = 'This Week';

  @override
  void initState() {
    super.initState();
    _fetchLatestCompanies();
    _fetchLatestEnquiries();
    _fetchLatestProducts();
    _fetchDashboardCounts();
    _fetchMarketingPartnerCount();
    _fetchPaidCompaniesCount();     // ✅ NEW
    _fetchPendingAmount();          // ✅ NEW
    _fetchPaidUnpaidEnquiryCounts();
    _fetchCompleteEnquiryCounts();


    _revenueController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _ordersController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _revenueAnimation = Tween<double>(begin: 0, end: 4567890).animate(
      CurvedAnimation(parent: _revenueController, curve: Curves.easeOutCubic),
    );

    _ordersAnimation = Tween<double>(begin: 0, end: 1847).animate(
      CurvedAnimation(parent: _ordersController, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _fetchPaidUnpaidEnquiryCounts() async {
    try {
      final service = PaidUnpaidEnquiryService();
      final response = await service.getPaidUnpaidEnquiryCounts();
      if (mounted) {
        setState(() {
          paidEnquiriesCount = response.data.paidEnquiries;
          unpaidEnquiriesCount = response.data.unpaidEnquiries;
          _isLoadingPaidEnquiries = false;
          _isLoadingUnpaidEnquiries = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPaidEnquiries = false;
          _isLoadingUnpaidEnquiries = false;
        });
      }
      print('Error fetching paid/unpaid enquiry counts: $e');
    }
  }

  // ✅ NEW: Fetch Complete/Incomplete Enquiry Counts
  Future<void> _fetchCompleteEnquiryCounts() async {
    try {
      final service = CompleteEnquiryService();
      final response = await service.getCompleteEnquiryCounts();
      if (mounted) {
        setState(() {
          completeEnquiriesCountApi = response.data.completeEnquiries;
          incompleteEnquiriesCount = response.data.incompleteEnquiries;
          _isLoadingCompleteEnquiriesApi = false;
          _isLoadingIncompleteEnquiries = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCompleteEnquiriesApi = false;
          _isLoadingIncompleteEnquiries = false;
        });
      }
      print('Error fetching complete enquiry counts: $e');
    }
  }

  Future<void> _fetchDashboardCounts() async {
    try {
      final companyRes = await DashboardService().getCompanyCount();
      final productRes = await DashboardService().getProductCount();
      final enquiryRes = await dashboardService.getEnquiryCount();

      // ✅ mounted चेक घाला
      if (mounted) {
        setState(() {
          totalCompanies = companyRes.total;
          totalProducts = productRes.approvedProductCount;
          totalEnquiry = enquiryRes.count;
          _isLoadingCounts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCounts = false);
      }
      print("Dashboard counts error: $e");
    }
  }

  Future<void> _fetchMarketingPartnerCount() async {
    try {
      final response = await _partnerService.getCount();
      if (mounted) { // ✅ हे घाला
        setState(() {
          marketingPartnerCount = response.count;
          _isLoadingPartnerCount = false;
        });
      }
    } catch (e) {
      if (mounted) { // ✅ हे घाला
        setState(() => _isLoadingPartnerCount = false);
      }
      print("Marketing partner count error: $e");
    }
  }

  // ✅ NEW: Fetch Paid Companies Count
  Future<void> _fetchPaidCompaniesCount() async {
    try {
      final response = await PaidCompanyService().getPaidCompaniesCount();
      if (mounted) { // ✅ हे घाला
        setState(() {
          paidCompaniesCount = response.count;
          _isLoadingPaidCompanies = false;
        });
      }
    } catch (e) {
      if (mounted) { // ✅ हे घाला
        setState(() => _isLoadingPaidCompanies = false);
      }
      print("Paid companies count error: $e");
    }
  }

  // ✅ NEW: Fetch Pending Amount
  Future<void> _fetchPendingAmount() async {
    try {
      final response = await PaidCompanyService().getUnpaidCompaniesPendingAmount();
      if (mounted) { // ✅ हे घाला
        setState(() {
          pendingAmount = response.totalPendingAmount;
          _isLoadingPendingAmount = false;
        });
      }
    } catch (e) {
      if (mounted) { // ✅ हे घाला
        setState(() => _isLoadingPendingAmount = false);
      }
      print("Pending amount error: $e");
    }
  }

  Future<void> _fetchLatestCompanies() async {
    try {
      final response = await _latestCompanyService.fetchLatestCompanies();
      if (mounted) { // ✅ हे घाला
        setState(() {
          _latestCompanies = response.data;
          _isLoadingCompanies = false;
        });
      }
    } catch (e) {
      if (mounted) { // ✅ हे घाला
        setState(() => _isLoadingCompanies = false);
      }
      print('Error fetching companies: $e');
    }
  }

  Future<void> _fetchLatestEnquiries() async {
    try {
      final response = await _latestEnquiryService.fetchLatestEnquiries();
      if (mounted) { // ✅ हे घाला
        setState(() {
          _latestEnquiries = response.data;
          _isLoadingEnquiries = false;
        });
      }
    } catch (e) {
      if (mounted) { // ✅ हे घाला
        setState(() => _isLoadingEnquiries = false);
      }
      print('Error fetching enquiries: $e');
    }
  }

  Future<void> _fetchLatestProducts() async {
    try {
      final response = await _latestProductService.fetchLatestProducts();
      if (mounted) { // ✅ हे घाला
        setState(() {
          _latestProducts = response.data;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) { // ✅ हे घाला
        setState(() => _isLoadingProducts = false);
      }
      print('Error fetching products: $e');
    }
  }


  Future<int> _fetchPendingProductsCount() async {
    try {
      final response = await PendingProductService().getPendingProducts();
      return response.data.length;
    } catch (e) {
      print('Error fetching pending products: $e');
      return 0;
    }
  }

  Future<int> _fetchAllEnquiriesCount() async {
    try {
      final pending = await PendingEnquiryService.fetchPendingEnquiries();
      final approved = await ApprovedEnquiryService.fetchApprovedEnquiries();
      return pending.data.length + approved.data.length;
    } catch (e) {
      print('Error fetching enquiries: $e');
      return 0;
    }
  }

  Future<int> _fetchApprovedEnquiriesCount() async {
    try {
      final response = await ApprovedEnquiryService.fetchApprovedEnquiries();
      return response.data.length;
    } catch (e) {
      print('Error fetching approved enquiries: $e');
      return 0;
    }
  }

  Future<int> _fetchPaymentRequestsCount() async {
    try {
      final response = await PaymentRequestService().getPendingWithdrawRequests();
      return response.data.length;
    } catch (e) {
      print('Error fetching payment requests: $e');
      return 0;
    }
  }

  @override
  void dispose() {
    _revenueController.dispose();
    _ordersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return Container(
      color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F5FA),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark, isMobile, isTablet),
            const SizedBox(height: 20),
            _buildStatsGrid(isDark, isMobile, isTablet),
            const SizedBox(height: 20),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildRevenueChart(isDark)),
                  const SizedBox(width: 16),
                  Expanded(flex: 1, child: _buildRecentActivities(isDark)),
                ],
              )
            else
              Column(
                children: [
                  _buildRevenueChart(isDark),
                  const SizedBox(height: 16),
                  _buildRecentActivities(isDark),
                ],
              ),
            const SizedBox(height: 20),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: _buildRecentOrders(isDark)),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _buildLatestProducts(isDark)),
                ],
              )
            else
              Column(
                children: [
                  _buildRecentOrders(isDark),
                  const SizedBox(height: 16),
                  _buildLatestProducts(isDark),
                ],
              ),
            const SizedBox(height: 20),
            _buildQuickStatsFooter(isDark, isMobile, isTablet),
          ],
        ),
      ),
    );
  }

  Widget _buildPaidEnquiriesCard(bool isDark) {
    return _buildNewStatCard(
      title: 'Paid Enquiries',
      value: _isLoadingPaidEnquiries ? '...' : paidEnquiriesCount.toString(),
      icon: Icons.paid,
      color: const Color(0xFF2ECC71), // Green
      isDark: isDark,
      onTap: () {
        // Navigate to Approved Enquiries Screen with filter or show paid only
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ApprovedEnquiriesScreen()),
        );
      },
    );
  }

  Widget _buildCompleteEnquiriesApiCard(bool isDark) {
    return _buildNewStatCard(
      title: 'Complete Enquiries',
      value: _isLoadingCompleteEnquiriesApi ? '...' : completeEnquiriesCountApi.toString(),
      icon: Icons.done_all,
      color: const Color(0xFF2ECC71), // Green
      isDark: isDark,
      onTap: () {
        // Navigate to Approved Enquiries Screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ApprovedEnquiriesScreen()),
        );
      },
    );
  }

// ✅ NEW: Incomplete Enquiries Card
  Widget _buildIncompleteEnquiriesCard(bool isDark) {
    return _buildNewStatCard(
      title: 'Incomplete Enquiries',
      value: _isLoadingIncompleteEnquiries ? '...' : incompleteEnquiriesCount.toString(),
      icon: Icons.pending,
      color: const Color(0xFFFF6B35), // Orange
      isDark: isDark,
      onTap: () {
        // Navigate to Approved Enquiries Screen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ApprovedEnquiriesScreen()),
        );
      },
    );
  }

// ✅ NEW: Unpaid Enquiries Card
  Widget _buildUnpaidEnquiriesCard(bool isDark) {
    return _buildNewStatCard(
      title: 'Unpaid Enquiries',
      value: _isLoadingUnpaidEnquiries ? '...' : unpaidEnquiriesCount.toString(),
      icon: Icons.currency_rupee,
      color: const Color(0xFFFF6B35), // Orange
      isDark: isDark,
      onTap: () {
        // Navigate to Approved Enquiries Screen with filter or show unpaid only
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ApprovedEnquiriesScreen()),
        );
      },
    );
  }

  Widget _buildHeader(bool isDark, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text(
                  "Good " + (DateTime.now().hour < 12 ? "Morning" : "Afternoon"),
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  "Admin!",
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 24,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                      ).createShader(const Rect.fromLTWH(0, 0, 150, 50)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // ====================== STATS GRID - 6 CARDS ======================
  Widget _buildStatsGrid(bool isDark, bool isMobile, bool isTablet) {
    int crossAxisCount = 7; // Desktop साठी 6 कार्ड एका ओळीत
    if (isMobile) {
      crossAxisCount = 2; // मोबाईल साठी 2 कार्ड
    } else if (isTablet) {
      crossAxisCount = 3; // टॅब्लेट साठी 3 कार्ड
    }
    // Show loading state
    if (_isLoadingCounts || _isLoadingPartnerCount || _isLoadingPaidCompanies || _isLoadingPendingAmount) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: List.generate(6, (index) =>
            _buildNewStatCard(
              title: '',
              value: '',
              icon: Icons.timer,
              color: Colors.grey,
              isDark: isDark,
              onTap: () {},
            )
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        // Card 1: Total Companies
        // Card 1: Total Companies
        _buildNewStatCard(
          title: 'Total Companies',
          value: totalCompanies.toString(),
          icon: Icons.business,
          color: const Color(0xFF9B59B6),
          isDark: isDark,
          onTap: () {
            // ✅ CompanyAllScreen उघडा
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CompanyAllScreen()),
            );
          },
        ),
        // Card 2: Total Products
        // Card 2: Total Products
        _buildNewStatCard(
          title: 'Approved Products',
          value: totalProducts.toString(),
          icon: Icons.inventory,
          color: const Color(0xFFF39C12),
          isDark: isDark,
          onTap: () {
            // ✅ ApprovedProductListScreen उघडा
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ApprovedProductListScreen()),
            );
          },
        ),
        // Card 3: Total Enquiries
        // Card 3: Total Enquiries
        _buildNewStatCard(
          title: 'Demo Enquiries',
          value: totalEnquiry.toString(),
          icon: Icons.question_answer,
          color: const Color(0xFF2ECC71),
          isDark: isDark,
          onTap: () {
            // ✅ EnquiryListScreen उघडा
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EnquiryListScreen()),
            );
          },
        ),
        // Card 4: Marketing Partners
        _buildMarketingPartnersCard(isDark),
        // Card 5: Paid Companies (NEW)
        _buildPaidCompaniesCard(isDark),
        // Card 6: Pending Amount (NEW)
        _buildPendingAmountCard(isDark),

        // ✅ NEW: Pending Products Card
        _buildPendingProductsCard(isDark),

        // ✅ NEW: All Enquiries Card
        _buildAllEnquiriesCard(isDark),

        // ✅ NEW: Approved Enquiries Card
        _buildApprovedEnquiriesCard(isDark),

        // ✅ NEW: Payment Requests Card
        _buildPaymentRequestsCard(isDark),

        // Card 7: Paid Enquiries (NEW)
        _buildPaidEnquiriesCard(isDark),
        // Card 8: Unpaid Enquiries (NEW)
        _buildUnpaidEnquiriesCard(isDark),
        _buildCompleteEnquiriesApiCard(isDark), // ✅ NEW - From new API
        _buildIncompleteEnquiriesCard(isDark),  // ✅ NEW - From new API

      ],
    );
  }

  // ====================== CARD WIDGETS ======================

  // Card 4: Marketing Partners
  Widget _buildMarketingPartnersCard(bool isDark) {
    return _buildNewStatCard(
      title: 'Partner Commission',
      value: _isLoadingPartnerCount ? '...' : marketingPartnerCount.toString(),
      icon: Icons.people_outline,
      color: const Color(0xFF4158D0),
      isDark: isDark,
      onTap: () {
        // ✅ Navigate to Marketing Partner Commission List
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const MarketingPartnerCommissionListScreen(),
          ),
        );
      },
    );
  }

  // ✅ NEW: Card 5 - Paid Companies
  Widget _buildPaidCompaniesCard(bool isDark) {
    return _buildNewStatCard(
      title: 'Paid Companies',
      value: _isLoadingPaidCompanies ? '...' : paidCompaniesCount.toString(),
      icon: Icons.payments,
      color: const Color(0xFFE74C3C), // Red color
      isDark: isDark,
      onTap: () {
        // Optional: Navigate to paid companies list
      },
    );
  }

  // ✅ NEW: Card 6 - Pending Amount
  Widget _buildPendingAmountCard(bool isDark) {
    return _buildNewStatCard(
      title: 'Pending Amount',
      value: _isLoadingPendingAmount ? '...' : '₹${pendingAmount.toString()}',
      icon: Icons.currency_rupee,
      color: const Color(0xFFFF6B35), // Orange color
      isDark: isDark,
      onTap: () {
        // Optional: Navigate to pending payments list
      },
    );
  }

  Widget _buildPendingProductsCard(bool isDark) {
    return FutureBuilder<int>(
      future: _fetchPendingProductsCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return _buildNewStatCard(
          title: 'Pending Products',
          value: snapshot.connectionState == ConnectionState.waiting ? '...' : count.toString(),
          icon: Icons.pending_actions,
          color: const Color(0xFFFF6B35), // Orange
          isDark: isDark,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PendingProductListScreen()),
            );
          },
        );
      },
    );
  }

// Card: All Enquiries
  Widget _buildAllEnquiriesCard(bool isDark) {
    return FutureBuilder<int>(
      future: _fetchAllEnquiriesCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return _buildNewStatCard(
          title: 'All Enquiries',
          value: snapshot.connectionState == ConnectionState.waiting ? '...' : count.toString(),
          icon: Icons.question_answer,
          color: const Color(0xFF4158D0), // Blue
          isDark: isDark,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EnquiryTabsScreen()),
            );
          },
        );
      },
    );
  }

// Card: Approved Enquiries
  Widget _buildApprovedEnquiriesCard(bool isDark) {
    return FutureBuilder<int>(
      future: _fetchApprovedEnquiriesCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return _buildNewStatCard(
          title: 'Approved Enquiries',
          value: snapshot.connectionState == ConnectionState.waiting ? '...' : count.toString(),
          icon: Icons.check_circle,
          color: const Color(0xFF2ECC71), // Green
          isDark: isDark,
          onTap: () {
            // EnquiryTabsScreen चा Approved tab उघडा
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ApprovedEnquiriesScreen()),
            );
          },
        );
      },
    );
  }

// Card: Payment Requests
  Widget _buildPaymentRequestsCard(bool isDark) {
    return FutureBuilder<int>(
      future: _fetchPaymentRequestsCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;
        return _buildNewStatCard(
          title: 'Payment Requests',
          value: snapshot.connectionState == ConnectionState.waiting ? '...' : count.toString(),
          icon: Icons.payments,
          color: const Color(0xFF9B59B6), // Purple
          isDark: isDark,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PendingPaymentRequestsScreen()),
            );
          },
        );
      },
    );
  }
  Widget _buildNewStatCard({
    required String title,
    required String value,
    String prefix = '',
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;

        final bool isVerySmall = cardWidth < 150;
        final bool isSmall = cardWidth < 180;

        final double iconSize = isVerySmall ? 20 : (isSmall ? 24 : 36); // Increased
        final double valueFontSize = isVerySmall ? 18 : (isSmall ? 22 : 36); // Increased
        final double titleFontSize = isVerySmall ? 10 : (isSmall ? 11 : 16); // Increased
        final double iconPadding = isVerySmall ? 1 : (isSmall ? 2 : 8);
        final double horizontalPadding = isVerySmall ? 1 : (isSmall ? 2 : 8);
        final double verticalPadding = (isVerySmall || isSmall) ? 4 : 8;
        final bool showArrow = !isVerySmall;

        return _HoverCard(
          onTap: onTap,
          builder: (isHover) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [color.withOpacity(0.15), color.withOpacity(0.05)]
                      : [color.withOpacity(0.1), Colors.white],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : color).withOpacity(isHover ? 0.2 : 0.05),
                    blurRadius: isHover ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: isDark ? color.withOpacity(0.3) : color.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.all(iconPadding),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: iconSize, color: color),
                      ),
                      if (showArrow)
                        Icon(
                          Icons.arrow_forward_ios,
                          size: iconSize * 0.45,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                    ],
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        height: 1.0,
                        color: isHover ? color : (isDark ? Colors.white : Colors.black),
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            if (prefix.isNotEmpty)
                              TextSpan(
                                text: prefix,
                                style: TextStyle(
                                  fontSize: valueFontSize * 0.8,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            TextSpan(text: value),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                      letterSpacing: 0.2,
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ====================== REVENUE CHART ======================
  Widget _buildRevenueChart(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  "Revenue Overview",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  _buildLegendItem('This Year', const Color(0xFF4158D0), isDark),
                  _buildLegendItem('Last Year', Colors.grey, isDark),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 300,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const months = [
                          "Jan", "Feb", "Mar", "Apr", "May", "Jun",
                          "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            months[value.toInt()],
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.grey[400] : Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: const Color(0xFF4158D0),
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    spots: const [
                      FlSpot(0, 3), FlSpot(1, 4), FlSpot(2, 3.5),
                      FlSpot(3, 5), FlSpot(4, 4), FlSpot(5, 6),
                      FlSpot(6, 5), FlSpot(7, 6.5), FlSpot(8, 6),
                      FlSpot(9, 7), FlSpot(10, 6.5), FlSpot(11, 8),
                    ],
                  ),
                  LineChartBarData(
                    isCurved: true,
                    color: Colors.grey,
                    barWidth: 2,
                    dotData: FlDotData(show: false),
                    spots: const [
                      FlSpot(0, 2), FlSpot(1, 3), FlSpot(2, 2.5),
                      FlSpot(3, 4), FlSpot(4, 3.5), FlSpot(5, 5),
                      FlSpot(6, 4), FlSpot(7, 5.5), FlSpot(8, 5),
                      FlSpot(9, 6), FlSpot(10, 5.5), FlSpot(11, 6.5),
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

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // ====================== RECENT ACTIVITIES ======================
  Widget _buildRecentActivities(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Latest Companies",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.circle, color: Colors.green, size: 6),
              ),
            ],
          ),
          const SizedBox(height: 45),
          if (_isLoadingCompanies)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_latestCompanies.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text("No companies found", style: TextStyle(fontSize: 12)),
              ),
            )
          else
            ...List.generate(_latestCompanies.length, (index) {
              return _buildCompanyItem(_latestCompanies[index], isDark, index);
            }),
        ],
      ),
    );
  }

  Widget _buildCompanyItem(LatestCompany company, bool isDark, int index) {
    final List<Color> colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal];
    final Color itemColor = colors[index % colors.length];

    String getImageUrl(String? s3Key) {
      if (s3Key == null || s3Key.isEmpty) return '';
      if (s3Key.startsWith('http')) return s3Key;
      return '${ApiUrls.baseUrl}/$s3Key';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [itemColor, itemColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: company.logoS3Key != null && company.logoS3Key!.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  getImageUrl(company.logoS3Key),
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Text(
                      company.name.isNotEmpty ? company.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    );
                  },
                ),
              )
                  : Text(
                company.name.isNotEmpty ? company.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        company.ownerName,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ====================== RECENT ORDERS ======================
  Widget _buildRecentOrders(bool isDark) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recent Enquiries",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(40, 20),
                ),
                child: const Text("View All", style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_isLoadingEnquiries)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_latestEnquiries.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text("No recent enquiries", style: TextStyle(fontSize: 12)),
              ),
            )
          else
            ..._latestEnquiries.map((enquiry) => _buildEnquiryItem(enquiry, isDark)).toList(),
        ],
      ),
    );
  }

  Widget _buildEnquiryItem(LatestEnquiry enquiry, bool isDark) {
    final List<Color> colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal];
    final Color avatarColor = colors[enquiry.id % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [avatarColor, avatarColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                enquiry.personName.isNotEmpty ? enquiry.personName[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enquiry.personName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 2,
                      height: 2,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        enquiry.shopName,
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: avatarColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  enquiry.companyName,
                  style: TextStyle(
                    fontSize: 8,
                    color: avatarColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ====================== LATEST PRODUCTS ======================
  Widget _buildLatestProducts(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(
                child: Text(
                  "Latest Products",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isLoadingProducts)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_latestProducts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text("No latest products", style: TextStyle(fontSize: 12)),
              ),
            )
          else
            isDesktop
                ? _buildDesktopDataTable(isDark)
                : Scrollbar(
              thickness: 6,
              radius: const Radius.circular(10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildDesktopDataTable(isDark),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopDataTable(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: DataTable(
            columnSpacing: 8,
            horizontalMargin: 0,
            headingRowHeight: 32,
            dataRowHeight: 44,
            headingRowColor: MaterialStateProperty.all(
              isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
            ),
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[300] : const Color(0xFF4158D0),
              fontSize: 11,
            ),
            columns: const [
              DataColumn(label: Text("Sr No")),
              DataColumn(label: Text("Thumbnail")),
              DataColumn(label: Text("Name")),
              DataColumn(label: Text("Company")),
              DataColumn(label: Text("Category")),
              DataColumn(label: Text("Brand")),
            ],
            rows: _latestProducts.asMap().entries.map((entry) {
              int index = entry.key;
              var product = entry.value;
              return DataRow(cells: [
                DataCell(
                  SizedBox(
                    width: 35,
                    child: Text(
                      (index + 1).toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  product.thumbnail.isNotEmpty
                      ? Image.network(
                    product.thumbnail,
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 30,
                        height: 30,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, size: 18),
                      );
                    },
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        width: 30,
                        height: 30,
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  )
                      : Container(
                    width: 28,
                    height: 28,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 16),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 80,
                    child: Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 80,
                    child: Text(
                      product.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 65,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 65,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.brandName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.purple[700],
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }

  // ====================== QUICK STATS FOOTER ======================
  Widget _buildQuickStatsFooter(bool isDark, bool isMobile, bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (isMobile || isTablet) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceEvenly,
              children: _getQuickStats(isDark),
            );
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _getQuickStats(isDark),
            );
          }
        },
      ),
    );
  }

  List<Widget> _getQuickStats(bool isDark) {
    return [
      _buildQuickStat(
        label: 'Conversion',
        value: '3.24%',
        change: '+0.5%',
        icon: Icons.trending_up,
        color: Colors.green,
        isDark: isDark,
      ),
      _buildQuickStat(
        label: 'Avg. Order',
        value: '₹2.4k',
        change: '+12%',
        icon: Icons.shopping_bag,
        color: Colors.blue,
        isDark: isDark,
      ),
      _buildQuickStat(
        label: 'Return',
        value: '1.2%',
        change: '-0.3%',
        icon: Icons.assignment_return,
        color: Colors.orange,
        isDark: isDark,
      ),
      _buildQuickStat(
        label: 'Satisfaction',
        value: '4.8',
        change: '+0.2',
        icon: Icons.star,
        color: Colors.purple,
        isDark: isDark,
      ),
    ];
  }

  Widget _buildQuickStat({
    required String label,
    required String value,
    required String change,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      width: 75,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 12),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: 7,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 1),
          Text(
            change,
            style: TextStyle(
              fontSize: 7,
              color: change.startsWith('+') ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

// ====================== HOVER CARD ======================
class _HoverCard extends StatefulWidget {
  final Widget Function(bool isHover) builder;
  final VoidCallback onTap;

  const _HoverCard({
    required this.builder,
    required this.onTap,
  });

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




/*import 'package:battery_regeneration_system/screens/qnx_admin/user_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';
import 'dart:convert';
// Import your screens
import '../../api/api_response.dart';
import '../../api/api_service.dart';
import '../../models/company_model.dart';
import '../../models/enquiry_list_model.dart';
import '../../models/product_model.dart';
import '../../screens/qnx_admin/unit_create.dart';
import '../../screens/qnx_admin/role_create.dart';
import '../../screens/qnx_admin/category_create.dart';
import '../../screens/qnx_admin/subcategory_screen.dart';
import '../../screens/qnx_admin/pending_product_list_screen.dart';
import '../../screens/qnx_admin/approve_product_list.dart';
import '../../screens/qnx_admin/company_all_screen.dart';
import '../../screens/qnx_admin/offer_screen.dart';
import '../../screens/qnx_admin/enquiry_list_screen.dart';
import '../../screens/qnx_admin/user_enquiry_screen.dart';
import '../../screens/qnx_admin/login_screen.dart';
import '../../screens/qnx_admin/agreement_screen.dart';
import '../../screens/qnx_admin/admin_create.dart';
import '../../screens/qnx_admin/update_request_list_screen.dart';
import '../../screens/qnx_admin/marketing_heads_screen.dart';
import '../../screens/qnx_admin/franchise_screen.dart';
import '../../api/api_url.dart';
import '../../screens/qnx_admin/marketing_partners_screen.dart';
import '../support/support_dashboard.dart';
import '../../screens/qnx_admin/approved_marketing_partners_screen.dart';
import '../../screens/qnx_admin/bank_details_screen.dart';
import '../../screens/qnx_admin/company_product_enquiry_screen.dart';



class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}


class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  // Tab Management
  late List<Map<String, dynamic>> _openTabs;
  late Map<String, Widget> _tabScreens;
  late String _activeTab;

  // Animation Controllers
  late AnimationController _sidebarController;
  late AnimationController _notificationController;
  late AnimationController _statsController;
  late Animation<double> _sidebarAnimation;
  late AnimationController _borderAnimationController;
  late Animation<Color?> _borderColorAnimation;

  // State variables
  bool _isRestoring = false;
  bool _isSidebarExpanded = true;
  bool _isDarkMode = false;
  int _notificationCount = 8;
  String _selectedTimeRange = 'This Week';

  String _userRole = '';  // Add this
  int? _companyId;
  bool _isAuthorized = false;
  // Search controller
  final TextEditingController _searchController = TextEditingController();

  // Global key for Scaffold state to open drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const String _kSavedTabsKey = 'dashboard_open_tabs';
  static const String _kActiveTabKey = 'dashboard_active_tab';
  // Sample data for live feel
  final List<Map<String, dynamic>> _recentActivities = [
    {
      'user': 'Rahul Sharma',
      'action': 'added new product',
      'target': 'iPhone 15 Pro',
      'time': '2 minutes ago',
      'avatar': 'R',
      'color': Colors.blue,
    },
    {
      'user': 'Priya Patel',
      'action': 'processed order',
      'target': '#ORD-2026-089',
      'time': '5 minutes ago',
      'avatar': 'P',
      'color': Colors.purple,
    },
    {
      'user': 'Amit Kumar',
      'action': 'updated inventory',
      'target': '50 units',
      'time': '12 minutes ago',
      'avatar': 'A',
      'color': Colors.green,
    },
    {
      'user': 'Neha Singh',
      'action': 'created offer',
      'target': 'Summer Sale 40%',
      'time': '25 minutes ago',
      'avatar': 'N',
      'color': Colors.orange,
    },
  ];



  @override
  void initState() {
    super.initState();
    _loadUserRole();  // Add this line
    _checkUserRole();
    // Initialize tabs
    _openTabs = [
      {'title': 'Dashboard', 'icon': Icons.dashboard, 'closable': false}
    ];
    _tabScreens = {
      'Dashboard': const DashboardHomeContent(),
    };
    _activeTab = 'Dashboard';

    _borderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _borderColorAnimation = ColorTween(
      begin: const Color(0xFF4158D0),
      end: const Color(0xFFC850C0),
    ).animate(_borderAnimationController);

    // Initialize animations
    _sidebarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _sidebarAnimation = Tween<double>(begin: 280, end: 80).animate(
      CurvedAnimation(parent: _sidebarController, curve: Curves.easeInOut),
    );

    _notificationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    // Simulate real-time updates
    _simulateRealTimeUpdates();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTabsState();
    });
  }
  // Add this method
  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('role') ?? '';
      _companyId = prefs.getInt('companyId');
    });
    print("User Role: $_userRole, CompanyId: $_companyId");
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? '';

    setState(() {
      _userRole = role.toLowerCase();
      _isAuthorized = _userRole.contains('admin') || _userRole.contains('qnx admin');
    });

    // ✅ जर Admin नसेल तर Support Dashboard वर redirect करा
    if (!_isAuthorized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Access Denied! You are not authorized as Admin.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SupportDashboard()),
        );
      });
    }
  }

  Future<void> _saveTabsState() async {
    final prefs = await SharedPreferences.getInstance();
    // Save only titles of non‑Dashboard tabs
    final List<String> tabTitles = _openTabs
        .where((tab) => tab['title'] != 'Dashboard')
        .map((tab) => tab['title'] as String)
        .toList();
    await prefs.setString(_kSavedTabsKey, jsonEncode(tabTitles));
    await prefs.setString(_kActiveTabKey, _activeTab);
  }

  Future<void> _loadTabsState() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedTabsJson = prefs.getString(_kSavedTabsKey);
    final String? savedActiveTab = prefs.getString(_kActiveTabKey);
    if (savedTabsJson == null || savedActiveTab == null) return;

    final List<dynamic> decodedTabs = jsonDecode(savedTabsJson);
    final List<String> savedTitles = decodedTabs.map((e) => e.toString()).toList();

    // Reopen each saved tab
    for (final title in savedTitles) {
      final (screen, icon) = _getScreenInfoForTitle(title);
      // Use a flag to avoid saving again during restore (we'll set a flag)
      _isRestoring = true;
      _openScreen(title, screen, icon: icon);
      _isRestoring = false;
    }

    // Set active tab if it exists among opened tabs
    if (_openTabs.any((tab) => tab['title'] == savedActiveTab)) {
      setState(() {
        _activeTab = savedActiveTab;
      });
    }
  }
  void _simulateRealTimeUpdates() {
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _notificationCount += 3;
        });
        _simulateRealTimeUpdates();
      }
    });
  }

  void _closeAllTabs() {
    setState(() {
      // Keep only the Dashboard tab
      _openTabs = _openTabs.where((tab) => tab['title'] == 'Dashboard').toList();
      _tabScreens.removeWhere((key, value) => key != 'Dashboard');
      _activeTab = 'Dashboard';
    });
  }
  @override
  void dispose() {
    _sidebarController.dispose();
    _notificationController.dispose();
    _statsController.dispose();
    _searchController.dispose();
    _borderAnimationController.dispose();
    super.dispose();
  }

  void _openScreen(String title, Widget screen, {IconData icon = Icons.tab}) {
    if (!_openTabs.any((tab) => tab['title'] == title)) {
      setState(() {
        if (!_isRestoring) _saveTabsState();
        _openTabs.add({'title': title, 'icon': icon, 'closable': true});
        _tabScreens[title] = screen;
        _activeTab = title;
      });
    } else {
      setState(() {
        _activeTab = title;
      });
    }
  }

  (Widget, IconData) _getScreenInfoForTitle(String title) {
    switch (title) {
      case 'Role':
        return (const RoleCreateScreen(), Icons.people);
      case 'Unit':
        return (const UnitCreateScreen(), Icons.straighten);
      case 'All Users':
        return (const UserListScreen(), Icons.people);
      case 'Category':
        return (const CategoryScreen(), Icons.category);
      case 'SubCategory':
        return (const SubCategoryAllScreen(), Icons.subtitles);
      case 'Pending Product':
        return (const PendingProductListScreen(), Icons.pending_actions);
      case 'Approved Product':
        return (const ApprovedProductListScreen(), Icons.check_circle);
      case 'Update Requests':
        return (const UpdateRequestListScreen(), Icons.update);
      case 'All Company':
        return (const CompanyAllScreen(), Icons.business);
      case 'Agreement':
      case 'Franchise':
        return (FranchiseListScreen(), Icons.storefront);
        return (AgreementScreen(), Icons.description);
      case 'Offer List':
        return (const OfferListScreen(), Icons.local_offer);
      case 'Demo Enquiry':
        return (const EnquiryListScreen(), Icons.question_answer);
      case 'User Enquiry':
        return (const UserEnquiryScreen(), Icons.person);
      case 'Product Enquiry':
        return (EnquiryTabsScreen(), Icons.person);
      case 'Marketing Head':
        return (const MarketingHeadsScreen(), Icons.people_alt);
      case 'Marketing Partners':
        return (const MarketingPartnersScreen(), Icons.people_outline);
      case 'Admin Create':
        return (const AdminCreateScreen(), Icons.admin_panel_settings);
      case 'Bank Details':   // ✅ नवीन केस जोडा
        return (const BankDetailsScreen(), Icons.account_balance_wallet_rounded);
      default:
        return (const DashboardHomeContent(), Icons.dashboard);
    }
  }

  void _closeTab(String title) {
    if (title != 'Dashboard') {
      setState(() {
        _openTabs.removeWhere((tab) => tab['title'] == title);
        _tabScreens.remove(title);
        if (_activeTab == title) {
          _activeTab = _openTabs.isNotEmpty ? _openTabs.last['title'] : 'Dashboard';
        }
      });
    }
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
      if (_isSidebarExpanded) {
        _sidebarController.forward();
      } else {
        _sidebarController.reverse();
      }
    });
  }

  void _logout() async  {
    final prefs = await SharedPreferences.getInstance();
    // await prefs.remove(_kSavedTabsKey);
    // await prefs.remove(_kActiveTabKey);
    await prefs.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1200;

    return AnimatedTheme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      duration: const Duration(milliseconds: 300),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: _isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF0F5FA),
        drawer: isMobile ? _buildMobileDrawer() : null,
        body: Row(
          children: [
            // Sidebar
            if (!isMobile)
        SafeArea(                              // ← Add this
        child: AnimatedBuilder(
        animation: _sidebarAnimation,
        builder: (context, child) {
          return Container(
            width: _isSidebarExpanded ? 230 : 50,
            height: screenHeight,
            child: _buildSidebar(),
          );
        },
      ),
        ),

      // Main Content
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(isMobile, isTablet),
                  _buildTabsBar(),
                  Expanded(
                    child: _buildContentArea(),
                  ),
                ],
              ),
            ),
          ],
        ),
        /*floatingActionButton: isMobile ? null : _buildFloatingActionButton(),*/
      ),
    );
  }

  /*Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(16),
              width: 300,
              constraints: const BoxConstraints(maxHeight: 400),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildQuickActionItem(
                            icon: Icons.local_offer,
                            label: 'Create Offer',
                            color: Colors.green,
                            onTap: () {
                              Navigator.pop(context);
                              _openScreen('Create Offer', const OfferListScreen(), icon: Icons.local_offer);
                            },
                          ),
                          _buildQuickActionItem(
                            icon: Icons.people,
                            label: 'Add User',
                            color: Colors.purple,
                            onTap: () {
                              Navigator.pop(context);
                              _openScreen('Add User', const AdminCreateScreen(), icon: Icons.people);
                            },
                          ),
                          _buildQuickActionItem(
                            icon: Icons.category,
                            label: 'Add Category',
                            color: Colors.orange,
                            onTap: () {
                              Navigator.pop(context);
                              _openScreen('Add Category', const CategoryScreen(), icon: Icons.category);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      label: const Text('Quick Actions'),
      icon: const Icon(Icons.add),
      backgroundColor: const Color(0xFF4158D0),
    );
  }


  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, overflow: TextOverflow.ellipsis),
      onTap: onTap,
      dense: true,
    );
  }*/

  Widget _buildMobileDrawer() {
    return Drawer(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        decoration: BoxDecoration(
          color: Colors.white, // solid white background
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildDrawerHeader(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    _buildDrawerSection('MAIN'),
                    _buildDrawerItem(
                      icon: Icons.dashboard,
                      title: 'Dashboard',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Dashboard', const DashboardHomeContent(), icon: Icons.dashboard);
                      },
                      isSelected: _activeTab == 'Dashboard',
                    ),
                    ExpansionTile(
                      title: const Text(
                        'MASTER',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black),
                      ),
                      leading: const Icon(Icons.folder_outlined, size: 20, color: Color(0xFF9B59B6)),
                      iconColor: const Color(0xFF9B59B6),
                      collapsedIconColor: const Color(0xFF9B59B6),
                      childrenPadding: EdgeInsets.zero,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 8),
                      initiallyExpanded: false,
                      children: [
                        _buildDrawerItem(
                          icon: Icons.people,
                          title: 'Role',
                          onTap: () {
                            Navigator.pop(context);
                            _openScreen('Role', const RoleCreateScreen(), icon: Icons.people);
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.straighten,
                          title: 'Unit',
                          onTap: () {
                            Navigator.pop(context);
                            _openScreen('Unit', const UnitCreateScreen(), icon: Icons.straighten);
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.straighten,
                          title: 'All users',
                          onTap: () {
                            Navigator.pop(context);
                            _openScreen('All users', const UserListScreen(), icon: Icons.straighten);
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.category,
                          title: 'Category',
                          onTap: () {
                            Navigator.pop(context);
                            _openScreen('Category', const CategoryScreen(), icon: Icons.category);
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.subtitles,
                          title: 'SubCategory',
                          onTap: () {
                            Navigator.pop(context);
                            _openScreen('SubCategory', const SubCategoryAllScreen(), icon: Icons.subtitles);
                          },
                        ),
                      ],
                    ),
                    _buildDrawerSection('PRODUCT'),
                    _buildDrawerItem(
                      icon: Icons.pending_actions,
                      title: 'Pending Product',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Pending Product', const PendingProductListScreen(), icon: Icons.pending_actions);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.check_circle,
                      title: 'Approved Product',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Approved Product', const ApprovedProductListScreen(), icon: Icons.check_circle);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.update,
                      title: 'Update Requests',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Update Requests', const UpdateRequestListScreen(), icon: Icons.update);
                      },
                    ),
                    _buildDrawerSection('COMPANY'),
                    _buildDrawerItem(
                      icon: Icons.business,
                      title: 'All Company',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('All Company', const CompanyAllScreen(), icon: Icons.business);
                      },
                    ),
                    _buildDrawerSection('AGREEMENT'),
                    _buildDrawerItem(
                      icon: Icons.description,
                      title: 'Agreement',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Agreement', AgreementScreen(), icon: Icons.description);
                      },
                    ),
                    _buildDrawerSection('FRANCHISE'),
                    _buildDrawerItem(
                      icon: Icons.storefront,  // ✅ बदलले
                      title: 'Franchise',      // ✅ "Available" काढले
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Franchise', FranchiseListScreen(), icon: Icons.storefront);
                      },
                    ),
                    _buildDrawerSection('OFFER'),
                    _buildDrawerItem(
                      icon: Icons.local_offer,
                      title: 'Offer List',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Offer List', const OfferListScreen(), icon: Icons.local_offer);
                      },
                    ),
                    _buildDrawerSection('ENQUIRY'),
                    _buildDrawerItem(
                      icon: Icons.question_answer,
                      title: 'Demo Enquiry',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Demo Enquiry', const EnquiryListScreen(), icon: Icons.question_answer);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.person,
                      title: 'User Enquiry',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('User Enquiry', const UserEnquiryScreen(), icon: Icons.person);
                      },
                    ),

                    _buildDrawerItem(
                      icon: Icons.person,
                      title: 'Product Enquiry',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Product Enquiry', const EnquiryTabsScreen(), icon: Icons.person);
                      },
                    ),
                    _buildDrawerSection('MARKETING MASTER'),
                    _buildDrawerItem(
                      icon: Icons.people_outline,
                      title: 'Marketing Head',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Marketing Head', const MarketingHeadsScreen(), icon: Icons.people_alt);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.people_outline,
                      title: 'Marketing Partners',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Marketing Partners', const MarketingPartnersScreen(), icon: Icons.people_outline);
                      },
                    ),
                    _buildDrawerItem(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'Bank Details',
                      onTap: () {
                        Navigator.pop(context);
                        _openScreen('Bank Details', const BankDetailsScreen(), icon: Icons.account_balance_wallet_rounded);
                      },
                    ),
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

  Widget _buildDrawerFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
        ),
      ),
      child: InkWell(
        onTap: _logout,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.red[50],
          ),
          child: Row(
            children: [
              Icon(Icons.logout, color: Colors.red[700], size: 20),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white, // solid background instead of gradient
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepPurple.withOpacity(0.05),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // QNX Logo Image
                Image.asset(
                  "assets/images/img_2.png",
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: _isDarkMode ? Colors.grey[400] : Colors.grey[600],
          letterSpacing: 1.2,
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
    // हा नवीन color मिळवा
    final Color iconColor = _getIconColorForItem(icon, title, isSelected);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: isSelected ? const Color(0xFF4158D0).withOpacity(0.1) : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: iconColor, size: 20),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? const Color(0xFF4158D0)
                : (_isDarkMode ? Colors.grey[300] : Colors.grey[800]),
          ),
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      ),
    );
  }

  Color _getIconColor(IconData icon, bool isSelected) {
    if (isSelected) return Colors.white;
    if (icon == Icons.dashboard) return const Color(0xFF4158D0);
    if (icon == Icons.people) return const Color(0xFF9B59B6);
    if (icon == Icons.straighten) return const Color(0xFF1ABC9C);
    if (icon == Icons.category) return const Color(0xFFF39C12);
    if (icon == Icons.subtitles) return const Color(0xFFE67E22);
    if (icon == Icons.pending_actions) return const Color(0xFFE74C3C);
    if (icon == Icons.check_circle) return const Color(0xFF2ECC71);
    if (icon == Icons.business) return const Color(0xFF3498DB);
    if (icon == Icons.description) return const Color(0xFF9B59B6);
    if (icon == Icons.local_offer) return const Color(0xFFF1C40F);
    if (icon == Icons.question_answer) return const Color(0xFFE67E22);
    if (icon == Icons.person) return const Color(0xFF1ABC9C);
    if (icon == Icons.account_balance_wallet_rounded) return const Color(0xFFFF6584); // pink/red
    if (icon == Icons.account_balance_wallet_rounded) return const Color(0xFFFF6584);
    if (icon == Icons.storefront) return const Color(0xFF2ECC71);

    return _isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
  }

  Color _getIconColorForItem(IconData icon, String title, bool isSelected) {
    if (isSelected) return const Color(0xFF4158D0);

    // Title-specific overrides (Marketing, Update Requests, Bank Details)
    switch (title) {
      case 'Marketing Head':
        return const Color(0xFF9B59B6);
      case 'Marketing Partners':
        return const Color(0xFFE67E22);
      case 'Update Requests':
        return const Color(0xFFF39C12);
      case 'Bank Details':
        return const Color(0xFFFF6584);
      case 'Franchise':
        return const Color(0xFFFF6584);
    }

    // Icon-based colors (same as sidebar's _getIconColor)
    if (icon == Icons.dashboard) return const Color(0xFF4158D0);
    if (icon == Icons.people) return const Color(0xFF9B59B6);
    if (icon == Icons.straighten) return const Color(0xFF1ABC9C);
    if (icon == Icons.category) return const Color(0xFFF39C12);
    if (icon == Icons.subtitles) return const Color(0xFFE67E22);
    if (icon == Icons.pending_actions) return const Color(0xFFE74C3C);
    if (icon == Icons.check_circle) return const Color(0xFF2ECC71);
    if (icon == Icons.update) return const Color(0xFFF39C12);
    if (icon == Icons.business) return const Color(0xFF3498DB);
    if (icon == Icons.description) return const Color(0xFF9B59B6);
    if (icon == Icons.local_offer) return const Color(0xFFF1C40F);
    if (icon == Icons.question_answer) return const Color(0xFFE67E22);
    if (icon == Icons.person) return const Color(0xFF1ABC9C);
    if (icon == Icons.account_balance_wallet_rounded) return const Color(0xFFFF6584);
    if (icon == Icons.people_outline) return const Color(0xFFE67E22);
    if (icon == Icons.storefront) return const Color(0xFF2ECC71);

    // Default
    return _isDarkMode ? Colors.grey[400]! : Colors.grey[700]!;
  }

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
              shrinkWrap: true,
              children: [
                _buildSidebarMenuItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  isSelected: _activeTab == 'Dashboard',
                  onTap: () => _openScreen('Dashboard', const DashboardHomeContent(), icon: Icons.dashboard),
                ),

                if (_isSidebarExpanded)
                  ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    childrenPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.folder_outlined, size: 18, color: Color(0xFF9B59B6)),
                    title: const Text(
                      'MASTER',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    iconColor: const Color(0xFF9B59B6),
                    collapsedIconColor: const Color(0xFF9B59B6),
                    initiallyExpanded: false,
                    children: [
                      _buildSidebarMenuItem(
                        icon: Icons.people,
                        title: 'Role',
                        isSelected: _activeTab == 'Role',
                        onTap: () => _openScreen('Role', const RoleCreateScreen(), icon: Icons.people),
                      ),
                      _buildSidebarMenuItem(
                        icon: Icons.straighten,
                        title: 'Unit',
                        isSelected: _activeTab == 'Unit',
                        onTap: () => _openScreen('Unit', const UnitCreateScreen(), icon: Icons.straighten),
                      ),
                      _buildSidebarMenuItem(
                        icon: Icons.people,
                        title: 'All Users',
                        isSelected: _activeTab == 'users',
                        onTap: () => _openScreen('Users', const UserListScreen(), icon: Icons.people),
                      ),
                      _buildSidebarMenuItem(
                        icon: Icons.category,
                        title: 'Category',
                        isSelected: _activeTab == 'Category',
                        onTap: () => _openScreen('Category', const CategoryScreen(), icon: Icons.category),
                      ),
                      _buildSidebarMenuItem(
                        icon: Icons.subtitles,
                        title: 'SubCategory',
                        isSelected: _activeTab == 'SubCategory',
                        onTap: () => _openScreen('SubCategory', const SubCategoryAllScreen(), icon: Icons.subtitles),
                      ),
                    ],
                  ),

                if (_isSidebarExpanded) _buildSidebarSection('PRODUCT'),
                _buildSidebarMenuItem(
                  icon: Icons.pending_actions,
                  title: 'Pending Product',
                  isSelected: _activeTab == 'Pending Product',
                  onTap: () => _openScreen('Pending Product', const PendingProductListScreen(), icon: Icons.pending_actions),
                ),
                _buildSidebarMenuItem(
                  icon: Icons.check_circle,
                  title: 'Approved Product',
                  isSelected: _activeTab == 'Approved Product',
                  onTap: () => _openScreen('Approved Product', const ApprovedProductListScreen(), icon: Icons.check_circle),
                ),
                  _buildSidebarMenuItem(
                    icon: Icons.update,
                    title: 'Update Requests',
                    isSelected: _activeTab == 'Update Requests',
                    onTap: () => _openScreen('Update Requests', const UpdateRequestListScreen(), icon: Icons.update),
                  ),
                if (_isSidebarExpanded) _buildSidebarSection('COMPANY'),
                _buildSidebarMenuItem(
                  icon: Icons.business,
                  title: 'All Company',
                  isSelected: _activeTab == 'All Company',
                  onTap: () => _openScreen('All Company', const CompanyAllScreen(), icon: Icons.business),
                ),

                if (_isSidebarExpanded) _buildSidebarSection('AGREEMENT'),

                _buildSidebarMenuItem(
                  icon: Icons.description,
                  title: 'Agreement',
                  isSelected: _activeTab == 'Agreement',
                  onTap: () => _openScreen(
                    'Agreement',
                    AgreementScreen(),
                    icon: Icons.description,
                  ),
                ),
                if (_isSidebarExpanded) _buildSidebarSection('FRANCHISE'),
                _buildSidebarMenuItem(
                  icon: Icons.storefront,
                  title: 'Franchise',
                  isSelected: _activeTab == 'Franchise',
                  onTap: () => _openScreen(
                    'Franchise',
                    FranchiseListScreen(),
                    icon: Icons.storefront,
                  ),
                ),
                if (_isSidebarExpanded) _buildSidebarSection('OFFER'),
                _buildSidebarMenuItem(
                  icon: Icons.local_offer,
                  title: 'Offer List',
                  isSelected: _activeTab == 'Offer List',
                  onTap: () => _openScreen('Offer List', const OfferListScreen(), icon: Icons.local_offer),
                ),

                if (_isSidebarExpanded) _buildSidebarSection('ENQUIRY'),
                _buildSidebarMenuItem(
                  icon: Icons.question_answer,
                  title: ' Demo Enquiry',
                  isSelected: _activeTab == 'Demo Enquiry',
                  onTap: () => _openScreen('Demo Enquiry', const EnquiryListScreen(), icon: Icons.question_answer),
                ),
                _buildSidebarMenuItem(
                  icon: Icons.person,
                  title: 'User Enquiry',
                  isSelected: _activeTab == 'User Enquiry',
                  onTap: () => _openScreen('User Enquiry', const UserEnquiryScreen(), icon: Icons.person),
                ),

                _buildSidebarMenuItem(
                  icon: Icons.person,
                  title: 'Product Enquiry',
                  isSelected: _activeTab == 'Product Enquiry',
                  onTap: () => _openScreen('Product Enquiry', EnquiryTabsScreen(), icon: Icons.person),
                ),
                if (_isSidebarExpanded) _buildSidebarSection('MARKETING'),
                _buildSidebarMenuItem(
                  icon: Icons.people_outline,
                  title: 'Marketing Head',
                  isSelected: _activeTab == 'Marketing Head',
                  onTap: () => _openScreen('Marketing Head', const MarketingHeadsScreen(), icon: Icons.people_alt),
                ),
                _buildSidebarMenuItem(
                  icon: Icons.people_outline,
                  title: 'Marketing Partners',
                  isSelected: _activeTab == 'Marketing Partners',
                  onTap: () => _openScreen('Marketing Partners', const MarketingPartnersScreen(), icon: Icons.people_outline),
                ),
                _buildSidebarMenuItem(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'Bank Details',
                  isSelected: _activeTab == 'Bank Details',
                  onTap: () => _openScreen('Bank Details', const BankDetailsScreen(), icon: Icons.account_balance_wallet_rounded),
                ),

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
      // Collapsed mode: only the toggle button, centered
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
            child: Icon(
              Icons.chevron_right,
              size: 18,
              color: _isDarkMode ? Colors.white70 : Colors.grey[700],
            ),
          ),
        ),
      );
    }

    // Expanded mode: logo + toggle button
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: Image.asset(
                "assets/images/img_2.png",
                height: 70,          // reduced from 120 to fit within 90
                fit: BoxFit.contain,
              ),
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
              child: Icon(
                Icons.chevron_left,
                size: 18,
                color: _isDarkMode ? Colors.white70 : Colors.grey[700],
              ),
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

  Widget _buildSidebarMenuItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // Compute custom icon color for specific items
    Color iconColor;
    if (isSelected) {
      iconColor = Colors.white; // selected items always white
    } else {
      // Assign custom colors based on title
      switch (title) {
        case 'Marketing Head':
          iconColor = const Color(0xFF9B59B6); // purple
          break;
        case 'Marketing Partners':
          iconColor = const Color(0xFFE67E22); // orange
          break;
        case 'Update Requests':
          iconColor = const Color(0xFFF39C12); // golden yellow
          break;
        default:
          iconColor = _getIconColor(icon, isSelected);
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
                Icon(
                  icon,
                  size: 18,
                  color: iconColor,
                ),
                if (_isSidebarExpanded) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? Colors.white
                            : (_isDarkMode ? Colors.grey[300] : Colors.grey[800]),
                      ),
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

  Widget _buildSidebarFooter() {
    // When sidebar is collapsed, show only a centered logout icon
    if (!_isSidebarExpanded) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        child: InkWell(
          onTap: _logout,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.logout,
              size: 20,
              color: Colors.red[700],
            ),
          ),
        ),
      );
    }

    // Original expanded footer (unchanged)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: _isDarkMode ? Colors.grey[800]! : Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const CircleAvatar(
                  radius: 14,
                  backgroundColor: Colors.white,
                  child: Text(
                    "A",
                    style: TextStyle(
                      color: Color(0xFF4158D0),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
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
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Admin User",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "admin@qnxmart.com",
                  style: TextStyle(
                    fontSize: 9,
                    color: _isDarkMode ? Colors.grey[500] : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.light_mode : Icons.dark_mode,
              size: 16,
              color: _isDarkMode ? Colors.yellow : Colors.grey[600],
            ),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: _logout,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.logout,
                size: 16,
                color: Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }


// ====================== Update _buildTopBar method for centered search ======================
  Widget _buildTopBar(bool isMobile, bool isTablet) {
    return Container(
      height: isMobile ? 60 : 70,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 16,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: (_isDarkMode ? Colors.black : Colors.grey).withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Mobile Menu Button
          if (isMobile)
            IconButton(
              icon: Icon(Icons.menu,
                  color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
                  size: 24
              ),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),

          // Search Bar - Premium Design
          Expanded(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                height: isMobile ? 38 : 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _isDarkMode
                        ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                        : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: _isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : const Color(0xFF4158D0).withOpacity(0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4158D0).withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Search Icon with Gradient
                    Container(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                        ).createShader(bounds),
                        child: Icon(
                          Icons.search_rounded,
                          size: isMobile ? 18 : 20,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Search Input
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
                          fontSize: isMobile ? 13 : 14,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: isMobile ? 'Search...' : 'Search products, orders...',
                          hintStyle: TextStyle(
                            color: _isDarkMode
                                ? Colors.grey[500]
                                : const Color(0xFF94A3B8),
                            fontSize: isMobile ? 12 : 13,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 0,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                    ),

                    // Clear Button (animated)
                    if (_searchController.text.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _searchController.clear();
                              });
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                size: isMobile ? 12 : 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.shortcut_rounded,
                          size: isMobile ? 12 : 14,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Premium Notification Button
          _buildPremiumIconButton(
            icon: Icons.notifications_outlined,
            count: _notificationCount,
            onTap: () {},
            isMobile: isMobile,
          ),

          const SizedBox(width: 4),

          // Premium Registration Button
          _buildPremiumRegistrationButton(isMobile),

          const SizedBox(width: 4),
        ],
      ),
    );
  }
  Widget _buildPremiumIconButton({
    required IconData icon,
    int? count,
    required VoidCallback onTap,
    required bool isMobile,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: isMobile ? 38 : 42,
          height: isMobile ? 38 : 42,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isDarkMode
                  ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                  : [const Color(0xFFF8FAFC), const Color(0xFFF1F5F9)],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF4158D0).withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF4158D0).withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: _isDarkMode ? Colors.white : const Color(0xFF1E293B),
              size: isMobile ? 18 : 20,
            ),
            onPressed: onTap,
            padding: EdgeInsets.zero,
            iconSize: isMobile ? 18 : 20,
          ),
        ),
        if (count != null && count > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                ),
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                count > 9 ? '9+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPremiumRegistrationButton(bool isMobile) {
    return AnimatedBuilder(
      animation: _borderAnimationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(left: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: _borderColorAnimation.value ?? const Color(0xFF4158D0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (_borderColorAnimation.value ?? const Color(0xFF4158D0))
                    .withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _openScreen(
                  'Admin Create',
                  const AdminCreateScreen(),
                  icon: Icons.admin_panel_settings,
                );
              },
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: isMobile ? 8 : 10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_add_alt_1,
                      size: isMobile ? 16 : 18,
                      color: Colors.white,
                    ),
                    if (!isMobile) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Registration',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
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
  Widget _buildRegistrationButton(bool isMobile) {
    return AnimatedBuilder(
      animation: _borderAnimationController,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _borderColorAnimation.value ?? const Color(0xFF4158D0),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _borderColorAnimation.value?.withOpacity(0.5) ?? Colors.transparent,
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _openScreen(
                  'Admin Create',
                  const AdminCreateScreen(),
                  icon: Icons.admin_panel_settings,
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 12, vertical: isMobile ? 6 : 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add_alt_1, size: isMobile ? 14 : 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Registration',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


// ====================== Update _buildTabsBar method ======================
  Widget _buildTabsBar() {
    if (_openTabs.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      color: _isDarkMode ? const Color(0xFF16213E) : Colors.white,
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: _openTabs.length,
              itemBuilder: (context, index) {
                final tab = _openTabs[index];
                final isSelected = _activeTab == tab['title'];

                return Container(
                  margin: const EdgeInsets.only(right: 4),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _activeTab = tab['title'];
                        });
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                            colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                              : null,
                          color: isSelected ? null : (_isDarkMode ? Colors.grey[800] : Colors.grey[100]),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              tab['icon'],
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : (_isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tab['title'],
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (_isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (tab['closable'] == true) ...[
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () => _closeTab(tab['title']),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white.withOpacity(0.2)
                                        : (_isDarkMode ? Colors.grey[600] : Colors.grey)?.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    size: 10,
                                    color: isSelected
                                        ? Colors.white
                                        : (_isDarkMode ? Colors.grey[400] : Colors.grey[600]),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Close All Tabs Button
          if (_openTabs.length > 1)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _closeAllTabs,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.close, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Close All',
                          style: TextStyle(fontSize: 11, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }


  Widget _buildContentArea() {
    return Container(
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
        child: _tabScreens[_activeTab] ?? const DashboardHomeContent(), // हेच आहे तुझ्याकडे
      ),
    );
  }
}

// Enhanced Dashboard Home Content
// Dashboard Home Content
class DashboardHomeContent extends StatefulWidget {
  const DashboardHomeContent({super.key});

  @override
  State<DashboardHomeContent> createState() => _DashboardHomeContentState();
}

class _DashboardHomeContentState extends State<DashboardHomeContent> with TickerProviderStateMixin {
  late AnimationController _revenueController;
  late AnimationController _ordersController;
  late Animation<double> _revenueAnimation;
  late Animation<double> _ordersAnimation;
  final DashboardService dashboardService = DashboardService(); //
  int totalCompanies = 0;
  int totalProducts = 0;
  int totalEnquiry = 0;
  bool _isLoadingCounts = true;

  Future<void> _fetchDashboardCounts() async {
    try {
      final companyRes = await DashboardService().getCompanyCount();
      final productRes = await DashboardService().getProductCount();
      final enquiryRes = await dashboardService.getEnquiryCount();
      setState(() {
        totalCompanies = companyRes.total;
        totalProducts = productRes.approvedProductCount;
        totalEnquiry = enquiryRes.count;  // set from your API when available
        _isLoadingCounts = false;
      });
    } catch (e) {
      print("Dashboard counts error: $e");
      setState(() => _isLoadingCounts = false);
    }
  }

  // Latest Companies
  final LatestCompanyService _latestCompanyService = LatestCompanyService();
  List<LatestCompany> _latestCompanies = [];
  bool _isLoadingCompanies = true;

  // Add after Latest Companies variables
  final LatestEnquiryService _latestEnquiryService = LatestEnquiryService();
  List<LatestEnquiry> _latestEnquiries = [];
  bool _isLoadingEnquiries = true;

  // Latest Products  <-- NEW
  final LatestProductService _latestProductService = LatestProductService();
  List<LatestProduct> _latestProducts = [];
  bool _isLoadingProducts = true;

  String _selectedPeriod = 'This Week';

  // Real-time data
  final List<Map<String, dynamic>> _recentOrders = [
    {
      'id': '#ORD-2026-089',
      'customer': 'Rajesh Kumar',
      'amount': '₹2,549',
      'status': 'Delivered',
      'time': '2 mins ago',
      'items': 3,
      'avatar': 'RK',
    },
    {
      'id': '#ORD-2026-088',
      'customer': 'Priya Sharma',
      'amount': '₹4,299',
      'status': 'Processing',
      'time': '15 mins ago',
      'items': 5,
      'avatar': 'PS',
    },
    {
      'id': '#ORD-2026-087',
      'customer': 'Amit Patel',
      'amount': '₹1,899',
      'status': 'Shipped',
      'time': '25 mins ago',
      'items': 2,
      'avatar': 'AP',
    },
    {
      'id': '#ORD-2026-086',
      'customer': 'Neha Gupta',
      'amount': '₹6,999',
      'status': 'Pending',
      'time': '1 hour ago',
      'items': 7,
      'avatar': 'NG',
    },
  ];

  final List<Map<String, dynamic>> _topProducts = [
    {
      'name': 'iPhone 15 Pro Max',
      'category': 'Electronics',
      'sales': 1234,
      'revenue': '₹1,59,99,966',
      'growth': '+23%',
      'image': '📱',
    },
    {
      'name': 'Samsung Galaxy S24 Ultra',
      'category': 'Electronics',
      'sales': 987,
      'revenue': '₹88,99,713',
      'growth': '+18%',
      'image': '📱',
    },
    {
      'name': 'Premium Cotton Shirt',
      'category': 'Fashion',
      'sales': 2456,
      'revenue': '₹31,99,944',
      'growth': '+45%',
      'image': '👕',
    },
    {
      'name': 'Wireless Earbuds Pro',
      'category': 'Electronics',
      'sales': 3789,
      'revenue': '₹1,13,66,211',
      'growth': '+67%',
      'image': '🎧',
    },
  ];


  @override
  void initState() {
    super.initState();
    _fetchLatestCompanies();
    _fetchLatestEnquiries();
    _fetchLatestProducts();
    _fetchDashboardCounts();



    _revenueController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _ordersController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _revenueAnimation = Tween<double>(begin: 0, end: 4567890).animate(
      CurvedAnimation(parent: _revenueController, curve: Curves.easeOutCubic),
    );

    _ordersAnimation = Tween<double>(begin: 0, end: 1847).animate(
      CurvedAnimation(parent: _ordersController, curve: Curves.easeOutCubic),
    );
  }

  Future<void> _fetchLatestCompanies() async {
    try {
      final response = await _latestCompanyService.fetchLatestCompanies();
      if (mounted) {
        setState(() {
          _latestCompanies = response.data;
          _isLoadingCompanies = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingCompanies = false;
        });
        print('Error fetching companies: $e');
      }
    }
  }

  Future<void> _fetchLatestEnquiries() async {
    try {
      final response = await _latestEnquiryService.fetchLatestEnquiries();
      if (mounted) {
        setState(() {
          _latestEnquiries = response.data;
          _isLoadingEnquiries = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingEnquiries = false;
        });
        print('Error fetching enquiries: $e');
      }
    }
  }

  // NEW: fetch latest products
  Future<void> _fetchLatestProducts() async {
    try {
      final response = await _latestProductService.fetchLatestProducts();
      if (mounted) {
        setState(() {
          _latestProducts = response.data;
          _isLoadingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProducts = false);
        print('Error fetching products: $e');
      }
    }
  }

  @override
  void dispose() {
    _revenueController.dispose();
    _ordersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isDesktop = screenWidth >= 1024;

    return Container(
      color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F5FA),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark, isMobile, isTablet),
            const SizedBox(height: 20),
            _buildStatsGrid(isDark, isMobile, isTablet),
            const SizedBox(height: 20),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildRevenueChart(isDark)),
                  const SizedBox(width: 16),
                  Expanded(flex: 1, child: _buildRecentActivities(isDark)),
                ],
              )
            else
              Column(
                children: [
                  _buildRevenueChart(isDark),
                  const SizedBox(height: 16),
                  _buildRecentActivities(isDark),
                ],
              ),
            const SizedBox(height: 20),
            if (isDesktop)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: _buildRecentOrders(isDark)),
                  const SizedBox(width: 16),
                  Expanded(flex: 2, child: _buildLatestProducts(isDark)),
                ],
              )
            else
              Column(
                children: [
                  _buildRecentOrders(isDark),
                  const SizedBox(height: 16),
                  _buildLatestProducts(isDark),
                ],
              ),
            const SizedBox(height: 20),
            _buildQuickStatsFooter(isDark, isMobile, isTablet),
          ],
        ),
      ),
    );
  }

  // Update _buildHeader: remove green dot and reduce spacing
  Widget _buildHeader(bool isDark, bool isMobile, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              children: [
                Text(
                  "Good " + (DateTime.now().hour < 12 ? "Morning" : "Afternoon"),
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 20,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  "Admin!",
                  style: TextStyle(
                    fontSize: isMobile ? 18 : 24,
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                      ).createShader(const Rect.fromLTWH(0, 0, 150, 50)),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4), // reduced from original 8
      ],
    );
  }


  Widget _buildStatsGrid(bool isDark, bool isMobile, bool isTablet) {
    int crossAxisCount = 4;
    if (isMobile) crossAxisCount = 2;
    else if (isTablet) crossAxisCount = 3;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5, // slightly taller than before
      children: [
        if (_isLoadingCounts)
          for (int i = 0; i < 4; i++)
            _buildNewStatCard(
              title: '',
              value: '',
              icon: Icons.timer,
              color: Colors.grey,
              isDark: isDark,
              onTap: () {},
            )
        else ...[
          _buildNewStatCard(
            title: 'Total Companies',
            value: totalCompanies.toString(),
            icon: Icons.business,
            color: const Color(0xFF9B59B6), // purple
            isDark: isDark,
            onTap: () {
              // optional: navigate to company list
              // _openScreen('All Company', const CompanyAllScreen());
            },
          ),
          _buildNewStatCard(
            title: 'Total Products',
            value: totalProducts.toString(),
            icon: Icons.inventory,
            color: const Color(0xFFF39C12), // orange
            isDark: isDark,
            onTap: () {},
          ),
          _buildNewStatCard(
            title: 'Total Enquiries',
            value: totalEnquiry.toString(),
            icon: Icons.question_answer,
            color: const Color(0xFF2ECC71), // green
            isDark: isDark,
            onTap: () {},
          ),
          _buildMarketingPartnersCard(isDark),
        ],
      ],
    );
  }
  Widget _buildMarketingPartnersCard(bool isDark) {
    final ApprovedMarketingPartnerService _partnerService = ApprovedMarketingPartnerService();

    return FutureBuilder<ApprovedMarketingPartnerCountResponse>(
      future: _partnerService.getCount(),
      builder: (context, snapshot) {
        int count = 0;
        if (snapshot.hasData && snapshot.data != null) {
          count = snapshot.data!.count;
        }

        return _buildNewStatCard(
          title: 'Marketing Partners',
          value: snapshot.hasData ? count.toString() : '...',
          icon: Icons.people_outline,
          color: const Color(0xFF4158D0), // Same blue as before
          isDark: isDark,
          onTap: () {
            // Navigate to approved marketing partners list
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ApprovedMarketingPartnersScreen(),
              ),
            );
          },
        );
      },
    );
  }
  /*Widget _buildStatsGrid(bool isDark, bool isMobile, bool isTablet) {
    int crossAxisCount = 4;
    if (isMobile) crossAxisCount = 2;
    else if (isTablet) crossAxisCount = 3;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.7,
      children: [
        if (_isLoadingCounts)
          for (int i = 0; i < 4; i++)
            _buildNewStatCard(
              title: '',
              value: '',
              icon: Icons.timer,
              color: Colors.grey,
              isDark: isDark,
              onTap: () {},
            )
        else ...[
          _buildNewStatCard(
            title: 'Total Companies',
            value: totalCompanies.toString(),
            icon: Icons.business,
            color: Colors.purple,
            isDark: isDark,
            onTap: () {},
          ),
          _buildNewStatCard(
            title: 'Total Products',
            value: totalProducts.toString(),
            icon: Icons.inventory,
            color: Colors.orange,
            isDark: isDark,
            onTap: () {},
          ),
          _buildNewStatCard(
            title: 'Total Enquiry',
            value: totalEnquiry.toString(),
            icon: Icons.question_answer,
            color: Colors.green,
            isDark: isDark,
            onTap: () {},
          ),

          _buildNewStatCard(
            title: 'Total Revenue',
            value: '4567890', // or fetch from API if available
            prefix: '₹',
            icon: Icons.currency_rupee,
            color: const Color(0xFF4158D0),
            isDark: isDark,
            onTap: () {},
          ),
        ],
      ],
    );
  }

  Widget _buildNewStatCard({
    required String title,
    required String value,
    String prefix = '',
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return _HoverCard(
      onTap: onTap,
      builder: (isHover) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isHover
                ? color.withOpacity(0.6) // 👈 hover ला color
                : (isDark ? const Color(0xFF16213E) : Colors.white),

            borderRadius: BorderRadius.circular(12),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isHover ? 0.08 : 0.05),
                blurRadius: isHover ? 10 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [

              /// TOP ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [

                  /// ICON WITH BG
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 26,
                      color: color,
                    ),
                  ),

                  Icon(
                    Icons.arrow_forward_ios,
                    size: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey,
                  ),
                ],
              ),

              /// VALUE
              Text(
                '$prefix$value',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),

              /// TITLE
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }*/

  Widget _buildNewStatCard({
    required String title,
    required String value,
    String prefix = '',
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;

        final bool isVerySmall = cardWidth < 150;
        final bool isSmall = cardWidth < 180;

        final double iconSize = isVerySmall ? 12 : (isSmall ? 16 : 28);
        final double valueFontSize = isVerySmall ? 10 : (isSmall ? 14 : 28);
        final double titleFontSize = isVerySmall ? 6 : (isSmall ? 7 : 12);
        final double iconPadding = isVerySmall ? 1 : (isSmall ? 2 : 8);
        final double horizontalPadding = isVerySmall ? 1 : (isSmall ? 2 : 8);
        final double verticalPadding = (isVerySmall || isSmall) ? 4 : 8;
        final bool showArrow = !isVerySmall;

        return _HoverCard(
          onTap: onTap,
          builder: (isHover) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: verticalPadding,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [color.withOpacity(0.15), color.withOpacity(0.05)]
                      : [color.withOpacity(0.1), Colors.white],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : color).withOpacity(isHover ? 0.2 : 0.05),
                    blurRadius: isHover ? 8 : 4,
                    offset: const Offset(0, 2),
                  ),
                ],
                border: Border.all(
                  color: isDark ? color.withOpacity(0.3) : color.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // वरची ओळ – आयकॉन आणि अॅरो
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: EdgeInsets.all(iconPadding),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: iconSize, color: color),
                      ),
                      if (showArrow)
                        Icon(
                          Icons.arrow_forward_ios,
                          size: iconSize * 0.45,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                    ],
                  ),
                  // काउंट (सेंटर)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: TextStyle(
                        fontSize: valueFontSize,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        height: 1.0,
                        color: isHover ? color : (isDark ? Colors.white : Colors.black),
                      ),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            if (prefix.isNotEmpty)
                              TextSpan(
                                text: prefix,
                                style: TextStyle(
                                  fontSize: valueFontSize * 0.8,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            TextSpan(text: value),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  // टायटल (तळाशी सेंटर)
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                      letterSpacing: 0.2,
                      height: 1.0,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }



  Widget _buildRevenueChart(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  "Revenue Overview",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  _buildLegendItem('This Year', const Color(0xFF4158D0), isDark),
                  _buildLegendItem('Last Year', Colors.grey, isDark),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 300,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const months = [
                          "Jan","Feb","Mar","Apr","May","Jun",
                          "Jul","Aug","Sep","Oct","Nov","Dec"
                        ];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            months[value.toInt()],
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.grey[400] : Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 28),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),

                borderData: FlBorderData(show: false),

                lineBarsData: [

                  /// THIS YEAR (BLUE FLOW LINE)
                  LineChartBarData(
                    isCurved: true, // 👈 dongar effect
                    color: const Color(0xFF4158D0),
                    barWidth: 3,
                    dotData: FlDotData(show: true),

                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 4),
                      FlSpot(2, 3.5),
                      FlSpot(3, 5),
                      FlSpot(4, 4),
                      FlSpot(5, 6),
                      FlSpot(6, 5),
                      FlSpot(7, 6.5),
                      FlSpot(8, 6),
                      FlSpot(9, 7),
                      FlSpot(10, 6.5),
                      FlSpot(11, 8),
                    ],
                  ),

                  /// LAST YEAR (GREY FLOW LINE)
                  LineChartBarData(
                    isCurved: true,
                    color: Colors.grey,
                    barWidth: 2,
                    dotData: FlDotData(show: false),

                    spots: const [
                      FlSpot(0, 2),
                      FlSpot(1, 3),
                      FlSpot(2, 2.5),
                      FlSpot(3, 4),
                      FlSpot(4, 3.5),
                      FlSpot(5, 5),
                      FlSpot(6, 4),
                      FlSpot(7, 5.5),
                      FlSpot(8, 5),
                      FlSpot(9, 6),
                      FlSpot(10, 5.5),
                      FlSpot(11, 6.5),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  // Updated Recent Activities with Latest Companies API
  Widget _buildRecentActivities(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Latest Companies",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.circle, color: Colors.green, size: 6),
              ),
            ],
          ),
          const SizedBox(height: 45),

          if (_isLoadingCompanies)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_latestCompanies.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text("No companies found", style: TextStyle(fontSize: 12)),
              ),
            )
          else
            ...List.generate(_latestCompanies.length, (index) {
              return _buildCompanyItem(_latestCompanies[index], isDark, index);
            }),

          /*  Center(
            child: TextButton(
              onPressed: () {
                // Open All Companies screen if needed
              },
              style: TextButton.styleFrom(
                  padding: EdgeInsets.zero, minimumSize: const Size(40, 20)),
              child: const Text("View All", style: TextStyle(fontSize: 11)),
            ),
          ),*/
        ],
      ),
    );
  }

  // New Company Item Builder
  Widget _buildCompanyItem(LatestCompany company, bool isDark, int index) {
    final List<Color> colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal];
    final Color itemColor = colors[index % colors.length];

    // ✅ योग्य URL तयार करण्यासाठी function
    String getImageUrl(String? s3Key) {
      if (s3Key == null || s3Key.isEmpty) return '';
      // जर आधीच full URL असेल
      if (s3Key.startsWith('http')) return s3Key;
      // baseUrl + s3Key
      return '${ApiUrls.baseUrl}/$s3Key';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [itemColor, itemColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: company.logoS3Key != null && company.logoS3Key!.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  getImageUrl(company.logoS3Key), // ✅ FIXED URL
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // ✅ एरर आल्यावर Text दाखवा
                    return Text(
                      company.name.isNotEmpty ? company.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16
                      ),
                    );
                  },
                ),
              )
                  : Text(
                company.name.isNotEmpty ? company.name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        company.ownerName,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders(bool isDark) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Recent Enquiries",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
              TextButton(
                onPressed: () {
                  // Optionally navigate to full enquiry list
                },
                style: TextButton.styleFrom(
                    padding: EdgeInsets.zero, minimumSize: const Size(40, 20)),
                child: const Text("View All", style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isLoadingEnquiries)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_latestEnquiries.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text("No recent enquiries", style: TextStyle(fontSize: 12)),
              ),
            )
          else
            ..._latestEnquiries.map((enquiry) => _buildEnquiryItem(enquiry, isDark)).toList(),
        ],
      ),
    );
  }

  Widget _buildEnquiryItem(LatestEnquiry enquiry, bool isDark) {
    // Different colors for avatar
    final List<Color> colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal];
    final Color avatarColor = colors[enquiry.id % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [avatarColor, avatarColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                enquiry.personName.isNotEmpty ? enquiry.personName[0].toUpperCase() : '?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enquiry.personName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
            /*        Flexible(
                      child: Text(
                        'ID: ${enquiry.id}',
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),*/

                    Container(
                      width: 2,
                      height: 2,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),

                    const SizedBox(width: 4),

                    // 🔥 IMPORTANT FIX
                    Expanded(
                      child: Text(
                        enquiry.shopName,
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Company name as a badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: avatarColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  enquiry.companyName,
                  style: TextStyle(fontSize: 8, color: avatarColor, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // NEW: Latest Products section (replaces old Top Selling Products)
  Widget _buildLatestProducts(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024; // डेस्कटॉपसाठी गरज नसल्यास स्क्रोलबार नको

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(
                child: Text(
                  "Latest Products",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_isLoadingProducts)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_latestProducts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text("No latest products", style: TextStyle(fontSize: 12)),
              ),
            )
          else
          // मोबाइल/टॅब्लेटसाठी स्क्रोल करण्याजोगे विजेट
            isDesktop
                ? _buildDesktopDataTable(isDark)
                : Scrollbar(
              thickness: 6,
              radius: const Radius.circular(10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildDesktopDataTable(isDark), // समान DataTable
              ),
            ),
        ],
      ),
    );
  }

// डेस्कटॉप आणि स्क्रोल करताना वापरण्यासाठी सामान्य DataTable
  Widget _buildDesktopDataTable(bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          // डेस्कटॉपवर पूर्ण रुंदी, स्क्रोल करताना ही width लागू होत नाही (पण ठेवली तरी चालेल)
          width: constraints.maxWidth,
          child: DataTable(
            columnSpacing: 8,
            horizontalMargin: 0,
            headingRowHeight: 32,
            dataRowHeight: 44,
            headingRowColor: MaterialStateProperty.all(
              isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
            ),
            headingTextStyle: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[300] : const Color(0xFF4158D0),
              fontSize: 11,
            ),
            columns: const [
              DataColumn(label: Text("Sr No")),
              DataColumn(label: Text("Thumbnail")),
              DataColumn(label: Text("Name")),
              DataColumn(label: Text("Company")),
              DataColumn(label: Text("Category")),
              DataColumn(label: Text("Brand")),
            ],
            rows: _latestProducts.asMap().entries.map((entry) {
              int index = entry.key;
              var product = entry.value;
              return DataRow(cells: [
                DataCell(
                  SizedBox(
                    width: 35,
                    child: Text(
                      (index + 1).toString(),
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ),
                DataCell(
                  product.thumbnail.isNotEmpty
                      ? Image.network(
                    product.thumbnail,
                    width: 30,
                    height: 30,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 30,
                        height: 30,
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image, size: 18),
                      );
                    },
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        width: 30,
                        height: 30,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                  )
                      : Container(
                    width: 28,
                    height: 28,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported, size: 16),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 80,
                    child: Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 80,
                    child: Text(
                      product.companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 65,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.categoryName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 65,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.brandName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.purple[700],
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }


  Widget _buildOrderItem(Map<String, dynamic> order, bool isDark) {
    Color statusColor;
    IconData statusIcon;

    switch (order['status']) {
      case 'Delivered':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Processing':
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case 'Shipped':
        statusColor = Colors.orange;
        statusIcon = Icons.local_shipping;
        break;
      default:
        statusColor = Colors.red;
        statusIcon = Icons.pending;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [statusColor, statusColor.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                order['avatar'],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order['customer'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        order['id'],
                        style: TextStyle(
                          fontSize: 9,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      width: 2,
                      height: 2,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[600] : Colors.grey[400],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${order['items']} items',
                      style: TextStyle(
                        fontSize: 9,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                order['amount'],
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 8, color: statusColor),
                    const SizedBox(width: 2),
                    Text(
                      order['status'],
                      style: TextStyle(fontSize: 8, color: statusColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  "Top Selling Products",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download, size: 12),
                    SizedBox(width: 2),
                    Text("Export", style: TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              headingRowHeight: 32,
              dataRowHeight: 48,
              headingRowColor: MaterialStateProperty.all(
                isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
              ),
              headingTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[300] : const Color(0xFF4158D0),
                fontSize: 11,
              ),
              columns: const [
                DataColumn(label: Text("Product")),
                DataColumn(label: Text("Category")),
                DataColumn(label: Text("Sales")),
                DataColumn(label: Text("Revenue")),
                DataColumn(label: Text("Growth")),
              ],
              rows: _topProducts.map((product) {
                return DataRow(cells: [
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(product['image'], style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            product['name'],
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white : Colors.black),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product['category'],
                        style: TextStyle(color: Colors.blue[700], fontSize: 9, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(
                    Text(
                      product['sales'].toString(),
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white : Colors.black),
                    ),
                  ),
                  DataCell(
                    Text(
                      product['revenue'],
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product['growth'],
                        style: TextStyle(color: Colors.green[700], fontSize: 9, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsFooter(bool isDark, bool isMobile, bool isTablet) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16213E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (isMobile || isTablet) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.spaceEvenly,
              children: _getQuickStats(isDark),
            );
          } else {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _getQuickStats(isDark),
            );
          }
        },
      ),
    );
  }

  List<Widget> _getQuickStats(bool isDark) {
    return [
      _buildQuickStat(
        label: 'Conversion',
        value: '3.24%',
        change: '+0.5%',
        icon: Icons.trending_up,
        color: Colors.green,
        isDark: isDark,
      ),
      _buildQuickStat(
        label: 'Avg. Order',
        value: '₹2.4k',
        change: '+12%',
        icon: Icons.shopping_bag,
        color: Colors.blue,
        isDark: isDark,
      ),
      _buildQuickStat(
        label: 'Return',
        value: '1.2%',
        change: '-0.3%',
        icon: Icons.assignment_return,
        color: Colors.orange,
        isDark: isDark,
      ),
      _buildQuickStat(
        label: 'Satisfaction',
        value: '4.8',
        change: '+0.2',
        icon: Icons.star,
        color: Colors.purple,
        isDark: isDark,
      ),
    ];
  }

  Widget _buildQuickStat({
    required String label,
    required String value,
    required String change,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      width: 75,
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 12),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(fontSize: 7, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
          const SizedBox(height: 1),
          Text(
            change,
            style: TextStyle(
              fontSize: 7,
              color: change.startsWith('+') ? Colors.green : Colors.red,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
class _HoverCard extends StatefulWidget {
  final Widget Function(bool isHover) builder;
  final VoidCallback onTap;

  const _HoverCard({
    required this.builder,
    required this.onTap,
  });

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
          child: widget.builder(isHover), // 👈 hover state pass केला
        ),
      ),
    );
  }
}*/