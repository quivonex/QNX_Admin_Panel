import 'package:flutter/material.dart';
import '../../api/api_service.dart';
import '../../models/qnx_admin/approved_enquiry_model.dart';
import 'company_approved_enquiry.dart';

class ApprovedEnquiriesScreen extends StatefulWidget {
  const ApprovedEnquiriesScreen({super.key});

  @override
  State<ApprovedEnquiriesScreen> createState() => _ApprovedEnquiriesScreenState();
}

class _ApprovedEnquiriesScreenState extends State<ApprovedEnquiriesScreen> {
  List<ApprovedEnquiry> approved = [];
  bool isLoadingApproved = true;

  @override
  void initState() {
    super.initState();
    _loadApprovedData();
  }

  Future<void> _loadApprovedData() async {
    try {
      final response = await ApprovedEnquiryService.fetchApprovedEnquiries();
      if (mounted) {
        setState(() {
          approved = response.data;
          isLoadingApproved = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingApproved = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load approved enquiries")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.check_circle, color: Color(0xFF4158D0)),
            const SizedBox(width: 10),
            const Text(
              "Approved Enquiries",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() => isLoadingApproved = true);
              _loadApprovedData();
            },
            icon: const Icon(Icons.refresh, color: Color(0xFF4158D0)),
          ),
        ],
      ),
      body: isLoadingApproved
          ? const Center(child: CircularProgressIndicator())
          : approved.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No Approved Enquiries",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      )
          : ApprovedEnquiryTable(initialData: approved),
    );
  }
}