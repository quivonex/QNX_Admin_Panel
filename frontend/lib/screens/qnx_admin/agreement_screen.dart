// lib/screens/qnx_admin/agreement_screen.dart

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui' show RenderRepaintBoundary;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../api/api_service.dart';
import '../../models/qnx_admin/agreement_model.dart';
import '../../models/qnx_admin/marketing_partner_model.dart';
import '../../api/marketing_service.dart' show MarketingProfileService;

class AgreementScreen extends StatefulWidget {
  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen>
    with SingleTickerProviderStateMixin {
  AgreementType? _selectedType;
  CompanyAgreementData? _selectedCompanyAgreement;
  MarketingPartnerAgreementData? _selectedMPAgreement;

  List<CompanyAgreementData> _companyAgreements = [];
  List<MarketingPartnerAgreementData> _mpAgreements = [];
  bool _loadingAgreements = false;

  late AnimationController _cardController;
  late List<Animation<double>> _cardAnimations;
  final reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardAnimations = List.generate(2, (i) {
      return Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _cardController,
          curve: Interval(i * 0.15, 0.6 + i * 0.1, curve: Curves.easeOutBack),
        ),
      );
    });
    _cardController.forward();
  }

  Future<void> _fetchAgreementsByType(AgreementType type) async {
    if (!mounted) return;
    _safeSetState(() {
      _loadingAgreements = true;
      _companyAgreements = [];
      _mpAgreements = [];
      _selectedCompanyAgreement = null;
      _selectedMPAgreement = null;
    });

    try {
      if (type == AgreementType.company) {
        final res = await AgreementService.fetchCompanyAgreements();
        if (mounted) {
          _safeSetState(() {
            _companyAgreements = res.data;
            _loadingAgreements = false;
          });
        }
      } else {
        final res = await AgreementService.fetchMarketingPartnerAgreements();
        if (mounted) {
          _safeSetState(() {
            _mpAgreements = res.data;
            _loadingAgreements = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        _safeSetState(() => _loadingAgreements = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load agreements: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  void _refreshAgreementList() {
    if (_selectedType != null) {
      _fetchAgreementsByType(_selectedType!);
    }
  }

  void _onTypeSelected(AgreementType type) {
    if (!mounted) return;
    setState(() {
      _selectedType = type;
      _selectedCompanyAgreement = null;
      _selectedMPAgreement = null;
    });
    _fetchAgreementsByType(type);
  }

  void _openCreateForm(BuildContext context) {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an agreement type first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
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
            child: _selectedType == AgreementType.marketingPartner
                ? MarketingPartnerAgreementFormContent(
              onClose: () {
                if (mounted) Navigator.of(ctx).pop();
                _refreshAgreementList();
              },
            )
                : CompanyAgreementFormContent(
              onClose: () {
                if (mounted) Navigator.of(ctx).pop();
                _refreshAgreementList();
              },
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ✅ NEW HELPER: Approve/Reject button दिसायला हवा का?
  // Company: stage == 'signed_by_company'
  // MP: stage == 'signed_by_partner'
  // ============================================================
  bool _canShowApproveRejectForCompany(CompanyAgreementData ag) {
    return ag.isPending && ag.agreementStage == 'signed_by_company';
  }

  bool _canShowApproveRejectForMP(MarketingPartnerAgreementData ag) {
    return ag.isPending && ag.agreementStage == 'signed_by_partner';
  }

  Future<void> _handleCompanyApprove(CompanyAgreementData ag) async {
    if (!mounted) return;
    try {
      final response = await AgreementService.approveRejectCompanyAgreement(
        agreementId: ag.agreementId,
        approve: true,
      );

      if (!mounted) return;

      if (response != null && response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response.message), backgroundColor: Colors.green),
        );
        _refreshAgreementList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?.message ?? 'Failed to approve'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to approve: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleCompanyReject(CompanyAgreementData ag) async {
    if (!mounted) return;
    final reason = await _showRejectDialog();
    if (reason == null || reason.isEmpty) return;
    if (!mounted) return;

    try {
      final response = await AgreementService.approveRejectCompanyAgreement(
        agreementId: ag.agreementId,
        approve: false,
        rejectionReason: reason,
      );

      if (!mounted) return;

      if (response != null && response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response.message), backgroundColor: Colors.orange),
        );
        setState(() => _selectedCompanyAgreement = null);
        await _fetchAgreementsByType(AgreementType.company);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?.message ?? 'Failed to reject'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleMPApprove(MarketingPartnerAgreementData ag) async {
    if (!mounted) return;
    try {
      final response =
      await AgreementService.approveRejectMarketingPartnerAgreement(
        agreementId: ag.agreementId,
        approve: true,
      );

      if (!mounted) return;

      if (response != null && response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response.message), backgroundColor: Colors.green),
        );
        _refreshAgreementList();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?.message ?? 'Failed to approve'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to approve: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleMPReject(MarketingPartnerAgreementData ag) async {
    if (!mounted) return;
    final reason = await _showRejectDialog();
    if (reason == null || reason.isEmpty) return;
    if (!mounted) return;

    try {
      final response =
      await AgreementService.approveRejectMarketingPartnerAgreement(
        agreementId: ag.agreementId,
        approve: false,
        rejectionReason: reason,
      );

      if (!mounted) return;

      if (response != null && response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response.message), backgroundColor: Colors.orange),
        );
        setState(() => _selectedMPAgreement = null);
        await _fetchAgreementsByType(AgreementType.marketingPartner);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response?.message ?? 'Failed to reject'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleCompanyTerminate(CompanyAgreementData ag) async {
    if (!mounted) return;
    final reason = await _showTerminateDialog();
    if (reason == null || reason.isEmpty) return;
    if (!mounted) return;

    try {
      final response = await AgreementService.terminateCompanyAgreement(
        agreementId: ag.agreementId,
        reason: reason,
      );

      if (!mounted) return;

      if (response != null && response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response.message), backgroundColor: Colors.orange),
        );
        setState(() => _selectedCompanyAgreement = null);
        await _fetchAgreementsByType(AgreementType.company);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleMPTerminate(MarketingPartnerAgreementData ag) async {
    if (!mounted) return;
    final reason = await _showTerminateDialog();
    if (reason == null || reason.isEmpty) return;
    if (!mounted) return;

    try {
      final response =
      await AgreementService.terminateMarketingPartnerAgreement(
        agreementId: ag.agreementId,
        reason: reason,
      );

      if (!mounted) return;

      if (response != null && response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(response.message), backgroundColor: Colors.orange),
        );
        setState(() => _selectedMPAgreement = null);
        await _fetchAgreementsByType(AgreementType.marketingPartner);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<String?> _showRejectDialog() async {
    final formKey = GlobalKey<FormState>();
    String? reason;
    reasonController.clear();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject Agreement'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonController,
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
              reason = reasonController.text.trim();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    return reason;
  }

  Future<String?> _showTerminateDialog() async {
    final formKey = GlobalKey<FormState>();
    final ctrl = TextEditingController();
    String? reason;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Terminate Agreement'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: ctrl,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Enter termination reason',
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
            child: const Text('Terminate'),
          ),
        ],
      ),
    );
    return reason;
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
    }
  }

  Future<void> _downloadSample(AgreementType type) async {
    try {
      final bytes = await AgreementService.downloadSampleAgreement(type);
      if (bytes != null) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: 'sample_${type.name}_agreement.pdf',
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to download sample'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _cardController.dispose();
    reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Agreement Management',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (_selectedType != null)
            IconButton(
              tooltip: 'Download Sample Agreement',
              icon: const Icon(Icons.file_download_outlined,
                  color: Colors.deepPurple),
              onPressed: () => _downloadSample(_selectedType!),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isMobile
                      ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.4,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: AgreementType.values.length,
                    itemBuilder: (_, i) => ScaleTransition(
                      scale: _cardAnimations[i],
                      child: _TypeCard(
                        type: AgreementType.values[i],
                        isSelected:
                        _selectedType == AgreementType.values[i],
                        onTap: () =>
                            _onTypeSelected(AgreementType.values[i]),
                      ),
                    ),
                  )
                      : Row(
                    children: List.generate(
                        AgreementType.values.length, (i) {
                      return Expanded(
                        child: Padding(
                          padding:
                          EdgeInsets.only(right: i < 1 ? 12 : 0),
                          child: ScaleTransition(
                            scale: _cardAnimations[i],
                            child: _TypeCard(
                              type: AgreementType.values[i],
                              isSelected:
                              _selectedType == AgreementType.values[i],
                              onTap: () => _onTypeSelected(
                                  AgreementType.values[i]),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  if (_selectedType != null)
                    Expanded(
                      child: isMobile
                          ? _buildMobileSplitView()
                          : _buildDesktopSplitView(),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopSplitView() {
    final screenWidth = MediaQuery.of(context).size.width;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: screenWidth * 0.35, child: _buildListPanel()),
        const SizedBox(width: 20),
        Expanded(child: _buildDetailPanel()),
      ],
    );
  }

  Widget _buildMobileSplitView() {
    final hasSelection =
        _selectedCompanyAgreement != null || _selectedMPAgreement != null;
    if (hasSelection) {
      return Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _selectedCompanyAgreement = null;
                    _selectedMPAgreement = null;
                  });
                }
              },
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              label: const Text('Back to list'),
            ),
          ),
          Expanded(child: _buildDetailPanel()),
        ],
      );
    }
    return _buildListPanel();
  }

  Widget _buildListPanel() {
    final color = _selectedType!.color;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(_selectedType!.icon, color: color, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedType!.label.split(' to ').last,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () => _openCreateForm(context),
                    icon: const Icon(Icons.add_circle_outline,
                        size: 18, color: Colors.white),
                    label: const Text(
                      'Create',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildListContent()),
        ],
      ),
    );
  }

  Widget _buildListContent() {
    if (_loadingAgreements) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_selectedType == AgreementType.marketingPartner) {
      if (_mpAgreements.isEmpty) {
        return _buildEmptyState();
      }
      return ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: _mpAgreements.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final ag = _mpAgreements[i];
          final isSelected =
              _selectedMPAgreement?.agreementId == ag.agreementId;
          final color = _selectedType!.color;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedMPAgreement = ag;
              _selectedCompanyAgreement = null;
            }),
            child: _buildMPListItem(ag, isSelected, color),
          );
        },
      );
    }

    if (_companyAgreements.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: _companyAgreements.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final ag = _companyAgreements[i];
        final isSelected =
            _selectedCompanyAgreement?.agreementId == ag.agreementId;
        final color = _selectedType!.color;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedCompanyAgreement = ag;
            _selectedMPAgreement = null;
          }),
          child: _buildCompanyListItem(ag, isSelected, color),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 8),
          Text('No agreements found',
              style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _openCreateForm(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create First Agreement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedType!.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyListItem(
      CompanyAgreementData ag, bool isSelected, Color color) {
    // ✅ FIX: Approve/Reject फक्त stage == 'signed_by_company' असताना
    final showApproveReject = _canShowApproveRejectForCompany(ag);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.12) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (ag.companyName.isNotEmpty)
                    ? ag.companyName[0].toUpperCase()
                    : (ag.companyOwnerName.isNotEmpty
                    ? ag.companyOwnerName[0].toUpperCase()
                    : '#'),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ag.companyName.isNotEmpty
                      ? ag.companyName
                      : (ag.companyOwnerName.isNotEmpty
                      ? ag.companyOwnerName
                      : 'Agreement #${ag.agreementId}'),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isSelected ? color : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        ag.agreementNumber,
                        style:
                        TextStyle(fontSize: 11, color: Colors.grey[500]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusBadge(ag.status),
                    if (ag.products.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${ag.products.length} products',
                          style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                              color: color),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (showApproveReject)
            _actionButtons(
              onApprove: () => _handleCompanyApprove(ag),
              onReject: () => _handleCompanyReject(ag),
            ),
          if (isSelected)
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ],
      ),
    );
  }

  Widget _buildMPListItem(
      MarketingPartnerAgreementData ag, bool isSelected, Color color) {
    // ✅ FIX: Approve/Reject फक्त stage == 'signed_by_partner' असताना
    final showApproveReject = _canShowApproveRejectForMP(ag);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.12) : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? color : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (ag.marketingPartnerName.isNotEmpty)
                    ? ag.marketingPartnerName[0].toUpperCase()
                    : '#',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ag.marketingPartnerName.isNotEmpty
                      ? ag.marketingPartnerName
                      : 'Marketing Partner #${ag.marketingPartnerId}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: isSelected ? color : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        ag.agreementNumber,
                        style:
                        TextStyle(fontSize: 11, color: Colors.grey[500]),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _statusBadge(ag.status),
                  ],
                ),
              ],
            ),
          ),
          if (showApproveReject)
            _actionButtons(
              onApprove: () => _handleMPApprove(ag),
              onReject: () => _handleMPReject(ag),
            ),
          if (isSelected)
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final c = status == 'approved'
        ? Colors.green
        : (status == 'rejected' ? Colors.red : Colors.orange);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(status,
          style: TextStyle(
              fontSize: 9, fontWeight: FontWeight.w600, color: c.shade800)),
    );
  }

  Widget _actionButtons(
      {required VoidCallback onApprove, required VoidCallback onReject}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onApprove,
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 22),
          tooltip: 'Approve',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
        IconButton(
          onPressed: onReject,
          icon: const Icon(Icons.cancel, color: Colors.red, size: 22),
          tooltip: 'Reject',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        ),
      ],
    );
  }

  Widget _buildDetailPanel() {
    if (_selectedType == AgreementType.marketingPartner &&
        _selectedMPAgreement != null) {
      return _MPAgreementDetailView(
        data: _selectedMPAgreement!,
        typeColor: _selectedType!.color,
        onApprove: () => _handleMPApprove(_selectedMPAgreement!),
        onReject: () => _handleMPReject(_selectedMPAgreement!),
        onTerminate: () => _handleMPTerminate(_selectedMPAgreement!),
        canApproveReject: _canShowApproveRejectForMP(_selectedMPAgreement!),
      );
    }

    if (_selectedCompanyAgreement == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_rounded, size: 64, color: Colors.grey[200]),
              const SizedBox(height: 12),
              Text(
                'Select an item from the list\nto view agreement details',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }

    return _CompanyAgreementDetailView(
      data: _selectedCompanyAgreement!,
      typeColor: _selectedType!.color,
      onApprove: () => _handleCompanyApprove(_selectedCompanyAgreement!),
      onReject: () => _handleCompanyReject(_selectedCompanyAgreement!),
      onTerminate: () => _handleCompanyTerminate(_selectedCompanyAgreement!),
      canApproveReject:
      _canShowApproveRejectForCompany(_selectedCompanyAgreement!),
    );
  }
}

// ============================================================
// TYPE CARD
// ============================================================
class _TypeCard extends StatefulWidget {
  final AgreementType type;
  final bool isSelected;
  final VoidCallback onTap;
  const _TypeCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
  });
  @override
  State<_TypeCard> createState() => _TypeCardState();
}

class _TypeCardState extends State<_TypeCard> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final color = widget.type.color;
    final selected = widget.isSelected;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
              colors: [color, color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
                : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
              selected ? color : (_hovered ? color : Colors.grey.shade200),
              width: selected ? 2 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: selected
                    ? color.withOpacity(0.28)
                    : (_hovered
                    ? color.withOpacity(0.12)
                    : Colors.black.withOpacity(0.05)),
                blurRadius: selected ? 18 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withOpacity(0.25)
                      : color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.type.icon,
                  color: selected ? Colors.white : color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.type.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? Colors.white : Colors.black87,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// COMPANY AGREEMENT DETAIL VIEW
// ============================================================
class _CompanyAgreementDetailView extends StatelessWidget {
  final CompanyAgreementData data;
  final Color typeColor;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onTerminate;
  // ✅ NEW
  final bool canApproveReject;

  const _CompanyAgreementDetailView({
    required this.data,
    required this.typeColor,
    required this.onApprove,
    required this.onReject,
    required this.onTerminate,
    required this.canApproveReject,
  });

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  void _openPdf(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      final bytes =
      await AgreementService.downloadCompanyAgreementPdf(data.agreementId);
      if (bytes != null) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: '${data.agreementNumber}.pdf',
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to download PDF'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ✅ Can show download/terminate?
  bool get _isFinalizedApproved =>
      data.isApproved && !data.isTerminated;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: typeColor.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  typeColor.withOpacity(0.1),
                  typeColor.withOpacity(0.05)
                ],
              ),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.companyName.isNotEmpty
                            ? data.companyName
                            : (data.companyOwnerName.isNotEmpty
                            ? data.companyOwnerName
                            : 'Agreement Detail'),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: typeColor),
                      ),
                      const SizedBox(height: 2),
                      Text(data.agreementNumber,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // ✅ Approve/Reject — फक्त stage signed_by_company असताना
                    if (canApproveReject)
                      ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    if (canApproveReject)
                      ElevatedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    // ✅ Download PDF — फक्त finalized approved
                    if (_isFinalizedApproved)
                      ElevatedButton.icon(
                        onPressed: () => _downloadPdf(context),
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    // ✅ Terminate — फक्त finalized approved
                    if (_isFinalizedApproved)
                      ElevatedButton.icon(
                        onPressed: onTerminate,
                        icon: const Icon(Icons.block, size: 16),
                        label: const Text('Terminate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Basic Information', typeColor),
                  const SizedBox(height: 12),
                  _fullWidthInfo(Icons.numbers_rounded, 'Agreement Number',
                      data.agreementNumber, typeColor),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _infoCard(Icons.calendar_today_rounded,
                            'Start Date',
                            _formatDate(data.agreementStartDate),
                            typeColor)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _infoCard(Icons.calendar_month_rounded,
                            'End Date',
                            _formatDate(data.agreementEndDate),
                            typeColor)),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _infoCard(Icons.flag_rounded, 'Status',
                            data.status.toUpperCase(), typeColor)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _infoCard(Icons.stairs_rounded, 'Stage',
                            data.agreementStage, typeColor)),
                  ]),
                  const SizedBox(height: 24),
                  _sectionTitle('Owner Details', typeColor),
                  const SizedBox(height: 12),
                  _fullWidthInfo(Icons.person_rounded, 'Company Owner Name',
                      data.companyOwnerName, typeColor),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _infoCard(Icons.credit_card_rounded,
                            'Owner Aadhar', data.ownerAdharNumber ?? '-',
                            typeColor)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _infoCard(Icons.assignment_ind_rounded,
                            'Owner PAN', data.ownerPanNumber ?? '-',
                            typeColor)),
                  ]),
                  const SizedBox(height: 24),
                  _sectionTitle('Representative Details', typeColor),
                  const SizedBox(height: 12),
                  _fullWidthInfo(Icons.person_outline_rounded,
                      'QNX Representative',
                      data.qnxMartRepresentative.isNotEmpty
                          ? data.qnxMartRepresentative
                          : '-', typeColor),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _infoCard(Icons.credit_card_rounded,
                            'Rep. Aadhar', data.sellerAdharNumber ?? '-',
                            typeColor)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _infoCard(Icons.assignment_ind_rounded,
                            'Rep. PAN', data.sellerPanNumber ?? '-',
                            typeColor)),
                  ]),
                  const SizedBox(height: 24),
                  if (data.products.isNotEmpty) ...[
                    _sectionTitle('Agreement Products', typeColor),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          typeColor.withOpacity(0.05),
                          typeColor.withOpacity(0.02)
                        ]),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: typeColor.withOpacity(0.12)),
                      ),
                      child: Column(children: [
                        Row(children: [
                          Expanded(
                            flex: 3,
                            child: Text('Product Name',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.grey[600])),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text('Profit %',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Colors.grey[600])),
                          ),
                        ]),
                        const Divider(height: 16, thickness: 1),
                        ...data.products.map((product) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(children: [
                              Expanded(
                                flex: 3,
                                child: Row(children: [
                                  Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                          color: typeColor.withOpacity(0.6),
                                          shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                        product.productName.isNotEmpty
                                            ? product.productName
                                            : 'Product #${product.productId}',
                                        style: const TextStyle(fontSize: 13)),
                                  ),
                                ]),
                              ),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                      color: typeColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6)),
                                  child: Text(
                                      '${product.profitPercentage}%',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: typeColor),
                                      textAlign: TextAlign.right),
                                ),
                              ),
                            ]),
                          );
                        }).toList(),
                      ]),
                    ),
                    const SizedBox(height: 24),
                  ],
                  _sectionTitle('Location', typeColor),
                  const SizedBox(height: 12),
                  _fullWidthInfo(
                      Icons.location_on_rounded,
                      'Address',
                      data.companyAddress.isNotEmpty
                          ? data.companyAddress
                          : '-',
                      typeColor),
                  const SizedBox(height: 24),
                  _sectionTitle('Additional Terms & Conditions', typeColor),
                  const SizedBox(height: 12),
                  _fullWidthInfo(
                      Icons.note_add_rounded,
                      'Additional Points',
                      data.additionalPoints.isNotEmpty
                          ? data.additionalPoints
                          : '-',
                      typeColor),
                  if (data.rejectionReason != null &&
                      data.rejectionReason!.isNotEmpty) ...[
                    const SizedBox(height: 12),
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
                            Row(children: [
                              Icon(Icons.warning,
                                  color: Colors.red.shade700, size: 18),
                              const SizedBox(width: 6),
                              Text('Rejection Reason',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700)),
                            ]),
                            const SizedBox(height: 4),
                            Text(data.rejectionReason!,
                                style:
                                TextStyle(color: Colors.red.shade900)),
                          ]),
                    ),
                  ],
                  if (data.uploadedAgreementPdfUrl != null &&
                      data.uploadedAgreementPdfUrl!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _sectionTitle('Uploaded Agreement PDF', typeColor),
                    const SizedBox(height: 12),
                    _buildPdfView(context, typeColor),
                  ],
                  if (_hasImages()) ...[
                    const SizedBox(height: 24),
                    _sectionTitle('Signatures & Photos', typeColor),
                    const SizedBox(height: 12),
                    _buildImageRow(context, typeColor),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasImages() =>
      (data.qnxMartSignUrl?.isNotEmpty ?? false) ||
          (data.companySignUrl?.isNotEmpty ?? false) ||
          (data.qnxMartPictureUrl?.isNotEmpty ?? false) ||
          (data.companyPictureUrl?.isNotEmpty ?? false);

  Widget _buildPdfView(BuildContext context, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          color.withOpacity(0.05),
          color.withOpacity(0.02)
        ]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.picture_as_pdf,
              color: Colors.red.shade600, size: 40),
        ),
        const SizedBox(width: 16),
        const Expanded(
            child: Text('Agreement PDF Document',
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 14))),
        ElevatedButton.icon(
          onPressed: () => _openPdf(context, data.uploadedAgreementPdfUrl),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('View'),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white),
        ),
      ]),
    );
  }

  Widget _buildImageRow(BuildContext context, Color color) {
    final images = <Map<String, String>>[
      if (data.qnxMartSignUrl?.isNotEmpty ?? false)
        {'url': data.qnxMartSignUrl!, 'label': 'QNX Sign'},
      if (data.companySignUrl?.isNotEmpty ?? false)
        {'url': data.companySignUrl!, 'label': 'Company Sign'},
      if (data.qnxMartPictureUrl?.isNotEmpty ?? false)
        {'url': data.qnxMartPictureUrl!, 'label': 'QNX Photo'},
      if (data.companyPictureUrl?.isNotEmpty ?? false)
        {'url': data.companyPictureUrl!, 'label': 'Company Photo'},
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: images.map((img) {
        return Column(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(img['url']!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 100,
                  height: 100,
                  color: color.withOpacity(0.1),
                  child: Icon(Icons.image_not_supported_rounded,
                      color: color, size: 32),
                )),
          ),
          const SizedBox(height: 6),
          Text(img['label']!,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600])),
        ]);
      }).toList(),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Row(children: [
      Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Flexible(
        child: Text(title,
            style:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    ]);
  }

  Widget _infoCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          color.withOpacity(0.05),
          color.withOpacity(0.02)
        ]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style:
                    TextStyle(fontSize: 11, color: Colors.grey[500])),
                const SizedBox(height: 2),
                Text(value.isEmpty ? '-' : value,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2),
              ]),
        ),
      ]),
    );
  }

  Widget _fullWidthInfo(
      IconData icon, String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          color.withOpacity(0.05),
          color.withOpacity(0.02)
        ]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500])),
                  const SizedBox(height: 4),
                  Text(value.isEmpty ? '-' : value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Colors.black87)),
                ]),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MARKETING PARTNER AGREEMENT DETAIL VIEW
// ============================================================
class _MPAgreementDetailView extends StatelessWidget {
  final MarketingPartnerAgreementData data;
  final Color typeColor;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onTerminate;
  // ✅ NEW
  final bool canApproveReject;

  const _MPAgreementDetailView({
    required this.data,
    required this.typeColor,
    required this.onApprove,
    required this.onReject,
    required this.onTerminate,
    required this.canApproveReject,
  });

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  void _openPdf(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _downloadPdf(BuildContext context) async {
    try {
      final bytes = await AgreementService.downloadMarketingPartnerAgreementPdf(
          data.agreementId);
      if (bytes != null) {
        await Printing.sharePdf(
          bytes: bytes,
          filename: '${data.agreementNumber}.pdf',
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to download PDF'),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  bool get _isFinalizedApproved =>
      data.isApproved && !data.isTerminated;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: typeColor.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  typeColor.withOpacity(0.1),
                  typeColor.withOpacity(0.05)
                ],
              ),
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.marketingPartnerName.isNotEmpty
                            ? data.marketingPartnerName
                            : 'Marketing Partner',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: typeColor),
                      ),
                      const SizedBox(height: 2),
                      Text(data.agreementNumber,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                    ],
                  ),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // ✅ Approve/Reject — फक्त stage signed_by_partner
                    if (canApproveReject)
                      ElevatedButton.icon(
                        onPressed: onApprove,
                        icon: const Icon(Icons.check_circle, size: 16),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    if (canApproveReject)
                      ElevatedButton.icon(
                        onPressed: onReject,
                        icon: const Icon(Icons.cancel, size: 16),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    // ✅ Download + Terminate — फक्त finalized approved
                    if (_isFinalizedApproved)
                      ElevatedButton.icon(
                        onPressed: () => _downloadPdf(context),
                        icon: const Icon(Icons.download, size: 16),
                        label: const Text('Download PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    if (_isFinalizedApproved)
                      ElevatedButton.icon(
                        onPressed: onTerminate,
                        icon: const Icon(Icons.block, size: 16),
                        label: const Text('Terminate'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _section('Basic Information', typeColor),
                  const SizedBox(height: 12),
                  _info('Agreement Number', data.agreementNumber, typeColor),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: _info('Start Date',
                            _formatDate(data.agreementStartDate), typeColor)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _info('End Date',
                            _formatDate(data.agreementEndDate), typeColor)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: _info(
                            'Status', data.status.toUpperCase(), typeColor)),
                    const SizedBox(width: 12),
                    Expanded(
                        child:
                        _info('Stage', data.agreementStage, typeColor)),
                  ]),
                  const SizedBox(height: 24),
                  _section('Marketing Partner Details', typeColor),
                  const SizedBox(height: 12),
                  _info('Partner Name', data.marketingPartnerName, typeColor),
                  const SizedBox(height: 8),
                  _info('Address', data.marketingPartnerAddress, typeColor),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: _info(
                            'Aadhar Number', data.adharNumber ?? '-',
                            typeColor)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _info(
                            'PAN Number', data.panNumber ?? '-', typeColor)),
                  ]),
                  const SizedBox(height: 24),
                  _section('Commission & Profit', typeColor),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _info('Company Commission %',
                            '${data.companyCommissionPercentage}%',
                            typeColor)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _info('Profit Share %',
                            '${data.profitSharePercentage}%', typeColor)),
                  ]),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                        child: _info('Selling Commission %',
                            '${data.sellingCommissionPercentage}%',
                            typeColor)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _info('Representative',
                            data.qnxMartRepresentative, typeColor)),
                  ]),
                  const SizedBox(height: 24),
                  _section('Additional Terms', typeColor),
                  const SizedBox(height: 12),
                  _info('Additional Points', data.additionalPoints, typeColor),
                  if (data.remarks != null && data.remarks!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _info('Remarks', data.remarks!, typeColor),
                  ],
                  if (data.rejectionReason != null &&
                      data.rejectionReason!.isNotEmpty) ...[
                    const SizedBox(height: 8),
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
                            Row(children: [
                              Icon(Icons.warning,
                                  color: Colors.red.shade700, size: 18),
                              const SizedBox(width: 6),
                              Text('Rejection Reason',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade700)),
                            ]),
                            const SizedBox(height: 4),
                            Text(data.rejectionReason!,
                                style:
                                TextStyle(color: Colors.red.shade900)),
                          ]),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (data.uploadedAgreementPdfUrl != null &&
                      data.uploadedAgreementPdfUrl!.isNotEmpty) ...[
                    _section('Uploaded Agreement PDF', typeColor),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          typeColor.withOpacity(0.05),
                          typeColor.withOpacity(0.02)
                        ]),
                        borderRadius: BorderRadius.circular(12),
                        border:
                        Border.all(color: typeColor.withOpacity(0.12)),
                      ),
                      child: Row(children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.picture_as_pdf,
                              color: Colors.red.shade600, size: 32),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                            child: Text('Agreement PDF Document',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14))),
                        ElevatedButton.icon(
                          onPressed: () => _openPdf(
                              context, data.uploadedAgreementPdfUrl),
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('View'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (_hasImages()) ...[
                    _section('Signatures & Photos', typeColor),
                    const SizedBox(height: 12),
                    Wrap(spacing: 12, runSpacing: 12, children: [
                      if (data.qnxMartSignUrl?.isNotEmpty ?? false)
                        _img(data.qnxMartSignUrl!, 'QNX Sign', typeColor),
                      if (data.marketingPartnerSignUrl?.isNotEmpty ?? false)
                        _img(data.marketingPartnerSignUrl!, 'Partner Sign',
                            typeColor),
                      if (data.qnxMartPictureUrl?.isNotEmpty ?? false)
                        _img(data.qnxMartPictureUrl!, 'QNX Photo', typeColor),
                      if (data.marketingPartnerPictureUrl?.isNotEmpty ?? false)
                        _img(data.marketingPartnerPictureUrl!, 'Partner Photo',
                            typeColor),
                    ]),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasImages() =>
      (data.qnxMartSignUrl?.isNotEmpty ?? false) ||
          (data.marketingPartnerSignUrl?.isNotEmpty ?? false) ||
          (data.qnxMartPictureUrl?.isNotEmpty ?? false) ||
          (data.marketingPartnerPictureUrl?.isNotEmpty ?? false);

  Widget _section(String title, Color color) {
    return Row(children: [
      Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Flexible(
        child: Text(title,
            style:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    ]);
  }

  Widget _info(String label, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          color.withOpacity(0.05),
          color.withOpacity(0.02)
        ]),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        const SizedBox(height: 4),
        Text(value.isEmpty ? '-' : value,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }

  Widget _img(String url, String label, Color color) {
    return Column(children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(url,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 100,
              height: 100,
              color: color.withOpacity(0.1),
              child: Icon(Icons.image_not_supported, color: color, size: 32),
            )),
      ),
      const SizedBox(height: 6),
      Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
    ]);
  }
}

// ============================================================
// COMPANY AGREEMENT FORM
// ============================================================
class CompanyAgreementFormContent extends StatefulWidget {
  final VoidCallback onClose;
  const CompanyAgreementFormContent({required this.onClose});
  @override
  State<CompanyAgreementFormContent> createState() =>
      _CompanyAgreementFormContentState();
}

class _CompanyAgreementFormContentState
    extends State<CompanyAgreementFormContent> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isFetchingCompanies = true;
  bool _isFetchingProducts = false;
  bool _isDisposed = false;

  final ScrollController _scrollController = ScrollController();

  late FocusNode startDateFocus;
  late FocusNode endDateFocus;
  late FocusNode repNameFocus;
  late FocusNode repAdharFocus;
  late FocusNode repPanFocus;
  late FocusNode ownerNameFocus;
  late FocusNode ownerAdharFocus;
  late FocusNode ownerPanFocus;
  late FocusNode addressFocus;
  late FocusNode additionalTermsFocus;

  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  final repNameController = TextEditingController();
  final repAdharController = TextEditingController();
  final repPanController = TextEditingController();
  final ownerNameController = TextEditingController();
  final ownerAdharController = TextEditingController();
  final ownerPanController = TextEditingController();
  final addressController = TextEditingController();
  final additionalTermsController = TextEditingController();

  List<AgreementCompanyModel> companies = [];
  String? selectedCompanyId;
  String? selectedCompanyName;
  List<AgreementProductModel> products = [];
  Map<int, bool> selectedProducts = {};
  Map<int, TextEditingController> productProfitControllers = {};
  final TextEditingController globalProductProfitController =
  TextEditingController();

  List<Uint8List> repSigns = [];
  List<Uint8List> repPhotos = [];
  List<Uint8List> ownerPhotos = [];
  final int maxImagesPerCategory = 1;
  Uint8List? _uploadedPdfBytes;
  String? _uploadedPdfFileName;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _fetchCompanies();
    startDateFocus = FocusNode();
    endDateFocus = FocusNode();
    repNameFocus = FocusNode();
    repAdharFocus = FocusNode();
    repPanFocus = FocusNode();
    ownerNameFocus = FocusNode();
    ownerAdharFocus = FocusNode();
    ownerPanFocus = FocusNode();
    addressFocus = FocusNode();
    additionalTermsFocus = FocusNode();
  }

  Future<void> _fetchCompanies() async {
    try {
      final response = await AgreementCompanyService().getCompanies();
      _safeSetState(() {
        companies = response.data;
        _isFetchingCompanies = false;
      });
    } catch (e) {
      _safeSetState(() => _isFetchingCompanies = false);
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load companies: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _fetchProducts() async {
    if (selectedCompanyId == null) return;
    _safeSetState(() {
      _isFetchingProducts = true;
      products = [];
      selectedProducts.clear();
      for (var ctrl in productProfitControllers.values) {
        ctrl.dispose();
      }
      productProfitControllers.clear();
    });
    try {
      final response = await AgreementProductService()
          .getProductsByCompany(selectedCompanyId!);
      _safeSetState(() {
        products = response.data;
        for (int i = 0; i < products.length; i++) {
          // ✅ FIX: फक्त approved products आधीच select करता येतील
          selectedProducts[i] = false;
          productProfitControllers[i] = TextEditingController();
        }
        _isFetchingProducts = false;
      });
    } catch (e) {
      _safeSetState(() => _isFetchingProducts = false);
      if (mounted && !_isDisposed) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load products: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void onCompanyChanged(String? companyName) {
    if (companyName == null) {
      setState(() {
        selectedCompanyId = null;
        selectedCompanyName = null;
        ownerNameController.clear();
        addressController.clear();
        products = [];
        selectedProducts.clear();
        productProfitControllers.clear();
      });
      return;
    }
    final selected = companies.firstWhere(
          (c) => c.name == companyName,
      orElse: () => AgreementCompanyModel(id: 0, name: '', ownerName: ''),
    );
    if (selected.id != 0) {
      setState(() {
        selectedCompanyId = selected.id.toString();
        selectedCompanyName = selected.name;
        ownerNameController.text = selected.ownerName;
      });
      _fetchProducts();
    }
  }

  // ✅ FIX: Select All फक्त approved products साठी
  void toggleSelectAll(bool? value) {
    setState(() {
      for (int i = 0; i < products.length; i++) {
        if (products[i].status == 'approved') {
          selectedProducts[i] = value ?? false;
        }
      }
    });
  }

  void applyGlobalProductProfit() {
    final double? globalProfit =
    double.tryParse(globalProductProfitController.text);
    if (globalProfit != null) {
      setState(() {
        for (int i = 0; i < products.length; i++) {
          if (selectedProducts[i] == true &&
              products[i].status == 'approved') {
            productProfitControllers[i]?.text = globalProfit.toString();
          }
        }
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        startDateController.text =
        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 10, now.month, now.day),
    );
    if (picked != null) {
      setState(() {
        endDateController.text =
        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Color _getIconColor(String label) {
    final Map<String, Color> colors = {
      'Agreement': const Color(0xFF6C63FF),
      'Owner': const Color(0xFF00BFA5),
      'Start': const Color(0xFF1ABC9C),
      'End': const Color(0xFFE74C3C),
      'Company': const Color(0xFFF39C12),
      'Aadhar': const Color(0xFF3498DB),
      'PAN': const Color(0xFF2ECC71),
      'Address': const Color(0xFF1E88E5),
      'Terms': const Color(0xFFFF9800),
      'Representative': const Color(0xFF9B59B6),
    };
    for (var entry in colors.entries) {
      if (label.contains(entry.key)) return entry.value;
    }
    return Colors.grey;
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = true,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? customValidator,
    bool showSuffixIcon = false,
    String suffixText = '',
  }) {
    final iconColor = _getIconColor(label);
    return TextFormField(
      inputFormatters: inputFormatters,
      validator: customValidator ??
          (required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null),
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      keyboardType: keyboardType,
      focusNode: focusNode,
      textInputAction: textInputAction ??
          (nextFocusNode != null
              ? TextInputAction.next
              : TextInputAction.done),
      onFieldSubmitted: nextFocusNode != null
          ? (value) => FocusScope.of(context).requestFocus(nextFocusNode)
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700]),
        prefixIcon: Container(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: iconColor, size: 20)),
        suffixIcon: showSuffixIcon
            ? Container(
            padding: const EdgeInsets.all(14),
            child: Text(suffixText,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: iconColor)))
            : null,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: iconColor, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red, width: 2)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red, width: 2.5)),
        filled: true,
        fillColor: readOnly ? Colors.grey[100] : Colors.grey[50],
        contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  Widget _buildPdfUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient:
        const LinearGradient(colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.picture_as_pdf, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Upload Agreement PDF',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          if (_uploadedPdfFileName != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300)),
              child: Row(children: [
                Icon(Icons.picture_as_pdf,
                    color: Colors.red.shade600, size: 32),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(_uploadedPdfFileName!,
                        overflow: TextOverflow.ellipsis)),
                IconButton(
                    onPressed: () => setState(() {
                      _uploadedPdfBytes = null;
                      _uploadedPdfFileName = null;
                    }),
                    icon: const Icon(Icons.close, color: Colors.red)),
              ]),
            )
          else
            InkWell(
              onTap: () async {
                try {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                  );
                  if (result != null && result.files.isNotEmpty) {
                    final file = result.files.first;
                    if (file.bytes != null) {
                      setState(() {
                        _uploadedPdfBytes = file.bytes;
                        _uploadedPdfFileName = file.name;
                      });
                    }
                  }
                } catch (e) {
                  _showError('Failed to pick PDF: $e');
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Column(children: [
                  Icon(Icons.upload_file,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text('Tap to upload PDF file',
                      style: TextStyle(color: Colors.grey.shade600)),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompanyDropdown() {
    if (_isFetchingCompanies) {
      return const Center(child: CircularProgressIndicator());
    }
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return companies.map((c) => c.name);
        }
        return companies
            .map((c) => c.name)
            .where((item) => item
            .toLowerCase()
            .contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: onCompanyChanged,
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Company Name',
            prefixIcon: Container(
                padding: const EdgeInsets.all(10),
                child: const Icon(Icons.business,
                    color: Color(0xFFF39C12), size: 20)),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFF39C12), width: 2)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 2)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 2.5)),
            filled: true,
            fillColor: Colors.grey[50],
            suffixIcon:
            const Icon(Icons.arrow_drop_down, color: Color(0xFFF39C12)),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        );
      },
    );
  }

  Widget _buildSignatureCard(Map<String, dynamic> category) {
    final title = category['title'] as String;
    final List<Uint8List> images = category['images'];
    final Function(List<Uint8List>) onChanged = category['onChanged'];
    final isMobile = MediaQuery.of(context).size.width < 600;
    final thumbnailSize = isMobile ? 80.0 : 100.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
            const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[50]),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              ...images.map((img) => Stack(children: [
                Container(
                  width: thumbnailSize,
                  height: thumbnailSize,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                          image: MemoryImage(img), fit: BoxFit.cover)),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () {
                      final newList = List<Uint8List>.from(images);
                      newList.remove(img);
                      onChanged(newList);
                    },
                    child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            size: 18, color: Colors.white)),
                  ),
                ),
              ])),
              if (images.length < maxImagesPerCategory)
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                        source: ImageSource.gallery, imageQuality: 85);
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      final newList = List<Uint8List>.from(images);
                      newList.add(bytes);
                      onChanged(newList);
                    }
                  },
                  child: Container(
                    width: thumbnailSize,
                    height: thumbnailSize,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white),
                    child: const Center(
                        child: Icon(Icons.add_a_photo,
                            size: 40, color: Colors.deepPurple)),
                  ),
                ),
              if (images.length < maxImagesPerCategory && title.contains('Sign'))
                GestureDetector(
                  onTap: () async {
                    final bytes = await showDialog<Uint8List>(
                      context: context,
                      builder: (_) => _SignatureDrawingDialog(title: title),
                    );
                    if (bytes != null) {
                      final newList = List<Uint8List>.from(images);
                      newList.add(bytes);
                      onChanged(newList);
                    }
                  },
                  child: Container(
                    width: thumbnailSize,
                    height: thumbnailSize,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.deepPurple.shade200),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.deepPurple.shade50),
                    child: const Center(
                        child: Icon(Icons.draw_rounded,
                            size: 36, color: Colors.deepPurple)),
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (!formState.validate()) return;

    if (selectedCompanyId == null) {
      _showError('Please select a company');
      return;
    }
    if (startDateController.text.isEmpty) {
      _showError('Please select start date');
      return;
    }
    if (endDateController.text.isEmpty) {
      _showError('Please select end date');
      return;
    }

    _safeSetState(() => _isLoading = true);

    List<AgreementProductItem> productList = [];
    for (int i = 0; i < products.length; i++) {
      if (selectedProducts[i] == true) {
        // ✅ FIX: फक्त approved products allow
        if (products[i].status != 'approved') continue;
        final profitStr = productProfitControllers[i]?.text ?? '';
        final profit = double.tryParse(profitStr);
        if (profit != null) {
          productList.add(AgreementProductItem(
            product: products[i].id,
            profitPercentage: profit.toString(),
          ));
        }
      }
    }

    final request = CompanyAgreementCreateRequest(
      companyId: int.parse(selectedCompanyId!),
      agreementStartDate: startDateController.text,
      agreementEndDate: endDateController.text,
      companyOwnerName: ownerNameController.text,
      companyAddress: addressController.text,
      sellerAdharNumber:
      repAdharController.text.isNotEmpty ? repAdharController.text : null,
      sellerPanNumber:
      repPanController.text.isNotEmpty ? repPanController.text : null,
      ownerAdharNumber: ownerAdharController.text.isNotEmpty
          ? ownerAdharController.text
          : null,
      ownerPanNumber: ownerPanController.text.isNotEmpty
          ? ownerPanController.text
          : null,
      qnxMartRepresentative: repNameController.text,
      additionalPoints: additionalTermsController.text,
      remarks: null,
      agreementProducts: productList,
      qnxMartSign: repSigns.isNotEmpty ? repSigns.first : null,
      qnxMartPicture: repPhotos.isNotEmpty ? repPhotos.first : null,
      companyPicture: ownerPhotos.isNotEmpty ? ownerPhotos.first : null,
      uploadedAgreementPdf: _uploadedPdfBytes,
    );

    try {
      final response =
      await AgreementService.createCompanyAgreement(request);
      _safeSetState(() => _isLoading = false);

      if (response != null && response.success) {
        if (mounted && !_isDisposed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response.message),
                backgroundColor: Colors.green),
          );
          widget.onClose();
        }
      } else {
        _showError(response?.message ?? 'Failed to create agreement');
      }
    } catch (e) {
      _safeSetState(() => _isLoading = false);
      _showError('Error: $e');
    }
  }

  void _showError(String msg) {
    if (mounted && !_isDisposed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) setState(fn);
  }

  // ============================================================
  // ✅ NEW HELPER: Product card (approved/non-approved)
  // ============================================================
  Widget _buildProductCard(
      int index,
      int crossAxisCount,
      double childAspectRatio) {
    final product = products[index];
    final isApproved = product.status == 'approved';
    final isSelected = isApproved && (selectedProducts[index] ?? false);
    final profitCtrl =
        productProfitControllers[index] ?? TextEditingController();

    return Opacity(
      // ✅ Non-approved products faded दिसतील
      opacity: isApproved ? 1.0 : 0.55,
      child: Card(
        elevation: isApproved ? 2 : 0,
        color: isApproved ? null : Colors.grey[100],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: isApproved
              ? BorderSide.none
              : BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.thumbnailS3Key.isNotEmpty
                    ? Image.network(
                  product.thumbnailS3Key,
                  height: 80,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      height: 80,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image,
                          size: 30, color: Colors.grey)),
                )
                    : Container(
                    height: 80,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image_not_supported,
                        size: 30, color: Colors.grey)),
              ),
              const SizedBox(height: 4),

              // Product name
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 10),
              ),

              // Price + Status badge
              Row(children: [
                Text('₹${product.price}',
                    style: const TextStyle(
                        fontSize: 9, color: Colors.green)),
                const SizedBox(width: 4),
                _buildStatusChip(product.status),
              ]),

              const SizedBox(height: 4),

              // Checkbox + Profit field (approved साठीच enable)
              Row(children: [
                Checkbox(
                  value: isSelected,
                  // ✅ Non-approved products साठी onChanged = null (disable)
                  onChanged: isApproved
                      ? (val) {
                    setState(() {
                      selectedProducts[index] = val ?? false;
                    });
                  }
                      : null,
                  activeColor: Colors.deepPurple,
                  visualDensity:
                  const VisualDensity(horizontal: -4, vertical: -4),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Expanded(
                  child: TextFormField(
                    controller: profitCtrl,
                    enabled: isApproved, // ✅ disable
                    decoration: InputDecoration(
                      hintText: isApproved
                          ? 'Profit %'
                          : 'Not Approved',
                      hintStyle: TextStyle(
                        fontSize: 9,
                        color: isApproved ? Colors.grey : Colors.red.shade400,
                      ),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 4),
                      isDense: true,
                      filled: !isApproved,
                      fillColor:
                      isApproved ? null : Colors.grey.shade200,
                    ),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ]),

              // Non-approved notice
              if (!isApproved)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: Colors.red.shade200, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock,
                            size: 10, color: Colors.red.shade600),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            'Approval Pending',
                            style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final color = status == 'approved'
        ? Colors.green
        : (status == 'pending' ? Colors.orange : Colors.red);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
            fontSize: 7,
            color: color.shade800,
            fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;
    int crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 5);
    double childAspectRatio = isMobile ? 0.95 : (isTablet ? 0.9 : 0.85);

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF9B59B6), Color(0xFFFF6584)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(children: [
              const Expanded(
                child: Text('Create Company Agreement',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20)),
                child: IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white)),
              ),
            ]),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  _buildPdfUploadSection(),
                  const SizedBox(height: 16),
                  _buildCompanyDropdown(),
                  const SizedBox(height: 16),
                  if (isMobile)
                    Column(children: [
                      buildTextField(
                          controller: startDateController,
                          label: 'Start Date',
                          icon: Icons.calendar_today,
                          readOnly: true,
                          onTap: () => _selectStartDate(context),
                          focusNode: startDateFocus,
                          nextFocusNode: endDateFocus),
                      const SizedBox(height: 12),
                      buildTextField(
                          controller: endDateController,
                          label: 'End Date',
                          icon: Icons.calendar_month,
                          readOnly: true,
                          onTap: () => _selectEndDate(context),
                          focusNode: endDateFocus,
                          nextFocusNode: ownerNameFocus),
                    ])
                  else
                    Row(children: [
                      Expanded(
                          child: buildTextField(
                              controller: startDateController,
                              label: 'Start Date',
                              icon: Icons.calendar_today,
                              readOnly: true,
                              onTap: () => _selectStartDate(context),
                              focusNode: startDateFocus,
                              nextFocusNode: endDateFocus)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: buildTextField(
                              controller: endDateController,
                              label: 'End Date',
                              icon: Icons.calendar_month,
                              readOnly: true,
                              onTap: () => _selectEndDate(context),
                              focusNode: endDateFocus,
                              nextFocusNode: ownerNameFocus)),
                    ]),
                  const SizedBox(height: 16),
                  buildTextField(
                      controller: ownerNameController,
                      label: 'Company Owner Name',
                      icon: Icons.person,
                      required: true,
                      readOnly: true,
                      focusNode: ownerNameFocus,
                      nextFocusNode: ownerAdharFocus),
                  const SizedBox(height: 16),
                  if (isMobile)
                    Column(children: [
                      buildTextField(
                          controller: ownerAdharController,
                          label: 'Owner Aadhar Number',
                          icon: Icons.credit_card,
                          focusNode: ownerAdharFocus,
                          nextFocusNode: ownerPanFocus,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(12)
                          ]),
                      const SizedBox(height: 12),
                      buildTextField(
                          controller: ownerPanController,
                          label: 'Owner PAN Number',
                          icon: Icons.assignment_ind,
                          focusNode: ownerPanFocus,
                          nextFocusNode: repNameFocus,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9]')),
                            LengthLimitingTextInputFormatter(10)
                          ]),
                    ])
                  else
                    Row(children: [
                      Expanded(
                          child: buildTextField(
                              controller: ownerAdharController,
                              label: 'Owner Aadhar Number',
                              icon: Icons.credit_card,
                              focusNode: ownerAdharFocus,
                              nextFocusNode: ownerPanFocus,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(12)
                              ])),
                      const SizedBox(width: 12),
                      Expanded(
                          child: buildTextField(
                              controller: ownerPanController,
                              label: 'Owner PAN Number',
                              icon: Icons.assignment_ind,
                              focusNode: ownerPanFocus,
                              nextFocusNode: repNameFocus,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[A-Za-z0-9]')),
                                LengthLimitingTextInputFormatter(10)
                              ])),
                    ]),
                  const SizedBox(height: 16),
                  buildTextField(
                      controller: repNameController,
                      label: 'QNX Representative Name',
                      icon: Icons.person_outline,
                      focusNode: repNameFocus,
                      nextFocusNode: repAdharFocus),
                  const SizedBox(height: 16),
                  if (isMobile)
                    Column(children: [
                      buildTextField(
                          controller: repAdharController,
                          label: 'Representative Aadhar Number',
                          icon: Icons.credit_card,
                          focusNode: repAdharFocus,
                          nextFocusNode: repPanFocus,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(12)
                          ]),
                      const SizedBox(height: 12),
                      buildTextField(
                          controller: repPanController,
                          label: 'Representative PAN Number',
                          icon: Icons.assignment_ind,
                          focusNode: repPanFocus,
                          nextFocusNode: addressFocus,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9]')),
                            LengthLimitingTextInputFormatter(10)
                          ]),
                    ])
                  else
                    Row(children: [
                      Expanded(
                          child: buildTextField(
                              controller: repAdharController,
                              label: 'Representative Aadhar Number',
                              icon: Icons.credit_card,
                              focusNode: repAdharFocus,
                              nextFocusNode: repPanFocus,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(12)
                              ])),
                      const SizedBox(width: 12),
                      Expanded(
                          child: buildTextField(
                              controller: repPanController,
                              label: 'Representative PAN Number',
                              icon: Icons.assignment_ind,
                              focusNode: repPanFocus,
                              nextFocusNode: addressFocus,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[A-Za-z0-9]')),
                                LengthLimitingTextInputFormatter(10)
                              ])),
                    ]),
                  const SizedBox(height: 16),
                  buildTextField(
                      controller: addressController,
                      label: 'Address',
                      icon: Icons.location_on,
                      maxLines: 2,
                      focusNode: addressFocus,
                      nextFocusNode: additionalTermsFocus),
                  const SizedBox(height: 16),
                  buildTextField(
                      controller: additionalTermsController,
                      label: 'Additional Terms and Conditions',
                      icon: Icons.note_add,
                      maxLines: 2,
                      required: false,
                      focusNode: additionalTermsFocus),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(children: [
                      Row(children: [
                        Icon(Icons.fingerprint, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        const Text('Digital Signatures & Photos',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple)),
                      ]),
                      const Divider(height: 30, thickness: 1),
                      isMobile
                          ? Column(children: [
                        _buildSignatureCard({
                          'title': 'Representative Sign',
                          'images': repSigns,
                          'onChanged': (List<Uint8List> v) =>
                              setState(() => repSigns = v)
                        }),
                        const SizedBox(height: 16),
                        _buildSignatureCard({
                          'title': 'Representative Photo',
                          'images': repPhotos,
                          'onChanged': (List<Uint8List> v) =>
                              setState(() => repPhotos = v)
                        }),
                        const SizedBox(height: 16),
                        _buildSignatureCard({
                          'title': 'Owner Photo',
                          'images': ownerPhotos,
                          'onChanged': (List<Uint8List> v) =>
                              setState(() => ownerPhotos = v)
                        }),
                      ])
                          : Column(children: [
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: _buildSignatureCard({
                                    'title': 'Representative Sign',
                                    'images': repSigns,
                                    'onChanged': (List<Uint8List> v) =>
                                        setState(() => repSigns = v)
                                  })),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _buildSignatureCard({
                                    'title': 'Representative Photo',
                                    'images': repPhotos,
                                    'onChanged': (List<Uint8List> v) =>
                                        setState(() => repPhotos = v)
                                  })),
                            ]),
                        const SizedBox(height: 16),
                        _buildSignatureCard({
                          'title': 'Owner Photo',
                          'images': ownerPhotos,
                          'onChanged': (List<Uint8List> v) =>
                              setState(() => ownerPhotos = v)
                        }),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  if (selectedCompanyId != null) ...[
                    if (_isFetchingProducts)
                      const Center(child: CircularProgressIndicator())
                    else if (products.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12)),
                        child: const Center(
                            child: Text('No products found for this company.')),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                              colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(children: [
                          const SizedBox(height: 12),
                          // ✅ Legend
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.amber.shade200, width: 1),
                            ),
                            child: Row(children: [
                              Icon(Icons.info_outline,
                                  size: 14, color: Colors.amber.shade800),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Only approved products can be selected for agreement.',
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber.shade900),
                                ),
                              ),
                            ]),
                          ),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Text('Products of $selectedCompanyName',
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepPurple)),
                              Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // ✅ Select All — फक्त approved products साठी
                                        Checkbox(
                                            value: selectedProducts.isNotEmpty &&
                                                products.any((p) =>
                                                p.status ==
                                                    'approved') &&
                                                products
                                                    .where((p) =>
                                                p.status == 'approved')
                                                    .every((p) =>
                                                selectedProducts[
                                                products
                                                    .indexOf(
                                                    p)] ==
                                                    true),
                                            onChanged: toggleSelectAll,
                                            activeColor: Colors.deepPurple),
                                        const Text('Select All',
                                            style: TextStyle(fontSize: 11)),
                                      ]),
                                  SizedBox(
                                    width: 90,
                                    child: TextFormField(
                                      controller: globalProductProfitController,
                                      decoration: const InputDecoration(
                                        hintText: 'Profit %',
                                        border: OutlineInputBorder(),
                                        contentPadding: EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 6),
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                                  ElevatedButton(
                                      onPressed: applyGlobalProductProfit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(20)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                      ),
                                      child: const Text('Apply',
                                          style: TextStyle(fontSize: 11))),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: childAspectRatio,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              return _buildProductCard(
                                  index, crossAxisCount, childAspectRatio);
                            },
                          ),
                        ]),
                      ),
                    const SizedBox(height: 24),
                  ],
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('CREATE AGREEMENT',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    startDateController.dispose();
    endDateController.dispose();
    repNameController.dispose();
    repAdharController.dispose();
    repPanController.dispose();
    ownerNameController.dispose();
    ownerAdharController.dispose();
    ownerPanController.dispose();
    addressController.dispose();
    additionalTermsController.dispose();
    globalProductProfitController.dispose();
    _scrollController.dispose();
    for (var ctrl in productProfitControllers.values) {
      ctrl.dispose();
    }
    startDateFocus.dispose();
    endDateFocus.dispose();
    repNameFocus.dispose();
    repAdharFocus.dispose();
    repPanFocus.dispose();
    ownerNameFocus.dispose();
    ownerAdharFocus.dispose();
    ownerPanFocus.dispose();
    addressFocus.dispose();
    additionalTermsFocus.dispose();
    super.dispose();
  }
}

// ============================================================
// MARKETING PARTNER AGREEMENT FORM (unchanged from previous)
// ============================================================
class MarketingPartnerAgreementFormContent extends StatefulWidget {
  final VoidCallback onClose;
  const MarketingPartnerAgreementFormContent({required this.onClose});

  @override
  State<MarketingPartnerAgreementFormContent> createState() =>
      _MarketingPartnerAgreementFormContentState();
}

class _MarketingPartnerAgreementFormContentState
    extends State<MarketingPartnerAgreementFormContent> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isDisposed = false;
  bool _isMarketingPartner = false;
  MarketingPartner? _myPartnerProfile;

  final ScrollController _scrollController = ScrollController();

  late FocusNode startDateFocus;
  late FocusNode endDateFocus;
  late FocusNode partnerAddressFocus;
  late FocusNode adharFocus;
  late FocusNode panFocus;
  late FocusNode companyCommissionFocus;
  late FocusNode profitShareFocus;
  late FocusNode sellingCommissionFocus;
  late FocusNode additionalPointsFocus;
  late FocusNode repNameFocus;

  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  final partnerNameController = TextEditingController();
  final partnerAddressController = TextEditingController();
  final adharNumberController = TextEditingController();
  final panNumberController = TextEditingController();
  final companyCommissionController = TextEditingController(text: '5');
  final profitShareController = TextEditingController(text: '20');
  final sellingCommissionController = TextEditingController(text: '10');
  final additionalPointsController = TextEditingController();
  final repNameController = TextEditingController();

  List<MarketingPartner> _marketingPartners = [];
  bool _loadingPartners = false;
  int? _selectedMarketingPartnerId;

  List<Uint8List> qnxSigns = [];
  List<Uint8List> qnxPhotos = [];
  List<Uint8List> partnerPhotos = [];
  Uint8List? _uploadedPdfBytes;
  String? _uploadedPdfFileName;
  final int maxImages = 1;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _checkRoleAndLoadData();
    startDateFocus = FocusNode();
    endDateFocus = FocusNode();
    partnerAddressFocus = FocusNode();
    adharFocus = FocusNode();
    panFocus = FocusNode();
    companyCommissionFocus = FocusNode();
    profitShareFocus = FocusNode();
    sellingCommissionFocus = FocusNode();
    additionalPointsFocus = FocusNode();
    repNameFocus = FocusNode();
  }

  Future<void> _checkRoleAndLoadData() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? '';
    final roleLower = role.toLowerCase();

    final isPartner = roleLower.contains('marketing partner') ||
        roleLower.contains('marketing_partner');

    _safeSetState(() => _isMarketingPartner = isPartner);

    if (isPartner) {
      await _loadMyProfile();
    } else {
      await _fetchMarketingPartners();
    }
  }

  Future<void> _loadMyProfile() async {
    _safeSetState(() => _loadingPartners = true);

    try {
      final profileService = MarketingProfileService();
      final response = await profileService.getMyProfile();

      if (response.status && response.data != null) {
        final profile = response.data!;

        final addressParts = <String>[];
        if (profile.workingArea != null && profile.workingArea!.isNotEmpty) {
          addressParts.add(profile.workingArea!);
        }
        if (profile.village != null && profile.village!.isNotEmpty) {
          addressParts.add(profile.village!);
        }
        if (profile.taluka != null && profile.taluka!.isNotEmpty) {
          addressParts.add(profile.taluka!);
        }
        if (profile.district != null && profile.district!.isNotEmpty) {
          addressParts.add(profile.district!);
        }
        if (profile.state != null && profile.state!.isNotEmpty) {
          addressParts.add(profile.state!);
        }
        if (profile.pincode != null && profile.pincode!.isNotEmpty) {
          addressParts.add(profile.pincode!);
        }
        final address = addressParts.join(', ');

        _safeSetState(() {
          _selectedMarketingPartnerId = profile.id;
          partnerNameController.text = profile.fullName ?? '';
          partnerAddressController.text = address;
          _loadingPartners = false;
        });
      } else {
        _safeSetState(() => _loadingPartners = false);
        _showError('Failed to load your profile');
      }
    } catch (e) {
      _safeSetState(() => _loadingPartners = false);
      _showError('Failed to load profile: $e');
    }
  }

  Future<void> _fetchMarketingPartners() async {
    _safeSetState(() => _loadingPartners = true);
    try {
      final response = await MarketingPartnerService().getMarketingPartners();
      _safeSetState(() {
        _marketingPartners = response.data;
        _loadingPartners = false;
      });
    } catch (e) {
      _safeSetState(() => _loadingPartners = false);
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1, now.month, now.day),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        startDateController.text =
        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 10, now.month, now.day),
    );
    if (picked != null) {
      setState(() {
        endDateController.text =
        "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted && !_isDisposed) setState(fn);
  }

  void _showError(String msg) {
    if (mounted && !_isDisposed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    }
  }

  Color _getIconColor(String label) {
    final Map<String, Color> colors = {
      'Start': const Color(0xFF1ABC9C),
      'End': const Color(0xFFE74C3C),
      'Partner': const Color(0xFFF39C12),
      'Company': const Color(0xFFF39C12),
      'Profit': const Color(0xFFE91E63),
      'Aadhar': const Color(0xFF3498DB),
      'PAN': const Color(0xFF2ECC71),
      'Address': const Color(0xFF1E88E5),
      'Terms': const Color(0xFFFF9800),
      'Representative': const Color(0xFF9B59B6),
      'Commission': const Color(0xFF8B5CF6),
    };
    for (var entry in colors.entries) {
      if (label.contains(entry.key)) return entry.value;
    }
    return Colors.deepPurple;
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
    VoidCallback? onTap,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = true,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    TextInputAction? textInputAction,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? customValidator,
    bool showSuffixIcon = false,
    String suffixText = '',
  }) {
    final iconColor = _getIconColor(label);
    return TextFormField(
      inputFormatters: inputFormatters,
      validator: customValidator ??
          (required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null),
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      keyboardType: keyboardType,
      focusNode: focusNode,
      textInputAction: textInputAction ??
          (nextFocusNode != null
              ? TextInputAction.next
              : TextInputAction.done),
      onFieldSubmitted: nextFocusNode != null
          ? (value) => FocusScope.of(context).requestFocus(nextFocusNode)
          : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[700]),
        prefixIcon: Container(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: iconColor, size: 20)),
        suffixIcon: showSuffixIcon
            ? Container(
            padding: const EdgeInsets.all(14),
            child: Text(suffixText,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: iconColor)))
            : null,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: iconColor, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red, width: 2)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red, width: 2.5)),
        filled: true,
        fillColor: readOnly ? Colors.grey[100] : Colors.grey[50],
        contentPadding:
        const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      ),
    );
  }

  Widget _buildPdfUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient:
        const LinearGradient(colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.picture_as_pdf, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Upload Agreement PDF',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 12),
          if (_uploadedPdfFileName != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300)),
              child: Row(children: [
                Icon(Icons.picture_as_pdf,
                    color: Colors.red.shade600, size: 32),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(_uploadedPdfFileName!,
                        overflow: TextOverflow.ellipsis)),
                IconButton(
                    onPressed: () => setState(() {
                      _uploadedPdfBytes = null;
                      _uploadedPdfFileName = null;
                    }),
                    icon: const Icon(Icons.close, color: Colors.red)),
              ]),
            )
          else
            InkWell(
              onTap: () async {
                try {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['pdf'],
                  );
                  if (result != null && result.files.isNotEmpty) {
                    final file = result.files.first;
                    if (file.bytes != null) {
                      setState(() {
                        _uploadedPdfBytes = file.bytes;
                        _uploadedPdfFileName = file.name;
                      });
                    }
                  }
                } catch (e) {
                  _showError('Failed to pick PDF: $e');
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Column(children: [
                  Icon(Icons.upload_file,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text('Tap to upload PDF file',
                      style: TextStyle(color: Colors.grey.shade600)),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMarketingPartnerDropdown() {
    if (_isMarketingPartner) {
      return _loadingPartners
          ? const Center(child: CircularProgressIndicator())
          : buildTextField(
        controller: partnerNameController,
        label: 'Marketing Partner Name',
        icon: Icons.handshake,
        required: true,
        readOnly: true,
        focusNode: partnerAddressFocus,
      );
    }

    return _loadingPartners
        ? const Center(child: CircularProgressIndicator())
        : DropdownButtonFormField<int>(
      value: _selectedMarketingPartnerId,
      decoration: InputDecoration(
        labelText: 'Select Marketing Partner',
        labelStyle: TextStyle(color: Colors.grey[700]),
        prefixIcon: Container(
            padding: const EdgeInsets.all(10),
            child: const Icon(Icons.handshake,
                color: Color(0xFFF39C12), size: 20)),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            const BorderSide(color: Color(0xFFF39C12), width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red, width: 2)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.red, width: 2.5)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: _marketingPartners.map((p) {
        return DropdownMenuItem<int>(
          value: p.id,
          child: Text(p.name),
        );
      }).toList(),
      onChanged: (val) {
        if (val == null) return;
        final partner =
        _marketingPartners.firstWhere((p) => p.id == val);
        setState(() {
          _selectedMarketingPartnerId = val;
          partnerNameController.text = partner.name;
        });
      },
      validator: (v) => v == null ? 'Required' : null,
    );
  }

  Widget _buildSignatureCard(Map<String, dynamic> category) {
    final title = category['title'] as String;
    final List<Uint8List> images = category['images'];
    final Function(List<Uint8List>) onChanged = category['onChanged'];
    final isMobile = MediaQuery.of(context).size.width < 600;
    final thumbnailSize = isMobile ? 80.0 : 100.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style:
            const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[50]),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              ...images.map((img) => Stack(children: [
                Container(
                  width: thumbnailSize,
                  height: thumbnailSize,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                          image: MemoryImage(img), fit: BoxFit.cover)),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: GestureDetector(
                    onTap: () {
                      final newList = List<Uint8List>.from(images);
                      newList.remove(img);
                      onChanged(newList);
                    },
                    child: Container(
                        decoration: const BoxDecoration(
                            color: Colors.red, shape: BoxShape.circle),
                        child: const Icon(Icons.close,
                            size: 18, color: Colors.white)),
                  ),
                ),
              ])),
              if (images.length < maxImages)
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(
                        source: ImageSource.gallery, imageQuality: 85);
                    if (picked != null) {
                      final bytes = await picked.readAsBytes();
                      final newList = List<Uint8List>.from(images);
                      newList.add(bytes);
                      onChanged(newList);
                    }
                  },
                  child: Container(
                    width: thumbnailSize,
                    height: thumbnailSize,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white),
                    child: const Center(
                        child: Icon(Icons.add_a_photo,
                            size: 40, color: Colors.deepPurple)),
                  ),
                ),
              if (images.length < maxImages && title.contains('Sign'))
                GestureDetector(
                  onTap: () async {
                    final bytes = await showDialog<Uint8List>(
                      context: context,
                      builder: (_) => _SignatureDrawingDialog(title: title),
                    );
                    if (bytes != null) {
                      final newList = List<Uint8List>.from(images);
                      newList.add(bytes);
                      onChanged(newList);
                    }
                  },
                  child: Container(
                    width: thumbnailSize,
                    height: thumbnailSize,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.deepPurple.shade200),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.deepPurple.shade50),
                    child: const Center(
                        child: Icon(Icons.draw_rounded,
                            size: 36, color: Colors.deepPurple)),
                  ),
                ),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (!formState.validate()) return;

    if (_selectedMarketingPartnerId == null) {
      _showError('Please select a marketing partner');
      return;
    }

    _safeSetState(() => _isLoading = true);

    final request = MarketingPartnerAgreementCreateRequest(
      marketingPartnerId: _selectedMarketingPartnerId!,
      agreementStartDate: startDateController.text,
      agreementEndDate: endDateController.text,
      marketingPartnerName: partnerNameController.text,
      marketingPartnerAddress: partnerAddressController.text,
      adharNumber:
      adharNumberController.text.isNotEmpty ? adharNumberController.text : null,
      panNumber:
      panNumberController.text.isNotEmpty ? panNumberController.text : null,
      companyCommissionPercentage: companyCommissionController.text,
      profitSharePercentage: profitShareController.text,
      sellingCommissionPercentage: sellingCommissionController.text,
      qnxMartRepresentative: repNameController.text,
      additionalPoints: additionalPointsController.text,
      remarks: null,
      qnxMartSign: qnxSigns.isNotEmpty ? qnxSigns.first : null,
      qnxMartPicture: qnxPhotos.isNotEmpty ? qnxPhotos.first : null,
      marketingPartnerPicture:
      partnerPhotos.isNotEmpty ? partnerPhotos.first : null,
      uploadedAgreementPdf: _uploadedPdfBytes,
    );

    try {
      final response =
      await AgreementService.createMarketingPartnerAgreement(request);
      _safeSetState(() => _isLoading = false);

      if (response != null && response.success) {
        if (mounted && !_isDisposed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(response.message),
                backgroundColor: Colors.green),
          );
          widget.onClose();
        }
      } else {
        _showError(response?.message ?? 'Failed to create agreement');
      }
    } catch (e) {
      _safeSetState(() => _isLoading = false);
      _showError('Error: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    startDateController.dispose();
    endDateController.dispose();
    partnerNameController.dispose();
    partnerAddressController.dispose();
    adharNumberController.dispose();
    panNumberController.dispose();
    companyCommissionController.dispose();
    profitShareController.dispose();
    sellingCommissionController.dispose();
    additionalPointsController.dispose();
    repNameController.dispose();
    startDateFocus.dispose();
    endDateFocus.dispose();
    partnerAddressFocus.dispose();
    adharFocus.dispose();
    panFocus.dispose();
    companyCommissionFocus.dispose();
    profitShareFocus.dispose();
    sellingCommissionFocus.dispose();
    additionalPointsFocus.dispose();
    repNameFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF9B59B6), Color(0xFFFF6584)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Row(children: [
              const Expanded(
                child: Text(
                  'Create Marketing Partner Agreement',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20)),
                child: IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.close_rounded,
                        color: Colors.white)),
              ),
            ]),
          ),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  _buildPdfUploadSection(),
                  const SizedBox(height: 16),
                  _buildMarketingPartnerDropdown(),
                  const SizedBox(height: 16),
                  if (isMobile)
                    Column(children: [
                      buildTextField(
                          controller: startDateController,
                          label: 'Start Date',
                          icon: Icons.calendar_today,
                          readOnly: true,
                          onTap: () => _selectStartDate(context),
                          focusNode: startDateFocus,
                          nextFocusNode: endDateFocus),
                      const SizedBox(height: 12),
                      buildTextField(
                          controller: endDateController,
                          label: 'End Date',
                          icon: Icons.calendar_month,
                          readOnly: true,
                          onTap: () => _selectEndDate(context),
                          focusNode: endDateFocus,
                          nextFocusNode: partnerAddressFocus),
                    ])
                  else
                    Row(children: [
                      Expanded(
                          child: buildTextField(
                              controller: startDateController,
                              label: 'Start Date',
                              icon: Icons.calendar_today,
                              readOnly: true,
                              onTap: () => _selectStartDate(context),
                              focusNode: startDateFocus,
                              nextFocusNode: endDateFocus)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: buildTextField(
                              controller: endDateController,
                              label: 'End Date',
                              icon: Icons.calendar_month,
                              readOnly: true,
                              onTap: () => _selectEndDate(context),
                              focusNode: endDateFocus,
                              nextFocusNode: partnerAddressFocus)),
                    ]),
                  const SizedBox(height: 16),
                  buildTextField(
                      controller: partnerAddressController,
                      label: 'Marketing Partner Address',
                      icon: Icons.location_on,
                      maxLines: 2,
                      required: true,
                      focusNode: partnerAddressFocus,
                      nextFocusNode: adharFocus),
                  const SizedBox(height: 16),
                  if (isMobile)
                    Column(children: [
                      buildTextField(
                          controller: adharNumberController,
                          label: 'Aadhar Number',
                          icon: Icons.credit_card,
                          focusNode: adharFocus,
                          nextFocusNode: panFocus,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(12)
                          ]),
                      const SizedBox(height: 12),
                      buildTextField(
                          controller: panNumberController,
                          label: 'PAN Number',
                          icon: Icons.assignment_ind,
                          focusNode: panFocus,
                          nextFocusNode: companyCommissionFocus,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9]')),
                            LengthLimitingTextInputFormatter(10)
                          ]),
                    ])
                  else
                    Row(children: [
                      Expanded(
                          child: buildTextField(
                              controller: adharNumberController,
                              label: 'Aadhar Number',
                              icon: Icons.credit_card,
                              focusNode: adharFocus,
                              nextFocusNode: panFocus,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(12)
                              ])),
                      const SizedBox(width: 12),
                      Expanded(
                          child: buildTextField(
                              controller: panNumberController,
                              label: 'PAN Number',
                              icon: Icons.assignment_ind,
                              focusNode: panFocus,
                              nextFocusNode: companyCommissionFocus,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[A-Za-z0-9]')),
                                LengthLimitingTextInputFormatter(10)
                              ])),
                    ]),
                  const SizedBox(height: 16),
                  if (isMobile)
                    Column(children: [
                      buildTextField(
                          controller: companyCommissionController,
                          label: 'Company Commission %',
                          icon: Icons.percent,
                          keyboardType: TextInputType.number,
                          focusNode: companyCommissionFocus,
                          nextFocusNode: profitShareFocus,
                          showSuffixIcon: true,
                          suffixText: '%'),
                      const SizedBox(height: 12),
                      buildTextField(
                          controller: profitShareController,
                          label: 'Profit Share %',
                          icon: Icons.trending_up,
                          keyboardType: TextInputType.number,
                          focusNode: profitShareFocus,
                          nextFocusNode: sellingCommissionFocus,
                          showSuffixIcon: true,
                          suffixText: '%'),
                      const SizedBox(height: 12),
                      buildTextField(
                          controller: sellingCommissionController,
                          label: 'Selling Commission %',
                          icon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          focusNode: sellingCommissionFocus,
                          nextFocusNode: additionalPointsFocus,
                          showSuffixIcon: true,
                          suffixText: '%'),
                    ])
                  else
                    Row(children: [
                      Expanded(
                          child: buildTextField(
                              controller: companyCommissionController,
                              label: 'Company Commission %',
                              icon: Icons.percent,
                              keyboardType: TextInputType.number,
                              focusNode: companyCommissionFocus,
                              nextFocusNode: profitShareFocus,
                              showSuffixIcon: true,
                              suffixText: '%')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: buildTextField(
                              controller: profitShareController,
                              label: 'Profit Share %',
                              icon: Icons.trending_up,
                              keyboardType: TextInputType.number,
                              focusNode: profitShareFocus,
                              nextFocusNode: sellingCommissionFocus,
                              showSuffixIcon: true,
                              suffixText: '%')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: buildTextField(
                              controller: sellingCommissionController,
                              label: 'Selling Commission %',
                              icon: Icons.attach_money,
                              keyboardType: TextInputType.number,
                              focusNode: sellingCommissionFocus,
                              nextFocusNode: additionalPointsFocus,
                              showSuffixIcon: true,
                              suffixText: '%')),
                    ]),
                  const SizedBox(height: 16),
                  buildTextField(
                      controller: additionalPointsController,
                      label: 'Additional Terms and Conditions',
                      icon: Icons.note_add,
                      maxLines: 2,
                      required: false,
                      focusNode: additionalPointsFocus,
                      nextFocusNode: repNameFocus),
                  const SizedBox(height: 16),
                  buildTextField(
                      controller: repNameController,
                      label: 'QNX Mart Representative',
                      icon: Icons.person_outline,
                      focusNode: repNameFocus,
                      textInputAction: TextInputAction.done),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(children: [
                      Row(children: [
                        Icon(Icons.fingerprint, color: Colors.deepPurple),
                        const SizedBox(width: 8),
                        const Text('Digital Signatures & Photos',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple)),
                      ]),
                      const Divider(height: 30, thickness: 1),
                      isMobile
                          ? Column(children: [
                        _buildSignatureCard({
                          'title': 'QNX Mart Sign',
                          'images': qnxSigns,
                          'onChanged': (List<Uint8List> v) =>
                              setState(() => qnxSigns = v)
                        }),
                        const SizedBox(height: 16),
                        _buildSignatureCard({
                          'title': 'QNX Mart Photo',
                          'images': qnxPhotos,
                          'onChanged': (List<Uint8List> v) =>
                              setState(() => qnxPhotos = v)
                        }),
                        const SizedBox(height: 16),
                        _buildSignatureCard({
                          'title': 'Partner Photo',
                          'images': partnerPhotos,
                          'onChanged': (List<Uint8List> v) =>
                              setState(() => partnerPhotos = v)
                        }),
                      ])
                          : Column(children: [
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: _buildSignatureCard({
                                    'title': 'QNX Mart Sign',
                                    'images': qnxSigns,
                                    'onChanged': (List<Uint8List> v) =>
                                        setState(() => qnxSigns = v)
                                  })),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _buildSignatureCard({
                                    'title': 'QNX Mart Photo',
                                    'images': qnxPhotos,
                                    'onChanged': (List<Uint8List> v) =>
                                        setState(() => qnxPhotos = v)
                                  })),
                            ]),
                        const SizedBox(height: 16),
                        _buildSignatureCard({
                          'title': 'Partner Photo',
                          'images': partnerPhotos,
                          'onChanged': (List<Uint8List> v) =>
                              setState(() => partnerPhotos = v)
                        }),
                      ]),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('CREATE AGREEMENT',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SIGNATURE DRAWING DIALOG
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

class _SignatureDrawingDialog extends StatefulWidget {
  final String title;
  const _SignatureDrawingDialog({required this.title});

  @override
  State<_SignatureDrawingDialog> createState() =>
      _SignatureDrawingDialogState();
}

class _SignatureDrawingDialogState extends State<_SignatureDrawingDialog> {
  final List<List<Offset>> _strokes = [];
  final GlobalKey _boundaryKey = GlobalKey();

  void _clear() {
    setState(() {
      _strokes.clear();
    });
  }

  Future<void> _save() async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please draw your signature first'),
            backgroundColor: Colors.orange),
      );
      return;
    }
    try {
      final boundary =
      _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      if (mounted) Navigator.of(context).pop(bytes);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to save signature: $e'),
              backgroundColor: Colors.red),
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
            Row(children: [
              const Icon(Icons.draw_rounded, color: Colors.deepPurple),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(widget.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16))),
              IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close)),
            ]),
            const SizedBox(height: 8),
            Text('Draw your signature on the board below',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 12),
            RepaintBoundary(
              key: _boundaryKey,
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400, width: 2),
                    borderRadius: BorderRadius.circular(12)),
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
                        size: Size.infinite),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: _clear,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Clear'))),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white))),
            ]),
          ],
        ),
      ),
    );
  }
}