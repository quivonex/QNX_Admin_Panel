import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:battery_regeneration_system/screens/qnx_admin/login_screen.dart';
import 'package:battery_regeneration_system/screens/qnx_admin/dashboard.dart';
import 'package:battery_regeneration_system/screens/marketing_head/marketing_head_dashboard.dart';
import 'package:battery_regeneration_system/screens/marketing_partner/marketing_partner_dashboard.dart';
import 'package:battery_regeneration_system/services/notification_service.dart';
import 'firebase_options.dart';

// Your other screens (for testing buttons) – kept as is
import 'package:battery_regeneration_system/screens/qnx_admin/unit_create.dart';
import 'package:battery_regeneration_system/screens/qnx_admin/role_create.dart';
import 'package:battery_regeneration_system/screens/qnx_admin/admin_create.dart';
import 'package:battery_regeneration_system/screens/qnx_admin/category_create.dart';
import 'package:battery_regeneration_system/screens/qnx_admin/user_enquiry_screen.dart';
import 'package:battery_regeneration_system/screens/qnx_admin/offer_screen.dart';
import 'package:battery_regeneration_system/screens/qnx_admin/enquiry_list_screen.dart';
import 'package:battery_regeneration_system/screens/qnx_admin/company_all_screen.dart';
import 'package:battery_regeneration_system/screens/qnx_admin/subcategory_screen.dart';
import 'package:battery_regeneration_system/screens/qnx_admin/pending_product_list_screen.dart';
import 'package:battery_regeneration_system/screens/qnx_admin/approve_product_list.dart';
import 'package:battery_regeneration_system/screens/qnx_admin/agreement_screen.dart';

// Global navigator key for navigation from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');

    // Request notification permissions
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('🔔 Notification permission: ${settings.authorizationStatus}');

    // Initialize Notification Service
    await NotificationService.init();
    print('✅ Notification Service initialized');

    // Get FCM Token for debugging
    String? token = await FirebaseMessaging.instance.getToken();
    print('📱 FCM Token: $token');

  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QNX MART',
      navigatorKey: navigatorKey, // For notification navigation
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // 🟢 MaterialType.transparency handles material ancestor context globally
      builder: (context, child) {
        return Material(
          type: MaterialType.transparency,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isChecking = true;
  Widget? _initialScreen;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userRole = prefs.getString('user_role') ?? '';

    Widget screen;
    if (token != null && token.isNotEmpty) {
      // User is logged in – show appropriate dashboard
      final role = userRole.trim().toLowerCase();

      switch (role) {
        case 'marketing head':
        case 'marketing_head':
          screen = const MarketingHeadDashboard();
          break;
        case 'marketing partner':
        case 'marketing_partner':
          screen = const MarketingPartnerDashboard();
          break;
        case 'admin':
        case 'qnx admin':
        case 'qnx_admin':
          screen = const DashboardScreen();
          break;
        default:
          screen = const LoginScreen();
      }
    } else {
      screen = const LoginScreen();
    }

    if (mounted) {
      setState(() {
        _initialScreen = screen;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      // Simple loading indicator inside a Scaffold
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/img_2.png',
                height: 100,
                errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.flash_on, size: 60, color: Colors.deepPurple),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              const Text('Checking session...'),
            ],
          ),
        ),
      );
    }

    return Material(
      type: MaterialType.transparency,
      child: _initialScreen ?? const LoginScreen(),
    );
  }
}

// ----------------------------------------------------------------------
// Your test screen (MyHomePage) – unchanged, kept for development
// ----------------------------------------------------------------------
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('You have pushed the button this many times:'),
              Text(
                '$_counter',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),
              // All your test buttons (they remain the same)
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UnitCreateScreen(),
                    ),
                  );
                },
                child: const Text("Unit"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RoleCreateScreen(),
                    ),
                  );
                },
                child: const Text("role"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                child: const Text("login"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminCreateScreen(),
                    ),
                  );
                },
                child: const Text("admin create"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoryScreen(),
                    ),
                  );
                },
                child: const Text(" category"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserEnquiryScreen(),
                    ),
                  );
                },
                child: const Text(" user enquiry"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OfferListScreen(),
                    ),
                  );
                },
                child: const Text(" Offer list"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EnquiryListScreen(),
                    ),
                  );
                },
                child: const Text(" enquiry list"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CompanyAllScreen(),
                    ),
                  );
                },
                child: const Text(" all companies"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SubCategoryAllScreen(),
                    ),
                  );
                },
                child: const Text(" subcategory list"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PendingProductListScreen(),
                    ),
                  );
                },
                child: const Text(" pending product list"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ApprovedProductListScreen(),
                    ),
                  );
                },
                child: const Text(" product approved list"),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DashboardScreen(),
                    ),
                  );
                },
                child: const Text(" dashboard"),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}