/*
// lib/screens/support/support_dashboard.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io' show Platform;
import '../../models/map/place_model.dart' as place_model;
import '../../api/place_service.dart';
import '../../screens/qnx_admin/login_screen.dart';
import '../marketing_head/marketing_head_dashboard.dart';
import '../marketing_partner/marketing_partner_dashboard.dart';
import '../qnx_admin/dashboard.dart';
import '../real_estate/create_builder_screen.dart';
import '../real_estate/create_property_screen.dart';
import '../real_estate/create_builder_property_screen.dart';

// ============================================================
// CONSTANTS
// ============================================================

class SupportConstants {
  static const String appName = 'QNX Mart Support';

  static const double defaultLatitude = 18.5204;
  static const double defaultLongitude = 73.8567;

  static const int defaultZoom = 14;

  static const String defaultMarketingMessage = '''
🚀 *Grow Your Business with QNX MART!*

Why pay ₹1–2 Lakh every month on expensive marketing? Get direct verified B2B buyer inquiries on WhatsApp for your store in {Location}! Let's connect.

✨ Key Benefits for Your Business:

✅ Register Your Company & Add Owner Details

✅ Upload Unlimited Products

✅ Connect with Suppliers & Dealers

✅ Reach Thousands of Customers & Boost Sales

📞 Need Help or Have Questions?

Call (Toll-Free): (+91) 9226859922

Email: quivonexsolutions@gmail.com

👇 Check out the banner attached above for details!

👉 Register Your Company Today & Start Growing!

https://drive.google.com/file/d/1G-ZcYwMXEqbDuEFBZPkFVBRa85JJp9vl/view?usp=drive_link

https://qnxmartb2b.com/info-company

use referrel link to register your company = https://qnxmartb2b.com/company_create?ref=MPJJG9N8F2

''';
}

// ============================================================
// COLOR TOKENS (matching HTML design)
// ============================================================

class _AppColors {
  static const brand500 = Color(0xFF6366F1);
  static const brand600 = Color(0xFF4F46E5);
  static const brand700 = Color(0xFF4338CA);
  static const brand50 = Color(0xFFEEF2FF);
  static const brand100 = Color(0xFFE0E7FF);

  static const whatsapp500 = Color(0xFF22C55E);
  static const whatsapp600 = Color(0xFF16A34A);
  static const whatsapp700 = Color(0xFF15803D);
  static const whatsapp50 = Color(0xFFF0FDF4);

  static const slate50 = Color(0xFFF8FAFC);
  static const slate100 = Color(0xFFF1F5F9);
  static const slate200 = Color(0xFFE2E8F0);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate400 = Color(0xFF94A3B8);
  static const slate500 = Color(0xFF64748B);
  static const slate600 = Color(0xFF475569);
  static const slate700 = Color(0xFF334155);
  static const slate800 = Color(0xFF1E293B);
  static const slate900 = Color(0xFF0F172A);

  static const emerald50 = Color(0xFFECFDF5);
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald200 = Color(0xFFA7F3D0);
  static const emerald400 = Color(0xFF34D399);
  static const emerald500 = Color(0xFF10B981);
  static const emerald600 = Color(0xFF059669);
  static const emerald700 = Color(0xFF047857);
  static const emerald800 = Color(0xFF065F46);

  static const amber50 = Color(0xFFFFFBEB);
  static const amber100 = Color(0xFFFEF3C7);
  static const amber200 = Color(0xFFFDE68A);
  static const amber500 = Color(0xFFF59E0B);
  static const amber600 = Color(0xFFD97706);
  static const amber700 = Color(0xFFB45309);
  static const amber800 = Color(0xFF92400E);

  static const red500 = Color(0xFFEF4444);
  static const red600 = Color(0xFFDC2626);

  static const violet500 = Color(0xFF8B5CF6);

  static const mapBg = Color(0xFFE5EDF5);
}

// ============================================================
// SUPPORT DASHBOARD
// ============================================================

class SupportDashboard extends StatefulWidget {
  const SupportDashboard({super.key});

  @override
  State<SupportDashboard> createState() => _SupportDashboardState();
}

class _SupportDashboardState extends State<SupportDashboard>
    with WidgetsBindingObserver {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _searchController = TextEditingController();

  final TextEditingController _marketingMessageController =
  TextEditingController(
    text: SupportConstants.defaultMarketingMessage,
  );

  // ============================================================
  // SERVICES
  // ============================================================

  final PlaceService _placeService = PlaceService();

  final ImagePicker _imagePicker = ImagePicker();

  // ============================================================
  // UI STATE
  // ============================================================
  bool _isPopupOpen = false;
  bool _isDarkMode = false;
  bool _isLoading = false;
  bool _isPinSet = false;
  bool _isAuthorized = false;
  bool _isMapReady = false;
  bool _hasSearched = false;
  bool _isGettingLocationName = false;
  bool get _mapInteractionEnabled => !_isPopupOpen;
  String _userRole = '';

  // ============================================================
  // SEARCH & LOCATION
  // ============================================================

  String _searchQuery = '';

  int _selectedRadius = 10;

  final List<int> _radiusOptions = [
    5,
    10,
    15,
    20,
    25,
    30,
    40,
    50,
  ];

  String _locationName = '';

  // ============================================================
  // MAP
  // ============================================================

  GoogleMapController? _mapController;

  LatLng _currentLocation = const LatLng(
    SupportConstants.defaultLatitude,
    SupportConstants.defaultLongitude,
  );

  LatLng? _selectedLocation;

  // ============================================================
  // PLACES DATA
  // ============================================================

  List<place_model.PlaceResult> _allPlaces = [];

  List<place_model.PlaceResult> _filteredPlaces = [];

  List<place_model.PlaceResult> _currentPagePlaces = [];

  String? _errorMessage;

  // ============================================================
  // PAGINATION
  // ============================================================

  int _currentPage = 0;

  final List<List<place_model.PlaceResult>> _pagesCache = [];

  String? _nextPageToken;

  bool _isFetchingPage = false;

  bool _hasNextPage = false;

  // ============================================================
  // IMAGE
  // ============================================================

  XFile? _selectedMarketingImage;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _checkUserRoleAndLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _searchController.dispose();

    _marketingMessageController.dispose();

    _mapController?.dispose();

    _placeService.dispose();

    super.dispose();
  }

  // ============================================================
  // APP LIFECYCLE
  // ============================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  // ============================================================
  // AUTHENTICATION & LOCATION
  // ============================================================

  Future<void> _checkUserRoleAndLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final role = prefs.getString('user_role') ?? '';

      final roleLower = role.toLowerCase().trim();

      final isSupport = roleLower.contains('support') ||
          roleLower == 'support_agent' ||
          roleLower == 'support agent' ||
          roleLower == 'application support' ||
          roleLower.contains('application support');

      if (!mounted) return;

      setState(() {
        _userRole = role;
        _isAuthorized = isSupport;
      });

      if (isSupport) {
        await _getCurrentLocation();
        _updateMapLocation();
      } else {
        _redirectToDashboard(role);
      }
    } catch (e) {
      debugPrint('❌ Error in _checkUserRoleAndLocation: $e');

      if (!mounted) return;

      setState(() {
        _isAuthorized = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();

        if (!mounted) return;

        setState(() {
          _currentLocation = const LatLng(
            SupportConstants.defaultLatitude,
            SupportConstants.defaultLongitude,
          );
          _selectedLocation = _currentLocation;
          _isPinSet = true;
        });

        await _getLocationName(_currentLocation);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          _setDefaultLocation();
          await _getLocationName(_currentLocation);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setDefaultLocation();
        await _getLocationName(_currentLocation);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _selectedLocation = _currentLocation;
        _isPinSet = true;
      });

      await _getLocationName(_currentLocation);
      _updateMapLocation();
    } catch (e) {
      debugPrint('❌ Error getting location: $e');
      _setDefaultLocation();
      await _getLocationName(_currentLocation);
    }
  }

  void _setDefaultLocation() {
    if (!mounted) return;

    setState(() {
      _currentLocation = const LatLng(
        SupportConstants.defaultLatitude,
        SupportConstants.defaultLongitude,
      );
      _selectedLocation = _currentLocation;
      _isPinSet = true;
    });
  }

  void _updateMapLocation() {
    if (_mapController != null && _isMapReady) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentLocation,
            zoom: SupportConstants.defaultZoom.toDouble(),
          ),
        ),
      );
    }
  }

  Future<void> _getLocationName(LatLng location) async {
    if (_isGettingLocationName) return;
    if (!mounted) return;

    setState(() {
      _isGettingLocationName = true;
      _locationName = 'Fetching...';
    });

    try {
      final response = await _placeService.getLocationName(
        lat: location.latitude,
        lng: location.longitude,
      );

      if (!mounted) return;

      setState(() {
        if (response != null &&
            response.isNotEmpty &&
            !response.contains('Unknown') &&
            !response.contains('Unable') &&
            !response.contains('null')) {
          _locationName = response;
        } else {
          _locationName = _formatCoordinates(location);
        }
        _isGettingLocationName = false;
      });
    } catch (e) {
      debugPrint('❌ Error getting location name: $e');

      if (!mounted) return;

      setState(() {
        _locationName = _formatCoordinates(location);
        _isGettingLocationName = false;
      });
    }
  }

  String _formatCoordinates(LatLng location) {
    final lat = location.latitude.toStringAsFixed(4);
    final lng = location.longitude.toStringAsFixed(4);
    return '$lat, $lng';
  }

  void _redirectToDashboard(String role) {
    if (!mounted) return;

    final roleLower = role.toLowerCase().trim();

    Widget dashboard;

    if (roleLower.contains('admin') || roleLower.contains('qnx admin')) {
      dashboard = const DashboardScreen();
    } else if (roleLower.contains('marketing head') ||
        roleLower.contains('marketing_head')) {
      dashboard = const MarketingHeadDashboard();
    } else if (roleLower.contains('marketing partner') ||
        roleLower.contains('marketing_partner')) {
      dashboard = const MarketingPartnerDashboard();
    } else {
      dashboard = const LoginScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => dashboard),
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  Future<void> _searchNearbyPlaces(
      LatLng location, {
        String? keyword,
        String? pageToken,
      }) async {
    if (!mounted) return;
    if (_isFetchingPage) return;

    final bool isFreshSearch = pageToken == null;

    setState(() {
      _isFetchingPage = true;

      if (isFreshSearch) {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 0;
        _hasSearched = true;
        _allPlaces = [];
        _filteredPlaces = [];
        _currentPagePlaces = [];
        _pagesCache.clear();
        _nextPageToken = null;
        _hasNextPage = false;
      }
    });

    try {
      final response = await _placeService.searchNearbyPlaces(
        lat: location.latitude,
        lng: location.longitude,
        radius: _selectedRadius * 1000,
        keyword: keyword,
        pageToken: pageToken,
      );

      if (!mounted) return;

      setState(() {
        _pagesCache.add(response.results);
        _allPlaces.addAll(response.results);
        _filteredPlaces = List.from(_allPlaces);

        _currentPage = _pagesCache.length - 1;
        _currentPagePlaces = _pagesCache[_currentPage];

        _nextPageToken = response.nextPageToken;
        _hasNextPage = _nextPageToken != null;

        _isLoading = false;
        _isFetchingPage = false;
        _isPinSet = true;
        _selectedLocation = location;
      });

      await _getLocationName(location);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isFetchingPage = false;
      });

      _showSnackBar('Error: $e', isError: true);
    }
  }

  Future<void> _fetchNextPage() async {
    if (_isFetchingPage) return;

    if (_currentPage + 1 < _pagesCache.length) {
      setState(() {
        _currentPage++;
        _currentPagePlaces = _pagesCache[_currentPage];
      });
      return;
    }

    if (!_hasNextPage || _nextPageToken == null) return;

    final location = _selectedLocation ?? _currentLocation;
    final keyword = _searchQuery.trim().isEmpty ? null : _searchQuery.trim();
    final tokenToUse = _nextPageToken;

    setState(() {
      _isFetchingPage = true;
    });

    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    setState(() {
      _isFetchingPage = false;
    });

    await _searchNearbyPlaces(
      location,
      keyword: keyword,
      pageToken: tokenToUse,
    );
  }

  void _fetchPrevPage() {
    if (_isFetchingPage) return;
    if (_currentPage <= 0) return;

    setState(() {
      _currentPage--;
      _currentPagePlaces = _pagesCache[_currentPage];
    });
  }

  void _goToPage(int pageIndex) {
    if (_isFetchingPage) return;
    if (pageIndex < 0 || pageIndex >= _pagesCache.length) return;
    if (pageIndex == _currentPage) return;

    setState(() {
      _currentPage = pageIndex;
      _currentPagePlaces = _pagesCache[_currentPage];
    });
  }

  Future<void> _loadAllPages() async {
    if (_isFetchingPage) return;

    final location = _selectedLocation ?? _currentLocation;
    final keyword = _searchQuery.trim().isEmpty ? null : _searchQuery.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      if (_pagesCache.isEmpty) {
        await _searchNearbyPlaces(location, keyword: keyword);
      }

      int safetyCounter = 0;

      while (_hasNextPage && _nextPageToken != null && safetyCounter < 10) {
        final tokenToUse = _nextPageToken;

        await Future.delayed(const Duration(milliseconds: 2000));

        if (!mounted) return;

        await _searchNearbyPlaces(
          location,
          keyword: keyword,
          pageToken: tokenToUse,
        );

        safetyCounter++;
      }

      if (!mounted) return;

      setState(() {
        final merged = <place_model.PlaceResult>[];
        for (final page in _pagesCache) {
          merged.addAll(page);
        }

        _pagesCache
          ..clear()
          ..add(merged);

        _currentPage = 0;
        _currentPagePlaces = merged;
        _allPlaces = merged;
        _filteredPlaces = List.from(merged);
        _isLoading = false;
      });

      _showSnackBar('Loaded ${_currentPagePlaces.length} places');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar('Error loading all pages: $e', isError: true);
    }
  }

  void _onSearch() {
    final location = _selectedLocation ?? _currentLocation;
    final keyword = _searchQuery.trim().isEmpty ? null : _searchQuery.trim();

    _searchNearbyPlaces(location, keyword: keyword);
  }

  void _onRadiusChanged(int? newRadius) {
    if (newRadius == null) return;
    if (newRadius == _selectedRadius) return;

    setState(() {
      _selectedRadius = newRadius;
    });
  }

  // ============================================================
  // MAP
  // ============================================================

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _isMapReady = true;

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentLocation,
          zoom: SupportConstants.defaultZoom.toDouble(),
        ),
      ),
    );
  }

  Future<void> _onMapTap(LatLng position) async {
    if (_isPopupOpen) return;

    if (_hasSearched) {
      setState(() {
        _isPopupOpen = true;
      });

      final bool? shouldRemove = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.65),
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text(
              'Remove Previous Data?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Are you sure you want to remove previous data?\n\n'
                  'All search results will be cleared and the new location will be selected.',
              style: TextStyle(fontSize: 14),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext, rootNavigator: true).pop(false);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'No',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext, rootNavigator: true).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _AppColors.red600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Yes, Clear Data',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      );

      if (shouldRemove != true) {
        await Future.delayed(const Duration(milliseconds: 350));

        if (mounted) {
          setState(() {
            _isPopupOpen = false;
          });
        }

        _showSnackBar('Data kept as is', isError: false);
        return;
      }

      _clearPreviousData();

      if (mounted) {
        setState(() {
          _isPopupOpen = false;
        });
      }
    }

    setState(() {
      _selectedLocation = position;
      _isPinSet = true;
      _locationName = 'Fetching...';
    });

    _mapController?.animateCamera(
      CameraUpdate.newLatLng(position),
    );

    await _getLocationName(position);
  }

  Future<void> _confirmRemoveData() async {
    setState(() {
      _isPopupOpen = true;
    });

    final bool? shouldRemove = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Remove Previous Data?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to remove previous data?\n\n'
                'All search results and selected location data will be cleared.',
            style: TextStyle(fontSize: 14),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext, rootNavigator: true).pop(false);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'No',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext, rootNavigator: true).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _AppColors.red600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Yes, Clear Data',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );

    if (mounted) {
      setState(() {
        _isPopupOpen = false;
      });
    }

    if (shouldRemove == true) {
      _clearPreviousData();
      _showSnackBar('Data cleared successfully', isError: false);
    } else {
      _showSnackBar('Data kept as is', isError: false);
    }
  }

  void _clearPreviousData() {
    setState(() {
      _allPlaces = [];
      _filteredPlaces = [];
      _currentPagePlaces = [];
      _currentPage = 0;
      _hasSearched = false;
      _errorMessage = null;
      _pagesCache.clear();
      _nextPageToken = null;
      _hasNextPage = false;
      _isFetchingPage = false;
    });
  }

  void _clearPlacesData() {
    if (!mounted) return;

    setState(() {
      _allPlaces = [];
      _filteredPlaces = [];
      _currentPagePlaces = [];
      _currentPage = 0;
      _hasSearched = false;
      _errorMessage = null;
      _pagesCache.clear();
      _nextPageToken = null;
      _hasNextPage = false;
      _isFetchingPage = false;
    });
  }

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = {};

    if (_selectedLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          infoWindow: const InfoWindow(title: '📍 Selected Location'),
        ),
      );
    }

    if (_hasSearched) {
      for (final place in _currentPagePlaces) {
        markers.add(
          Marker(
            markerId: MarkerId(place.placeId),
            position: LatLng(
              place.geometry.location.lat,
              place.geometry.location.lng,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
            infoWindow: InfoWindow(
              title: place.name,
              snippet: place.displayAddress,
              onTap: () {
                _showPlaceDetails(place);
              },
            ),
          ),
        );
      }
    }

    return markers;
  }

  Set<Circle> _buildCircles() {
    final Set<Circle> circles = {};

    if (_selectedLocation != null && _hasSearched) {
      circles.add(
        Circle(
          circleId: const CircleId('search_radius'),
          center: _selectedLocation!,
          radius: (_selectedRadius * 1000).toDouble(),
          fillColor: _AppColors.brand500.withOpacity(0.08),
          strokeColor: _AppColors.brand500.withOpacity(0.5),
          strokeWidth: 2,
        ),
      );
    }

    return circles;
  }

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  Future<void> _pickMarketingImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return;
      if (!mounted) return;

      setState(() {
        _selectedMarketingImage = image;
      });

      _showSnackBar('Image selected successfully');
    } catch (e) {
      _showSnackBar('Could not select image: $e', isError: true);
    }
  }

  void _removeMarketingImage() {
    setState(() {
      _selectedMarketingImage = null;
    });
  }

  // ============================================================
  // WHATSAPP MARKETING
  // ============================================================

  Future<void> _openWhatsApp(
      String phoneNumber,
      String placeName,
      ) async {
    final cleanNumber = _cleanPhoneNumber(phoneNumber);
    final message = _marketingMessageController.text.trim();

    if (message.isEmpty) {
      _showSnackBar('Please enter marketing message', isError: true);
      return;
    }

    try {
      if (_selectedMarketingImage != null) {
        await _shareMarketingMessageWithImage(message);
      } else {
        await _openWhatsAppWithText(cleanNumber, message);
      }
    } catch (e) {
      _showSnackBar('Could not open WhatsApp: $e', isError: true);
    }
  }

  String _cleanPhoneNumber(String phoneNumber) {
    var cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (cleanNumber.startsWith('0')) {
      cleanNumber = cleanNumber.substring(1);
    }

    if (!cleanNumber.startsWith('91') && cleanNumber.length == 10) {
      cleanNumber = '91$cleanNumber';
    }

    return cleanNumber;
  }

  Future<void> _openWhatsAppWithText(
      String phoneNumber,
      String message,
      ) async {
    final encodedMessage = Uri.encodeComponent(message);
    final url = 'https://wa.me/$phoneNumber?text=$encodedMessage';
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        if (kIsWeb) {
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
            webOnlyWindowName: '_blank',
          );
        } else {
          bool launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );

          if (!launched) {
            final String alternativeUrl;
            if (Platform.isAndroid) {
              alternativeUrl =
              'https://api.whatsapp.com/send?phone=$phoneNumber&text=$encodedMessage';
            } else if (Platform.isIOS) {
              alternativeUrl =
              'https://api.whatsapp.com/send?phone=$phoneNumber&text=$encodedMessage';
            } else {
              alternativeUrl = url;
            }

            final altUri = Uri.parse(alternativeUrl);
            await launchUrl(altUri, mode: LaunchMode.externalApplication);
          }
        }
      } else {
        final webUrl =
            'https://web.whatsapp.com/send?phone=$phoneNumber&text=$encodedMessage';
        final webUri = Uri.parse(webUrl);
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _showSnackBar('Could not open WhatsApp: ${e.toString()}', isError: true);
    }
  }

  Future<void> _shareMarketingMessageWithImage(String message) async {
    if (_selectedMarketingImage == null) {
      return;
    }

    await Share.shareXFiles(
      [_selectedMarketingImage!],
      text: message,
      subject: 'QNX MART Business Promotion',
    );
  }

  // ============================================================
  // PLACE DETAILS POPUP
  // ============================================================

  void _showPlaceDetails(place_model.PlaceResult place) {
    setState(() {
      _isPopupOpen = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 650,
              maxHeight: 700,
            ),
            decoration: BoxDecoration(
              color: _isDarkMode ? _AppColors.slate800 : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        place.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (place.photos != null && place.photos!.isNotEmpty) ...[
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: place.photos!.length,
                            itemBuilder: (context, index) {
                              final photo = place.photos![index];
                              return Container(
                                width: 300,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Colors.grey[300],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    photo.photoReference,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _detailRow(
                        Icons.location_on,
                        'Address',
                        place.displayAddress,
                      ),
                      const SizedBox(height: 12),
                      if (place.internationalPhoneNumber != null)
                        _detailRow(
                          Icons.phone,
                          'Phone',
                          place.internationalPhoneNumber!,
                        ),
                      if (place.internationalPhoneNumber != null)
                        const SizedBox(height: 12),
                      if (place.rating != null)
                        _detailRow(
                          Icons.star,
                          'Rating',
                          '${place.rating!.toStringAsFixed(1)} '
                              '(${place.userRatingsTotal ?? 0} reviews)',
                        ),
                      if (place.rating != null) const SizedBox(height: 12),
                      if (place.types.isNotEmpty)
                        _detailRow(
                          Icons.category,
                          'Category',
                          place.types.join(', '),
                        ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          if (place.internationalPhoneNumber != null)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  _closePopupAndOpenWhatsApp(
                                      dialogContext, place);
                                },
                                icon: const Icon(Icons.message),
                                label: const Text('WhatsApp'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _AppColors.whatsapp500,
                                  foregroundColor: Colors.white,
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          if (place.internationalPhoneNumber != null)
                            const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _closePopupAndOpenMaps(dialogContext, place);
                              },
                              icon: const Icon(Icons.map),
                              label: const Text('View on Map'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _AppColors.brand600,
                                foregroundColor: Colors.white,
                                padding:
                                const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        Navigator.pop(dialogContext);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _AppColors.red500.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: _AppColors.red500,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          setState(() {
            _isPopupOpen = false;
          });
        }
      });
    });
  }

  void _closePopupAndOpenWhatsApp(
      BuildContext dialogContext,
      place_model.PlaceResult place,
      ) {
    Navigator.pop(dialogContext);

    Future.delayed(const Duration(milliseconds: 100), () {
      _openWhatsApp(
        place.internationalPhoneNumber!,
        place.name,
      );
    });
  }

  void _closePopupAndOpenMaps(
      BuildContext dialogContext,
      place_model.PlaceResult place,
      ) {
    Navigator.pop(dialogContext);

    Future.delayed(const Duration(milliseconds: 100), () {
      _openInGoogleMaps(
        place.geometry.location.lat,
        place.geometry.location.lng,
        place.name,
      );
    });
  }

  // ============================================================
  // GOOGLE MAPS
  // ============================================================

  Future<void> _openInGoogleMaps(
      double lat,
      double lng,
      String placeName,
      ) async {
    final googleMapsUrl = 'geo:$lat,$lng?q=$lat,$lng($placeName)';
    final webUrl =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

    try {
      final geoUri = Uri.parse(googleMapsUrl);
      final webUri = Uri.parse(webUrl);

      if (await canLaunchUrl(geoUri)) {
        await launchUrl(
          geoUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      _showSnackBar('Could not open Google Maps: $e', isError: true);
    }
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

  void _showSnackBar(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _AppColors.red500 : _AppColors.whatsapp600,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: _AppColors.brand600,
          size: 21,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode
                      ? _AppColors.slate400
                      : _AppColors.slate500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: _isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;

    if (!_isAuthorized) {
      return Scaffold(
        backgroundColor: _isDarkMode ? _AppColors.slate900 : _AppColors.slate50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.block,
                size: 80,
                color: _AppColors.red500,
              ),
              const SizedBox(height: 20),
              Text(
                'Unauthorized Access',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode ? Colors.white : _AppColors.slate900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Role: $_userRole',
                style: TextStyle(
                  fontSize: 16,
                  color: _isDarkMode ? _AppColors.slate400 : _AppColors.slate600,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _AppColors.brand600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _isDarkMode ? _AppColors.slate900 : _AppColors.slate100,
      appBar: _buildAppBar(),
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  // ============================================================
  // APP BAR (matching HTML top header)
  // ============================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _isDarkMode ? _AppColors.slate800 : Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withOpacity(0.05),
      titleSpacing: 16,
      title: Row(
        children: [
          // Brand Logo
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_AppColors.brand600, _AppColors.violet500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'Q',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Brand text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'QNX',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: _isDarkMode ? Colors.white : _AppColors.slate900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const TextSpan(
                      text: 'MART',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: _AppColors.brand600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // Prospector Pro badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _AppColors.brand50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: _AppColors.brand100,
                width: 0.8,
              ),
            ),
            child: const Text(
              'PROSPECTOR PRO',
              style: TextStyle(
                color: _AppColors.brand700,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Active blast chip (hidden on small)
        if (MediaQuery.of(context).size.width > 1000)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _AppColors.emerald50,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _AppColors.emerald200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: _AppColors.emerald500,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Active Blast: ',
                  style: TextStyle(
                    fontSize: 11,
                    color: _AppColors.emerald800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Text(
                  'Satara Furniture Outreach',
                  style: TextStyle(
                    fontSize: 11,
                    color: _AppColors.emerald800,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '· 56 queued',
                  style: TextStyle(
                    fontSize: 11,
                    color: _AppColors.emerald600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(width: 8),
        // Credits pill
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _AppColors.amber50,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _AppColors.amber200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bolt,
                size: 14,
                color: _AppColors.amber600,
              ),
              const SizedBox(width: 4),
              Text(
                '1,240',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _AppColors.amber800,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                'credits',
                style: TextStyle(
                  fontSize: 10,
                  color: _AppColors.amber700,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 4),
        // Dark mode toggle
        IconButton(
          icon: Icon(
            _isDarkMode ? Icons.light_mode : Icons.dark_mode,
            size: 18,
            color: _AppColors.slate500,
          ),
          onPressed: () {
            setState(() {
              _isDarkMode = !_isDarkMode;
            });
          },
          tooltip: 'Toggle theme',
        ),
        // Notification bell
        IconButton(
          icon: Stack(
            children: [
              const Icon(
                Icons.notifications_outlined,
                size: 18,
                color: _AppColors.slate500,
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: _AppColors.brand600,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          onPressed: () {},
          tooltip: 'Notifications',
        ),
        // Divider
        Container(
          width: 1,
          height: 16,
          color: _AppColors.slate200,
          margin: const EdgeInsets.symmetric(horizontal: 4),
        ),
        // User profile
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), _AppColors.brand600],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: _AppColors.brand100, width: 2),
                ),
                child: const Center(
                  child: Text(
                    'AP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (MediaQuery.of(context).size.width > 600) ...[
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Aniket Patel',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _isDarkMode
                            ? Colors.white
                            : _AppColors.slate800,
                      ),
                    ),
                    Text(
                      'Satara Hub (HQ)',
                      style: TextStyle(
                        fontSize: 9,
                        color: _AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        // Logout
        IconButton(
          icon: const Icon(
            Icons.logout,
            size: 18,
            color: _AppColors.red500,
          ),
          onPressed: _logout,
          tooltip: 'Logout',
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  // ============================================================
  // DESKTOP LAYOUT (split panel — left controls, right map)
  // ============================================================

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left Control Panel (48% / 46%)
        Expanded(
          flex: 46,
          child: Container(
            color: _isDarkMode ? _AppColors.slate800 : Colors.white,
            child: Column(
              children: [
                _buildSearchBar(),
                _buildMarketingBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : !_hasSearched
                      ? _buildBlankState()
                      : _currentPagePlaces.isEmpty
                      ? _buildEmptyState()
                      : _buildResultsTable(),
                ),
              ],
            ),
          ),
        ),
        // Right Map Canvas
        Expanded(
          flex: 54,
          child: _buildMap(),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE LAYOUT
  // ============================================================

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        children: [
          _buildSearchBar(),
          _buildMarketingBar(),
          SizedBox(
            height: 320,
            child: _buildMap(),
          ),
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isDarkMode ? _AppColors.slate800 : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildMobileContentArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileContentArea() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (!_hasSearched) {
      return SizedBox(
        height: 260,
        child: _buildBlankState(),
      );
    } else if (_currentPagePlaces.isEmpty) {
      return SizedBox(
        height: 200,
        child: _buildEmptyState(),
      );
    } else {
      return _buildResultsTable(shrinkWrapMode: true);
    }
  }

  // ============================================================
  // MAP WIDGET
  // ============================================================

  Widget _buildMap() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isDarkMode ? _AppColors.slate700 : _AppColors.slate200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            IgnorePointer(
              ignoring: _isPopupOpen,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _currentLocation,
                  zoom: SupportConstants.defaultZoom.toDouble(),
                ),
                onTap: _onMapTap,
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                zoomControlsEnabled: true,
                mapType: MapType.normal,
                markers: _buildMarkers(),
                circles: _buildCircles(),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            // Re-scan floating button (top-left)
            Positioned(
              top: 12,
              left: 12,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: _onSearch,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: _AppColors.slate200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.refresh,
                          size: 14,
                          color: _AppColors.brand600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Re-scan visible map area',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _AppColors.slate700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Metrics ribbon (top-right)
            Positioned(
              top: 12,
              right: 12,
              child: Row(
                children: [
                  // Metrics ribbon (hidden on small)
                  if (MediaQuery.of(context).size.width > 1100)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _AppColors.slate200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          _mapMetric('SCANNED', '56 Leads',
                              _AppColors.slate800),
                          Container(
                            width: 1,
                            height: 24,
                            color: _AppColors.slate200,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          _mapMetric('WA DELIVERY', '98.4%',
                              _AppColors.emerald600),
                          Container(
                            width: 1,
                            height: 24,
                            color: _AppColors.slate200,
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          _mapMetric('EST. REPLY RATE', '~24.8%',
                              _AppColors.brand600),
                        ],
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Layer switcher
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _AppColors.slate200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _mapLayerButton('Street', true),
                        _mapLayerButton('Satellite', false),
                        _mapLayerButton('Heatmap', false),
                      ],
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

  Widget _mapMetric(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: _AppColors.slate400,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _mapLayerButton(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? _AppColors.brand50 : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          color: isActive ? _AppColors.brand700 : _AppColors.slate600,
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH BAR (matching HTML)
  // ============================================================

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: _isDarkMode ? _AppColors.slate800 : _AppColors.slate50.withOpacity(0.7),
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode ? _AppColors.slate700 : _AppColors.slate200,
          ),
        ),
      ),
      child: Column(
        children: [
          // Row 1: Search input + radius dropdown + scan + add
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    color: _isDarkMode ? _AppColors.slate700 : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _isDarkMode
                          ? _AppColors.slate600
                          : _AppColors.slate300,
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onSubmitted: (_) => _onSearch(),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _isDarkMode ? Colors.white : _AppColors.slate900,
                    ),
                    decoration: InputDecoration(
                      hintText:
                      'Search category or company (e.g. furniture, hardware)',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        color: _AppColors.slate400,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        size: 16,
                        color: _AppColors.slate400,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 14,
                          color: _AppColors.slate400,
                        ),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                            _hasSearched = false;
                            _clearPlacesData();
                          });
                        },
                      )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Radius dropdown
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: _isDarkMode ? _AppColors.slate700 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isDarkMode
                        ? _AppColors.slate600
                        : _AppColors.slate300,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedRadius,
                    isDense: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 16,
                      color: _AppColors.slate500,
                    ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isDarkMode
                          ? Colors.white
                          : _AppColors.slate700,
                    ),
                    items: _radiusOptions
                        .map(
                          (radius) => DropdownMenuItem<int>(
                        value: radius,
                        child: Text('$radius km radius'),
                      ),
                    )
                        .toList(),
                    onChanged: _onRadiusChanged,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Scan button
              Container(
                height: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_AppColors.brand600, _AppColors.brand700],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: _AppColors.brand600.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _onSearch,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.search,
                            size: 15,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Scan',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Add button (Create New)
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_AppColors.emerald500, _AppColors.brand500],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                          const CreateBuilderPropertyScreen(),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2: Location + filters
          Row(
            children: [
              Text(
                'Location:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _AppColors.slate500,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _AppColors.slate200.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on,
                      size: 12,
                      color: _AppColors.red500,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _locationName.isEmpty
                          ? 'Fetching...'
                          : _locationName,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _AppColors.slate800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Verified WhatsApp toggle
              Row(
                children: [
                  SizedBox(
                    height: 16,
                    width: 16,
                    child: Checkbox(
                      value: true,
                      onChanged: (v) {},
                      materialTapTargetSize:
                      MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      activeColor: _AppColors.brand600,
                      side: BorderSide(
                        color: _AppColors.slate300,
                        width: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Verified WhatsApp Only',
                    style: TextStyle(
                      fontSize: 11,
                      color: _AppColors.slate600,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Text(
                '|',
                style: TextStyle(color: _AppColors.slate300),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                    _clearPlacesData();
                  });
                },
                child: const Text(
                  'Clear Filters',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _AppColors.brand600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MARKETING MESSAGE BAR (matching HTML)
  // ============================================================

  Widget _buildMarketingBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkMode
              ? [_AppColors.slate800, _AppColors.slate800]
              : [Colors.white, _AppColors.slate50.withOpacity(0.5)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode ? _AppColors.slate700 : _AppColors.slate200,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: _AppColors.whatsapp500,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat,
                  size: 12,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'WhatsApp Marketing Template',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _isDarkMode ? Colors.white : _AppColors.slate800,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _AppColors.emerald100,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Ready to Send',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: _AppColors.emerald800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Saved Templates',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _AppColors.slate500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Message box
          Container(
            decoration: BoxDecoration(
              color: _isDarkMode ? _AppColors.slate700 : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isDarkMode
                    ? _AppColors.slate600
                    : _AppColors.slate300,
              ),
            ),
            child: Column(
              children: [
                // Variable chips
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: _isDarkMode
                            ? _AppColors.slate600
                            : _AppColors.slate100,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Insert:',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _AppColors.slate400,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _variableChip('{Company_Name}'),
                      const SizedBox(width: 4),
                      _variableChip('{Location}'),
                      const SizedBox(width: 4),
                      _variableChip('{Category}'),
                      const SizedBox(width: 4),
                      _emojiChip(),
                    ],
                  ),
                ),
                // Textarea
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextField(
                    controller: _marketingMessageController,
                    maxLines: 3,
                    style: TextStyle(
                      fontSize: 11,
                      color:
                      _isDarkMode ? Colors.white : _AppColors.slate800,
                      height: 1.5,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Type your WhatsApp message...',
                      hintStyle: TextStyle(
                        fontSize: 11,
                        color: _AppColors.slate400,
                      ),
                    ),
                  ),
                ),
                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: _isDarkMode
                            ? _AppColors.slate600
                            : _AppColors.slate100,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Media attachment
                      if (_selectedMarketingImage != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _AppColors.slate100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.image,
                                size: 14,
                                color: _AppColors.brand600,
                              ),
                              const SizedBox(width: 4),
                              ConstrainedBox(
                                constraints:
                                const BoxConstraints(maxWidth: 120),
                                child: Text(
                                  _selectedMarketingImage!.name,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _AppColors.slate700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: _removeMarketingImage,
                          child: Text(
                            'Remove',
                            style: TextStyle(
                              fontSize: 10,
                              color: _AppColors.slate400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ] else
                        GestureDetector(
                          onTap: _pickMarketingImage,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.attach_file,
                                size: 14,
                                color: _AppColors.slate500,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Attach Image',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _AppColors.slate500,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Spacer(),
                      Text(
                        '${_marketingMessageController.text.length} / 1024 chars',
                        style: TextStyle(
                          fontSize: 10,
                          color: _AppColors.slate400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Action row: Export CSV, Select All, Launch Bulk Blast
          Row(
            children: [
              // Export CSV
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _isDarkMode ? _AppColors.slate700 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isDarkMode
                        ? _AppColors.slate600
                        : _AppColors.slate300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.download,
                      size: 13,
                      color: _AppColors.slate500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Export CSV',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _isDarkMode
                            ? Colors.white
                            : _AppColors.slate700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Select All
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _isDarkMode ? _AppColors.slate700 : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isDarkMode
                        ? _AppColors.slate600
                        : _AppColors.slate300,
                  ),
                ),
                child: Text(
                  'Select All (56)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isDarkMode ? Colors.white : _AppColors.slate700,
                  ),
                ),
              ),
              const Spacer(),
              // Launch Bulk Blast
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _AppColors.whatsapp600,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: _AppColors.whatsapp600.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.send,
                      size: 13,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Launch Bulk Blast (56)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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

  Widget _variableChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _AppColors.slate100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
          color: _AppColors.slate700,
        ),
      ),
    );
  }

  Widget _emojiChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _AppColors.amber50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        '✨ Emoji',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          fontFamily: 'monospace',
          color: _AppColors.amber700,
        ),
      ),
    );
  }

  // ============================================================
  // BLANK STATE
  // ============================================================

  Widget _buildBlankState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: _isDarkMode ? _AppColors.slate600 : _AppColors.slate300,
          ),
          const SizedBox(height: 16),
          Text(
            'Search for companies',
            style: TextStyle(
              color: _isDarkMode ? _AppColors.slate400 : _AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 48,
            color: _isDarkMode ? _AppColors.slate600 : _AppColors.slate400,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'No places found. Try different keywords.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _isDarkMode ? _AppColors.slate400 : _AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESULTS TABLE (matching HTML)
  // ============================================================

  Widget _buildResultsTable({bool shrinkWrapMode = false}) {
    // Header
    final header = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: _isDarkMode
          ? _AppColors.slate700.withOpacity(0.95)
          : _AppColors.slate100.withOpacity(0.95),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: true,
              onChanged: (v) {},
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              activeColor: _AppColors.brand600,
              side: BorderSide(
                color: _AppColors.slate300,
                width: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Columns
          Expanded(
            flex: 3,
            child: Text(
              'BUSINESS & CATEGORY',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _isDarkMode ? _AppColors.slate400 : _AppColors.slate600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'LOCATION & AREA',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _isDarkMode ? _AppColors.slate400 : _AppColors.slate600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'PHONE / CONTACT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _isDarkMode ? _AppColors.slate400 : _AppColors.slate600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'QUICK ACTION',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _isDarkMode ? _AppColors.slate400 : _AppColors.slate600,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );

    final list = ListView.builder(
      shrinkWrap: shrinkWrapMode,
      physics: shrinkWrapMode
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount: _currentPagePlaces.length,
      itemBuilder: (context, index) {
        final place = _currentPagePlaces[index];
        return _buildLeadRow(place);
      },
    );

    // Footer
    final footer = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: _isDarkMode ? _AppColors.slate700 : _AppColors.slate50,
      child: Row(
        children: [
          // Loaded count + Load All
          Row(
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Loaded: ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _AppColors.slate500,
                      ),
                    ),
                    TextSpan(
                      text: '${_allPlaces.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _isDarkMode
                            ? Colors.white
                            : _AppColors.slate900,
                      ),
                    ),
                    TextSpan(
                      text: ' companies',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 1,
                height: 12,
                color: _AppColors.slate300,
              ),
              const SizedBox(width: 10),
              Text(
                '52 WhatsApp Validated',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _AppColors.emerald700,
                ),
              ),
              const SizedBox(width: 10),
              if (_allPlaces.isNotEmpty &&
                  (_hasNextPage || _pagesCache.length > 1))
                GestureDetector(
                  onTap: (_isLoading || _isFetchingPage) ? null : _loadAllPages,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _AppColors.brand600.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: (_isLoading || _isFetchingPage)
                        ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Text(
                      'Load All',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _AppColors.brand600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          // Pagination
          Row(
            children: [
              _paginationIcon(
                Icons.first_page,
                onPressed:
                _currentPage > 0 ? () => _goToPage(0) : null,
              ),
              _paginationIcon(
                Icons.chevron_left,
                onPressed:
                _currentPage > 0 ? _fetchPrevPage : null,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _isFetchingPage
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(
                  '${_currentPage + 1} / ${_pagesCache.length}${_hasNextPage ? '+' : ''}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isDarkMode
                        ? Colors.white
                        : _AppColors.slate800,
                  ),
                ),
              ),
              _paginationIcon(
                Icons.chevron_right,
                onPressed: (_currentPage + 1 < _pagesCache.length ||
                    _hasNextPage)
                    ? _fetchNextPage
                    : null,
              ),
              _paginationIcon(
                Icons.last_page,
                onPressed: _currentPage < _pagesCache.length - 1
                    ? () => _goToPage(_pagesCache.length - 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );

    if (shrinkWrapMode) {
      return Column(
        children: [
          header,
          list,
          footer,
        ],
      );
    }

    return Column(
      children: [
        header,
        Expanded(child: list),
        footer,
      ],
    );
  }

  Widget _paginationIcon(IconData icon, {VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Icon(
          icon,
          size: 18,
          color: onPressed == null
              ? _AppColors.slate300
              : _AppColors.slate600,
        ),
      ),
    );
  }

  // ============================================================
  // LEAD ROW
  // ============================================================

  Widget _buildLeadRow(place_model.PlaceResult place) {
    final isFirst = _currentPagePlaces.isNotEmpty &&
        _currentPagePlaces.first.placeId == place.placeId;

    final hasPhone = place.internationalPhoneNumber != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isFirst
            ? _AppColors.brand50.withOpacity(0.4)
            : (_isDarkMode ? _AppColors.slate800 : Colors.white),
        border: Border(
          bottom: BorderSide(
            color: _isDarkMode ? _AppColors.slate700 : _AppColors.slate200,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Checkbox
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: isFirst || hasPhone,
              onChanged: (v) {},
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              activeColor: _AppColors.brand600,
              side: BorderSide(
                color: _AppColors.slate300,
                width: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Business & Category
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        place.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isFirst
                              ? _AppColors.brand600
                              : (_isDarkMode
                              ? Colors.white
                              : _AppColors.slate900),
                        ),
                      ),
                    ),
                    if (isFirst) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _AppColors.brand100,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'HOT',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: _AppColors.brand700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    if (place.rating != null) ...[
                      Text(
                        '${place.rating!.toStringAsFixed(1)} ★',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _AppColors.amber500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${place.userRatingsTotal ?? 0} reviews)',
                        style: TextStyle(
                          fontSize: 10,
                          color: _AppColors.slate500,
                        ),
                      ),
                      Container(
                        width: 3,
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: _AppColors.slate300,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    Flexible(
                      child: Text(
                        place.types.isNotEmpty
                            ? place.types.first
                            : 'Business',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: _AppColors.slate500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Location & Area
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.displayAddress,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: _isDarkMode
                        ? _AppColors.slate200
                        : _AppColors.slate800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _distanceLabel(place),
                  style: TextStyle(
                    fontSize: 10,
                    color: _AppColors.slate400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // Phone / Contact
          Expanded(
            flex: 2,
            child: hasPhone
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        place.internationalPhoneNumber!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                          color: _isDarkMode
                              ? Colors.white
                              : _AppColors.slate700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.verified,
                      size: 12,
                      color: _AppColors.emerald600,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'WhatsApp Active',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: _AppColors.emerald600,
                  ),
                ),
              ],
            )
                : Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? _AppColors.slate700
                    : _AppColors.slate100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'N/A (Unverified)',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: _AppColors.slate500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Quick Action
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Info button
                InkWell(
                  onTap: () => _showPlaceDetails(place),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: _AppColors.slate500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Send button
                if (hasPhone)
                  GestureDetector(
                    onTap: () => _openWhatsApp(
                      place.internationalPhoneNumber!,
                      place.name,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _AppColors.whatsapp500,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: _AppColors.whatsapp500.withOpacity(0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.chat,
                            size: 11,
                            color: Colors.white,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'Send',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _AppColors.slate200,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'No Phone',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _AppColors.slate400,
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

  String _distanceLabel(place_model.PlaceResult place) {
    if (_selectedLocation == null) return '—';
    final lat1 = _selectedLocation!.latitude;
    final lng1 = _selectedLocation!.longitude;
    final lat2 = place.geometry.location.lat;
    final lng2 = place.geometry.location.lng;

    // Approximate distance in km
    final dLat = (lat2 - lat1).abs();
    final dLng = (lng2 - lng1).abs();
    final km = ((dLat * dLat + dLng * dLng) * 111 * 111).toDouble();
    final dist = (km > 0) ? (km * 1000).round() / 1000 : 0;
    if (dist < 1) {
      return '${(dist * 1000).round()} m from center';
    }
    return '${dist.toStringAsFixed(1)} km from center';
  }
}
*/

// lib/screens/support/support_dashboard.dart

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io' show Platform;
import '../../models/map/place_model.dart' as place_model;
import '../../api/place_service.dart';
import '../../screens/qnx_admin/login_screen.dart';
import '../marketing_head/marketing_head_dashboard.dart';
import '../marketing_partner/marketing_partner_dashboard.dart';
import '../qnx_admin/dashboard.dart';
import '../real_estate/create_builder_screen.dart';
import '../real_estate/create_property_screen.dart';
import '../real_estate/create_builder_property_screen.dart';

// ============================================================
// CONSTANTS
// ============================================================

class SupportConstants {
  static const String appName = 'QNX Mart Support';

  static const double defaultLatitude = 18.5204;
  static const double defaultLongitude = 73.8567;

  static const int defaultZoom = 14;

  static const String defaultMarketingMessage = '''
🚀 Grow Your Business with QNX MART!

Why pay ₹1–2 Lakh every month on expensive marketing?

Promote your business with QNX MART for just ₹1,000 – ₹5,000 (Lifetime Access)!

✨ Key Benefits for Your Business:

✅ Register Your Company & Add Owner Details

✅ Upload Unlimited Products

✅ Connect with Suppliers & Dealers

✅ Reach Thousands of Customers & Boost Sales

📞 Need Help or Have Questions?

Call (Toll-Free): (+91) 9226859922

Email: quivonexsolutions@gmail.com

👇 Check out the banner attached above for details!

👉 Register Your Company Today & Start Growing!

https://drive.google.com/file/d/1G-ZcYwMXEqbDuEFBZPkFVBRa85JJp9vl/view?usp=drive_link

https://qnxmartb2b.com/info-company

use referrel link to register your company = https://qnxmartb2b.com/company_create?ref=MPJJG9N8F2

''';

}

// ============================================================
// SUPPORT DASHBOARD
// ============================================================

class SupportDashboard extends StatefulWidget {
  const SupportDashboard({super.key});

  @override
  State<SupportDashboard> createState() => _SupportDashboardState();
}

class _SupportDashboardState extends State<SupportDashboard>
    with WidgetsBindingObserver {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController _searchController =
  TextEditingController();

  final TextEditingController _marketingMessageController =
  TextEditingController(
    text: SupportConstants.defaultMarketingMessage,
  );

  // ============================================================
  // SERVICES
  // ============================================================

  final PlaceService _placeService = PlaceService();

  final ImagePicker _imagePicker = ImagePicker();

  // ============================================================
  // UI STATE
  // ============================================================
  bool _isPopupOpen = false;
  bool _isDarkMode = false;
  bool _isLoading = false;
  bool _isPinSet = false;
  bool _isAuthorized = false;
  bool _isMapReady = false;
  bool _hasSearched = false;
  bool _isGettingLocationName = false;
  bool get _mapInteractionEnabled => !_isPopupOpen;
  String _userRole = '';

  // ============================================================
  // SEARCH & LOCATION
  // ============================================================

  String _searchQuery = '';

  int _selectedRadius = 10;

  final List<int> _radiusOptions = [
    5,
    10,
    15,
    20,
    25,
    30,
    40,
    50,
  ];

  String _locationName = '';

  // ============================================================
  // MAP
  // ============================================================

  GoogleMapController? _mapController;

  LatLng _currentLocation = const LatLng(
    SupportConstants.defaultLatitude,
    SupportConstants.defaultLongitude,
  );

  LatLng? _selectedLocation;

  // ============================================================
  // PLACES DATA
  // ============================================================

  List<place_model.PlaceResult> _allPlaces = [];

  List<place_model.PlaceResult> _filteredPlaces = [];

  List<place_model.PlaceResult> _currentPagePlaces = [];

  String? _errorMessage;

  // ============================================================
  // PAGINATION
  // ------------------------------------------------------------
  // Google Places Nearby Search returns a fixed batch (~20 results)
  // per call, plus an optional `next_page_token` for the next batch.
  // There is no way to request "all results at once" from the API,
  // so pagination here works like this:
  //   - Every fetched batch is cached (in order) in `_pagesCache`.
  //   - "Next" moves to the next cached page instantly if we already
  //     have it, otherwise it fetches a new batch using the token.
  //   - "Previous"/"First" always uses the cache — no re-fetch needed.
  //   - "Load All" walks through every remaining page (respecting the
  //     ~2s delay Google requires before a page token becomes valid)
  //     and merges everything into one page.
  // ============================================================

  int _currentPage = 0;

  final List<List<place_model.PlaceResult>> _pagesCache = [];

  String? _nextPageToken;

  bool _isFetchingPage = false;

  bool _hasNextPage = false;

  // ============================================================
  // IMAGE
  // ============================================================

  XFile? _selectedMarketingImage;

  // ============================================================
  // LIFECYCLE
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _checkUserRoleAndLocation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _searchController.dispose();

    _marketingMessageController.dispose();

    _mapController?.dispose();

    _placeService.dispose();

    super.dispose();
  }

  // ============================================================
  // APP LIFECYCLE
  // ============================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  // ============================================================
  // AUTHENTICATION & LOCATION
  // ============================================================

  Future<void> _checkUserRoleAndLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final role = prefs.getString('user_role') ?? '';

      final roleLower = role.toLowerCase().trim();

      final isSupport =
          roleLower.contains('support') ||
              roleLower == 'support_agent' ||
              roleLower == 'support agent' ||
              roleLower == 'application support' ||
              roleLower.contains('application support');

      if (!mounted) return;

      setState(() {
        _userRole = role;

        _isAuthorized = isSupport;
      });

      if (isSupport) {
        await _getCurrentLocation();

        _updateMapLocation();
      } else {
        _redirectToDashboard(role);
      }
    } catch (e) {
      debugPrint(
        '❌ Error in _checkUserRoleAndLocation: $e',
      );

      if (!mounted) return;

      setState(() {
        _isAuthorized = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();

        if (!mounted) return;

        setState(() {
          _currentLocation = const LatLng(
            SupportConstants.defaultLatitude,
            SupportConstants.defaultLongitude,
          );

          _selectedLocation = _currentLocation;

          _isPinSet = true;
        });

        await _getLocationName(_currentLocation);

        return;
      }

      LocationPermission permission =
      await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          _setDefaultLocation();

          await _getLocationName(_currentLocation);

          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setDefaultLocation();

        await _getLocationName(_currentLocation);

        return;
      }

      final position =
      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;

      setState(() {
        _currentLocation = LatLng(
          position.latitude,
          position.longitude,
        );

        _selectedLocation = _currentLocation;

        _isPinSet = true;
      });

      await _getLocationName(_currentLocation);

      _updateMapLocation();
    } catch (e) {
      debugPrint(
        '❌ Error getting location: $e',
      );

      _setDefaultLocation();

      await _getLocationName(_currentLocation);
    }
  }

  void _setDefaultLocation() {
    if (!mounted) return;

    setState(() {
      _currentLocation = const LatLng(
        SupportConstants.defaultLatitude,
        SupportConstants.defaultLongitude,
      );

      _selectedLocation = _currentLocation;

      _isPinSet = true;
    });
  }

  void _updateMapLocation() {
    if (_mapController != null && _isMapReady) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _currentLocation,
            zoom: SupportConstants.defaultZoom.toDouble(),
          ),
        ),
      );
    }
  }

  Future<void> _getLocationName(LatLng location) async {
    if (_isGettingLocationName) return;

    if (!mounted) return;

    setState(() {
      _isGettingLocationName = true;

      _locationName = 'Fetching...';
    });

    try {
      final response =
      await _placeService.getLocationName(
        lat: location.latitude,
        lng: location.longitude,
      );

      if (!mounted) return;

      setState(() {
        if (response != null &&
            response.isNotEmpty &&
            !response.contains('Unknown') &&
            !response.contains('Unable') &&
            !response.contains('null')) {
          _locationName = response;
        } else {
          _locationName =
              _formatCoordinates(location);
        }

        _isGettingLocationName = false;
      });
    } catch (e) {
      debugPrint(
        '❌ Error getting location name: $e',
      );

      if (!mounted) return;

      setState(() {
        _locationName =
            _formatCoordinates(location);

        _isGettingLocationName = false;
      });
    }
  }

  String _formatCoordinates(LatLng location) {
    final lat =
    location.latitude.toStringAsFixed(4);

    final lng =
    location.longitude.toStringAsFixed(4);

    return '$lat, $lng';
  }

  void _redirectToDashboard(String role) {
    if (!mounted) return;

    final roleLower = role.toLowerCase().trim();

    Widget dashboard;

    if (roleLower.contains('admin') ||
        roleLower.contains('qnx admin')) {
      dashboard = const DashboardScreen();
    } else if (roleLower.contains('marketing head') ||
        roleLower.contains('marketing_head')) {
      dashboard = const MarketingHeadDashboard();
    } else if (roleLower.contains('marketing partner') ||
        roleLower.contains('marketing_partner')) {
      dashboard = const MarketingPartnerDashboard();
    }
    else {
      dashboard = const LoginScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => dashboard,
      ),
    );
  }

  Future<void> _logout() async {
    final prefs =
    await SharedPreferences.getInstance();

    await prefs.clear();

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  // ============================================================
  // SEARCH
  // ============================================================

  /// Fetches exactly ONE batch/page from the API.
  ///
  /// - `pageToken == null`  -> this is a brand-new search: clears
  ///   everything and fetches page 1.
  /// - `pageToken != null`  -> fetches the next batch using the
  ///   token and appends it to the page cache.
  Future<void> _searchNearbyPlaces(
      LatLng location, {
        String? keyword,
        String? pageToken,
      }) async {
    if (!mounted) return;

    if (_isFetchingPage) return;

    final bool isFreshSearch = pageToken == null;

    setState(() {
      _isFetchingPage = true;

      if (isFreshSearch) {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 0;
        _hasSearched = true;
        _allPlaces = [];
        _filteredPlaces = [];
        _currentPagePlaces = [];
        _pagesCache.clear();
        _nextPageToken = null;
        _hasNextPage = false;
      }
    });

    try {
      final response = await _placeService.searchNearbyPlaces(
        lat: location.latitude,
        lng: location.longitude,
        radius: _selectedRadius * 1000,
        keyword: keyword,
        pageToken: pageToken,
      );

      if (!mounted) return;

      setState(() {
        _pagesCache.add(response.results);
        _allPlaces.addAll(response.results);
        _filteredPlaces = List.from(_allPlaces);

        // Jump straight to the page we just fetched
        _currentPage = _pagesCache.length - 1;
        _currentPagePlaces = _pagesCache[_currentPage];

        _nextPageToken = response.nextPageToken;
        _hasNextPage = _nextPageToken != null;

        _isLoading = false;
        _isFetchingPage = false;
        _isPinSet = true;
        _selectedLocation = location;
      });

      await _getLocationName(location);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isFetchingPage = false;
      });

      _showSnackBar(
        'Error: $e',
        isError: true,
      );
    }
  }

  /// Next page: instant if already cached, otherwise fetches a new
  /// batch (with the delay Google requires before a page token works).
  Future<void> _fetchNextPage() async {
    if (_isFetchingPage) return;

    // Already have this page cached — just switch, no API call needed.
    if (_currentPage + 1 < _pagesCache.length) {
      setState(() {
        _currentPage++;
        _currentPagePlaces = _pagesCache[_currentPage];
      });
      return;
    }

    if (!_hasNextPage || _nextPageToken == null) return;

    final location = _selectedLocation ?? _currentLocation;
    final keyword = _searchQuery.trim().isEmpty ? null : _searchQuery.trim();
    final tokenToUse = _nextPageToken;

    setState(() {
      _isFetchingPage = true;
    });

    // Google Places page tokens are not valid immediately — a short
    // delay is required, otherwise the API returns INVALID_REQUEST.
    await Future.delayed(const Duration(milliseconds: 2000));

    if (!mounted) return;

    setState(() {
      _isFetchingPage = false;
    });

    await _searchNearbyPlaces(
      location,
      keyword: keyword,
      pageToken: tokenToUse,
    );
  }

  /// Previous page: always cached already, so this is instant.
  void _fetchPrevPage() {
    if (_isFetchingPage) return;

    if (_currentPage <= 0) return;

    setState(() {
      _currentPage--;
      _currentPagePlaces = _pagesCache[_currentPage];
    });
  }

  /// Jump to a page we have already fetched (used by First/Last).
  void _goToPage(int pageIndex) {
    if (_isFetchingPage) return;

    if (pageIndex < 0 || pageIndex >= _pagesCache.length) return;

    if (pageIndex == _currentPage) return;

    setState(() {
      _currentPage = pageIndex;
      _currentPagePlaces = _pagesCache[_currentPage];
    });
  }

  /// Fetches every remaining page (one by one, respecting the token
  /// delay) and merges everything into a single page so the user can
  /// see/scroll through all results at once.
  Future<void> _loadAllPages() async {
    if (_isFetchingPage) return;

    final location = _selectedLocation ?? _currentLocation;
    final keyword = _searchQuery.trim().isEmpty ? null : _searchQuery.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      if (_pagesCache.isEmpty) {
        await _searchNearbyPlaces(location, keyword: keyword);
      }

      int safetyCounter = 0;

      while (_hasNextPage && _nextPageToken != null && safetyCounter < 10) {
        final tokenToUse = _nextPageToken;

        await Future.delayed(const Duration(milliseconds: 2000));

        if (!mounted) return;

        await _searchNearbyPlaces(
          location,
          keyword: keyword,
          pageToken: tokenToUse,
        );

        safetyCounter++;
      }

      if (!mounted) return;

      setState(() {
        final merged = <place_model.PlaceResult>[];
        for (final page in _pagesCache) {
          merged.addAll(page);
        }

        _pagesCache
          ..clear()
          ..add(merged);

        _currentPage = 0;
        _currentPagePlaces = merged;
        _allPlaces = merged;
        _filteredPlaces = List.from(merged);
        _isLoading = false;
      });

      _showSnackBar('Loaded ${_currentPagePlaces.length} places');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar('Error loading all pages: $e', isError: true);
    }
  }

  void _onSearch() {
    final location =
        _selectedLocation ?? _currentLocation;

    final keyword =
    _searchQuery.trim().isEmpty
        ? null
        : _searchQuery.trim();

    _searchNearbyPlaces(
      location,
      keyword: keyword,
    );
  }

  void _onRadiusChanged(int? newRadius) {
    if (newRadius == null) return;

    if (newRadius == _selectedRadius) {
      return;
    }

    setState(() {
      _selectedRadius = newRadius;
    });
  }

  // ============================================================
  // MAP
  // ============================================================

  void _onMapCreated(
      GoogleMapController controller,
      ) {
    _mapController = controller;

    _isMapReady = true;

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentLocation,
          zoom: SupportConstants.defaultZoom
              .toDouble(),
        ),
      ),
    );
  }

  // ✅ Map tap: popup open असताना काहीच होणार नाही.
  // Popup बंद असल्यास आणि जुना data (search results) असल्यास आधी
  // permission popup येईल - Yes केल्यास जुना data clear होऊन नवीन
  // location set होईल, No केल्यास काहीही बदलणार नाही (data as is).
  Future<void> _onMapTap(LatLng position) async {
    // ✅ Popup open असल्यास map tap पूर्णपणे ignore करा
    if (_isPopupOpen) {
      return;
    }

    // ✅ जुना data (search results) असेल तरच permission विचारा
    if (_hasSearched) {
      setState(() {
        _isPopupOpen = true;
      });

      final bool? shouldRemove = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.65),
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text(
              'Remove Previous Data?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Are you sure you want to remove previous data?\n\n'
                  'All search results will be cleared and the new location will be selected.',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  // ❌ NO - data clear करू नका, dialog नक्की बंद व्हावा
                  // म्हणून rootNavigator वापरतो
                  Navigator.of(dialogContext, rootNavigator: true)
                      .pop(false);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[700],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'No',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // ✅ YES - data clear करा
                  Navigator.of(dialogContext, rootNavigator: true)
                      .pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC3545),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Yes, Clear Data',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (shouldRemove != true) {
        // ❌ No selected - काहीही बदलू नका, data तसाच ठेवा.
        // थोडा grace delay देऊनच map परत click साठी enable करतो,
        // जेणेकरून याच tap चा उरलेला भाग परत map वर registered होणार नाही.
        await Future.delayed(const Duration(milliseconds: 350));

        if (mounted) {
          setState(() {
            _isPopupOpen = false;
          });
        }

        _showSnackBar(
          'Data kept as is',
          isError: false,
        );

        return;
      }

      // ✅ Yes selected - जुना data clear करा
      _clearPreviousData();

      if (mounted) {
        setState(() {
          _isPopupOpen = false;
        });
      }
    }

    // ✅ Location update करा
    setState(() {
      _selectedLocation = position;
      _isPinSet = true;
      _locationName = 'Fetching...';
    });

    // ✅ Map camera animate करा
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(position),
    );

    // ✅ Location name fetch करा
    await _getLocationName(position);
  }

  Future<void> _confirmRemoveData() async {
    // Popup open state set करा
    setState(() {
      _isPopupOpen = true;
    });

    // Permission popup दाखवा
    final bool? shouldRemove = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Remove Previous Data?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to remove previous data?\n\n'
                'All search results and selected location data will be cleared.',
            style: TextStyle(
              fontSize: 14,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // ❌ NO - data clear करू नका, dialog नक्की बंद व्हावा
                // म्हणून rootNavigator वापरतो
                Navigator.of(dialogContext, rootNavigator: true)
                    .pop(false);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'No',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // ✅ YES - data clear करा
                Navigator.of(dialogContext, rootNavigator: true)
                    .pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC3545),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Yes, Clear Data',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    // Popup close state update
    if (mounted) {
      setState(() {
        _isPopupOpen = false;
      });
    }

    // ✅ Yes selected तरच data clear करा
    if (shouldRemove == true) {
      _clearPreviousData();

      // User ला notification द्या
      _showSnackBar(
        'Data cleared successfully',
        isError: false,
      );
    } else {
      // ❌ No selected - data तसेच राहील
      _showSnackBar(
        'Data kept as is',
        isError: false,
      );
    }
  }

  void _clearPreviousData() {
    setState(() {
      _allPlaces = [];
      _filteredPlaces = [];
      _currentPagePlaces = [];
      _currentPage = 0;
      _hasSearched = false;
      _errorMessage = null;
      _pagesCache.clear();
      _nextPageToken = null;
      _hasNextPage = false;
      _isFetchingPage = false;
    });
  }

// ✅ हे method फक्त search results clear करण्यासाठी
  void _clearPlacesData() {
    if (!mounted) return;

    setState(() {
      _allPlaces = [];
      _filteredPlaces = [];
      _currentPagePlaces = [];
      _currentPage = 0;
      _hasSearched = false;
      _errorMessage = null;
      _pagesCache.clear();
      _nextPageToken = null;
      _hasNextPage = false;
      _isFetchingPage = false;
    });
  }

  Set<Marker> _buildMarkers() {
    final Set<Marker> markers = {};

    if (_selectedLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId(
            'selected_location',
          ),
          position: _selectedLocation!,
          icon:
          BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          infoWindow: const InfoWindow(
            title: '📍 Selected Location',
          ),
        ),
      );
    }

    if (_hasSearched) {
      for (final place
      in _currentPagePlaces) {
        markers.add(
          Marker(
            markerId: MarkerId(
              place.placeId,
            ),
            position: LatLng(
              place.geometry.location.lat,
              place.geometry.location.lng,
            ),
            icon: BitmapDescriptor
                .defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            infoWindow: InfoWindow(
              title: place.name,
              snippet: place.displayAddress,
              onTap: () {
                _showPlaceDetails(place);
              },
            ),
          ),
        );
      }
    }

    return markers;
  }

  Set<Circle> _buildCircles() {
    final Set<Circle> circles = {};

    if (_selectedLocation != null &&
        _hasSearched) {
      circles.add(
        Circle(
          circleId: const CircleId(
            'search_radius',
          ),
          center: _selectedLocation!,
          radius:
          (_selectedRadius * 1000)
              .toDouble(),
          fillColor:
          Colors.blue.withOpacity(0.1),
          strokeColor:
          Colors.blue.withOpacity(0.5),
          strokeWidth: 2,
        ),
      );
    }

    return circles;
  }

  // ============================================================
  // IMAGE PICKER
  // ============================================================

  Future<void> _pickMarketingImage() async {
    try {
      final image =
      await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return;

      if (!mounted) return;

      setState(() {
        _selectedMarketingImage = image;
      });

      _showSnackBar(
        'Image selected successfully',
      );
    } catch (e) {
      _showSnackBar(
        'Could not select image: $e',
        isError: true,
      );
    }
  }

  void _removeMarketingImage() {
    setState(() {
      _selectedMarketingImage = null;
    });
  }

  // ============================================================
  // WHATSAPP MARKETING
  // ============================================================

  Future<void> _openWhatsApp(
      String phoneNumber,
      String placeName,
      ) async {
    final cleanNumber = _cleanPhoneNumber(phoneNumber);
    final message = _marketingMessageController.text.trim();

    if (message.isEmpty) {
      _showSnackBar(
        'Please enter marketing message',
        isError: true,
      );
      return;
    }

    try {
      if (_selectedMarketingImage != null) {
        // If image is selected, share via share_plus
        await _shareMarketingMessageWithImage(message);
      } else {
        // If no image, open WhatsApp directly
        await _openWhatsAppWithText(cleanNumber, message);
      }
    } catch (e) {
      _showSnackBar(
        'Could not open WhatsApp: $e',
        isError: true,
      );
    }
  }

  String _cleanPhoneNumber(
      String phoneNumber,
      ) {
    var cleanNumber =
    phoneNumber.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    if (cleanNumber.startsWith('0')) {
      cleanNumber =
          cleanNumber.substring(1);
    }

    if (!cleanNumber.startsWith('91') &&
        cleanNumber.length == 10) {
      cleanNumber = '91$cleanNumber';
    }

    return cleanNumber;
  }

  Future<void> _openWhatsAppWithText(
      String phoneNumber,
      String message,
      ) async {
    final encodedMessage = Uri.encodeComponent(message);
    final url = 'https://wa.me/$phoneNumber?text=$encodedMessage';
    final uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        if (kIsWeb) {
          // Web - always open in new tab
          await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
            webOnlyWindowName: '_blank',
          );
        } else {
          // Mobile - try multiple approaches
          bool launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );

          // If externalApplication fails, try platform-specific URLs
          if (!launched) {
            final String alternativeUrl;
            if (Platform.isAndroid) {
              alternativeUrl = 'https://api.whatsapp.com/send?phone=$phoneNumber&text=$encodedMessage';
            } else if (Platform.isIOS) {
              alternativeUrl = 'https://api.whatsapp.com/send?phone=$phoneNumber&text=$encodedMessage';
            } else {
              alternativeUrl = url;
            }

            final altUri = Uri.parse(alternativeUrl);
            await launchUrl(altUri, mode: LaunchMode.externalApplication);
          }
        }
      } else {
        // WhatsApp might not be installed - try web version
        final webUrl = 'https://web.whatsapp.com/send?phone=$phoneNumber&text=$encodedMessage';
        final webUri = Uri.parse(webUrl);
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _showSnackBar(
        'Could not open WhatsApp: ${e.toString()}',
        isError: true,
      );
    }
  }

  // ✅ Image निवडलेली असल्यास text सोबत तीही share होते
  // (मूळ XFile directly वापरतो, path वरून पुन्हा wrap करत नाही -
  // यामुळे web/mobile दोन्हीवर image reliably attach होते)
  Future<void> _shareMarketingMessageWithImage(
      String message,
      ) async {
    if (_selectedMarketingImage == null) {
      return;
    }

    await Share.shareXFiles(
      [_selectedMarketingImage!],
      text: message,
      subject: 'QNX MART Business Promotion',
    );
  }

  // ============================================================
  // PLACE DETAILS POPUP
  // ============================================================

  void _showPlaceDetails(place_model.PlaceResult place) {
    setState(() {
      _isPopupOpen = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 650,
              maxHeight: 700,
            ),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? const Color(0xFF1A1A2E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      // PLACE NAME
                      Text(
                        place.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _isDarkMode
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // PHOTOS
                      if (place.photos != null &&
                          place.photos!.isNotEmpty) ...[
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: place.photos!.length,
                            itemBuilder: (context, index) {
                              final photo = place.photos![index];
                              return Container(
                                width: 300,
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: Colors.grey[300],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    photo.photoReference,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ADDRESS
                      _detailRow(
                        Icons.location_on,
                        'Address',
                        place.displayAddress,
                      ),
                      const SizedBox(height: 12),

                      // PHONE
                      if (place.internationalPhoneNumber != null)
                        _detailRow(
                          Icons.phone,
                          'Phone',
                          place.internationalPhoneNumber!,
                        ),
                      if (place.internationalPhoneNumber != null)
                        const SizedBox(height: 12),

                      // RATING
                      if (place.rating != null)
                        _detailRow(
                          Icons.star,
                          'Rating',
                          '${place.rating!.toStringAsFixed(1)} '
                              '(${place.userRatingsTotal ?? 0} reviews)',
                        ),
                      if (place.rating != null)
                        const SizedBox(height: 12),

                      // TYPES
                      if (place.types.isNotEmpty)
                        _detailRow(
                          Icons.category,
                          'Category',
                          place.types.join(', '),
                        ),

                      const SizedBox(height: 20),

                      // ACTION BUTTONS
                      Row(
                        children: [
                          if (place.internationalPhoneNumber != null)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  // ✅ फक्त dialog बंद करा, data clear करू नका
                                  _closePopupAndOpenWhatsApp(dialogContext, place);
                                },
                                icon: const Icon(Icons.message),
                                label: const Text('WhatsApp'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  padding:
                                  const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),

                          if (place.internationalPhoneNumber != null)
                            const SizedBox(width: 10),

                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                // ✅ फक्त dialog बंद करा, data clear करू नका
                                _closePopupAndOpenMaps(dialogContext, place);
                              },
                              icon: const Icon(Icons.map),
                              label: const Text('View on Map'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                const Color(0xFF4158D0),
                                foregroundColor: Colors.white,
                                padding:
                                const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // CLOSE BUTTON
                Positioned(
                  top: 8,
                  right: 8,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: () {
                        // ✅ फक्त dialog बंद करा, data clear करू नका
                        Navigator.pop(dialogContext);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.red,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // ✅ Dialog बंद झाल्यावर लगेच map enable न करता थोडा grace-delay
      // देतो, जेणेकरून popup बंद करतानाचा उरलासुरला/accidental tap
      // map पर्यंत पोहोचणार नाही. या delay नंतर वापरकर्त्याने परत
      // map वर स्वतः click केलं तरच तो click म्हणून गणला जाईल.
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          setState(() {
            _isPopupOpen = false;
          });
        }
      });
    });
  }

// ============================================================
// HELPER METHODS FOR POPUP CLOSE WITH ACTIONS
// ============================================================

  void _closePopupAndOpenWhatsApp(
      BuildContext dialogContext,
      place_model.PlaceResult place,
      ) {
    // Dialog बंद करा
    Navigator.pop(dialogContext);

    // थोडा वेळ द्या की dialog close होईल
    Future.delayed(const Duration(milliseconds: 100), () {
      _openWhatsApp(
        place.internationalPhoneNumber!,
        place.name,
      );
    });
  }

  void _closePopupAndOpenMaps(
      BuildContext dialogContext,
      place_model.PlaceResult place,
      ) {
    // Dialog बंद करा
    Navigator.pop(dialogContext);

    // थोडा वेळ द्या की dialog close होईल
    Future.delayed(const Duration(milliseconds: 100), () {
      _openInGoogleMaps(
        place.geometry.location.lat,
        place.geometry.location.lng,
        place.name,
      );
    });
  }

  // ============================================================
  // GOOGLE MAPS
  // ============================================================

  Future<void> _openInGoogleMaps(
      double lat,
      double lng,
      String placeName,
      ) async {
    final googleMapsUrl =
        'geo:$lat,$lng?q=$lat,$lng($placeName)';

    final webUrl =
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng';

    try {
      final geoUri =
      Uri.parse(googleMapsUrl);

      final webUri =
      Uri.parse(webUrl);

      if (await canLaunchUrl(geoUri)) {
        await launchUrl(
          geoUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      _showSnackBar(
        'Could not open Google Maps: $e',
        isError: true,
      );
    }
  }

  // ============================================================
  // UI HELPERS
  // ============================================================

  void _showSnackBar(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        isError ? Colors.red : Colors.green,
        behavior:
        SnackBarBehavior.floating,
        duration:
        const Duration(seconds: 3),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  Widget _detailRow(
      IconData icon,
      String title,
      String value,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFF4158D0),
          size: 21,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _isDarkMode
                      ? Colors.grey[400]
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: _isDarkMode
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  @override
  Widget build(
      BuildContext context,
      ) {
    final screenWidth =
        MediaQuery.of(context).size.width;

    final isMobile =
        screenWidth < 900;

    if (!_isAuthorized) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.block,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(
                height: 20,
              ),
              const Text(
                'Unauthorized Access',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                'Role: $_userRole',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: _logout,
                child: const Text(
                  'Go to Login',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _isDarkMode
          ? const Color(0xFF1A1A2E)
          : const Color(0xFFF0F5FA),

      appBar: AppBar(
        backgroundColor: _isDarkMode
            ? const Color(0xFF16213E)
            : Colors.white,

        elevation: 1,

        title: Image.asset(
          'assets/images/img_2.png',
          height: 40,
          fit: BoxFit.contain,
          errorBuilder:
              (context, error, stackTrace) {
            return const Text(
              'QNX Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                FontWeight.bold,
                color:
                Color(0xFF4158D0),
              ),
            );
          },
        ),

        actions: [
          IconButton(
            icon: Icon(
              _isDarkMode
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: _isDarkMode
                  ? Colors.yellow
                  : Colors.grey[600],
            ),
            onPressed: () {
              setState(() {
                _isDarkMode =
                !_isDarkMode;
              });
            },
          ),

          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Colors.red,
            ),
            onPressed: _logout,
          ),
        ],
      ),

      body: isMobile
          ? _buildMobileLayout()
          : _buildDesktopLayout(),
    );
  }

  // ============================================================
  // DESKTOP LAYOUT
  // ============================================================

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            margin:
            const EdgeInsets.all(8),
            decoration:
            BoxDecoration(
              color: _isDarkMode
                  ? const Color(
                0xFF16213E,
              )
                  : Colors.white,
              borderRadius:
              BorderRadius.circular(
                12,
              ),
            ),
            child: Column(
              children: [
                _buildSearchBar(),

                _buildMarketingBar(),

                Expanded(
                  child: _isLoading
                      ? const Center(
                    child:
                    CircularProgressIndicator(),
                  )
                      : !_hasSearched
                      ? _buildBlankState()
                      : _currentPagePlaces
                      .isEmpty
                      ? _buildEmptyState()
                      : _buildResultsTable(),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          flex: 3,
          child: _buildMap(),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE LAYOUT (fully scrollable / responsive)
  // ============================================================

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        children: [
          _buildSearchBar(),

          _buildMarketingBar(),

          SizedBox(
            height: 320,
            child: _buildMap(),
          ),

          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? const Color(0xFF16213E)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildMobileContentArea(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileContentArea() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else if (!_hasSearched) {
      return SizedBox(
        height: 260,
        child: _buildBlankState(),
      );
    } else if (_currentPagePlaces.isEmpty) {
      return SizedBox(
        height: 200,
        child: _buildEmptyState(),
      );
    } else {
      return _buildResultsTable(shrinkWrapMode: true);
    }
  }

  // ============================================================
  // MAP WIDGET
  // ============================================================

  Widget _buildMap() {
    return Container(
      margin:
      const EdgeInsets.all(8),
      decoration:
      BoxDecoration(
        borderRadius:
        BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(
              0.1,
            ),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
        BorderRadius.circular(12),
        child: Stack(
          children: [
            // ✅ Popup open असताना IgnorePointer मुळे map ला touch
            // पोहोचतच नाही (native platform-view touch leak देखील
            // यामुळे थांबतो), popup बंद झाल्यावर लगेच normal काम करतो.
            IgnorePointer(
              ignoring: _isPopupOpen,
              child: GoogleMap(
                onMapCreated:
                _onMapCreated,

                initialCameraPosition:
                CameraPosition(
                  target:
                  _currentLocation,
                  zoom:
                  SupportConstants
                      .defaultZoom
                      .toDouble(),
                ),

                onTap: _onMapTap,

                myLocationEnabled: true,

                myLocationButtonEnabled:
                true,

                zoomControlsEnabled:
                true,

                mapType:
                MapType.normal,

                markers:
                _buildMarkers(),

                circles:
                _buildCircles(),
              ),
            ),

            if (_isLoading)
              Container(
                color: Colors.black
                    .withOpacity(0.3),
                child: const Center(
                  child:
                  CircularProgressIndicator(
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

  // ✅ Remove Data button पूर्णपणे काढला
  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isDarkMode
            ? const Color(0xFF16213E)
            : Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: _isDarkMode
                    ? Colors.grey[800]
                    : const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _onSearch(),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: TextStyle(
                  color: _isDarkMode
                      ? Colors.white
                      : Colors.black,
                ),
                decoration: InputDecoration(
                  hintText: 'Search places, companies...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF4158D0),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                        _searchQuery = '';
                        _hasSearched = false;
                        _clearPlacesData();
                      });
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),



          // Radius Dropdown
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: _isDarkMode
                  ? Colors.grey[800]
                  : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButton<int>(
              value: _selectedRadius,
              underline: const SizedBox(),
              items: _radiusOptions
                  .map(
                    (radius) => DropdownMenuItem<int>(
                  value: radius,
                  child: Text('$radius km'),
                ),
              )
                  .toList(),
              onChanged: _onRadiusChanged,
            ),
          ),

          const SizedBox(width: 8),

          // Search Button
          Container(
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF4158D0),
                  Color(0xFFC850C0),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: _onSearch,
              icon: const Icon(
                Icons.search,
                color: Colors.white,
              ),
            ),
          ),



          // In _buildSearchBar method, after the Search Button, add:
          const SizedBox(width: 8),

// Create Builder Button
          /*Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF2ECC71),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateBuilderScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.business_center,
                color: Colors.white,
              ),
              tooltip: 'Create Builder',
            ),
          ),

          // Create Property Button
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreatePropertyScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.home_work,
                color: Colors.white,
              ),
              tooltip: 'Create Property',
            ),
          ),*/

          const SizedBox(width: 8),

          // ✅ Create New Button (opens CreateBuilderPropertyScreen)
          Container(
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF2ECC71),
                  Color(0xFF6C63FF),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateBuilderPropertyScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.add_box,
                color: Colors.white,
              ),
              tooltip: 'Create New',
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MARKETING MESSAGE BAR
  // ============================================================

  Widget _buildMarketingBar() {
    return Container(
      margin:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      padding:
      const EdgeInsets.all(10),
      decoration:
      BoxDecoration(
        color: _isDarkMode
            ? const Color(0xFF1A1A2E)
            : const Color(0xFFF8F9FA),
        borderRadius:
        BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            'QNX MART WhatsApp Marketing Message',
            style: TextStyle(
              fontWeight:
              FontWeight.bold,
              color: _isDarkMode
                  ? Colors.white
                  : Colors.black87,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          TextField(
            controller:
            _marketingMessageController,

            maxLines: 3,

            decoration:
            InputDecoration(
              hintText:
              'Enter marketing message',
              border:
              OutlineInputBorder(
                borderRadius:
                BorderRadius.circular(
                  8,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          Row(
            children: [
              ElevatedButton.icon(
                onPressed:
                _pickMarketingImage,
                icon: const Icon(
                  Icons.image,
                ),
                label: const Text(
                  'Select Image',
                ),
              ),

              if (_selectedMarketingImage !=
                  null)
                IconButton(
                  onPressed:
                  _removeMarketingImage,
                  icon: const Icon(
                    Icons.delete,
                    color: Colors.red,
                  ),
                ),
            ],
          ),

          // ✅ Selected image ची preview - चेट/message box च्या खाली
          // दिसते, जेणेकरून WhatsApp वर पाठवण्याआधी confirm करता येईल.
          if (_selectedMarketingImage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: kIsWeb
                        ? Image.network(
                      _selectedMarketingImage!.path,
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    )
                        : Image.file(
                      File(_selectedMarketingImage!.path),
                      height: 60,
                      width: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedMarketingImage!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _isDarkMode
                            ? Colors.white70
                            : Colors.black87,
                        fontSize: 13,
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

  // ============================================================
  // BLANK STATE
  // ============================================================

  Widget _buildBlankState() {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: _isDarkMode
                ? Colors.grey[600]
                : Colors.grey[300],
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            'Search for companies',
            style: TextStyle(
              color: _isDarkMode
                  ? Colors.grey[400]
                  : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off,
            size: 48,
            color: Colors.grey,
          ),
          const SizedBox(
            height: 8,
          ),
          Text(
            _errorMessage ??
                'No places found. Try different keywords.',
            textAlign:
            TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESULTS TABLE
  // ============================================================

  // ✅ shrinkWrapMode = true : mobile वर SingleChildScrollView च्या
  // आत वापरण्यासाठी - list स्वतःच्या content इतकीच height घेते,
  // outer scroll शीच scroll होते (double-scroll conflict येत नाही).
  Widget _buildResultsTable({bool shrinkWrapMode = false}) {
    final header = Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      color: _isDarkMode
          ? Colors.grey[800]
          : const Color(0xFFF0F2F5),
      child: const Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'Company',
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              'Address',
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Phone',
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),
          // ✅ Action column चा flex 1 वरून 2 केला (overflow नाही)
          Expanded(
            flex: 2,
            child: Text(
              'Action',
              textAlign:
              TextAlign.center,
              style: TextStyle(
                fontWeight:
                FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    final list = ListView.builder(
      shrinkWrap: shrinkWrapMode,
      physics: shrinkWrapMode
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount:
      _currentPagePlaces.length,

      itemBuilder:
          (context, index) {
        final place =
        _currentPagePlaces[
        index];

        return Container(
          padding:
          const EdgeInsets
              .symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration:
          BoxDecoration(
            border: Border(
              bottom:
              BorderSide(
                color: _isDarkMode
                    ? Colors.grey[
                800]!
                    : Colors.grey[
                200]!,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  place.name,
                  maxLines: 1,
                  overflow:
                  TextOverflow
                      .ellipsis,
                ),
              ),

              Expanded(
                flex: 4,
                child: Text(
                  place
                      .displayAddress,
                  maxLines: 2,
                  overflow:
                  TextOverflow
                      .ellipsis,
                ),
              ),

              Expanded(
                flex: 2,
                child: Text(
                  place
                      .internationalPhoneNumber ??
                      'N/A',
                  maxLines: 1,
                  overflow:
                  TextOverflow
                      .ellipsis,
                ),
              ),

              // ✅ Action column - flex 2 दिल्याने आता buttons ला
              // पुरेशी जागा मिळते, overflow नाही
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment
                      .center,
                  children: [
                    IconButton(
                      icon:
                      const Icon(
                        Icons
                            .info_outline,
                        color: Color(
                          0xFF4158D0,
                        ),
                        size: 22,
                      ),
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      onPressed:
                          () {
                        _showPlaceDetails(
                          place,
                        );
                      },
                    ),

                    if (place
                        .internationalPhoneNumber !=
                        null)
                      IconButton(
                        icon:
                        const Icon(
                          Icons.message,
                          color: Color(
                            0xFF25D366,
                          ),
                          size: 22,
                        ),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed:
                            () {
                          _openWhatsApp(
                            place
                                .internationalPhoneNumber!,
                            place.name,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    final footer = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: _isDarkMode ? Colors.grey[800] : const Color(0xFFF0F2F5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Loaded count so far + Load All button
          Row(
            children: [
              Text(
                'Loaded: ${_allPlaces.length} companies',
                style: TextStyle(
                  color: _isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(width: 12),
              if (_allPlaces.isNotEmpty && (_hasNextPage || _pagesCache.length > 1))
                TextButton(
                  onPressed: (_isLoading || _isFetchingPage) ? null : _loadAllPages,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    backgroundColor: const Color(0xFF4158D0).withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: (_isLoading || _isFetchingPage)
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text(
                    'Load All',
                    style: TextStyle(
                      color: Color(0xFF4158D0),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),

          // Page navigation
          Row(
            children: [
              // First page
              IconButton(
                icon: const Icon(Icons.first_page, size: 20),
                onPressed: _currentPage > 0 ? () => _goToPage(0) : null,
                tooltip: 'First page',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),

              // Previous page (always cached, instant)
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 24),
                onPressed: _currentPage > 0 ? _fetchPrevPage : null,
                tooltip: 'Previous page',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),

              // Page info with loading indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _isFetchingPage
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(
                  '${_currentPage + 1} / ${_pagesCache.length}${_hasNextPage ? '+' : ''}',
                  style: TextStyle(
                    color: _isDarkMode ? Colors.white70 : Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),

              // Next page (fetches a new batch if needed)
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 24),
                onPressed: (_currentPage + 1 < _pagesCache.length || _hasNextPage)
                    ? _fetchNextPage
                    : null,
                tooltip: 'Next page',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),

              // Last known page
              IconButton(
                icon: const Icon(Icons.last_page, size: 20),
                onPressed: _currentPage < _pagesCache.length - 1
                    ? () => _goToPage(_pagesCache.length - 1)
                    : null,
                tooltip: 'Last fetched page',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),

          // Showing count
          Text(
            'Showing ${_currentPagePlaces.length} items',
            style: TextStyle(
              color: _isDarkMode ? Colors.white70 : Colors.black87,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    if (shrinkWrapMode) {
      // Mobile: outer SingleChildScrollView स्वतः scroll करते
      return Column(
        children: [
          header,
          list,
          footer,
        ],
      );
    }

    // Desktop: bounded parent (Expanded) असल्यामुळे list स्वतः scroll होते
    return Column(
      children: [
        header,
        Expanded(child: list),
        footer,
      ],
    );
  }
}