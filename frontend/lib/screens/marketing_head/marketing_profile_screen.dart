// lib/screens/profile/marketing_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../../api/marketing_service.dart';
import '../../models/marketing_head/marketing_profile_model.dart';

class MarketingProfileScreen extends StatefulWidget {
  const MarketingProfileScreen({super.key});

  @override
  State<MarketingProfileScreen> createState() => _MarketingProfileScreenState();
}

class _MarketingProfileScreenState extends State<MarketingProfileScreen> {
  final MarketingProfileService _service = MarketingProfileService();
  MarketingProfile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _service.getMyProfile();
      if (response.status) {
        setState(() {
          _profile = response.data;
          _isLoading = false;
        });
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showFullImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "Profile Picture",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  height: 400,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 100),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _shareReferralLink(String link) {
    Share.share(link, subject: 'Join me on QNX Mart');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0F5FA),
              Color(0xFFE8EEF6),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadProfile,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        )
            : Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 800,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card with Avatar and Basic Info
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (_profile!.profileImage != null &&
                                  _profile!.profileImage!.isNotEmpty) {
                                _showFullImageDialog(
                                    _profile!.profileImage!);
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 8,
                                      offset: Offset(0, 2))
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundImage:
                                _profile!.profileImage != null &&
                                    _profile!
                                        .profileImage!.isNotEmpty
                                    ? NetworkImage(
                                    _profile!.profileImage!)
                                    : null,
                                child: (_profile!.profileImage == null ||
                                    _profile!.profileImage!.isEmpty)
                                    ? const Icon(Icons.person,
                                    size: 60, color: Colors.white70)
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _profile!.fullName ?? '',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _profile!.email,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _profile!.status ==
                                        'approved'
                                        ? Colors.green.shade100
                                        : (_profile!.status == 'rejected'
                                        ? Colors.red.shade100
                                        : Colors.orange.shade100),
                                    borderRadius:
                                    BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _profile!.status.toUpperCase(),
                                    style: TextStyle(
                                      color: _profile!.status ==
                                          'approved'
                                          ? Colors.green
                                          : (_profile!.status ==
                                          'rejected'
                                          ? Colors.red
                                          : Colors.orange),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Personal Information Card
                  _buildInfoCard(
                    title: "Personal Information",
                    icon: Icons.person_outline,
                    iconColor: Colors.blue,
                    children: [
                      _InfoRow("Full Name", _profile!.fullName ?? '-'),
                      _InfoRow("Email", _profile!.email),
                      _InfoRow("Mobile", _profile!.mobile),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Professional Details Card
                  _buildInfoCard(
                    title: "Professional Details",
                    icon: Icons.work_outline,
                    iconColor: Colors.green,
                    children: [
                      _InfoRow("Working Area", _profile!.workingArea),
                      _InfoRow("Profession", _profile!.profession),
                      _InfoRow("Experience", _profile!.experience),
                      _InfoRow("Team Size",
                          _profile!.teamSize.toString()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location Card
                  _buildInfoCard(
                    title: "Location",
                    icon: Icons.location_on_outlined,
                    iconColor: Colors.orange,
                    children: [
                      _InfoRow("State", _profile!.state),
                      _InfoRow("District", _profile!.district),
                      _InfoRow("Taluka", _profile!.taluka),
                      _InfoRow("Village", _profile!.village),
                      _InfoRow("Pincode", _profile!.pincode),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Referral & Social Card (with shareable link)
                  _buildInfoCard(
                    title: "Referral & Social",
                    icon: Icons.share_outlined,
                    iconColor: Colors.purple,
                    children: [
                      _InfoRow("Referral Code", _profile!.referralCode),
                      if (_profile!.referredByName != null)
                        _InfoRow("Referred By",
                            _profile!.referredByName!),
                      _InfoRow(
                          "Promotion Platforms",
                          _profile!.promotionPlatforms.join(", "),
                          isLong: true),
                      _InfoRow("Created At",
                          _profile!.createdAt.substring(0, 10)),
                      const SizedBox(height: 8),
                      // 👇 Referral link row with share button
                      _buildReferralLinkRow(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReferralLinkRow() {
    final link = _profile!.referralLink;
    if (link == null || link.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const SizedBox(width: 130),
            Expanded(
              child: Text(
                "No referral link available",
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 130,
            child: Text(
              "Referral Link",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    link,
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.share, size: 18, color: Colors.purple),
                  onPressed: () => _shareReferralLink(link),
                  tooltip: 'Share referral link',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

// Reusable Info Row Widget (unchanged)
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLong;

  const _InfoRow(this.label, this.value, {this.isLong = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
              maxLines: isLong ? 3 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}