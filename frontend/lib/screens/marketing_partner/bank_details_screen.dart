import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:battery_regeneration_system/models/marketing_partner/bank_details_model.dart';
import 'package:battery_regeneration_system/models/qnx_admin/bank_details_request.dart' as bankService;
import '../../api/api_response.dart';
import '../../api/marketing_service.dart';
import '../../api/api_service.dart';
import '../../models/marketing_partner/update_bank_details_model.dart';

class CreateBankDetailsScreen extends StatefulWidget {
  const CreateBankDetailsScreen({super.key});

  @override
  State<CreateBankDetailsScreen> createState() =>
      _CreateBankDetailsScreenState();
}

class _CreateBankDetailsScreenState extends State<CreateBankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final accountHolderController = TextEditingController();
  final bankNameController = TextEditingController();
  final branchController = TextEditingController();
  final accountNumberController = TextEditingController();
  final ifscController = TextEditingController();
  final upiController = TextEditingController();

  String accountType = "savings";
  bool loading = false;
  bool _isFormVisible = false;
  bool _isLoadingData = true;
  bool _isUpdateMode = false; // ✅ Track if we are in update mode

  // ✅ REAL DATA from API
  int? _partnerId;
  BankDetailsData? _bankDetails;
  bool _hasExistingData = false;

  // Services
  final _retrieveService = RetrieveBankDetailsService();
  final _createService = CreateBankDetailsRequest();
  final _updateService = UpdateBankDetailsService(); // ✅ Added update service

  @override
  void initState() {
    super.initState();
    _loadPartnerIdAndBankDetails();
  }

  // ✅ Step 1: Load Partner ID
  Future<void> _loadPartnerIdAndBankDetails() async {
    setState(() => _isLoadingData = true);

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
        }
      }

      setState(() {
        _partnerId = partnerId != null ? int.tryParse(partnerId) : null;
      });

      print('✅ Partner ID: $_partnerId');

      // ✅ Step 2: Fetch Bank Details using partner ID
      if (_partnerId != null) {
        await _fetchBankDetails(_partnerId!);
      }

    } catch (e) {
      print('❌ Error loading data: $e');
    } finally {
      setState(() => _isLoadingData = false);
    }
  }

  // ✅ Step 3: Fetch Bank Details from API
  Future<void> _fetchBankDetails(int partnerId) async {
    try {
      print('📤 Fetching bank details for partner: $partnerId');

      final request = bankService.RetrieveBankDetailsRequest(
        marketingPartner: partnerId,
      );

      final response = await _retrieveService.retrieveBankDetails(request);

      print('📥 Response Status: ${response.status}');
      print('📦 Response Data: ${response.data}');

      if (response.status && response.data != null) {
        setState(() {
          _bankDetails = response.data;
          _hasExistingData = true;
        });
        print('✅ Bank details loaded successfully');
      } else {
        setState(() {
          _hasExistingData = false;
          _bankDetails = null;
        });
        print('ℹ️ No bank details found for partner: $partnerId');
      }

    } catch (e) {
      print('❌ Failed to fetch bank details: $e');
      setState(() {
        _hasExistingData = false;
        _bankDetails = null;
      });
    }
  }

  // ✅ Refresh data after save/update
  Future<void> _refreshData() async {
    if (_partnerId != null) {
      await _fetchBankDetails(_partnerId!);
    }
  }

  // ✅ Open Form for Create/Update
  void _openForm({bool isUpdate = false}) {
    setState(() {
      _isFormVisible = true;
      _isUpdateMode = isUpdate;

      if (isUpdate && _hasExistingData && _bankDetails != null) {
        // Populate form with existing data for update
        accountHolderController.text = _bankDetails!.accountHolderName;
        bankNameController.text = _bankDetails!.bankName;
        branchController.text = _bankDetails!.branchName;
        accountNumberController.text = _bankDetails!.accountNumber;
        ifscController.text = _bankDetails!.ifscCode;
        upiController.text = _bankDetails!.upiId ?? "";

        // Set account type
        if (_bankDetails!.accountType.toLowerCase().contains('savings')) {
          accountType = "savings";
        } else if (_bankDetails!.accountType.toLowerCase().contains('current')) {
          accountType = "current";
        }
      } else {
        // Clear form for create
        accountHolderController.clear();
        bankNameController.clear();
        branchController.clear();
        accountNumberController.clear();
        ifscController.clear();
        upiController.clear();
        accountType = "savings";
      }
    });
  }

  // ✅ Submit: Create or Update Bank Details
  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_partnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait, loading partner information...'),
          backgroundColor: Colors.orange,
        ),
      );
      await _loadPartnerIdAndBankDetails();
      return;
    }

    setState(() => loading = true);

    try {
      if (_isUpdateMode && _hasExistingData) {
        // ✅ UPDATE MODE
        await _updateBankDetails();
      } else {
        // ✅ CREATE MODE
        await _createBankDetails();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    setState(() => loading = false);
  }

  // ✅ Create Bank Details
  Future<void> _createBankDetails() async {
    final request = bankService.BankDetailsRequest(
      marketingPartner: _partnerId!,
      accountHolderName: accountHolderController.text.trim(),
      bankName: bankNameController.text.trim(),
      branchName: branchController.text.trim(),
      accountNumber: accountNumberController.text.trim(),
      ifscCode: ifscController.text.trim().toUpperCase(),
      accountType: accountType,
      upiId: upiController.text.trim().isEmpty
          ? null
          : upiController.text.trim(),
    );

    print('📤 Creating bank details with partner_id: ${request.marketingPartner}');
    print('📤 Request: ${request.toJson()}');

    final response = await _createService.createBankDetails(request);

    if (!mounted) return;

    if (response.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? "Bank details saved successfully!"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );

      // ✅ Refresh data after saving
      await _refreshData();

      setState(() {
        _isFormVisible = false;
        _isUpdateMode = false;
      });

      // Clear form
      _formKey.currentState!.reset();
      accountHolderController.clear();
      bankNameController.clear();
      branchController.clear();
      accountNumberController.clear();
      ifscController.clear();
      upiController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? "Failed to save bank details"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ✅ Update Bank Details
  Future<void> _updateBankDetails() async {
    final request = UpdateBankDetailsRequest(
      id: _bankDetails!.id,
      accountHolderName: accountHolderController.text.trim(),
      bankName: bankNameController.text.trim(),
      branchName: branchController.text.trim(),
      accountNumber: accountNumberController.text.trim(),
      ifscCode: ifscController.text.trim().toUpperCase(),
      accountType: accountType,
      upiId: upiController.text.trim().isEmpty
          ? null
          : upiController.text.trim(),
    );

    print('📤 Updating bank details with id: ${request.id}');
    print('📤 Request: ${request.toJson()}');

    final response = await _updateService.updateBankDetails(request);

    if (!mounted) return;

    if (response.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? "Bank details updated successfully!"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );

      // ✅ Refresh data after update
      await _refreshData();

      setState(() {
        _isFormVisible = false;
        _isUpdateMode = false;
      });

      // Clear form
      _formKey.currentState!.reset();
      accountHolderController.clear();
      bankNameController.clear();
      branchController.clear();
      accountNumberController.clear();
      ifscController.clear();
      upiController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? "Failed to update bank details"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    accountHolderController.dispose();
    bankNameController.dispose();
    branchController.dispose();
    accountNumberController.dispose();
    ifscController.dispose();
    upiController.dispose();
    _retrieveService.dispose();
    _updateService.dispose();
    super.dispose();
  }

  // ================= UI BUILD =================
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 800;

    // ✅ Show loading while fetching data
    if (_isLoadingData) {
      return Container(
        color: const Color(0xFFF3F7FA),
        child: const Center(
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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFF3F7FA),
      padding: EdgeInsets.all(isDesktop ? 40.0 : 16.0),
      child: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 900),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4158D0).withOpacity(0.06),
                  blurRadius: 30,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: EdgeInsets.all(isDesktop ? 48.0 : 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 32),

                // Conditional View
                _isFormVisible
                    ? _buildTableForm(isDesktop)
                    : _buildRetrievedDetails(isDesktop),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 6,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4158D0), Color(0xFFC850C0)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              _isFormVisible
                  ? (_isUpdateMode ? 'Update Bank Details' : 'Create Bank Details')
                  : 'Bank Account Profile',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        Row(
          children: [
            // ✅ Update Button - Only show if data exists
            if (_hasExistingData && !_isFormVisible)
              ElevatedButton.icon(
                onPressed: () => _openForm(isUpdate: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4158D0),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.update_rounded, size: 18),
                label: const Text('Update', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            const SizedBox(width: 8),

            // ✅ Create/Edit Button
            ElevatedButton.icon(
              onPressed: () {
                if (_hasExistingData && !_isFormVisible) {
                  // If data exists and form is not visible, open update form
                  _openForm(isUpdate: true);
                } else if (_isFormVisible) {
                  // If form is visible, close it
                  setState(() {
                    _isFormVisible = false;
                    _isUpdateMode = false;
                    _formKey.currentState?.reset();
                    accountHolderController.clear();
                    bankNameController.clear();
                    branchController.clear();
                    accountNumberController.clear();
                    ifscController.clear();
                    upiController.clear();
                  });
                } else {
                  // If no data, open create form
                  _openForm(isUpdate: false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFormVisible
                    ? Colors.red.withOpacity(0.08)
                    : const Color(0xFF4158D0).withOpacity(0.08),
                foregroundColor: _isFormVisible ? Colors.red : const Color(0xFF4158D0),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(
                _isFormVisible
                    ? Icons.close_rounded
                    : (_hasExistingData ? Icons.edit_outlined : Icons.add_rounded),
                size: 18,
              ),
              label: Text(
                _isFormVisible
                    ? "Cancel"
                    : (_hasExistingData ? "Edit" : "Create"),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ================= FORM VIEW =================
  Widget _buildTableForm(bool isDesktop) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
            ),
            child: Column(
              children: [
                _buildFormRow(
                  isDesktop: isDesktop,
                  label1: "Account Holder *",
                  child1: _buildTableCellField(
                    hint: "Enter holder's name",
                    icon: Icons.person_outline,
                    controller: accountHolderController,
                  ),
                  label2: "Bank Name *",
                  child2: _buildTableCellField(
                    hint: "e.g. HDFC Bank",
                    icon: Icons.account_balance_outlined,
                    controller: bankNameController,
                  ),
                ),
                const Divider(height: 1, thickness: 1.5, color: Color(0xFFE2E8F0)),
                _buildFormRow(
                  isDesktop: isDesktop,
                  label1: "Account Number *",
                  child1: _buildTableCellField(
                    hint: "Enter account number",
                    icon: Icons.tag,
                    controller: accountNumberController,
                    isNumber: true,
                  ),
                  label2: "Account Type *",
                  child2: DropdownButtonFormField<String>(
                    value: accountType,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF4158D0)),
                    style: const TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.w500),
                    decoration: _getTableCellDecoration("Select Type", Icons.wallet_outlined),
                    items: const [
                      DropdownMenuItem(value: "savings", child: Text("Savings Account")),
                      DropdownMenuItem(value: "current", child: Text("Current Account")),
                    ],
                    onChanged: (v) => setState(() => accountType = v!),
                  ),
                ),
                const Divider(height: 1, thickness: 1.5, color: Color(0xFFE2E8F0)),
                _buildFormRow(
                  isDesktop: isDesktop,
                  label1: "IFSC Code *",
                  child1: _buildTableCellField(
                    hint: "e.g. HDFC0001234",
                    icon: Icons.password_rounded,
                    controller: ifscController,
                  ),
                  label2: "Branch Name *",
                  child2: _buildTableCellField(
                    hint: "Enter branch location",
                    icon: Icons.location_on_outlined,
                    controller: branchController,
                  ),
                ),
                const Divider(height: 1, thickness: 1.5, color: Color(0xFFE2E8F0)),
                _buildFormRow(
                  isDesktop: isDesktop,
                  label1: "UPI ID (Optional)",
                  child1: _buildTableCellField(
                    hint: "e.g. name@upi",
                    icon: Icons.qr_code_scanner_rounded,
                    controller: upiController,
                  ),
                  label2: "",
                  child2: const SizedBox(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Container(
            width: isDesktop ? 280 : double.infinity,
            height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4158D0), Color(0xFF6B21A8)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4158D0).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: loading ? null : submit,
              icon: loading
                  ? const SizedBox()
                  : Icon(
                _isUpdateMode ? Icons.update_rounded : Icons.check_circle_outline,
                color: Colors.white,
                size: 20,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              label: loading
                  ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
                  : Text(
                _isUpdateMode ? 'Update Bank Profile' : 'Save Bank Profile',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= DISPLAY PROFILE VIEW =================
  Widget _buildRetrievedDetails(bool isDesktop) {
    // ✅ If no data exists, show empty state
    if (!_hasExistingData || _bankDetails == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 50),
          child: Column(
            children: [
              Icon(Icons.account_balance_wallet_outlined, size: 70, color: const Color(0xFF94A3B8)),
              const SizedBox(height: 18),
              const Text(
                "No Bank Details Found",
                style: TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Click on 'Create' button to add bank details.",
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ Display real data from API
    final bank = _bankDetails!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 32 : 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            Icons.person_outline_rounded,
            "Account Holder",
            bank.accountHolderName,
            isDesktop,
          ),
          const Divider(height: 32, color: Color(0xFFE2E8F0)),
          _buildDetailRow(
            Icons.account_balance_outlined,
            "Bank Name",
            bank.bankName,
            isDesktop,
          ),
          const Divider(height: 32, color: Color(0xFFE2E8F0)),
          _buildDetailRow(
            Icons.tag_rounded,
            "Account Number",
            bank.accountNumber,
            isDesktop,
          ),
          const Divider(height: 32, color: Color(0xFFE2E8F0)),
          _buildDetailRow(
            Icons.password_outlined,
            "IFSC Code",
            bank.ifscCode,
            isDesktop,
          ),
          const Divider(height: 32, color: Color(0xFFE2E8F0)),
          _buildDetailRow(
            Icons.location_on_outlined,
            "Branch",
            bank.branchName,
            isDesktop,
          ),
          const Divider(height: 32, color: Color(0xFFE2E8F0)),
          _buildDetailRow(
            Icons.wallet_outlined,
            "Account Type",
            bank.accountType.toUpperCase(),
            isDesktop,
          ),
          if (bank.upiId != null && bank.upiId!.isNotEmpty) ...[
            const Divider(height: 32, color: Color(0xFFE2E8F0)),
            _buildDetailRow(
              Icons.qr_code_scanner_rounded,
              "UPI ID",
              bank.upiId!,
              isDesktop,
            ),
          ],
          const SizedBox(height: 24),

          // ✅ UPDATE Button at bottom
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openForm(isUpdate: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4158D0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.update_rounded, size: 20),
              label: const Text(
                'Update Bank Details',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPER WIDGETS =================
  Widget _buildFormRow({
    required bool isDesktop,
    required String label1,
    required Widget child1,
    required String label2,
    required Widget child2,
  }) {
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              color: const Color(0xFFF8FAFC),
              child: Text(label1, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569), fontSize: 13.5)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: child1,
            ),
          ),
          Container(width: 1.5, height: 76, color: const Color(0xFFE2E8F0)),
          Expanded(
            flex: 2,
            child: label2.isEmpty
                ? Container(color: const Color(0xFFF8FAFC), height: 76)
                : Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              color: const Color(0xFFF8FAFC),
              child: Text(label2, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569), fontSize: 13.5)),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: child2,
            ),
          ),
        ],
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label1, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569), fontSize: 13.5)),
            const SizedBox(height: 8),
            child1,
            if (label2.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(label2, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF475569), fontSize: 13.5)),
              const SizedBox(height: 8),
              child2,
            ],
          ],
        ),
      );
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value, bool isDesktop) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Icon(icon, color: const Color(0xFF4158D0), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: isDesktop ? 3 : 4,
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          flex: isDesktop ? 7 : 6,
          child: Text(
            value,
            softWrap: true,
            maxLines: 2,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _getTableCellDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
      prefixIcon: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Icon(icon, color: const Color(0xFF64748B), size: 19),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 40),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF4158D0), width: 1.8)),
      errorStyle: const TextStyle(height: 0.6, fontSize: 11, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildTableCellField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isNumber = false
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(fontSize: 14, color: Color(0xFF334155), fontWeight: FontWeight.w500),
      decoration: _getTableCellDecoration(hint, icon),
      validator: (value) {
        if (hint.contains('Optional')) return null;
        if (value == null || value.isEmpty) return 'Field Required';
        if (isNumber && value.length < 9) return 'Enter a valid account number';
        return null;
      },
    );
  }
}