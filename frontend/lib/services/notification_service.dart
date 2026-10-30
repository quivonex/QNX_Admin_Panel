import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/notification/notification_model.dart';

class NotificationService {
  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  static const String _notificationsKey = 'cached_notifications';
  static List<NotificationModel> _notifications = [];

  // Callback for when notifications change
  static Function(List<NotificationModel>)? onNotificationsChanged;

  // Get all notifications
  static List<NotificationModel> get notifications => _notifications;

  // Get unread count
  static int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Get total count
  static int get count => _notifications.length;

  static Future<void> init() async {
    try {
      // Request permissions
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print('🔔 Notification permission: ${settings.authorizationStatus}');

      if (settings.authorizationStatus != AuthorizationStatus.authorized) {
        print('⚠️ User declined or has not granted permission');
        return;
      }

      // Load cached notifications
      await _loadCachedNotifications();

      // Initialize local notifications
      const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
      DarwinInitializationSettings();
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Get FCM token
      String? token = await _fcm.getToken();
      print('📱 FCM Token: $token');

      // Set up FCM listeners
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      print('✅ Notification Service initialized successfully');
      print('📬 Total notifications: ${_notifications.length}');
      print('🔴 Unread notifications: ${unreadCount}');
    } catch (e) {
      print('❌ Notification Service initialization error: $e');
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    print('👆 Notification tapped: ${response.payload}');
    // Handle notification tap for navigation
    if (response.payload != null && response.payload!.isNotEmpty) {
      // Navigate using navigatorKey
      // navigatorKey.currentState?.pushNamed(response.payload!);
    }
  }

  static Future<void> _loadCachedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? cached = prefs.getString(_notificationsKey);
      if (cached != null && cached.isNotEmpty) {
        List<dynamic> decoded = jsonDecode(cached);
        _notifications = decoded.map((item) => NotificationModel.fromJson(item)).toList();
        print('✅ Loaded ${_notifications.length} cached notifications');
      } else {
        // Add default welcome notification
        _addDefaultWelcomeNotification();
      }
    } catch (e) {
      print('⚠️ Error loading cached notifications: $e');
      _addDefaultWelcomeNotification();
    }
  }

  static void _addDefaultWelcomeNotification() {
    if (_notifications.isEmpty) {
      _notifications.add(
        NotificationModel(
          id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
          title: 'Welcome to QNXmart!',
          body: 'Your admin dashboard is ready to use.',
          time: 'Just now',
          isRead: false,
          route: 'dashboard',
          createdAt: DateTime.now(),
        ),
      );
      _saveCachedNotifications();
    }
  }

  static Future<void> _saveCachedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String encoded = jsonEncode(_notifications.map((n) => n.toJson()).toList());
      await prefs.setString(_notificationsKey, encoded);
      print('💾 Saved ${_notifications.length} notifications to cache');

      // Notify listeners
      onNotificationsChanged?.call(_notifications);
    } catch (e) {
      print('⚠️ Error saving cached notifications: $e');
    }
  }

  // ✅ PUBLIC METHOD - Call this from dashboard.dart
  static void addNotification({
    required String title,
    required String body,
    String? route,
    String? icon,
  }) {
    _addNotification(
      title: title,
      body: body,
      route: route,
      icon: icon,
    );
  }

  // ✅ PRIVATE METHOD - Internal use only
  static void _addNotification({
    required String title,
    required String body,
    String? route,
    String? icon,
  }) {
    // Check if notification already exists (avoid duplicates)
    final exists = _notifications.any((n) => n.title == title && n.body == body);
    if (exists) {
      print('⚠️ Notification already exists, skipping duplicate');
      return;
    }

    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      time: _getTimeAgo(DateTime.now()),
      isRead: false,
      route: route,
      icon: icon,
      createdAt: DateTime.now(),
    );

    _notifications.insert(0, notification);
    _saveCachedNotifications();
    _notifyListeners();

    print('✅ New notification added: $title');

    // Show local notification
    _showLocalNotification(
      title: title,
      body: body,
      payload: route ?? '',
    );
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    print('📨 Foreground message received: ${message.notification?.title}');

    final String title = message.notification?.title ?? 'QNXmart Notification';
    final String body = message.notification?.body ?? 'You have a new notification';
    final Map<String, dynamic> data = message.data;

    // Add to notification list
    _addNotification(
      title: title,
      body: body,
      route: data['route'],
      icon: data['icon'],
    );

    // Show local notification
    _showLocalNotification(
      title: title,
      body: body,
      payload: data['route'] ?? '',
    );

    // Update unread count
    _notifyListeners();
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    print('📱 App opened from notification: ${message.notification?.title}');

    String? route = message.data['route'];
    if (route != null && route.isNotEmpty) {
      // Mark notification as read when opened
      final title = message.notification?.title ?? '';
      _markNotificationAsReadByTitle(title);

      // Navigate using navigatorKey
      // navigatorKey.currentState?.pushNamed(route);
    }
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    print('📨 Background message received: ${message.notification?.title}');

    final String title = message.notification?.title ?? 'QNXmart Notification';
    final String body = message.notification?.body ?? 'You have a new notification';
    final Map<String, dynamic> data = message.data;

    _addNotification(
      title: title,
      body: body,
      route: data['route'],
      icon: data['icon'],
    );

    _notifyListeners();
  }

  static void _markNotificationAsReadByTitle(String title) {
    final index = _notifications.indexWhere((n) => n.title == title && !n.isRead);
    if (index != -1) {
      _notifications[index].isRead = true;
      _saveCachedNotifications();
      _notifyListeners();
      print('✅ Notification marked as read: $title');
    }
  }

  static String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes} min ago';
    if (difference.inHours < 24) return '${difference.inHours} hours ago';
    if (difference.inDays < 7) return '${difference.inDays} days ago';
    if (difference.inDays < 30) return '${(difference.inDays / 7).floor()} weeks ago';
    if (difference.inDays < 365) return '${(difference.inDays / 30).floor()} months ago';
    return '${(difference.inDays / 365).floor()} years ago';
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'qnxmart_channel',
        'QNXmart Notifications',
        channelDescription: 'Notifications from QNXmart',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        enableVibration: true,
        enableLights: true,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('notification'),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecond,
        title,
        body,
        details,
        payload: payload,
      );
      print('✅ Local notification shown');
    } catch (e) {
      print('⚠️ Local notification error: $e');
    }
  }

  static Future<String?> getToken() async {
    return await _fcm.getToken();
  }

  // Public methods for managing notifications

  static void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index].isRead = true;
      _saveCachedNotifications();
      _notifyListeners();
      print('✅ Notification marked as read: ${_notifications[index].title}');
    }
  }

  static void markAllAsRead() {
    bool hasUnread = false;
    for (var notification in _notifications) {
      if (!notification.isRead) {
        notification.isRead = true;
        hasUnread = true;
      }
    }
    if (hasUnread) {
      _saveCachedNotifications();
      _notifyListeners();
      print('✅ All notifications marked as read');
    }
  }

  static void clearAll() {
    _notifications.clear();
    _saveCachedNotifications();
    _notifyListeners();
    print('🗑️ All notifications cleared');
  }

  static void removeNotification(String id) {
    _notifications.removeWhere((n) => n.id == id);
    _saveCachedNotifications();
    _notifyListeners();
    print('🗑️ Notification removed: $id');
  }

  static int getUnreadCount() {
    return _notifications.where((n) => !n.isRead).length;
  }

  static List<NotificationModel> getNotifications() {
    return _notifications;
  }

  static Future<void> refresh() async {
    await _loadCachedNotifications();
    _notifyListeners();
  }

  static void _notifyListeners() {
    onNotificationsChanged?.call(_notifications);
  }

  // ✅ Public notify method if needed externally
  static void notifyListeners() {
    _notifyListeners();
  }

  // ✅ Get notification data with count
  static Map<String, dynamic> getNotificationData() {
    return {
      'notifications': _notifications,
      'unreadCount': unreadCount,
      'totalCount': _notifications.length,
    };
  }
}