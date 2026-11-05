// lib/screens/marketing_partner/marketing_agreement_screen.dart

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui' show RenderRepaintBoundary;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../api/marketing_service.dart';
import '../../models/marketing_partner/marketing_agreement_model.dart';

// ============================================================
// ✅ MARKETING PARTNER AGREEMENT SCREEN
// ============================================================
class MarketingAgreementScreen extends StatefulWidget {
  const MarketingAgreementScreen({super.key});

  @override
  State<MarketingAgreementScreen> createState() =>
      _MarketingAgreementScreenState();
}

class _MarketingAgreementScreenState extends State<MarketingAgreementScreen> {
  // Colors
  static const Color primaryColor = Color(0xFFFF6584);
  static const Color secondaryColor = Color(0xFF9B59B6);
  static const Color bgColor = Color(0xFFF5F7FA);
  static const Color cardBg = Colors.white;
  static const Color textMain = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);

  List<MarketingPartnerAgreementData> _agreements = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMyAgreements();
  }

  // ============================================================
  // LOAD
  // ============================================================
  Future<void> _loadMyAgreements() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response =
      await MarketingPartnerAgreementService.fetchMyAgreements();

      if (!mounted) return;

      if (response.success) {
        setState(() {
          _agreements = response.data;
          _isLoading = false;
        });
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
          _buildHeader(isMobile),
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
  // HEADER
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
          IconButton(
            onPressed: _loadMyAgreements,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LIST
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
  // AGREEMENT CARD
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
              // Row 1: Avatar + Name + Status
              Row(
                children: [
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          agreement.marketingPartnerName ??
                              'Marketing Partner',
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

              // Row 2: Info chips
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
                      onPressed: () => _openPdf(agreement.pdfUrl),
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
  // EMPTY / ERROR
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
              'Your agreements will appear here\nonce created by admin',
              style: TextStyle(fontSize: 13, color: textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

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
  // DETAIL VIEW
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
              onRefresh: () {
                Navigator.of(ctx).pop();
                _loadMyAgreements();
              },
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================
  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final date = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy').format(date);
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

  Future<void> _openPdf(String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

// ============================================================
// ✅ DETAIL VIEW
// ============================================================
class _AgreementDetailView extends StatefulWidget {
  final MarketingPartnerAgreementData agreement;
  final VoidCallback onClose;
  final VoidCallback onRefresh;

  const _AgreementDetailView({
    required this.agreement,
    required this.onClose,
    required this.onRefresh,
  });

  @override
  State<_AgreementDetailView> createState() => _AgreementDetailViewState();
}

class _AgreementDetailViewState extends State<_AgreementDetailView> {
  static const Color primaryColor = Color(0xFFFF6584);
  static const Color textMain = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color cardBg = Colors.white;

  bool _isProcessing = false;

  MarketingPartnerAgreementData get agreement => widget.agreement;

  // ============================================================
  // SIGN AGREEMENT
  // ============================================================
  Future<void> _signAgreement() async {
    final signature = await showDialog<Uint8List>(
      context: context,
      builder: (_) => const _SignatureDialog(),
    );

    if (signature == null) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);

    try {
      final response =
      await MarketingPartnerAgreementService.partnerSignAgreement(
        agreementId: agreement.agreementId,
        signatureBytes: signature,
      );

      setState(() => _isProcessing = false);

      if (!mounted) return;

      if (response != null && response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
          ),
        );
        widget.onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?.message ?? 'Failed to sign'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ============================================================
  // REJECT AGREEMENT
  // ============================================================
  Future<void> _rejectAgreement() async {
    final reason = await _showRejectDialog();
    if (reason == null || reason.isEmpty) return;
    if (!mounted) return;

    setState(() => _isProcessing = true);

    try {
      final response =
      await MarketingPartnerAgreementService.partnerRejectAgreement(
        agreementId: agreement.agreementId,
        rejectionReason: reason,
      );

      setState(() => _isProcessing = false);

      if (!mounted) return;

      if (response != null && response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.orange,
          ),
        );
        widget.onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?.message ?? 'Failed to reject'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ============================================================
  // DOWNLOAD PDF
  // ============================================================
  Future<void> _downloadPdf() async {
    setState(() => _isProcessing = true);

    try {
      final bytes =
      await MarketingPartnerAgreementService.downloadAgreementPdf(
          agreement.agreementId);

      setState(() => _isProcessing = false);

      if (!mounted) return;

      if (bytes != null) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: '${agreement.agreementNumber}.pdf',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to download PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ============================================================
  // REJECT DIALOG
  // ============================================================
  Future<String?> _showRejectDialog() async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController();
    String? reason;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Reject Agreement'),
          ],
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter rejection reason',
              border: OutlineInputBorder(),
            ),
            validator: (value) =>
            value == null || value.isEmpty ? 'Reason is required' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              reason = ctrl.text.trim();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    return reason;
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          color: const Color(0xFFF8FAFC),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Action buttons section
                      if (agreement.canPartnerSign ||
                          agreement.canPartnerReject ||
                          agreement.canDownloadPdf)
                        _buildActionSection(),

                      const SizedBox(height: 16),
                      _section('Basic Information', Icons.info_rounded),
                      const SizedBox(height: 10),
                      _row('Agreement Number', agreement.agreementNumber),
                      _row('Start Date',
                          _formatDate(agreement.agreementStartDate)),
                      _row('End Date',
                          _formatDate(agreement.agreementEndDate)),
                      _row('Status', agreement.status.toUpperCase()),
                      _row('Stage', agreement.agreementStage),
                      if (agreement.partnerSignedAt != null)
                        _row('Partner Signed',
                            _formatDate(agreement.partnerSignedAt)),
                      if (agreement.approvedAt != null)
                        _row('Approved', _formatDate(agreement.approvedAt)),

                      const SizedBox(height: 20),
                      _section('Partner Details', Icons.person_rounded),
                      const SizedBox(height: 10),
                      _row('Partner Name',
                          agreement.marketingPartnerName ?? '-'),
                      _row('Address',
                          agreement.marketingPartnerAddress ?? '-'),
                      _row('Aadhar Number', agreement.adharNumber ?? '-'),
                      _row('PAN Number', agreement.panNumber ?? '-'),

                      const SizedBox(height: 20),
                      _section('Commission & Profit',
                          Icons.trending_up_rounded),
                      const SizedBox(height: 10),
                      _row('Company Commission',
                          '${agreement.companyCommissionPercentage}%'),
                      _row('Profit Share',
                          '${agreement.profitSharePercentage}%'),
                      _row('Selling Commission',
                          '${agreement.sellingCommissionPercentage}%'),

                      const SizedBox(height: 20),
                      _section('Additional Terms', Icons.notes_rounded),
                      const SizedBox(height: 10),
                      _row(
                          'Additional Points',
                          agreement.additionalPoints.isEmpty
                              ? '-'
                              : agreement.additionalPoints),
                      _row(
                          'Representative',
                          agreement.qnxMartRepresentative.isEmpty
                              ? '-'
                              : agreement.qnxMartRepresentative),
                      if (agreement.remarks != null &&
                          agreement.remarks!.isNotEmpty)
                        _row('Remarks', agreement.remarks!),

                      const SizedBox(height: 20),

                      // Uploaded Documents
                      if (agreement.hasImages || agreement.hasPdf) ...[
                        _section('Uploaded Documents', Icons.folder_rounded),
                        const SizedBox(height: 10),
                        if (agreement.hasPdf) ...[
                          _buildPdfTile(),
                          const SizedBox(height: 14),
                        ],
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

                      // Rejection reason
                      if (agreement.rejectionReason != null &&
                          agreement.rejectionReason!.isNotEmpty)
                        _buildRejectionBox(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Processing overlay
        if (_isProcessing)
          Container(
            color: Colors.black.withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(color: primaryColor),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, Color(0xFF9B59B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
                    color: Colors.white,
                  ),
                ),
                Text(
                  agreement.agreementNumber,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTION SECTION
  // ============================================================
  Widget _buildActionSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.08),
            const Color(0xFF9B59B6).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.touch_app_rounded, color: primaryColor, size: 18),
              SizedBox(width: 8),
              Text(
                'Actions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // Sign button
              if (agreement.canPartnerSign)
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _signAgreement,
                  icon: const Icon(Icons.draw_rounded, size: 18),
                  label: const Text('Sign Agreement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

              // Reject button
              if (agreement.canPartnerReject)
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _rejectAgreement,
                  icon: const Icon(Icons.cancel_rounded, size: 18),
                  label: const Text('Reject Agreement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

              // Download PDF (only approved)
              if (agreement.canDownloadPdf)
                ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _downloadPdf,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
  // PDF TILE
  // ============================================================
  Widget _buildPdfTile() {
    return Container(
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
              final url = agreement.pdfUrl;
              if (url == null || url.isEmpty) return;
              try {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (e) {
                print('Error: $e');
              }
            },
            icon: const Icon(Icons.open_in_new, size: 14),
            label: const Text('View', style: TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // IMAGE TILE
  // ============================================================
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

  // ============================================================
  // REJECTION BOX
  // ============================================================
  Widget _buildRejectionBox() {
    return Container(
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
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================
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

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final date = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return raw;
    }
  }
}

// ============================================================
// ✅ SIGNATURE DIALOG
// ============================================================
class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  _SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        canvas.drawLine(stroke[i], stroke[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

class _SignatureDialog extends StatefulWidget {
  const _SignatureDialog();

  @override
  State<_SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<_SignatureDialog> {
  final List<List<Offset>> _strokes = [];
  final GlobalKey _boundaryKey = GlobalKey();

  void _clear() {
    setState(() => _strokes.clear());
  }

  Future<void> _save() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please draw your signature first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject()
      as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      if (mounted) Navigator.of(context).pop(bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.draw_rounded, color: Color(0xFFFF6584)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Sign Agreement',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Draw your signature below',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            RepaintBoundary(
              key: _boundaryKey,
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _strokes.add([details.localPosition]);
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _strokes.last.add(details.localPosition);
                      });
                    },
                    child: CustomPaint(
                      painter: _SignaturePainter(_strokes),
                      size: Size.infinite,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _clear,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Clear'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6584),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}