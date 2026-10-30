// lib/screens/marketing_head/head_agreement_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/marketing_service.dart';

class HeadAgreementScreen extends StatefulWidget {
  const HeadAgreementScreen({super.key});

  @override
  State<HeadAgreementScreen> createState() => _HeadAgreementScreenState();
}

class _HeadAgreementScreenState extends State<HeadAgreementScreen> {
  final MarketingAgreementService _agreementService = MarketingAgreementService();
  Map<String, dynamic>? agreementData;
  bool isLoading = true;
  String? errorMessage;
  bool _isDarkMode = false;

  // Design Colors
  static const Color primaryColor = Color(0xFF4158D0);
  static const Color secondaryColor = Color(0xFFC850C0);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color scaffoldBg = Color(0xFFF8FAFC);
  static const Color cardBg = Colors.white;
  static const Color textMain = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _loadAgreementData();
  }

  Future<void> _loadAgreementData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedHeadId = prefs.getString('marketing_head_id');

      if (savedHeadId == null || savedHeadId.isEmpty) {
        setState(() {
          errorMessage = "Marketing Head ID not found! Please login again.";
          isLoading = false;
        });
        return;
      }

      final response = await _agreementService.fetchMarketingPartnerAgreement(savedHeadId);

      if (response['status'] == true && response['data'] != null) {
        setState(() {
          agreementData = response['data'];
          errorMessage = null;
        });
      } else {
        setState(() {
          errorMessage = response['message'] ?? "No agreement data available.";
          agreementData = null;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Failed to load data: $e";
        agreementData = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _viewDocument(String url, String type) {
    _showSnackbar('Opening $type view...');
    // Add URL launcher here if needed
  }

  void _downloadDocument(String url, String type) {
    _showSnackbar('$type download started...');
    // Add download logic here if needed
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: isError ? Colors.redAccent : successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showDocumentActionPopup({required String title, required String? fileUrl, required String type}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Center(
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          backgroundColor: _isDarkMode ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: textMain,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Container(color: primaryColor.withOpacity(0.15), height: 1),
                  const SizedBox(height: 16),
                  ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Color(0xFFE0E7FF), shape: BoxShape.circle),
                      child: const Icon(Icons.visibility_rounded, color: primaryColor, size: 18),
                    ),
                    title: Text(
                      'View $type',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textMain),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (fileUrl != null && fileUrl.isNotEmpty) {
                        _viewDocument(fileUrl, type);
                      } else {
                        _showSnackbar('Document URL not available', isError: true);
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Color(0xFFFAE8FF), shape: BoxShape.circle),
                      child: const Icon(Icons.download_rounded, color: secondaryColor, size: 18),
                    ),
                    title: Text(
                      'Download $type',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textMain),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      if (fileUrl != null && fileUrl.isNotEmpty) {
                        _downloadDocument(fileUrl, type);
                      } else {
                        _showSnackbar('Download link not available', isError: true);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'CLOSE',
                        style: TextStyle(color: textMuted, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateAgreementPopup() {
    // Close current dialog and navigate to create screen
    Navigator.pop(context);
    // Navigate to create agreement screen for marketing head
    // Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateHeadAgreementScreen()));
    _showSnackbar('Navigate to Create Head Agreement Screen');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Marketing Head Agreement',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: textMain,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: textMain),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (agreementData != null)
            _buildStatusBadge(agreementData?['status']),
          const SizedBox(width: 12),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: primaryColor,
          strokeWidth: 3,
        ),
      )
          : errorMessage != null
          ? _buildErrorState()
          : agreementData == null
          ? _buildEmptyState()
          : _buildAgreementContent(),
    );
  }

  // ========== ERROR STATE ==========
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 50, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: const TextStyle(
                color: textMain,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
              label: const Text(
                "Retry",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _loadAgreementData,
            ),
          ],
        ),
      ),
    );
  }

  // ========== EMPTY STATE ==========
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.document_scanner_rounded, size: 55, color: textMuted),
          const SizedBox(height: 16),
          const Text(
            'No Agreement Found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textMain,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 18),
            label: const Text(
              "Create New Agreement",
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _showCreateAgreementPopup,
          ),
        ],
      ),
    );
  }

  // ========== AGREEMENT CONTENT ==========
  Widget _buildAgreementContent() {
    final data = agreementData!;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Section 1: Head Profile
          _buildSectionContainer(
            title: "Marketing Head Profile",
            icon: Icons.person_rounded,
            accentColor: primaryColor,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 500;
                final items = [
                  _buildDetailTile(
                    Icons.badge_outlined,
                    "Full Name",
                    data['marketing_head_name'] ?? data['company_owner_name'],
                  ),
                  _buildDetailTile(
                    Icons.email_outlined,
                    "Email Address",
                    data['marketing_head_email'] ?? 'Not Provided',
                  ),
                  _buildDetailTile(
                    Icons.phone_android_rounded,
                    "Mobile Number",
                    data['marketing_head_mobile'] ?? 'Not Provided',
                  ),
                  _buildDetailTile(
                    Icons.business_center_outlined,
                    "Company Owner",
                    data['company_owner_name'],
                  ),
                  _buildDetailTile(
                    Icons.location_on_outlined,
                    "Company Address",
                    data['company_address'],
                  ),
                  _buildDetailTile(
                    Icons.confirmation_number_outlined,
                    "Agreement Number",
                    data['agreement_number'],
                  ),
                ];

                if (!isWide) {
                  return Column(children: items);
                }

                return Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: items.map((item) => SizedBox(
                    width: (constraints.maxWidth - 16) / 2,
                    child: item,
                  )).toList(),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Section 2: Verification & Terms
          _buildSectionContainer(
            title: "Verification & Terms",
            icon: Icons.gavel_rounded,
            accentColor: secondaryColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfitShareRow(data['profit_share_percentage'], primaryColor),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showDocumentActionPopup(
                          title: "PAN Card Document",
                          fileUrl: data['owner_pan_number'],
                          type: "PAN Card",
                        ),
                        child: _buildMiniDocTile(
                          Icons.badge_rounded,
                          "Owner PAN",
                          data['owner_pan_number'] ?? 'Not Provided',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showDocumentActionPopup(
                          title: "Aadhaar Card Document",
                          fileUrl: data['owner_adhar_number'],
                          type: "Aadhaar",
                        ),
                        child: _buildMiniDocTile(
                          Icons.fingerprint_rounded,
                          "Owner Aadhaar",
                          data['owner_adhar_number'] ?? 'Not Provided',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateTile(
                        Icons.calendar_today_rounded,
                        "Start Date",
                        data['agreement_start_date'],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDateTile(
                        Icons.calendar_month_rounded,
                        "End Date",
                        data['agreement_end_date'],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildDetailTile(
                  Icons.note_add_outlined,
                  "Additional Points",
                  data['additional_points'] ?? 'No additional points',
                ),
                const SizedBox(height: 4),
                _buildDetailTile(
                  Icons.comment_outlined,
                  "Remarks",
                  data['remarks'] ?? 'No remarks',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Section 3: Digital Verification & Signatures
          _buildSectionContainer(
            title: "Digital Verification & Signatures",
            icon: Icons.assignment_turned_in_rounded,
            accentColor: successColor,
            child: Column(
              children: [
                // PDF Document
                Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBFDBFE)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.picture_as_pdf_rounded, color: Colors.blueAccent, size: 20),
                            SizedBox(width: 10),
                            Text(
                              "Agreement PDF Document",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: textMain,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            final pdfUrl = data['uploaded_agreement_pdf_s3_key'];
                            if (pdfUrl != null && pdfUrl.isNotEmpty) {
                              _showDocumentActionPopup(
                                title: "Agreement PDF",
                                fileUrl: pdfUrl,
                                type: "PDF Document",
                              );
                            } else {
                              _showSnackbar('PDF not uploaded yet!', isError: true);
                            }
                          },
                          icon: const Icon(Icons.visibility_rounded, size: 14, color: Colors.white),
                          label: const Text(
                            "View",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Signatures Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSignComponent(
                          title: "QNX Mart Rep.",
                          name: data['qnx_mart_representative'] ?? 'Not Available',
                          photoUrl: data['qnx_mart_picture_url'],
                          signUrl: data['qnx_mart_sign_url'],
                        ),
                      ),
                      Container(width: 1, height: 150, color: borderColor),
                      Expanded(
                        child: _buildSignComponent(
                          title: "Head Sign",
                          name: data['marketing_head_name'] ?? data['company_owner_name'],
                          photoUrl: data['head_picture_url'] ?? data['company_picture_url'],
                          signUrl: data['head_sign_url'] ?? data['company_sign_url'],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Battery Regeneration System • Confidential Document",
            style: TextStyle(
              fontSize: 10,
              color: textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ========== COMPONENTS ==========

  Widget _buildSectionContainer({
    required String title,
    required IconData icon,
    required Color accentColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, dynamic value) {
    final String displayValue = value?.toString() ?? 'Not Provided';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(icon, size: 15, color: textMuted),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  displayValue,
                  style: const TextStyle(
                    fontSize: 13,
                    color: textMain,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniDocTile(IconData icon, String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value?.toString() ?? 'N/A',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: textMain,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTile(IconData icon, String label, dynamic value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: textMain),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: textMuted,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value?.toString() ?? 'N/A',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: textMain,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildProfitShareRow(dynamic percentage, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: themeColor.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.monetization_on_rounded, color: themeColor, size: 18),
              const SizedBox(width: 10),
              Text(
                "Profit Share",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: themeColor,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "${percentage ?? '0'}%",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignComponent({
    required String title,
    dynamic name,
    String? photoUrl,
    String? signUrl,
  }) {
    return GestureDetector(
      onTap: () {
        if ((photoUrl != null && photoUrl.isNotEmpty) ||
            (signUrl != null && signUrl.isNotEmpty)) {
          _showDocumentActionPopup(
            title: "$title Documents",
            fileUrl: photoUrl ?? signUrl,
            type: "Media",
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 10),
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: photoUrl != null && photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? const Icon(Icons.person, color: textMuted, size: 18)
                  : null,
            ),
            const SizedBox(height: 6),
            Text(
              name?.toString() ?? 'N/A',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: textMain,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Container(
              height: 44,
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
              ),
              child: signUrl != null && signUrl.isNotEmpty
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  signUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Text(
                        "No Sign",
                        style: TextStyle(fontSize: 9, color: textMuted),
                      ),
                    );
                  },
                ),
              )
                  : const Center(
                child: Text(
                  "No Sign",
                  style: TextStyle(fontSize: 9, color: textMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String? status) {
    final cleanStatus = (status ?? 'pending').toLowerCase();
    final bool isApproved = cleanStatus == 'approved';
    final bool isRejected = cleanStatus == 'rejected';

    Color bgColor;
    if (isApproved) {
      bgColor = successColor;
    } else if (isRejected) {
      bgColor = Colors.redAccent;
    } else {
      bgColor = warningColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isApproved
                ? Icons.check_circle_rounded
                : isRejected
                ? Icons.cancel_rounded
                : Icons.pending_rounded,
            size: 11,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            cleanStatus.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 9,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}