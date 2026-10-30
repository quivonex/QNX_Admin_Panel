import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'dart:html' as html;
import '../../api/api_service.dart';
import '../../models/qnx_admin/company_model.dart';
import '../../models/qnx_admin/agreement_model.dart';
import '../../api/api_response.dart';
import 'package:linked_scroll_controller/linked_scroll_controller.dart';

class CompanyAllScreen extends StatefulWidget {
  const CompanyAllScreen({super.key});

  @override
  State<CompanyAllScreen> createState() => _CompanyAllScreenState();
}

class _CompanyAllScreenState extends State<CompanyAllScreen> {
  final CompanyAllService _service = CompanyAllService();
  final CompanySoftDeleteService _softDeleteService = CompanySoftDeleteService();
  final CompanyRestoreService _restoreService = CompanyRestoreService();
  final AgreementProductService _productService = AgreementProductService();

  List<CompanyAllModel> companies = [];
  List<CompanyAllModel> filtered = [];
  bool isLoading = true;
  String filterStatus = "All";

  String searchQuery = '';
  String filterType = 'Name';
  final TextEditingController _searchController = TextEditingController();

  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  CompanyAllModel? selectedCompany;
  List<AgreementProductModel> companyProducts = [];
  bool isLoadingProducts = false;

  // Premium gradient colors (matching dashboard)
  static const Color _premiumPrimary = Color(0xFF4158D0);
  static const Color _premiumSecondary = Color(0xFFC850C0);

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();
    loadCompanies();
  }

  @override
  void dispose() {
    _headerHorizontalController.dispose();
    _rowsHorizontalController.dispose();
    _verticalController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadCompanies() async {
    try {
      final response = await _service.getCompanies();
      if (mounted) {
        setState(() {
          // Sort by ID descending - most recent first
          companies = response.data..sort((a, b) => b.id.compareTo(a.id));
          applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load companies")),
        );
      }
    }
  }

  // ---------- Premium Details Popup ----------
  void _showCompanyDetailsPopup(CompanyAllModel company) async {
    // First fetch products for this company
    setState(() {
      isLoadingProducts = true;
    });
    try {
      final response = await _productService.getProductsByCompany(company.id.toString());
      setState(() {
        companyProducts = response.data;
        isLoadingProducts = false;
      });
    } catch (e) {
      setState(() => isLoadingProducts = false);
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.transparent,
        child: LayoutBuilder(
          builder: (context, constraints) {
            double dialogWidth = constraints.maxWidth * 0.9;
            if (constraints.maxWidth > 600) dialogWidth = 600;
            if (constraints.maxWidth > 800) dialogWidth = 700;
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
                    const Color(0xFFF8F9FA),
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
                  // Premium Header with Company Logo
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_premiumPrimary, _premiumSecondary],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(28),
                        topRight: Radius.circular(28),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Company Logo
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: company.logo != null && company.logo!.isNotEmpty
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              company.logo!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.business,
                                size: 30,
                                color: Colors.grey,
                              ),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              },
                            ),
                          )
                              : const Icon(
                            Icons.business,
                            size: 30,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                company.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                company.ownerName,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(ctx),
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
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
                          // Status Row (Fixed Overflow using Wrap)
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _premiumStatusChip(
                                company.isActive ? 'Active' : 'Inactive',
                                company.isActive ? Colors.green : Colors.red,
                              ),
                              if (company.referralCode != null && company.referralCode!.isNotEmpty)
                                _premiumStatusChip(
                                  'Ref: ${company.referralCode}',
                                  _premiumPrimary,
                                  icon: Icons.share,
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Basic Information Section
                          _buildPremiumSection(
                            title: "Basic Information",
                            icon: Icons.info_outline,
                            children: [
                              _infoRow("Name", company.name),
                              _infoRow("Owner", company.ownerName),
                              _infoRow("Email", company.email),
                              _infoRow("Phone", company.phoneNumber),
                              _infoRow("GST", company.gstNumber),
                              _infoRow("IAN No", company.ianNo),
                              _infoRow("PAN No", company.companyPanNo),
                              _infoRow("Reg No", company.registrationNo),
                              _infoRow("Firm Reg Year", company.farmRegistrationYear.toString()),
                              _infoRow("Slogan", company.companySlogan),
                              _infoRow("Website", company.websiteUrl),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Referral Information Section
                          _buildPremiumSection(
                            title: "Referral Information",
                            icon: Icons.share_outlined,
                            children: [
                              _infoRow("Referral Code", company.referralCode ?? '-'),
                              _infoRow("Marketing Partner", company.marketingPartnerName ?? '-'),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Location Section
                          _buildPremiumSection(
                            title: "Location",
                            icon: Icons.location_on_outlined,
                            children: [
                              _infoRow("Address", company.address),
                              _infoRow("State", company.state),
                              _infoRow("District", company.district),
                              _infoRow("Taluka", company.taluka),
                              _infoRow("Village", company.village),
                              _infoRow("Pincode", company.pincode),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Contact & Social Section with Social Icons
                          if (company.multipleEmailIds.isNotEmpty ||
                              company.contacts.isNotEmpty ||
                              company.socialMediaAccounts.isNotEmpty)
                            _buildPremiumSection(
                              title: "Contact & Social",
                              icon: Icons.contact_mail_outlined,
                              children: [
                                if (company.multipleEmailIds.isNotEmpty)
                                  _infoRow("Additional Emails", company.multipleEmailIds.join(", "), isLong: true),
                                if (company.contacts.isNotEmpty)
                                  _infoRow("Contacts", company.contacts.join(", "), isLong: true),
                                if (company.socialMediaAccounts.isNotEmpty)
                                  _buildSocialMediaRow(company.socialMediaAccounts),
                              ],
                            ),
                          const SizedBox(height: 20),

                          // Created Information
                          _buildPremiumSection(
                            title: "Created Information",
                            icon: Icons.calendar_today_outlined,
                            children: [
                              _infoRow("Created By", company.user.toString()),
                              _infoRow("Created At", company.createdAt.length >= 10 ? company.createdAt.substring(0, 10) : company.createdAt),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Products Section with Images
                          if (isLoadingProducts)
                            const Center(child: CircularProgressIndicator())
                          else if (companyProducts.isNotEmpty) ...[
                            _buildPremiumSection(
                              title: "Products (${companyProducts.length})",
                              icon: Icons.shopping_bag_outlined,
                              children: [
                                _buildProductGridWithImages(),
                              ],
                            ),
                          ] else if (!isLoadingProducts) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text('No products found for this company.'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Action Buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (company.isActive)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                softDeleteCompany(company.id);
                              },
                              icon: const Icon(Icons.block, size: 18),
                              label: const Text('Deactivate', style: TextStyle(fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        if (!company.isActive)
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                restoreCompany(company.id);
                              },
                              icon: const Icon(Icons.check_circle, size: 18),
                              label: const Text('Activate', style: TextStyle(fontWeight: FontWeight.w600)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                      ],
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

// Add this helper method for Social Media with icons
  Widget _buildSocialMediaRow(Map<String, dynamic> socialMediaAccounts) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Social Media",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: socialMediaAccounts.entries.map((entry) {
              IconData socialIcon;
              Color iconColor;

              switch (entry.key.toLowerCase()) {
                case 'facebook':
                  socialIcon = Icons.facebook;
                  iconColor = Colors.blue.shade700;
                  break;
                case 'instagram':
                  socialIcon = Icons.camera_alt;
                  iconColor = Colors.purple.shade700;
                  break;
                case 'twitter':
                case 'x':
                  socialIcon = Icons.chat;
                  iconColor = Colors.black;
                  break;
                case 'linkedin':
                  socialIcon = Icons.work;
                  iconColor = Colors.blue.shade800;
                  break;
                case 'youtube':
                  socialIcon = Icons.play_circle;
                  iconColor = Colors.red.shade700;
                  break;
                case 'whatsapp':
                  socialIcon = Icons.chat;
                  iconColor = Colors.green.shade700;
                  break;
                case 'telegram':
                  socialIcon = Icons.send;
                  iconColor = Colors.blue.shade500;
                  break;
                default:
                  socialIcon = Icons.link;
                  iconColor = Colors.grey.shade700;
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: iconColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(socialIcon, size: 14, color: iconColor),
                    const SizedBox(width: 6),
                    Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 11,
                        color: iconColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

// Updated Product Grid with proper images
  Widget _buildProductGridWithImages() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    int crossAxisCount = 3;
    double childAspectRatio = 0.85;
    if (isMobile) {
      crossAxisCount = 2;
      childAspectRatio = 1.0;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: companyProducts.length,
      itemBuilder: (context, index) {
        final product = companyProducts[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: product.thumbnailS3Key.isNotEmpty
                      ? Image.network(
                    product.thumbnailS3Key,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                          const SizedBox(height: 4),
                          Text(
                            'No Image',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                  )
                      : Container(
                    color: Colors.grey.shade200,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image, size: 40, color: Colors.grey),
                        const SizedBox(height: 4),
                        Text(
                          'No Image',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Product Details
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        '₹${product.price}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: product.status == 'approved'
                              ? Colors.green.shade100
                              : product.status == 'pending'
                              ? Colors.orange.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.status,
                          style: TextStyle(
                            fontSize: 9,
                            color: product.status == 'approved'
                                ? Colors.green.shade800
                                : product.status == 'pending'
                                ? Colors.orange.shade800
                                : Colors.red.shade800,
                            fontWeight: FontWeight.w600,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_premiumPrimary, _premiumSecondary]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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

  Widget _infoRow(String label, String value, {bool isLong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.normal,
                color: Color(0xFF1A1A2E),
              ),
              maxLines: isLong ? 3 : null,
              overflow: isLong ? TextOverflow.ellipsis : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    int crossAxisCount = 3;
    double childAspectRatio = 0.9;
    if (isMobile) {
      crossAxisCount = 2;
      childAspectRatio = 1.2;
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: companyProducts.length,
      itemBuilder: (context, index) {
        final product = companyProducts[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: product.thumbnailS3Key.isNotEmpty
                      ? Image.network(
                    product.thumbnailS3Key,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade100,
                        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    },
                  )
                      : Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                  ),
                ),
              ),
              // Product Details
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        '₹${product.price}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: product.status == 'approved'
                              ? Colors.green.shade100
                              : product.status == 'pending'
                              ? Colors.orange.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.status,
                          style: TextStyle(
                            fontSize: 9,
                            color: product.status == 'approved'
                                ? Colors.green.shade800
                                : product.status == 'pending'
                                ? Colors.orange.shade800
                                : Colors.red.shade800,
                            fontWeight: FontWeight.w600,
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
    );
  }

  Future<void> fetchProductsForCompany(int companyId) async {
    setState(() {
      isLoadingProducts = true;
      companyProducts = [];
    });
    try {
      final response = await _productService.getProductsByCompany(companyId.toString());
      setState(() {
        companyProducts = response.data;
        isLoadingProducts = false;
      });
    } catch (e) {
      setState(() => isLoadingProducts = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load products: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void onCompanyRowTap(CompanyAllModel company) {
    setState(() {
      if (selectedCompany == company) {
        selectedCompany = null;
        companyProducts = [];
      } else {
        selectedCompany = company;
        fetchProductsForCompany(company.id);
      }
    });
  }

  void applyFilters() {
    List<CompanyAllModel> temp = companies;

    if (filterStatus == "Active") {
      temp = temp.where((c) => c.isActive).toList();
    } else if (filterStatus == "Inactive") {
      temp = temp.where((c) => !c.isActive).toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      temp = temp.where((c) {
        switch (filterType) {
          case 'Name':
            return c.name.toLowerCase().contains(query);
          case 'Owner':
            return c.ownerName.toLowerCase().contains(query);
          case 'Email':
            return c.email.toLowerCase().contains(query);
          case 'Phone':
            return c.phoneNumber.toLowerCase().contains(query);
          default:
            return false;
        }
      }).toList();
    }

    setState(() {
      filtered = temp;
      totalPages = (filtered.length / itemsPerPage).ceil();
      if (currentPage > totalPages) currentPage = totalPages;
      if (currentPage < 1) currentPage = 1;
    });
  }

  void setStatusFilter(String type) {
    setState(() {
      filterStatus = type;
      currentPage = 1;
      applyFilters();
    });
  }

  void onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
      currentPage = 1;
      applyFilters();
    });
  }

  void onFilterTypeChanged(String? newType) {
    setState(() {
      filterType = newType!;
      currentPage = 1;
      applyFilters();
    });
  }

  void resetFilters() {
    setState(() {
      searchQuery = '';
      filterType = 'Name';
      filterStatus = 'All';
      currentPage = 1;
      itemsPerPage = 10;
      _searchController.clear();
      applyFilters();
    });
  }

  Future<void> softDeleteCompany(int companyId) async {
    try {
      final model = CompanySoftDeleteModel(companyId: companyId);
      final response = await _softDeleteService.deleteCompany(model);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: Colors.green),
        );
        loadCompanies();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete company"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> restoreCompany(int companyId) async {
    try {
      final model = CompanyRestoreModel(companyId: companyId);
      final response = await _restoreService.restoreCompany(model);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: Colors.green),
        );
        loadCompanies();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to restore company"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ---------- Filter Header (FIXED OVERFLOW) ----------
  Widget _buildHeader(bool isMobile) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 120,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: filterType,
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
                    style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
                    isExpanded: true,
                    onChanged: onFilterTypeChanged,
                    items: const [
                      DropdownMenuItem(value: 'Name', child: Text('Name')),
                      DropdownMenuItem(value: 'Owner', child: Text('Owner')),
                      DropdownMenuItem(value: 'Email', child: Text('Email')),
                      DropdownMenuItem(value: 'Phone', child: Text('Phone')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search by ${filterType.toLowerCase()}...",
                      prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF6366F1)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          onSearchChanged('');
                        },
                      )
                          : null,
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildExportIcons(),
                const SizedBox(width: 12),
                ..._buildFilterChips(),
                const SizedBox(width: 12),
                Text(
                  "Total: ${filtered.length}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                IconButton(
                  onPressed: resetFilters,
                  icon: const Icon(Icons.refresh),
                  color: Colors.red,
                  tooltip: "Reset",
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(12),
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
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Container(
                width: 120,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: filterType,
                    isExpanded: true,
                    icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF6366F1)),
                    style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13),
                    onChanged: onFilterTypeChanged,
                    items: const [
                      DropdownMenuItem(value: 'Name', child: Text('Name')),
                      DropdownMenuItem(value: 'Owner', child: Text('Owner')),
                      DropdownMenuItem(value: 'Email', child: Text('Email')),
                      DropdownMenuItem(value: 'Phone', child: Text('Phone')),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 250,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search by ${filterType.toLowerCase()}...",
                      prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF6366F1)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchController.clear();
                          onSearchChanged('');
                        },
                      )
                          : null,
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildExportIcons(),
              const SizedBox(width: 12),
              ..._buildFilterChips(),
              const SizedBox(width: 12),
              Text(
                "Total: ${filtered.length}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              IconButton(
                onPressed: resetFilters,
                icon: const Icon(Icons.refresh),
                color: Colors.red,
                tooltip: "Reset",
              ),
            ],
          ),
        ),
      );
    }
  }

  List<Widget> _buildFilterChips() {
    return ["All", "Active", "Inactive"].map((type) {
      final isSelected = filterStatus == type;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          label: Text(type),
          selected: isSelected,
          onSelected: (_) => setStatusFilter(type),
          selectedColor: const Color(0xFF6366F1),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 11,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildExportIcons() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _iconButton(
          icon: MaterialCommunityIcons.file_excel,
          color: Colors.green,
          onTap: exportExcel,
          tooltip: "Export Excel",
        ),
        _iconButton(
          icon: MaterialCommunityIcons.file_pdf_box,
          color: Colors.red,
          onTap: exportPDF,
          tooltip: "Export PDF",
        ),
        _iconButton(
          icon: MaterialCommunityIcons.file_word_box,
          color: Colors.blue,
          onTap: exportDOC,
          tooltip: "Export DOC",
        ),
      ],
    );
  }

  Widget _iconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  // ---------- Export functions ----------
  void exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['Sheet1'];
    sheet.appendRow([
      "SR No", "Name", "Owner", "Email", "Phone", "Address", "GST", "State",
      "District", "Taluka", "Village", "Pincode", "Company Slogan",
      "Firm Reg Year", "Registration No", "Company PAN No", "IAN No",
      "Website URL", "Referral Code", "Marketing Partner Name",
      "Status", "Created By", "Created At"
    ]);
    int srNo = 1;
    for (var c in filtered) {
      sheet.appendRow([
        srNo++,
        c.name, c.ownerName, c.email, c.phoneNumber, c.address,
        c.gstNumber, c.state, c.district, c.taluka, c.village, c.pincode,
        c.companySlogan, c.farmRegistrationYear, c.registrationNo,
        c.companyPanNo, c.ianNo, c.websiteUrl,
        c.referralCode ?? "-",
        c.marketingPartnerName ?? "-",
        c.isActive ? "Active" : "Inactive",
        c.user.toString(),

        c.createdAt
      ]);
    }
    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "companies.xlsx")
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }

  Future<void> exportPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: [
              "SR No", "Name", "Owner", "Email", "Phone", "Referral Code", "Partner Name", "Status"
            ],
            data: filtered.asMap().entries.map((entry) {
              final c = entry.value;
              final srNo = entry.key + 1;
              return [
                srNo.toString(),
                c.name,
                c.ownerName,
                c.email,
                c.phoneNumber,
                c.referralCode ?? "-",
                c.marketingPartnerName ?? "-",
                c.isActive ? "Active" : "Inactive"
              ];
            }).toList(),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void exportDOC() {
    final content = StringBuffer();
    content.writeln("Company List\n");
    content.writeln("=" * 50);
    int srNo = 1;
    for (var c in filtered) {
      content.writeln("SR No: ${srNo++}");
      content.writeln("Name: ${c.name}");
      content.writeln("Owner: ${c.ownerName}");
      content.writeln("Email: ${c.email}");
      content.writeln("Phone: ${c.phoneNumber}");
      content.writeln("Referral Code: ${c.referralCode ?? '-'}");
      content.writeln("Marketing Partner: ${c.marketingPartnerName ?? '-'}");
      content.writeln("Status: ${c.isActive ? "Active" : "Inactive"}");
      content.writeln("-------------------------");
    }
    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "companies.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ---------- Table helpers ----------
  Widget _tableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: Color(0xFF1E293B),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _tableCell(String text, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          fontSize: 10,
          color: const Color(0xFF4B5563),
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ---------- Pagination ----------
  Widget _buildPagination() {
    if (filtered.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: isMobile
          ? Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Show ", style: TextStyle(fontSize: 12)),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButton<int>(
                  value: itemsPerPage,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  style: const TextStyle(fontSize: 12),
                  items: rowsPerPageOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      itemsPerPage = v!;
                      currentPage = 1;
                      applyFilters();
                    });
                  },
                ),
              ),
              const Text(" entries", style: TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: [
              _compactPageButton(
                icon: Icons.chevron_left,
                onTap: currentPage > 1 ? () => setState(() { currentPage--; applyFilters(); }) : null,
              ),
              if (totalPages <= 5)
                ...List.generate(totalPages, (index) => _compactPageNumber(index + 1))
              else if (currentPage <= 3) ...[
                ...List.generate(4, (index) => _compactPageNumber(index + 1)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
                _compactPageNumber(totalPages),
              ] else if (currentPage >= totalPages - 2) ...[
                _compactPageNumber(1),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
                ...List.generate(4, (index) => _compactPageNumber(totalPages - 3 + index)),
              ] else ...[
                _compactPageNumber(1),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
                _compactPageNumber(currentPage - 1),
                _compactPageNumber(currentPage),
                _compactPageNumber(currentPage + 1),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
                _compactPageNumber(totalPages),
              ],
              _compactPageButton(
                icon: Icons.chevron_right,
                onTap: currentPage < totalPages ? () => setState(() { currentPage++; applyFilters(); }) : null,
              ),
            ],
          ),
        ],
      )
          : Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text("Show ", style: TextStyle(fontSize: 12)),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButton<int>(
                  value: itemsPerPage,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  style: const TextStyle(fontSize: 12),
                  items: rowsPerPageOptions
                      .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      itemsPerPage = v!;
                      currentPage = 1;
                      applyFilters();
                    });
                  },
                ),
              ),
              const Text(" entries", style: TextStyle(fontSize: 12)),
              const SizedBox(width: 12),
              Text(
                "Showing ${filtered.isEmpty ? 0 : (currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filtered.length ? filtered.length : currentPage * itemsPerPage} of ${filtered.length}",
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          Row(
            children: [
              _compactPageButton(
                icon: Icons.chevron_left,
                onTap: currentPage > 1 ? () => setState(() { currentPage--; applyFilters(); }) : null,
              ),
              if (totalPages <= 5)
                ...List.generate(totalPages, (index) => _compactPageNumber(index + 1))
              else if (currentPage <= 3) ...[
                ...List.generate(4, (index) => _compactPageNumber(index + 1)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
                _compactPageNumber(totalPages),
              ] else if (currentPage >= totalPages - 2) ...[
                _compactPageNumber(1),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
                ...List.generate(4, (index) => _compactPageNumber(totalPages - 3 + index)),
              ] else ...[
                _compactPageNumber(1),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
                _compactPageNumber(currentPage - 1),
                _compactPageNumber(currentPage),
                _compactPageNumber(currentPage + 1),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2),
                  child: Text("...", style: TextStyle(fontSize: 11, color: Colors.grey)),
                ),
                _compactPageNumber(totalPages),
              ],
              _compactPageButton(
                icon: Icons.chevron_right,
                onTap: currentPage < totalPages ? () => setState(() { currentPage++; applyFilters(); }) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactPageButton({required IconData icon, required VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16),
        onPressed: onTap,
        color: onTap != null ? const Color(0xFF6366F1) : Colors.grey,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      ),
    );
  }

  Widget _compactPageNumber(int pageNum) {
    final isSelected = currentPage == pageNum;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            currentPage = pageNum;
            applyFilters();
          });
        },
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          child: Text(
            pageNum.toString(),
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 700;

    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    if (start >= filtered.length) start = 0;
    List<CompanyAllModel> pageData = filtered.isEmpty
        ? []
        : filtered.sublist(start, end > filtered.length ? filtered.length : end);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Company Management",
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isMobile),
                  const SizedBox(height: 20),

                  // Fixed header - SR No column added, ID removed
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SingleChildScrollView(
                      controller: _headerHorizontalController,
                      scrollDirection: Axis.horizontal,
                      child: Table(
                        border: TableBorder(
                          horizontalInside: BorderSide(color: Colors.grey.shade300),
                          verticalInside: BorderSide(color: Colors.grey.shade300),
                          top: BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                        columnWidths: const {
                          0: FixedColumnWidth(60),   // SR No
                          1: FixedColumnWidth(60),   // Logo
                          2: FixedColumnWidth(120),  // Name
                          3: FixedColumnWidth(120),  // Owner
                          4: FixedColumnWidth(120),  // Email
                          5: FixedColumnWidth(100),  // Phone
                          6: FixedColumnWidth(130),  // GST
                          7: FixedColumnWidth(80),   // State
                          8: FixedColumnWidth(80),   // District
                          9: FixedColumnWidth(80),   // Taluka
                          10: FixedColumnWidth(80),  // Village
                          11: FixedColumnWidth(70),  // Pincode
                          12: FixedColumnWidth(150), // Slogan
                          13: FixedColumnWidth(80),  // Farm Year
                          14: FixedColumnWidth(100), // Reg No
                          15: FixedColumnWidth(100), // PAN No
                          16: FixedColumnWidth(100), // IAN No
                          17: FixedColumnWidth(120), // Website
                          18: FixedColumnWidth(120), // Multiple Emails
                          19: FixedColumnWidth(120), // Contacts
                          20: FixedColumnWidth(120), // Social Media
                          21: FixedColumnWidth(100), // Referral Code
                          22: FixedColumnWidth(120), // Partner Name
                          23: FixedColumnWidth(80),  // Status
                          24: FixedColumnWidth(100), // Created
                          25: FixedColumnWidth(80),  // Actions
                        },
                        children: [
                          TableRow(
                            children: [
                              _tableHeader("SR No"),
                              _tableHeader("Logo"),
                              _tableHeader("Name"),
                              _tableHeader("Owner"),
                              _tableHeader("Email"),
                              _tableHeader("Phone"),
                              _tableHeader("GST"),
                              _tableHeader("State"),
                              _tableHeader("District"),
                              _tableHeader("Taluka"),
                              _tableHeader("Village"),
                              _tableHeader("Pincode"),
                              _tableHeader("Slogan"),
                              _tableHeader("Firm Year"),
                              _tableHeader("Reg No"),
                              _tableHeader("PAN No"),
                              _tableHeader("IAN No"),
                              _tableHeader("Website"),
                              _tableHeader("Multiple Emails"),
                              _tableHeader("Contacts"),
                              _tableHeader("Social Media"),
                              _tableHeader("Referral Code"),
                              _tableHeader("Partner Name"),
                              _tableHeader("Status"),
                              _tableHeader("Created"),
                              _tableHeader("Actions"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Scrollable rows - SR No added, ID removed
                  if (filtered.isEmpty)
                    SizedBox(
                      height: 200,
                      child: Center(
                        child: Text(
                          "No companies found",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    )
                  else
                    Scrollbar(
                      controller: _verticalController,
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        controller: _verticalController,
                        child: SingleChildScrollView(
                          controller: _rowsHorizontalController,
                          scrollDirection: Axis.horizontal,
                          child: Table(
                            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
                            columnWidths: const {
                              0: FixedColumnWidth(60),
                              1: FixedColumnWidth(60),
                              2: FixedColumnWidth(120),
                              3: FixedColumnWidth(120),
                              4: FixedColumnWidth(120),
                              5: FixedColumnWidth(100),
                              6: FixedColumnWidth(130),
                              7: FixedColumnWidth(80),
                              8: FixedColumnWidth(80),
                              9: FixedColumnWidth(80),
                              10: FixedColumnWidth(80),
                              11: FixedColumnWidth(70),
                              12: FixedColumnWidth(150),
                              13: FixedColumnWidth(80),
                              14: FixedColumnWidth(100),
                              15: FixedColumnWidth(100),
                              16: FixedColumnWidth(100),
                              17: FixedColumnWidth(120),
                              18: FixedColumnWidth(120),
                              19: FixedColumnWidth(120),
                              20: FixedColumnWidth(120),
                              21: FixedColumnWidth(100),
                              22: FixedColumnWidth(120),
                              23: FixedColumnWidth(80),
                              24: FixedColumnWidth(100),
                              25: FixedColumnWidth(80),
                            },
                            children: List.generate(pageData.length, (rowIndex) {
                              final company = pageData[rowIndex];
                              final isEven = rowIndex % 2 == 0;
                              final int srNo = filtered.length - ((currentPage - 1) * itemsPerPage + rowIndex);
                              return TableRow(
                                decoration: BoxDecoration(
                                  color: isEven ? Colors.white : const Color(0xFFF8FAFC),
                                ),
                                children: [
                                  _tableCell(srNo.toString()),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      height: 50,
                                      child: company.logo != null
                                          ? Image.network(
                                        company.logo!,
                                        height: 40,
                                        width: 40,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          height: 40,
                                          width: 40,
                                          color: Colors.grey[200],
                                          child: const Icon(Icons.business, size: 20, color: Colors.grey),
                                        ),
                                      )
                                          : Container(
                                        height: 40,
                                        width: 40,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.business, size: 20, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: _tableCell(company.name, isBold: true),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: _tableCell(company.ownerName),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: _tableCell(company.email),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: _tableCell(company.phoneNumber),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: _tableCell(company.gstNumber),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: _tableCell(company.state),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: _tableCell(company.district),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: _tableCell(company.taluka),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: _tableCell(company.village),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: _tableCell(company.pincode),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: _tableCell(company.companySlogan),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: _tableCell(company.farmRegistrationYear.toString()),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: _tableCell(company.registrationNo),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: _tableCell(company.companyPanNo),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: _tableCell(company.ianNo),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: _tableCell(company.websiteUrl),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: _tableCell(
                                      company.multipleEmailIds.isNotEmpty
                                          ? "${company.multipleEmailIds.length} emails"
                                          : "-",
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: _tableCell(
                                      company.contacts.isNotEmpty
                                          ? "${company.contacts.length} contacts"
                                          : "-",
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: _tableCell(
                                      company.socialMediaAccounts.isNotEmpty
                                          ? "${company.socialMediaAccounts.length} accounts"
                                          : "-",
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: _tableCell(company.referralCode ?? "-"),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: _tableCell(company.marketingPartnerName ?? "-"),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: company.isActive
                                              ? const Color(0xFFDCFCE7)
                                              : const Color(0xFFFEE2E2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          company.isActive ? "Active" : "Inactive",
                                          style: TextStyle(
                                            color: company.isActive
                                                ? const Color(0xFF15803D)
                                                : const Color(0xFFB91C1C),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _showCompanyDetailsPopup(company),
                                    child: _tableCell(
                                      company.createdAt.length >= 10
                                          ? company.createdAt.substring(0, 10)
                                          : company.createdAt,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    child: IconButton(
                                      icon: const Icon(Icons.visibility, color: _premiumPrimary, size: 18),
                                      onPressed: () => _showCompanyDetailsPopup(company),
                                      tooltip: 'View Details',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _buildPagination(),
        ],
      ),
    );
  }
}