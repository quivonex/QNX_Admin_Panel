import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/api_service.dart';
import '../../api/marketing_service.dart';
import '../../models/marketing_partner/bank_details_model.dart';
import '../../models/marketing_partner/update_bank_details_model.dart';
import '../../api/api_response.dart';

class UpdateBankDetailsScreen extends StatefulWidget {
  final BankDetailsData bankDetails;

  const UpdateBankDetailsScreen({
    super.key,
    required this.bankDetails,
  });

  @override
  State<UpdateBankDetailsScreen> createState() =>
      _UpdateBankDetailsScreenState();
}

class _UpdateBankDetailsScreenState extends State<UpdateBankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _updateService = UpdateBankDetailsService();

  // Controllers
  final _accountHolderController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _branchNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _upiController = TextEditingController();

  String _accountType = 'savings';
  bool _isLoading = false;

  static const _purple = Color(0xFF6C63FF);
  static const _pink = Color(0xFFC850C0);

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  void _populateFields() {
    _accountHolderController.text = widget.bankDetails.accountHolderName;
    _bankNameController.text = widget.bankDetails.bankName;
    _branchNameController.text = widget.bankDetails.branchName;
    _accountNumberController.text = widget.bankDetails.accountNumber;
    _ifscController.text = widget.bankDetails.ifscCode;
    _upiController.text = widget.bankDetails.upiId ?? '';
    _accountType = widget.bankDetails.accountType;
  }

  @override
  void dispose() {
    _updateService.dispose();
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _branchNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _updateBankDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final request = UpdateBankDetailsRequest(
        id: widget.bankDetails.id,
        accountHolderName: _accountHolderController.text.trim(),
        bankName: _bankNameController.text.trim(),
        branchName: _branchNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        ifscCode: _ifscController.text.trim().toUpperCase(),
        accountType: _accountType,
        upiId: _upiController.text.trim().isEmpty
            ? null
            : _upiController.text.trim(),
      );

      final response = await _updateService.updateBankDetails(request);

      if (!mounted) return;

      if (response.status) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context, true); // Return true to refresh parent
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      appBar: AppBar(
        title: const Text(
          'Update Bank Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: _purple,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateBankDetails,
            style: TextButton.styleFrom(
              foregroundColor: _purple,
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: _isLoading
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _purple,
              ),
            )
                : const Text(
              'Save',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_purple, _pink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.edit_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Update Bank Details',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Update your bank information for commission payouts',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.85),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _sectionHeader('Account Information', Icons.credit_card_outlined),
            const SizedBox(height: 16),
            _buildField(
              controller: _accountHolderController,
              label: 'Account Holder Name',
              hint: 'Full name as on bank records',
              icon: Icons.person_outline_rounded,
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildField(
                    controller: _bankNameController,
                    label: 'Bank Name',
                    hint: 'e.g. SBI',
                    icon: Icons.account_balance_outlined,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _branchNameController,
                    label: 'Branch Name',
                    hint: 'e.g. Satara',
                    icon: Icons.location_city_outlined,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildField(
                    controller: _accountNumberController,
                    label: 'Account Number',
                    hint: 'Account number',
                    icon: Icons.tag_rounded,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    validator: (v) => v!.isEmpty
                        ? 'Required'
                        : v.length < 9
                        ? 'Invalid'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _ifscController,
                    label: 'IFSC Code',
                    hint: 'e.g. SBIN0001234',
                    icon: Icons.code_rounded,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9]')),
                      LengthLimitingTextInputFormatter(11),
                      _UpperCaseTextFormatter(),
                    ],
                    helperText: '4 letters + 0 + 6 chars',
                    validator: (v) {
                      if (v!.isEmpty) return 'Required';
                      if (!RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$')
                          .hasMatch(v.toUpperCase())) {
                        return 'Invalid IFSC';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            _sectionHeader('Account Type', Icons.account_balance_wallet_outlined),
            const SizedBox(height: 12),
            _buildAccountTypeSelector(),

            const SizedBox(height: 20),

            _sectionHeader('UPI', Icons.qr_code_2_rounded, optional: true),
            const SizedBox(height: 12),
            _buildField(
              controller: _upiController,
              label: 'UPI ID',
              hint: 'e.g. name@okicici',
              icon: Icons.qr_code_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                if (!v.contains('@')) return 'Invalid UPI (e.g. name@bank)';
                return null;
              },
            ),

            const SizedBox(height: 24),
            _buildUpdateButton(),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, {bool optional = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _purple.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _purple, size: 16),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF444444),
            letterSpacing: 0.3,
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Optional',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 14),
      decoration: _inputDecoration(label: label, icon: icon, hint: hint)
          .copyWith(helperText: helperText),
      validator: validator,
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(fontSize: 13),
      hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
      prefixIcon: Icon(icon, color: _purple, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _purple, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }

  Widget _buildAccountTypeSelector() {
    return Row(
      children: [
        _accountTypeOption('savings', 'Savings Account', Icons.savings_outlined),
        const SizedBox(width: 12),
        _accountTypeOption('current', 'Current Account', Icons.business_center_outlined),
      ],
    );
  }

  Widget _accountTypeOption(String value, String label, IconData icon) {
    final selected = _accountType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _accountType = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          decoration: BoxDecoration(
            color: selected ? _purple.withOpacity(0.07) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _purple : Colors.grey.shade200,
              width: selected ? 1.5 : 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? _purple : Colors.grey.shade500),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    color: selected ? _purple : Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _updateBankDetails,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.grey.shade200,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: _isLoading
                ? null
                : const LinearGradient(
              colors: [_purple, _pink],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
                : const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.update_rounded, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Update Bank Details',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}