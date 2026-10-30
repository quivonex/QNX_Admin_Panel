// lib/screens/qnx_admin/agreement_screen.dart

import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:ui' show RenderRepaintBoundary;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../api/api_service.dart';
import '../../models/marketing_partner/marketing_agreement_model.dart';
import '../../models/qnx_admin/agreement_model.dart';
import '../../models/qnx_admin/marketing_head_model.dart';
import '../../models/qnx_admin/marketing_partner_model.dart';
import '../../models/qnx_admin/agreement_model.dart'
    hide MarketingPartnerAgreementModel, MarketingPartnerAgreementData;

import '../../api/marketing_service.dart' show MarketingProfileService;

enum AgreementType {
  company,
  marketingPartner,
}

extension AgreementTypeExt on AgreementType {
  String get label {
    switch (this) {
      case AgreementType.company:
        return 'QNX Admin to Company';
      case AgreementType.marketingPartner:
        return 'QNX Admin to Marketing Partner';
    }
  }

  IconData get icon {
    switch (this) {
      case AgreementType.company:
        return Icons.business_rounded;
      case AgreementType.marketingPartner:
        return Icons.handshake_rounded;
    }
  }

  Color get color {
    switch (this) {
      case AgreementType.company:
        return const Color(0xFF6C63FF);
      case AgreementType.marketingPartner:
        return const Color(0xFFFF6584);
    }
  }

  String get roleString {
    switch (this) {
      case AgreementType.company:
        return 'company';
      case AgreementType.marketingPartner:
        return 'marketing_partner';
    }
  }
}

class AgreementScreen extends StatefulWidget {
  @override
  State<AgreementScreen> createState() => _AgreementScreenState();
}

class _AgreementScreenState extends State<AgreementScreen>
    with SingleTickerProviderStateMixin {
  AgreementType? _selectedType;
  AgreementData? _selectedAgreement;
  MarketingPartnerAgreementData? _selectedMarketingPartnerAgreement;

  List<AgreementCompanyModel> _companies = [];
  bool _loadingCompanies = true;

  List<AgreementData> _agreementList = [];
  List<MarketingPartnerAgreementData> _marketingPartnerAgreementList = [];
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
    _fetchCompanies();
  }

  Future<void> _fetchCompanies() async {
    try {
      final res = await AgreementCompanyService().getCompanies();
      if (mounted) {
        setState(() {
          _companies = res.data;
          _loadingCompanies = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingCompanies = false);
      }
    }
  }

  Future<void> _fetchAgreementsByRole(String role) async {
    if (!mounted) return;
    _safeSetState(() {
      _loadingAgreements = true;
      _agreementList = [];
      _marketingPartnerAgreementList = [];
      _selectedAgreement = null;
      _selectedMarketingPartnerAgreement = null;
    });

    try {
      if (role == 'marketing_partner') {
        final res = await AgreementService.fetchMarketingPartnerAgreements();
        if (mounted) {
          _safeSetState(() {
            _marketingPartnerAgreementList = res.data;
            _loadingAgreements = false;
          });
        }
      } else {
        final res = await AgreementService.fetchCompanyAgreements();
        final filtered =
        res.data.where((ag) => ag.agreementRole == role).toList();
        if (mounted) {
          _safeSetState(() {
            _agreementList = filtered;
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
      _fetchAgreementsByRole(_selectedType!.roleString);
    }
  }

  void _onTypeSelected(AgreementType type) {
    if (!mounted) return;
    setState(() {
      _selectedType = type;
      _selectedAgreement = null;
      _selectedMarketingPartnerAgreement = null;
    });
    _fetchAgreementsByRole(type.roleString);
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
                : _AgreementFormContent(
              onClose: () {
                if (mounted) Navigator.of(ctx).pop();
              },
              agreementType: _selectedType!,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleApprove(AgreementData agreement) async {
    if (!mounted) return;
    try {
      final response = await AgreementService.approveCompanyAgreement(
        agreementId: agreement.id,
        remarks: 'Agreement verified and approved successfully.',
      );

      if (!mounted) return;

      if (response != null && response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: Colors.green),
        );
        if (_selectedType != null) {
          _fetchAgreementsByRole(_selectedType!.roleString);
        }
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
        SnackBar(content: Text('Failed to approve: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleMarketingPartnerApprove(
      MarketingPartnerAgreementData agreement) async {
    if (!mounted) return;
    try {
      final response = await AgreementService.approveMarketingPartnerAgreement(
        agreementId: agreement.agreementId,
        remarks: 'Agreement verified and approved successfully.',
      );

      if (!mounted) return;

      if (response != null && response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: Colors.green),
        );
        if (_selectedType != null) {
          _fetchAgreementsByRole(_selectedType!.roleString);
        }
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
        SnackBar(content: Text('Failed to approve: $e'), backgroundColor: Colors.red),
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

  Future<void> _handleReject(AgreementData agreement) async {
    if (!mounted) return;
    final reason = await _showRejectDialog();
    if (reason == null || reason.isEmpty) return;
    if (!mounted) return;

    try {
      final response = await AgreementService.rejectCompanyAgreement(
        agreementId: agreement.id,
        rejectionReason: reason,
      );

      if (!mounted) return;

      if (response != null && response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: Colors.orange),
        );
        setState(() => _selectedAgreement = null);
        if (_selectedType != null) {
          await _fetchAgreementsByRole(_selectedType!.roleString);
        }
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

  Future<void> _handleMarketingPartnerReject(
      MarketingPartnerAgreementData agreement) async {
    if (!mounted) return;
    final reason = await _showRejectDialog();
    if (reason == null || reason.isEmpty) return;
    if (!mounted) return;

    try {
      final response = await AgreementService.rejectMarketingPartnerAgreement(
        agreementId: agreement.agreementId,
        rejectionReason: reason,
      );

      if (!mounted) return;

      if (response != null && response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: Colors.orange),
        );
        setState(() => _selectedMarketingPartnerAgreement = null);
        if (_selectedType != null) {
          await _fetchAgreementsByRole(_selectedType!.roleString);
        }
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

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(date));
    } catch (_) {
      return date;
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
                          padding: EdgeInsets.only(
                              right: i < 1 ? 12 : 0),
                          child: ScaleTransition(
                            scale: _cardAnimations[i],
                            child: _TypeCard(
                              type: AgreementType.values[i],
                              isSelected: _selectedType ==
                                  AgreementType.values[i],
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
    final hasSelection = _selectedAgreement != null ||
        _selectedMarketingPartnerAgreement != null;
    if (hasSelection) {
      return Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                if (mounted) {
                  setState(() {
                    _selectedAgreement = null;
                    _selectedMarketingPartnerAgreement = null;
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
      if (_marketingPartnerAgreementList.isEmpty) {
        return _buildEmptyState();
      }
      return ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: _marketingPartnerAgreementList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final ag = _marketingPartnerAgreementList[i];
          final isSelected =
              _selectedMarketingPartnerAgreement?.agreementId == ag.agreementId;
          final color = _selectedType!.color;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedMarketingPartnerAgreement = ag;
              _selectedAgreement = null;
            }),
            child: _buildMPListItem(ag, isSelected, color),
          );
        },
      );
    }

    if (_agreementList.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: _agreementList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final ag = _agreementList[i];
        final isSelected = _selectedAgreement?.id == ag.id;
        final color = _selectedType!.color;
        return GestureDetector(
          onTap: () => setState(() {
            _selectedAgreement = ag;
            _selectedMarketingPartnerAgreement = null;
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
      AgreementData ag, bool isSelected, Color color) {
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
                (ag.companyName != null && ag.companyName!.isNotEmpty)
                    ? ag.companyName![0].toUpperCase()
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
                  (ag.companyName != null && ag.companyName!.isNotEmpty)
                      ? ag.companyName!
                      : (ag.companyOwnerName.isNotEmpty
                      ? ag.companyOwnerName
                      : 'Agreement #${ag.id}'),
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
                    if (ag.agreementProducts != null &&
                        ag.agreementProducts!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${ag.agreementProducts!.length} products',
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
          if (ag.status == 'pending')
            _actionButtons(
              onApprove: () => _handleApprove(ag),
              onReject: () => _handleReject(ag),
            ),
          if (isSelected)
            Icon(Icons.chevron_right_rounded, color: color, size: 20),
        ],
      ),
    );
  }

  Widget _buildMPListItem(
      MarketingPartnerAgreementData ag, bool isSelected, Color color) {
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
                (ag.marketingPartnerName?.isNotEmpty ?? false)
                    ? ag.marketingPartnerName![0].toUpperCase()
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
                  ag.marketingPartnerName ??
                      'Marketing Partner #${ag.marketingPartnerId}',
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
          if (ag.status == 'pending')
            _actionButtons(
              onApprove: () => _handleMarketingPartnerApprove(ag),
              onReject: () => _handleMarketingPartnerReject(ag),
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
        _selectedMarketingPartnerAgreement != null) {
      return _MarketingPartnerAgreementDetailView(
        data: _selectedMarketingPartnerAgreement!,
        typeColor: _selectedType!.color,
        onApprove: () =>
            _handleMarketingPartnerApprove(_selectedMarketingPartnerAgreement!),
        onReject: () =>
            _handleMarketingPartnerReject(_selectedMarketingPartnerAgreement!),
      );
    }

    if (_selectedAgreement == null) {
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

    return _AgreementDetailView(
      data: _selectedAgreement!,
      typeColor: _selectedType!.color,
      typeLabel: _selectedType!.label,
      onApprove: () => _handleApprove(_selectedAgreement!),
      onReject: () => _handleReject(_selectedAgreement!),
      onUpdateSuccess: _refreshAgreementList,
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
              color: selected ? color : (_hovered ? color : Colors.grey.shade200),
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
// MARKETING PARTNER AGREEMENT DETAIL VIEW
// ============================================================
class _MarketingPartnerAgreementDetailView extends StatelessWidget {
  final MarketingPartnerAgreementData data;
  final Color typeColor;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _MarketingPartnerAgreementDetailView({
    required this.data,
    required this.typeColor,
    required this.onApprove,
    required this.onReject,
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
                        data.marketingPartnerName ?? 'Marketing Partner',
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
                if (data.status == 'pending')
                  ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_circle, size: 16),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                if (data.status == 'pending') const SizedBox(width: 8),
                if (data.status == 'pending')
                  ElevatedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.cancel, size: 16),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
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
                  const SizedBox(height: 24),
                  _section('Marketing Partner Details', typeColor),
                  const SizedBox(height: 12),
                  _info('Partner Name', data.marketingPartnerName ?? '-',
                      typeColor),
                  const SizedBox(height: 8),
                  _info('Address', data.marketingPartnerAddress ?? '-',
                      typeColor),

                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: _info(
                        'Aadhar Number',
                        data.adharNumber ?? '-',
                        typeColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _info(
                        'PAN Number',
                        data.panNumber ?? '-',
                        typeColor,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _section('Commission & Profit', typeColor),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _info(
                            'Company Commission %',
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
                        child: _info(
                            'Selling Commission %',
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
                                style: TextStyle(
                                    color: Colors.red.shade900)),
                          ]),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (data.hasPdf) ...[
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
                          onPressed: () =>
                              _openPdf(context, data.uploadedAgreementPdfUrl),
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
                  if (data.hasImages) ...[
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

  Widget _section(String title, Color color) {
    return Row(children: [
      Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
              child: Icon(Icons.image_not_supported,
                  color: color, size: 32),
            )),
      ),
      const SizedBox(height: 6),
      Text(label,
          style: TextStyle(fontSize: 11, color: Colors.grey[600])),
    ]);
  }
}

// ============================================================
// MARKETING PARTNER AGREEMENT CREATE FORM
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
  String _userRole = '';
  MarketingPartner? _myPartnerProfile;

  // ✅ NEW: Validation + Scroll
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _fieldKeys = {};
  final Map<String, FocusNode> _fieldFocusNodes = {};

  late FocusNode agreementNoFocus;
  late FocusNode startDateFocus;
  late FocusNode endDateFocus;
  late FocusNode partnerNameFocus;
  late FocusNode partnerAddressFocus;
  late FocusNode adharFocus;
  late FocusNode panFocus;
  late FocusNode companyCommissionFocus;
  late FocusNode profitShareFocus;
  late FocusNode sellingCommissionFocus;
  late FocusNode additionalPointsFocus;
  late FocusNode repNameFocus;

  final agreementNoController = TextEditingController();
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
  List<Uint8List> partnerSigns = [];
  List<Uint8List> qnxPhotos = [];
  List<Uint8List> partnerPhotos = [];
  Uint8List? _uploadedPdfBytes;
  String? _uploadedPdfFileName;
  final int maxImages = 1;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _generateAgreementNumber();
    _fetchMarketingPartners();
    _checkRoleAndLoadData();
    agreementNoFocus = FocusNode();
    startDateFocus = FocusNode();
    endDateFocus = FocusNode();
    partnerNameFocus = FocusNode();
    partnerAddressFocus = FocusNode();
    adharFocus = FocusNode();
    panFocus = FocusNode();
    companyCommissionFocus = FocusNode();
    profitShareFocus = FocusNode();
    sellingCommissionFocus = FocusNode();
    additionalPointsFocus = FocusNode();
    repNameFocus = FocusNode();

    // ✅ NEW: Field keys register
    _registerField('Agreement Number');
    _registerField('Partner Name');
    _registerField('Start Date');
    _registerField('End Date');
    _registerField('Address');
    _registerField('Aadhar');
    _registerField('PAN');
    _registerField('Company Commission');
    _registerField('Profit Share');
    _registerField('Selling Commission');
    _registerField('Additional Terms');
    _registerField('Representative');
  }

  void _generateAgreementNumber() {
    final now = DateTime.now();
    final formatted = DateFormat('yyyyMMdd').format(now);
    final random = (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    agreementNoController.text = "MP-AGR-$formatted-$random";
  }

  // ============================================================
  // ✅ NEW: Field validation + scroll helpers
  // ============================================================
  void _registerField(String fieldName) {
    _fieldKeys[fieldName] = GlobalKey();
    _fieldFocusNodes[fieldName] = FocusNode();
  }

  String? _getFieldValue(String fieldName) {
    switch (fieldName) {
      case 'Agreement Number': return agreementNoController.text;
      case 'Partner Name': return partnerNameController.text;
      case 'Start Date': return startDateController.text;
      case 'End Date': return endDateController.text;
      case 'Address': return partnerAddressController.text;
      case 'Aadhar': return adharNumberController.text;
      case 'PAN': return panNumberController.text;
      case 'Company Commission': return companyCommissionController.text;
      case 'Profit Share': return profitShareController.text;
      case 'Selling Commission': return sellingCommissionController.text;
      case 'Additional Terms': return additionalPointsController.text;
      case 'Representative': return repNameController.text;
      default: return null;
    }
  }

  Future<void> _validateAndScroll() async {
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (formState.validate()) return;

    final fieldOrder = [
      'Agreement Number', 'Partner Name', 'Start Date', 'End Date',
      'Address', 'Aadhar', 'PAN',
      'Company Commission', 'Profit Share', 'Selling Commission',
      'Additional Terms', 'Representative',
    ];

    String? firstInvalid;
    for (final f in fieldOrder) {
      if (f == 'Additional Terms') continue;
      if (f == 'Agreement Number') continue;
      if (f == 'Partner Name' && _isMarketingPartner) continue;
      final v = _getFieldValue(f);
      if (v == null || v.trim().isEmpty) {
        firstInvalid = f;
        break;
      }
    }

    if (mounted && !_isDisposed) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                firstInvalid != null
                    ? 'Please fill "$firstInvalid" field'
                    : 'Please fill all required fields',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    if (firstInvalid != null) {
      final key = _fieldKeys[firstInvalid];
      final fn = _fieldFocusNodes[firstInvalid];

      if (key != null && key.currentContext != null) {
        await Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.3,
        );
      }
      if (fn != null && !fn.hasFocus) {
        await Future.delayed(const Duration(milliseconds: 300));
        fn.requestFocus();
      }
    }
  }

  Future<void> _checkRoleAndLoadData() async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role') ?? '';
    final roleLower = role.toLowerCase();

    final isPartner = roleLower.contains('marketing partner') ||
        roleLower.contains('marketing_partner');

    _safeSetState(() {
      _userRole = role;
      _isMarketingPartner = isPartner;
    });

    print('🔍 ===== ROLE CHECK =====');
    print('🔍 Role: "$role"');
    print('🔍 Is Marketing Partner: $isPartner');
    print('🔍 =======================');

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

        String address = '';
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
        address = addressParts.join(', ');

        _safeSetState(() {
          _selectedMarketingPartnerId = profile.id;
          partnerNameController.text = profile.fullName ?? '';
          partnerAddressController.text = address;
          _loadingPartners = false;
        });

        print('✅ Auto-filled partner details:');
        print('   ID: ${profile.id}');
        print('   Name: ${profile.fullName}');
        print('   Address: $address');
        print('   Mobile: ${profile.mobile}');
        print('   Email: ${profile.email}');
      } else {
        _safeSetState(() => _loadingPartners = false);
        _showError('Failed to load your profile');
      }
    } catch (e) {
      _safeSetState(() => _loadingPartners = false);
      print('❌ Load Profile Error: $e');
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

  Future<void> _pickPdfFile() async {
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
  }

  void _removePdf() {
    setState(() {
      _uploadedPdfBytes = null;
      _uploadedPdfFileName = null;
    });
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
      'Agreement': const Color(0xFF6C63FF),
      'Owner': const Color(0xFF00BFA5),
      'Start': const Color(0xFF1ABC9C),
      'End': const Color(0xFFE74C3C),
      'Partner': const Color(0xFFF39C12),
      'Company': const Color(0xFFF39C12),
      'Global': const Color(0xFF9B59B6),
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
    String? fieldKey,
  }) {
    final iconColor = _getIconColor(label);
    final Widget field = TextFormField(
      inputFormatters: inputFormatters,
      validator: customValidator ??
          (required ? (v) => v!.isEmpty ? 'Required' : null : null),
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

    if (fieldKey != null && _fieldKeys.containsKey(fieldKey)) {
      return Container(key: _fieldKeys[fieldKey], child: field);
    }
    return field;
  }

  Widget _buildPdfUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [
          Color(0xFFF8FAFC),
          Color(0xFFF1F5F9)
        ]),
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
                Icon(Icons.picture_as_pdf, color: Colors.red.shade600, size: 32),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(_uploadedPdfFileName!,
                        overflow: TextOverflow.ellipsis)),
                IconButton(
                    onPressed: _removePdf,
                    icon: const Icon(Icons.close, color: Colors.red)),
              ]),
            )
          else
            InkWell(
              onTap: _pickPdfFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Column(children: [
                  Icon(Icons.upload_file, size: 48, color: Colors.grey.shade400),
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
          : Container(
        key: _fieldKeys['Partner Name'],
        child: buildTextField(
          controller: partnerNameController,
          label: 'Marketing Partner Name',
          icon: Icons.handshake,
          required: true,
          readOnly: true,
          focusNode: partnerNameFocus,
          nextFocusNode: partnerAddressFocus,
          fieldKey: 'Partner Name',
        ),
      );
    }

    return _loadingPartners
        ? const Center(child: CircularProgressIndicator())
        : Container(
      key: _fieldKeys['Partner Name'],
      child: DropdownButtonFormField<int>(
        value: _selectedMarketingPartnerId,
        decoration: InputDecoration(
          labelText: 'Select Marketing Partner',
          labelStyle: TextStyle(color: Colors.grey[700]),
          prefixIcon: Container(
              padding: const EdgeInsets.all(10),
              child: Icon(Icons.handshake,
                  color: const Color(0xFFF39C12), size: 20)),
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
              borderSide:
              const BorderSide(color: Colors.red, width: 2)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
              const BorderSide(color: Colors.red, width: 2.5)),
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
      ),
    );
  }

  Widget _buildDigitalSignaturesGrid() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final List<Map<String, dynamic>> categories = [
      {
        'title': 'QNX Mart Sign',
        'images': qnxSigns,
        'onChanged': (List<Uint8List> v) => setState(() => qnxSigns = v)
      },
      {
        'title': 'Partner Sign',
        'images': partnerSigns,
        'onChanged': (List<Uint8List> v) => setState(() => partnerSigns = v)
      },
      {
        'title': 'QNX Mart Photo',
        'images': qnxPhotos,
        'onChanged': (List<Uint8List> v) => setState(() => qnxPhotos = v)
      },
      {
        'title': 'Partner Photo',
        'images': partnerPhotos,
        'onChanged': (List<Uint8List> v) => setState(() => partnerPhotos = v)
      },
    ];
    if (isMobile) {
      return Column(
        children: categories
            .map((cat) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildImagePickerCard(cat)))
            .toList(),
      );
    } else {
      return Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _buildImagePickerCard(categories[0])),
          const SizedBox(width: 12),
          Expanded(child: _buildImagePickerCard(categories[1])),
        ]),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _buildImagePickerCard(categories[2])),
          const SizedBox(width: 12),
          Expanded(child: _buildImagePickerCard(categories[3])),
        ]),
      ]);
    }
  }

  Widget _buildImagePickerCard(Map<String, dynamic> category) {
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
    if (!formState.validate()) {
      await _validateAndScroll();
      return;
    }

    if (_selectedMarketingPartnerId == null) {
      _showError('Please select a marketing partner');
      return;
    }

    if (_isMarketingPartner) {
      final prefs = await SharedPreferences.getInstance();
      final myPartnerId = prefs.getString('marketing_partner_id') ??
          prefs.getString('partner_id') ??
          prefs.getString('user_id');

      if (myPartnerId != null && myPartnerId.isNotEmpty) {
        _selectedMarketingPartnerId =
            int.tryParse(myPartnerId) ?? _selectedMarketingPartnerId;
      }
    }

    _safeSetState(() => _isLoading = true);

    print('🔍 ===== UPLOAD DEBUG =====');
    print(
        '📸 QNX Sign: ${qnxSigns.isNotEmpty ? "✅ ${qnxSigns.first.length} bytes" : "❌ Empty"}');
    print(
        '📸 Partner Sign: ${partnerSigns.isNotEmpty ? "✅ ${partnerSigns.first.length} bytes" : "❌ Empty"}');
    print(
        '📸 QNX Photo: ${qnxPhotos.isNotEmpty ? "✅ ${qnxPhotos.first.length} bytes" : "❌ Empty"}');
    print(
        '📸 Partner Photo: ${partnerPhotos.isNotEmpty ? "✅ ${partnerPhotos.first.length} bytes" : "❌ Empty"}');
    print(
        '📄 PDF: ${_uploadedPdfBytes != null ? "✅ ${_uploadedPdfBytes!.length} bytes" : "❌ Empty"}');
    print('🔍 =========================');

    final model = MarketingPartnerAgreementModel(
      agreementNumber: agreementNoController.text,
      marketingPartnerId: _selectedMarketingPartnerId!,
      agreementRole: 'marketing_partner',
      agreementStartDate: startDateController.text,
      agreementEndDate: endDateController.text,
      marketingPartnerName: partnerNameController.text,
      marketingPartnerAddress: partnerAddressController.text,
      companyCommissionPercentage: companyCommissionController.text,
      profitSharePercentage: profitShareController.text,
      sellingCommissionPercentage: sellingCommissionController.text,
      additionalPoints: additionalPointsController.text,
      qnxMartRepresentative: repNameController.text,
      remarks: null,
      adharNumber: adharNumberController.text.isNotEmpty
          ? adharNumberController.text
          : null,
      panNumber:
      panNumberController.text.isNotEmpty ? panNumberController.text : null,
      qnxMartSign: qnxSigns.isNotEmpty ? qnxSigns.first : null,
      marketingPartnerSign: partnerSigns.isNotEmpty ? partnerSigns.first : null,
      qnxMartPicture: qnxPhotos.isNotEmpty ? qnxPhotos.first : null,
      marketingPartnerPicture:
      partnerPhotos.isNotEmpty ? partnerPhotos.first : null,
      uploadedAgreementPdf: _uploadedPdfBytes,
    );

    try {
      final response =
      await AgreementService.createMarketingPartnerAgreement(model);
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
    agreementNoController.dispose();
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

    agreementNoFocus.dispose();
    startDateFocus.dispose();
    endDateFocus.dispose();
    partnerNameFocus.dispose();
    partnerAddressFocus.dispose();
    adharFocus.dispose();
    panFocus.dispose();
    companyCommissionFocus.dispose();
    profitShareFocus.dispose();
    sellingCommissionFocus.dispose();
    additionalPointsFocus.dispose();
    repNameFocus.dispose();

    _scrollController.dispose();
    for (var fn in _fieldFocusNodes.values) {
      fn.dispose();
    }

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
                  buildTextField(
                    controller: agreementNoController,
                    label: 'Agreement Number',
                    icon: Icons.numbers,
                    required: false,
                    readOnly: true,
                    focusNode: agreementNoFocus,
                    fieldKey: 'Agreement Number',
                  ),
                  const SizedBox(height: 16),

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
                          fieldKey: 'Start Date',
                          nextFocusNode: endDateFocus),
                      const SizedBox(height: 12),
                      buildTextField(
                          controller: endDateController,
                          label: 'End Date',
                          icon: Icons.calendar_month,
                          readOnly: true,
                          onTap: () => _selectEndDate(context),
                          focusNode: endDateFocus,
                          fieldKey: 'End Date',
                          nextFocusNode: partnerNameFocus),
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
                              fieldKey: 'Start Date',
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
                              fieldKey: 'End Date',
                              nextFocusNode: partnerNameFocus)),
                    ]),
                  const SizedBox(height: 16),

                  buildTextField(
                      controller: partnerAddressController,
                      label: 'Marketing Partner Address',
                      icon: Icons.location_on,
                      maxLines: 2,
                      required: true,
                      focusNode: partnerAddressFocus,
                      fieldKey: 'Address',
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
                          fieldKey: 'Aadhar',
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(12)
                          ],
                          customValidator: (value) {
                            if (value == null || value.isEmpty) return null;
                            if (value.length != 12)
                              return 'Aadhar must be exactly 12 digits';
                            return null;
                          }),
                      const SizedBox(height: 12),
                      buildTextField(
                          controller: panNumberController,
                          label: 'PAN Number',
                          icon: Icons.assignment_ind,
                          focusNode: panFocus,
                          nextFocusNode: companyCommissionFocus,
                          fieldKey: 'PAN',
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9]')),
                            LengthLimitingTextInputFormatter(10)
                          ],
                          customValidator: (value) {
                            if (value == null || value.isEmpty) return null;
                            final panRegex =
                            RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
                            if (!panRegex.hasMatch(value.toUpperCase())) {
                              return 'Invalid PAN format (e.g., ABCDE1234F)';
                            }
                            return null;
                          }),
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
                              fieldKey: 'Aadhar',
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(12)
                              ],
                              customValidator: (value) {
                                if (value == null || value.isEmpty)
                                  return null;
                                if (value.length != 12)
                                  return 'Aadhar must be exactly 12 digits';
                                return null;
                              })),
                      const SizedBox(width: 12),
                      Expanded(
                          child: buildTextField(
                              controller: panNumberController,
                              label: 'PAN Number',
                              icon: Icons.assignment_ind,
                              focusNode: panFocus,
                              nextFocusNode: companyCommissionFocus,
                              fieldKey: 'PAN',
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[A-Za-z0-9]')),
                                LengthLimitingTextInputFormatter(10)
                              ],
                              customValidator: (value) {
                                if (value == null || value.isEmpty)
                                  return null;
                                final panRegex =
                                RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
                                if (!panRegex.hasMatch(value.toUpperCase())) {
                                  return 'Invalid PAN format (e.g., ABCDE1234F)';
                                }
                                return null;
                              })),
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
                          fieldKey: 'Company Commission',
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
                          fieldKey: 'Profit Share',
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
                          fieldKey: 'Selling Commission',
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
                              fieldKey: 'Company Commission',
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
                              fieldKey: 'Profit Share',
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
                              fieldKey: 'Selling Commission',
                              showSuffixIcon: true,
                              suffixText: '%')),
                    ]),
                  const SizedBox(height: 16),

                  buildTextField(
                      controller: additionalPointsController,
                      label: 'Additional Terms and Conditions',
                      icon: Icons.note_add,
                      maxLines: 2,
                      focusNode: additionalPointsFocus,
                      nextFocusNode: repNameFocus,
                      fieldKey: 'Additional Terms'),
                  const SizedBox(height: 16),

                  buildTextField(
                      controller: repNameController,
                      label: 'QNX Mart Representative',
                      icon: Icons.person_outline,
                      focusNode: repNameFocus,
                      fieldKey: 'Representative',
                      textInputAction: TextInputAction.done),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFFF8FAFC),
                        Color(0xFFF1F5F9)
                      ]),
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
                      _buildDigitalSignaturesGrid(),
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
// COMPANY AGREEMENT DETAIL VIEW
// ============================================================
class _AgreementDetailView extends StatelessWidget {
  final AgreementData data;
  final Color typeColor;
  final String typeLabel;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onUpdateSuccess;

  const _AgreementDetailView({
    required this.data,
    required this.typeColor,
    required this.typeLabel,
    required this.onApprove,
    required this.onReject,
    required this.onUpdateSuccess,
  });

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  String _formatText(dynamic value) {
    if (value == null || value.toString().isEmpty) return '-';
    return value.toString();
  }

  Future<void> _exportPDF(BuildContext context) async {
    final pdf = pw.Document();

    Future<pw.MemoryImage?> _loadImage(String? url) async {
      if (url == null || url.isEmpty) return null;
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          return pw.MemoryImage(response.bodyBytes);
        }
        return null;
      } catch (e) {
        return null;
      }
    }

    final qnxSignImage = await _loadImage(data.qnxMartSignUrl);
    final companySignImage = await _loadImage(data.companySignUrl);
    final qnxPhotoImage = await _loadImage(data.qnxMartPictureUrl);
    final companyPhotoImage = await _loadImage(data.companyPictureUrl);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context ctx) => [
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              border: pw.Border.all(color: PdfColors.blue300, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('AGREEMENT DETAIL',
                    style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800)),
                pw.SizedBox(height: 4),
                pw.Text(typeLabel,
                    style: pw.TextStyle(
                        fontSize: 14, color: PdfColors.grey600)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          _buildSectionTitle('Basic Information'),
          pw.SizedBox(height: 8),
          _buildInfoTable([
            ['Agreement Number', data.agreementNumber],
            ['Company Owner', data.companyOwnerName],
            ['Start Date', _formatDate(data.startDate)],
            ['End Date', _formatDate(data.endDate)],
            ['Profit Share %', data.profitSharePercentage],
            ['Status', data.status.toUpperCase()],
          ]),
          pw.SizedBox(height: 16),
          _buildSectionTitle('Owner Details'),
          pw.SizedBox(height: 8),
          _buildInfoTable([
            ['Owner Name', data.companyOwnerName],
            ['Owner Aadhar', _formatText(data.ownerAdharNumber)],
            ['Owner PAN', _formatText(data.ownerPanNumber)],
          ]),
          pw.SizedBox(height: 16),
          _buildSectionTitle('Representative Details'),
          pw.SizedBox(height: 8),
          _buildInfoTable([
            ['Representative', data.qnxMartRepresentative],
            ['Rep. Aadhar', _formatText(data.sellerAdharNumber)],
            ['Rep. PAN', _formatText(data.sellerPanNumber)],
          ]),
          pw.SizedBox(height: 16),
          _buildSectionTitle('Location & Terms'),
          pw.SizedBox(height: 8),
          _buildInfoTable([
            ['Address', data.companyAddress],
            ['Additional Points', data.additionalPoints],
            ['Created At', _formatDate(data.createdAt)],
          ]),
          if (data.agreementProducts != null &&
              data.agreementProducts!.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildSectionTitle('Agreement Products'),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Table(
                border:
                pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.blue50),
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Product ID',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Product Name',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Profit %',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10))),
                    ],
                  ),
                  ...data.agreementProducts!.map((product) {
                    return pw.TableRow(children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(product.product.toString(),
                              style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(product.productName ?? '-',
                              style: const pw.TextStyle(fontSize: 10))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('${product.profitPercentage}%',
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.blue700))),
                    ]);
                  }).toList(),
                ],
              ),
            ),
          ],
          if (qnxSignImage != null ||
              companySignImage != null ||
              qnxPhotoImage != null ||
              companyPhotoImage != null) ...[
            pw.SizedBox(height: 16),
            _buildSectionTitle('Signatures & Photos'),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Column(children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    if (qnxSignImage != null)
                      _buildImageBox('QNX Sign', qnxSignImage),
                    if (companySignImage != null)
                      _buildImageBox('Company Sign', companySignImage),
                  ],
                ),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    if (qnxPhotoImage != null)
                      _buildImageBox('QNX Photo', qnxPhotoImage),
                    if (companyPhotoImage != null)
                      _buildImageBox('Company Photo', companyPhotoImage),
                  ],
                ),
              ]),
            ),
          ],
          pw.SizedBox(height: 24),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(children: [
                    pw.Text('QNX MART Representative'),
                    pw.SizedBox(height: 8),
                    pw.Container(
                        width: 150, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('(Signature)',
                        style: pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey600)),
                  ]),
                  pw.Column(children: [
                    pw.Text('Company Representative'),
                    pw.SizedBox(height: 8),
                    pw.Container(
                        width: 150, height: 1, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text('(Signature)',
                        style: pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey600)),
                  ]),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(children: [
                    pw.Text('Date'),
                    pw.SizedBox(height: 8),
                    pw.Container(
                        width: 150, height: 1, color: PdfColors.black),
                  ]),
                  pw.Column(children: [
                    pw.Text('Place'),
                    pw.SizedBox(height: 8),
                    pw.Container(
                        width: 150, height: 1, color: PdfColors.black),
                  ]),
                ],
              ),
            ]),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  void _showUpdatePercentageDialog(BuildContext context) {
    final profitShareController =
    TextEditingController(text: data.profitSharePercentage);
    final sellingCommissionController =
    TextEditingController(text: data.sellingCommissionPercentage);
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Icon(Icons.percent_rounded, color: typeColor),
            const SizedBox(width: 10),
            const Text('Update Percentages',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.numbers, size: 18, color: Colors.grey),
                  const SizedBox(width: 10),
                  Text('Agreement #${data.id}',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(data.agreementNumber,
                        style: TextStyle(fontSize: 11, color: typeColor)),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: profitShareController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Profit Share Percentage',
                  prefixIcon:
                  Icon(Icons.percent, color: Colors.green.shade700),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  suffixText: '%',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  final val = double.tryParse(value);
                  if (val == null || val < 0 || val > 100)
                    return 'Enter 0-100';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: sellingCommissionController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Selling Commission %',
                  prefixIcon:
                  Icon(Icons.attach_money, color: Colors.orange.shade700),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  suffixText: '%',
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                if (!formKey.currentState!.validate()) return;
                setState(() => isLoading = true);
                try {
                  final profitShare = double.parse(
                      profitShareController.text.trim());
                  double? sellingCommission;
                  if (sellingCommissionController.text.trim().isNotEmpty) {
                    sellingCommission = double.parse(
                        sellingCommissionController.text.trim());
                  }
                  final response = await AgreementService
                      .updateAgreementPercentage(
                    agreementId: data.id,
                    profitSharePercentage: profitShare,
                    sellingCommissionPercentage: sellingCommission,
                  );
                  if (!context.mounted) return;
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(response.message),
                        backgroundColor: Colors.green),
                  );
                  onUpdateSuccess();
                } catch (e) {
                  if (!context.mounted) return;
                  setState(() => isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Failed: $e'),
                        backgroundColor: Colors.red),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
                  : const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(title,
          style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 14,
              color: PdfColors.blue800)),
    );
  }

  pw.Widget _buildInfoTable(List<List<String>> rows) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: rows.map((row) {
        return pw.TableRow(children: [
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(row[0],
                style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 11,
                    color: PdfColors.grey700)),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(row[1], style: pw.TextStyle(fontSize: 11)),
          ),
        ]);
      }).toList(),
    );
  }

  pw.Widget _buildImageBox(String label, pw.MemoryImage image) {
    return pw.Column(children: [
      pw.Container(
        width: 80,
        height: 80,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Image(image),
      ),
      pw.SizedBox(height: 4),
      pw.Text(label,
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
    ]);
  }

  void _openPdf(BuildContext context, String url) async {
    if (url.isEmpty) return;
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

  bool _hasPdf() => data.hasPdf;

  Widget _buildPdfView(BuildContext context, Color color) {
    final pdfUrl = data.pdfUrl;
    if (!data.hasPdf) return const SizedBox.shrink();
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
          onPressed: () => _openPdf(context, pdfUrl),
          icon: const Icon(Icons.open_in_new, size: 18),
          label: const Text('View'),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white),
        ),
      ]),
    );
  }

  bool _hasImages() =>
      data.qnxMartSignUrl.isNotEmpty ||
          data.companySignUrl.isNotEmpty ||
          data.qnxMartPictureUrl.isNotEmpty ||
          data.companyPictureUrl.isNotEmpty;

  Widget _sectionTitle(String title, Color color) {
    return Row(children: [
      Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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

  Widget _fullWidthInfo(IconData icon, String label, String value, Color color) {
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

  Widget _buildImageRow(BuildContext context, Color color) {
    final images = <Map<String, String>>[
      if (data.qnxMartSignUrl.isNotEmpty)
        {'url': data.qnxMartSignUrl, 'label': 'QNX Sign'},
      if (data.companySignUrl.isNotEmpty)
        {'url': data.companySignUrl, 'label': 'Company Sign'},
      if (data.qnxMartPictureUrl.isNotEmpty)
        {'url': data.qnxMartPictureUrl, 'label': 'QNX Photo'},
      if (data.companyPictureUrl.isNotEmpty)
        {'url': data.companyPictureUrl, 'label': 'Company Photo'},
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
                        (data.companyName != null &&
                            data.companyName!.isNotEmpty)
                            ? data.companyName!
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
                Row(children: [
                  if (data.status == 'pending')
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
                  if (data.status == 'pending') const SizedBox(width: 8),
                  if (data.status == 'pending')
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
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showUpdatePercentageDialog(context),
                    icon: const Icon(Icons.percent_rounded, size: 16),
                    label: const Text('Update %'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _exportPDF(context),
                    icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                    label: const Text('PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ]),
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
                            'Start Date', _formatDate(data.startDate), typeColor)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _infoCard(Icons.calendar_month_rounded,
                            'End Date', _formatDate(data.endDate), typeColor)),
                  ]),
                  const SizedBox(height: 24),
                  _sectionTitle('Owner Details', typeColor),
                  const SizedBox(height: 12),
                  _fullWidthInfo(Icons.person_rounded, 'company Owner Name',
                      data.companyOwnerName, typeColor),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _infoCard(Icons.credit_card_rounded,
                            'Company Owner Aadhar Card',
                            _formatText(data.ownerAdharNumber), typeColor)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _infoCard(Icons.assignment_ind_rounded,
                            'Company Owner PAN Card',
                            _formatText(data.ownerPanNumber), typeColor)),
                  ]),
                  const SizedBox(height: 24),
                  _sectionTitle('Representative Details', typeColor),
                  const SizedBox(height: 12),
                  _fullWidthInfo(Icons.person_outline_rounded,
                      'QNX Representative Name',
                      data.qnxMartRepresentative.isNotEmpty
                          ? data.qnxMartRepresentative
                          : '-', typeColor),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _infoCard(Icons.credit_card_rounded,
                            'QNX Representative Aadhar Card',
                            _formatText(data.sellerAdharNumber), typeColor)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _infoCard(Icons.assignment_ind_rounded,
                            'QNX Representative PAN Card',
                            _formatText(data.sellerPanNumber), typeColor)),
                  ]),
                  const SizedBox(height: 24),
                  _sectionTitle('Financial', typeColor),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _infoCard(Icons.percent_rounded,
                            'Profit Share %', data.profitSharePercentage, typeColor)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _infoCard(Icons.trending_up_rounded,
                            'Global Profit',
                            data.globalProfit != null
                                ? data.globalProfit.toString()
                                : '-', typeColor)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _infoCard(Icons.attach_money_rounded,
                            'Selling Commission %',
                            data.sellingCommissionPercentage.isEmpty
                                ? '-'
                                : data.sellingCommissionPercentage,
                            typeColor)),
                  ]),
                  const SizedBox(height: 24),
                  if (data.agreementProducts != null &&
                      data.agreementProducts!.isNotEmpty) ...[
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
                        ...data.agreementProducts!.map((product) {
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
                                  Text(product.productName ??
                                      'Product #${product.product}',
                                      style: const TextStyle(fontSize: 13)),
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
                                  child: Text('${product.profitPercentage}%',
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
                          : '-', typeColor),
                  const SizedBox(height: 24),
                  _sectionTitle('Additional Terms & Conditions', typeColor),
                  const SizedBox(height: 12),
                  _fullWidthInfo(
                      Icons.note_add_rounded,
                      'Additional Points',
                      data.additionalPoints.isNotEmpty
                          ? data.additionalPoints
                          : '-', typeColor),
                  if (_hasPdf()) ...[
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
}

// ============================================================
// COMPANY AGREEMENT FORM
// ============================================================
class _AgreementFormContent extends StatefulWidget {
  final VoidCallback onClose;
  final AgreementType agreementType;
  const _AgreementFormContent({
    required this.onClose,
    required this.agreementType,
  });
  @override
  State<_AgreementFormContent> createState() => _AgreementFormContentState();
}

class _AgreementFormContentState extends State<_AgreementFormContent> {
  List<MarketingHead> _marketingHeads = [];
  List<MarketingPartner> _marketingPartners = [];
  bool _loadingHeads = false;
  bool _loadingPartners = false;
  int? _selectedMarketingHeadId;
  int? _selectedMarketingPartnerId;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isFetchingCompanies = true;
  bool _isFetchingProducts = false;
  bool _applyOnAllProducts = false;
  bool _isDisposed = false;
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _fieldKeys = {};
  final Map<String, FocusNode> _fieldFocusNodes = {};
  late FocusNode agreementNoFocus;
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
  late FocusNode globalProfitFocus;
  final agreementNoController = TextEditingController();
  final startDateController = TextEditingController();
  final endDateController = TextEditingController();
  final globalProfitController = TextEditingController();
  final repNameController = TextEditingController();
  final repAdharController = TextEditingController();
  final repPanController = TextEditingController();
  final ownerNameController = TextEditingController();
  final ownerAdharController = TextEditingController();
  final ownerPanController = TextEditingController();
  final addressController = TextEditingController();
  final additionalTermsController = TextEditingController();
  final TextEditingController _sellingCommissionController =
  TextEditingController();
  List<AgreementCompanyModel> companies = [];
  String? selectedCompanyId;
  String? selectedCompanyName;
  String? autoOwnerName;
  List<AgreementProductModel> products = [];
  Map<int, bool> selectedProducts = {};
  Map<int, TextEditingController> productProfitControllers = {};
  final TextEditingController globalProductProfitController =
  TextEditingController();
  final TextEditingController _rejectReasonController = TextEditingController();
  List<Uint8List> repSigns = [];
  List<Uint8List> ownerSigns = [];
  List<Uint8List> repPhotos = [];
  List<Uint8List> ownerPhotos = [];
  final int maxImagesPerCategory = 1;
  Uint8List? _uploadedPdfBytes;
  String? _uploadedPdfFileName;

  @override
  void initState() {
    super.initState();
    _isDisposed = false;
    _generateAgreementNumber();
    _fetchCompanies();
    _fetchMarketingHeads();
    _fetchMarketingPartners();
    agreementNoFocus = FocusNode();
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
    globalProfitFocus = FocusNode();
    // ✅ NEW: Field keys register
    _registerField('Agreement Number');
    _registerField('Company Name');
    _registerField('Start Date');
    _registerField('End Date');
    _registerField('Owner Name');
    _registerField('Owner Aadhar');
    _registerField('Owner PAN');
    _registerField('Representative Name');
    _registerField('Representative Aadhar');
    _registerField('Representative PAN');
    _registerField('Address');
    _registerField('Additional Terms');
    _registerField('Global Profit');
    _registerField('Selling Commission');
  }

  void _generateAgreementNumber() {
    final now = DateTime.now();
    final formatted = DateFormat('yyyyMMdd').format(now);
    final random =
    (now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0');
    agreementNoController.text = "AG-$formatted-$random";
  }

  // ============================================================
  // ✅ NEW: Field validation + scroll helpers
  // ============================================================
  void _registerField(String fieldName) {
    _fieldKeys[fieldName] = GlobalKey();
    _fieldFocusNodes[fieldName] = FocusNode();
  }

  String? _getFieldValue(String fieldName) {
    switch (fieldName) {
      case 'Agreement Number':
        return agreementNoController.text;
      case 'Company Name':
        return selectedCompanyName;
      case 'Start Date':
        return startDateController.text;
      case 'End Date':
        return endDateController.text;
      case 'Owner Name':
        return ownerNameController.text;
      case 'Owner Aadhar':
        return ownerAdharController.text;
      case 'Owner PAN':
        return ownerPanController.text;
      case 'Representative Name':
        return repNameController.text;
      case 'Representative Aadhar':
        return repAdharController.text;
      case 'Representative PAN':
        return repPanController.text;
      case 'Address':
        return addressController.text;
      case 'Additional Terms':
        return additionalTermsController.text;
      case 'Global Profit':
        return globalProfitController.text;
      case 'Selling Commission':
        return _sellingCommissionController.text;
      default:
        return null;
    }
  }

  bool _isFieldRequired(String fieldName) {
    if (fieldName == 'Additional Terms') return false;
    if (fieldName == 'Agreement Number') return false;
    return true;
  }

  Future<void> _validateAndScroll() async {
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (formState.validate()) return;

    final fieldOrder = [
      'Agreement Number',
      'Company Name',
      'Start Date',
      'End Date',
      'Owner Name',
      'Owner Aadhar',
      'Owner PAN',
      'Representative Name',
      'Representative Aadhar',
      'Representative PAN',
      'Address',
      'Additional Terms',
      'Global Profit',
      'Selling Commission',
    ];

    String? firstInvalid;
    for (final f in fieldOrder) {
      if (!_isFieldRequired(f)) continue;
      final v = _getFieldValue(f);
      if (v == null || v.trim().isEmpty) {
        firstInvalid = f;
        break;
      }
    }

    if (mounted && !_isDisposed) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                firstInvalid != null
                    ? 'Please fill "$firstInvalid" field'
                    : 'Please fill all required fields',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }

    if (firstInvalid != null) {
      final key = _fieldKeys[firstInvalid];
      final fn = _fieldFocusNodes[firstInvalid];

      if (key != null && key.currentContext != null) {
        await Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.3,
        );
      }
      if (fn != null && !fn.hasFocus) {
        await Future.delayed(const Duration(milliseconds: 300));
        fn.requestFocus();
      }
    }
  }

  Future<void> _fetchMarketingHeads() async {
    _safeSetState(() => _loadingHeads = true);
    try {
      final response = await MarketingHeadService().getMarketingHeads();
      _safeSetState(() {
        _marketingHeads = response.data;
        _loadingHeads = false;
      });
    } catch (e) {
      _safeSetState(() => _loadingHeads = false);
    }
  }

  Future<void> _pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        if (bytes != null) {
          setState(() {
            _uploadedPdfBytes = bytes;
            _uploadedPdfFileName = file.name;
          });
        }
      }
    } catch (e) {
      _showError('Failed to pick PDF: $e');
    }
  }

  void _removePdf() {
    setState(() {
      _uploadedPdfBytes = null;
      _uploadedPdfFileName = null;
    });
  }

  String? _validatePAN(String? value) {
    if (value == null || value.isEmpty) return null;
    final panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$');
    if (!panRegex.hasMatch(value.toUpperCase())) {
      return 'Invalid PAN format (e.g., ABCDE1234F)';
    }
    return null;
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
      _applyOnAllProducts = false;
    });
    try {
      final response = await AgreementProductService()
          .getProductsByCompany(selectedCompanyId!);
      _safeSetState(() {
        products = response.data;
        for (int i = 0; i < products.length; i++) {
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
        autoOwnerName = null;
        ownerNameController.clear();
        addressController.clear();
        products = [];
        selectedProducts.clear();
        productProfitControllers.clear();
        _applyOnAllProducts = false;
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
        autoOwnerName = selected.ownerName;
        ownerNameController.text = selected.ownerName;
        _applyOnAllProducts = false;
      });
      _fetchProducts();
    } else {
      setState(() {
        selectedCompanyId = null;
        selectedCompanyName = null;
        autoOwnerName = null;
        ownerNameController.clear();
        addressController.clear();
        products = [];
        selectedProducts.clear();
        productProfitControllers.clear();
        _applyOnAllProducts = false;
      });
    }
  }

  void toggleSelectAll(bool? value) {
    setState(() {
      for (int i = 0; i < products.length; i++) {
        selectedProducts[i] = value ?? false;
      }
    });
  }

  void applyGlobalProductProfit() {
    final double? globalProfit =
    double.tryParse(globalProductProfitController.text);
    if (globalProfit != null) {
      setState(() {
        for (int i = 0; i < products.length; i++) {
          if (selectedProducts[i] == true) {
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
      'Global': const Color(0xFF9B59B6),
      'Profit': const Color(0xFFE91E63),
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
    String? fieldKey,
  }) {
    final iconColor = _getIconColor(label);
    final Widget field = TextFormField(
      inputFormatters: inputFormatters,
      validator: customValidator ??
          (required ? (v) => v!.isEmpty ? 'Required' : null : null),
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

    if (fieldKey != null && _fieldKeys.containsKey(fieldKey)) {
      return Container(key: _fieldKeys[fieldKey], child: field);
    }
    return field;
  }

  Widget _buildPdfUploadSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [
          Color(0xFFF8FAFC),
          Color(0xFFF1F5F9)
        ]),
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
                Icon(Icons.picture_as_pdf, color: Colors.red.shade600, size: 32),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(_uploadedPdfFileName!,
                        overflow: TextOverflow.ellipsis)),
                IconButton(
                    onPressed: _removePdf,
                    icon: const Icon(Icons.close, color: Colors.red)),
              ]),
            )
          else
            InkWell(
              onTap: _pickPdfFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey.shade50,
                ),
                child: Column(children: [
                  Icon(Icons.upload_file, size: 48, color: Colors.grey.shade400),
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

  Widget buildDropdownField({
    required String label,
    required IconData icon,
    required List<String> items,
    String? value,
    required void Function(String?) onChanged,
    bool isSearchable = false,
    bool required = true,
  }) {
    final iconColor = _getIconColor(label);
    if (isSearchable) {
      return Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) return items;
          return items.where((item) =>
              item.toLowerCase().contains(textEditingValue.text.toLowerCase()));
        },
        onSelected: onChanged,
        fieldViewBuilder:
            (context, textEditingController, focusNode, onFieldSubmitted) {
          return TextFormField(
            controller: textEditingController,
            focusNode: focusNode,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Container(
                  padding: const EdgeInsets.all(10),
                  child: Icon(icon, color: iconColor, size: 20)),
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
              fillColor: Colors.grey[50],
              suffixIcon: Icon(Icons.arrow_drop_down, color: iconColor),
            ),
            validator: required ? (v) => v!.isEmpty ? 'Required' : null : null,
          );
        },
      );
    } else {
      return DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: iconColor, size: 20)),
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
          fillColor: Colors.grey[50],
        ),
        items: items
            .map((String item) =>
            DropdownMenuItem<String>(value: item, child: Text(item)))
            .toList(),
        onChanged: onChanged,
        validator: required ? (v) => v == null ? 'Required' : null : null,
      );
    }
  }

  Widget _buildForeignPartyDropdown() {
    if (_isFetchingCompanies) {
      return const Center(child: CircularProgressIndicator());
    }
    return Container(
      key: _fieldKeys['Company Name'],
      child: buildDropdownField(
        label: 'Company Name',
        icon: Icons.business,
        items: companies.map((c) => c.name).toList(),
        value: selectedCompanyName,
        onChanged: onCompanyChanged,
        isSearchable: true,
      ),
    );
  }

  Widget _buildDigitalSignaturesGrid() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final List<Map<String, dynamic>> categories = [
      {
        'title': 'Representative Sign',
        'images': repSigns,
        'onChanged': (List<Uint8List> v) => setState(() => repSigns = v)
      },
      {
        'title': 'Owner Sign',
        'images': ownerSigns,
        'onChanged': (List<Uint8List> v) => setState(() => ownerSigns = v)
      },
      {
        'title': 'Representative Photo',
        'images': repPhotos,
        'onChanged': (List<Uint8List> v) => setState(() => repPhotos = v)
      },
      {
        'title': 'Owner Photo',
        'images': ownerPhotos,
        'onChanged': (List<Uint8List> v) => setState(() => ownerPhotos = v)
      },
    ];
    if (isMobile) {
      return Column(
        children: categories
            .map((cat) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildImagePickerCard(cat)))
            .toList(),
      );
    } else {
      return Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _buildImagePickerCard(categories[0])),
          const SizedBox(width: 12),
          Expanded(child: _buildImagePickerCard(categories[1])),
        ]),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _buildImagePickerCard(categories[2])),
          const SizedBox(width: 12),
          Expanded(child: _buildImagePickerCard(categories[3])),
        ]),
      ]);
    }
  }

  Widget _buildImagePickerCard(Map<String, dynamic> category) {
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

  Future<void> _submitAgreement() async {
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (!formState.validate()) {
      await _validateAndScroll();
      return;
    }

    if (widget.agreementType == AgreementType.company &&
        selectedCompanyId == null) {
      _showError('Please select a company');
      return;
    }

    _safeSetState(() => _isLoading = true);

    List<Map<String, dynamic>> productList = [];
    if (widget.agreementType == AgreementType.company) {
      for (int i = 0; i < products.length; i++) {
        if (selectedProducts[i] == true) {
          final profitStr = productProfitControllers[i]?.text ?? '';
          final profit = double.tryParse(profitStr);
          if (profit != null) {
            productList.add({
              'product': products[i].id,
              'profit_percentage': profit,
            });
          } else {
            _showError('Please enter profit % for: ${products[i].name}');
            _safeSetState(() => _isLoading = false);
            return;
          }
        }
      }
      if (productList.isEmpty && products.isNotEmpty) {
        _showError('Please select at least one product');
        _safeSetState(() => _isLoading = false);
        return;
      }
    }

    final model = AgreementModel(
      agreementNumber: agreementNoController.text,
      agreementRole: widget.agreementType.roleString,
      applyOnAllProducts: false,
      agreementStartDate: startDateController.text,
      agreementEndDate: endDateController.text,
      companyOwnerName: ownerNameController.text,
      companyAddress: addressController.text,
      globalProfit: double.tryParse(globalProfitController.text) ?? 0,
      sellerAdharNumber: repAdharController.text.isNotEmpty
          ? repAdharController.text
          : null,
      ownerAdharNumber: ownerAdharController.text.isNotEmpty
          ? ownerAdharController.text
          : null,
      sellerPanNumber:
      repPanController.text.isNotEmpty ? repPanController.text : null,
      ownerPanNumber:
      ownerPanController.text.isNotEmpty ? ownerPanController.text : null,
      sellingCommissionPercentage: _sellingCommissionController.text,
      profitSharePercentage: globalProfitController.text,
      additionalPoints: additionalTermsController.text,
      qnxMartRepresentative: repNameController.text,
      remarks: null,
      companyId: widget.agreementType == AgreementType.company
          ? int.tryParse(selectedCompanyId!)
          : null,
      marketingPartnerId: null,
      agreementProducts: productList,
      qnxMartSign: repSigns.isNotEmpty ? repSigns.first : null,
      companySign: ownerSigns.isNotEmpty ? ownerSigns.first : null,
      qnxMartPicture: repPhotos.isNotEmpty ? repPhotos.first : null,
      companyPicture: ownerPhotos.isNotEmpty ? ownerPhotos.first : null,
      uploadedAgreementPdf: _uploadedPdfBytes,
    );

    try {
      final response = await AgreementService.createAgreement(model);
      _safeSetState(() => _isLoading = false);

      if (response != null && response.status == 'success') {
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;
    int crossAxisCount = isMobile ? 2 : (isTablet ? 3 : 5);
    double childAspectRatio = isMobile ? 1.2 : (isTablet ? 1.1 : 1.0);

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
              Expanded(
                child: Text('Create ${widget.agreementType.label} Agreement',
                    style: const TextStyle(
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
                  buildTextField(
                    controller: agreementNoController,
                    label: 'Agreement Number',
                    icon: Icons.numbers,
                    required: false,
                    readOnly: true,
                    focusNode: agreementNoFocus,
                    fieldKey: 'Agreement Number',
                  ),
                  const SizedBox(height: 16),
                  _buildPdfUploadSection(),
                  _buildForeignPartyDropdown(),
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
                          fieldKey: 'Start Date',
                          nextFocusNode: endDateFocus),
                      const SizedBox(height: 12),
                      buildTextField(
                          controller: endDateController,
                          label: 'End Date',
                          icon: Icons.calendar_month,
                          readOnly: true,
                          onTap: () => _selectEndDate(context),
                          focusNode: endDateFocus,
                          fieldKey: 'End Date',
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
                              fieldKey: 'Start Date',
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
                              fieldKey: 'End Date',
                              nextFocusNode: ownerNameFocus)),
                    ]),
                  const SizedBox(height: 16),
                  buildTextField(
                      controller: ownerNameController,
                      label: 'Company Owner Name',
                      icon: Icons.person,
                      required: true,
                      readOnly: widget.agreementType != AgreementType.company,
                      focusNode: ownerNameFocus,
                      fieldKey: 'Owner Name',
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
                          fieldKey: 'Owner Aadhar',
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(12)
                          ],
                          customValidator: (value) {
                            if (value == null || value.isEmpty) return null;
                            if (value.length != 12)
                              return 'Aadhar must be exactly 12 digits';
                            return null;
                          }),
                      const SizedBox(height: 12),
                      buildTextField(
                          controller: ownerPanController,
                          label: 'Owner PAN Number',
                          icon: Icons.assignment_ind,
                          focusNode: ownerPanFocus,
                          nextFocusNode: repNameFocus,
                          fieldKey: 'Owner PAN',
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9]')),
                            LengthLimitingTextInputFormatter(10)
                          ],
                          customValidator: _validatePAN),
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
                              fieldKey: 'Owner Aadhar',
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(12)
                              ],
                              customValidator: (value) {
                                if (value == null || value.isEmpty)
                                  return null;
                                if (value.length != 12)
                                  return 'Aadhar must be exactly 12 digits';
                                return null;
                              })),
                      const SizedBox(width: 12),
                      Expanded(
                          child: buildTextField(
                              controller: ownerPanController,
                              label: 'Owner PAN Number',
                              icon: Icons.assignment_ind,
                              focusNode: ownerPanFocus,
                              nextFocusNode: repNameFocus,
                              fieldKey: 'Owner PAN',
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[A-Za-z0-9]')),
                                LengthLimitingTextInputFormatter(10)
                              ],
                              customValidator: _validatePAN)),
                    ]),
                  const SizedBox(height: 16),
                  buildTextField(
                      controller: repNameController,
                      label: 'QNX Representative Name',
                      icon: Icons.person_outline,
                      focusNode: repNameFocus,
                      fieldKey: 'Representative Name',
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
                          fieldKey: 'Representative Aadhar',
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(12)
                          ],
                          customValidator: (value) {
                            if (value == null || value.isEmpty) return null;
                            if (value.length != 12)
                              return 'Aadhar must be exactly 12 digits';
                            return null;
                          }),
                      const SizedBox(height: 12),
                      buildTextField(
                          controller: repPanController,
                          label: 'Representative PAN Number',
                          icon: Icons.assignment_ind,
                          focusNode: repPanFocus,
                          nextFocusNode: addressFocus,
                          fieldKey: 'Representative PAN',
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[A-Za-z0-9]')),
                            LengthLimitingTextInputFormatter(10)
                          ],
                          customValidator: _validatePAN),
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
                              fieldKey: 'Representative Aadhar',
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(12)
                              ],
                              customValidator: (value) {
                                if (value == null || value.isEmpty)
                                  return null;
                                if (value.length != 12)
                                  return 'Aadhar must be exactly 12 digits';
                                return null;
                              })),
                      const SizedBox(width: 12),
                      Expanded(
                          child: buildTextField(
                              controller: repPanController,
                              label: 'Representative PAN Number',
                              icon: Icons.assignment_ind,
                              focusNode: repPanFocus,
                              nextFocusNode: addressFocus,
                              fieldKey: 'Representative PAN',
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[A-Za-z0-9]')),
                                LengthLimitingTextInputFormatter(10)
                              ],
                              customValidator: _validatePAN)),
                    ]),
                  const SizedBox(height: 16),
                  buildTextField(
                      controller: addressController,
                      label: 'Address',
                      icon: Icons.location_on,
                      maxLines: 2,
                      focusNode: addressFocus,
                      fieldKey: 'Address',
                      nextFocusNode: additionalTermsFocus),
                  const SizedBox(height: 16),
                  buildTextField(
                      controller: additionalTermsController,
                      label: 'Additional Terms and Conditions',
                      icon: Icons.note_add,
                      maxLines: 2,
                      focusNode: additionalTermsFocus,
                      fieldKey: 'Additional Terms',
                      nextFocusNode: globalProfitFocus),
                  const SizedBox(height: 16),
                  buildTextField(
                      controller: globalProfitController,
                      label: 'Global Profit Shared %',
                      icon: Icons.percent,
                      keyboardType: TextInputType.number,
                      focusNode: globalProfitFocus,
                      fieldKey: 'Global Profit',
                      textInputAction: TextInputAction.done,
                      showSuffixIcon: true,
                      suffixText: '%'),
                  const SizedBox(height: 24),
                  buildTextField(
                    controller: _sellingCommissionController,
                    label: 'Selling Commission %',
                    icon: Icons.attach_money_rounded,
                    keyboardType: TextInputType.number,
                    showSuffixIcon: true,
                    suffixText: '%',
                    fieldKey: 'Selling Commission',
                    customValidator: (value) {
                      if (value == null || value.isEmpty) return 'Required';
                      final val = double.tryParse(value);
                      if (val == null || val < 0 || val > 100)
                        return 'Enter 0-100';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFFF8FAFC),
                        Color(0xFFF1F5F9)
                      ]),
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
                      _buildDigitalSignaturesGrid(),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  if (widget.agreementType == AgreementType.company &&
                      selectedCompanyId != null) ...[
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
                    else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [
                              Color(0xFFF8FAFC),
                              Color(0xFFF1F5F9)
                            ]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(children: [
                            const SizedBox(height: 12),
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
                                          Checkbox(
                                              value: selectedProducts.isNotEmpty &&
                                                  selectedProducts.values
                                                      .every((v) => v == true),
                                              onChanged: toggleSelectAll,
                                              activeColor: Colors.deepPurple),
                                          const Text('Select All',
                                              style: TextStyle(fontSize: 11)),
                                        ]),
                                    SizedBox(
                                      width: 90,
                                      child: TextFormField(
                                        controller:
                                        globalProductProfitController,
                                        decoration: const InputDecoration(
                                          hintText: 'Profit %',
                                          border: OutlineInputBorder(),
                                          contentPadding:
                                          EdgeInsets.symmetric(
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
                                final product = products[index];
                                final isSelected =
                                    selectedProducts[index] ?? false;
                                final profitCtrl =
                                    productProfitControllers[index] ??
                                        TextEditingController();
                                return Card(
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                          BorderRadius.circular(8),
                                          child: product.thumbnailS3Key.isNotEmpty
                                              ? Image.network(
                                            product.thumbnailS3Key,
                                            height: 80,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                Container(
                                                    height: 80,
                                                    width: double.infinity,
                                                    color:
                                                    Colors.grey[200],
                                                    child: const Icon(
                                                        Icons.broken_image,
                                                        size: 30,
                                                        color:
                                                        Colors.grey)),
                                          )
                                              : Container(
                                              height: 80,
                                              width: double.infinity,
                                              color: Colors.grey[200],
                                              child: const Icon(
                                                  Icons.image_not_supported,
                                                  size: 30,
                                                  color: Colors.grey)),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(product.name,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10)),
                                        Row(children: [
                                          Text('₹${product.price}',
                                              style: const TextStyle(
                                                  fontSize: 9,
                                                  color: Colors.green)),
                                          const SizedBox(width: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: product.status == 'approved'
                                                  ? Colors.green.shade100
                                                  : (product.status == 'pending'
                                                  ? Colors.orange.shade100
                                                  : Colors.red.shade100),
                                              borderRadius:
                                              BorderRadius.circular(4),
                                            ),
                                            child: Text(product.status,
                                                style: TextStyle(
                                                    fontSize: 7,
                                                    color: product.status ==
                                                        'approved'
                                                        ? Colors.green.shade800
                                                        : (product.status ==
                                                        'pending'
                                                        ? Colors
                                                        .orange.shade800
                                                        : Colors
                                                        .red.shade800),
                                                    fontWeight:
                                                    FontWeight.w600)),
                                          ),
                                        ]),
                                        const SizedBox(height: 4),
                                        Row(children: [
                                          Checkbox(
                                            value: isSelected,
                                            onChanged: (val) {
                                              setState(() {
                                                selectedProducts[index] =
                                                    val ?? false;
                                              });
                                            },
                                            activeColor: Colors.deepPurple,
                                            visualDensity: const VisualDensity(
                                                horizontal: -4, vertical: -4),
                                            materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          Expanded(
                                            child: TextFormField(
                                              controller: profitCtrl,
                                              decoration: const InputDecoration(
                                                hintText: 'Profit %',
                                                border: OutlineInputBorder(),
                                                contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 4),
                                                isDense: true,
                                              ),
                                              keyboardType:
                                              TextInputType.number,
                                              style:
                                              const TextStyle(fontSize: 10),
                                            ),
                                          ),
                                        ]),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ]),
                        ),
                      ],
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitAgreement,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 3,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                          color: Colors.white)
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
    agreementNoController.dispose();
    startDateController.dispose();
    endDateController.dispose();
    globalProfitController.dispose();
    _sellingCommissionController.dispose();
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
    for (var fn in _fieldFocusNodes.values) {
      fn.dispose();
    }
    for (var ctrl in productProfitControllers.values) {
      ctrl.dispose();
    }
    agreementNoFocus.dispose();
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
    globalProfitFocus.dispose();
    _uploadedPdfBytes = null;
    super.dispose();
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