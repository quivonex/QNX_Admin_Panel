// lib/screens/qnx_admin/olx_communication_settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/olx/olx_communication_settings_model.dart';
import '../../api/olx_service.dart';

// ==================== PALETTE ====================
const Color _kBrand = Color(0xFF6366F1);
const Color _kInk = Color(0xFF1E293B);
const Color _kBody = Color(0xFF475569);
const Color _kMuted = Color(0xFF64748B);
const Color _kFaint = Color(0xFF94A3B8);
const Color _kBorder = Color(0xFFE2E8F0);
const Color _kCanvas = Color(0xFFF8FAFC);
const Color _kSuccess = Color(0xFF10B981);
const Color _kDanger = Color(0xFFEF4444);
const Color _kWarning = Color(0xFFF59E0B);
const Color _kPurple = Color(0xFF8B5CF6);

class OlxCommunicationSettingsScreen extends StatefulWidget {
  const OlxCommunicationSettingsScreen({super.key});

  @override
  State<OlxCommunicationSettingsScreen> createState() =>
      _OlxCommunicationSettingsScreenState();
}

class _OlxCommunicationSettingsScreenState
    extends State<OlxCommunicationSettingsScreen> {
  final OlxCommunicationSettingsService _service =
  OlxCommunicationSettingsService();

  // Form controllers
  final TextEditingController _freeChatLimitController = TextEditingController();
  final TextEditingController _freeEnquiryLimitController = TextEditingController();

  // Form state
  String _chatMode = 'free';
  String _enquiryMode = 'free';
  String _freeChatPeriod = 'daily';
  String _freeEnquiryPeriod = 'daily';
  bool _blockContactInfo = false;
  bool _blockPhoneNumbers = false;
  bool _blockEmails = false;
  bool _blockSocialHandles = false;
  bool _blockExternalLinks = false;
  bool _isActive = true;

  // UI state
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _loadError;
  OlxCommunicationSettingsData? _settings;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _freeChatLimitController.dispose();
    _freeEnquiryLimitController.dispose();
    _service.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final response = await _service.getSettings();

      // ✅ Debug prints
      print('🔍 Response status: ${response.status}');
      print('🔍 Response message: ${response.message}');
      print('🔍 Response data: ${response.data?.toJson()}');

      if (mounted) {
        if (response.status && response.data != null) {
          final data = response.data!;
          setState(() {
            _settings = data;
            _chatMode = data.chatMode;
            _enquiryMode = data.enquiryMode;
            _freeChatLimitController.text = data.freeChatLimit.toString();
            _freeChatPeriod = data.freeChatPeriod;
            _freeEnquiryLimitController.text =
                data.freeEnquiryLimit.toString();
            _freeEnquiryPeriod = data.freeEnquiryPeriod;
            _blockContactInfo = data.blockContactInfo;
            _blockPhoneNumbers = data.blockPhoneNumbers;
            _blockEmails = data.blockEmails;
            _blockSocialHandles = data.blockSocialHandles;
            _blockExternalLinks = data.blockExternalLinks;
            _isActive = data.isActive;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _loadError = response.message.isNotEmpty
                ? response.message
                : 'Failed to load settings';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = 'Error: $e';
        });
      }
    }
  }

  Future<void> _updateSettings() async {
    // Validation
    final chatLimit = int.tryParse(_freeChatLimitController.text.trim());
    final enquiryLimit =
    int.tryParse(_freeEnquiryLimitController.text.trim());

    if (chatLimit == null || chatLimit < 0) {
      _showSnackBar('Please enter a valid free chat limit', _kDanger);
      return;
    }
    if (enquiryLimit == null || enquiryLimit < 0) {
      _showSnackBar('Please enter a valid free enquiry limit', _kDanger);
      return;
    }

    setState(() => _isUpdating = true);

    try {
      final request = OlxCommunicationSettingsUpdateRequest(
        chatMode: _chatMode,
        enquiryMode: _enquiryMode,
        freeChatLimit: chatLimit,
        freeChatPeriod: _freeChatPeriod,
        freeEnquiryLimit: enquiryLimit,
        freeEnquiryPeriod: _freeEnquiryPeriod,
        blockContactInfo: _blockContactInfo,
        blockPhoneNumbers: _blockPhoneNumbers,
        blockEmails: _blockEmails,
        blockSocialHandles: _blockSocialHandles,
        blockExternalLinks: _blockExternalLinks,
        isActive: _isActive,
      );

      final response = await _service.updateSettings(request);

      if (mounted) {
        setState(() => _isUpdating = false);
        if (response.status) {
          _showSnackBar(
            response.message.isNotEmpty
                ? response.message
                : 'Settings updated successfully',
            _kSuccess,
          );
          if (response.data != null) {
            setState(() => _settings = response.data);
          }
        } else {
          _showSnackBar(response.message, _kDanger);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpdating = false);
        _showSnackBar('Error: $e', _kDanger);
      }
    }
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == _kSuccess ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kCanvas,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "OLX Communication Settings",
          style: TextStyle(
            color: _kInk,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadSettings,
            icon: const Icon(Icons.refresh, color: _kBrand),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _kBrand),
      );
    }

    if (_loadError != null && _settings == null) {
      return _buildErrorState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: isMobile
              ? Column(
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 20),
              _buildChatSettingsCard(),
              const SizedBox(height: 20),
              _buildEnquirySettingsCard(),
              const SizedBox(height: 20),
              _buildBlockingSettingsCard(),
              const SizedBox(height: 20),
              _buildStatusCard(),
              const SizedBox(height: 24),
              _buildUpdateButton(),
            ],
          )
              : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildChatSettingsCard()),
                  const SizedBox(width: 20),
                  Expanded(child: _buildEnquirySettingsCard()),
                ],
              ),
              const SizedBox(height: 24),
              _buildBlockingSettingsCard(),
              const SizedBox(height: 24),
              _buildStatusCard(),
              const SizedBox(height: 24),
              _buildUpdateButton(),
            ],
          ),
        );
      },
    );
  }

  // ==================== ERROR STATE ====================
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _kDanger.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_outlined,
                  size: 48, color: _kDanger),
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load settings',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _kInk,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _loadError ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _kMuted),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadSettings,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Try Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _kBrand,
                side: const BorderSide(color: _kBorder),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HEADER CARD ====================
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4158D0).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.forum, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Communication Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Configure chat & enquiry access modes, free limits and content blocking',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          if (_settings != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'ID #${_settings!.id}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==================== CHAT SETTINGS CARD ====================
  Widget _buildChatSettingsCard() {
    return _buildSectionCard(
      title: 'Chat Settings',
      subtitle: 'Configure how users can chat with each other',
      icon: Icons.chat_bubble_outline,
      iconColor: const Color(0xFF0EA5E9),
      children: [
        _buildDropdownField<String>(
          label: 'Chat Mode',
          value: _chatMode,
          items: OlxCommunicationConstants.chatModeOptions,
          icon: Icons.tune,
          onChanged: (v) => setState(() => _chatMode = v ?? 'free'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildNumberField(
                controller: _freeChatLimitController,
                label: 'Free Chat Limit',
                hint: 'e.g., 5',
                icon: Icons.numbers,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildDropdownField<String>(
                label: 'Free Chat Period',
                value: _freeChatPeriod,
                items: OlxCommunicationConstants.freePeriodOptions,
                icon: Icons.schedule,
                onChanged: (v) => setState(() => _freeChatPeriod = v ?? 'daily'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== ENQUIRY SETTINGS CARD ====================
  Widget _buildEnquirySettingsCard() {
    return _buildSectionCard(
      title: 'Enquiry Settings',
      subtitle: 'Configure how users can send enquiries',
      icon: Icons.question_answer_outlined,
      iconColor: const Color(0xFF8B5CF6),
      children: [
        _buildDropdownField<String>(
          label: 'Enquiry Mode',
          value: _enquiryMode,
          items: OlxCommunicationConstants.enquiryModeOptions,
          icon: Icons.tune,
          onChanged: (v) => setState(() => _enquiryMode = v ?? 'free'),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: _buildNumberField(
                controller: _freeEnquiryLimitController,
                label: 'Free Enquiry Limit',
                hint: 'e.g., 3',
                icon: Icons.numbers,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _buildDropdownField<String>(
                label: 'Free Enquiry Period',
                value: _freeEnquiryPeriod,
                items: OlxCommunicationConstants.freePeriodOptions,
                icon: Icons.schedule,
                onChanged: (v) =>
                    setState(() => _freeEnquiryPeriod = v ?? 'daily'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ==================== BLOCKING SETTINGS CARD ====================
  Widget _buildBlockingSettingsCard() {
    return _buildSectionCard(
      title: 'Content Blocking',
      subtitle: 'Prevent sharing of contact information in chats',
      icon: Icons.shield_outlined,
      iconColor: const Color(0xFFEF4444),
      children: [
        _buildSwitchTile(
          title: 'Block Contact Info',
          subtitle: 'Master toggle to block all contact information',
          value: _blockContactInfo,
          icon: Icons.contact_phone_outlined,
          onChanged: (v) => setState(() => _blockContactInfo = v),
        ),
        const SizedBox(height: 10),
        _buildSwitchTile(
          title: 'Block Phone Numbers',
          subtitle: 'Prevent users from sharing phone numbers',
          value: _blockPhoneNumbers,
          icon: Icons.phone_disabled_outlined,
          onChanged: (v) => setState(() => _blockPhoneNumbers = v),
        ),
        const SizedBox(height: 10),
        _buildSwitchTile(
          title: 'Block Emails',
          subtitle: 'Prevent users from sharing email addresses',
          value: _blockEmails,
          icon: Icons.email_outlined,
          onChanged: (v) => setState(() => _blockEmails = v),
        ),
        const SizedBox(height: 10),
        _buildSwitchTile(
          title: 'Block Social Handles',
          subtitle: 'Prevent sharing social media handles',
          value: _blockSocialHandles,
          icon: Icons.share_outlined,
          onChanged: (v) => setState(() => _blockSocialHandles = v),
        ),
        const SizedBox(height: 10),
        _buildSwitchTile(
          title: 'Block External Links',
          subtitle: 'Prevent sharing external URLs',
          value: _blockExternalLinks,
          icon: Icons.link_off,
          onChanged: (v) => setState(() => _blockExternalLinks = v),
        ),
      ],
    );
  }

  // ==================== STATUS CARD ====================
  Widget _buildStatusCard() {
    return _buildSectionCard(
      title: 'Status',
      subtitle: 'Enable or disable communication settings',
      icon: Icons.toggle_on_outlined,
      iconColor: _kSuccess,
      children: [
        _buildSwitchTile(
          title: 'Active Status',
          subtitle: _isActive
              ? 'Settings are currently active'
              : 'Settings are currently disabled',
          value: _isActive,
          icon: Icons.power_settings_new,
          onChanged: (v) => setState(() => _isActive = v),
        ),
      ],
    );
  }

  // ==================== SECTION CARD BUILDER ====================
  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _kInk,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: _kMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  // ==================== DROPDOWN FIELD ====================
  Widget _buildDropdownField<T>({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kInk,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: _kCanvas,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20, color: _kMuted),
              borderRadius: BorderRadius.circular(10),
              dropdownColor: Colors.white,
              style: const TextStyle(fontSize: 14, color: _kInk),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              items: items.map((e) {
                return DropdownMenuItem<String>(
                  value: e['value']!,
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: _kMuted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e['label']!,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== NUMBER FIELD ====================
  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kInk,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 14, color: _kInk),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: _kFaint, fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: _kMuted),
            filled: true,
            fillColor: _kCanvas,
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _kBrand, width: 1.6),
            ),
          ),
        ),
      ],
    );
  }

  // ==================== SWITCH TILE ====================
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: value ? _kBrand.withOpacity(0.05) : _kCanvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? _kBrand.withOpacity(0.4) : _kBorder,
          width: value ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value
                  ? _kBrand.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: value ? _kBrand : _kMuted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                    color: value ? _kInk : _kBody,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.5, color: _kMuted),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: _kBrand,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ==================== UPDATE BUTTON ====================
  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _isUpdating ? null : _updateSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kBrand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: _kBrand.withOpacity(0.6),
          disabledForegroundColor: Colors.white,
          elevation: 2,
          shadowColor: _kBrand.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: _isUpdating
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : const Icon(Icons.save_rounded, size: 20),
        label: Text(
          _isUpdating ? 'Updating...' : 'Update Settings',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}