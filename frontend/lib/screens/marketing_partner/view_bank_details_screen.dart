import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../api/api_response.dart';
import '../../api/marketing_service.dart';
import '../../models/marketing_partner/bank_details_model.dart';
import '../../models/marketing_partner/bank_details_response.dart';
import '../../models/marketing_partner/retrieve_bank_details_request.dart' hide RetrieveBankDetailsRequest;
import '../../models/qnx_admin/bank_details_request.dart';
import '../marketing_head/bank_detail_screen.dart';
import 'update_bank_details_screen.dart'; // ✅ हे import करायला विसरू नका

class ViewBankDetailsScreen extends StatefulWidget {
  const ViewBankDetailsScreen({super.key});

  @override
  State<ViewBankDetailsScreen> createState() =>
      _ViewBankDetailsScreenState();
}

class _ViewBankDetailsScreenState extends State<ViewBankDetailsScreen> {

  bool loading = true;
  BankDetailsData? bankData;
  int? _partnerId;

  final RetrieveBankDetailsService _retrieveService = RetrieveBankDetailsService();

  @override
  void initState() {
    super.initState();
    _loadPartnerIdAndBankDetails();
  }

  Future<void> _loadPartnerIdAndBankDetails() async {
    setState(() => loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String? partnerId = prefs.getString('marketing_partner_id');

      print('🔍 Looking for marketing_partner_id...');

      if (partnerId == null || partnerId.isEmpty) {
        print('⚠️ marketing_partner_id not found. Fetching from profile...');

        final profileService = MarketingProfileService();
        final response = await profileService.getMyProfile();

        if (response.status && response.data != null) {
          partnerId = response.data!.id.toString();
          await prefs.setString('marketing_partner_id', partnerId);
          await prefs.setString('partner_id', partnerId);
          print('✅ Fetched partner_id from profile: $partnerId');
        } else {
          partnerId = prefs.getString('user_id');
          print('⚠️ Using user_id as fallback: $partnerId');
        }
      }

      setState(() {
        _partnerId = partnerId != null ? int.tryParse(partnerId) : null;
      });

      print('✅ Partner ID: $_partnerId');

      if (_partnerId != null) {
        await _fetchBankDetails(_partnerId!);
      } else {
        setState(() {
          loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find partner ID. Please login again.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() {
        loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchBankDetails(int partnerId) async {
    try {
      print('📤 Fetching bank details for partner: $partnerId');

      final request = RetrieveBankDetailsRequest(
        marketingPartner: partnerId,
      );

      final response = await _retrieveService.retrieveBankDetails(request);

      print('📥 Response Status: ${response.status}');
      print('📦 Response Data: ${response.data}');

      if (mounted) {
        setState(() {
          if (response.status && response.data != null) {
            bankData = response.data;
            print('✅ Bank details loaded successfully');
          } else {
            bankData = null;
            print('ℹ️ No bank details found for partner: $partnerId');
          }
          loading = false;
        });
      }

    } catch (e) {
      print('❌ Failed to fetch bank details: $e');
      if (mounted) {
        setState(() {
          loading = false;
          bankData = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load bank details: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF475569),
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Bank Details",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: loading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4158D0)),
            ),
            SizedBox(height: 16),
            Text(
              'Loading bank details...',
              style: TextStyle(
                color: Color(0xFF475569),
                fontSize: 14,
              ),
            ),
          ],
        ),
      )
          : bankData == null
          ? _buildEmptyState()
          : _buildBankDetailsContent(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "No Bank Details Found",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Please add your bank details",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateBankDetailsScreen(),
                  ),
                ).then((_) => _loadPartnerIdAndBankDetails());
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Bank Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4158D0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
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

  Widget _buildBankDetailsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4158D0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Bank Account Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Details
              _buildRow("Account Holder", bankData!.accountHolderName),
              const Divider(height: 16),
              _buildRow("Bank Name", bankData!.bankName),
              const Divider(height: 16),
              _buildRow("Branch Name", bankData!.branchName),
              const Divider(height: 16),
              _buildRow("Account Number", bankData!.accountNumber),
              const Divider(height: 16),
              _buildRow("IFSC Code", bankData!.ifscCode),
              const Divider(height: 16),
              _buildRow("Account Type", bankData!.accountType.toUpperCase()),
              if (bankData!.upiId != null && bankData!.upiId!.isNotEmpty) ...[
                const Divider(height: 16),
                _buildRow("UPI ID", bankData!.upiId!),
              ],

              const SizedBox(height: 16),

              // ✅ EDIT BUTTON
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // UpdateBankDetailsScreen ला navigate करा
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UpdateBankDetailsScreen(
                          bankDetails: bankData!,
                        ),
                      ),
                    ).then((result) {
                      // Update झाल्यावर data refresh करा
                      if (result == true) {
                        _loadPartnerIdAndBankDetails();
                      }
                    });
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Bank Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4158D0),
                    side: const BorderSide(color: Color(0xFF4158D0)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _retrieveService.dispose();
    super.dispose();
  }
}