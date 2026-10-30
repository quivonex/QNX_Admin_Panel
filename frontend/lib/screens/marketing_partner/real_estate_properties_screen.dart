// lib/screens/marketing_partner/real_estate_properties_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/marketing_service.dart';
import '../../models/marketing_partner/property_model.dart';

class RealEstatePropertiesScreen extends StatefulWidget {
  const RealEstatePropertiesScreen({super.key});

  @override
  State<RealEstatePropertiesScreen> createState() => _RealEstatePropertiesScreenState();
}

class _RealEstatePropertiesScreenState extends State<RealEstatePropertiesScreen> {
  final RealEstateService _service = RealEstateService();

  List<PropertyData> _properties = [];
  List<PropertyData> _filteredProperties = [];
  List<PropertyData> _paginatedProperties = [];

  bool _isLoading = true;
  String? _error;

  // Search & Filter
  String _searchQuery = '';
  String _filterType = 'Title';
  final TextEditingController _searchController = TextEditingController();

  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalPages = 1;
  final List<int> _itemsPerPageOptions = [5, 10, 15, 20, 25, 50];

  // Referral
  String? _partnerReferralCode;

  // Premium colors
  static const Color _premiumPrimary = Color(0xFF5A67F2);
  static const Color _premiumSecondary = Color(0xFF7B4DDB);
  static const Color _premiumAccent = Color(0xFFC84DB5);
  static const Color _premiumGold = Color(0xFF5A67F2);
  static const Color _premiumLight = Color(0xFF7B4DDB);
  static const Color _premiumBg = Color(0xFFF7F8FF);
  static const Color _premiumCard = Colors.white;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _partnerReferralCode = prefs.getString('referral_code');

      final response = await _service.getApprovedProperties(
        referralCode: _partnerReferralCode,
      );

      setState(() {
        _properties = response.data;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception:', '');
        _isLoading = false;
      });
    }
  }

  // ========================================================================
  // FILTER & PAGINATION
  // ========================================================================
  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredProperties = List.from(_properties);
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredProperties = _properties.where((property) {
        switch (_filterType) {
          case 'Title':
            return property.title.toLowerCase().contains(query);
          case 'City':
            return property.city.toLowerCase().contains(query);
          case 'Area':
            return property.area.toLowerCase().contains(query);
          case 'Property Type':
            return property.propertyType.toLowerCase().contains(query);
          case 'Transaction Type':
            return property.transactionType.toLowerCase().contains(query);
          default:
            return false;
        }
      }).toList();
    }
    _applyPagination();
  }

  void _applyPagination() {
    if (_filteredProperties.isEmpty) {
      _paginatedProperties = [];
      _totalPages = 1;
      _currentPage = 1;
      setState(() {});
      return;
    }

    _totalPages = (_filteredProperties.length / _itemsPerPage).ceil();
    if (_currentPage > _totalPages) _currentPage = _totalPages;
    if (_currentPage < 1) _currentPage = 1;

    int start = (_currentPage - 1) * _itemsPerPage;
    int end = start + _itemsPerPage;
    if (end > _filteredProperties.length) end = _filteredProperties.length;

    _paginatedProperties = _filteredProperties.sublist(start, end);
    setState(() {});
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      setState(() {
        _currentPage++;
        _applyPagination();
      });
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      setState(() {
        _currentPage--;
        _applyPagination();
      });
    }
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      setState(() {
        _currentPage = page;
        _applyPagination();
      });
    }
  }

  void _changeItemsPerPage(int? value) {
    if (value != null) {
      setState(() {
        _itemsPerPage = value;
        _currentPage = 1;
        _applyPagination();
      });
    }
  }

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _filterType = 'Title';
      _searchController.clear();
      _currentPage = 1;
      _applyFilters();
    });
  }

  // ========================================================================
  // FULL PROPERTY DETAILS POPUP (Like Approved Products)
  // ========================================================================
  void _showPropertyDetails(PropertyData property) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            double dialogWidth = constraints.maxWidth * 0.9;
            if (constraints.maxWidth > 600) dialogWidth = 640;
            if (constraints.maxWidth > 1000) dialogWidth = 760;

            return Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    _premiumBg,
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: _premiumPrimary.withOpacity(0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Premium Header - No ID
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFF5A67F2),
                          Color(0xFF7B4DDB),
                          Color(0xFFC84DB5),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _premiumGold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                property.title.isNotEmpty ? property.title[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      property.propertyType,
                                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      property.transactionType,
                                      style: const TextStyle(fontSize: 11, color: Colors.white70),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Scrollable Body
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Chips
                          Row(
                            children: [
                              _premiumStatusChip(
                                property.statusApprove,
                                property.statusApprove == 'approved' ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 12),
                              _premiumStatusChip(
                                property.status,
                                property.status == 'active' ? Colors.blue : Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              if (property.isFeatured)
                                _premiumStatusChip(
                                  "Featured",
                                  _premiumGold,
                                  icon: Icons.star,
                                ),
                              const SizedBox(width: 12),
                              if (property.isVerified)
                                _premiumStatusChip(
                                  "Verified",
                                  Colors.green,
                                  icon: Icons.verified,
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Price Section
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_premiumGold.withOpacity(0.1), _premiumLight.withOpacity(0.05)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _premiumGold.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Price",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: _premiumGold,
                                  ),
                                ),
                                Text(
                                  "₹${double.parse(property.price).toStringAsFixed(0)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: _premiumGold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Property Information
                          _buildPremiumSection(
                            title: "Property Information",
                            icon: Icons.info_outline,
                            children: [
                              _infoRow("Type", property.propertyType),
                              _infoRow("Transaction", property.transactionType),
                              _infoRow("Status", property.status),
                              _infoRow("Approve Status", property.statusApprove),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Price & Area
                          _buildPremiumSection(
                            title: "Price & Area",
                            icon: Icons.attach_money,
                            children: [
                              _infoRow("Price per Sqft", "₹${property.pricePerSqft}"),
                              _infoRow("Maintenance", "₹${property.maintenanceCharge}"),
                              _infoRow("Booking Amount", "₹${property.bookingAmount}"),
                              _infoRow("Total Area", "${property.totalArea} sqft"),
                              _infoRow("Carpet Area", "${property.carpetArea} sqft"),
                              _infoRow("Built Up Area", "${property.builtUpArea} sqft"),
                              _infoRow("Plot Area", "${property.plotArea} sqft"),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Specifications
                          _buildPremiumSection(
                            title: "Specifications",
                            icon: Icons.square_foot,
                            children: [
                              _infoRow("BHK", "${property.bedrooms} BHK"),
                              _infoRow("Bathrooms", property.bathrooms.toString()),
                              _infoRow("Balconies", property.balconies.toString()),
                              _infoRow("Kitchens", property.kitchens.toString()),
                              _infoRow("Total Floors", property.totalFloors.toString()),
                              _infoRow("Floor Number", property.floorNumber.toString()),
                              _infoRow("Parking", "${property.parkingCount} (${property.parkingType})"),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Location
                          _buildPremiumSection(
                            title: "Location",
                            icon: Icons.location_on,
                            children: [
                              _infoRow("City", property.city),
                              _infoRow("Area", property.area),
                              _infoRow("Address", property.address),
                              if (property.landmark != null && property.landmark!.isNotEmpty)
                                _infoRow("Landmark", property.landmark!),
                              if (property.pincode != null && property.pincode!.isNotEmpty)
                                _infoRow("Pincode", property.pincode!),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Owner Details
                          _buildPremiumSection(
                            title: "Owner Details",
                            icon: Icons.person,
                            children: [
                              _infoRow("Name", property.ownerName),
                              _infoRow("Contact", property.ownerContact),
                              if (property.ownerEmail != null && property.ownerEmail!.isNotEmpty)
                                _infoRow("Email", property.ownerEmail!),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Features
                          if (property.features != null && property.features!.isNotEmpty) ...[
                            _buildPremiumSection(
                              title: "Features",
                              icon: Icons.checklist,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: property.features!.entries.map((entry) {
                                    return _premiumChip(
                                      entry.key.replaceAll('_', ' ').toUpperCase(),
                                      entry.value == true ? "✅ Yes" : "❌ No",
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Amenities
                          if (property.amenityDetails != null && property.amenityDetails!.isNotEmpty) ...[
                            _buildPremiumSection(
                              title: "Amenities",
                              icon: Icons.room_service,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: property.amenityDetails!.map((amenity) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF2FF),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFF5A67F2).withOpacity(0.25),
                                        ),
                                      ),
                                      child: Text(
                                        amenity.name,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF5A67F2),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Statistics
                          _buildPremiumSection(
                            title: "Statistics",
                            icon: Icons.bar_chart,
                            children: [
                              _infoRow("Views", property.viewsCount.toString()),
                              _infoRow("Enquiries", property.enquiryCount.toString()),
                              _infoRow("Favorites", property.favoriteCount.toString()),
                              _infoRow("Created", property.createdAt),
                              _infoRow("Updated", property.updatedAt),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Generate Referral Link Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showReferralPopup(property),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4158D0),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: const Icon(Icons.link, size: 18),
                              label: const Text(
                                'Generate Referral Link',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _premiumStatusChip(String label, Color color, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Icon(icon, size: 14, color: color),
          if (icon != null) const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF5A67F2),
                    Color(0xFF7B4DDB),
                    Color(0xFFC84DB5),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF5A67F2),
                  Color(0xFF7B4DDB),
                  Color(0xFFC84DB5),
                ],
              ).createShader(bounds),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
                color: isHighlight ? _premiumPrimary : Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _premiumChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF5A67F2).withOpacity(0.25),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color(0xFF5A67F2),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF7B4DDB),
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // GENERATE REFERRAL LINK POPUP
  // ========================================================================
  void _showReferralPopup(PropertyData property) {
    if (!mounted) return;

    final String referralLink = 'https://qnxmartb2b.com/property/${property.slug}?ref=${_partnerReferralCode ?? ""}';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.link, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Generate Referral Link',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Property: ${property.title}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Price: ₹${property.price}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (property.referralCode != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Referral Code: ${property.referralCode}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Marketing Partner Referral Code',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.code, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(
                      _partnerReferralCode ?? 'Not available',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Generated Link',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        referralLink,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.blue, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: referralLink));
                        Navigator.pop(context);
                        _showSnackBar('Link copied to clipboard!', Colors.green);
                      },
                      tooltip: 'Copy Link',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
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
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: referralLink));
              Navigator.pop(context);
              _showSnackBar('Link copied to clipboard!', Colors.green);
            },
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy Link'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ========================================================================
  // BUILD UI
  // ========================================================================
  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A2E) : const Color(0xFFF5F7FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorWidget()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterSection(isDarkMode, isMobile),
            const SizedBox(height: 12),
            if (_filteredProperties.isEmpty)
              _buildEmptyState()
            else ...[
              Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildPropertiesTable(isDarkMode),
                ),
              ),
              const SizedBox(height: 12),
              _buildPagination(isDarkMode, isMobile),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ========================================================================
  // FILTER SECTION
  // ========================================================================
  Widget _buildFilterSection(bool isDarkMode, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: isMobile
          ? Column(
        children: [
          Row(
            children: [
              _buildFilterDropdown(isDarkMode),
              const SizedBox(width: 12),
              Expanded(child: _buildSearchField(isDarkMode)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total: ${_filteredProperties.length}",
                style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.grey, fontSize: 13),
              ),
              IconButton(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh),
                color: Colors.red,
              ),
            ],
          ),
        ],
      )
          : Row(
        children: [
          _buildFilterDropdown(isDarkMode),
          const SizedBox(width: 12),
          Expanded(child: _buildSearchField(isDarkMode)),
          const SizedBox(width: 12),
          Text(
            "Total: ${_filteredProperties.length}",
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.grey,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: _resetFilters,
            icon: const Icon(Icons.refresh),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(bool isDarkMode) {
    return Container(
      width: 150,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _filterType,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
          style: TextStyle(color: isDarkMode ? Colors.white : const Color(0xFF1E293B), fontSize: 13),
          isExpanded: true,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _filterType = newValue;
                _currentPage = 1;
                _applyFilters();
              });
            }
          },
          items: ['Title', 'City', 'Area', 'Property Type', 'Transaction Type']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSearchField(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: "Search by $_filterType...",
          hintStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600], fontSize: 13),
          prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF6366F1)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, size: 16, color: isDarkMode ? Colors.white70 : Colors.grey),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _currentPage = 1;
                _applyFilters();
              });
            },
          )
              : null,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _currentPage = 1;
            _applyFilters();
          });
        },
      ),
    );
  }

  // ========================================================================
  // PROPERTIES TABLE - Increased Column Widths
  // ========================================================================
  Widget _buildPropertiesTable(bool isDarkMode) {
    final borderSide = BorderSide(
      color: isDarkMode ? Colors.grey[700]! : const Color(0xFFCBD5E1),
      width: 1.0,
    );

    // Increased column widths
    final Map<int, TableColumnWidth> columnWidths = {
      0: const FixedColumnWidth(60),   // Sr. No.
      1: const FixedColumnWidth(200),  // Title
      2: const FixedColumnWidth(120),  // Type
      3: const FixedColumnWidth(120),  // Transaction
      4: const FixedColumnWidth(120),  // Price
      5: const FixedColumnWidth(100),  // City
      6: const FixedColumnWidth(100),  // Area
      7: const FixedColumnWidth(80),   // BHK
      8: const FixedColumnWidth(100),  // Status
      9: const FixedColumnWidth(120),  // Referral
      10: const FixedColumnWidth(80),  // Action
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.grey[700]! : const Color(0xFFCBD5E1)),
      ),
      child: DataTable(
        columnSpacing: 20,
        horizontalMargin: 12,
        showBottomBorder: true,
        border: TableBorder(
          horizontalInside: borderSide,
          verticalInside: borderSide,
          bottom: borderSide,
          top: borderSide,
          right: borderSide,
          left: borderSide,
        ),
        headingRowColor: WidgetStateProperty.all(
          isDarkMode ? const Color(0xFF16213E) : const Color(0xFFEEF2F6),
        ),
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.grey[300] : const Color(0xFF334155),
          fontSize: 12,
        ),
        dataRowColor: WidgetStateProperty.all(
          isDarkMode ? const Color(0xFF1E293B) : Colors.white,
        ),
        columns: const [
          DataColumn(label: Text('Sr. No.')),
          DataColumn(label: Text('Title')),
          DataColumn(label: Text('Type')),
          DataColumn(label: Text('Transaction')),
          DataColumn(label: Text('Price')),
          DataColumn(label: Text('City')),
          DataColumn(label: Text('Area')),
          DataColumn(label: Text('BHK')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Referral')),
          DataColumn(label: Text('Action')),
        ],
        rows: _paginatedProperties.asMap().entries.map((entry) {
          int index = entry.key;
          var property = entry.value;

          final int globalIndex = (_currentPage - 1) * _itemsPerPage + index;
          final int srNo = _filteredProperties.length - globalIndex;

          return DataRow(
            onSelectChanged: (_) => _showPropertyDetails(property),
            cells: [
              // Sr. No.
              DataCell(
                Center(
                  child: Text(
                    srNo.toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
              // Title - Clickable
              DataCell(
                InkWell(
                  onTap: () => _showPropertyDetails(property),
                  child: SizedBox(
                    width: 180,
                    child: Text(
                      property.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : const Color(0xFF475569),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              // Type
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    property.propertyType.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // Transaction
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    property.transactionType.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // Price
              DataCell(
                Text(
                  '₹${double.parse(property.price).toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFF39C12),
                  ),
                ),
              ),
              // City
              DataCell(
                Text(
                  property.city,
                  style: TextStyle(color: isDarkMode ? Colors.grey[400] : const Color(0xFF475569)),
                ),
              ),
              // Area
              DataCell(
                Text(
                  property.area,
                  style: TextStyle(color: isDarkMode ? Colors.grey[400] : const Color(0xFF475569)),
                ),
              ),
              // BHK
              DataCell(
                Text(
                  '${property.bedrooms} BHK',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ),
              // Status
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: property.statusApprove == 'approved'
                        ? Colors.green.withOpacity(0.15)
                        : Colors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    property.statusApprove.toUpperCase(),
                    style: TextStyle(
                      color: property.statusApprove == 'approved'
                          ? Colors.green
                          : Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Referral Code
              DataCell(
                property.referralCode != null
                    ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    property.referralCode!,
                    style: const TextStyle(
                      color: Colors.purple,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
                    : const Text(
                  '-',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              // Action
              DataCell(
                Center(
                  child: IconButton(
                    icon: const Icon(Icons.link, size: 18, color: Color(0xFF4158D0)),
                    onPressed: () => _showReferralPopup(property),
                    tooltip: 'Generate Referral Link',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ========================================================================
  // PAGINATION
  // ========================================================================
  Widget _buildPagination(bool isDarkMode, bool isMobile) {
    if (_filteredProperties.isEmpty) return const SizedBox.shrink();

    final entriesWidget = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Show ", style: TextStyle(fontSize: 11)),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF334155) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
          ),
          child: DropdownButton<int>(
            value: _itemsPerPage,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: isDarkMode ? Colors.white70 : Colors.grey),
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontSize: 11),
            items: _itemsPerPageOptions.map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
            onChanged: _changeItemsPerPage,
          ),
        ),
        const Text(" entries", style: TextStyle(fontSize: 11)),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            "Showing ${(_currentPage - 1) * _itemsPerPage + 1} to ${_currentPage * _itemsPerPage > _filteredProperties.length ? _filteredProperties.length : _currentPage * _itemsPerPage} of ${_filteredProperties.length}",
            style: TextStyle(fontSize: 11, color: isDarkMode ? Colors.grey[400] : Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final buttonsWidget = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _compactPageButton(
            icon: Icons.chevron_left,
            onTap: _currentPage > 1 ? _previousPage : null,
            isDarkMode: isDarkMode,
          ),
          if (_totalPages <= 5)
            ...List.generate(_totalPages, (index) => _compactPageNumber(index + 1, isDarkMode))
          else if (_currentPage <= 3) ...[
            ...List.generate(4, (index) => _compactPageNumber(index + 1, isDarkMode)),
            const Text("..."),
            _compactPageNumber(_totalPages, isDarkMode),
          ] else if (_currentPage >= _totalPages - 2) ...[
            _compactPageNumber(1, isDarkMode),
            const Text("..."),
            ...List.generate(4, (index) => _compactPageNumber(_totalPages - 3 + index, isDarkMode)),
          ] else ...[
            _compactPageNumber(1, isDarkMode),
            const Text("..."),
            _compactPageNumber(_currentPage - 1, isDarkMode),
            _compactPageNumber(_currentPage, isDarkMode),
            _compactPageNumber(_currentPage + 1, isDarkMode),
            const Text("..."),
            _compactPageNumber(_totalPages, isDarkMode),
          ],
          _compactPageButton(
            icon: Icons.chevron_right,
            onTap: _currentPage < _totalPages ? _nextPage : null,
            isDarkMode: isDarkMode,
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: isMobile
          ? Column(
        children: [
          entriesWidget,
          const SizedBox(height: 10),
          buttonsWidget,
        ],
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          entriesWidget,
          buttonsWidget,
        ],
      ),
    );
  }

  Widget _compactPageButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: onTap,
        color: onTap != null ? const Color(0xFF6366F1) : (isDarkMode ? Colors.grey[600] : Colors.grey),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
    );
  }

  Widget _compactPageNumber(int pageNum, bool isDarkMode) {
    final isSelected = _currentPage == pageNum;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: () => _goToPage(pageNum),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: Text(
            pageNum.toString(),
            style: TextStyle(
              color: isSelected ? Colors.white : (isDarkMode ? Colors.white70 : const Color(0xFF1E293B)),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
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
          const SizedBox(height: 40),
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'No properties found'
                : 'No properties match your search',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search terms or filter',
              style: TextStyle(color: Colors.grey[500]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Reset Search'),
            ),
          ],
        ],
      ),
    );
  }
}