// lib/screens/marketing_partner/marketing_agreement_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api_service.dart';
import '../../models/marketing_partner/marketing_agreement_model.dart';
import 'package:url_launcher/url_launcher.dart';
import '../qnx_admin/agreement_screen.dart';

class MarketingAgreementScreen extends StatefulWidget {
  const MarketingAgreementScreen({super.key});

  @override
  State<MarketingAgreementScreen> createState() =>
      _MarketingAgreementScreenState();
}

class _MarketingAgreementScreenState extends State<MarketingAgreementScreen> {
  // ============================================================
  // STATE
  // ============================================================
  List<MarketingPartnerAgreementData> _agreements = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isMarketingPartner = false;
  String _userRole = '';

  // Design Palette (QNX Admin सारखेच)
  static const Color primaryColor = Color(0xFFFF6584);
  static const Color secondaryColor = Color(0xFF9B59B6);
  static const Color bgColor = Color(0xFFF5F7FA);
  static const Color cardBg = Colors.white;
  static const Color textMain = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _loadMyAgreements();
    _checkUserRole();  //
  }

  // ============================================================
  // ✅ LOAD MY AGREEMENTS (Only logged-in Marketing Partner)
  // ============================================================
  Future<void> _loadMyAgreements() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response =
      await AgreementService.fetchMyMarketingPartnerAgreements();

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _agreements = response.data;
          _isLoading = false;
        });
        print('✅ Loaded ${_agreements.length} agreements');
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load agreements: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _checkUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? '';
    final roleLower = role.toLowerCase();

    setState(() {
      _userRole = role;
      _isMarketingPartner = roleLower.contains('marketing partner') ||
          roleLower.contains('marketing_partner');
    });

    print('🔍 User Role: "$role"');
    print('🔍 Is Marketing Partner: $_isMarketingPartner');
  }

  // ============================================================
  // ✅ OPEN CREATE AGREEMENT DIALOG (QNX Admin चा same form)
  // ============================================================
  void _openCreateAgreementDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: double.infinity,
          constraints: BoxConstraints(
            maxWidth: 1200,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            // ✅ QNX Admin चा Marketing Partner Agreement Form (Public class)
            child: MarketingPartnerAgreementFormContent(
              onClose: () {
                if (mounted) Navigator.of(ctx).pop();
                // ✅ Form close झाल्यावर list refresh करा
                _loadMyAgreements();
              },
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ✅ OPEN DETAIL VIEW
  // ============================================================
  void _openAgreementDetail(MarketingPartnerAgreementData agreement) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 900,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _AgreementDetailView(
              agreement: agreement,
              onClose: () => Navigator.of(ctx).pop(),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      backgroundColor: bgColor,
      body: Column(
        children: [
          // -------------------- HEADER --------------------
          _buildHeader(isMobile),

          // -------------------- CONTENT --------------------
          Expanded(
            child: _isLoading
                ? const Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
                : _errorMessage != null
                ? _buildErrorState()
                : _agreements.isEmpty
                ? _buildEmptyState()
                : _buildAgreementsList(isMobile),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ HEADER
  // ============================================================
  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20,
        vertical: 14,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Agreements',
                  style: TextStyle(
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${_agreements.length} agreement${_agreements.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: isMobile ? 11 : 12,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _openCreateAgreementDialog,
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: Text(
              isMobile ? 'New' : 'Create Agreement',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 16,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ AGREEMENTS LIST
  // ============================================================
  Widget _buildAgreementsList(bool isMobile) {
    return RefreshIndicator(
      onRefresh: _loadMyAgreements,
      color: primaryColor,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _agreements.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final agreement = _agreements[index];
          return _buildAgreementCard(agreement, isMobile);
        },
      ),
    );
  }

  // ============================================================
  // ✅ AGREEMENT CARD
  // ============================================================
  Widget _buildAgreementCard(
      MarketingPartnerAgreementData agreement, bool isMobile) {
    final statusColor = _getStatusColor(agreement.status);
    final statusIcon = _getStatusIcon(agreement.status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openAgreementDetail(agreement),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
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
            children: [
              // Row 1: Icon + Name + Status Badge
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [primaryColor, secondaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        (agreement.marketingPartnerName?.isNotEmpty ?? false)
                            ? agreement.marketingPartnerName![0].toUpperCase()
                            : '#',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name + Agreement Number
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agreement.marketingPartnerName ?? 'Marketing Partner',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textMain,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          agreement.agreementNumber,
                          style: const TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          agreement.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1, color: borderColor),
              const SizedBox(height: 12),

              // Row 2: Dates + Commission
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildInfoChip(
                    Icons.calendar_today_rounded,
                    'Start',
                    _formatDate(agreement.agreementStartDate),
                    const Color(0xFF1ABC9C),
                  ),
                  _buildInfoChip(
                    Icons.calendar_month_rounded,
                    'End',
                    _formatDate(agreement.agreementEndDate),
                    const Color(0xFFE74C3C),
                  ),
                  _buildInfoChip(
                    Icons.trending_up_rounded,
                    'Profit',
                    '${agreement.profitSharePercentage}%',
                    const Color(0xFFE91E63),
                  ),
                  _buildInfoChip(
                    Icons.attach_money_rounded,
                    'Selling',
                    '${agreement.sellingCommissionPercentage}%',
                    const Color(0xFF8B5CF6),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Row 3: Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (agreement.hasPdf)
                    TextButton.icon(
                      onPressed: () {
                        // PDF open logic (optional)
                      },
                      icon: const Icon(
                        Icons.picture_as_pdf,
                        size: 16,
                        color: Colors.red,
                      ),
                      label: const Text(
                        'PDF',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    onPressed: () => _openAgreementDetail(agreement),
                    icon: const Icon(
                      Icons.visibility,
                      size: 16,
                      color: primaryColor,
                    ),
                    label: const Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ✅ SMALL INFO CHIP
  // ============================================================
  Widget _buildInfoChip(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: textMain,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ✅ EMPTY STATE
  // ============================================================
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.description_outlined,
                size: 56,
                color: primaryColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No Agreements Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textMain,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create your first agreement to get started',
              style: TextStyle(fontSize: 13, color: textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _openCreateAgreementDialog,
              icon: const Icon(Icons.add_circle_outline),
              label: const Text(
                'Create Agreement',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ✅ ERROR STATE
  // ============================================================
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: const TextStyle(
                fontSize: 14,
                color: textMain,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadMyAgreements,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ✅ HELPERS
  // ============================================================
  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final date = DateTime.parse(raw);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return raw;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return const Color(0xFFEF4444);
      case 'pending':
      default:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      case 'pending':
      default:
        return Icons.pending_rounded;
    }
  }
}

// ============================================================
// ✅ AGREEMENT DETAIL VIEW (Bottom Sheet / Dialog)
// ============================================================
class _AgreementDetailView extends StatelessWidget {
  final MarketingPartnerAgreementData agreement;
  final VoidCallback onClose;

  const _AgreementDetailView({
    required this.agreement,
    required this.onClose,
  });

  static const Color primaryColor = Color(0xFFFF6584);
  static const Color textMain = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color cardBg = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: cardBg,
              border: Border(
                bottom: BorderSide(color: borderColor),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.description_rounded,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agreement.marketingPartnerName ?? 'Agreement',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textMain,
                        ),
                      ),
                      Text(
                        agreement.agreementNumber,
                        style: const TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                  color: Colors.redAccent,
                ),
              ],
            ),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Info
                  _section('Basic Information', Icons.info_rounded),
                  const SizedBox(height: 10),
                  _row('Agreement Number', agreement.agreementNumber),
                  _row(
                      'Start Date', _formatDate(agreement.agreementStartDate)),
                  _row('End Date', _formatDate(agreement.agreementEndDate)),
                  _row('Status', agreement.status.toUpperCase()),

                  const SizedBox(height: 20),

                  // Partner Details
                  _section('Partner Details', Icons.person_rounded),
                  const SizedBox(height: 10),
                  _row('Partner Name',
                      agreement.marketingPartnerName ?? '-'),
                  _row('Address', agreement.marketingPartnerAddress ?? '-'),
                  _row('Aadhar Number', agreement.adharNumber ?? '-'),
                  _row('PAN Number', agreement.panNumber ?? '-'),

                  const SizedBox(height: 20),

                  // Commission
                  _section('Commission & Profit', Icons.trending_up_rounded),
                  const SizedBox(height: 10),
                  _row('Company Commission',
                      '${agreement.companyCommissionPercentage}%'),
                  _row('Profit Share',
                      '${agreement.profitSharePercentage}%'),
                  _row('Selling Commission',
                      '${agreement.sellingCommissionPercentage}%'),

                  const SizedBox(height: 20),

                  // Terms
                  _section('Additional Terms', Icons.notes_rounded),
                  const SizedBox(height: 10),
                  _row('Additional Points',
                      agreement.additionalPoints.isEmpty
                          ? '-'
                          : agreement.additionalPoints),
                  _row('Representative',
                      agreement.qnxMartRepresentative.isEmpty
                          ? '-'
                          : agreement.qnxMartRepresentative),
                  if (agreement.remarks != null &&
                      agreement.remarks!.isNotEmpty)
                    _row('Remarks', agreement.remarks!),

                  const SizedBox(height: 20),

                  // ✅ SIGNATURES & PHOTOS SECTION
                  // ✅ SIGNATURES & PHOTOS SECTION
                  if (agreement.hasImages || agreement.hasPdf) ...[
                    const SizedBox(height: 20),
                    _section('Uploaded Documents', Icons.folder_rounded),
                    const SizedBox(height: 10),

                    // ✅ PDF Document
                    if (agreement.hasPdf) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.picture_as_pdf,
                                color: Colors.red.shade600,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Agreement PDF Document',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: textMain,
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () async {
                                // ✅ Use the resolver, not the raw field
                                final url = agreement.pdfUrl;
                                if (url == null || url.isEmpty) {
                                  print('❌ PDF URL is empty');
                                  return;
                                }
                                final uri = Uri.parse(url);
                                try {
                                  if (await canLaunchUrl(uri)) {
                                    await launchUrl(
                                      uri,
                                      mode: LaunchMode.externalApplication,
                                    );
                                  } else {
                                    print('❌ Cannot launch URL: $url');
                                  }
                                } catch (e) {
                                  print('❌ Error launching PDF: $e');
                                }
                              },
                              icon: const Icon(Icons.open_in_new, size: 14),
                              label: const Text('View',
                                  style: TextStyle(fontSize: 11)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ✅ Signatures & Photos Grid — uses resolvers now
                    if (agreement.hasImages)
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          if (agreement.qnxSignDisplayUrl != null)
                            _buildImageTile(
                              'QNX Mart Sign',
                              agreement.qnxSignDisplayUrl!,
                              Icons.draw_rounded,
                              const Color(0xFF6C63FF),
                            ),
                          if (agreement.mpSignDisplayUrl != null)
                            _buildImageTile(
                              'Partner Sign',
                              agreement.mpSignDisplayUrl!,
                              Icons.draw_rounded,
                              const Color(0xFFFF6584),
                            ),
                          if (agreement.qnxPictureDisplayUrl != null)
                            _buildImageTile(
                              'QNX Mart Photo',
                              agreement.qnxPictureDisplayUrl!,
                              Icons.person_rounded,
                              const Color(0xFF10B981),
                            ),
                          if (agreement.mpPictureDisplayUrl != null)
                            _buildImageTile(
                              'Partner Photo',
                              agreement.mpPictureDisplayUrl!,
                              Icons.person_rounded,
                              const Color(0xFFF59E0B),
                            ),
                        ],
                      ),
                  ],

                  const SizedBox(height: 20),

                  // Rejection Reason
                  if (agreement.rejectionReason != null &&
                      agreement.rejectionReason!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.red.shade700, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'Rejection Reason',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            agreement.rejectionReason!,
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: primaryColor),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textMain,
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
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
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ✅ Image tile (Signatures/Photos साठी)
  Widget _buildImageTile(
      String label, String imageUrl, IconData icon, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 12, color: color),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              height: 100,
              width: double.infinity,
              color: color.withOpacity(0.05),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                      value: progress.expectedTotalBytes != null
                          ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: color.withOpacity(0.5),
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final date = DateTime.parse(raw);
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return raw;
    }
  }
}