// lib/screens/real_estate/property_update_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import '../../api/realestate_service.dart';
import '../../models/real_estate/my_properties_model.dart';

class PropertyUpdateScreen extends StatefulWidget {
  final MyPropertyData property;

  const PropertyUpdateScreen({super.key, required this.property});

  @override
  State<PropertyUpdateScreen> createState() => _PropertyUpdateScreenState();
}

// ==================== LOCAL MODELS FOR FORM ====================
class LocalFlatType {
  String flatType;
  String areaSqft;
  String carpetArea;
  String builtUpArea;
  String balconyArea;
  int bedrooms;
  int bathrooms;
  int balconies;
  int kitchens;
  int parkingCount;
  String description;
  bool isAvailable;

  LocalFlatType({
    this.flatType = '',
    this.areaSqft = '',
    this.carpetArea = '',
    this.builtUpArea = '',
    this.balconyArea = '',
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.balconies = 0,
    this.kitchens = 0,
    this.parkingCount = 0,
    this.description = '',
    this.isAvailable = true,
  });

  Map<String, dynamic> toJson() => {
    'flat_type': flatType,
    'area_sqft': areaSqft,
    if (carpetArea.isNotEmpty) 'carpet_area': carpetArea,
    if (builtUpArea.isNotEmpty) 'built_up_area': builtUpArea,
    if (balconyArea.isNotEmpty) 'balcony_area': balconyArea,
    'bedrooms': bedrooms,
    'bathrooms': bathrooms,
    'balconies': balconies,
    'kitchens': kitchens,
    'parking_count': parkingCount,
    if (description.isNotEmpty) 'description': description,
    'is_available': isAvailable,
  };
}

class LocalFloor {
  int floorNumber;
  String floorName;
  int totalUnits;
  int availableUnits;

  LocalFloor({
    this.floorNumber = 0,
    this.floorName = '',
    this.totalUnits = 0,
    this.availableUnits = 0,
  });

  Map<String, dynamic> toJson() => {
    'floor_number': floorNumber,
    'floor_name': floorName,
    'total_units': totalUnits,
    'available_units': availableUnits,
  };
}

class LocalPricingSlab {
  int floor;
  String flatType;
  String basePrice;
  String pricePerSqft;
  String bookingAmount;
  String discountPercentage;
  String gstPercentage;
  bool isAvailable;

  LocalPricingSlab({
    this.floor = 0,
    this.flatType = '',
    this.basePrice = '',
    this.pricePerSqft = '',
    this.bookingAmount = '',
    this.discountPercentage = '',
    this.gstPercentage = '',
    this.isAvailable = true,
  });

  Map<String, dynamic> toJson() => {
    'floor': floor,
    'flat_type': flatType,
    'base_price': basePrice,
    if (pricePerSqft.isNotEmpty) 'price_per_sqft': pricePerSqft,
    if (bookingAmount.isNotEmpty) 'booking_amount': bookingAmount,
    if (discountPercentage.isNotEmpty) 'discount_percentage': discountPercentage,
    if (gstPercentage.isNotEmpty) 'gst_percentage': gstPercentage,
    'is_available': isAvailable,
  };
}

class LocalSeller {
  String name;
  String phone;
  String email;
  String company;
  String designation;
  String experienceYears;
  String whatsappNumber;
  bool isPrimary;
  bool isActive;

  LocalSeller({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.company = '',
    this.designation = '',
    this.experienceYears = '',
    this.whatsappNumber = '',
    this.isPrimary = false,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'phone': phone,
    if (email.isNotEmpty) 'email': email,
    if (company.isNotEmpty) 'company': company,
    if (designation.isNotEmpty) 'designation': designation,
    if (experienceYears.isNotEmpty) 'experience_years': int.tryParse(experienceYears),
    if (whatsappNumber.isNotEmpty) 'whatsapp_number': whatsappNumber,
    'is_primary': isPrimary,
    'is_active': isActive,
  };
}

// ==================== MAIN STATE ====================
class _PropertyUpdateScreenState extends State<PropertyUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final MyPropertiesService _service = MyPropertiesService();

  bool _isLoading = false;

  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _cityController;
  late TextEditingController _areaController;
  late TextEditingController _addressController;
  late TextEditingController _landmarkController;
  late TextEditingController _pincodeController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;
  late TextEditingController _googleLocationUrlController;
  late TextEditingController _totalAreaController;
  late TextEditingController _plotAreaController;
  late TextEditingController _totalFloorsController;
  late TextEditingController _totalTowersController;
  late TextEditingController _reraNumberController;
  late TextEditingController _reraQrCodeController;
  late TextEditingController _reraWebsiteController;
  late TextEditingController _propertyWebsiteUrlController;
  late TextEditingController _possessionDateController;
  late TextEditingController _completionPercentageController;

  // Dropdown values
  String _selectedPropertyType = 'flat';
  String _selectedTransactionType = 'sale';
  String _selectedStatus = 'draft';
  String _selectedPropertyCondition = 'new';

  // Toggle values
  bool _isUnderConstruction = false;
  bool _readyToMove = false;
  bool _isFeatured = false;
  bool _isVerified = false;
  bool _isNegotiable = false;

  // Dynamic lists
  List<String> _reraAdditionalUrls = [];
  List<LocalFlatType> _flatTypes = [];
  List<LocalFloor> _floors = [];
  List<LocalPricingSlab> _pricingSlabs = [];
  List<LocalSeller> _sellers = [];

  // Selected amenities (IDs)
  Set<int> _selectedAmenityIds = {};

  // New media files to upload
  List<Uint8List> _newImageBytes = [];
  List<String> _newImageNames = [];
  List<Uint8List> _newVideoBytes = [];
  List<String> _newVideoNames = [];
  List<Uint8List> _newDocumentBytes = [];
  List<String> _newDocumentNames = [];

  // Existing media
  List<PropertyImage> _existingImages = [];
  List<PropertyVideo> _existingVideos = [];
  List<PropertyDocument> _existingDocuments = [];

  // RERA URL controller
  final TextEditingController _reraUrlInputController = TextEditingController();

  // Colors
  static const Color _premiumPrimary = Color(0xFF5A67F2);
  static const Color _premiumSecondary = Color(0xFF7B4DDB);
  static const Color _premiumAccent = Color(0xFFC84DB5);
  static const Color _premiumBg = Color(0xFFF7F8FF);

  final List<String> _propertyTypes = [
    'flat', 'villa', 'plot', 'commercial', 'shop', 'office'
  ];

  final List<String> _transactionTypes = ['sale', 'rent', 'lease'];
  final List<String> _statusTypes = ['draft', 'pending', 'approved', 'rejected'];
  final List<String> _propertyConditions = ['new', 'resale', 'under_construction'];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadExistingData();
  }

  void _initializeControllers() {
    final p = widget.property;
    _titleController = TextEditingController(text: p.title);
    _descriptionController = TextEditingController(text: p.description);
    _cityController = TextEditingController(text: p.city);
    _areaController = TextEditingController(text: p.area);
    _addressController = TextEditingController(text: p.address);
    _landmarkController = TextEditingController(text: p.landmark ?? '');
    _pincodeController = TextEditingController(text: p.pincode ?? '');
    _latitudeController = TextEditingController(text: p.latitude ?? '');
    _longitudeController = TextEditingController(text: p.longitude ?? '');
    _googleLocationUrlController =
        TextEditingController(text: p.googleLocationUrl ?? '');
    _totalAreaController = TextEditingController(text: p.totalArea ?? '');
    _plotAreaController = TextEditingController(text: p.plotArea ?? '');
    _totalFloorsController =
        TextEditingController(text: p.totalFloors?.toString() ?? '');
    _totalTowersController =
        TextEditingController(text: p.totalTowers?.toString() ?? '');
    _reraNumberController = TextEditingController(text: p.reraNumber ?? '');
    _reraQrCodeController = TextEditingController(text: p.reraQrCode ?? '');
    _reraWebsiteController = TextEditingController(text: p.reraWebsite ?? '');
    _propertyWebsiteUrlController =
        TextEditingController(text: p.propertyWebsiteUrl ?? '');
    _possessionDateController =
        TextEditingController(text: p.possessionDate ?? '');
    _completionPercentageController =
        TextEditingController(text: p.completionPercentage?.toString() ?? '');

    _selectedPropertyType =
    _propertyTypes.contains(p.propertyType) ? p.propertyType : 'flat';
    _selectedTransactionType =
    _transactionTypes.contains(p.transactionType) ? p.transactionType : 'sale';
    _selectedStatus =
    _statusTypes.contains(p.status) ? p.status : 'draft';
    _selectedPropertyCondition = _propertyConditions
        .contains(p.propertyCondition ?? '')
        ? p.propertyCondition!
        : 'new';

    _isUnderConstruction = p.isUnderConstruction;
    _readyToMove = p.readyToMove;
    _isFeatured = p.isFeatured;
    _isVerified = p.isVerified;
    _isNegotiable = p.isNegotiable;
  }

  void _loadExistingData() {
    final p = widget.property;

    // Load existing RERA URLs
    _reraAdditionalUrls = List<String>.from(p.reraAdditionalUrls);

    // Load existing amenities
    _selectedAmenityIds = p.amenityDetails.map((a) => a.id).toSet();

    // Load existing media
    _existingImages = List<PropertyImage>.from(p.images);
    _existingVideos = List<PropertyVideo>.from(p.videos);
    _existingDocuments = List<PropertyDocument>.from(p.documents);
  }

  @override
  void dispose() {
    _titleController.dispose();
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
    _reraNumberController.dispose();
    _reraQrCodeController.dispose();
    _reraWebsiteController.dispose();
    _propertyWebsiteUrlController.dispose();
    _possessionDateController.dispose();
    _completionPercentageController.dispose();
    _reraUrlInputController.dispose();
    _service.dispose();
    super.dispose();
  }

  // ==================== SUBMIT ====================
  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = PropertyUpdateRequest(
        propertyId: widget.property.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        propertyType: _selectedPropertyType,
        transactionType: _selectedTransactionType,
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
            : _latitudeController.text.trim(),
        longitude: _longitudeController.text.trim().isEmpty
            ? null
            : _longitudeController.text.trim(),
        googleLocationUrl: _googleLocationUrlController.text.trim().isEmpty
            ? null
            : _googleLocationUrlController.text.trim(),
        totalArea: _totalAreaController.text.trim().isEmpty
            ? null
            : _totalAreaController.text.trim(),
        plotArea: _plotAreaController.text.trim().isEmpty
            ? null
            : _plotAreaController.text.trim(),
        totalFloors: int.tryParse(_totalFloorsController.text.trim()),
        totalTowers: int.tryParse(_totalTowersController.text.trim()),
        reraNumber: _reraNumberController.text.trim().isEmpty
            ? null
            : _reraNumberController.text.trim(),
        reraQrCode: _reraQrCodeController.text.trim().isEmpty
            ? null
            : _reraQrCodeController.text.trim(),
        reraWebsite: _reraWebsiteController.text.trim().isEmpty
            ? null
            : _reraWebsiteController.text.trim(),
        reraAdditionalUrls: _reraAdditionalUrls.isNotEmpty
            ? _reraAdditionalUrls
            : null,
        propertyWebsiteUrl: _propertyWebsiteUrlController.text.trim().isEmpty
            ? null
            : _propertyWebsiteUrlController.text.trim(),
        isUnderConstruction: _isUnderConstruction,
        readyToMove: _readyToMove,
        possessionDate: _possessionDateController.text.trim().isEmpty
            ? null
            : _possessionDateController.text.trim(),
        completionPercentage:
        int.tryParse(_completionPercentageController.text.trim()),
        isFeatured: _isFeatured,
        isVerified: _isVerified,
        isNegotiable: _isNegotiable,
        features: widget.property.features.isNotEmpty
            ? widget.property.features
            : null,
      );

      final response = await _service.updateProperty(request);

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ==================== BUILD ====================
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: _premiumBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Update Property',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _submitUpdate,
            icon: _isLoading
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.save),
            label: Text(_isLoading ? 'Saving...' : 'Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================== BASIC INFORMATION ====================
              _buildSection(
                title: 'Basic Information',
                icon: Icons.info_outline,
                children: [
                  _buildTextField(
                    controller: _titleController,
                    label: 'Property Title',
                    hint: 'Enter property title',
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Enter description',
                    maxLines: 3,
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  _responsiveRow(
                    isMobile: isMobile,
                    children: [
                      _buildDropdown(
                        label: 'Property Type',
                        value: _selectedPropertyType,
                        items: _propertyTypes,
                        onChanged: (v) =>
                            setState(() => _selectedPropertyType = v!),
                      ),
                      _buildDropdown(
                        label: 'Transaction Type',
                        value: _selectedTransactionType,
                        items: _transactionTypes,
                        onChanged: (v) =>
                            setState(() => _selectedTransactionType = v!),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _responsiveRow(
                    isMobile: isMobile,
                    children: [
                      _buildDropdown(
                        label: 'Status',
                        value: _selectedStatus,
                        items: _statusTypes,
                        onChanged: (v) => setState(() => _selectedStatus = v!),
                      ),
                      _buildDropdown(
                        label: 'Property Condition',
                        value: _selectedPropertyCondition,
                        items: _propertyConditions,
                        onChanged: (v) =>
                            setState(() => _selectedPropertyCondition = v!),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================== LOCATION DETAILS ====================
              _buildSection(
                title: 'Location Details',
                icon: Icons.location_on,
                children: [
                  _responsiveRow(
                    isMobile: isMobile,
                    children: [
                      _buildTextField(
                        controller: _cityController,
                        label: 'City',
                        hint: 'Enter city',
                        required: true,
                      ),
                      _buildTextField(
                        controller: _areaController,
                        label: 'Area',
                        hint: 'Enter area',
                        required: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    hint: 'Enter full address',
                    maxLines: 2,
                    required: true,
                  ),
                  const SizedBox(height: 12),
                  _responsiveRow(
                    isMobile: isMobile,
                    children: [
                      _buildTextField(
                        controller: _landmarkController,
                        label: 'Landmark',
                        hint: 'Enter landmark',
                      ),
                      _buildTextField(
                        controller: _pincodeController,
                        label: 'Pincode',
                        hint: 'Enter pincode',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _responsiveRow(
                    isMobile: isMobile,
                    children: [
                      _buildTextField(
                        controller: _latitudeController,
                        label: 'Latitude',
                        hint: 'Enter latitude',
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                      ),
                      _buildTextField(
                        controller: _longitudeController,
                        label: 'Longitude',
                        hint: 'Enter longitude',
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _googleLocationUrlController,
                    label: 'Google Location URL',
                    hint: 'Enter Google Maps URL',
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================== PROPERTY DETAILS ====================
              _buildSection(
                title: 'Property Details',
                icon: Icons.home_work,
                children: [
                  _responsiveRow(
                    isMobile: isMobile,
                    children: [
                      _buildTextField(
                        controller: _totalAreaController,
                        label: 'Total Area (sq ft)',
                        hint: 'Enter total area',
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                      ),
                      _buildTextField(
                        controller: _plotAreaController,
                        label: 'Plot Area (sq ft)',
                        hint: 'Enter plot area',
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _responsiveRow(
                    isMobile: isMobile,
                    children: [
                      _buildTextField(
                        controller: _totalFloorsController,
                        label: 'Total Floors',
                        hint: 'Enter total floors',
                        keyboardType: TextInputType.number,
                      ),
                      _buildTextField(
                        controller: _totalTowersController,
                        label: 'Total Towers',
                        hint: 'Enter total towers',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _responsiveRow(
                    isMobile: isMobile,
                    children: [
                      _buildTextField(
                        controller: _possessionDateController,
                        label: 'Possession Date',
                        hint: 'YYYY-MM-DD',
                      ),
                      _buildTextField(
                        controller: _completionPercentageController,
                        label: 'Completion %',
                        hint: 'Enter completion percentage',
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildToggleRow(
                    'Under Construction',
                    _isUnderConstruction,
                        (v) => setState(() => _isUnderConstruction = v),
                  ),
                  _buildToggleRow(
                    'Ready to Move',
                    _readyToMove,
                        (v) => setState(() => _readyToMove = v),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================== RERA DETAILS ====================
              _buildSection(
                title: 'RERA Details',
                icon: Icons.verified_user,
                children: [
                  _buildTextField(
                    controller: _reraNumberController,
                    label: 'RERA Number',
                    hint: 'Enter RERA number',
                  ),
                  const SizedBox(height: 12),
                  _responsiveRow(
                    isMobile: isMobile,
                    children: [
                      _buildTextField(
                        controller: _reraWebsiteController,
                        label: 'RERA Website',
                        hint: 'Enter RERA website URL',
                      ),
                      _buildTextField(
                        controller: _reraQrCodeController,
                        label: 'RERA QR Code URL',
                        hint: 'Enter QR code URL',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _propertyWebsiteUrlController,
                    label: 'Property Website URL',
                    hint: 'Enter property website URL',
                  ),
                  const SizedBox(height: 16),
                  _buildReraAdditionalUrlsSection(),
                ],
              ),

              const SizedBox(height: 16),

              // ==================== AMENITIES ====================
              _buildSection(
                title: 'Amenities (${_selectedAmenityIds.length} selected)',
                icon: Icons.pool,
                children: [
                  _buildAmenitiesSelector(),
                ],
              ),

              const SizedBox(height: 16),

              // ==================== FLAT TYPES ====================
              _buildSection(
                title: 'Flat Types (${_flatTypes.length})',
                icon: Icons.apartment,
                children: [
                  ..._flatTypes.asMap().entries.map((entry) {
                    return _buildFlatTypeCard(entry.key, entry.value);
                  }),
                  const SizedBox(height: 8),
                  _buildAddButton(
                    label: 'Add Flat Type',
                    onTap: () {
                      setState(() {
                        _flatTypes.add(LocalFlatType());
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================== FLOORS ====================
              _buildSection(
                title: 'Floors (${_floors.length})',
                icon: Icons.account_balance,
                children: [
                  ..._floors.asMap().entries.map((entry) {
                    return _buildFloorCard(entry.key, entry.value);
                  }),
                  const SizedBox(height: 8),
                  _buildAddButton(
                    label: 'Add Floor',
                    onTap: () {
                      setState(() {
                        _floors.add(LocalFloor());
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================== PRICING SLABS ====================
              _buildSection(
                title: 'Pricing Slabs (${_pricingSlabs.length})',
                icon: Icons.attach_money,
                children: [
                  ..._pricingSlabs.asMap().entries.map((entry) {
                    return _buildPricingSlabCard(entry.key, entry.value);
                  }),
                  const SizedBox(height: 8),
                  _buildAddButton(
                    label: 'Add Pricing Slab',
                    onTap: () {
                      setState(() {
                        _pricingSlabs.add(LocalPricingSlab());
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================== SELLERS ====================
              _buildSection(
                title: 'Sellers (${_sellers.length})',
                icon: Icons.people,
                children: [
                  ..._sellers.asMap().entries.map((entry) {
                    return _buildSellerCard(entry.key, entry.value);
                  }),
                  const SizedBox(height: 8),
                  _buildAddButton(
                    label: 'Add Seller',
                    onTap: () {
                      setState(() {
                        _sellers.add(LocalSeller());
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================== EXISTING IMAGES ====================
              _buildSection(
                title: 'Existing Images (${_existingImages.length})',
                icon: Icons.photo_library,
                children: [
                  _existingImages.isEmpty
                      ? const Text('No images')
                      : SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _existingImages.length,
                      itemBuilder: (context, index) {
                        final img = _existingImages[index];
                        return Stack(
                          children: [
                            Container(
                              width: 90,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.network(
                                  img.imageS3Key,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.shade100,
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                            ),
                            if (img.isPrimary)
                              Positioned(
                                top: 2,
                                left: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius:
                                    BorderRadius.circular(4),
                                  ),
                                  child: const Text('Primary',
                                      style: TextStyle(
                                          fontSize: 8,
                                          color: Colors.white)),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================== NEW IMAGES ====================
              _buildSection(
                title: 'Add New Images (${_newImageBytes.length})',
                icon: Icons.add_photo_alternate,
                children: [
                  _newImageBytes.isEmpty
                      ? const Text('No new images selected')
                      : SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _newImageBytes.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              width: 90,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.grey.shade300),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(7),
                                child: Image.memory(
                                  _newImageBytes[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _newImageBytes.removeAt(index);
                                    _newImageNames.removeAt(index);
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 12, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildAddButton(
                    label: 'Pick Images',
                    onTap: _pickImages,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================== EXISTING VIDEOS ====================
              _buildSection(
                title: 'Existing Videos (${_existingVideos.length})',
                icon: Icons.videocam,
                children: [
                  _existingVideos.isEmpty
                      ? const Text('No videos')
                      : Column(
                    children: _existingVideos.map((v) {
                      return ListTile(
                        leading: const Icon(Icons.play_circle,
                            color: Colors.red),
                        title: Text(v.title ?? 'Video ${v.id}'),
                        subtitle: Text(v.videoS3Key,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================== NEW VIDEOS ====================
              _buildSection(
                title: 'Add New Videos (${_newVideoBytes.length})',
                icon: Icons.video_call,
                children: [
                  _newVideoBytes.isEmpty
                      ? const Text('No new videos selected')
                      : Column(
                    children: _newVideoBytes.asMap().entries.map((e) {
                      return ListTile(
                        leading: const Icon(Icons.video_file,
                            color: Colors.red),
                        title: Text(_newVideoNames[e.key]),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _newVideoBytes.removeAt(e.key);
                              _newVideoNames.removeAt(e.key);
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  _buildAddButton(
                    label: 'Pick Videos',
                    onTap: _pickVideos,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================== EXISTING DOCUMENTS ====================
              _buildSection(
                title: 'Existing Documents (${_existingDocuments.length})',
                icon: Icons.description,
                children: [
                  _existingDocuments.isEmpty
                      ? const Text('No documents')
                      : Column(
                    children: _existingDocuments.map((d) {
                      return ListTile(
                        leading: const Icon(Icons.insert_drive_file,
                            color: Colors.blue),
                        title: Text(d.title),
                        subtitle: Text(d.documentType.toUpperCase()),
                      );
                    }).toList(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================== NEW DOCUMENTS ====================
              _buildSection(
                title: 'Add New Documents (${_newDocumentBytes.length})',
                icon: Icons.upload_file,
                children: [
                  _newDocumentBytes.isEmpty
                      ? const Text('No new documents selected')
                      : Column(
                    children: _newDocumentBytes.asMap().entries.map((e) {
                      return ListTile(
                        leading: const Icon(Icons.description,
                            color: Colors.blue),
                        title: Text(_newDocumentNames[e.key]),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _newDocumentBytes.removeAt(e.key);
                              _newDocumentNames.removeAt(e.key);
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  _buildAddButton(
                    label: 'Pick Documents',
                    onTap: _pickDocuments,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================== STATUS FLAGS ====================
              _buildSection(
                title: 'Status Flags',
                icon: Icons.flag,
                children: [
                  _buildToggleRow(
                    'Featured Property',
                    _isFeatured,
                        (v) => setState(() => _isFeatured = v),
                  ),
                  _buildToggleRow(
                    'Verified Property',
                    _isVerified,
                        (v) => setState(() => _isVerified = v),
                  ),
                  _buildToggleRow(
                    'Negotiable Price',
                    _isNegotiable,
                        (v) => setState(() => _isNegotiable = v),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ==================== SUBMIT BUTTON ====================
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitUpdate,
                  icon: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.save),
                  label: Text(
                    _isLoading ? 'Updating...' : 'Update Property',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _premiumPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== MEDIA PICKERS (Web) ====================
  void _pickImages() async {
    // For web: use file input
    // This is a placeholder - you'll need to implement actual file picking
    // using file_picker package or html input
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image picker - implement with file_picker package')),
    );
  }

  void _pickVideos() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video picker - implement with file_picker package')),
    );
  }

  void _pickDocuments() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document picker - implement with file_picker package')),
    );
  }

  // ==================== RERA ADDITIONAL URLS SECTION ====================
  Widget _buildReraAdditionalUrlsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('RERA Additional URLs',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 8),
        if (_reraAdditionalUrls.isNotEmpty)
          ..._reraAdditionalUrls.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(entry.value,
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 18),
                    onPressed: () {
                      setState(() {
                        _reraAdditionalUrls.removeAt(entry.key);
                      });
                    },
                  ),
                ],
              ),
            );
          }),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _reraUrlInputController,
                decoration: InputDecoration(
                  hintText: 'Enter RERA additional URL',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle, color: _premiumPrimary),
              onPressed: () {
                if (_reraUrlInputController.text.trim().isNotEmpty) {
                  setState(() {
                    _reraAdditionalUrls.add(_reraUrlInputController.text.trim());
                    _reraUrlInputController.clear();
                  });
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  // ==================== AMENITIES SELECTOR ====================
  Widget _buildAmenitiesSelector() {
    // Common amenities list (you can fetch from API)
    final amenities = [
      {'id': 1, 'name': 'Swimming Pool'},
      {'id': 2, 'name': 'Gym'},
      {'id': 3, 'name': 'Parking'},
      {'id': 4, 'name': 'Security'},
      {'id': 5, 'name': 'Lift'},
      {'id': 6, 'name': 'Power Backup'},
      {'id': 7, 'name': 'Garden'},
      {'id': 8, 'name': 'Clubhouse'},
      {'id': 9, 'name': 'Playground'},
      {'id': 10, 'name': 'Water Supply'},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: amenities.map((a) {
        final id = a['id'] as int;
        final isSelected = _selectedAmenityIds.contains(id);
        return FilterChip(
          label: Text(a['name'] as String),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedAmenityIds.add(id);
              } else {
                _selectedAmenityIds.remove(id);
              }
            });
          },
          selectedColor: _premiumPrimary.withOpacity(0.2),
          checkmarkColor: _premiumPrimary,
        );
      }).toList(),
    );
  }

  // ==================== FLAT TYPE CARD ====================
  Widget _buildFlatTypeCard(int index, LocalFlatType ft) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Flat Type ${index + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                onPressed: () {
                  setState(() {
                    _flatTypes.removeAt(index);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _responsiveRow(
            isMobile: true,
            children: [
              TextFormField(
                initialValue: ft.flatType,
                decoration: const InputDecoration(
                  labelText: 'Flat Type',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => ft.flatType = v,
              ),
              TextFormField(
                initialValue: ft.areaSqft,
                decoration: const InputDecoration(
                  labelText: 'Area (sq ft)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => ft.areaSqft = v,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _responsiveRow(
            isMobile: true,
            children: [
              TextFormField(
                initialValue: ft.bedrooms.toString(),
                decoration: const InputDecoration(
                  labelText: 'Bedrooms',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => ft.bedrooms = int.tryParse(v) ?? 0,
              ),
              TextFormField(
                initialValue: ft.bathrooms.toString(),
                decoration: const InputDecoration(
                  labelText: 'Bathrooms',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => ft.bathrooms = int.tryParse(v) ?? 0,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _responsiveRow(
            isMobile: true,
            children: [
              TextFormField(
                initialValue: ft.balconies.toString(),
                decoration: const InputDecoration(
                  labelText: 'Balconies',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => ft.balconies = int.tryParse(v) ?? 0,
              ),
              TextFormField(
                initialValue: ft.kitchens.toString(),
                decoration: const InputDecoration(
                  labelText: 'Kitchens',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => ft.kitchens = int.tryParse(v) ?? 0,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Available: '),
              Switch(
                value: ft.isAvailable,
                onChanged: (v) => setState(() => ft.isAvailable = v),
                activeColor: _premiumPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== FLOOR CARD ====================
  Widget _buildFloorCard(int index, LocalFloor floor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Floor ${index + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                onPressed: () {
                  setState(() {
                    _floors.removeAt(index);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _responsiveRow(
            isMobile: true,
            children: [
              TextFormField(
                initialValue: floor.floorNumber.toString(),
                decoration: const InputDecoration(
                  labelText: 'Floor Number',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => floor.floorNumber = int.tryParse(v) ?? 0,
              ),
              TextFormField(
                initialValue: floor.floorName,
                decoration: const InputDecoration(
                  labelText: 'Floor Name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => floor.floorName = v,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _responsiveRow(
            isMobile: true,
            children: [
              TextFormField(
                initialValue: floor.totalUnits.toString(),
                decoration: const InputDecoration(
                  labelText: 'Total Units',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => floor.totalUnits = int.tryParse(v) ?? 0,
              ),
              TextFormField(
                initialValue: floor.availableUnits.toString(),
                decoration: const InputDecoration(
                  labelText: 'Available Units',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => floor.availableUnits = int.tryParse(v) ?? 0,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== PRICING SLAB CARD ====================
  Widget _buildPricingSlabCard(int index, LocalPricingSlab ps) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pricing Slab ${index + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                onPressed: () {
                  setState(() {
                    _pricingSlabs.removeAt(index);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _responsiveRow(
            isMobile: true,
            children: [
              TextFormField(
                initialValue: ps.floor.toString(),
                decoration: const InputDecoration(
                  labelText: 'Floor',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => ps.floor = int.tryParse(v) ?? 0,
              ),
              TextFormField(
                initialValue: ps.flatType,
                decoration: const InputDecoration(
                  labelText: 'Flat Type',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => ps.flatType = v,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _responsiveRow(
            isMobile: true,
            children: [
              TextFormField(
                initialValue: ps.basePrice,
                decoration: const InputDecoration(
                  labelText: 'Base Price',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => ps.basePrice = v,
              ),
              TextFormField(
                initialValue: ps.pricePerSqft,
                decoration: const InputDecoration(
                  labelText: 'Price/sqft',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => ps.pricePerSqft = v,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Available: '),
              Switch(
                value: ps.isAvailable,
                onChanged: (v) => setState(() => ps.isAvailable = v),
                activeColor: _premiumPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== SELLER CARD ====================
  Widget _buildSellerCard(int index, LocalSeller seller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Seller ${index + 1}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                onPressed: () {
                  setState(() {
                    _sellers.removeAt(index);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _responsiveRow(
            isMobile: true,
            children: [
              TextFormField(
                initialValue: seller.name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => seller.name = v,
              ),
              TextFormField(
                initialValue: seller.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.phone,
                onChanged: (v) => seller.phone = v,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _responsiveRow(
            isMobile: true,
            children: [
              TextFormField(
                initialValue: seller.email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (v) => seller.email = v,
              ),
              TextFormField(
                initialValue: seller.company,
                decoration: const InputDecoration(
                  labelText: 'Company',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => seller.company = v,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Primary: '),
              Switch(
                value: seller.isPrimary,
                onChanged: (v) => setState(() => seller.isPrimary = v),
                activeColor: _premiumPrimary,
              ),
              const SizedBox(width: 16),
              const Text('Active: '),
              Switch(
                value: seller.isActive,
                onChanged: (v) => setState(() => seller.isActive = v),
                activeColor: _premiumPrimary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==================== UI HELPERS ====================
  Widget _buildAddButton({required String label, required VoidCallback onTap}) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.add, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: _premiumPrimary,
        side: BorderSide(color: _premiumPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5A67F2), Color(0xFF7B4DDB)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: required
          ? (v) => v == null || v.trim().isEmpty ? 'Required' : null
          : null,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _premiumPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _premiumPrimary, width: 1.5),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(
        value: e,
        child: Text(e.replaceAll('_', ' ').toUpperCase()),
      ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildToggleRow(
      String label, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _premiumPrimary,
          ),
        ],
      ),
    );
  }

  Widget _responsiveRow({
    required bool isMobile,
    required List<Widget> children,
  }) {
    if (isMobile) {
      return Column(
        children: children
            .map((w) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: w,
        ))
            .toList(),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: children[0]),
        const SizedBox(width: 12),
        Expanded(child: children[1]),
      ],
    );
  }
}