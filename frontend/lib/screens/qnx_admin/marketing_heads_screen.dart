// lib/screens/qnx_admin/marketing_heads_screen.dart
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:html' as html;
import 'package:linked_scroll_controller/linked_scroll_controller.dart';
import '../../api/api_service.dart';
import '../../models/qnx_admin/marketing_head_model.dart';
import '../../models/qnx_admin/referral_partner_model.dart';

class MarketingHeadsScreen extends StatefulWidget {
  const MarketingHeadsScreen({super.key});

  @override
  State<MarketingHeadsScreen> createState() => _MarketingHeadsScreenState();
}

class _MarketingHeadsScreenState extends State<MarketingHeadsScreen> {
  final MarketingHeadService _service = MarketingHeadService();
  final ReferralPartnerService _referralService = ReferralPartnerService();

  List<MarketingHead> allHeads = [];
  List<MarketingHead> filteredHeads = [];
  List<MarketingHead> paginatedHeads = [];

  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  String filterType = 'Name';

  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  late LinkedScrollControllerGroup _linkedControllers;
  late ScrollController _headerHorizontalController;
  late ScrollController _rowsHorizontalController;
  final ScrollController _verticalController = ScrollController();

  // Premium gradient colors (matching dashboard)
  static const Color _premiumPrimary = Color(0xFF4158D0);
  static const Color _premiumSecondary = Color(0xFFC850C0);
  static const Color _premiumBg = Color(0xFFF5F7FA);

  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(50),   // SR No
    1: FixedColumnWidth(200),  // Full Name
    2: FixedColumnWidth(80),   // Profile Image
    3: FixedColumnWidth(210),  // Email
    4: FixedColumnWidth(110),  // Mobile
    5: FixedColumnWidth(150),  // Working Area
    6: FixedColumnWidth(80),   // Team Size
    7: FixedColumnWidth(90),   // Status
    8: FixedColumnWidth(130),  // Created At
    9: FixedColumnWidth(80),   // Actions
  };

  final List<String> headerLabels = [
    "SR No", "Full Name", "Profile", "Email", "Mobile", "Working Area", "Team Size", "Status", "Created", "Actions"
  ];

  @override
  void initState() {
    super.initState();
    _linkedControllers = LinkedScrollControllerGroup();
    _headerHorizontalController = _linkedControllers.addAndGet();
    _rowsHorizontalController = _linkedControllers.addAndGet();
    loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _headerHorizontalController.dispose();
    _rowsHorizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    try {
      final response = await _service.getMarketingHeads();
      if (mounted) {
        final List<MarketingHead> reversed = response.data.reversed.toList();
        setState(() {
          allHeads = reversed;
          applyFilters();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load data: $e")),
        );
      }
    }
  }

  void applyFilters() {
    if (searchQuery.isEmpty) {
      filteredHeads = List.from(allHeads);
    } else {
      final query = searchQuery.toLowerCase();
      filteredHeads = allHeads.where((h) {
        switch (filterType) {
          case 'Name':
            return h.fullName.toLowerCase().contains(query);
          case 'Email':
            return h.email.toLowerCase().contains(query);
          case 'Mobile':
            return h.mobile.contains(query);
          case 'Status':
            return h.status.toLowerCase().contains(query);
          default:
            return false;
        }
      }).toList();
    }
    applyPagination();
  }

  void applyPagination() {
    if (filteredHeads.isEmpty) {
      paginatedHeads = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }
    totalPages = (filteredHeads.length / itemsPerPage).ceil();
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    if (end > filteredHeads.length) end = filteredHeads.length;
    paginatedHeads = filteredHeads.sublist(start, end);
    setState(() {});
  }

  void nextPage() {
    if (currentPage < totalPages) {
      setState(() { currentPage++; applyPagination(); });
    }
  }

  void previousPage() {
    if (currentPage > 1) {
      setState(() { currentPage--; applyPagination(); });
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() { currentPage = page; applyPagination(); });
    }
  }

  void changeItemsPerPage(int? value) {
    if (value != null) {
      setState(() {
        itemsPerPage = value;
        currentPage = 1;
        applyPagination();
      });
    }
  }

  void resetFilters() {
    setState(() {
      searchQuery = '';
      filterType = 'Name';
      _searchController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  // ---------------------- EXPORT ----------------------
  void exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['Marketing Heads'];
    sheet.appendRow(["SR No", "Full Name", "Email", "Mobile", "Working Area", "Team Size", "Status", "Created At"]);
    int srNo = 1;
    for (var h in filteredHeads) {
      sheet.appendRow([
        srNo++,
        h.fullName,
        h.email,
        h.mobile,
        h.workingArea,
        h.teamSize,
        h.status,
        h.createdAt,
      ]);
    }
    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "marketing_heads.xlsx")
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
            headers: ["SR No", "Name", "Email", "Mobile", "Working Area", "Team Size", "Status", "Created"],
            data: List.generate(filteredHeads.length, (index) {
              final h = filteredHeads[index];
              return [
                (index + 1).toString(),
                h.fullName,
                h.email,
                h.mobile,
                h.workingArea,
                h.teamSize.toString(),
                h.status,
                h.createdAt
              ];
            }),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void exportDOC() {
    final content = StringBuffer();
    content.writeln("Marketing Heads List\n");
    content.writeln("=" * 50);
    int srNo = 1;
    for (var h in filteredHeads) {
      content.writeln("SR No: ${srNo++}");
      content.writeln("Name: ${h.fullName}");
      content.writeln("Email: ${h.email}");
      content.writeln("Mobile: ${h.mobile}");
      content.writeln("Working Area: ${h.workingArea}");
      content.writeln("Team Size: ${h.teamSize}");
      content.writeln("Status: ${h.status}");
      content.writeln("Created: ${h.createdAt}");
      content.writeln("-" * 30);
    }
    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "marketing_heads.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // ---------------------- REJECT FLOW ----------------------
  void rejectHead(MarketingHead head) {
    TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.transparent,
          child: Container(
            width: 450,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFEF2F2), Color(0xFFFFE5E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                      child: const Icon(Icons.cancel, color: Colors.red, size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Reject Marketing Head",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF991B1B)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: reasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Enter rejection reason...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Cancel"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final reason = reasonController.text.trim();
                          if (reason.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please enter a reason")),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          try {
                            final response = await _service.rejectPartner(head.id, reason);
                            if (response.status) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(response.message), backgroundColor: Colors.orange),
                              );
                              await loadData();
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(response.message), backgroundColor: Colors.red),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Reject"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Profile image builder with click to enlarge
  Widget _buildProfileImage(String? url, double size, {bool clickable = true}) {
    if (url == null || url.isEmpty) {
      return const Icon(Icons.person, size: 24, color: Colors.white70);
    }
    Widget image = ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(Icons.person, size: size * 0.6, color: Colors.white70),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
      ),
    );
    if (clickable) {
      return GestureDetector(
        onTap: () => _showFullImageDialog(url),
        child: image,
      );
    }
    return image;
  }

  void _showFullImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Profile Picture", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------- PREMIUM DETAIL POPUP ----------------------
  void showDetailsPopup(MarketingHead head) {
    final bool isPending = head.status.toLowerCase() == 'pending';
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
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
                    // Premium Header
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
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white,
                            child: ClipOval(
                              child: _buildProfileImage(head.profileImage, 50, clickable: false),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  head.fullName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  head.email,
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
                            // Status Row
                            Row(
                              children: [
                                _premiumStatusChip(
                                  head.status,
                                  head.status == 'approved' ? Colors.green : (head.status == 'rejected' ? Colors.red : Colors.orange),
                                ),
                                const SizedBox(width: 12),
                                if (head.referralCode.isNotEmpty)
                                  _premiumStatusChip(
                                    "Ref: ${head.referralCode}",
                                    _premiumPrimary,
                                    icon: Icons.share,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Basic Information Section (No ID)
                            _buildPremiumSection(
                              title: "Basic Information",
                              icon: Icons.person_outline,
                              children: [
                                _infoRow("Full Name", head.fullName),
                                _infoRow("Status", head.status),
                                _infoRow("Created", head.createdAt.substring(0, 10)),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Contact Details Section
                            _buildPremiumSection(
                              title: "Contact Details",
                              icon: Icons.contact_phone_outlined,
                              children: [
                                _infoRow("Email", head.email),
                                _infoRow("Mobile", head.mobile),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Professional Details Section
                            _buildPremiumSection(
                              title: "Professional Details",
                              icon: Icons.work_outline,
                              children: [
                                _infoRow("Working Area", head.workingArea),
                                _infoRow("Profession", head.profession),
                                _infoRow("Experience", head.experience),
                                _infoRow("Team Size", head.teamSize.toString()),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Location Section
                            _buildPremiumSection(
                              title: "Location",
                              icon: Icons.location_on_outlined,
                              children: [
                                _infoRow("State", head.state),
                                _infoRow("District", head.district),
                                _infoRow("Taluka", head.taluka),
                                _infoRow("Village", head.village),
                                _infoRow("Pincode", head.pincode),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Marketing Info Section
                            _buildPremiumSection(
                              title: "Marketing Info",
                              icon: Icons.flag_outlined,
                              children: [
                                _infoRow("Referral Code", head.referralCode),
                                if (head.promotionPlatforms.isNotEmpty)
                                  _infoRow("Promotion Platforms", head.promotionPlatforms.join(", "), isLong: true),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // View referred partners button
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _navigateToReferredPartners(head);
                                },
                                icon: const Icon(Icons.people_alt, size: 18),
                                label: const Text("View Referred Partners"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _premiumPrimary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Action buttons if pending
                    if (isPending)
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
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showApproveFlow(head);
                                },
                                icon: const Icon(Icons.check_circle, size: 18),
                                label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  rejectHead(head);
                                },
                                icon: const Icon(Icons.cancel, size: 18),
                                label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w600)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A2E),
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
            width: 140,
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

  void _navigateToReferredPartners(MarketingHead head) async {
    try {
      final response = await _referralService.getReferredPartners(head.id);
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReferredPartnersScreen(
            headName: head.fullName,
            referralCode: response.referralCode,
            partners: response.data,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load referred partners: $e")),
      );
    }
  }

  // ---------------------- APPROVE FLOW ----------------------
  void _showApproveFlow(MarketingHead head) async {
    String? email = head.email;
    String? otp;
    String? username;
    String? password;

    final sendOtpResult = await _showSendOtpDialog(email);
    if (sendOtpResult == null) return;
    email = sendOtpResult;

    final verifyResult = await _showVerifyOtpDialog(email!);
    if (verifyResult == null) return;
    otp = verifyResult;

    final regResult = await _showCompleteRegistrationDialog(email!, head);
    if (regResult != null) {
      await loadData();
    }
  }

  Future<String?> _showSendOtpDialog(String initialEmail) async {
    TextEditingController emailCtrl = TextEditingController(text: initialEmail);
    bool loading = false;
    String? error;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.transparent,
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _premiumPrimary.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.mark_email_unread, color: _premiumPrimary, size: 28),
                    ),
                    const SizedBox(height: 12),
                    const Text("Send OTP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      "We'll send a one-time password to the email address.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: emailCtrl,
                      decoration: InputDecoration(
                        labelText: "Email Address",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        errorText: error,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text("Cancel", style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: loading
                                ? null
                                : () async {
                              if (emailCtrl.text.trim().isEmpty) {
                                setState(() => error = "Email is required");
                                return;
                              }
                              setState(() => loading = true);
                              try {
                                await _service.sendOtp(emailCtrl.text.trim());
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("OTP sent successfully!"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.pop(context, emailCtrl.text.trim());
                                }
                              } catch (e) {
                                setState(() => error = e.toString());
                              } finally {
                                if (context.mounted) setState(() => loading = false);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _premiumPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: loading
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                                : const Text("Send OTP", style: TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      ],
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

  Future<String?> _showVerifyOtpDialog(String email) async {
    // सर्व variables method मध्येच declare करा
    TextEditingController otpCtrl = TextEditingController();
    bool loading = false;
    bool resending = false;
    String? error;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.transparent,
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.verified, color: Colors.green, size: 28),
                    ),
                    const SizedBox(height: 12),
                    const Text("Verify OTP", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      "Enter the 6-digit code sent to $email",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: otpCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "OTP",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        errorText: error,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: const Text("Cancel", style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextButton(
                            onPressed: resending
                                ? null
                                : () async {
                              setState(() {
                                resending = true;
                                error = null;
                              });
                              try {
                                await _service.sendOtp(email);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("OTP resent successfully!"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                setState(() => error = e.toString());
                              } finally {
                                if (context.mounted) setState(() => resending = false);
                              }
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: resending
                                ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                                : const Text(
                              "Resend OTP",
                              style: TextStyle(
                                color: _premiumPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: loading
                                ? null
                                : () async {
                              if (otpCtrl.text.trim().isEmpty) {
                                setState(() => error = "OTP is required");
                                return;
                              }
                              setState(() => loading = true);
                              try {
                                await _service.verifyOtp(email, otpCtrl.text.trim());
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("OTP verified successfully!"),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.pop(context, otpCtrl.text.trim());
                                }
                              } catch (e) {
                                setState(() => error = e.toString());
                              } finally {
                                if (context.mounted) setState(() => loading = false);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _premiumPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            child: loading
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              "Verify OTP",
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
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

  Future<bool?> _showCompleteRegistrationDialog(String email, MarketingHead head) async {
    TextEditingController usernameCtrl = TextEditingController();
    TextEditingController passwordCtrl = TextEditingController();
    TextEditingController confirmCtrl = TextEditingController();
    bool loading = false;
    String? error;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              backgroundColor: Colors.transparent,
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: _premiumPrimary.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.person_add, color: _premiumPrimary, size: 28),
                    ),
                    const SizedBox(height: 12),
                    const Text("Complete Registration", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text("Create credentials for ${head.fullName}", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    const SizedBox(height: 20),
                    TextField(
                      controller: usernameCtrl,
                      decoration: InputDecoration(labelText: "Username", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(labelText: "Password", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: confirmCtrl,
                      obscureText: true,
                      decoration: InputDecoration(labelText: "Confirm Password", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 6),
                      Text(error!, style: const TextStyle(color: Colors.red, fontSize: 11)),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)),
                            child: const Text("Cancel"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: loading ? null : () async {
                              final username = usernameCtrl.text.trim();
                              final password = passwordCtrl.text.trim();
                              final confirm = confirmCtrl.text.trim();
                              if (username.isEmpty) {
                                setState(() => error = "Username required");
                                return;
                              }
                              if (password.isEmpty) {
                                setState(() => error = "Password required");
                                return;
                              }
                              if (password != confirm) {
                                setState(() => error = "Passwords do not match");
                                return;
                              }
                              setState(() => loading = true);
                              try {
                                final response = await _service.completeRegistration(
                                  email: email,
                                  username: username,
                                  password: password,
                                  role: 'marketing_head',
                                );
                                if (response.status) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(response.message), backgroundColor: Colors.green),
                                    );
                                    Navigator.pop(context, true);
                                  }
                                } else {
                                  setState(() => error = response.message);
                                }
                              } catch (e) {
                                setState(() => error = e.toString());
                              } finally {
                                if (context.mounted) setState(() => loading = false);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _premiumPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Complete"),
                          ),
                        ),
                      ],
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

  // ---------------------- FILTER UI ----------------------
  Widget _buildFilterSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: isMobile
          ? Column(
        children: [
          Row(
            children: [
              _buildFilterDropdown(),
              const SizedBox(width: 12),
              Expanded(child: _buildSearchField()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildExportIcons(),
              Row(
                children: [
                  Text("Total: ${filteredHeads.length}"),
                  const SizedBox(width: 8),
                  IconButton(onPressed: resetFilters, icon: const Icon(Icons.refresh), color: Colors.red),
                ],
              ),
            ],
          ),
        ],
      )
          : Row(
        children: [
          _buildFilterDropdown(),
          const SizedBox(width: 12),
          Expanded(child: _buildSearchField()),
          const SizedBox(width: 12),
          _buildExportIcons(),
          const SizedBox(width: 12),
          Text("Total: ${filteredHeads.length}"),
          IconButton(onPressed: resetFilters, icon: const Icon(Icons.refresh), color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
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
          onChanged: (String? newValue) {
            setState(() {
              filterType = newValue!;
              currentPage = 1;
              applyFilters();
            });
          },
          items: ['Name', 'Email', 'Mobile', 'Status']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search by $filterType...",
          prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF6366F1)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, size: 16),
            onPressed: () {
              _searchController.clear();
              setState(() {
                searchQuery = '';
                currentPage = 1;
                applyFilters();
              });
            },
          )
              : null,
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
            currentPage = 1;
            applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildExportIcons() {
    return Row(
      children: [
        Tooltip(
          message: "Export Excel",
          child: InkWell(
            onTap: exportExcel,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Image.asset("assets/icon/xls.png", height: 20, width: 20, errorBuilder: (_, __, ___) => const Icon(Icons.table_chart, size: 20)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "Export PDF",
          child: InkWell(
            onTap: exportPDF,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Image.asset("assets/icon/pdf.png", height: 20, width: 20, errorBuilder: (_, __, ___) => const Icon(Icons.picture_as_pdf, size: 20)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "Export DOC",
          child: InkWell(
            onTap: exportDOC,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Image.asset("assets/icon/doc.png", height: 20, width: 20, errorBuilder: (_, __, ___) => const Icon(Icons.description, size: 20)),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------- TABLE HELPERS ----------------------
  Widget _tableHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _tableCell(String text, {VoidCallback? onTap, bool isBold = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 10),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // ---------------------- PAGINATION ----------------------
  Widget _buildPagination() {
    if (filteredHeads.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 700) {
            // Mobile layout
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Show ", style: TextStyle(fontSize: 11)),
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<int>(
                        value: itemsPerPage,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, size: 16),
                        style: const TextStyle(fontSize: 11),
                        items: rowsPerPageOptions
                            .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            itemsPerPage = v!;
                            currentPage = 1;
                            applyPagination();
                          });
                        },
                      ),
                    ),
                    const Text(" entries", style: TextStyle(fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _compactPageButton(
                      icon: Icons.chevron_left,
                      onTap: currentPage > 1 ? previousPage : null,
                    ),
                    ...List.generate(
                      totalPages > 3 ? 3 : totalPages,
                          (index) {
                        int pageNum;
                        if (totalPages <= 3) {
                          pageNum = index + 1;
                        } else if (currentPage == 1) {
                          pageNum = index + 1;
                        } else if (currentPage == totalPages) {
                          pageNum = totalPages - 2 + index;
                        } else {
                          pageNum = currentPage - 1 + index;
                        }
                        return _compactPageNumber(pageNum);
                      },
                    ),
                    _compactPageButton(
                      icon: Icons.chevron_right,
                      onTap: currentPage < totalPages ? nextPage : null,
                    ),
                  ],
                ),
              ],
            );
          } else {
            // Desktop layout
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text("Show ", style: TextStyle(fontSize: 11)),
                    Container(
                      height: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButton<int>(
                        value: itemsPerPage,
                        underline: const SizedBox(),
                        icon: const Icon(Icons.arrow_drop_down, size: 16),
                        style: const TextStyle(fontSize: 11),
                        items: rowsPerPageOptions
                            .map((e) => DropdownMenuItem(value: e, child: Text(e.toString())))
                            .toList(),
                        onChanged: (v) {
                          setState(() {
                            itemsPerPage = v!;
                            currentPage = 1;
                            applyPagination();
                          });
                        },
                      ),
                    ),
                    const Text(" entries", style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 8),
                    Text(
                      "Showing ${(currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filteredHeads.length ? filteredHeads.length : currentPage * itemsPerPage} of ${filteredHeads.length}",
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _compactPageButton(
                      icon: Icons.chevron_left,
                      onTap: currentPage > 1 ? previousPage : null,
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
                      onTap: currentPage < totalPages ? nextPage : null,
                    ),
                  ],
                ),
              ],
            );
          }
        },
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
        onTap: () => goToPage(pageNum),
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

  // ---------------------- MAIN BUILD ----------------------
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: _premiumBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text("Marketing Heads", style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildFilterSection(isMobile),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                children: [
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
                        columnWidths: columnWidths,
                        children: [TableRow(children: headerLabels.map((l) => _tableHeader(l)).toList())],
                      ),
                    ),
                  ),
                  Expanded(
                    child: filteredHeads.isEmpty
                        ? const Center(child: Text("No marketing heads found"))
                        : SingleChildScrollView(
                      controller: _verticalController,
                      child: SingleChildScrollView(
                        controller: _rowsHorizontalController,
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          border: TableBorder.all(color: Colors.grey.shade300),
                          columnWidths: columnWidths,
                          children: List.generate(paginatedHeads.length, (rowIndex) {
                            final head = paginatedHeads[rowIndex];
                            final bool isEven = rowIndex % 2 == 0;
                            final int srNo = filteredHeads.length - ((currentPage - 1) * itemsPerPage + rowIndex);
                            Color statusColor = head.status == 'approved'
                                ? Colors.green
                                : (head.status == 'rejected' ? Colors.red : Colors.orange);
                            return TableRow(
                              decoration: BoxDecoration(color: isEven ? Colors.white : const Color(0xFFF8FAFC)),
                              children: [
                                _tableCell(srNo.toString(), onTap: () => showDetailsPopup(head)),
                                _tableCell(head.fullName, onTap: () => showDetailsPopup(head)),
                                GestureDetector(
                                  onTap: () => showDetailsPopup(head),
                                  child: Container(
                                    height: 40,
                                    width: 40,
                                    alignment: Alignment.center,
                                    child: ClipOval(
                                      child: _buildProfileImage(head.profileImage, 35, clickable: false),
                                    ),
                                  ),
                                ),
                                _tableCell(head.email, onTap: () => showDetailsPopup(head)),
                                _tableCell(head.mobile, onTap: () => showDetailsPopup(head)),
                                _tableCell(head.workingArea, onTap: () => showDetailsPopup(head)),
                                _tableCell(head.teamSize.toString(), onTap: () => showDetailsPopup(head)),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                    child: Text(head.status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                _tableCell(head.createdAt.substring(0, 10), onTap: () => showDetailsPopup(head)),
                                IconButton(
                                  icon: const Icon(Icons.visibility, color: Color(0xFF4158D0), size: 18),
                                  onPressed: () => showDetailsPopup(head),
                                  tooltip: 'View Details',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildPagination(),
          ],
        ),
      ),
    );
  }
}

// ---------------------- REFERRED PARTNERS SCREEN (UPDATED WITH SR NO) ----------------------
class ReferredPartnersScreen extends StatefulWidget {
  final String headName;
  final String referralCode;
  final List<ReferredPartner> partners;

  const ReferredPartnersScreen({
    super.key,
    required this.headName,
    required this.referralCode,
    required this.partners,
  });

  @override
  State<ReferredPartnersScreen> createState() => _ReferredPartnersScreenState();
}

class _ReferredPartnersScreenState extends State<ReferredPartnersScreen> {
  List<ReferredPartner> filteredPartners = [];
  List<ReferredPartner> paginatedPartners = [];

  String searchQuery = '';
  String filterType = 'Name';

  int currentPage = 1;
  int itemsPerPage = 10;
  int totalPages = 1;
  final List<int> rowsPerPageOptions = [5, 10, 15, 20, 25, 30, 50];

  final TextEditingController _searchController = TextEditingController();

  final Map<int, TableColumnWidth> columnWidths = const {
    0: FixedColumnWidth(50),   // SR No
    1: FixedColumnWidth(150),  // Full Name
    2: FixedColumnWidth(55),   // Profile
    3: FixedColumnWidth(170),  // Email
    4: FixedColumnWidth(100),  // Mobile
    5: FixedColumnWidth(120),  // Working Area
    6: FixedColumnWidth(70),   // Team Size
    7: FixedColumnWidth(80),   // Status
    8: FixedColumnWidth(90),   // Created At
  };

  final List<String> headerLabels = [
    "SR No", "Full Name", "Profile", "Email", "Mobile", "Working Area", "Team Size", "Status", "Created"
  ];

  @override
  void initState() {
    super.initState();
    filteredPartners = List.from(widget.partners);
    applyFilters();
  }

  void applyFilters() {
    if (searchQuery.isEmpty) {
      filteredPartners = List.from(widget.partners);
    } else {
      final query = searchQuery.toLowerCase();
      filteredPartners = widget.partners.where((p) {
        switch (filterType) {
          case 'Name':
            return p.fullName.toLowerCase().contains(query);
          case 'Email':
            return p.email.toLowerCase().contains(query);
          case 'Mobile':
            return p.mobile.contains(query);
          case 'Status':
            return p.status.toLowerCase().contains(query);
          default:
            return false;
        }
      }).toList();
    }
    applyPagination();
  }

  void applyPagination() {
    if (filteredPartners.isEmpty) {
      paginatedPartners = [];
      totalPages = 1;
      currentPage = 1;
      setState(() {});
      return;
    }
    totalPages = (filteredPartners.length / itemsPerPage).ceil();
    if (currentPage > totalPages) currentPage = totalPages;
    if (currentPage < 1) currentPage = 1;
    int start = (currentPage - 1) * itemsPerPage;
    int end = start + itemsPerPage;
    if (end > filteredPartners.length) end = filteredPartners.length;
    paginatedPartners = filteredPartners.sublist(start, end);
    setState(() {});
  }

  void nextPage() {
    if (currentPage < totalPages) {
      setState(() { currentPage++; applyPagination(); });
    }
  }

  void previousPage() {
    if (currentPage > 1) {
      setState(() { currentPage--; applyPagination(); });
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      setState(() { currentPage = page; applyPagination(); });
    }
  }

  void changeItemsPerPage(int? value) {
    if (value != null) {
      setState(() {
        itemsPerPage = value;
        currentPage = 1;
        applyPagination();
      });
    }
  }

  void resetFilters() {
    setState(() {
      searchQuery = '';
      filterType = 'Name';
      _searchController.clear();
      currentPage = 1;
      applyFilters();
    });
  }

  void exportExcel() {
    final file = excel.Excel.createExcel();
    final sheet = file['Referred Partners'];
    sheet.appendRow(["SR No", "Full Name", "Email", "Mobile", "Working Area", "Team Size", "Status", "Created At"]);
    int srNo = 1;
    for (var p in filteredPartners) {
      sheet.appendRow([
        srNo++,
        p.fullName,
        p.email,
        p.mobile,
        p.workingArea,
        p.teamSize,
        p.status,
        p.createdAt,
      ]);
    }
    final bytes = file.encode();
    if (bytes != null) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", "referred_partners_${widget.headName.replaceAll(' ', '_')}.xlsx")
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
            headers: ["SR No", "Name", "Email", "Mobile", "Working Area", "Team Size", "Status", "Created"],
            data: List.generate(filteredPartners.length, (index) {
              final p = filteredPartners[index];
              return [
                (index + 1).toString(),
                p.fullName,
                p.email,
                p.mobile,
                p.workingArea,
                p.teamSize.toString(),
                p.status,
                p.createdAt
              ];
            }),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  void exportDOC() {
    final content = StringBuffer();
    content.writeln("Referred Partners for ${widget.headName}\n");
    content.writeln("Referral Code: ${widget.referralCode}\n");
    content.writeln("=" * 50);
    int srNo = 1;
    for (var p in filteredPartners) {
      content.writeln("SR No: ${srNo++}");
      content.writeln("Name: ${p.fullName}");
      content.writeln("Email: ${p.email}");
      content.writeln("Mobile: ${p.mobile}");
      content.writeln("Working Area: ${p.workingArea}");
      content.writeln("Team Size: ${p.teamSize}");
      content.writeln("Status: ${p.status}");
      content.writeln("Created: ${p.createdAt}");
      content.writeln("-" * 30);
    }
    final blob = html.Blob([content.toString()]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "referred_partners_${widget.headName.replaceAll(' ', '_')}.doc")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Widget _buildProfileImage(String? url, double size) {
    if (url == null || url.isEmpty) {
      return const Icon(Icons.person, size: 24, color: Colors.white70);
    }
    return GestureDetector(
      onTap: () => _showFullImageDialog(url),
      child: ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.person, size: size * 0.6, color: Colors.white70),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return const Center(child: CircularProgressIndicator(strokeWidth: 2));
          },
        ),
      ),
    );
  }

  void _showFullImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Profile Picture", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: isMobile
          ? Column(
        children: [
          Row(
            children: [
              _buildFilterDropdown(),
              const SizedBox(width: 12),
              Expanded(child: _buildSearchField()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildExportIcons(),
              Row(
                children: [
                  Text("Total: ${filteredPartners.length}"),
                  const SizedBox(width: 8),
                  IconButton(onPressed: resetFilters, icon: const Icon(Icons.refresh), color: Colors.red),
                ],
              ),
            ],
          ),
        ],
      )
          : Row(
        children: [
          _buildFilterDropdown(),
          const SizedBox(width: 12),
          Expanded(child: _buildSearchField()),
          const SizedBox(width: 12),
          _buildExportIcons(),
          const SizedBox(width: 12),
          Text("Total: ${filteredPartners.length}"),
          IconButton(onPressed: resetFilters, icon: const Icon(Icons.refresh), color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
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
          onChanged: (String? newValue) {
            setState(() {
              filterType = newValue!;
              currentPage = 1;
              applyFilters();
            });
          },
          items: ['Name', 'Email', 'Mobile', 'Status']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: "Search by $filterType...",
          prefixIcon: const Icon(Icons.search, size: 16, color: Color(0xFF6366F1)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, size: 16),
            onPressed: () {
              _searchController.clear();
              setState(() {
                searchQuery = '';
                currentPage = 1;
                applyFilters();
              });
            },
          )
              : null,
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
            currentPage = 1;
            applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildExportIcons() {
    return Row(
      children: [
        Tooltip(
          message: "Export Excel",
          child: InkWell(
            onTap: exportExcel,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Image.asset("assets/icon/xls.png", height: 20, width: 20, errorBuilder: (_, __, ___) => const Icon(Icons.table_chart, size: 20)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "Export PDF",
          child: InkWell(
            onTap: exportPDF,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Image.asset("assets/icon/pdf.png", height: 20, width: 20, errorBuilder: (_, __, ___) => const Icon(Icons.picture_as_pdf, size: 20)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: "Export DOC",
          child: InkWell(
            onTap: exportDOC,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: Image.asset("assets/icon/doc.png", height: 20, width: 20, errorBuilder: (_, __, ___) => const Icon(Icons.description, size: 20)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _tableHeader(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _tableCell(String text, {VoidCallback? onTap, bool isBold = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        alignment: Alignment.center,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: 10),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildPagination() {
    if (filteredPartners.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text("Show "),
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
                  icon: const Icon(Icons.arrow_drop_down),
                  items: rowsPerPageOptions.map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
                  onChanged: changeItemsPerPage,
                ),
              ),
              const Text(" entries"),
              const SizedBox(width: 16),
              Text(
                "Showing ${(currentPage - 1) * itemsPerPage + 1} to ${currentPage * itemsPerPage > filteredPartners.length ? filteredPartners.length : currentPage * itemsPerPage} of ${filteredPartners.length}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          Row(
            children: [
              _compactPageButton(icon: Icons.chevron_left, onTap: currentPage > 1 ? previousPage : null),
              if (totalPages <= 5)
                ...List.generate(totalPages, (index) => _compactPageNumber(index + 1))
              else if (currentPage <= 3) ...[
                ...List.generate(4, (index) => _compactPageNumber(index + 1)),
                const Text("..."),
                _compactPageNumber(totalPages),
              ] else if (currentPage >= totalPages - 2) ...[
                _compactPageNumber(1),
                const Text("..."),
                ...List.generate(4, (index) => _compactPageNumber(totalPages - 3 + index)),
              ] else ...[
                _compactPageNumber(1),
                const Text("..."),
                _compactPageNumber(currentPage - 1),
                _compactPageNumber(currentPage),
                _compactPageNumber(currentPage + 1),
                const Text("..."),
                _compactPageNumber(totalPages),
              ],
              _compactPageButton(icon: Icons.chevron_right, onTap: currentPage < totalPages ? nextPage : null),
            ],
          ),
        ],
      ),
    );
  }

  Widget _compactPageButton({required IconData icon, required VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(6)),
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
        onTap: () => goToPage(pageNum),
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Referred Partners: ${widget.headName}"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildFilterSection(isMobile),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Table(
                        border: TableBorder(
                          horizontalInside: BorderSide(color: Colors.grey.shade300),
                          verticalInside: BorderSide(color: Colors.grey.shade300),
                          top: BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                        columnWidths: columnWidths,
                        children: [TableRow(children: headerLabels.map((l) => _tableHeader(l)).toList())],
                      ),
                    ),
                  ),
                  Expanded(
                    child: filteredPartners.isEmpty
                        ? const Center(child: Text("No referred partners found"))
                        : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Table(
                          border: TableBorder.all(color: Colors.grey.shade300),
                          columnWidths: columnWidths,
                          children: List.generate(paginatedPartners.length, (rowIndex) {
                            final partner = paginatedPartners[rowIndex];
                            final bool isEven = rowIndex % 2 == 0;
                            final int srNo = rowIndex + 1;
                            Color statusColor = partner.status == 'approved'
                                ? Colors.green
                                : (partner.status == 'rejected' ? Colors.red : Colors.orange);
                            return TableRow(
                              decoration: BoxDecoration(color: isEven ? Colors.white : const Color(0xFFF8FAFC)),
                              children: [
                                _tableCell(srNo.toString()),
                                _tableCell(partner.fullName),
                                GestureDetector(
                                  onTap: () => _showFullImageDialog(partner.profileImage ?? ''),
                                  child: Container(
                                    height: 40,
                                    width: 40,
                                    alignment: Alignment.center,
                                    child: ClipOval(
                                      child: _buildProfileImage(partner.profileImage, 35),
                                    ),
                                  ),
                                ),
                                _tableCell(partner.email),
                                _tableCell(partner.mobile),
                                _tableCell(partner.workingArea),
                                _tableCell(partner.teamSize.toString()),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: statusColor.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                                    child: Text(partner.status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                _tableCell(partner.createdAt.substring(0, 10)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _buildPagination(),
          ],
        ),
      ),
    );
  }
}