import 'package:flutter/material.dart';

import '../../api/api_response.dart';
import '../../models/qnx_admin/bank_details_request.dart';
import '../../models/marketing_head/bank_details_model.dart' hide RetrieveBankDetailsRequest, BankDetailsRequest;
import '../../api/marketing_service.dart';

class CreateBankDetailsScreen extends StatefulWidget {
  const CreateBankDetailsScreen({super.key});

  @override
  State<CreateBankDetailsScreen> createState() =>
      _CreateBankDetailsScreenState();
}

class _CreateBankDetailsScreenState extends State<CreateBankDetailsScreen> {
  final _createService = BankDetailsService();
  final _retrieveService = RetrieveBankDetailsService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final holderController = TextEditingController();
  final bankController = TextEditingController();
  final branchController = TextEditingController();
  final accountController = TextEditingController();
  final ifscController = TextEditingController();
  final upiController = TextEditingController();

  String accountType = "savings";
  bool isEditing = false;
  bool isLoading = false;
  BankDetail? bankData;

  @override
  void initState() {
    super.initState();
    _fetchBankDetailsOnLoad();
  }

  @override
  void dispose() {
    holderController.dispose();
    bankController.dispose();
    branchController.dispose();
    accountController.dispose();
    ifscController.dispose();
    upiController.dispose();
    super.dispose();
  }

  Future<void> _fetchBankDetailsOnLoad() async {
    try {
      setState(() {
        isLoading = true;
      });
      final request = RetrieveBankDetailsRequest(marketingPartner: 2);
      final response = await _retrieveService.retrieveBankDetails(request);
      setState(() {
        bankData = response.data as BankDetail?;
        if (bankData != null) {
          holderController.text = bankData!.accountHolderName;
          bankController.text = bankData!.bankName;
          branchController.text = bankData!.branchName;
          accountController.text = bankData!.accountNumber;
          ifscController.text = bankData!.ifscCode;
          upiController.text = bankData!.upiId ?? "";

          String type = bankData!.accountType.toLowerCase().trim();
          if (type == "savings" || type == "current") {
            accountType = type;
          } else {
            accountType = "savings";
          }
        }
      });
    } catch (e) {
      // सुरुवातीला डेटा नसेल तर एरर दाखवण्याची गरज नाही
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> saveBankDetails() async {
    try {
      final request = BankDetailsRequest(
        marketingPartner: 2,
        accountHolderName: holderController.text,
        bankName: bankController.text,
        branchName: branchController.text,
        accountNumber: accountController.text,
        ifscCode: ifscController.text,
        accountType: accountType,
        upiId: upiController.text,
      );

      final response = await _createService.createBankDetails(request);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.message)),
      );

      setState(() {
        isEditing = false;
      });
      _fetchBankDetailsOnLoad();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // 🛠️ ग्रिड सिस्टीममध्ये योग्य डिझाईन दिसण्यासाठी इनपुट領तील खालचा बॉटम पॅडिंग काढून टाकला आहे.
  Widget buildInputField(String hintText, TextEditingController controller, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
        prefixIcon: Icon(icon, color: const Color(0xFF4158D0), size: 20),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF4158D0), width: 1.5)),
      ),
    );
  }

  // 🛠️ ओव्हरफ्लो टाळण्यासाठी फिक्स विड्थऐवजी Expanded चा वापर केला आहे
  Widget buildDetailRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4158D0), size: 20),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 4,
            child: Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5FA),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          padding: const EdgeInsets.all(24.0),
          child: isEditing ? _buildFormView() : _buildDataDetailsView(),
        ),
      ),
    );
  }

  Widget _buildDataDetailsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🛠️ हे मुख्य Row चे ओव्हरफ्लो घालवण्यासाठी बदलले आहे (Expanded चा वापर करून)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(color: const Color(0xFF9B59B6), borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Bank Details',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
              icon: const Icon(Icons.edit, size: 18, color: Color(0xFF4158D0)),
              label: const Text(
                "Add / Edit Form",
                style: TextStyle(color: Color(0xFF4158D0), fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[100]!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              buildDetailRow(Icons.person, "Account Holder", bankData?.accountHolderName ?? ""),
              buildDetailRow(Icons.account_balance, "Bank Name", bankData?.bankName ?? ""),
              buildDetailRow(Icons.numbers, "Account Number", bankData?.accountNumber ?? ""),
              buildDetailRow(Icons.pin, "IFSC Code", bankData?.ifscCode ?? ""),
              buildDetailRow(Icons.location_on, "Branch", bankData?.branchName ?? ""),
              buildDetailRow(Icons.merge_type, "Account Type", bankData != null ? "${bankData!.accountType.toUpperCase()} Account" : ""),
              buildDetailRow(Icons.qr_code, "UPI ID", bankData?.upiId ?? ""),
            ],
          ),
        ),
      ],
    );
  }

  // 📂 2-Column Responsive Grid सिस्टीम लावलेला फॉर्म व्ह्यू
  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Edit Bank Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () {
                  setState(() {
                    isEditing = false;
                  });
                },
              )
            ],
          ),
          const SizedBox(height: 24),

          // LayoutBuilder स्क्रीनची रुंदी (Width) मोजून २ कॉलम्स तयार करतो
          LayoutBuilder(
            builder: (context, constraints) {
              // स्क्रीन रुंद असेल तर २ कॉलम (Width अर्धी होईल), मोबाईलवर १ कॉलम (Full Width)
              double width = constraints.maxWidth > 600
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 16,     // दोन कॉलममधील आडवे अंतर
                runSpacing: 16,  // दोन ओळींमधील उभे अंतर
                children: [
                  SizedBox(
                    width: width,
                    child: buildInputField("Account Holder Name", holderController, Icons.person),
                  ),
                  SizedBox(
                    width: width,
                    child: buildInputField("Bank Name", bankController, Icons.account_balance),
                  ),
                  SizedBox(
                    width: width,
                    child: buildInputField("Branch Name", branchController, Icons.location_on),
                  ),
                  SizedBox(
                    width: width,
                    child: buildInputField("Account Number", accountController, Icons.credit_card, keyboardType: TextInputType.number),
                  ),
                  SizedBox(
                    width: width,
                    child: buildInputField("IFSC Code", ifscController, Icons.pin),
                  ),
                  SizedBox(
                    width: width,
                    child: buildInputField("UPI ID", upiController, Icons.qr_code),
                  ),
                  SizedBox(
                    width: width,
                    child: DropdownButtonFormField<String>(
                      value: accountType,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        prefixIcon: const Icon(Icons.merge_type, color: Color(0xFF4158D0), size: 20),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                      ),
                      items: const [
                        DropdownMenuItem(value: "savings", child: Text("Savings")),
                        DropdownMenuItem(value: "current", child: Text("Current")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          accountType = value.toString();
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => isEditing = false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Cancel"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: saveBankDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4158D0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text("Save Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}