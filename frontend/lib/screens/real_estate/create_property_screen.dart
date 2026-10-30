
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';  // ✅ ADD THIS
import '../../api/realestate_service.dart';
import '../../api/marketing_service.dart' show MarketingProfileService;
import '../../models/real_estate/amenity_model.dart';
import '../../models/real_estate/pdf_extract_model.dart';
import '../../models/real_estate/property_model.dart';
import '../../models/real_estate/builder_list_model.dart';

// ==================== DECIMAL INPUT FORMATTER ====================
class DecimalTextInputFormatter extends TextInputFormatter {
  final int decimalRange;
  DecimalTextInputFormatter({this.decimalRange = 2});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;
    final regExp = RegExp(r'^\d*\.?\d{0,' + decimalRange.toString() + r'}$');
    if (regExp.hasMatch(text)) {
      return newValue;
    }
    return oldValue;
  }
}

// ==================== DD-MM-YYYY DATE FORMATTER ====================
class DateTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final cleaned = newValue.text.replaceAll(RegExp(r'[^0-9-]'), '');
    if (cleaned.length > 10) return oldValue;
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: cleaned.length),
    );
  }
}

class CreatePropertyScreen extends StatefulWidget {
  final PdfPropertyData? prefilledData;
  final List<MediaFile> prefilledImages;
  final List<MediaFile> prefilledVideos;
  final List<MediaFile> prefilledDocuments;
  final VoidCallback? onUploadPdf;

  const CreatePropertyScreen({
    super.key,
    this.prefilledData,
    this.prefilledImages = const [],
    this.prefilledVideos = const [],
    this.prefilledDocuments = const [],
    this.onUploadPdf,
  });

  @override
  State<CreatePropertyScreen> createState() => _CreatePropertyScreenState();
}

class _CreatePropertyScreenState extends State<CreatePropertyScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final Map<String, String> _backendErrors = {};
  final Map<String, GlobalKey<FormFieldState>> _fieldKeys = {};
  final Map<String, FocusNode> _fieldFocusNodes = {};
  final Map<String, GlobalKey> _fieldWidgetKeys = {};

  GlobalKey<FormFieldState> _keyFor(String field) =>
      _fieldKeys.putIfAbsent(field, () => GlobalKey<FormFieldState>());

  FocusNode _focusFor(String field) =>
      _fieldFocusNodes.putIfAbsent(field, () => FocusNode());

  GlobalKey _widgetKeyFor(String field) =>
      _fieldWidgetKeys.putIfAbsent(field, () => GlobalKey());

  String _cleanError(String msg) {
    var m = msg.trim();
    m = m.replaceAll(RegExp(r'^\s*\[\s*'), '');
    m = m.replaceAll(RegExp(r'\s*\]\s*$'), '');
    return m;
  }

  String _labelForField(String field) {
    final labels = {
      'project_name': 'Project Name',
      'title': 'Property / Company Title',
      'description': 'Property Description',
      'city': 'City',
      'area': 'Area / Locality',
      'pincode': 'Pincode',
      'address': 'Complete Address',
      'landmark': 'Landmark',
      'latitude': 'Latitude',
      'longitude': 'Longitude',
      'google_location_url': 'Google Location URL',
      'plot_area': 'Plot / Land Area',
      'total_area': 'Total Built-up / Sales Area',
      'total_towers': 'Number of Towers',
      'total_floors': 'Number of Floors',
      'rera_website': 'RERA Portal URL',
      'rera_qr_code': 'RERA QR Code URL',
      'property_website_url': 'Property Website URL',
      'amenities': 'Amenities',
    };
    if (labels.containsKey(field)) return labels[field]!;
    if (field.startsWith('rera_number_')) {
      final idx = int.tryParse(field.replaceAll('rera_number_', '')) ?? 0;
      return 'RERA Number ${idx + 1}';
    }
    if (field.startsWith('legal_advisor_')) {
      final idx = int.tryParse(field.replaceAll('legal_advisor_', '')) ?? 0;
      return 'Legal Advisor ${idx + 1}';
    }
    return field[0].toUpperCase() + field.substring(1).replaceAll('_', ' ');
  }

  String? _findFirstInvalidField() {
    final errors = _formKey.currentState?.validate() ?? false;
    if (errors) return null;

    const fieldOrder = [
      'project_name',
      'title',
      'description',
      'city',
      'area',
      'pincode',
      'address',
      'plot_area',
      'total_area',
      'total_towers',
      'total_floors',
      'rera_number_0',
      'rera_number_1',
      'rera_number_2',
      'rera_number_3',
      'rera_number_4',
      'legal_advisor_0',
      'legal_advisor_1',
      'legal_advisor_2',
      'legal_advisor_3',
      'legal_advisor_4',
      'rera_website',
      'rera_qr_code',
      'property_website_url',
      'amenities',
    ];

    for (final field in fieldOrder) {
      final key = _fieldKeys[field];
      if (key?.currentState?.hasError == true) {
        return field;
      }
    }
    for (final entry in _fieldKeys.entries) {
      if (entry.value.currentState?.hasError == true) {
        return entry.key;
      }
    }
    return null;
  }

  void _focusOnField(String field) {
    final widgetKey = _fieldWidgetKeys[field];
    final ctx = widgetKey?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        alignment: 0.25,
        curve: Curves.easeInOut,
      );
    }

    Future.delayed(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      final node = _fieldFocusNodes[field];
      if (node != null) {
        node.requestFocus();
      }
    });
  }

  // ==================== CONTROLLERS ====================
  final _companyNameController = TextEditingController();
  final _projectNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _googleLocationUrlController = TextEditingController();
  final _totalAreaController = TextEditingController();
  final _plotAreaController = TextEditingController();
  final _totalFloorsController = TextEditingController();
  final _totalTowersController = TextEditingController();
  final _possessionDateController = TextEditingController();
  final _completionPercentageController = TextEditingController();

  final List<TextEditingController> _legalAdvisorControllers = [];
  final List<TextEditingController> _reraNumberControllers = [];
  final List<TextEditingController> _reraAdditionalUrlControllers = [];

  final _reraQrCodeController = TextEditingController();
  final _reraWebsiteController = TextEditingController();
  final _propertyWebsiteUrlController = TextEditingController();

  final List<Map<String, TextEditingController>> _featureControllers = [];

  final List<SelectedMedia> _images = [];
  final List<SelectedMedia> _videos = [];
  final List<MediaFile> _documents = [];

  List<BuilderData> _builders = [];
  bool _isLoadingBuilders = false;
  int? _selectedBuilderId;
  String _selectedBuilderName = '';
  PdfBuilder? _pdfBuilderForCreate;

  List<Amenity> _availableAmenities = [];
  bool _isLoadingAmenities = false;
  bool _isAddingAmenity = false;

  final Map<int, Map<String, dynamic>> _flatTypes = {};
  int _nextFlatTypeId = 0;

  final _wingControllers = <int, Map<String, dynamic>>{};
  int _nextWingId = 0;

  final _pricingSlabControllers = <int, Map<String, dynamic>>{};
  int _nextPricingSlabId = 0;

  String _selectedPropertyType = 'flat';
  String _selectedTransactionType = 'sale';
  String _selectedStatus = 'draft';
  String _selectedSource = 'admin';
  bool _isUnderConstruction = true;
  bool _isFeatured = false;
  bool _isVerified = false;
  bool _isNegotiable = true;
  bool _isReadyToMove = false;
  int? _marketingPartnerId;
  String _marketingPartnerName = '';
  bool _isLoadingPartner = false;

  List<int> _selectedAmenityIds = [];

  bool _isLoading = false;
  bool _isDarkMode = false;

  bool _isFetchingPincode = false;

  final PropertyService _propertyService = PropertyService();
  final BuilderListService _builderService = BuilderListService();
  final RealEstateService _realEstateService = RealEstateService();

  late AnimationController _cardController;
  late List<Animation<double>> _cardAnimations;

  final List<String> _propertyTypes = [
    'flat', 'villa', 'independent_house', 'plot',
    'commercial', 'office', 'shop', 'warehouse',
  ];

  final List<String> _transactionTypes = ['sale', 'rent', 'lease'];
  final List<String> _statusTypes = ['draft', 'pending', 'approved', 'rejected'];
  final List<String> _sourceTypes = ['admin'];  // ✅ ADD THIS LINE

  final List<String> _bhkOptions = [
    '1 BHK', '2 BHK', '3 BHK', '4 BHK', '5 BHK', '6 BHK', 'Penthouse', 'Studio'
  ];

  // ==================== Common colors (matching screenshot) ====================
  final Color kPrimary = const Color(0xFF7C3AED);
  final Color kPrimaryLight = const Color(0xFFF3E8FF);
  final Color kBorder = const Color(0xFFE5E7EB);
  final Color kTextPrimary = const Color(0xFF111827);
  final Color kTextSecondary = const Color(0xFF6B7280);
  final Color kBg = const Color(0xFFF9FAFB);
  final Color kSuccess = const Color(0xFF10B981);

  bool get _showReraSection {
    return _selectedPropertyType != 'villa' &&
        _selectedPropertyType != 'plot';
  }

  bool get _showConstructionStage {
    return _selectedPropertyType != 'plot';
  }

  bool get _showPossessionDate {
    return _selectedPropertyType != 'plot';
  }

  bool get _isBuilderRequired {
    return _selectedPropertyType != 'villa';
  }

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardAnimations = List.generate(3, (i) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _cardController,
          curve: Interval(i * 0.15, 0.6 + i * 0.1, curve: Curves.easeOutBack),
        ),
      );
    });
    _cardController.forward();

    _reraNumberControllers.add(TextEditingController());
    _legalAdvisorControllers.add(TextEditingController());

    _loadBuilders();
    _loadAmenities();
    _loadMarketingPartner();
    _prefillFromPdf();
  }

  @override
  void didUpdateWidget(covariant CreatePropertyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final pdfChanged = oldWidget.prefilledData != widget.prefilledData;
    final mediaChanged = oldWidget.prefilledImages != widget.prefilledImages ||
        oldWidget.prefilledVideos != widget.prefilledVideos ||
        oldWidget.prefilledDocuments != widget.prefilledDocuments;
    if (pdfChanged || mediaChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _clearForm();
        _prefillFromPdf();
      });
    }
  }

  // ==================== DATE CONVERSION HELPERS ====================
  String _toDdMmYyyy(String raw) {
    if (raw.trim().isEmpty) return '';
    final trimmed = raw.trim();
    if (RegExp(r'^\d{2}-\d{2}-\d{4}$').hasMatch(trimmed)) return trimmed;
    if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(trimmed)) {
      final parts = trimmed.split('-');
      return '${parts[2]}-${parts[1]}-${parts[0]}';
    }
    try {
      final dt = DateTime.parse(trimmed);
      return '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    } catch (_) {
      return trimmed;
    }
  }

  String? _ddMmYyyyToIso(String ddMmYyyy) {
    if (ddMmYyyy.trim().isEmpty) return null;
    final parts = ddMmYyyy.trim().split('-');
    if (parts.length != 3) return null;
    if (parts[0].length != 2 || parts[1].length != 2 || parts[2].length != 4) {
      return null;
    }
    return '${parts[2]}-${parts[1]}-${parts[0]}';
  }

  DateTime? _parseDdMmYyyy(String raw) {
    try {
      final parts = raw.trim().split('-');
      if (parts.length != 3) return null;
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      return null;
    }
  }

  String _formatDecimal(String value) {
    if (value.trim().isEmpty) return '';
    final num = double.tryParse(value.trim());
    if (num == null) return value.trim();
    final formatted = num.toStringAsFixed(2);
    if (formatted.endsWith('.00')) {
      return formatted.substring(0, formatted.length - 3);
    } else if (formatted.endsWith('0')) {
      return formatted.substring(0, formatted.length - 1);
    }
    return formatted;
  }

  // ==================== AMENITIES LOADING ====================
  Future<void> _loadAmenities() async {
    setState(() => _isLoadingAmenities = true);
    try {
      final response = await _realEstateService.getAmenities();
      if (mounted) {
        setState(() {
          _availableAmenities = response.data;
          _isLoadingAmenities = false;
          _matchPdfAmenitiesAfterLoad();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAmenities = false);
        print('Error loading amenities: $e');
      }
    }
  }

  List<String> _pendingPdfAmenities = [];

  void _matchPdfAmenitiesAfterLoad() {
    if (_pendingPdfAmenities.isEmpty || _availableAmenities.isEmpty) return;
    for (var pdfName in _pendingPdfAmenities) {
      final matched = _availableAmenities.firstWhere(
            (a) => a.name.toLowerCase() == pdfName.toLowerCase(),
        orElse: () => Amenity(id: -1, name: '', isActive: false, createdAt: ''),
      );
      if (matched.id != -1 && !_selectedAmenityIds.contains(matched.id)) {
        _selectedAmenityIds.add(matched.id);
      }
    }
    _pendingPdfAmenities.clear();
  }

  // ==================== ADD AMENITY DIALOG ====================
  Future<void> _showAddAmenityDialog() async {
    final nameController = TextEditingController();
    final addFormKey = GlobalKey<FormState>();
    bool isActive = true;
    bool isSaving = false;

    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kPrimaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.add_circle_outline,
                      color: kPrimary, size: 22),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Add Amenity',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            content: Form(
              key: addFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    validator: (v) =>
                    (v == null || v.trim().isEmpty)
                        ? 'Name is required'
                        : null,
                    decoration: InputDecoration(
                      labelText: 'Amenity Name',
                      hintText: 'e.g., Gym, Swimming Pool, Garden',
                      prefixIcon: Icon(Icons.label_outline,
                          color: kPrimary, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: kPrimary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Switch(
                        value: isActive,
                        activeColor: kPrimary,
                        onChanged: (v) =>
                            setDialogState(() => isActive = v),
                      ),
                      const SizedBox(width: 8),
                      const Text('Active Status',
                          style: TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: isSaving
                    ? null
                    : () async {
                  if (!addFormKey.currentState!.validate()) return;

                  setDialogState(() => isSaving = true);

                  try {
                    final amenity = Amenity(
                      id: 0,
                      name: nameController.text.trim(),
                      isActive: isActive,
                      createdAt: '',
                    );

                    final response =
                    await _realEstateService.createAmenity(amenity);

                    if (!mounted) return;
                    Navigator.pop(ctx, true);

                    final newId = response.data.id;
                    await _loadAmenities();

                    if (newId != 0 && mounted) {
                      setState(() {
                        if (!_selectedAmenityIds.contains(newId)) {
                          _selectedAmenityIds.add(newId);
                        }
                      });
                    }

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            response.message.isNotEmpty
                                ? response.message
                                : 'Amenity added successfully!',
                          ),
                          backgroundColor: kSuccess,
                        ),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    setDialogState(() => isSaving = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to add amenity: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                icon: isSaving
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                )
                    : const Icon(Icons.check, size: 18),
                label: Text(isSaving ? 'Saving...' : 'Add Amenity'),
              ),
            ],
          );
        },
      ),
    );

    nameController.dispose();
  }

  // ==================== PDF PREFILL ====================
  void _prefillFromPdf() {
    final data = widget.prefilledData;

    for (var img in widget.prefilledImages) {
      _images.add(SelectedMedia(file: img, isSelected: false));
    }
    for (var vid in widget.prefilledVideos) {
      _videos.add(SelectedMedia(file: vid, isSelected: false));
    }
    _documents.addAll(widget.prefilledDocuments);

    if (data == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return;
    }

    _companyNameController.text = data.title;
    _projectNameController.text = data.title;
    _descriptionController.text = data.description;

    final validSubcategories = ['flat', 'villa', 'plot', 'commercial', 'shop', 'office'];
    if (validSubcategories.contains(data.propertyType)) {
      _selectedPropertyType = data.propertyType;
    } else if (data.propertyType == 'independent_house') {
      _selectedPropertyType = 'villa';
    } else if (data.propertyType == 'warehouse') {
      _selectedPropertyType = 'commercial';
    } else {
      _selectedPropertyType = 'flat';
    }

    if (_transactionTypes.contains(data.transactionType)) {
      _selectedTransactionType = data.transactionType;
    }
    if (_statusTypes.contains(data.status)) {
      _selectedStatus = data.status;
    }

    _cityController.text = data.city;
    _areaController.text = data.area;
    _addressController.text = data.address;
    _landmarkController.text = data.landmark;
    _pincodeController.text = data.pincode;

    if (data.latitude != null && data.latitude != 0) {
      _latitudeController.text = _formatDecimal(data.latitude.toString());
    }
    if (data.longitude != null && data.longitude != 0) {
      _longitudeController.text = _formatDecimal(data.longitude.toString());
    }
    _googleLocationUrlController.text = data.googleLocationUrl;

    if (data.totalArea != null && data.totalArea != 0) {
      _totalAreaController.text = _formatDecimal(data.totalArea.toString());
    }
    if (data.plotArea != null && data.plotArea != 0) {
      _plotAreaController.text = _formatDecimal(data.plotArea.toString());
    }
    if (data.totalFloors != null && data.totalFloors != 0) {
      _totalFloorsController.text = data.totalFloors.toString();
    }
    if (data.totalTowers != null && data.totalTowers != 0) {
      _totalTowersController.text = data.totalTowers.toString();
    }

    _reraQrCodeController.text = data.reraQrCode;
    _reraWebsiteController.text = data.reraWebsite;
    _propertyWebsiteUrlController.text = data.propertyWebsiteUrl;

    if (data.possessionDate.isNotEmpty) {
      final converted = _toDdMmYyyy(data.possessionDate);
      final parsed = _parseDdMmYyyy(converted);
      final now = DateTime.now();
      if (parsed != null && parsed.isAfter(now.subtract(const Duration(days: 1)))) {
        _possessionDateController.text = converted;
      }
    }

    if (data.completionPercentage != null && data.completionPercentage != 0) {
      _completionPercentageController.text =
          data.completionPercentage.toString();
    }

    if (data.reraNumber.isNotEmpty) {
      final parts = data.reraNumber
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (_reraNumberControllers.length == 1 && _reraNumberControllers.first.text.trim().isEmpty) {
        _reraNumberControllers.first.text = parts.first;
        for (var p in parts.skip(1)) {
          _reraNumberControllers.add(TextEditingController(text: p));
        }
      } else {
        for (var p in parts) {
          _reraNumberControllers.add(TextEditingController(text: p));
        }
      }
    }

    for (var url in data.reraAdditionalUrls) {
      if (url.isNotEmpty) {
        _reraAdditionalUrlControllers.add(TextEditingController(text: url));
      }
    }

    _isUnderConstruction = data.isUnderConstruction;
    _isFeatured = data.isFeatured;
    _isVerified = data.isVerified;
    _isNegotiable = data.isNegotiable;

    for (var f in data.features) {
      if (f.name.isNotEmpty && f.value.isNotEmpty) {
        _featureControllers.add({
          'key': TextEditingController(text: f.name),
          'value': TextEditingController(text: f.value),
        });
      }
    }

    _pendingPdfAmenities = List.from(data.amenities);

    for (var ft in data.flatTypes) {
      if (ft.flatType.isEmpty) continue;
      final c = _createFlatTypeEntry(ft.flatType.trim());
      if (ft.areaSqft != null && ft.areaSqft!.isNotEmpty) {
        (c['areaSqft'] as TextEditingController).text = _formatDecimal(ft.areaSqft!);
      }
      if (ft.bedrooms != null && ft.bedrooms! > 0) {
        (c['bedrooms'] as TextEditingController).text = ft.bedrooms.toString();
      }
      if (ft.bathrooms != null && ft.bathrooms! > 0) {
        (c['bathrooms'] as TextEditingController).text = ft.bathrooms.toString();
      }
    }

    for (final raw in data.floors) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final id = _nextWingId++;
      _wingControllers[id] = {
        'floorNumber': TextEditingController(text: m['floor_number']?.toString() ?? ''),
        'name': TextEditingController(text: m['floor_name']?.toString() ?? m['name']?.toString() ?? ''),
        'units': TextEditingController(text: m['total_units']?.toString() ?? m['units']?.toString() ?? ''),
        'availableUnits': TextEditingController(text: m['available_units']?.toString() ?? m['availableUnits']?.toString() ?? ''),
      };
    }

    for (final raw in data.pricingSlabs) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final id = _nextPricingSlabId++;

      final paymentRows = <Map<String, TextEditingController>>[];
      if (m['payment_schedule'] is Map) {
        (m['payment_schedule'] as Map).forEach((k, v) {
          paymentRows.add({
            'key': TextEditingController(text: k.toString()),
            'value': TextEditingController(text: v.toString()),
          });
        });
      }

      final chargeRows = <Map<String, TextEditingController>>[];
      if (m['additional_charges'] is Map) {
        (m['additional_charges'] as Map).forEach((k, v) {
          chargeRows.add({
            'key': TextEditingController(text: k.toString()),
            'value': TextEditingController(text: v.toString()),
          });
        });
      }

      _pricingSlabControllers[id] = {
        'floor': TextEditingController(text: m['floor']?.toString() ?? ''),
        'flatType': TextEditingController(text: m['flat_type']?.toString() ?? ''),
        'basePrice': TextEditingController(text: m['base_price']?.toString() ?? ''),
        'pricePerSqft': TextEditingController(text: m['price_per_sqft']?.toString() ?? ''),
        'bookingAmount': TextEditingController(text: m['booking_amount']?.toString() ?? ''),
        'discountPercentage': TextEditingController(text: m['discount_percentage']?.toString() ?? ''),
        'gstPercentage': TextEditingController(text: m['gst_percentage']?.toString() ?? ''),
        'paymentSchedule': paymentRows,
        'additionalCharges': chargeRows,
        'isAvailable': m['is_available'] ?? true,
      };
    }

    _matchBuilderFromPdf(data.builder);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Map<String, dynamic> _createFlatTypeEntry(String flatType) {
    final id = _nextFlatTypeId++;
    _flatTypes[id] = {
      'flatType': flatType,
      'count': TextEditingController(),
      'areaSqft': TextEditingController(),
      'carpetArea': TextEditingController(),
      'balconyArea': TextEditingController(),
      'bedrooms': TextEditingController(),
      'bathrooms': TextEditingController(),
      'balconies': TextEditingController(),
      'kitchens': TextEditingController(),
      'parkingCount': TextEditingController(),
    };
    return _flatTypes[id]!;
  }

  void _showAddFlatTypeDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Flat Type'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select or type a flat type',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _bhkOptions.map((bhk) {
                  // ✅ duplicate check काढला — आता same type multiple वेळा add होईल
                  return ActionChip(
                    label: Text(bhk,
                        style: const TextStyle(
                            color: Colors.black87, fontSize: 12)),
                    backgroundColor: kPrimaryLight,
                    onPressed: () {
                      Navigator.pop(ctx);
                      _safeSetState(() => _createFlatTypeEntry(bhk));
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Custom Flat Type',
                  hintText: 'e.g., 3.5 BHK',
                  border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                _safeSetState(() => _createFlatTypeEntry(val));
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _removeFlatType(int id) {
    if (_flatTypes.containsKey(id)) {
      final entry = _flatTypes[id]!;
      for (var c in entry.values) {
        if (c is TextEditingController) c.dispose();
      }
      _flatTypes.remove(id);
      _safeSetState(() {});
    }
  }

  void _matchBuilderFromPdf(PdfBuilder? pdfBuilder) {
    _pdfBuilderForCreate = pdfBuilder;
    if (pdfBuilder == null || pdfBuilder.name.isEmpty) return;
    _pendingBuilderMatch = pdfBuilder.name;
    if (_builders.isNotEmpty) {
      final q = pdfBuilder.name.trim().toLowerCase();
      final index = _builders.indexWhere((b) => b.name.trim().toLowerCase() == q);
      if (index >= 0) {
        _selectedBuilderId = _builders[index].id;
        _selectedBuilderName = _builders[index].name;
        _pendingBuilderMatch = null;
      }
    }
  }

  String? _pendingBuilderMatch;

  Future<void> _loadBuilders() async {
    if (_builders.isNotEmpty) return;
    setState(() => _isLoadingBuilders = true);
    try {
      final response = await _builderService.getBuilders();
      if (mounted) {
        setState(() {
          _builders = response.data;
          _isLoadingBuilders = false;
          if (_pendingBuilderMatch != null) {
            final match = _builders.firstWhere(
                  (b) => b.name.toLowerCase() == _pendingBuilderMatch!.toLowerCase(),
              orElse: () => BuilderData(
                id: -1,
                name: '',
                shortInfo: '',
                isActive: false,
                createdAt: '',
                updatedAt: '',
              ),
            );
            if (match.id != -1) {
              _selectedBuilderId = match.id;
              _selectedBuilderName = match.name;
            }
            _pendingBuilderMatch = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingBuilders = false);
        print('Error loading builders: $e');
      }
    }
  }

  // ============================================================
  // ✅ AUTO-LOAD LOGGED-IN MARKETING PARTNER
  // ============================================================
  Future<void> _loadMarketingPartner() async {
    setState(() => _isLoadingPartner = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ STEP 1: Partner ID try kar — role check kartana
      // Priority: marketing_partner_id > partner_id > user_id
      String? partnerIdStr = prefs.getString('marketing_partner_id') ??
          prefs.getString('partner_id') ??
          prefs.getString('user_id');

      // ✅ STEP 2: Role check — jr marketing partner asel tar name pan ghe
      final role = (prefs.getString('user_role') ?? '').toLowerCase();

      final isPartnerRole = role.contains('marketing partner') ||
          role.contains('marketing_partner') ||
          role.contains('marketing head') ||
          role.contains('marketing_head') ||
          role.contains('admin');  // ✅ ADMIN pan include kara

      if (!isPartnerRole) {
        if (mounted) setState(() => _isLoadingPartner = false);
        return;
      }

      if (partnerIdStr == null || partnerIdStr.isEmpty) {
        if (mounted) setState(() => _isLoadingPartner = false);
        return;
      }

      final partnerId = int.tryParse(partnerIdStr);
      if (partnerId == null || partnerId <= 0) {
        if (mounted) setState(() => _isLoadingPartner = false);
        return;
      }

      // ✅ STEP 3: ID set kara — submit madhe jael
      if (mounted) {
        setState(() {
          _marketingPartnerId = partnerId;
        });
      }

      // ✅ STEP 4: Name fetch kara (UI sathi)
      final cachedName = prefs.getString('user_name') ??
          prefs.getString('username') ??
          prefs.getString('full_name') ??
          '';

      if (cachedName.isNotEmpty && mounted) {
        setState(() {
          _marketingPartnerName = cachedName;
          _isLoadingPartner = false;
        });
        return;
      }

      // ✅ STEP 5: API fallback
      try {
        final profileService = MarketingProfileService();
        final response = await profileService.getMyProfile();

        if (!mounted) return;

        if (response.status && response.data != null) {
          setState(() {
            _marketingPartnerName = response.data!.fullName ??
                response.data!.email ??
                'Partner #$partnerId';
            _isLoadingPartner = false;
          });
        } else {
          setState(() {
            _marketingPartnerName = 'Partner #$partnerId';
            _isLoadingPartner = false;
          });
        }
      } catch (e) {
        print('⚠️ Partner name fetch failed: $e');
        if (mounted) {
          setState(() {
            _marketingPartnerName = 'Partner #$partnerId';
            _isLoadingPartner = false;
          });
        }
      }
    } catch (e) {
      print('❌ Load Marketing Partner Error: $e');
      if (mounted) setState(() => _isLoadingPartner = false);
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _projectNameController.dispose();
    _descriptionController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _googleLocationUrlController.dispose();
    _totalAreaController.dispose();
    _plotAreaController.dispose();
    _totalFloorsController.dispose();
    _totalTowersController.dispose();
    _possessionDateController.dispose();
    _completionPercentageController.dispose();
    _reraQrCodeController.dispose();
    _reraWebsiteController.dispose();
    _propertyWebsiteUrlController.dispose();

    for (var c in _legalAdvisorControllers) {
      c.dispose();
    }
    for (var c in _reraNumberControllers) {
      c.dispose();
    }
    for (var c in _reraAdditionalUrlControllers) {
      c.dispose();
    }
    for (var feature in _featureControllers) {
      feature['key']?.dispose();
      feature['value']?.dispose();
    }
    for (var entry in _flatTypes.values) {
      for (var c in entry.values) {
        if (c is TextEditingController) c.dispose();
      }
    }
    _flatTypes.clear();
    _nextFlatTypeId = 0;
    for (var ctrl in _wingControllers.values) {
      if (ctrl['name'] is TextEditingController) {
        (ctrl['name'] as TextEditingController).dispose();
      }
      if (ctrl['units'] is TextEditingController) {
        (ctrl['units'] as TextEditingController).dispose();
      }
      if (ctrl['availableUnits'] is TextEditingController) {
        (ctrl['availableUnits'] as TextEditingController).dispose();
      }
    }
    for (var ctrl in _pricingSlabControllers.values) {
      for (var c in ctrl.values) {
        if (c is TextEditingController) {
          c.dispose();
        } else if (c is List<Map<String, TextEditingController>>) {
          for (var row in c) {
            row['key']?.dispose();
            row['value']?.dispose();
          }
        }
      }
    }

    for (var node in _fieldFocusNodes.values) {
      node.dispose();
    }

    _propertyService.dispose();
    _builderService.dispose();
    _cardController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  // ==================== LEGAL ADVISORS ====================
  void _addLegalAdvisor() {
    _legalAdvisorControllers.add(TextEditingController());
    _safeSetState(() {});
  }

  void _removeLegalAdvisor(int index) {
    if (index >= 0 && index < _legalAdvisorControllers.length) {
      _legalAdvisorControllers[index].dispose();
      _legalAdvisorControllers.removeAt(index);
      _safeSetState(() {});
    }
  }

  List<String> _getLegalAdvisors() => _legalAdvisorControllers
      .map((c) => c.text.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  // ==================== RERA NUMBERS ====================
  void _addReraNumber() {
    _reraNumberControllers.add(TextEditingController());
    _safeSetState(() {});
  }

  void _removeReraNumber(int index) {
    if (index >= 0 && index < _reraNumberControllers.length) {
      _reraNumberControllers[index].dispose();
      _reraNumberControllers.removeAt(index);
      _safeSetState(() {});
    }
  }

  List<String> _getReraNumbers() => _reraNumberControllers
      .map((c) => c.text.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  // ==================== RERA ADDITIONAL URLS ====================
  void _addReraAdditionalUrl() {
    _reraAdditionalUrlControllers.add(TextEditingController());
    _safeSetState(() {});
  }

  void _removeReraAdditionalUrl(int index) {
    if (index >= 0 && index < _reraAdditionalUrlControllers.length) {
      _reraAdditionalUrlControllers[index].dispose();
      _reraAdditionalUrlControllers.removeAt(index);
      _safeSetState(() {});
    }
  }

  List<String> _getReraAdditionalUrls() => _reraAdditionalUrlControllers
      .map((c) => c.text.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  // ==================== FEATURES ====================
  void _addFeature() {
    _featureControllers.add({
      'key': TextEditingController(),
      'value': TextEditingController(),
    });
    _safeSetState(() {});
  }

  void _removeFeature(int index) {
    if (index >= 0 && index < _featureControllers.length) {
      _featureControllers[index]['key']?.dispose();
      _featureControllers[index]['value']?.dispose();
      _featureControllers.removeAt(index);
      _safeSetState(() {});
    }
  }

  Map<String, dynamic> _getFeatures() {
    final Map<String, dynamic> features = {};
    for (var item in _featureControllers) {
      final key = (item['key'] as TextEditingController).text.trim();
      final value = (item['value'] as TextEditingController).text.trim();
      if (key.isNotEmpty && value.isNotEmpty) features[key] = value;
    }

    final advisors = _getLegalAdvisors();
    if (advisors.isNotEmpty) {
      features['Legal Advisors'] = advisors.join(', ');
    }

    return features;
  }

  // ==================== WINGS ====================
  void _addWing() {
    final id = _nextWingId++;
    _wingControllers[id] = {
      'floorNumber': TextEditingController(),  // ✅ ADD THIS
      'name': TextEditingController(),
      'units': TextEditingController(),
      'availableUnits': TextEditingController(),
    };
    _safeSetState(() {});
  }

  void _removeWing(int id) {
    if (_wingControllers.containsKey(id)) {
      final ctrl = _wingControllers[id]!;
      for (var c in ctrl.values) {
        if (c is TextEditingController) c.dispose();
      }
      _wingControllers.remove(id);
      _safeSetState(() {});
    }
  }

  List<Floor> _getFloors() {
    final result = <Floor>[];
    for (final c in _wingControllers.values) {
      final floorNumber = int.tryParse(
          (c['floorNumber'] as TextEditingController).text.trim()) ??
          0;
      final name = (c['name'] as TextEditingController).text.trim();
      final units = int.tryParse(
          (c['units'] as TextEditingController).text.trim()) ??
          0;
      final available = int.tryParse(
          (c['availableUnits'] as TextEditingController).text.trim()) ??
          0;

      // ✅ Skip if floorNumber <= 0 AND everything else is empty
      if (floorNumber <= 0 && name.isEmpty && units == 0 && available == 0) {
        continue;
      }

      result.add(Floor(
        floorNumber: floorNumber,
        floorName: name,
        totalUnits: units,
        availableUnits: available,
      ));
    }
    return result;
  }

  // ==================== PRICING SLABS ====================
  void _addPricingSlab() {
    final id = _nextPricingSlabId++;
    _pricingSlabControllers[id] = {
      'floor': TextEditingController(),
      'flatType': TextEditingController(),
      'basePrice': TextEditingController(),
      'pricePerSqft': TextEditingController(),
      'bookingAmount': TextEditingController(),
      'discountPercentage': TextEditingController(),
      'gstPercentage': TextEditingController(),
      'paymentSchedule': <Map<String, TextEditingController>>[],
      'additionalCharges': <Map<String, TextEditingController>>[],
      'isAvailable': true,
    };
    _safeSetState(() {});
  }

  void _removePricingSlab(int id) {
    if (_pricingSlabControllers.containsKey(id)) {
      final ctrl = _pricingSlabControllers[id]!;
      for (var c in ctrl.values) {
        if (c is TextEditingController) {
          c.dispose();
        } else if (c is List<Map<String, TextEditingController>>) {
          for (var row in c) {
            row['key']?.dispose();
            row['value']?.dispose();
          }
        }
      }
      _pricingSlabControllers.remove(id);
      _safeSetState(() {});
    }
  }

  void _addJsonRow(List<Map<String, TextEditingController>> list) {
    list.add({
      'key': TextEditingController(),
      'value': TextEditingController(),
    });
    _safeSetState(() {});
  }

  void _removeJsonRow(List<Map<String, TextEditingController>> list, int index) {
    if (index >= 0 && index < list.length) {
      list[index]['key']?.dispose();
      list[index]['value']?.dispose();
      list.removeAt(index);
      _safeSetState(() {});
    }
  }

  List<PricingSlab> _getPricingSlabs() {
    final List<PricingSlab> result = [];
    for (var entry in _pricingSlabControllers.entries) {
      final c = entry.value;
      final floor =
          int.tryParse((c['floor'] as TextEditingController).text.trim()) ?? 0;
      final flatType = (c['flatType'] as TextEditingController).text.trim();
      final basePrice = (c['basePrice'] as TextEditingController).text.trim();

      // ✅ FIX: Skip if floor is 0 (not selected) OR flatType/basePrice empty
      if (floor <= 0) continue;
      if (flatType.isEmpty || basePrice.isEmpty) continue;

      final paymentSchedule = <String, dynamic>{};
      for (var row
      in (c['paymentSchedule'] as List<Map<String, TextEditingController>>)) {
        final k = row['key']!.text.trim();
        final v = row['value']!.text.trim();
        if (k.isNotEmpty && v.isNotEmpty) paymentSchedule[k] = v;
      }

      final additionalCharges = <String, dynamic>{};
      for (var row
      in (c['additionalCharges'] as List<Map<String, TextEditingController>>)) {
        final k = row['key']!.text.trim();
        final v = row['value']!.text.trim();
        if (k.isNotEmpty && v.isNotEmpty) additionalCharges[k] = v;
      }

      result.add(PricingSlab(
        floor: floor,
        flatType: flatType,
        basePrice: _formatDecimal(basePrice),
        pricePerSqft: _formatDecimal(
            (c['pricePerSqft'] as TextEditingController).text.trim()),
        bookingAmount: _formatDecimal(
            (c['bookingAmount'] as TextEditingController).text.trim()),
        discountPercentage: _formatDecimal(
            (c['discountPercentage'] as TextEditingController).text.trim()),
        gstPercentage: _formatDecimal(
            (c['gstPercentage'] as TextEditingController).text.trim()),
        paymentSchedule: paymentSchedule.isEmpty ? null : paymentSchedule,
        additionalCharges: additionalCharges.isEmpty ? null : additionalCharges,
        isAvailable: c['isAvailable'] ?? true,
      ));
    }
    return result;
  }

  // ==================== FLAT TYPES ====================
  List<FlatType> _getFlatTypes() {
    final List<FlatType> result = [];
    for (var entry in _flatTypes.values) {
      final c = entry;
      final flatType = c['flatType'] as String;  // ✅ आता flatType field मधून
      final areaSqft = (c['areaSqft'] as TextEditingController).text.trim();
      final count = int.tryParse((c['count'] as TextEditingController).text.trim()) ?? 0;
      if (areaSqft.isEmpty && count == 0) continue;
      result.add(FlatType(
        flatType: flatType,
        areaSqft: areaSqft.isEmpty ? '0' : _formatDecimal(areaSqft),
        carpetArea: _formatDecimal((c['carpetArea'] as TextEditingController).text.trim()),
        builtUpArea: null,
        balconyArea: _formatDecimal((c['balconyArea'] as TextEditingController).text.trim()),
        bedrooms: int.tryParse((c['bedrooms'] as TextEditingController).text.trim()) ?? 0,
        bathrooms: int.tryParse((c['bathrooms'] as TextEditingController).text.trim()) ?? 0,
        balconies: int.tryParse((c['balconies'] as TextEditingController).text.trim()) ?? 0,
        kitchens: int.tryParse((c['kitchens'] as TextEditingController).text.trim()) ?? 0,
        parkingCount: int.tryParse((c['parkingCount'] as TextEditingController).text.trim()) ?? 0,
        description: '',
        isAvailable: true,
      ));
    }
    return result;
  }

  // ==================== MEDIA PICKERS ====================
  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
      if (result == null) return;
      for (var file in result.files) {
        if (file.bytes != null) {
          _images.add(SelectedMedia(
            file: MediaFile(
              name: file.name,
              bytes: file.bytes!,
              mimeType: _getMimeType(file.name),
              size: file.size,
            ),
            isSelected: true,
          ));
        }
      }
      _safeSetState(() {});
    } catch (e) {
      _showError('Failed to pick images: $e');
    }
  }

  Future<void> _pickVideos() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
        withData: true,
      );
      if (result == null) return;
      for (var file in result.files) {
        if (file.bytes != null) {
          _videos.add(SelectedMedia(
            file: MediaFile(
              name: file.name,
              bytes: file.bytes!,
              mimeType: _getMimeType(file.name),
              size: file.size,
            ),
            isSelected: true,
          ));
        }
      }
      _safeSetState(() {});
    } catch (e) {
      _showError('Failed to pick videos: $e');
    }
  }

  Future<void> _pickDocuments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
        allowMultiple: true,
        withData: true,
      );
      if (result == null) return;
      for (var file in result.files) {
        if (file.bytes != null) {
          _documents.add(MediaFile(
            name: file.name,
            bytes: file.bytes!,
            mimeType: _getMimeType(file.name),
            size: file.size,
          ));
        }
      }
      _safeSetState(() {});
    } catch (e) {
      _showError('Failed to pick documents: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ==================== POSSESSION DATE ====================
  Future<void> _pickPossessionDate() async {
    final now = DateTime.now();
    DateTime initialDate = now;

    final existing = _possessionDateController.text.trim();
    if (existing.isNotEmpty) {
      final parsed = _parseDdMmYyyy(existing);
      if (parsed != null && parsed.isAfter(now.subtract(const Duration(days: 1)))) {
        initialDate = parsed;
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: DateTime(now.year + 30, 12, 31),
      helpText: 'Select Possession Date',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: kPrimary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
      _safeSetState(() => _possessionDateController.text = formatted);
    }
  }

  // ==================== PINCODE AUTO-FILL ====================
  Future<void> _autoFillPincodeFromLocation() async {
    _safeSetState(() => _isFetchingPincode = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showError('Location services are disabled. Please enable them.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permission denied.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showError('Location permission permanently denied. Open settings.');
        await Geolocator.openAppSettings();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 20),
      );

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isEmpty) {
        _showError('Could not determine your address.');
        return;
      }

      final place = placemarks.first;

      _safeSetState(() {
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          _pincodeController.text = place.postalCode!;
        }
        if (_cityController.text.trim().isEmpty &&
            place.locality != null && place.locality!.isNotEmpty) {
          _cityController.text = place.locality!;
        }
        if (_areaController.text.trim().isEmpty &&
            place.subLocality != null && place.subLocality!.isNotEmpty) {
          _areaController.text = place.subLocality!;
        }
        if (_addressController.text.trim().isEmpty) {
          final addr = [
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
            place.postalCode,
          ].where((s) => s != null && s.isNotEmpty).join(', ');
          if (addr.isNotEmpty) _addressController.text = addr;
        }
        if (_latitudeController.text.trim().isEmpty) {
          _latitudeController.text = _formatDecimal(position.latitude.toString());
        }
        if (_longitudeController.text.trim().isEmpty) {
          _longitudeController.text = _formatDecimal(position.longitude.toString());
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Location fetched successfully!'),
            backgroundColor: kSuccess,
          ),
        );
      }
    } catch (e) {
      _showError('Failed to fetch location: $e');
    } finally {
      if (mounted) _safeSetState(() => _isFetchingPincode = false);
    }
  }

  // ==================== SUBMIT ====================
  Future<void> _submitForm() async {
    _backendErrors.clear();

    final isValid = _formKey.currentState!.validate();

    if (!isValid) {
      final firstInvalid = _findFirstInvalidField();
      if (firstInvalid != null) {
        final label = _labelForField(firstInvalid);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please fill $label',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange.shade800,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          );
        }

        _focusOnField(firstInvalid);
      }
      return;
    }

    if (_isBuilderRequired && _selectedBuilderId == null) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please select a builder',
                  style: TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      _focusOnField('builder');
      return;
    }

    _safeSetState(() => _isLoading = true);

    try {
      final selectedImages =
      _images.where((m) => m.isSelected).map((m) => m.file).toList();
      final selectedVideos =
      _videos.where((m) => m.isSelected).map((m) => m.file).toList();

      final request = PropertyCreateRequest(
        title: _projectNameController.text.trim().isNotEmpty
            ? _projectNameController.text.trim()
            : _companyNameController.text.trim(),
        description: _descriptionController.text.trim(),
        propertyType: _selectedPropertyType,
        transactionType: _selectedTransactionType,
        status: _selectedStatus,
        source: _selectedSource,  // ✅ ADD THIS LINE
        marketingPartner: _marketingPartnerId,
        city: _cityController.text.trim(),
        area: _areaController.text.trim(),
        address: _addressController.text.trim(),
        landmark: _landmarkController.text.trim().isEmpty
            ? null
            : _landmarkController.text.trim(),
        pincode: _pincodeController.text.trim().isEmpty
            ? null
            : _pincodeController.text.trim(),
        latitude: _latitudeController.text.trim().isEmpty
            ? null
            : _formatDecimal(_latitudeController.text.trim()),
        longitude: _longitudeController.text.trim().isEmpty
            ? null
            : _formatDecimal(_longitudeController.text.trim()),
        googleLocationUrl: _googleLocationUrlController.text.trim().isEmpty
            ? null
            : _googleLocationUrlController.text.trim(),
        totalArea: _totalAreaController.text.trim().isEmpty
            ? null
            : _formatDecimal(_totalAreaController.text.trim()),
        plotArea: _plotAreaController.text.trim().isEmpty
            ? null
            : _formatDecimal(_plotAreaController.text.trim()),
        totalFloors: int.tryParse(_totalFloorsController.text.trim()),
        totalTowers: int.tryParse(_totalTowersController.text.trim()),
        builder: _selectedBuilderId,
        amenities: _selectedAmenityIds.isNotEmpty ? _selectedAmenityIds : null,
        reraNumber:
        _getReraNumbers().isNotEmpty ? _getReraNumbers().join(', ') : null,
        reraQrCode: _reraQrCodeController.text.trim().isEmpty
            ? null
            : _reraQrCodeController.text.trim(),
        reraWebsite: _reraWebsiteController.text.trim().isEmpty
            ? null
            : _reraWebsiteController.text.trim(),
        reraAdditionalUrls:
        _getReraAdditionalUrls().isNotEmpty ? _getReraAdditionalUrls() : null,
        propertyWebsiteUrl: _propertyWebsiteUrlController.text.trim().isEmpty
            ? null
            : _propertyWebsiteUrlController.text.trim(),
        isUnderConstruction: _isUnderConstruction,
        possessionDate: _possessionDateController.text.trim().isEmpty
            ? null
            : _ddMmYyyyToIso(_possessionDateController.text.trim()) ??
            _possessionDateController.text.trim(),
        completionPercentage:
        int.tryParse(_completionPercentageController.text.trim()),
        isFeatured: _isFeatured,
        isVerified: _isVerified,
        isNegotiable: _isNegotiable,
        features: _getFeatures().isNotEmpty ? _getFeatures() : null,
        flatTypes: _getFlatTypes().isNotEmpty ? _getFlatTypes() : null,
        floors: _getFloors().isNotEmpty ? _getFloors() : null,
        pricingSlabs: _getPricingSlabs().isNotEmpty ? _getPricingSlabs() : null,
        images: selectedImages.isNotEmpty ? selectedImages : null,
        videos: selectedVideos.isNotEmpty ? selectedVideos : null,
        documents: _documents.isNotEmpty ? _documents : null,
      );

      final response = await _propertyService.createProperty(request);

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response.message), backgroundColor: kSuccess),
        );
        _clearForm();
        _showSuccessDialog(response);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );

        final errs = response.errors;
        if (errs != null && errs.isNotEmpty) {
          _safeSetState(() {
            errs.forEach((key, messages) {
              if (messages.isNotEmpty) {
                if (key == 'rera_number') {
                  _backendErrors['rera_number_0'] = _cleanError(messages.first);
                } else {
                  _backendErrors[key] = _cleanError(messages.first);
                }
              }
            });
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _backendErrors.forEach((key, _) {
              _fieldKeys[key]?.currentState?.validate();
            });
            final firstErr = _backendErrors.keys.firstOrNull;
            if (firstErr != null) _focusOnField(firstErr);
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5)),
      );
    } finally {
      if (mounted) _safeSetState(() => _isLoading = false);
    }


    // In _submitForm(), before creating request:
    final invalidPricingSlabs = _pricingSlabControllers.values.where((c) {
      final floor = int.tryParse((c['floor'] as TextEditingController).text.trim()) ?? 0;
      final flatType = (c['flatType'] as TextEditingController).text.trim();
      final basePrice = (c['basePrice'] as TextEditingController).text.trim();
      // If user filled flatType & basePrice but didn't select floor
      return floor <= 0 && flatType.isNotEmpty && basePrice.isNotEmpty;
    }).toList();

    if (invalidPricingSlabs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please select Floor for all Pricing Slabs',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
  }

  void _clearForm() {
    _companyNameController.clear();
    _projectNameController.clear();
    _descriptionController.clear();
    _cityController.clear();
    _areaController.clear();
    _addressController.clear();
    _landmarkController.clear();
    _pincodeController.clear();
    _latitudeController.clear();
    _longitudeController.clear();
    _googleLocationUrlController.clear();
    _totalAreaController.clear();
    _plotAreaController.clear();
    _totalFloorsController.clear();
    _totalTowersController.clear();
    _possessionDateController.clear();
    _completionPercentageController.clear();
    _reraQrCodeController.clear();
    _reraWebsiteController.clear();
    _propertyWebsiteUrlController.clear();

    _selectedBuilderId = null;
    _selectedBuilderName = '';
    _pdfBuilderForCreate = null;
    _pendingBuilderMatch = null;
    _selectedPropertyType = 'flat';
    _selectedTransactionType = 'sale';
    _selectedStatus = 'draft';
    _selectedSource = 'admin';  // ✅ ADD THIS LINE
    _isUnderConstruction = true;
    _isReadyToMove = false;
    _isFeatured = false;
    _isVerified = false;
    _isNegotiable = true;

    for (var entry in _flatTypes.values) {
      for (var c in entry.values) {
        if (c is TextEditingController) c.dispose();
      }
    }
    _flatTypes.clear();

    for (final ctrl in _wingControllers.values) {
      for (final c in ctrl.values) {
        if (c is TextEditingController) c.dispose();
      }
    }
    _wingControllers.clear();

    for (final ctrl in _pricingSlabControllers.values) {
      for (final c in ctrl.values) {
        if (c is TextEditingController) {
          c.dispose();
        } else if (c is List<Map<String, TextEditingController>>) {
          for (var row in c) {
            row['key']?.dispose();
            row['value']?.dispose();
          }
        }
      }
    }
    _pricingSlabControllers.clear();
    _nextWingId = 0;
    _nextPricingSlabId = 0;
    _selectedAmenityIds.clear();

    for (var c in _reraNumberControllers) {
      c.dispose();
    }
    _reraNumberControllers.clear();
    _reraNumberControllers.add(TextEditingController());

    for (var c in _reraAdditionalUrlControllers) {
      c.dispose();
    }
    _reraAdditionalUrlControllers.clear();

    for (var c in _legalAdvisorControllers) {
      c.dispose();
    }
    _legalAdvisorControllers.clear();
    _legalAdvisorControllers.add(TextEditingController());

    for (var feature in _featureControllers) {
      feature['key']?.dispose();
      feature['value']?.dispose();
    }
    _featureControllers.clear();

    _images.clear();
    _videos.clear();
    _documents.clear();
    _backendErrors.clear();

    _safeSetState(() {});
  }

  void _showSuccessDialog(PropertyCreateResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: kSuccess),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Property Created Successfully',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (response.data != null) ...[
                _buildDetailRow('ID', response.data!.id.toString()),
                _buildDetailRow('Company', response.data!.title),
                _buildDetailRow('Type', response.data!.propertyType),
                _buildDetailRow('Transaction', response.data!.transactionType),
                _buildDetailRow('Status', response.data!.status),
                _buildDetailRow('City', response.data!.city),
                _buildDetailRow('Area', response.data!.area),
                _buildDetailRow(
                    'Builder',
                    _selectedBuilderName.isNotEmpty
                        ? _selectedBuilderName
                        : 'N/A'),
                if (response.data!.reraNumber != null)
                  _buildDetailRow('RERA No', response.data!.reraNumber!),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: kSuccess, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(response.message,
                          style: TextStyle(
                              fontSize: 12,
                              color: kSuccess,
                              fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK', style: TextStyle(color: kPrimary))),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: Colors.grey)),
          ),
          Expanded(
              child: Text(value,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  // ==================== FIELD LABEL (screenshot style) ====================
  Widget _fieldLabel(String text, {bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: kTextPrimary,
          ),
          children: [
            if (required)
              TextSpan(
                text: ' *',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==================== SCREENSHOT-STYLE TEXT FIELD ====================
  Widget _ssTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    String? fieldName,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    Widget? prefixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    String? Function(String?)? validator,
  }) {
    final formFieldKey = fieldName != null ? _keyFor(fieldName) : null;
    final widgetKey = fieldName != null ? _widgetKeyFor(fieldName) : null;
    final focusNode = fieldName != null ? _focusFor(fieldName) : null;

    return Container(
      key: widgetKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _fieldLabel(label, required: required),
          TextFormField(
            key: formFieldKey,
            controller: controller,
            focusNode: focusNode,
            maxLines: maxLines,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            readOnly: readOnly,
            onTap: onTap,
            validator: (v) {
              if (fieldName != null && _backendErrors.containsKey(fieldName)) {
                return _backendErrors[fieldName];
              }
              if (validator != null) return validator(v);
              if (required && (v == null || v.isEmpty)) return 'Required';
              return null;
            },
            onChanged: (val) {
              if (fieldName != null && _backendErrors.containsKey(fieldName)) {
                _safeSetState(() => _backendErrors.remove(fieldName));
              }
            },
            style: TextStyle(
                fontSize: 14,
                color: kTextPrimary,
                fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  fontSize: 13,
                  color: kTextSecondary,
                  fontWeight: FontWeight.normal),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: kPrimary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
              errorStyle: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SCREENSHOT-STYLE DROPDOWN ====================
  Widget _ssDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    bool required = false,
    String Function(String)? displayFn,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label, required: required),
        DropdownButtonFormField<String>(
          value: value,
          isDense: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: kPrimary, width: 1.5),
            ),
          ),
          style: TextStyle(
              fontSize: 14,
              color: kTextPrimary,
              fontWeight: FontWeight.w500),
          items: items
              .map((item) => DropdownMenuItem<String>(
            value: item,
            child: Text(
                displayFn?.call(item) ?? item.replaceAll('_', ' ').toUpperCase()),
          ))
              .toList(),
          onChanged: onChanged,
          validator: required ? (v) => v == null ? 'Required' : null : null,
        ),
      ],
    );
  }

  // ==================== SCREENSHOT-STYLE SECTION CARD ====================
  Widget _ssSectionCard({
    required String title,
    required Widget child,
    Color? accentColor,
    Widget? trailing,
    String? badgeText,
    Color? badgeColor,
  }) {
    final accent = accentColor ?? kPrimary;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: kTextPrimary,
                    ),
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (badgeColor ?? kPrimary).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: badgeColor ?? kPrimary,
                      ),
                    ),
                  ),
                if (trailing != null) ...[
                  const SizedBox(width: 8),
                  trailing,
                ] else if (badgeText == null) ...[
                  Icon(Icons.keyboard_arrow_down,
                      size: 20, color: kTextSecondary),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: kBorder),
          Padding(
            padding: const EdgeInsets.all(18),
            child: child,
          ),
        ],
      ),
    );
  }

  // ==================== SCREENSHOT-STYLE SUBCATEGORY SELECTOR ====================
  Widget _buildSubcategorySelector({required bool isMobile}) {
    final items = [
      ('flat', '🏢', 'Flat / Apt'),
      ('villa', '🏡', 'Villa / Bungalow'),
      ('plot', '📐', 'Plot / Land'),
      ('commercial', '🏢', 'Commercial'),
      ('shop', '🛍️', 'Retail Shop'),
      ('office', '💼', 'Office Space'),
    ];

    return _ssSectionCard(
      title: 'SELECT PROPERTY SUBCATEGORY',
      badgeText: _selectedPropertyType.isNotEmpty
          ? 'Active Configuration: ${_propertyLabel(_selectedPropertyType)} Form (Custom Attributes Enabled)'
          : null,
      badgeColor: kSuccess,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = isMobile
              ? (constraints.maxWidth - 20) / 2
              : (constraints.maxWidth - 50) / 6;
          return Wrap(
            spacing: 10,
            runSpacing: 10,
            children: items.map((item) {
              final selected = _selectedPropertyType == item.$1;
              return SizedBox(
                width: width,
                child: InkWell(
                  onTap: () => _safeSetState(
                          () => _selectedPropertyType = item.$1),
                  borderRadius: BorderRadius.circular(10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected ? kPrimary : kBorder,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(item.$2, style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 6),
                        Text(
                          item.$3,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected ? kPrimary : kTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  String _propertyLabel(String type) {
    switch (type) {
      case 'flat':
        return 'Flat';
      case 'villa':
        return 'Villa';
      case 'plot':
        return 'Plot';
      case 'commercial':
        return 'Commercial';
      case 'shop':
        return 'Shop';
      case 'office':
        return 'Office';
      default:
        return type;
    }
  }

  // ==================== SCREENSHOT-STYLE TRANSACTION STAGE ====================
  Widget _buildTransactionStage() {
    Widget pill(String label, bool selected, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? kPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : kTextPrimary,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('TRANSACTION TYPE:',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: kTextSecondary,
                      letterSpacing: 0.5)),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  pill('Sale', _selectedTransactionType == 'sale',
                          () => _safeSetState(() => _selectedTransactionType = 'sale')),
                  pill('Resale', _selectedTransactionType == 'rent',
                          () => _safeSetState(() => _selectedTransactionType = 'rent')),
                  pill('Rent / Lease', _selectedTransactionType == 'lease',
                          () => _safeSetState(() => _selectedTransactionType = 'lease')),
                ]),
              ),
            ],
          ),
          if (_showConstructionStage)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('CONSTRUCTION STAGE:',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: kTextSecondary,
                        letterSpacing: 0.5)),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    pill('Under Construction', _isUnderConstruction,
                            () => _safeSetState(() {
                          _isUnderConstruction = true;
                          _isReadyToMove = false;
                        })),
                    pill('Ready to Move', _isReadyToMove,
                            () => _safeSetState(() {
                          _isReadyToMove = true;
                          _isUnderConstruction = false;
                        })),
                  ]),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ==================== SCREENSHOT-STYLE AMENITIES ====================
  Widget _buildAmenitiesSection() {
    return _ssSectionCard(
      title: 'Amenities & Lifestyle Perks',
      accentColor: kSuccess,
      badgeText: '${_selectedAmenityIds.length} Selected',
      badgeColor: kPrimary,
      trailing: InkWell(
        onTap: _isAddingAmenity ? null : _showAddAmenityDialog,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: kPrimaryLight,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.add, size: 16, color: kPrimary),
        ),
      ),
      child: FormField<List<int>>(
        key: _keyFor('amenities'),
        initialValue: _selectedAmenityIds,
        validator: (_) {
          if (_backendErrors.containsKey('amenities')) {
            return _backendErrors['amenities'];
          }
          return null;
        },
        builder: (state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Click any chip to toggle amenity inclusion for this listing:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: kTextSecondary,
                ),
              ),
              const SizedBox(height: 14),
              if (_isLoadingAmenities)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: kSuccess),
                        ),
                        const SizedBox(height: 8),
                        Text('Loading amenities...',
                            style: TextStyle(
                                fontSize: 12, color: kTextSecondary)),
                      ],
                    ),
                  ),
                )
              else if (_availableAmenities.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(Icons.category_outlined,
                          size: 36, color: kTextSecondary),
                      const SizedBox(height: 8),
                      Text(
                        'No amenities available',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kTextSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Click "+" to create one',
                        style: TextStyle(
                            fontSize: 11, color: kTextSecondary),
                      ),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableAmenities.map((amenity) {
                    final isSelected =
                    _selectedAmenityIds.contains(amenity.id);
                    return InkWell(
                      onTap: () {
                        _safeSetState(() {
                          if (isSelected) {
                            _selectedAmenityIds.remove(amenity.id);
                          } else {
                            _selectedAmenityIds.add(amenity.id);
                          }
                          _backendErrors.remove('amenities');
                        });
                        state.didChange(_selectedAmenityIds);
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? kPrimaryLight
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? kPrimary : Colors.transparent,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              Icon(Icons.check_circle,
                                  size: 14, color: kPrimary),
                              const SizedBox(width: 6),
                            ] else ...[
                              Icon(Icons.add,
                                  size: 14, color: kTextSecondary),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              amenity.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? kPrimary : kTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(state.errorText ?? '',
                      style: const TextStyle(
                          color: Colors.red, fontSize: 12)),
                ),
            ],
          );
        },
      ),
    );
  }

  // ==================== SCREENSHOT-STYLE FLAT TYPE CARD ====================
  Widget _buildFlatTypeCard(int id, Map<String, dynamic> c) {
    final flatType = c['flatType'] as String;
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: kPrimaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(flatType,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: kPrimary)),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _removeFlatType(id),  // ✅ id use करा
                child: Icon(Icons.close, size: 18, color: kTextSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _smallField(c['count'] as TextEditingController, 'Flats Count',
                  'e.g., 40', isMobile, allowDecimal: false),
              _smallField(c['areaSqft'] as TextEditingController,
                  'Area (sq ft)', 'e.g., 1050', isMobile),
              _smallField(c['carpetArea'] as TextEditingController,
                  'Carpet Area', 'e.g., 850', isMobile),
              _smallField(c['balconyArea'] as TextEditingController,
                  'Balcony Area', 'e.g., 50', isMobile),
              _smallField(c['bedrooms'] as TextEditingController,
                  'Bedrooms', 'e.g., 2', isMobile, allowDecimal: false),
              _smallField(c['bathrooms'] as TextEditingController,
                  'Bathrooms', 'e.g., 2', isMobile, allowDecimal: false),
              _smallField(c['balconies'] as TextEditingController,
                  'Balconies', 'e.g., 1', isMobile, allowDecimal: false),
              _smallField(c['kitchens'] as TextEditingController,
                  'Kitchens', 'e.g., 1', isMobile, allowDecimal: false),
              _smallField(c['parkingCount'] as TextEditingController,
                  'Parking', 'e.g., 1', isMobile, allowDecimal: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _smallField(
      TextEditingController ctrl, String label, String hint, bool isMobile,
      {bool allowDecimal = true}) {
    return SizedBox(
      width: isMobile ? (MediaQuery.of(context).size.width - 90) / 2 : 190,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary)),
          ),
          TextFormField(
            controller: ctrl,
            keyboardType: allowDecimal
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.number,
            inputFormatters: allowDecimal
                ? [DecimalTextInputFormatter(decimalRange: 2)]
                : [FilteringTextInputFormatter.digitsOnly],
            style: TextStyle(
                fontSize: 13,
                color: kTextPrimary,
                fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  fontSize: 12,
                  color: kTextSecondary,
                  fontWeight: FontWeight.normal),
              filled: true,
              fillColor: Colors.white,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: kBorder)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: kBorder)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: kPrimary, width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SCREENSHOT-STYLE WING CARD ====================
  Widget _buildWingCard(int id, Map<String, dynamic> ctrl) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================== HEADER: FLOOR #1 + Remove Button ====================
          Row(
            children: [
              Text(
                'FLOOR #${id + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: kTextPrimary,
                  letterSpacing: 0.8,
                ),
              ),
              const Spacer(),
              // Remove Button (screenshot सारखा)
              OutlinedButton.icon(
                onPressed: () => _removeWing(id),
                icon: const Icon(Icons.delete_outline, size: 14),
                label: const Text('Remove', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Divider line (screenshot सारखी)
          Divider(height: 1, color: kBorder),
          const SizedBox(height: 16),

          // ==================== 4 FIELDS ROW ====================
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              // ✅ 1. FLOOR NUMBER
              SizedBox(
                width: isMobile
                    ? (MediaQuery.of(context).size.width - 90) / 2
                    : 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Floor Number',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kTextPrimary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: ctrl['floorNumber'] as TextEditingController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                            fontSize: 13,
                            color: kTextSecondary,
                            fontWeight: FontWeight.normal),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: kBorder)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: kBorder)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: kPrimary, width: 1.5)),
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ 2. FLOOR NAME
              SizedBox(
                width: isMobile
                    ? (MediaQuery.of(context).size.width - 90) / 2
                    : 220,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Floor Name',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kTextPrimary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: ctrl['name'] as TextEditingController,
                      decoration: InputDecoration(
                        hintText: 'e.g. First Floor',
                        hintStyle: TextStyle(
                            fontSize: 13,
                            color: kTextSecondary,
                            fontWeight: FontWeight.normal),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: kBorder)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: kBorder)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: kPrimary, width: 1.5)),
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ 3. TOTAL UNITS
              SizedBox(
                width: isMobile
                    ? (MediaQuery.of(context).size.width - 90) / 2
                    : 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Units',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kTextPrimary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: ctrl['units'] as TextEditingController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                            fontSize: 13,
                            color: kTextSecondary,
                            fontWeight: FontWeight.normal),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: kBorder)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: kBorder)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: kPrimary, width: 1.5)),
                      ),
                    ),
                  ],
                ),
              ),

              // ✅ 4. AVAILABLE UNITS
              SizedBox(
                width: isMobile
                    ? (MediaQuery.of(context).size.width - 90) / 2
                    : 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Available Units',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kTextPrimary)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: ctrl['availableUnits'] as TextEditingController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                            fontSize: 13,
                            color: kTextSecondary,
                            fontWeight: FontWeight.normal),
                        filled: true,
                        fillColor: Colors.white,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: kBorder)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: kBorder)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: kPrimary, width: 1.5)),
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

  // ==================== SCREENSHOT-STYLE PRICING SLAB CARD ====================
  Widget _buildPricingSlabCard(int id, Map<String, dynamic> ctrl) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Pricing Slab ${id + 1}',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: kTextPrimary)),
              ),
              InkWell(
                onTap: () => _removePricingSlab(id),
                child: Icon(Icons.close, size: 18, color: kTextSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // ✅ ADD THIS - FLOOR FIELD (Dropdown of available floors)
              _buildFloorDropdownForPricing(ctrl, isMobile),

              _smallField(ctrl['flatType'] as TextEditingController,
                  'Flat Type', 'e.g., 2 BHK', isMobile,
                  allowDecimal: false),
              _smallField(ctrl['basePrice'] as TextEditingController,
                  'Total Expected Sale Price', 'e.g., 4850000', isMobile),
              _smallField(ctrl['pricePerSqft'] as TextEditingController,
                  'Base Price / sq.ft', 'e.g., 12597', isMobile),
              _smallField(ctrl['bookingAmount'] as TextEditingController,
                  'Booking Token Amount', 'e.g., 500000', isMobile),
              _smallField(ctrl['discountPercentage'] as TextEditingController,
                  'Discount %', '', isMobile),
            ],
          ),
          const SizedBox(height: 16),

          _buildJsonKeyValueSection(
            title: 'Payment Schedule',
            items: ctrl['paymentSchedule'] as List<Map<String, TextEditingController>>,
            onAdd: () => _addJsonRow(ctrl['paymentSchedule']),
            onRemove: (i) => _removeJsonRow(ctrl['paymentSchedule'], i),
            keyHint: 'e.g., Booking',
            valueHint: 'e.g., 10%',
          ),
          const SizedBox(height: 12),

          _buildJsonKeyValueSection(
            title: 'Additional Charges',
            items: ctrl['additionalCharges'] as List<Map<String, TextEditingController>>,
            onAdd: () => _addJsonRow(ctrl['additionalCharges']),
            onRemove: (i) => _removeJsonRow(ctrl['additionalCharges'], i),
            keyHint: 'e.g., Maintenance',
            valueHint: 'e.g., 5000',
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Text('Available:',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary)),
              const SizedBox(width: 8),
              Switch(
                value: ctrl['isAvailable'] ?? true,
                onChanged: (val) =>
                    _safeSetState(() => ctrl['isAvailable'] = val),
                activeColor: kPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== FLOOR DROPDOWN FOR PRICING SLAB ====================
  Widget _buildFloorDropdownForPricing(
      Map<String, dynamic> ctrl, bool isMobile) {
    // Get available floors from _wingControllers
    final floors = _getFloors();

    // Current selected floor number
    final currentText = (ctrl['floor'] as TextEditingController).text.trim();
    final currentFloor = int.tryParse(currentText);

    // Valid floor numbers list
    final List<int> floorNumbers = floors
        .map((f) => f.floorNumber)
        .where((n) => n > 0)
        .toSet()
        .toList()
      ..sort();

    return SizedBox(
      width: isMobile
          ? (MediaQuery.of(context).size.width - 90) / 2
          : 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Floor',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: kTextPrimary)),
          const SizedBox(height: 6),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: (currentFloor != null && floorNumbers.contains(currentFloor))
                    ? currentFloor
                    : null,
                hint: Text(
                  floorNumbers.isEmpty
                      ? 'Add floor first'
                      : 'Select floor',
                  style: TextStyle(
                      fontSize: 13,
                      color: kTextSecondary,
                      fontWeight: FontWeight.normal),
                ),
                isExpanded: true,
                icon: Icon(Icons.arrow_drop_down, color: kTextSecondary, size: 20),
                style: TextStyle(
                    fontSize: 13,
                    color: kTextPrimary,
                    fontWeight: FontWeight.w500),
                onChanged: floorNumbers.isEmpty
                    ? null
                    : (int? val) {
                  if (val != null) {
                    (ctrl['floor'] as TextEditingController).text =
                        val.toString();
                    _safeSetState(() {});
                  }
                },
                items: floorNumbers.map((n) {
                  // Find floor name for better UX
                  final floorObj = floors.firstWhere(
                        (f) => f.floorNumber == n,
                    orElse: () => Floor(
                      floorNumber: n,
                      floorName: '',
                      totalUnits: 0,
                      availableUnits: 0,
                    ),
                  );
                  final label = floorObj.floorName.isNotEmpty
                      ? 'Floor $n - ${floorObj.floorName}'
                      : 'Floor $n';
                  return DropdownMenuItem<int>(
                    value: n,
                    child: Text(label),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJsonKeyValueSection({
    required String title,
    required List<Map<String, TextEditingController>> items,
    required VoidCallback onAdd,
    required void Function(int) onRemove,
    required String keyHint,
    required String valueHint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: kTextPrimary),
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Add', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(
                foregroundColor: kPrimary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
              ),
            ),
          ],
        ),
        if (items.isEmpty)
          Text(
            'No $title entries',
            style: TextStyle(fontSize: 11, color: kTextSecondary),
          )
        else
          ...items.asMap().entries.map((e) {
            final i = e.key;
            final row = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: row['key'],
                      style: TextStyle(
                          fontSize: 12, color: kTextPrimary),
                      decoration: InputDecoration(
                        hintText: keyHint,
                        hintStyle: TextStyle(
                            fontSize: 12, color: kTextSecondary),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: kBorder)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: kBorder)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: kPrimary, width: 1.5)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextFormField(
                      controller: row['value'],
                      style: TextStyle(
                          fontSize: 12, color: kTextPrimary),
                      decoration: InputDecoration(
                        hintText: valueHint,
                        hintStyle: TextStyle(
                            fontSize: 12, color: kTextSecondary),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: kBorder)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: kBorder)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: kPrimary, width: 1.5)),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close,
                        color: Colors.red, size: 16),
                    onPressed: () => onRemove(i),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  // ==================== PROPERTY SUBCATEGORY FORM ====================
// ==================== PROPERTY SUBCATEGORY FORM ====================
  Widget _buildPropertySpecificSection({required bool isMobile}) {
    final type = _selectedPropertyType;
    final showArea = type != 'plot';
    final showPlotArea = type == 'villa' || type == 'flat' || type == 'plot';
    final showFloors =
        type == 'flat' || type == 'villa' || type == 'commercial' || type == 'office' || type == 'shop';
    final showTowers = type == 'flat' || type == 'commercial' || type == 'office';
    final showFlatTypes = type == 'flat' || type == 'villa';
    final showWings = type == 'flat' || type == 'commercial' || type == 'office';

    String sectionTitle;
    switch (type) {
      case 'flat':
        sectionTitle = 'Flat / Apartment Specifications';
        break;
      case 'villa':
        sectionTitle = 'Villa Specifications & Custom Attributes';
        break;
      case 'plot':
        sectionTitle = 'Plot / Land Specifications';
        break;
      case 'commercial':
        sectionTitle = 'Commercial Specifications';
        break;
      case 'shop':
        sectionTitle = 'Retail Shop Specifications';
        break;
      default:
        sectionTitle = 'Office Space Specifications';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ WINGS — ABOVE the specifications section


        // ✅ Specifications section
        _ssSectionCard(
          title: sectionTitle,
          accentColor: kPrimary,
          badgeText: 'DYNAMIC CONTAINER',
          badgeColor: kPrimary,
          child: Column(
            children: [
              _responsiveGrid(
                isMobile: isMobile,
                children: [
                  if (showPlotArea)
                    _ssTextField(
                      controller: _plotAreaController,
                      label: 'Plot / Land Area (sq ft)',
                      hint: 'e.g., 4500',
                      required: false,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [DecimalTextInputFormatter()],
                      fieldName: 'plot_area',
                    ),
                  if (showArea)
                    _ssTextField(
                      controller: _totalAreaController,
                      label: 'Total Built-up Area (sq ft)',
                      hint: 'e.g., 3850',
                      required: false,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [DecimalTextInputFormatter()],
                      fieldName: 'total_area',
                    ),
                  if (showFloors)
                    _ssTextField(
                      controller: _totalFloorsController,
                      label: 'Number of Floors',
                      hint: 'e.g., G + 2 Floors',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      fieldName: 'total_floors',
                    ),
                  if (showTowers)
                    _ssTextField(
                      controller: _totalTowersController,
                      label: 'Number of Towers',
                      hint: 'e.g., 3',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      fieldName: 'total_towers',
                    ),
                ],
              ),
              if (showFlatTypes) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                        child: Text(
                          'BHK / Unit Types',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: kTextPrimary),
                        )),
                    _addButtonOutlined('Add Flat Type', _showAddFlatTypeDialog),
                  ],
                ),
                const SizedBox(height: 12),
                if (_flatTypes.isEmpty)
                  _emptyState(
                      'No BHK / unit type added',
                      'Click Add Flat Type to add 1 BHK, 2 BHK, 3 BHK etc.',
                      Icons.home_outlined)
                else
                  ..._flatTypes.entries
                      .map((e) => _buildFlatTypeCard(e.key, e.value)),
              ],

              if (showWings) ...[
                _ssSectionCard(
                  title: 'Floors',                              // ✅ Wings → Floors
                  accentColor: kSuccess,
                  trailing: _addButtonOutlined(
                    'Add Floor',                                 // ✅ Add Wing → Add Floor
                    _addWing,                                    // method name same ठेवा
                    accent: kSuccess,
                  ),
                  child: _wingControllers.isEmpty
                      ? _emptyState(
                      'No floors added',                     // ✅ wings → floors
                      'Click Add Floor to add building floors', // ✅ message update
                      Icons.layers)                          // ✅ icon बदला (layers)
                      : Column(
                      children: _wingControllers.entries
                          .map((e) => _buildWingCard(e.key, e.value))
                          .toList()),
                ),
                const SizedBox(height: 14),
              ],


            ],
          ),
        ),
      ],
    );
  }

  Widget _addButtonOutlined(String label, VoidCallback onPressed,
      {Color? accent}) {
    final a = accent ?? kPrimary;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: a,
        side: BorderSide(color: a, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _emptyState(String title, String subtitle, IconData icon) {
    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: kTextSecondary, size: 30),
          const SizedBox(height: 8),
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: kTextPrimary)),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: kTextSecondary)),
        ],
      ),
    );
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                      isMobile ? 12 : 22, 18, isMobile ? 12 : 22, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSubcategorySelector(isMobile: isMobile),
                      const SizedBox(height: 12),
                      _buildTransactionStage(),
                      const SizedBox(height: 14),

                      // ========== Property Registration Banner ==========
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF8B5CF6),
                              Color(0xFFA855F7),
                              Color(0xFFD946EF),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimary.withOpacity(0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.domain,
                                  color: Colors.white, size: 26),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Property Registration',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800)),
                                  SizedBox(height: 3),
                                  Text(
                                      'Create and publish an authenticated real estate inventory listing for QNX Mart network.',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                            if (!isMobile)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text('Schema v2.4 Active',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ========== Basic Information ==========
                      _ssSectionCard(
                        title: 'Basic Information',
                        child: Column(
                          children: [
                            _responsiveGrid(
                              isMobile: isMobile,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    _fieldLabel(
                                        'Company / Builder Name',
                                        required: _isBuilderRequired),
                                    _buildBuilderDropdown(),
                                  ],
                                ),

                                // ✅ ADD THIS BLOCK - Marketing Partner Field
                                // ✅ Marketing Partner Field (Name only, no ID)
                                if (_marketingPartnerId != null)
                                  Column(
                                    key: _widgetKeyFor('marketing_partner'),
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _fieldLabel('Marketing Partner'),
                                      Container(
                                        height: 48,
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF3E8FF).withOpacity(0.4),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                              color: kPrimary.withOpacity(0.4)),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.handshake,
                                                size: 18, color: kPrimary),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: _isLoadingPartner
                                                  ? Row(
                                                children: [
                                                  SizedBox(
                                                    width: 14,
                                                    height: 14,
                                                    child: CircularProgressIndicator(
                                                        strokeWidth: 2, color: kPrimary),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text('Loading...',
                                                      style: TextStyle(
                                                          fontSize: 13,
                                                          color: kTextSecondary)),
                                                ],
                                              )
                                                  : Text(
                                                _marketingPartnerName.isNotEmpty
                                                    ? _marketingPartnerName
                                                    : 'Partner #$_marketingPartnerId',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: kTextPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            // ❌ ID BADGE REMOVED
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                _ssTextField(
                                  controller: _projectNameController,
                                  label: 'Project Name / Listing Title',
                                  hint: 'e.g., Supreme Rivana Luxury Estate',
                                  required: true,
                                  fieldName: 'project_name',
                                ),
                                _ssDropdown(
                                  label: 'Property Type',
                                  value: _selectedPropertyType,
                                  items: const [
                                    'flat',
                                    'villa',
                                    'plot',
                                    'commercial',
                                    'shop',
                                    'office'
                                  ],
                                  required: true,
                                  displayFn: (v) => v.toUpperCase(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      _safeSetState(() =>
                                      _selectedPropertyType = v);
                                    }
                                  },
                                ),
                                _ssDropdown(
                                  label: 'Transaction Mode',
                                  value: _selectedTransactionType,
                                  items: const ['sale', 'rent', 'lease'],
                                  required: true,
                                  displayFn: (v) => v.toUpperCase(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      _safeSetState(() =>
                                      _selectedTransactionType = v);
                                    }
                                  },
                                ),
                                _ssDropdown(
                                  label: 'Publication Status',
                                  value: _selectedStatus,
                                  items: _statusTypes,
                                  required: true,
                                  displayFn: (v) =>
                                  v == 'draft' ? 'DRAFT' : v.toUpperCase(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      _safeSetState(
                                              () => _selectedStatus = v);
                                    }
                                  },
                                ),
                                // ✅ SOURCE FIELD - Admin only
                                _ssDropdown(
                                  label: 'Source',
                                  value: _selectedSource,
                                  items: _sourceTypes,
                                  required: true,
                                  displayFn: (v) => v.toUpperCase(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      _safeSetState(() => _selectedSource = v);
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _ssTextField(
                              controller: _descriptionController,
                              label: 'Property Description',
                              hint:
                              'Detailed description of the property',
                              required: true,
                              maxLines: 4,
                              fieldName: 'description',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ========== Location Details ==========
                      _ssSectionCard(
                        title: 'Location Details',
                        accentColor: kPrimary,
                        child: Column(
                          children: [
                            _responsiveGrid(
                              isMobile: isMobile,
                              children: [
                                _ssTextField(
                                  controller: _cityController,
                                  label: 'City',
                                  hint: 'e.g., Pune',
                                  required: true,
                                  fieldName: 'city',
                                ),
                                _ssTextField(
                                  controller: _areaController,
                                  label: 'Area / Locality',
                                  hint: 'e.g., Baner - Pashan Link Road',
                                  required: true,
                                  fieldName: 'area',
                                ),
                                _ssTextField(
                                  controller: _landmarkController,
                                  label: 'Landmark',
                                  hint: 'Near Balewadi High Street',
                                  fieldName: 'landmark',
                                ),
                                // Pincode with location button
                                Container(
                                  key: _widgetKeyFor('pincode'),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      _fieldLabel('Pincode',
                                          required: true),
                                      TextFormField(
                                        key: _keyFor('pincode'),
                                        focusNode: _focusFor('pincode'),
                                        controller: _pincodeController,
                                        keyboardType:
                                        TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                          LengthLimitingTextInputFormatter(
                                              6),
                                        ],
                                        validator: (v) {
                                          if (_backendErrors
                                              .containsKey('pincode')) {
                                            return _backendErrors[
                                            'pincode'];
                                          }
                                          if (v == null || v.isEmpty) {
                                            return 'Required';
                                          }
                                          if (v.length != 6) {
                                            return 'Must be 6 digits';
                                          }
                                          return null;
                                        },
                                        onChanged: (val) {
                                          if (_backendErrors
                                              .containsKey('pincode')) {
                                            _safeSetState(() =>
                                                _backendErrors
                                                    .remove('pincode'));
                                          }
                                        },
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: kTextPrimary,
                                            fontWeight: FontWeight.w500),
                                        decoration: InputDecoration(
                                          hintText: '411045',
                                          hintStyle: TextStyle(
                                              fontSize: 13,
                                              color: kTextSecondary,
                                              fontWeight:
                                              FontWeight.normal),
                                          suffixIcon: IconButton(
                                            icon: _isFetchingPincode
                                                ? SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: kPrimary))
                                                : Icon(
                                                Icons.my_location,
                                                color: kPrimary,
                                                size: 18),
                                            tooltip:
                                            'Auto-fill from my location',
                                            onPressed: _isFetchingPincode
                                                ? null
                                                : _autoFillPincodeFromLocation,
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          isDense: true,
                                          contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 14),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                            BorderRadius.circular(8),
                                            borderSide:
                                            BorderSide(color: kBorder),
                                          ),
                                          enabledBorder:
                                          OutlineInputBorder(
                                            borderRadius:
                                            BorderRadius.circular(8),
                                            borderSide:
                                            BorderSide(color: kBorder),
                                          ),
                                          focusedBorder:
                                          OutlineInputBorder(
                                            borderRadius:
                                            BorderRadius.circular(8),
                                            borderSide: BorderSide(
                                                color: kPrimary,
                                                width: 1.5),
                                          ),
                                          errorBorder: OutlineInputBorder(
                                            borderRadius:
                                            BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: Colors.red,
                                                width: 1),
                                          ),
                                          focusedErrorBorder:
                                          OutlineInputBorder(
                                            borderRadius:
                                            BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                                color: Colors.red,
                                                width: 1.5),
                                          ),
                                          errorStyle:
                                          const TextStyle(fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _ssTextField(
                              controller: _addressController,
                              label: 'Complete Address / Plot No.',
                              hint: 'Full property address',
                              required: true,
                              maxLines: 2,
                              fieldName: 'address',
                            ),
                            const SizedBox(height: 12),
                            _responsiveGrid(
                              isMobile: isMobile,
                              children: [
                                _ssTextField(
                                  controller: _latitudeController,
                                  label: 'Latitude',
                                  keyboardType: const TextInputType
                                      .numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    DecimalTextInputFormatter()
                                  ],
                                  fieldName: 'latitude',
                                ),
                                _ssTextField(
                                  controller: _longitudeController,
                                  label: 'Longitude',
                                  keyboardType: const TextInputType
                                      .numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    DecimalTextInputFormatter()
                                  ],
                                  fieldName: 'longitude',
                                ),
                                _ssTextField(
                                  controller: _googleLocationUrlController,
                                  label: 'Google Location URL',
                                  hint: 'https://maps.google.com/...',
                                  fieldName: 'google_location_url',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      _buildPropertySpecificSection(isMobile: isMobile),
                      const SizedBox(height: 14),

                      // ========== RERA Details & Status Flags ==========
                      if (_showReraSection)
                        _ssSectionCard(
                          title: 'RERA Details & Status Flags',
                          accentColor: kSuccess,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // RERA Numbers
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'RERA Registration Numbers',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: kTextPrimary),
                                    ),
                                  ),
                                  _addButtonOutlined(
                                      'Add RERA Number', _addReraNumber),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ..._reraNumberControllers
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final index = entry.key;
                                final controller = entry.value;
                                return Padding(
                                  padding:
                                  const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _ssTextField(
                                          controller: controller,
                                          label: 'RERA Number ${index + 1}',
                                          hint: 'P52100028912',
                                          fieldName:
                                          'rera_number_$index',
                                        ),
                                      ),
                                      if (_reraNumberControllers.length > 1)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 24, left: 4),
                                          child: InkWell(
                                            onTap: () =>
                                                _removeReraNumber(index),
                                            child: Icon(Icons.close,
                                                color: kTextSecondary,
                                                size: 18),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 8),

                              // Legal Advisors
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Legal Advisors / Advocates',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: kTextPrimary),
                                    ),
                                  ),
                                  _addButtonOutlined(
                                      'Add Advisor', _addLegalAdvisor),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ..._legalAdvisorControllers
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final index = entry.key;
                                final controller = entry.value;
                                return Padding(
                                  padding:
                                  const EdgeInsets.only(bottom: 10),
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: _ssTextField(
                                          controller: controller,
                                          label: 'Advisor ${index + 1}',
                                          hint: 'Advocate name',
                                          fieldName:
                                          'legal_advisor_$index',
                                        ),
                                      ),
                                      if (_legalAdvisorControllers.length >
                                          1)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 24, left: 4),
                                          child: InkWell(
                                            onTap: () =>
                                                _removeLegalAdvisor(index),
                                            child: Icon(Icons.close,
                                                color: kTextSecondary,
                                                size: 18),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              const SizedBox(height: 8),

                              _responsiveGrid(
                                isMobile: isMobile,
                                children: [
                                  _ssTextField(
                                    controller: _reraWebsiteController,
                                    label: 'RERA Portal URL',
                                    hint:
                                    'https://maharera.mahaonline.gov.in',
                                    fieldName: 'rera_website',
                                  ),
                                  _ssTextField(
                                    controller: _reraQrCodeController,
                                    label: 'RERA QR Code URL',
                                    hint: 'https://...',
                                    fieldName: 'rera_qr_code',
                                  ),
                                  _ssTextField(
                                    controller:
                                    _propertyWebsiteUrlController,
                                    label: 'Property Website URL',
                                    hint: 'https://...',
                                    fieldName: 'property_website_url',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFAF5FF),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: kPrimary.withOpacity(0.2)),
                                ),
                                child: Column(
                                  children: [
                                    if (_showConstructionStage) ...[
                                      _buildToggleRowSS(
                                          'Under Construction',
                                          _isUnderConstruction,
                                              (v) => _safeSetState(() {
                                            _isUnderConstruction = v;
                                            if (v) _isReadyToMove = false;
                                          })),
                                      _buildToggleRowSS(
                                          'Ready to Move',
                                          _isReadyToMove,
                                              (v) => _safeSetState(() {
                                            _isReadyToMove = v;
                                            if (v)
                                              _isUnderConstruction = false;
                                          })),
                                    ],
                                    _buildToggleRowSS(
                                        'Featured Property Listing',
                                        _isFeatured,
                                            (v) => _safeSetState(
                                                () => _isFeatured = v)),
                                    _buildToggleRowSS(
                                        'Physically Verified Badge',
                                        _isVerified,
                                            (v) => _safeSetState(
                                                () => _isVerified = v)),
                                    _buildToggleRowSS(
                                        'Negotiable',
                                        _isNegotiable,
                                            (v) => _safeSetState(
                                                () => _isNegotiable = v)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              _responsiveGrid(
                                isMobile: isMobile,
                                children: [
                                  if (_showPossessionDate)
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        _fieldLabel('Possession Date'),
                                        TextFormField(
                                          controller:
                                          _possessionDateController,
                                          readOnly: true,
                                          onTap: _pickPossessionDate,
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: kTextPrimary,
                                              fontWeight:
                                              FontWeight.w500),
                                          decoration: InputDecoration(
                                            hintText: 'DD-MM-YYYY',
                                            hintStyle: TextStyle(
                                                fontSize: 13,
                                                color: kTextSecondary,
                                                fontWeight:
                                                FontWeight.normal),
                                            suffixIcon: IconButton(
                                              icon: const Icon(
                                                  Icons.calendar_today,
                                                  size: 16),
                                              onPressed: _pickPossessionDate,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            isDense: true,
                                            contentPadding:
                                            const EdgeInsets
                                                .symmetric(
                                                horizontal: 14,
                                                vertical: 14),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                  color: kBorder),
                                            ),
                                            enabledBorder:
                                            OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                  color: kBorder),
                                            ),
                                            focusedBorder:
                                            OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                  color: kPrimary,
                                                  width: 1.5),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  _ssTextField(
                                    controller:
                                    _completionPercentageController,
                                    label: 'Completion %',
                                    hint: '65',
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter
                                          .digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'RERA Additional URLs',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                          color: kTextPrimary),
                                    ),
                                  ),
                                  _addButtonOutlined(
                                      'Add URL', _addReraAdditionalUrl),
                                ],
                              ),
                              if (_reraAdditionalUrlControllers
                                  .isNotEmpty)
                                ..._reraAdditionalUrlControllers
                                    .asMap()
                                    .entries
                                    .map((e) => Padding(
                                  padding:
                                  const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: e.value,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: kTextPrimary),
                                          decoration: InputDecoration(
                                            hintText: 'https://...',
                                            isDense: true,
                                            contentPadding:
                                            const EdgeInsets
                                                .symmetric(
                                                horizontal: 12,
                                                vertical: 12),
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                BorderRadius.circular(
                                                    8),
                                                borderSide: BorderSide(
                                                    color: kBorder)),
                                            enabledBorder:
                                            OutlineInputBorder(
                                                borderRadius:
                                                BorderRadius.circular(
                                                    8),
                                                borderSide: BorderSide(
                                                    color: kBorder)),
                                            focusedBorder:
                                            OutlineInputBorder(
                                                borderRadius:
                                                BorderRadius.circular(
                                                    8),
                                                borderSide: BorderSide(
                                                    color: kPrimary,
                                                    width: 1.5)),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () =>
                                            _removeReraAdditionalUrl(
                                                e.key),
                                        icon: Icon(Icons.close,
                                            color: kTextSecondary,
                                            size: 18),
                                      ),
                                    ],
                                  ),
                                )),
                            ],
                          ),
                        ),
                      const SizedBox(height: 14),

                      _buildAmenitiesSection(),
                      const SizedBox(height: 14),

                      // ========== Property Features ==========
                      if (_featureControllers.isNotEmpty ||
                          _selectedPropertyType != 'plot')
                        _ssSectionCard(
                          title: 'Property Features',
                          accentColor: kSuccess,
                          trailing: _addButtonOutlined(
                              'Add Feature', _addFeature,
                              accent: kSuccess),
                          child: _featureControllers.isEmpty
                              ? _emptyState(
                              'No custom features added',
                              'PDF features will appear here automatically',
                              Icons.tune)
                              : Column(
                            children: _featureControllers
                                .asMap()
                                .entries
                                .map((entry) {
                              final i = entry.key;
                              final item = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: item['key'],
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: kTextPrimary),
                                        decoration: InputDecoration(
                                          labelText: 'Feature Name',
                                          isDense: true,
                                          contentPadding:
                                          const EdgeInsets
                                              .symmetric(
                                              horizontal: 12,
                                              vertical: 12),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(
                                                  8),
                                              borderSide: BorderSide(
                                                  color: kBorder)),
                                          enabledBorder:
                                          OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(
                                                  8),
                                              borderSide: BorderSide(
                                                  color: kBorder)),
                                          focusedBorder:
                                          OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(
                                                  8),
                                              borderSide: BorderSide(
                                                  color: kPrimary,
                                                  width: 1.5)),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: TextFormField(
                                        controller: item['value'],
                                        style: TextStyle(
                                            fontSize: 13,
                                            color: kTextPrimary),
                                        decoration: InputDecoration(
                                          labelText: 'Value',
                                          isDense: true,
                                          contentPadding:
                                          const EdgeInsets
                                              .symmetric(
                                              horizontal: 12,
                                              vertical: 12),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(
                                                  8),
                                              borderSide: BorderSide(
                                                  color: kBorder)),
                                          enabledBorder:
                                          OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(
                                                  8),
                                              borderSide: BorderSide(
                                                  color: kBorder)),
                                          focusedBorder:
                                          OutlineInputBorder(
                                              borderRadius:
                                              BorderRadius.circular(
                                                  8),
                                              borderSide: BorderSide(
                                                  color: kPrimary,
                                                  width: 1.5)),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _removeFeature(i),
                                      icon: Icon(Icons.close,
                                          color: kTextSecondary,
                                          size: 18),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      const SizedBox(height: 14),

                      _ssSectionCard(
                        title: 'Property Media & Documents',
                        child: _buildMediaSection(),
                      ),
                      const SizedBox(height: 14),

                      _ssSectionCard(
                        title: 'Pricing Slabs',
                        trailing: _addButtonOutlined(
                            'Add Pricing Slab', _addPricingSlab),
                        child: _pricingSlabControllers.isEmpty
                            ? _emptyState(
                            'No pricing slabs added',
                            'PDF pricing slabs will be loaded automatically',
                            Icons.payments_outlined)
                            : Column(
                            children: _pricingSlabControllers.entries
                                .map((e) =>
                                _buildPricingSlabCard(
                                    e.key, e.value))
                                .toList()),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ========== Bottom Action Bar ==========
            Container(
              padding: EdgeInsets.fromLTRB(
                  isMobile ? 12 : 22, 10, isMobile ? 12 : 22, 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: kBorder)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (!isMobile)
                    Expanded(
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 14, color: kTextSecondary),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Fields marked with * are required for listing activation.',
                              style: TextStyle(
                                  fontSize: 11, color: kTextSecondary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isMobile) const Spacer(),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _clearForm,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kTextPrimary,
                      side: BorderSide(color: kBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Reset',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _submitForm,
                    icon: _isLoading
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                        : const Icon(Icons.add, size: 18),
                    label: Text(isMobile ? 'CREATE' : 'CREATE PROPERTY',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 14 : 22, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
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

  Widget _buildToggleRowSS(
      String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary)),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: kPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== BUILDER DROPDOWN ====================
  Widget _buildBuilderDropdown() {
    final isRequired = _isBuilderRequired;

    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _isLoadingBuilders
                  ? Container(
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: kBorder),
                ),
                child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: kPrimary),
                    )),
              )
                  : Autocomplete<BuilderData>(
                // ✅ FIX 1: हे parameter add करा
                displayStringForOption: (BuilderData option) => option.name,

                optionsBuilder: (TextEditingValue value) {
                  if (value.text.isEmpty) return _builders;
                  final q = value.text.toLowerCase();
                  return _builders.where((b) =>
                  b.name.toLowerCase().contains(q) ||
                      (b.email?.toLowerCase().contains(q) ?? false) ||
                      (b.phone?.toLowerCase().contains(q) ?? false));
                },
                onSelected: (BuilderData selected) {
                  _safeSetState(() {
                    _selectedBuilderId = selected.id;
                    _selectedBuilderName = selected.name;
                  });
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                  // ✅ FIX 2: Controller text force set करा
                  if (_selectedBuilderName.isNotEmpty) {
                    if (controller.text.contains('Instance of') ||
                        controller.text.isEmpty ||
                        controller.text != _selectedBuilderName) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _selectedBuilderName.isNotEmpty) {
                          controller.text = _selectedBuilderName;
                          controller.selection =
                              TextSelection.collapsed(
                                offset: _selectedBuilderName.length,
                              );
                        }
                      });
                    }
                  }

                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    onFieldSubmitted: (_) => onFieldSubmitted(),
                    validator: (_) {
                      if (!isRequired) return null;
                      return _selectedBuilderId == null
                          ? 'Please select a builder'
                          : null;
                    },
                    style: TextStyle(
                        fontSize: 14,
                        color: kTextPrimary,
                        fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Select or search builder',
                      hintStyle: TextStyle(
                          fontSize: 13,
                          color: kTextSecondary,
                          fontWeight: FontWeight.normal),
                      suffixIcon: _selectedBuilderId == null
                          ? Icon(Icons.keyboard_arrow_down,
                          color: kTextSecondary, size: 20)
                          : IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          _safeSetState(() {
                            _selectedBuilderId = null;
                            _selectedBuilderName = '';
                            controller.clear();
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                        BorderSide(color: kPrimary, width: 1.5),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                        const BorderSide(color: Colors.red, width: 1),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                        const BorderSide(color: Colors.red, width: 1.5),
                      ),
                      errorStyle: const TextStyle(fontSize: 11),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                            maxHeight: 230, maxWidth: 520),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder: (context, index) {
                            final b = options.elementAt(index);
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                radius: 16,
                                backgroundColor: kPrimaryLight,
                                child: Icon(Icons.business,
                                    size: 16, color: kPrimary),
                              ),
                              title: Text(b.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              subtitle: Text(b.email ?? b.phone ?? '',
                                  style: const TextStyle(fontSize: 11)),
                              onTap: () => onSelected(b),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            height: 48,
            width: 48,
            margin: const EdgeInsets.only(top: 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [kPrimary, kPrimary.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              tooltip: 'Create Builder',
              onPressed: _showCreateBuilderDialog,
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          ),
        ]
    );
  }

  // ==================== CREATE BUILDER POPUP ====================
  Future<void> _showCreateBuilderDialog() async {
    final pre = _pdfBuilderForCreate;
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController(text: pre?.name ?? '');
    final short = TextEditingController(text: pre?.shortInfo ?? '');
    final website = TextEditingController(text: pre?.website ?? '');
    final email = TextEditingController(text: pre?.email ?? '');
    final phone = TextEditingController(text: pre?.phone ?? '');
    bool active = true;
    bool saving = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final width = MediaQuery.of(ctx).size.width;
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: width > 700 ? 650 : width - 28,
                  maxHeight: MediaQuery.of(ctx).size.height * .9),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  colors: [kPrimary, kPrimary.withOpacity(0.7)]),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.business,
                                color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Create Builder',
                                      style: TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w800)),
                                  SizedBox(height: 3),
                                  Text(
                                      'Builder details are auto-filled from PDF when available.',
                                      style: TextStyle(
                                          fontSize: 11, color: Colors.grey)),
                                ]),
                          ),
                          IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _dialogField(name, 'Builder Name *', Icons.business,
                          required: true),
                      const SizedBox(height: 12),
                      _dialogField(short, 'Short Info *', Icons.info_outline,
                          required: true),
                      const SizedBox(height: 12),
                      _dialogField(website, 'Website', Icons.language),
                      const SizedBox(height: 12),
                      _dialogField(email, 'Email', Icons.email,
                          keyboard: TextInputType.emailAddress),
                      const SizedBox(height: 12),
                      _dialogField(phone, 'Phone', Icons.phone,
                          keyboard: TextInputType.phone),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Active Builder',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        value: active,
                        activeColor: kPrimary,
                        onChanged: (v) => setDialogState(() => active = v),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                              onPressed: saving
                                  ? null
                                  : () => Navigator.pop(ctx),
                              child: const Text('Cancel')),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: saving
                                ? null
                                : () async {
                              if (!formKey.currentState!.validate()) return;
                              setDialogState(() => saving = true);
                              try {
                                final response =
                                await _builderService.createBuilder(
                                  name: name.text.trim(),
                                  shortInfo: short.text.trim(),
                                  logoBytes: null,
                                  logoFileName: null,
                                  website: website.text.trim().isEmpty
                                      ? null
                                      : website.text.trim(),
                                  email: email.text.trim().isEmpty
                                      ? null
                                      : email.text.trim(),
                                  phone: phone.text.trim().isEmpty
                                      ? null
                                      : phone.text.trim(),
                                  isActive: active,
                                );
                                if (!mounted) return;
                                if (!response.success) {
                                  setDialogState(() => saving = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content:
                                          Text(response.message),
                                          backgroundColor: Colors.red));
                                  return;
                                }
                                Navigator.pop(ctx);
                                _builders = [];
                                await _loadBuilders();
                                final created = response.data;
                                final createdId =
                                    response.builderId ?? created?.id;
                                if (createdId != null && createdId != 0) {
                                  _safeSetState(() {
                                    _selectedBuilderId = createdId;
                                    _selectedBuilderName =
                                        created?.name ?? name.text.trim();
                                  });
                                }
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(response.message
                                            .isNotEmpty
                                            ? response.message
                                            : 'Builder created successfully'),
                                        backgroundColor: kSuccess));
                              } catch (e) {
                                if (mounted)
                                  setDialogState(() => saving = false);
                                if (mounted)
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                      content: Text(
                                          'Failed to create builder: $e'),
                                      backgroundColor: Colors.red));
                              }
                            },
                            icon: saving
                                ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.check),
                            label: Text(
                                saving ? 'Saving...' : 'Create Builder'),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(10))),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
    name.dispose();
    short.dispose();
    website.dispose();
    email.dispose();
    phone.dispose();
  }

  Widget _dialogField(TextEditingController controller, String label,
      IconData icon,
      {bool required = false, TextInputType? keyboard}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: kPrimary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: kPrimary, width: 1.5)),
      ),
    );
  }

  // ==================== MEDIA SECTION ====================
  Widget _buildMediaSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Property Images',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: kTextPrimary)),
            ),
            _addButtonOutlined('Add Images', _pickImages),
          ],
        ),
        const SizedBox(height: 4),
        Text(
            '${_images.where((m) => m.isSelected).length} / ${_images.length} selected · Tap to select',
            style: TextStyle(fontSize: 11, color: kTextSecondary)),
        const SizedBox(height: 12),
        if (_images.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 130,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _images.length,
            itemBuilder: (context, i) {
              final item = _images[i];
              return _buildImageThumbnail(
                item: item,
                onToggle: () =>
                    _safeSetState(() => item.isSelected = !item.isSelected),
                onRemove: () => _safeSetState(() => _images.removeAt(i)),
              );
            },
          ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: Text('Property Videos',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: kTextPrimary)),
            ),
            _addButtonOutlined('Add Videos', _pickVideos, accent: kSuccess),
          ],
        ),
        const SizedBox(height: 4),
        Text(
            '${_videos.where((m) => m.isSelected).length} / ${_videos.length} selected · Tap to select',
            style: TextStyle(fontSize: 11, color: kTextSecondary)),
        const SizedBox(height: 12),
        if (_videos.isNotEmpty)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 130,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemCount: _videos.length,
            itemBuilder: (context, i) {
              final item = _videos[i];
              return _buildVideoThumbnail(
                item: item,
                onToggle: () =>
                    _safeSetState(() => item.isSelected = !item.isSelected),
                onRemove: () => _safeSetState(() => _videos.removeAt(i)),
              );
            },
          ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: Text('Documents',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: kTextPrimary)),
            ),
            _addButtonOutlined('Add Documents', _pickDocuments),
          ],
        ),
        const SizedBox(height: 4),
        Text('${_documents.length} selected',
            style: TextStyle(fontSize: 11, color: kTextSecondary)),
        const SizedBox(height: 12),
        if (_documents.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _documents.asMap().entries.map((entry) {
              return _buildFileChip(
                name: entry.value.name,
                size: entry.value.size,
                color: kPrimary,
                icon: Icons.description,
                onRemove: () =>
                    _safeSetState(() => _documents.removeAt(entry.key)),
              );
            }).toList(),
          ),
      ],
    );
  }
  void _showImagePreviewDialog(
      SelectedMedia item,
      VoidCallback onToggle,
      VoidCallback onRemove,  // ✅ NEW
      ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.08),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.image, color: kPrimary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.file.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: kTextPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close, size: 22),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),
                    ),

                    // Large Image Preview
                    Flexible(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.memory(
                              item.file.bytes,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 200,
                                    child: Center(
                                      child: Icon(Icons.broken_image,
                                          color: Colors.grey[400], size: 60),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Footer with checkbox toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Checkbox
                          GestureDetector(
                            onTap: () {
                              onToggle();
                              setDialogState(() {});
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: item.isSelected
                                    ? kPrimary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: item.isSelected ? kPrimary : kBorder,
                                  width: 2,
                                ),
                              ),
                              child: item.isSelected
                                  ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                onToggle();
                                setDialogState(() {});
                              },
                              child: Text(
                                item.isSelected
                                    ? 'Selected for upload'
                                    : 'Tap to select this image',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: item.isSelected
                                      ? kPrimary
                                      : kTextSecondary,
                                ),
                              ),
                            ),
                          ),
                          // ✅ Remove button - आता काम करेल
                          TextButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);  // popup बंद
                              onRemove();          // item remove
                            },
                            icon: const Icon(Icons.delete_outline,
                                size: 16, color: Colors.red),
                            label: const Text('Remove',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.red)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildImageThumbnail({
    required SelectedMedia item,
    required VoidCallback onToggle,
    required VoidCallback onRemove,
  }) {
    return GestureDetector(
      onTap: () => _showImagePreviewDialog(item, onToggle, onRemove),  // ✅ Popup open
      child: Stack(
        children: [

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: item.isSelected ? kPrimary : kBorder,
                  width: item.isSelected ? 2 : 1,
                ),
                color: Colors.grey[100],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: _buildImagePreview(item.file),
              ),
            ),
          ),
          if (!item.isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          Positioned(
            top: 6,
            left: 6,
            child: GestureDetector(
              onTap: onToggle, // ✅ Checkbox वर click केल्यावर toggle
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: item.isSelected ? kPrimary : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: item.isSelected ? kPrimary : kBorder,
                    width: 1.5,
                  ),
                ),
                child: item.isSelected
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    size: 13, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: Text(
                item.file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoThumbnail({
    required SelectedMedia item,
    required VoidCallback onToggle,
    required VoidCallback onRemove,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: item.isSelected ? kSuccess : kBorder,
                  width: item.isSelected ? 2 : 1,
                ),
                color: Colors.grey[900],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.movie_creation_outlined,
                        size: 36,
                        color: Colors.white.withOpacity(0.5)),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow,
                          color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!item.isSelected)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          Positioned(
            top: 6,
            left: 6,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: item.isSelected ? kSuccess : Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: item.isSelected ? kSuccess : kBorder,
                  width: 1.5,
                ),
              ),
              child: item.isSelected
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close,
                    size: 13, color: Colors.white),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.65),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: Text(
                item.file.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(MediaFile file) {
    try {
      return Image.memory(
        file.bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Center(
          child:
          Icon(Icons.broken_image, color: Colors.grey[400], size: 28),
        ),
      );
    } catch (e) {
      return Center(
        child: Icon(Icons.image, color: Colors.grey[400], size: 28),
      );
    }
  }

  Widget _buildFileChip({
    required String name,
    required int size,
    required Color color,
    required IconData icon,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 150),
            child: Text(
              name,
              style: TextStyle(
                  fontSize: 11,
                  color: kTextPrimary,
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text('${(size / 1024).toStringAsFixed(1)} KB',
              style: TextStyle(fontSize: 10, color: kTextSecondary)),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: color),
          ),
        ],
      ),
    );
  }

  // ==================== RESPONSIVE GRID ====================
  Widget _responsiveGrid(
      {required bool isMobile, required List<Widget> children}) {
    if (isMobile) {
      return Column(
        children: children
            .map((w) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: w,
        ))
            .toList(),
      );
    }
    final rows = <Widget>[];
    for (int i = 0; i < children.length; i += 2) {
      if (i + 1 < children.length) {
        rows.add(Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: children[i]),
              const SizedBox(width: 14),
              Expanded(child: children[i + 1]),
            ],
          ),
        ));
      } else {
        rows.add(Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(children: [Expanded(child: children[i])]),
        ));
      }
    }
    return Column(children: rows);
  }
}

// ==================== SELECTED MEDIA WRAPPER ====================
class SelectedMedia {
  final MediaFile file;
  bool isSelected;

  SelectedMedia({required this.file, this.isSelected = false});
}

